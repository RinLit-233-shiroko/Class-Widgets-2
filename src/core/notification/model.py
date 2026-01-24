from enum import IntEnum
from pathlib import Path
from typing import Optional, Union, TypedDict
from pydantic import BaseModel, Field
from pathlib import Path


class NotificationLevel(IntEnum):
    INFO = 0          # 普通提示
    ANNOUNCEMENT = 1  # 上下课 / 状态
    WARNING = 2       # 更新 / 风险
    SYSTEM = 3        # 内部


class NotificationData(BaseModel):
    provider_id: str          # 来源 Provider ID
    level: int                # 实际由前端映射样式
    title: str
    message: Optional[str] = None
    icon: Optional[Union[str, Path]] = None  # 图标，支持字体图标名称或图片URI

    # 行为 & 展示
    duration: int = 4000      # ms，0 = 常驻
    closable: bool = True
    silent: bool = False      # 是否无声音
    use_system: bool = False # 系统通知 or 应用内


# 与 NotificationData 对应的字典结构
class NotificationPayload(TypedDict):
    provider_id: str
    level: int
    title: str
    message: Optional[str]
    icon: Optional[Union[str, Path]]
    duration: int
    closable: bool
    silent: bool
    use_system: bool

class NotificationProviderConfig(BaseModel):
    enabled: bool = True
    use_system_notify: bool = False
    use_app_notify: bool = True
