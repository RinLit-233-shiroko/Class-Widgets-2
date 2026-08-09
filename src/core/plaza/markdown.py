import re

from PySide6.QtCore import QObject, Slot
from markdown_it import MarkdownIt


class MarkdownRenderBridge(QObject):
    @Slot(str, result=str)
    def render(self, markdown: str) -> str:
        return render_markdown(markdown)


_MARKDOWN = MarkdownIt("commonmark", {"html": True, "linkify": True, "breaks": False}).enable(
    ["table", "strikethrough"]
)


def render_markdown(markdown: str) -> str:
    text = _normalize_placeholders(markdown or "")
    text = _normalize_admonitions(text)
    html = _MARKDOWN.render(text)
    html = _postprocess_for_qt_rich_text(html)
    return f"<div>{html}</div>"


def _normalize_placeholders(text: str) -> str:
    text = re.sub(r"\$\{__web_page_repo__\}", "", text)
    text = re.sub(r"\$\{__web_page_stars_badge__\}", "", text)
    text = re.sub(r"\$\{__web_page_downloads_badge__\}", "", text)
    text = re.sub(r"\$\{__web_page_license_badge__\}", "", text)
    text = re.sub(r"\$\{__web_page_link:(https?://[^}]+)__\}", r"\1", text)
    text = re.sub(r"\$\{__web_page_badge:(https?://[^}]+)__\}", "", text)
    return text


def _normalize_admonitions(text: str) -> str:
    lines = text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    result = []
    index = 0

    while index < len(lines):
        match = re.match(r"^>\s*\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*$", lines[index], re.I)
        if not match:
            result.append(lines[index])
            index += 1
            continue

        kind = match.group(1).upper()
        result.append(f"> **CW_ADMONITION_{kind}**")
        result.append(">")
        index += 1
        while index < len(lines):
            line = lines[index]
            if line.strip() == "":
                if index + 1 < len(lines) and lines[index + 1].lstrip().startswith(">"):
                    result.append(">")
                    index += 1
                    continue
                break
            if not line.lstrip().startswith(">"):
                break
            result.append(line)
            index += 1

    return "\n".join(result)


def _admonition_colors(kind: str) -> tuple[str, str]:
    colors = {
        "NOTE": ("#2563eb", "#2563eb"),
        "TIP": ("#16a34a", "#16a34a"),
        "IMPORTANT": ("#7c3aed", "#7c3aed"),
        "WARNING": ("#d97706", "#d97706"),
        "CAUTION": ("#dc2626", "#dc2626"),
    }
    return colors.get(kind, colors["NOTE"])


def _postprocess_for_qt_rich_text(value: str) -> str:
    value = re.sub(
        r"<h([1-6])>(.*?)</h\1>",
        lambda match: _heading_to_paragraph(int(match.group(1)), match.group(2)),
        value,
        flags=re.S,
    )
    value = re.sub(
        r"<pre><code(?: class=\"language-([^\"]+)\")?>(.*?)</code></pre>",
        lambda match: _code_block_to_pre(match.group(2), match.group(1) or ""),
        value,
        flags=re.S,
    )
    value = re.sub(
        r"<blockquote>\s*(.*?)\s*</blockquote>",
        lambda match: _blockquote_to_qt_html(match.group(1)),
        value,
        flags=re.S,
    )
    value = re.sub(
        r"<code>(.*?)</code>",
        r"<code style='font-family:Consolas, Cascadia Mono, monospace; font-size:13px; background-color:rgba(127,127,127,0.14); padding:2px 4px;'>\1</code>",
        value,
        flags=re.S,
    )
    value = _normalize_aligned_blocks(value)
    value = _normalize_images(value)
    value = _normalize_typography(value)
    value = value.replace("<table>", "<table border='1' cellspacing='0' cellpadding='6'>")
    return value


def _blockquote_to_qt_html(content: str) -> str:
    marker = re.match(r"\s*<p><strong>CW_ADMONITION_(NOTE|TIP|IMPORTANT|WARNING|CAUTION)</strong></p>\s*(.*)", content, re.I | re.S)
    if not marker:
        return _qt_quote_block(content)

    kind = marker.group(1).upper()
    body = marker.group(2).strip()
    title_color, border_color = _admonition_colors(kind)
    title = kind.title()
    title_block = f"<p style='font-size:14px; font-weight:700; line-height:1.5; color:{title_color}; margin:0 0 6px 0;'>{title}</p>"
    return _qt_quote_block(title_block + body, border_color, True)


