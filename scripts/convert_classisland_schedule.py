#!/usr/bin/env python3
"""将 ClassIsland subjects/time layouts/class plans 档案转换为 CW 课程表 JSON。

转换器只处理课程表核心数据：科目、时间段、课程、休息和单双周。
ClassIsland 的 AttachedObjects、策略、通知、覆盖课表与插件数据不会写入 CW 输出。
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any


SCHEDULE_SCHEMA_VERSION = 1
CLASSISLAND_TIME_TYPE_CLASS = 0
CLASSISLAND_TIME_TYPE_BREAK = 1


class ConversionError(ValueError):
    """表示输入档案缺少转换所需的核心字段。"""


@dataclass
class ConversionReport:
    subjects: int = 0
    timelines: int = 0
    entries: int = 0
    skipped_disabled_plans: int = 0
    skipped_overlays: int = 0
    warnings: list[str] = field(default_factory=list)

    def add_warning(self, message: str) -> None:
        if message not in self.warnings:
            self.warnings.append(message)


def read_json_object(path: Path, label: str) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except FileNotFoundError as exc:
        raise ConversionError(f"找不到{label}文件：{path}") from exc
    except json.JSONDecodeError as exc:
        raise ConversionError(f"{label}不是有效 JSON：{path}（第 {exc.lineno} 行）") from exc
    if not isinstance(data, dict):
        raise ConversionError(f"{label}顶层必须是 JSON 对象：{path}")
    return data


def require_mapping(parent: dict[str, Any], key: str, label: str) -> dict[str, Any]:
    value = parent.get(key, {})
    if not isinstance(value, dict):
        raise ConversionError(f"{label}中的 {key} 必须是对象")
    return value


def normalize_time(value: Any, label: str) -> str:
    """将 ClassIsland ISO8601 时间或 HH:MM 值标准化为 CW 所需的 HH:MM。"""
    text = str(value or "").strip()
    if not text:
        raise ConversionError(f"缺少时间字段：{label}")
    if len(text) >= 5 and text[2:3] == ":" and text.count(":") == 1:
        hour, minute = text.split(":", 1)
        if hour.isdigit() and minute.isdigit() and 0 <= int(hour) <= 23 and 0 <= int(minute) <= 59:
            return f"{int(hour):02d}:{int(minute):02d}"
    try:
        normalized = text.replace("Z", "+00:00")
        return datetime.fromisoformat(normalized).strftime("%H:%M")
    except ValueError as exc:
        raise ConversionError(f"无法解析时间 {label}：{text}") from exc


def map_day_of_week(value: Any) -> int:
    """ClassIsland WeekDay: 0=周日、1=周一……6=周六；CW: 1=周一……7=周日。"""
    try:
        source_day = int(value)
    except (TypeError, ValueError) as exc:
        raise ConversionError(f"无效的 ClassIsland WeekDay：{value!r}") from exc
    if not 0 <= source_day <= 6:
        raise ConversionError(f"ClassIsland WeekDay 超出范围：{source_day}")
    return 7 if source_day == 0 else source_day


def map_weeks(value: Any) -> str | list[int]:
    """将 ClassIsland WeekCountDiv 0/1/2 映射为 CW all/单周/双周。"""
    try:
        week_count_div = int(value or 0)
    except (TypeError, ValueError) as exc:
        raise ConversionError(f"无效的 ClassIsland WeekCountDiv：{value!r}") from exc
    if week_count_div == 0:
        return "all"
    if week_count_div == 1:
        return [1]
    if week_count_div == 2:
        return [2]
    raise ConversionError(
        f"暂不支持 ClassIsland WeekCountDiv={week_count_div}；仅支持 0（每周）、1（单周）和 2（双周）"
    )


def convert_subjects(raw_subjects: dict[str, Any], report: ConversionReport) -> list[dict[str, Any]]:
    subjects: list[dict[str, Any]] = []
    for subject_id, raw_subject in raw_subjects.items():
        if not isinstance(raw_subject, dict):
            report.add_warning(f"已跳过无效科目：{subject_id}")
            continue
        name = str(raw_subject.get("Name", "")).strip()
        if not name:
            report.add_warning(f"已跳过没有 Name 的科目：{subject_id}")
            continue
        subject = {
            "id": str(subject_id),
            "name": name,
            "simplifiedName": str(raw_subject.get("Initial", "")).strip() or None,
            "teacher": str(raw_subject.get("TeacherName", "")).strip() or None,
            "isLocalClassroom": not bool(raw_subject.get("IsOutDoor", False)),
        }
        subjects.append({key: value for key, value in subject.items() if value is not None})
    report.subjects = len(subjects)
    return subjects


def entry_for_layout(
    layout: dict[str, Any],
    source_plan_id: str,
    layout_index: int,
    assigned_subject_id: str | None,
    report: ConversionReport,
) -> dict[str, Any]:
    start_time = normalize_time(layout.get("StartSecond"), f"时间表 {source_plan_id} 第 {layout_index + 1} 项 StartSecond")
    end_time = normalize_time(layout.get("EndSecond"), f"时间表 {source_plan_id} 第 {layout_index + 1} 项 EndSecond")
    try:
        time_type = int(layout.get("TimeType", CLASSISLAND_TIME_TYPE_CLASS))
    except (TypeError, ValueError) as exc:
        raise ConversionError(f"时间表 {source_plan_id} 第 {layout_index + 1} 项的 TimeType 无效") from exc

    entry: dict[str, Any] = {
        "id": f"ci-{source_plan_id}-{layout_index + 1}",
        "startTime": start_time,
        "endTime": end_time,
    }
    if time_type == CLASSISLAND_TIME_TYPE_CLASS:
        subject_id = assigned_subject_id or str(layout.get("DefaultClassId", "")).strip() or None
        if subject_id:
            entry.update({"type": "class", "subjectId": subject_id})
        else:
            entry.update({"type": "free", "title": "未安排课程"})
            report.add_warning(f"课表 {source_plan_id} 第 {layout_index + 1} 个课程时段未分配科目，已转换为空闲时段")
    elif time_type == CLASSISLAND_TIME_TYPE_BREAK:
        entry.update({"type": "break", "title": str(layout.get("Name", "休息")).strip() or "休息"})
    else:
        entry.update({"type": "activity", "title": str(layout.get("Name", "活动")).strip() or "活动"})
        report.add_warning(
            f"时间表 {source_plan_id} 第 {layout_index + 1} 项 TimeType={time_type} 已转换为 CW 活动时段"
        )
    return entry


def convert_class_plans(
    raw_class_plans: dict[str, Any],
    raw_time_layouts: dict[str, Any],
    known_subject_ids: set[str],
    report: ConversionReport,
    *,
    include_disabled: bool,
    include_overlays: bool,
) -> list[dict[str, Any]]:
    timelines: list[dict[str, Any]] = []
    for plan_id, raw_plan in raw_class_plans.items():
        if not isinstance(raw_plan, dict):
            report.add_warning(f"已跳过无效课表：{plan_id}")
            continue
        if not include_disabled and not bool(raw_plan.get("IsEnabled", False)):
            report.skipped_disabled_plans += 1
            continue
        if bool(raw_plan.get("IsOverlay", False)) and not include_overlays:
            report.skipped_overlays += 1
            report.add_warning(f"已跳过覆盖课表：{raw_plan.get('Name') or plan_id}")
            continue

        layout_id = str(raw_plan.get("TimeLayoutId", "")).strip()
        raw_layout = raw_time_layouts.get(layout_id)
        if not isinstance(raw_layout, dict):
            report.add_warning(f"已跳过课表 {raw_plan.get('Name') or plan_id}：找不到时间表 {layout_id}")
            continue
        layouts = raw_layout.get("Layouts", [])
        if not isinstance(layouts, list):
            report.add_warning(f"已跳过课表 {raw_plan.get('Name') or plan_id}：时间表 {layout_id} 的 Layouts 无效")
            continue

        time_rule = raw_plan.get("TimeRule", {})
        if not isinstance(time_rule, dict):
            report.add_warning(f"已跳过课表 {raw_plan.get('Name') or plan_id}：TimeRule 无效")
            continue
        try:
            day_of_week = map_day_of_week(time_rule.get("WeekDay"))
            weeks = map_weeks(time_rule.get("WeekCountDiv", 0))
        except ConversionError as exc:
            report.add_warning(f"已跳过课表 {raw_plan.get('Name') or plan_id}：{exc}")
            continue

        classes = raw_plan.get("Classes", [])
        if not isinstance(classes, list):
            classes = []
            report.add_warning(f"课表 {raw_plan.get('Name') or plan_id} 的 Classes 无效，未分配课程将转为空闲时段")
        class_subject_ids: list[str | None] = []
        for class_item in classes:
            subject_id = str(class_item.get("SubjectId", "")).strip() if isinstance(class_item, dict) else ""
            if subject_id and subject_id not in known_subject_ids:
                report.add_warning(f"课表 {raw_plan.get('Name') or plan_id} 引用了不存在的科目 {subject_id}，该时段将转为空闲")
                subject_id = ""
            class_subject_ids.append(subject_id or None)

        class_cursor = 0
        entries: list[dict[str, Any]] = []
        for layout_index, layout_item in enumerate(layouts):
            if not isinstance(layout_item, dict):
                report.add_warning(f"课表 {raw_plan.get('Name') or plan_id} 的第 {layout_index + 1} 个时间段无效，已跳过")
                continue
            try:
                time_type = int(layout_item.get("TimeType", CLASSISLAND_TIME_TYPE_CLASS))
            except (TypeError, ValueError):
                time_type = CLASSISLAND_TIME_TYPE_CLASS
            assigned_subject_id = None
            if time_type == CLASSISLAND_TIME_TYPE_CLASS:
                if class_cursor < len(class_subject_ids):
                    assigned_subject_id = class_subject_ids[class_cursor]
                class_cursor += 1
            entries.append(entry_for_layout(layout_item, str(plan_id), layout_index, assigned_subject_id, report))

        if class_cursor < len(class_subject_ids):
            report.add_warning(
                f"课表 {raw_plan.get('Name') or plan_id} 有 {len(class_subject_ids) - class_cursor} 个课程未对应到时间段，已忽略"
            )
        timelines.append(
            {
                "id": f"ci-{plan_id}",
                "dayOfWeek": [day_of_week],
                "weeks": weeks,
                "entries": entries,
            }
        )
        report.entries += len(entries)
    report.timelines = len(timelines)
    return timelines


def convert_classisland_archive(
    subjects_archive: dict[str, Any],
    time_layouts_archive: dict[str, Any],
    class_plans_archive: dict[str, Any],
    *,
    schedule_id: str,
    start_date: str,
    max_week_cycle: int,
    include_disabled: bool = False,
    include_overlays: bool = False,
) -> tuple[dict[str, Any], ConversionReport]:
    """将三份 ClassIsland 档案转换为可由 CW ScheduleData 校验的 JSON 对象。"""
    if max_week_cycle < 1:
        raise ConversionError("max_week_cycle 必须大于或等于 1")
    try:
        datetime.strptime(start_date, "%Y-%m-%d")
    except ValueError as exc:
        raise ConversionError("start_date 必须使用 YYYY-MM-DD 格式") from exc
    schedule_id = schedule_id.strip()
    if not schedule_id:
        raise ConversionError("schedule_id 不能为空")

    report = ConversionReport()
    raw_subjects = require_mapping(subjects_archive, "Subjects", "subjects 档案")
    raw_time_layouts = require_mapping(time_layouts_archive, "TimeLayouts", "timelayouts 档案")
    raw_class_plans = require_mapping(class_plans_archive, "ClassPlans", "classplans 档案")
    subjects = convert_subjects(raw_subjects, report)
    known_subject_ids = {subject["id"] for subject in subjects}
    days = convert_class_plans(
        raw_class_plans,
        raw_time_layouts,
        known_subject_ids,
        report,
        include_disabled=include_disabled,
        include_overlays=include_overlays,
    )
    schedule = {
        "meta": {
            "id": schedule_id,
            "version": SCHEDULE_SCHEMA_VERSION,
            "maxWeekCycle": max_week_cycle,
            "startDate": start_date,
        },
        "subjects": subjects,
        "days": days,
        "overrides": [],
    }
    return schedule, report


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="将 ClassIsland 的 subjects.json、timelayouts.json、classplans.json 转换为 CW 课程表 JSON。"
    )
    parser.add_argument("--subjects", required=True, type=Path, help="ClassIsland subjects.json 路径")
    parser.add_argument("--time-layouts", required=True, type=Path, help="ClassIsland timelayouts.json 路径")
    parser.add_argument("--class-plans", required=True, type=Path, help="ClassIsland classplans.json 路径")
    parser.add_argument("--output", required=True, type=Path, help="输出 CW 课程表 JSON 路径")
    parser.add_argument("--schedule-id", required=True, help="输出 CW 课程表 meta.id")
    parser.add_argument("--start-date", required=True, help="课程表第一周的周一日期，格式 YYYY-MM-DD")
    parser.add_argument("--max-week-cycle", type=int, default=2, help="CW 最大周循环数，默认 2")
    parser.add_argument("--include-disabled", action="store_true", help="同时转换 ClassIsland 中未启用的课表")
    parser.add_argument("--include-overlays", action="store_true", help="同时转换 ClassIsland 覆盖课表；覆盖语义不会保留")
    parser.add_argument("--strict", action="store_true", help="存在转换警告时返回非零状态，不写入输出")
    return parser


def print_report(report: ConversionReport) -> None:
    print(
        f"转换完成：{report.subjects} 个科目、{report.timelines} 个时间线、"
        f"{report.entries} 个时段。"
    )
    if report.skipped_disabled_plans:
        print(f"已跳过 {report.skipped_disabled_plans} 个未启用课表。")
    if report.skipped_overlays:
        print(f"已跳过 {report.skipped_overlays} 个覆盖课表。")
    for warning in report.warnings:
        print(f"警告：{warning}", file=sys.stderr)


def main() -> int:
    parser = build_argument_parser()
    args = parser.parse_args()
    try:
        schedule, report = convert_classisland_archive(
            read_json_object(args.subjects, "subjects"),
            read_json_object(args.time_layouts, "timelayouts"),
            read_json_object(args.class_plans, "classplans"),
            schedule_id=args.schedule_id,
            start_date=args.start_date,
            max_week_cycle=args.max_week_cycle,
            include_disabled=args.include_disabled,
            include_overlays=args.include_overlays,
        )
        print_report(report)
        if args.strict and report.warnings:
            print("严格模式下存在转换警告，未写入输出。", file=sys.stderr)
            return 2
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(schedule, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"已写入：{args.output}")
        return 0
    except ConversionError as exc:
        print(f"转换失败：{exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
