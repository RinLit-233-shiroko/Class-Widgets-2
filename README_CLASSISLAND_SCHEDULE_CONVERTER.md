# ClassIsland 课表档案转换为 CW 课程表

`scripts/convert_classisland_schedule.py` 可以将 ClassIsland 课表档案中的 `subjects.json`、`timelayouts.json` 和 `classplans.json` 转换为 ClassWidgets（CW）当前可读取的课程表 JSON。

> 转换器处理的是课程表核心数据：**科目、上课/休息时间段、课程安排、星期以及单双周**。ClassIsland 的通知、插件附加对象、集控策略、覆盖课表语义和其他应用专属配置不会写入 CW 输出。

## 准备输入文件

ClassIsland 的课表档案将科目、时间表和课表拆分保存。请从 ClassIsland 档案或集控文件中准备以下三份 JSON：

| 输入文件 | ClassIsland 顶层字段 | 用途 |
|---|---|---|
| `subjects.json` | `Subjects` | 科目名称、简称、教师与室内/室外状态。 |
| `timelayouts.json` | `TimeLayouts` | 每日各时间段的开始、结束与类型。 |
| `classplans.json` | `ClassPlans` | 每天、单双周对应的时间表和课程顺序。 |

ClassIsland 官方的静态集控教程也使用这三类档案分开分发。[1]

## 基本用法

在 CW 仓库根目录执行：

```bash
python3 scripts/convert_classisland_schedule.py \
  --subjects /path/to/subjects.json \
  --time-layouts /path/to/timelayouts.json \
  --class-plans /path/to/classplans.json \
  --output /path/to/cw-schedule.json \
  --schedule-id classisland-import \
  --start-date 2026-09-01 \
  --max-week-cycle 2
```

`--start-date` 是 CW 课程表第一周的周一日期，必须使用 `YYYY-MM-DD`。`--max-week-cycle` 是 CW 的最大周循环数；只使用单双周时通常填 `2`。

成功时脚本会输出转换后的科目、时间线和时段数量，并写入指定 JSON 文件。输出文件可在 CW 的课程表编辑功能中导入，也可计算 SHA-256 后作为集控课程表文件发布。

## 可选参数

| 参数 | 默认行为 | 适用情况 |
|---|---|---|
| `--include-disabled` | 跳过 ClassIsland 未启用的课表。 | 希望把暂时禁用的课表也一并迁移时使用。 |
| `--include-overlays` | 跳过覆盖课表。 | 仅用于检查内容；CW 不会保留 ClassIsland 覆盖课表的优先级语义。 |
| `--strict` | 有警告仍写出结果。 | 需要确保没有任何降级映射、缺失科目或未支持内容时使用；有警告则不生成输出并返回状态码 `2`。 |

## 字段映射

| ClassIsland 字段 | CW 字段 | 说明 |
|---|---|---|
| `Subjects.<id>.Name` | `subjects[].name` | 保留科目名称。 |
| `Subjects.<id>.Initial` | `subjects[].simplifiedName` | 保留简称；空值不写入。 |
| `Subjects.<id>.TeacherName` | `subjects[].teacher` | 保留教师名称；空值不写入。 |
| `Subjects.<id>.IsOutDoor` | `subjects[].isLocalClassroom` | 取反后写入；室外课程标记为非本班教室。 |
| `TimeLayouts.<id>.Layouts[].StartSecond/EndSecond` | `entries[].startTime/endTime` | ISO 8601 时间转为 `HH:MM`。 |
| `TimeType = 0` | `class` | 按 `Classes` 中的顺序绑定科目；未绑定时转为 `free`。 |
| `TimeType = 1` | `break` | 生成标题为“休息”的 CW 休息时段。 |
| 其他 `TimeType` | `activity` | 生成 CW 活动时段，并产生警告。 |
| `TimeRule.WeekDay` | `dayOfWeek` | ClassIsland 的 `0=周日` 转为 CW 的 `7=周日`；`1–6` 保持对应周一至周六。 |
| `TimeRule.WeekCountDiv = 0/1/2` | `weeks = all/[1]/[2]` | 分别映射每周、单周和双周。 |

## 未转换内容

转换器会忽略 ClassIsland 专属的 `AttachedObjects`、通知配置、插件配置、策略、`IsActive`、集控信息和覆盖课表优先级。对于以下情况，脚本会打印警告：科目不存在、课程数量与时间段不匹配、未找到时间表、未支持的周循环值，或非标准时间段类型。

建议首次转换使用 `--strict`。若出现警告，请先在 ClassIsland 中修正相应档案，或确认该降级映射符合预期后再不使用严格模式生成输出。

## 转换后校验与集控发布

转换完成后，可使用 CW 当前 Schema 验证结果：

```bash
PYTHONPATH=. python3 - <<'PY'
import json
from src.core.schedule.model import ScheduleData

with open("cw-schedule.json", encoding="utf-8") as file:
    ScheduleData.model_validate(json.load(file))
print("CW 课程表 Schema 校验通过")
PY
```

若要通过 CW 集控发布，计算文件 SHA-256 并写入 `manifest.json` 中对应课程表的 `sha256` 字段。完整部署方式请参阅仓库内的 [集控部署与使用说明](README_CENTRAL_CONTROL.md)。

## 验证转换器

仓库内含有覆盖核心映射、单双周、禁用课表、覆盖课表、CLI 输出和 CW Schema 的回归验证：

```bash
PYTHONPATH=. python3 scripts/verify_classisland_schedule_converter.py
```

## References

[1]: https://docs.classisland.tech/management/tutorial-create-management-config/ "ClassIsland：手动编写集控配置文件"
