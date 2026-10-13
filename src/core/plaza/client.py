from __future__ import annotations

import re
from collections.abc import Callable
from urllib.parse import parse_qsl, quote, urlencode, urljoin, urlsplit, urlunsplit

import requests

from src import __version__, __version_type__
from src.core.utils.http_stream import call_interruptibly


PollCallback = Callable[[], None]

# 统一标识本客户端，方便广场侧与边缘防护识别真实客户端、
# 并把扫描器（伪装/无 UA 的脚本）与正常轮询区分开。
CLIENT_USER_AGENT = f"ClassWidgets/{__version__}-{__version_type__} (+https://cw.rinlit.cn)"

# 与广场侧 MAX_IDS 保持一致。
MAX_VERSIONS_IDS = 50
PLUGIN_ID_RE = re.compile(r"^[A-Za-z0-9._-]+$")


def _default_headers(*, plugin_protocol: bool = False) -> dict[str, str]:
    headers = {
        "User-Agent": CLIENT_USER_AGENT,
        "Accept": "application/json",
    }
    if plugin_protocol:
        headers["X-CW-Client-Version"] = __version__
    return headers


class PlazaClientError(RuntimeError):
    """Raised when the Extension Plaza API returns an invalid response."""


class PlazaClient:
    """Small synchronous API client used by background plugin tasks."""

    def __init__(self, base_url: str, *, timeout: tuple[float, float] = (10, 30)):
        self.base_url = base_url.strip().rstrip("/")
        if not self.base_url:
            raise PlazaClientError("Plugin plaza URL is not configured.")
        self.timeout = timeout

    def get_plugin(self, plugin_id: str, *, poll: PollCallback | None = None) -> dict:
        endpoint = f"{self.base_url}/api/plugins/{quote(plugin_id, safe='')}"
        request = lambda: requests.get(
            endpoint,
            timeout=self.timeout,
            headers=_default_headers(),
        )
        response = call_interruptibly(request, poll=poll) if poll else request()
        try:
            response.raise_for_status()
            data = response.json()
        finally:
            response.close()
        if isinstance(data, dict) and data.get("ok") is False:
            raise PlazaClientError(data.get("error", "The plaza rejected the request."))
        plugin = data.get("data", data) if isinstance(data, dict) else None
        if not isinstance(plugin, dict):
            raise PlazaClientError("Invalid plugin response from the plaza.")
        if plugin.get("id") != plugin_id:
            raise PlazaClientError("The plaza returned a different plugin ID.")
        return plugin

    def get_plugin_versions(
        self,
        plugin_ids: list[str],
        *,
        poll: PollCallback | None = None,
    ) -> dict[str, str | None]:
        """Bulk-check published versions for many plugin IDs in one request.

        Returns ``plugin_id -> version``; unknown/unpublished IDs map to ``None``.
        IDs are trimmed, de-duplicated and sorted before sending so the same set
        of plugins always yields a stable, cacheable query string.
        """
        requested_ids = {str(pid).strip() for pid in plugin_ids if str(pid).strip()}
        results: dict[str, str | None] = {
            plugin_id: None
            for plugin_id in requested_ids
            if not PLUGIN_ID_RE.fullmatch(plugin_id)
        }
        ids = sorted(plugin_id for plugin_id in requested_ids if PLUGIN_ID_RE.fullmatch(plugin_id))
        if not ids:
            return results

        for start in range(0, len(ids), MAX_VERSIONS_IDS):
            chunk = ids[start : start + MAX_VERSIONS_IDS]
            query = "ids=" + quote(",".join(chunk), safe=",")
            endpoint = f"{self.base_url}/api/plugins/versions?{query}"
            request = lambda: requests.get(
                endpoint,
                timeout=self.timeout,
                headers=_default_headers(plugin_protocol=True),
            )
            response = call_interruptibly(request, poll=poll) if poll else request()
            try:
                response.raise_for_status()
                data = response.json()
            finally:
                response.close()
            if isinstance(data, dict) and data.get("ok") is False:
                raise PlazaClientError(data.get("error", "The plaza rejected the request."))
            payload = data.get("data", data) if isinstance(data, dict) else None
            if not isinstance(payload, dict):
                raise PlazaClientError("Invalid version response from the plaza.")

            found: dict[str, str] = {}
            for item in payload.get("plugins", []):
                if isinstance(item, dict) and item.get("id"):
                    found[str(item["id"])] = str(item.get("version", ""))
            for plugin_id in chunk:
                results[plugin_id] = found.get(plugin_id)
        return results

    def release_url(self, plugin: dict, *, format: str = "cwplugin") -> str:
        resources = plugin.get("resources")
        release = resources.get("release") if isinstance(resources, dict) else None
        if not release:
            release = (
            f"{self.base_url}/api/plugins/{quote(plugin['id'], safe='')}"
            f"/resources/release?format={format}"
            )
            return release

        url = urljoin(f"{self.base_url}/", str(release))
        parts = urlsplit(url)
        query = dict(parse_qsl(parts.query, keep_blank_values=True))
        query["format"] = format
        return urlunsplit((parts.scheme, parts.netloc, parts.path, urlencode(query), parts.fragment))
