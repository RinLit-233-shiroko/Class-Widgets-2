# Class Widgets 2 集控部署与使用指南

本指南说明如何用 **GitHub Pages + GitHub Actions** 为 Class Widgets 2（以下简称 **CW**）部署拉取式集控。当前集控可以安全地下发经 SHA-256 校验的课程表，并向客户端发送一次性公告通知；它**不是**常驻服务，也不支持服务器主动推送、远程重启或执行任意命令。[1] [3]

> **适用版本。** 本文对应仓库中 `CentralControlScheduleService` 的 `schemaVersion: 1` 协议。客户端默认不预填集控地址，默认关闭自动拉取，自动拉取默认间隔为 15 分钟。[3] [4]

## 目录

1. [工作原理与边界](#工作原理与边界)
2. [快速部署](#快速部署)
3. [集控清单与课程表](#集控清单与课程表)
4. [CW 客户端配置](#cw-客户端配置)
5. [通过 GitHub Actions 发布一次性公告](#通过-github-actions-发布一次性公告)
6. [验证、更新和排障](#验证更新和排障)
7. [安全建议与协议速查](#安全建议与协议速查)

---

## 工作原理与边界

GitHub Pages 只托管静态文件；CW 通过 HTTP 主动读取 `manifest.json`，再根据清单下载课程表。因此它属于**拉取式集控**：手动模式只在用户点击按钮时请求，自动模式则在应用启动后立即检查一次，并按设置的周期继续检查。它不能以 WebSocket 或通知推送的方式实时主动到达客户端。[1] [3]

| 环节 | 责任 | 说明 |
|---|---|---|
| 集控仓库 | 管理员 | 保存 `manifest.json`、课程表 JSON 和可选的 Actions 工作流。 |
| GitHub Pages | 静态托管 | 将仓库文件公开为 HTTPS 地址，例如 `https://OWNER.github.io/REPOSITORY/manifest.json`。 |
| CW 客户端 | 拉取与校验 | 下载清单和课程表，验证格式、大小、SHA-256 与课程表架构后才应用。 |
| GitHub Actions | 可选自动化 | 生成带新命令 ID 的公告清单，并可部署 Pages。 |

> **重要：一次检查不等于实时推送。** 将自动间隔设置为 1 分钟可以缩短延迟，但会增加请求次数，也不能消除 Pages 发布和 CDN 缓存带来的延迟。若需要秒级消息、设备在线状态或双向控制，应另行部署受认证保护的实时 API/WebSocket 服务。

当前客户端仅接受 `announcement` 公告命令。未实现且不会执行远程重启、运行脚本、修改系统设置等高风险命令。[3]

---

## 快速部署

### 1. 创建仓库与目录

创建一个专用仓库，例如 `cw-central-control`。若使用 GitHub Free，请将准备通过 GitHub Pages 对外提供文件的仓库设为公开；GitHub Pages 公开的内容可被互联网访问，不要将账号密钥、学生信息或其他敏感数据提交进去。[1]

推荐目录如下：

```text
cw-central-control/
├── manifest.json
├── schedules/
│   └── class-schedule.json
└── .github/
    ├── scripts/
    │   └── publish_announcement.py
    └── workflows/
        └── publish-announcement.yml
```

先在 CW 中导出或准备一个**当前客户端能够正常读取的课程表 JSON**，保存为 `schedules/class-schedule.json`。不要手工猜测课程表结构；课程表会由客户端按当前 `ScheduleData` 模型和 `meta.version` 校验。[3]

### 2. 计算课程表 SHA-256

`manifest.json` 必须写入课程表文件当前字节内容的 SHA-256。课程表任何改动，包括仅重新格式化 JSON，都要重新计算哈希并更新清单。[3]

| 系统 | 命令 |
|---|---|
| Linux / macOS / Git Bash | `sha256sum schedules/class-schedule.json` |
| Windows PowerShell | `Get-FileHash .\schedules\class-schedule.json -Algorithm SHA256` |

例如，Linux/macOS 输出的第一列即为要写入 `sha256` 的 64 位十六进制值：

```text
92a114111c9212fc0e0bd22ad3b395e70a976f1cba55cacc244edf9b729ee57d
```

### 3. 创建集控清单

在仓库根目录创建 `manifest.json`。其中 `url` 可以是相对路径；客户端会相对于清单 URL 解析它，因此同一份清单也可在 Pages 或 GitHub Raw 地址下使用。[3]

```json
{
  "schemaVersion": 1,
  "policyVersion": "2026-08-26-001",
  "schedule": {
    "id": "class-schedule",
    "name": "高一三班课程表",
    "url": "schedules/class-schedule.json",
    "sha256": "92a114111c9212fc0e0bd22ad3b395e70a976f1cba55cacc244edf9b729ee57d",
    "scheduleSchemaVersion": 1
  },
  "commands": []
}
```

提交并推送这些文件：

```bash
git add manifest.json schedules/class-schedule.json
git commit -m "feat: publish central-control schedule"
git push origin main
```

### 4. 启用 GitHub Pages

在仓库网页中依次打开 **Settings → Pages**，选择发布源。最简单的方式是选择 `Deploy from a branch`，然后选择 `main` 分支和 `/(root)` 文件夹；也可以选择 `GitHub Actions`，使用后文的部署步骤。GitHub Pages 发布的是静态文件，发布完成后可从 Pages 页面取得站点地址。[1]

若仓库为 `OWNER/cw-central-control`，通常使用以下完整清单地址：

```text
https://OWNER.github.io/cw-central-control/manifest.json
```

例如本项目的测试地址为：

```text
https://mmckb.github.io/Test/manifest.json
```

> **不要只填写站点根地址。** CW 当前需要的是完整的 `manifest.json` URL，而不是 `https://OWNER.github.io/REPOSITORY`。

---

## 集控清单与课程表

### 清单字段

| 字段 | 必填 | 规则与用途 |
|---|---:|---|
| `schemaVersion` | 是 | 必须为整数 `1`。 |
| `policyVersion` | 建议 | 用于在 CW 设置页标识当前策略版本，可使用日期、Git 提交号或公告 ID。 |
| `schedule` | 是 | 课程表描述对象。 |
| `schedule.id` | 是 | 仅允许字母、数字、`-`、`_`，长度 1–64；本地缓存名为 `central_<id>.json`。 |
| `schedule.name` | 建议 | 设置页中显示的课程表名称。 |
| `schedule.url` | 是 | 课程表 JSON 的相对或绝对 HTTP(S) 地址。 |
| `schedule.sha256` | 是 | 课程表内容的 64 位小写十六进制 SHA-256。 |
| `schedule.scheduleSchemaVersion` | 建议 | 便于管理员记录课程表版本；实际以课程表 JSON 内的 `meta.version` 为准。 |
| `commands` | 否 | 公告命令数组；省略或设为 `[]` 表示不下发公告。 |

客户端会依次验证清单版本、课程表标识、HTTP 状态、课程表大小（最多 2 MB）、SHA-256、UTF-8 JSON 和课程表架构版本。任何一步失败时，课程表与公告都不会应用。[3]

### 更新课程表的标准流程

每次变更课程表后，按以下顺序操作：

```bash
# 1) 替换为从 CW 导出的课程表 JSON
cp /path/to/exported-schedule.json schedules/class-schedule.json

# 2) 重新计算 SHA-256
sha256sum schedules/class-schedule.json

# 3) 将输出的哈希写入 manifest.json 的 schedule.sha256
# 4) 增加 policyVersion，例如 2026-08-26-002
# 5) 提交和推送
git add schedules/class-schedule.json manifest.json
git commit -m "feat: update central-control schedule"
git push
```

拉取成功后，CW 使用原子写入把课程表保存到本地课程表目录，并切换为 `central_<schedule.id>`。如果要回到本地课程表，可在课程表管理中选择原来的课程表。[3]

---

## CW 客户端配置

在 CW 设置中打开独立的 **集控** 页面，填写完整清单地址。地址默认是空的，不会预填任何公开地址。

| 模式 | 操作 | 网络行为 |
|---|---|---|
| 手动拉取 | 关闭“自动拉取集控内容”，点击“检查并应用集控内容” | 仅点击时请求网络。 |
| 自动拉取 | 开启“自动拉取集控内容”，设置 1–1440 分钟间隔 | 开启或应用启动时立即检查一次，随后按间隔检查。 |

建议先在**手动拉取**模式下验证地址和 SHA-256，再按设备规模设置自动间隔。若地址为空、不是 `http://`/`https://`，或服务器返回无效内容，设置页会显示失败原因。[3]

GitHub Raw 也可以作为清单地址，例如：

```text
https://raw.githubusercontent.com/OWNER/cw-central-control/main/manifest.json
```

不过推荐 GitHub Pages，因为其用途就是公开托管静态站点文件；Pages 地址也更适合作为稳定的管理员配置项。[1]

---

## 通过 GitHub Actions 发布一次性公告

### 公告命令格式

当前客户端只接受 `announcement` 类型。每台客户端会把已执行的公告 ID 记录在本地配置中，因此**同一个 ID 只会显示一次**；最多保留最近 100 个已执行 ID。使用新的 ID 即可让一次新的公告在每台尚未执行该 ID 的设备上显示一次。[3]

```json
{
  "id": "announcement-20260826-001",
  "type": "announcement",
  "title": "集控公告",
  "message": "明天第一节课改为班会，请提前到教室。",
  "duration": 8000,
  "expiresAt": "2026-08-27T12:00:00Z"
}
```

| 字段 | 限制 |
|---|---|
| `id` | 必填；仅允许字母、数字、`-`、`_`，长度 1–80；每次公告必须新建。 |
| `type` | 必填；当前只能是 `announcement`。 |
| `title` | 必填；最多 80 个字符。 |
| `message` | 必填；最多 500 个字符。 |
| `duration` | 可选；毫秒；客户端会限制在 1000–60000，默认 8000。 |
| `expiresAt` | 建议；ISO 8601 UTC 时间，例如 `2026-08-27T12:00:00Z`；过期命令会被跳过。 |

一份清单最多可包含 20 条命令。为了避免旧公告干扰，推荐每次发布后让 `commands` 只保留这一次待下发的公告，并设置合理过期时间。[3]

### 1. 添加公告生成脚本

将下面文件保存为 `.github/scripts/publish_announcement.py`。它每次运行都会用 `GITHUB_RUN_ID` 生成新的公告 ID，并默认将公告设置为 24 小时后过期。

```python
from __future__ import annotations

import argparse
import json
import os
from datetime import datetime, timedelta, timezone
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description="发布一次性 ClassWidgets 集控公告")
    parser.add_argument("--title", required=True)
    parser.add_argument("--message", required=True)
    parser.add_argument("--duration", type=int, default=8000)
    args = parser.parse_args()

    title = args.title.strip()
    message = args.message.strip()
    if not title or not message:
        raise SystemExit("公告标题和内容不能为空")
    if len(title) > 80 or len(message) > 500:
        raise SystemExit("公告标题或内容超过 CW 客户端限制")

    duration = max(1000, min(args.duration, 60000))
    run_id = os.environ.get(
        "GITHUB_RUN_ID",
        datetime.now(timezone.utc).strftime("%Y%m%d%H%M%S"),
    )
    expires_at = datetime.now(timezone.utc) + timedelta(days=1)

    manifest_path = Path("manifest.json")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["policyVersion"] = f"announcement-{run_id}"
    manifest["commands"] = [{
        "id": f"announcement-{run_id}",
        "type": "announcement",
        "title": title,
        "message": message,
        "duration": duration,
        "expiresAt": expires_at.isoformat().replace("+00:00", "Z"),
    }]
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
```

### 2. 添加手动发布工作流

将下面文件保存为 `.github/workflows/publish-announcement.yml`。管理员可在仓库 **Actions → 发布集控公告 → Run workflow** 中填写标题、内容和显示时长。`workflow_dispatch` 工作流必须位于默认分支，且执行者需要仓库写入权限。[2]

```yaml
name: 发布集控公告

on:
  workflow_dispatch:
    inputs:
      title:
        description: 公告标题
        required: true
        default: 集控公告
        type: string
      message:
        description: 公告内容
        required: true
        type: string
      duration:
        description: 显示时长（毫秒，1000 至 60000）
        required: true
        default: "8000"
        type: string

permissions:
  contents: write

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - name: 检出仓库
        uses: actions/checkout@v4

      - name: 更新公告命令
        env:
          ANNOUNCEMENT_TITLE: ${{ inputs.title }}
          ANNOUNCEMENT_MESSAGE: ${{ inputs.message }}
          ANNOUNCEMENT_DURATION: ${{ inputs.duration }}
        run: >-
          python .github/scripts/publish_announcement.py
          --title "$ANNOUNCEMENT_TITLE"
          --message "$ANNOUNCEMENT_MESSAGE"
          --duration "$ANNOUNCEMENT_DURATION"

      - name: 提交清单
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add manifest.json
          git diff --cached --quiet || git commit -m "chore: publish central-control announcement"
          git push
```

> **安全实践。** 不要把 `${{ inputs.message }}` 直接拼接进 Shell 命令；如示例所示，通过 `env` 将用户输入交给脚本，再在 Python 中进行长度与空值校验，可以避免常见的 Shell 注入与转义问题。

### 3. 将 Action 与 Pages 发布连通

如果 Pages 的发布源是分支，先确认一次普通推送能更新 `manifest.json`。GitHub 官方说明指出：使用 `GITHUB_TOKEN` 的工作流推送不会触发另一条常规 Pages 构建工作流；若发现 Actions 已提交新清单但 Pages 地址仍是旧版本，请改用 **GitHub Actions** 作为 Pages 发布源，或在同一工作流内显式部署 Pages。[1]

以下是在上述公告工作流末尾增加的推荐部署步骤。启用前请在 **Settings → Pages** 中选择 **GitHub Actions** 作为发布源，并把工作流的 `permissions` 扩展为 `contents: write`、`pages: write` 和 `id-token: write`。

```yaml
      - name: 配置 Pages
        uses: actions/configure-pages@v5

      - name: 上传 Pages 文件
        uses: actions/upload-pages-artifact@v3
        with:
          path: .

      - name: 部署 Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

这三步应位于 `git push` 之后，且与前面的 `publish` 作业使用相同工作目录。这样每运行一次“发布集控公告”，都会生成新的命令 ID、更新仓库中的 `manifest.json`，并部署当前静态文件。

---

## 验证、更新和排障

### 发布前本地检查

确认 JSON 可被解析、清单中 SHA-256 与实际文件一致：

```bash
python -m json.tool manifest.json >/dev/null
python -m json.tool schedules/class-schedule.json >/dev/null
sha256sum schedules/class-schedule.json
```

### 发布后检查

将 `OWNER`、`REPOSITORY` 替换为自己的仓库信息：

```bash
curl --fail --location \
  "https://OWNER.github.io/REPOSITORY/manifest.json"
```

如果系统安装了 `jq`，可格式化查看：

```bash
curl --fail --location \
  "https://OWNER.github.io/REPOSITORY/manifest.json" | jq .
```

检查以下内容：

| 检查项 | 预期结果 |
|---|---|
| HTTP 状态 | `200 OK`。 |
| `schemaVersion` | 为 `1`。 |
| `schedule.url` | 能从浏览器直接访问或可由相对路径解析。 |
| `schedule.sha256` | 与最新课程表文件的 SHA-256 完全一致。 |
| `commands` | 无公告时为 `[]`；有公告时每项的 ID 唯一且未过期。 |
| CW 状态文字 | 显示已应用课程表；有新公告时显示已处理公告数量。 |

### 常见问题

| 现象 | 可能原因 | 处理方式 |
|---|---|---|
| CW 显示“请先填写集控地址” | 地址为空。 | 填写完整的 `manifest.json` HTTPS 地址。 |
| CW 显示“集控地址必须以 http:// 或 https:// 开头” | 粘贴了本地路径或漏掉协议。 | 使用完整的 `https://.../manifest.json`。 |
| SHA-256 校验失败 | 课程表修改后未更新清单哈希，或文件发布到错误路径。 | 重新计算哈希，更新 `manifest.json` 后再次推送。 |
| 课程表或公告都没有应用 | 清单、课程表或任一命令验证失败。 | 使用上面的 JSON 与 `curl` 检查；先修复全部字段再重试。 |
| Action 成功但 Pages 还是旧内容 | Pages 构建尚未完成，或 workflow 的推送未触发单独部署。 | 等待 Pages 部署完成；必要时按“将 Action 与 Pages 发布连通”改为显式部署。 |
| 公告没有再次弹出 | 客户端已执行过相同 `id`，或 `expiresAt` 已过期。 | 使用新的命令 ID，确认 UTC 过期时间仍在未来。 |
| 自动拉取没有请求 | 未开启自动拉取、地址为空，或应用未保持运行。 | 开启开关、填写地址，并检查间隔设置。 |

---

## 安全建议与协议速查

集控地址相当于课程表与公告的发布权限。建议使用单独仓库、最小化写入权限、受信任维护者和可审计的提交记录。GitHub Pages 内容公开可读，因此集控清单、课程表和公告中不应包含个人隐私、密钥、令牌、住址、学号等敏感数据。[1]

| 项目 | 当前限制 |
|---|---|
| 清单版本 | 仅 `schemaVersion: 1`。 |
| 请求协议 | 集控地址必须是 HTTP 或 HTTPS；推荐 HTTPS。 |
| 课程表大小 | 最大 2 MB。 |
| 课程表完整性 | 必须匹配清单中的 SHA-256。 |
| 课程表结构 | 必须通过 CW 当前课程表模型与 `meta.version` 校验。 |
| 命令数量 | 每份清单最多 20 条。 |
| 允许的命令 | 仅 `announcement`。 |
| 公告去重 | 每台客户端的相同命令 ID 只执行一次，保留最近 100 个 ID。 |
| 自动拉取间隔 | 1–1440 分钟；默认 15 分钟，默认关闭。 |

> **变更策略。** 对课程表更新，更新文件、哈希和 `policyVersion`；对公告更新，生成新的公告 `id` 和 `policyVersion`。不要复用命令 ID，也不要依赖 Pages 作为实时消息服务。

## 参考资料

[1]: https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site "GitHub Docs：创建 GitHub Pages 站点"
[2]: https://docs.github.com/actions/managing-workflow-runs/manually-running-a-workflow "GitHub Docs：手动运行工作流"
[3]: src/core/central_control.py "ClassWidgets 集控服务实现"
[4]: src/core/config/model.py "ClassWidgets 集控客户端默认配置"
