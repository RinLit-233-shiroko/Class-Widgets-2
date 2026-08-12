from __future__ import annotations

import re

from PySide6.QtCore import QCoreApplication


_VERSION_MISMATCH = re.compile(
    r"^Archive version '(.+)' does not match release version '(.+)'\.$"
)


def plugin_install_error_message(error: str) -> str:
    """Return a localized, actionable message for a plugin install failure.

    Worker threads only transport exception strings across the Qt boundary. Keep
    their diagnostics in logs, while this boundary presents stable messages to
    notifications and QML.
    """
    message = error.strip()
    version_mismatch = _VERSION_MISMATCH.match(message)
    if version_mismatch:
        return QCoreApplication.translate("PluginPlaza", "The package version ({package_version}) does not match the Plugin Plaza version ({release_version}).").format(
            package_version=version_mismatch.group(1),
            release_version=version_mismatch.group(2),
        )

    if message.startswith("Archive contains '"):
        return QCoreApplication.translate("PluginPlaza", "The plugin package does not match the selected plugin.")
    if message.startswith("Plugin archive does not exist:"):
        return QCoreApplication.translate("PluginPlaza", "The plugin package could not be found.")
    if message in {
        "Plugin archive is too large.",
        "Extracted plugin is too large.",
        "Plugin download is too large.",
    }:
        return QCoreApplication.translate("PluginPlaza", "The plugin package is too large.")
    if message == "Plugin archive is not a valid ZIP file.":
        return QCoreApplication.translate("PluginPlaza", "The plugin package is invalid.")
    if (
        "cwplugin.json" in message
        or message.startswith("Invalid plugin version:")
        or message.startswith("Invalid plugin ID:")
    ):
        return QCoreApplication.translate("PluginPlaza", "The plugin manifest is invalid.")
    if message.startswith((
        "Symbolic links are not allowed:",
        "Unsafe path in plugin archive:",
        "Unsafe entry path in plugin manifest:",
        "Plugin archive has an unsafe compression ratio.",
        "Plugin archive contains files outside its plugin root.",
        "Extracted manifest ID changed during installation.",
    )):
        return QCoreApplication.translate("PluginPlaza", "The plugin package failed security checks.")
    if _is_download_or_plaza_error(message):
        return QCoreApplication.translate("PluginPlaza", "Unable to download the plugin. Check your connection and try again.")
    return QCoreApplication.translate("PluginPlaza", "Plugin installation failed.")


def _is_download_or_plaza_error(message: str) -> bool:
    prefixes = (
        "Plugin plaza URL is not configured.",
        "The plaza rejected the request.",
        "Invalid plugin response from the plaza.",
        "The plaza returned a different plugin ID.",
        "HTTPConnectionPool(",
        "HTTPSConnectionPool(",
        "ConnectionError(",
        "ReadTimeout(",
        "ConnectTimeout(",
        "Max retries exceeded",
        "Download ended before the archive was complete",
        "404 Client Error:",
        "403 Client Error:",
        "500 Server Error:",
    )
    return message.startswith(prefixes)
