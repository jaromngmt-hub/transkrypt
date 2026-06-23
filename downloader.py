from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlparse

import yt_dlp

SUPPORTED_HOSTS = (
    "tiktok.com",
    "instagram.com",
    "youtube.com",
    "youtu.be",
    "facebook.com",
    "fb.watch",
    "twitter.com",
    "x.com",
)

MEDIA_EXTENSIONS = {".mp4", ".webm", ".mkv", ".m4a", ".mp3", ".wav", ".mov"}


@dataclass
class DownloadResult:
    path: Path
    platform: str
    title: str
    duration: float | None
    url: str


def detect_platform(url: str) -> str:
    host = urlparse(url).netloc.lower().removeprefix("www.")
    if "tiktok" in host:
        return "tiktok"
    if "instagram" in host:
        return "instagram"
    if "youtube" in host or host == "youtu.be":
        return "youtube"
    if "facebook" in host or "fb.watch" in host:
        return "facebook"
    if "twitter" in host or host == "x.com":
        return "twitter"
    return "unknown"


def validate_url(url: str) -> str:
    cleaned = url.strip()
    if not cleaned:
        raise ValueError("Podaj link do filmiku.")
    if not re.match(r"^https?://", cleaned, re.I):
        cleaned = f"https://{cleaned}"
    host = urlparse(cleaned).netloc.lower()
    if not host:
        raise ValueError("Nieprawidłowy link.")
    if not any(token in host for token in SUPPORTED_HOSTS):
        raise ValueError(
            "Obsługujemy linki z Instagram, YouTube, TikTok, Facebook i X."
        )
    return cleaned


def download_video(url: str, work_dir: Path) -> DownloadResult:
    normalized_url = validate_url(url)
    work_dir.mkdir(parents=True, exist_ok=True)
    platform = detect_platform(normalized_url)

    opts: dict = {
        "format": "bv*+ba/b",
        "merge_output_format": "mp4",
        "outtmpl": str(work_dir / "%(id)s.%(ext)s"),
        "noplaylist": True,
        "quiet": True,
        "no_warnings": True,
        "socket_timeout": 30,
    }

    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(normalized_url, download=True)
    except yt_dlp.utils.DownloadError as exc:
        raise RuntimeError(f"Nie udało się pobrać filmiku: {exc}") from exc

    video_id = str(info.get("id") or "video")
    candidates = sorted(work_dir.glob(f"{video_id}.*"))
    media_path = next(
        (path for path in candidates if path.suffix.lower() in MEDIA_EXTENSIONS),
        None,
    )
    if media_path is None:
        media_path = next((path for path in work_dir.iterdir() if path.is_file()), None)
    if media_path is None:
        raise RuntimeError("Pobrano link, ale nie znaleziono pliku wideo.")

    return DownloadResult(
        path=media_path,
        platform=platform,
        title=str(info.get("title") or "Bez tytułu"),
        duration=float(info["duration"]) if info.get("duration") is not None else None,
        url=str(info.get("webpage_url") or normalized_url),
    )