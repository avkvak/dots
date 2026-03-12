#!/usr/bin/env python3

import html
import json
import re
import sys
from datetime import datetime, timedelta
from urllib.parse import parse_qs, unquote, urlparse
from zoneinfo import ZoneInfo

import gi

gi.require_version("EDataServer", "1.2")
gi.require_version("ECal", "2.0")

from gi.repository import ECal, EDataServer


MEETING_HOSTS = (
    "meet.google.com",
    "zoom.us",
    "teams.microsoft.com",
    "teams.live.com",
    "teams.office.com",
    "webex.com",
    "whereby.com",
    "meet.jit.si",
    "jitsi",
)

URL_RE = re.compile(r'https?://[^\s<>"\']+')
HREF_RE = re.compile(r'href=["\'](https?://[^"\']+)["\']', re.IGNORECASE)


def normalize_url(url: str) -> str:
    parsed = urlparse(url)
    if parsed.netloc in {"www.google.com", "google.com"} and parsed.path == "/url":
        target = parse_qs(parsed.query).get("q", [""])[0]
        if target:
            return unquote(target)
    return html.unescape(url.rstrip("),.;"))


def extract_meeting_link(*chunks: str) -> str:
    candidates = []

    for chunk in chunks:
        if not chunk:
            continue

        text = html.unescape(chunk)
        candidates.extend(HREF_RE.findall(text))
        candidates.extend(URL_RE.findall(text))

    normalized = []
    for candidate in candidates:
        url = normalize_url(candidate)
        if url.startswith("http://") or url.startswith("https://"):
            normalized.append(url)

    for url in normalized:
        host = urlparse(url).netloc.lower()
        if any(marker in host for marker in MEETING_HOSTS):
            return url

    return normalized[0] if normalized else ""


def format_delta(seconds: int) -> str:
    minutes = max(0, seconds // 60)
    hours, minutes = divmod(minutes, 60)

    if hours:
        return f"{hours}h {minutes:02d}m"
    return f"{minutes}m"


def trim_summary(summary: str, limit: int = 34) -> str:
    summary = " ".join(summary.split())
    if len(summary) <= limit:
        return summary
    return summary[: limit - 1] + "…"


def format_text(prefix: str, summary: str, max_length: int = 40) -> str:
    summary = " ".join(summary.split())
    available = max_length - len(prefix)
    if available <= 1:
        return prefix.rstrip()
    return f"{prefix}{trim_summary(summary, available)}"


def ical_time_to_timestamp(value) -> int:
    if value.is_utc():
        return int(value.as_timet())

    timezone = value.get_timezone()
    if timezone is not None:
        location = timezone.get_location()
        if location:
            dt = datetime(
                value.get_year(),
                value.get_month(),
                value.get_day(),
                value.get_hour(),
                value.get_minute(),
                value.get_second(),
                tzinfo=ZoneInfo(location),
            )
            return int(dt.astimezone().timestamp())

    local_tz = datetime.now().astimezone().tzinfo
    dt = datetime(
        value.get_year(),
        value.get_month(),
        value.get_day(),
        value.get_hour(),
        value.get_minute(),
        value.get_second(),
        tzinfo=local_tz,
    )
    return int(dt.timestamp())


def collect_events() -> list[dict]:
    registry = EDataServer.SourceRegistry.new_sync(None)
    now = datetime.now().astimezone()
    day_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    day_end = day_start + timedelta(days=1)

    start_ts = int(day_start.timestamp())
    end_ts = int(day_end.timestamp())
    events: list[dict] = []

    for source in registry.list_sources(EDataServer.SOURCE_EXTENSION_CALENDAR):
        if not source.get_enabled():
            continue

        client = ECal.Client.connect_sync(source, ECal.ClientSourceType.EVENTS, 10, None)

        def collect_instance(icalcomp, start_time, end_time, _mod, _data):
            if start_time.is_date():
                return True

            summary = (icalcomp.get_summary() or "").strip()
            if not summary:
                return True

            description = icalcomp.get_description() or ""
            location = icalcomp.get_location() or ""
            link = extract_meeting_link(location, description)

            events.append(
                {
                    "calendar": source.get_display_name(),
                    "summary": summary,
                    "start_ts": ical_time_to_timestamp(start_time),
                    "end_ts": ical_time_to_timestamp(end_time),
                    "link": link,
                }
            )
            return True

        client.generate_instances_sync(start_ts, end_ts, None, collect_instance, None)

    return events


def build_payload() -> dict:
    now = int(datetime.now().astimezone().timestamp())
    events = sorted(
        (event for event in collect_events() if event["end_ts"] > now),
        key=lambda event: (event["start_ts"], event["summary"]),
    )

    if not events:
        return {
            "text": "No upcoming events",
            "tooltip": "No upcoming events",
            "alt": "",
        }

    event = events[0]
    start = datetime.fromtimestamp(event["start_ts"]).astimezone()
    end = datetime.fromtimestamp(event["end_ts"]).astimezone()

    if event["start_ts"] <= now < event["end_ts"]:
        text = format_text("󰃰 now: ", event["summary"])
    else:
        text = format_text(f"󰃰 in {format_delta(event['start_ts'] - now)}: ", event["summary"])

    tooltip = "\n".join(
        part
        for part in (
            event["summary"],
            f"{event['calendar']} | {start:%H:%M} - {end:%H:%M}",
            event["link"] or "No meeting link found",
        )
        if part
    )

    return {
        "text": text,
        "tooltip": tooltip,
        "alt": event["link"],
    }


def main() -> int:
    try:
        print(json.dumps(build_payload(), ensure_ascii=False))
        return 0
    except Exception as exc:
        print(
            json.dumps(
                {
                    "text": "",
                    "tooltip": f"Evolution calendar error: {exc}",
                    "alt": "",
                },
                ensure_ascii=False,
            )
        )
        return 1


if __name__ == "__main__":
    sys.exit(main())
