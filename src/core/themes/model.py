from __future__ import annotations

from typing import NotRequired, Optional, TypedDict

from PySide6.QtCore import QUrl


type JsonScalar = Optional[str | int | float | bool]
type JsonData = JsonScalar | dict[str, "JsonData"] | list["JsonData"]


class ThemeMeta(TypedDict, total=False):
    id: str
    name: str
    description: str
    version: str
    api_version: str
    author: str
    preview: Optional[QUrl | str]
    _type: str
    _path: str
    _compatible: bool


class ThemeConflict(TypedDict):
    id: str
    name: str
    version: str
    existing_version: str
    meta: dict[str, JsonData]
    zip_path: NotRequired[str]


class ThemeImportResult(TypedDict):
    new_themes: list[str]
    updated_themes: list[str]
    all_imported: list[str]
