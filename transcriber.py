from __future__ import annotations

import os
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

from faster_whisper import WhisperModel


@dataclass
class TranscriptionResult:
    text: str
    language: str
    duration_seconds: float


class Transcriber:
    def __init__(self) -> None:
        model_name = os.getenv("WHISPER_MODEL", "base")
        device = os.getenv("WHISPER_DEVICE", "cpu")
        compute_type = os.getenv("WHISPER_COMPUTE_TYPE", "int8")
        self._model = WhisperModel(model_name, device=device, compute_type=compute_type)

    def _extract_audio(self, video_path: Path) -> Path:
        tmp = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
        tmp.close()
        output = Path(tmp.name)
        cmd = [
            "ffmpeg",
            "-y",
            "-i",
            str(video_path),
            "-ac",
            "1",
            "-ar",
            "16000",
            "-vn",
            str(output),
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        if result.returncode != 0:
            output.unlink(missing_ok=True)
            raise RuntimeError(f"Nie udało się wyciągnąć audio: {result.stderr.strip()}")
        return output

    def transcribe_file(self, file_path: Path) -> TranscriptionResult:
        audio_path: Path | None = None
        try:
            audio_path = self._extract_audio(file_path)
            segments_iter, info = self._model.transcribe(
                str(audio_path),
                vad_filter=True,
                word_timestamps=False,
            )
            parts: list[str] = []
            for segment in segments_iter:
                text = segment.text.strip()
                if text:
                    parts.append(text)
            return TranscriptionResult(
                text=" ".join(parts).strip(),
                language=info.language or "unknown",
                duration_seconds=round(info.duration or 0.0, 2),
            )
        finally:
            if audio_path is not None:
                audio_path.unlink(missing_ok=True)