def _qt_quote_block(content: str, border_color: str = "#8a8a8a", is_admonition: bool = False) -> str:
    blocks = [match.group(0) for match in re.finditer(r"<(p|ul|ol|pre|table)\b[^>]*>.*?</\1>", content, re.I | re.S)]
    if not blocks:
        blocks = [content]

    rendered = []
    cell_spacing = "12" if is_admonition else "10"
    for block in blocks:
        rendered.append(
            f"<table border='0' cellspacing='0' cellpadding='0' width='100%'>"
            f"<tr>"
            f"<td width='4' bgcolor='{border_color}'></td>"
            f"<td width='{cell_spacing}'></td>"
            f"<td>{block}</td>"
            f"</tr>"
            f"</table>"
        )
    return "".join(rendered)


def _normalize_typography(value: str) -> str:
    value = re.sub(r"<p>(.*?)</p>", r"<p style='font-size:14px; line-height:1.72; margin-top:8px; margin-bottom:12px;'>\1</p>", value, flags=re.S)
    value = re.sub(r"<li>(.*?)</li>", r"<li style='font-size:14px; line-height:1.72; margin-top:4px; margin-bottom:4px;'>\1</li>", value, flags=re.S)
    value = re.sub(r"<ul>", r"<ul style='margin-top:8px; margin-bottom:14px;'>", value)
    value = re.sub(r"<ol>", r"<ol style='margin-top:8px; margin-bottom:14px;'>", value)
    value = re.sub(r"<a ", r"<a style='text-decoration:none;' ", value)
    value = value.replace("<hr>", "<hr style='margin-top:20px; margin-bottom:20px;'>")
    return value


def _normalize_aligned_blocks(value: str) -> str:
    def replace_div(match: re.Match[str]) -> str:
        attributes = match.group(1)
        content = match.group(2)
        align_match = re.search(r"\balign\s*=\s*(['\"]?)(left|center|right)\1", attributes, re.I)
        if align_match:
            align_value = align_match.group(2)
        else:
            align_match = re.search(r"text-align\s*:\s*(left|center|right)", attributes, re.I)
            if align_match:
                align_value = align_match.group(1)
            else:
                return match.group(0)
        return f"<p align='{align_value.lower()}'>{content}</p>"

    return re.sub(r"<div\b([^>]*)>(.*?)</div>", replace_div, value, flags=re.I | re.S)


def _normalize_images(value: str) -> str:
    def replace_image(match: re.Match[str]) -> str:
        attributes = match.group(1).strip()
        attributes = re.sub(r"\s+style\s*=\s*(['\"])(.*?)\1", lambda style_match: _image_style_to_attributes(style_match), attributes, flags=re.I | re.S)
        return f"<img {attributes}>"

    return re.sub(r"<img\b([^>]*)>", replace_image, value, flags=re.I | re.S)


def _image_style_to_attributes(match: re.Match[str]) -> str:
    style = match.group(2)
    width = _style_dimension(style, "width")
    height = _style_dimension(style, "height")
    result = ""
    if width:
        result += f" width='{width}'"
    if height:
        result += f" height='{height}'"
    return result


def _style_dimension(style: str, name: str) -> str:
    match = re.search(rf"(?:^|;)\s*{name}\s*:\s*(\d+(?:\.\d+)?)px\s*(?:;|$)", style, re.I)
    if not match:
        return ""
    value = float(match.group(1))
    return str(int(value)) if value.is_integer() else str(value)


def _heading_to_paragraph(level: int, content: str) -> str:
    styles = {
        1: (30, 800, 26, 14),
        2: (24, 750, 24, 12),
        3: (20, 700, 20, 10),
        4: (17, 700, 18, 8),
        5: (15, 700, 16, 8),
        6: (14, 700, 14, 6),
    }
    size, weight, margin_top, margin_bottom = styles.get(level, styles[6])
    return (
        f"<p style='font-size:{size}px; font-weight:{weight}; line-height:1.3; "
        f"margin-top:{margin_top}px; margin-bottom:{margin_bottom}px;'>{content}</p>"
    )


def _code_block_to_pre(code: str, language: str) -> str:
    label = f"<span style='font-size:12px; color:#8a8a8a'>{language}</span><br>" if language else ""
    return (
        "<pre style='font-family:Consolas, Cascadia Mono, monospace; font-size:13px; "
        "line-height:1.55; background-color:rgba(127,127,127,0.12); padding:12px; "
        f"border-radius:8px; margin-top:10px; margin-bottom:14px; white-space:pre-wrap;'>{label}<code>{code}</code></pre>"
    )
