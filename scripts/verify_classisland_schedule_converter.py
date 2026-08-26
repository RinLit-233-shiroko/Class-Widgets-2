from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from src.core.schedule.model import ScheduleData


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CONVERTER_PATH = PROJECT_ROOT / "scripts" / "convert_classisland_schedule.py"


def load_converter_module():
    spec = importlib.util.spec_from_file_location("classisland_converter", CONVERTER_PATH)
    if spec is None or spec.loader is None:
        raise AssertionError("unable to import ClassIsland converter")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def fixture_archives() -> tuple[dict, dict, dict]:
    subjects = {
        "Subjects": {
            "math": {"Name": "数学", "Initial": "数", "TeacherName": "张老师", "IsOutDoor": False},
            "sport": {"Name": "体育", "Initial": "体", "TeacherName": "李老师", "IsOutDoor": True},
        }
    }
    time_layouts = {
        "TimeLayouts": {
            "weekday": {
                "Name": "工作日",
                "Layouts": [
                    {
                        "StartSecond": "2026-09-01T08:00:00+08:00",
                        "EndSecond": "2026-09-01T08:40:00+08:00",
                        "TimeType": 0,
                        "DefaultClassId": "math",
                    },
                    {
                        "StartSecond": "2026-09-01T08:40:00+08:00",
                        "EndSecond": "2026-09-01T08:50:00+08:00",
                        "TimeType": 1,
                    },
                    {
                        "StartSecond": "2026-09-01T08:50:00+08:00",
                        "EndSecond": "2026-09-01T09:30:00+08:00",
                        "TimeType": 0,
                    },
                    {
                        "StartSecond": "2026-09-01T09:30:00+08:00",
                        "EndSecond": "2026-09-01T09:35:00+08:00",
                        "TimeType": 2,
                        "Name": "晨会",
                    },
                ],
            }
        }
    }
    class_plans = {
        "ClassPlans": {
            "monday": {
                "Name": "周一",
                "TimeLayoutId": "weekday",
                "TimeRule": {"WeekDay": 1, "WeekCountDiv": 0},
                "Classes": [{"SubjectId": "math"}, {"SubjectId": "sport"}],
                "IsEnabled": True,
                "IsOverlay": False,
            },
            "sunday-even": {
                "Name": "周日双周",
                "TimeLayoutId": "weekday",
                "TimeRule": {"WeekDay": 0, "WeekCountDiv": 2},
                "Classes": [{"SubjectId": "sport"}, {"SubjectId": "math"}],
                "IsEnabled": True,
                "IsOverlay": False,
            },
            "disabled": {
                "Name": "未启用",
                "TimeLayoutId": "weekday",
                "TimeRule": {"WeekDay": 2, "WeekCountDiv": 0},
                "Classes": [],
                "IsEnabled": False,
                "IsOverlay": False,
            },
            "overlay": {
                "Name": "覆盖课表",
                "TimeLayoutId": "weekday",
                "TimeRule": {"WeekDay": 3, "WeekCountDiv": 0},
                "Classes": [],
                "IsEnabled": True,
                "IsOverlay": True,
            },
        }
    }
    return subjects, time_layouts, class_plans


def test_conversion_model() -> None:
    converter = load_converter_module()
    subjects, time_layouts, class_plans = fixture_archives()
    converted, report = converter.convert_classisland_archive(
        subjects,
        time_layouts,
        class_plans,
        schedule_id="from-classisland",
        start_date="2026-09-01",
        max_week_cycle=2,
    )
    ScheduleData.model_validate(converted)

    assert converted["meta"] == {
        "id": "from-classisland",
        "version": 1,
        "maxWeekCycle": 2,
        "startDate": "2026-09-01",
    }
    assert converted["subjects"] == [
        {"id": "math", "name": "数学", "simplifiedName": "数", "teacher": "张老师", "isLocalClassroom": True},
        {"id": "sport", "name": "体育", "simplifiedName": "体", "teacher": "李老师", "isLocalClassroom": False},
    ]
    assert len(converted["days"]) == 2
    monday, sunday_even = converted["days"]
    assert monday["dayOfWeek"] == [1]
    assert monday["weeks"] == "all"
    assert sunday_even["dayOfWeek"] == [7]
    assert sunday_even["weeks"] == [2]
    assert [entry["type"] for entry in monday["entries"]] == ["class", "break", "class", "activity"]
    assert [entry.get("subjectId") for entry in monday["entries"]] == ["math", None, "sport", None]
    assert [entry["startTime"] for entry in monday["entries"]] == ["08:00", "08:40", "08:50", "09:30"]
    assert report.subjects == 2
    assert report.timelines == 2
    assert report.entries == 8
    assert report.skipped_disabled_plans == 1
    assert report.skipped_overlays == 1
    assert any("TimeType=2" in warning for warning in report.warnings)


def test_cli_writes_valid_schedule() -> None:
    subjects, time_layouts, class_plans = fixture_archives()
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        subjects_path = temp_path / "subjects.json"
        time_layouts_path = temp_path / "timelayouts.json"
        class_plans_path = temp_path / "classplans.json"
        output_path = temp_path / "cw-schedule.json"
        for path, payload in (
            (subjects_path, subjects),
            (time_layouts_path, time_layouts),
            (class_plans_path, class_plans),
        ):
            path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
        completed = subprocess.run(
            [
                "python3",
                str(CONVERTER_PATH),
                "--subjects", str(subjects_path),
                "--time-layouts", str(time_layouts_path),
                "--class-plans", str(class_plans_path),
                "--output", str(output_path),
                "--schedule-id", "cli-schedule",
                "--start-date", "2026-09-01",
            ],
            check=False,
            text=True,
            capture_output=True,
        )
        assert completed.returncode == 0, completed.stderr
        output = json.loads(output_path.read_text(encoding="utf-8"))
        ScheduleData.model_validate(output)
        assert output["meta"]["id"] == "cli-schedule"
        assert "转换完成：2 个科目、2 个时间线、8 个时段。" in completed.stdout

        strict_output = temp_path / "strict.json"
        strict = subprocess.run(
            [
                "python3",
                str(CONVERTER_PATH),
                "--subjects", str(subjects_path),
                "--time-layouts", str(time_layouts_path),
                "--class-plans", str(class_plans_path),
                "--output", str(strict_output),
                "--schedule-id", "strict-schedule",
                "--start-date", "2026-09-01",
                "--strict",
            ],
            check=False,
            text=True,
            capture_output=True,
        )
        assert strict.returncode == 2
        assert not strict_output.exists()


def test_invalid_week_count_is_reported() -> None:
    converter = load_converter_module()
    subjects, time_layouts, class_plans = fixture_archives()
    class_plans["ClassPlans"]["monday"]["TimeRule"]["WeekCountDiv"] = 3
    converted, report = converter.convert_classisland_archive(
        subjects,
        time_layouts,
        class_plans,
        schedule_id="invalid-week-count",
        start_date="2026-09-01",
        max_week_cycle=2,
    )
    assert len(converted["days"]) == 1
    assert converted["days"][0]["id"] == "ci-sunday-even"
    assert any("WeekCountDiv=3" in warning for warning in report.warnings)


def main() -> None:
    test_conversion_model()
    test_cli_writes_valid_schedule()
    test_invalid_week_count_is_reported()
    print("ClassIsland schedule converter verification passed.")


if __name__ == "__main__":
    main()
