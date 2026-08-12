from __future__ import annotations

from collections.abc import Callable
from urllib.parse import parse_qsl, quote, urlencode, urljoin, urlsplit, urlunsplit

import requests

from src.core.utils.http_stream import call_interruptibly


PollCallback = Callable[[], None]


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
        request = lambda: requests.get(endpoint, timeout=self.timeout)
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
