# Class-Widgets-2
**Class Widgets**™ 2 启动

<details>
<summary>简介</summary>

**Class Widgets 2** 是 **Class Widgets** 的重构版
旨在更好性能地提供更加强大的功能和更好的多媒体使用体验。

### 功能特点
- 课表

</details>


## 概述
**Class Widgets 2**开发进度：
- ~~[x] 新建项目并导入所需的库~~
- [x] 课表处理的基础逻辑
- [ ] 
- [ ] 

### 课表格式
**Class Widgets 2**使用了<u>[新的JSON课表格式](docs/templates/schedule_file/index.md)</u>
<details>
<summary>JSON课表模板</summary>
<pre>
<code>
{
  "meta": {
    "id": "",
    "version": 1,
    "maxWeekCycle": 2,
    "startDate": "2026-09-01"
  },
  
  "subjects": [
    {
      "id": "math",
      "name": "Mathematics",
      "teacher": "Prof. Smith",
      "icon": "ic_fluent_ruler_24_regular",
      "location": "Room 9101",
      "isLocalClassRoom": true
    }
  ],
  
  "days": [
    {
      "id": "Monday-All",
      "dayOfWeek": 1,
      "weeks": "all",
      "entries": [
        {
          "id": "",
          "type": "class",
          "subjectId": "math",
          "startTime": "10:00",
          "endTime": "12:00"
        },
        {
          "id": "",
          "type": "break",
          "title": "Break 1",
          "startTime": "10:00",
          "endTime": "12:00"
        },
        {
          "id": "",
          "type": "activity",
          "title": "Meeting",
          "startTime": "14:00",
          "endTime": "15:30"
        }
      ]
    },
    {
      "id": "Tuesday-Even",
      "dayOfWeek": 2,
      "weeks": [2],
      "entries": []
    },
    {
      "id": "2026-09-01",
      "date": "2026-09-01",
      "entries": []
    }
  ]
}
</code>
</pre>
</details>

### 下一步计划
还没想好qwq

## 鸣谢
### 贡献者
目前还没有贡献者。:cry:

### 依赖库
- PySide6
- RinUI(https://github.com/RinLit-233-shiroko/Rin-UI)

## 许可证
本项目采用 GNU 通用公共许可证 v3.0 (GPL-3.0) 许可证，
详情请见 [LICENSE](LICENSE) 文件。