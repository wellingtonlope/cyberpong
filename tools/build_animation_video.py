#!/usr/bin/env python3
"""Monta os vídeos MP4 das animações de tamanho da raquete.

Os quadros são gravados pela ferramenta de capturas de tela
(`tools/capture_screenshots.gd`) em `.godot/animation_frames/<nome>/`, e este
script os reúne em um MP4 dentro de `docs/screenshots/`.

Requer o ffmpeg, procurado no PATH ou no pacote `imageio-ffmpeg`.

Uso:
    godot --path . res://tools/capture_screenshots.tscn
    python3 tools/build_animation_video.py
"""

import shutil
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
FRAMES_DIR = PROJECT_ROOT / ".godot" / "animation_frames"
OUTPUT_DIR = PROJECT_ROOT / "docs" / "screenshots"

# Quadros por segundo do vídeo final. A animação real dura menos de meio
# segundo, então o vídeo é ralentizado para o movimento ficar legível.
FRAME_RATE = 15
# Tempo em que o último quadro fica na tela antes do fim do vídeo.
HOLD_SECONDS = 0.6

ANIMATIONS = {
    "aumento": "power-up-animacao-aumento.mp4",
    "reducao": "power-up-animacao-reducao.mp4",
}


def find_ffmpeg() -> str:
    executable = shutil.which("ffmpeg")
    if executable:
        return executable
    try:
        import imageio_ffmpeg
    except ImportError:
        raise SystemExit(
            "ffmpeg nao encontrado: instale o ffmpeg ou o pacote imageio-ffmpeg"
        )
    return imageio_ffmpeg.get_ffmpeg_exe()


def build(ffmpeg: str, name: str, file_name: str) -> None:
    folder = FRAMES_DIR / name
    if not folder.is_dir() or not list(folder.glob("frame_*.png")):
        raise SystemExit(f"nenhum quadro encontrado em {folder}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output_path = OUTPUT_DIR / file_name
    command = [
        ffmpeg,
        "-y",
        "-loglevel",
        "error",
        "-framerate",
        str(FRAME_RATE),
        "-i",
        str(folder / "frame_%02d.png"),
        "-vf",
        f"tpad=stop_mode=clone:stop_duration={HOLD_SECONDS}",
        "-c:v",
        "libx264",
        "-preset",
        "slow",
        "-crf",
        "20",
        "-pix_fmt",
        "yuv420p",
        "-movflags",
        "+faststart",
        str(output_path),
    ]
    subprocess.run(command, check=True)
    print(f"salvo {output_path} ({output_path.stat().st_size} bytes)")


def main() -> None:
    ffmpeg = find_ffmpeg()
    for name, file_name in ANIMATIONS.items():
        build(ffmpeg, name, file_name)


if __name__ == "__main__":
    sys.exit(main())
