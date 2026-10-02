from __future__ import annotations

import sys
from typing import Optional, Sequence

#: 启动参数：不加载任何外部插件与主题（配置、课程表等用户数据照常读取）。
SAFE_MODE_ARGUMENT = "--safe-mode"


def safe_mode_requested(arguments: Optional[Sequence[str]] = None) -> bool:
    """是否要求以安全模式启动。"""
    args = sys.argv if arguments is None else arguments
    return SAFE_MODE_ARGUMENT in args
