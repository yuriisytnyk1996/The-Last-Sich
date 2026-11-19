"""Generates the placeholder sounds and music in assets/audio/.

    python3 -I tools/placeholder_audio            everything
    python3 -I tools/placeholder_audio sfx        sound effects only
    python3 -I tools/placeholder_audio steppe hit only these

Sound effects are mono 44.1 kHz WAV (positional in the game), one file per
take (`hit_1.wav`...) for sounds with several. Music is stereo, encoded to
Ogg Vorbis with ffmpeg when it is installed (WAV otherwise). Standard
library only. Re-running overwrites the files: replace a placeholder by
pointing its cue in assets/audio/sound_bank.tres at a new file instead.
"""

import array
import os
import shutil
import subprocess
import sys
import time
import wave

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from dsp import RATE, dc_block, fade_edges, limit, new_rng, normalize  # noqa: E402
from sfx import SFX, TAKES  # noqa: E402
from tracks import TRACKS  # noqa: E402

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "audio"))


def write_wav(path, channels):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    frames = array.array("h")
    for samples in zip(*channels):
        frames.extend(int(max(-1.0, min(1.0, s)) * 32767) for s in samples)
    if sys.byteorder == "big":
        frames.byteswap()
    with wave.open(path, "wb") as f:
        f.setnchannels(len(channels))
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(frames.tobytes())


def make_sfx(name):
    takes = TAKES.get(name, 1)
    for take in range(takes):
        sig = SFX[name](new_rng(sum(map(ord, name)) + take * 7919))
        sig = fade_edges(normalize(dc_block(sig), 0.89), 0.0005, 0.02)
        limit([sig], 0.89)
        suffix = "_%d" % (take + 1) if takes > 1 else ""
        write_wav(os.path.join(ROOT, "sfx", name + suffix + ".wav"), [sig])


def make_track(name):
    path = os.path.join(ROOT, "music", name + ".wav")
    write_wav(path, TRACKS[name]())
    if shutil.which("ffmpeg"):
        ogg = path[:-4] + ".ogg"
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-c:a", "vorbis", "-strict", "-2", "-q:a", "8", ogg],
            check=True,
        )
        os.remove(path)


def main(args):
    names = args or ["sfx", "music"]
    wanted_sfx = [n for n in SFX if "sfx" in names or n in names]
    wanted_music = [n for n in TRACKS if "music" in names or n in names]
    for name in wanted_sfx:
        start = time.time()
        make_sfx(name)
        print("sfx   %-14s %.1fs" % (name, time.time() - start))
    for name in wanted_music:
        start = time.time()
        make_track(name)
        print("music %-14s %.1fs" % (name, time.time() - start))


if __name__ == "__main__":
    main(sys.argv[1:])
