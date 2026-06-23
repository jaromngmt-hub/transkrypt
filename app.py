from __future__ import annotations

import asyncio
import tempfile
import time
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.responses import FileResponse, PlainTextResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

from downloader import download_video
from transcriber import Transcriber

ALLOWED_EXTENSIONS = {
    ".mp4",
    ".mov",
    ".webm",
    ".mkv",
    ".avi",
    ".m4v",
    ".mp3",
    ".wav",
    ".m4a",
    ".aac",
    ".ogg",
}

transcriber: Transcriber | None = None


class TranscribeUrlRequest(BaseModel):
    url: str = Field(..., min_length=4, max_length=2048)


@asynccontextmanager
async def lifespan(_: FastAPI):
    global transcriber
    transcriber = Transcriber()
    yield
    transcriber = None


app = FastAPI(title="Video Transcript", lifespan=lifespan)
static_dir = Path(__file__).parent / "static"
app.mount("/static", StaticFiles(directory=static_dir), name="static")


def _build_response(
    *,
    text: str,
    language: str,
    duration_seconds: float,
    processing_seconds: float,
    source: dict | None = None,
    download_seconds: float | None = None,
    transcribe_seconds: float | None = None,
) -> dict:
    payload = {
        "text": text,
        "language": language,
        "duration_seconds": duration_seconds,
        "processing_seconds": processing_seconds,
    }
    if source is not None:
        payload["source"] = source
    if download_seconds is not None:
        payload["download_seconds"] = download_seconds
    if transcribe_seconds is not None:
        payload["transcribe_seconds"] = transcribe_seconds
    return payload


@app.get("/")
async def index() -> FileResponse:
    return FileResponse(static_dir / "index.html")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/transcribe")
async def transcribe(video: UploadFile = File(...)) -> dict:
    if transcriber is None:
        raise HTTPException(status_code=503, detail="Model jeszcze się ładuje, spróbuj za chwilę.")

    suffix = Path(video.filename or "").suffix.lower()
    if suffix not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Nieobsługiwany format. Dozwolone: {', '.join(sorted(ALLOWED_EXTENSIONS))}",
        )

    started = time.perf_counter()
    tmp_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
            tmp.write(await video.read())
            tmp_path = Path(tmp.name)

        result = await asyncio.to_thread(transcriber.transcribe_file, tmp_path)
        elapsed = round(time.perf_counter() - started, 2)

        return _build_response(
            text=result.text,
            language=result.language,
            duration_seconds=result.duration_seconds,
            processing_seconds=elapsed,
            transcribe_seconds=elapsed,
        )
    except RuntimeError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    finally:
        if tmp_path is not None:
            tmp_path.unlink(missing_ok=True)


@app.post("/transcribe/url")
async def transcribe_url(body: TranscribeUrlRequest) -> dict:
    if transcriber is None:
        raise HTTPException(status_code=503, detail="Model jeszcze się ładuje, spróbuj za chwilę.")

    started = time.perf_counter()
    try:
        with tempfile.TemporaryDirectory() as tmp_dir:
            work_dir = Path(tmp_dir)

            download_started = time.perf_counter()
            download = await asyncio.to_thread(download_video, body.url, work_dir)
            download_seconds = round(time.perf_counter() - download_started, 2)

            transcribe_started = time.perf_counter()
            result = await asyncio.to_thread(transcriber.transcribe_file, download.path)
            transcribe_seconds = round(time.perf_counter() - transcribe_started, 2)

            return _build_response(
                text=result.text,
                language=result.language,
                duration_seconds=result.duration_seconds,
                processing_seconds=round(time.perf_counter() - started, 2),
                download_seconds=download_seconds,
                transcribe_seconds=transcribe_seconds,
                source={
                    "platform": download.platform,
                    "title": download.title,
                    "url": download.url,
                },
            )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except RuntimeError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc


@app.post("/transcribe/text", response_class=PlainTextResponse)
async def transcribe_plain(video: UploadFile = File(...)) -> str:
    payload = await transcribe(video)
    return payload["text"]