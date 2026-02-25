from loguru import logger
from packaging.specifiers import SpecifierSet
from packaging.version import Version

from .json_loader import JsonLoader
from .calculator import get_cycle_week, get_week_number
from .tray import TrayIcon
from .subjects import DEFAULT_SUBJECTS, get_default_subjects, translate_sources
from .translator import AppTranslator
from .backend import UtilsBackend
from uuid import uuid4


# Parser
def generate_id(prefix: str = "id") -> str:
    return f"{prefix}_{uuid4().hex}"

def _parse_version(v: str):
    return tuple(int(p) for p in v.split('.') if p.isdigit())


import re

def is_valid_context_property_name(name: str) -> bool:
    # 只能包含字母数字和下划线，不能以数字开头，不能为空
    if not name:
        return False
    return bool(re.match(r'^[a-zA-Z_]\w*$', name))
