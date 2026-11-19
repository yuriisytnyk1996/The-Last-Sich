"""Generates the placeholder sounds and music in assets/audio/.

Synthesised bleeps, thuds and plucked loops so every cue in the sound bank
is audible before real recordings exist. Standard library only; music is
encoded to Ogg Vorbis with ffmpeg when it is installed (WAV otherwise).

    python3 -I tools/placeholder_audio.py

Re-running overwrites the files, so replace a placeholder by pointing its
cue in assets/audio/sound_bank.tres at a new file instead of overwriting.
"""

import array
import math
import os
import random
import shutil
import subprocess
import sys
import wave

RATE = 22050
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
rng = random.Random(7)


# --- primitives -------------------------------------------------------------


def silence(seconds):
    return [0.0] * int(seconds * RATE)


def mix(target, source, at=0.0, gain=1.0, wrap=False):
    start = int(at * RATE)
    n = len(target)
    for i, s in enumerate(source):
        j = start + i
        if wrap:
            j %= n
        elif j >= n:
            target.extend([0.0] * (j - n + 1))
            n = len(target)
        target[j] += s * gain
    return target


def env(n, attack, decay_power=1.0):
    """Short linear attack, then a decay curve to zero."""
    a = max(1, int(attack * RATE))
    out = []
    for i in range(n):
        if i < a:
            out.append(i / a)
        else:
            out.append((1.0 - (i - a) / max(1, n - a)) ** decay_power)
    return out


def osc(freq_from, freq_to, seconds, shape="sine", attack=0.003, power=1.5):
    n = int(seconds * RATE)
    e = env(n, attack, power)
    phase = 0.0
    out = []
    for i in range(n):
        f = freq_from * (freq_to / freq_from) ** (i / n)
        phase += f / RATE
        p = phase % 1.0
        if shape == "sine":
            v = math.sin(2 * math.pi * p)
        elif shape == "square":
            v = 1.0 if p < 0.5 else -1.0
        elif shape == "saw":
            v = 2.0 * p - 1.0
        else:
            v = 4.0 * abs(p - 0.5) - 1.0
        out.append(v * e[i])
    return out


def noise(seconds, cutoff_from=4000.0, cutoff_to=None, attack=0.002, power=2.0, high=False):
    """White noise through a one-pole low-pass (or high-pass) filter sweep."""
    n = int(seconds * RATE)
    e = env(n, attack, power)
    cutoff_to = cutoff_to or cutoff_from
    low = 0.0
    out = []
    for i in range(n):
        c = cutoff_from * (cutoff_to / cutoff_from) ** (i / n)
        k = 1.0 - math.exp(-2 * math.pi * c / RATE)
        x = rng.uniform(-1.0, 1.0)
        low += k * (x - low)
        out.append((x - low if high else low) * e[i])
    return out


def bell(partials, seconds, attack=0.002, power=3.0):
    """Inharmonic partials (freq, gain) for clangs and rings."""
    out = silence(seconds)
    for freq, gain in partials:
        mix(out, osc(freq, freq, seconds, "sine", attack, power), 0.0, gain)
    return out


def pluck(freq, seconds, damping=0.996, bright=0.5):
    """Karplus-Strong plucked string, close enough to a bandura."""
    period = max(2, int(RATE / freq))
    buf = [rng.uniform(-1.0, 1.0) for _ in range(period)]
    for i in range(1, period):
        buf[i] = buf[i - 1] + bright * (buf[i] - buf[i - 1])
    out = []
    for i in range(int(seconds * RATE)):
        j = i % period
        nxt = buf[(j + 1) % period]
        out.append(buf[j])
        buf[j] = damping * 0.5 * (buf[j] + nxt)
    return out


def normalize(samples, peak=0.8):
    top = max((abs(s) for s in samples), default=0.0) or 1.0
    return [s * peak / top for s in samples]


def write_wav(path, samples):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = array.array("h", (int(max(-1.0, min(1.0, s)) * 32767) for s in samples))
    if sys.byteorder == "big":
        data.byteswap()
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data.tobytes())


# --- sound effects ----------------------------------------------------------


def seq(*parts):
    out = []
    for at, part, gain in parts:
        mix(out, part, at, gain)
    return out


SFX = {
    "ui_move": lambda: osc(880, 880, 0.04, "square", power=2),
    "ui_accept": lambda: seq((0, osc(660, 660, 0.05, "square"), 1), (0.05, osc(990, 990, 0.08, "square"), 1)),
    "ui_back": lambda: seq((0, osc(660, 660, 0.05, "square"), 1), (0.05, osc(440, 440, 0.08, "square"), 1)),
    "swing": lambda: noise(0.15, 1500, 5000, attack=0.05, power=2),
    "swing_heavy": lambda: noise(0.26, 700, 2600, attack=0.08, power=2),
    "hit": lambda: seq((0, noise(0.08, 3000, 600), 0.8), (0, osc(140, 50, 0.14, "sine"), 1)),
    "hit_critical": lambda: seq(
        (0, noise(0.08, 4000, 800), 0.8), (0, osc(140, 50, 0.14), 1),
        (0, bell([(1250, 0.4), (1720, 0.3), (2630, 0.2)], 0.35), 0.7),
    ),
    "hit_wood": lambda: seq((0, osc(320, 200, 0.09, "triangle", power=3), 1), (0, noise(0.03, 5000), 0.6)),
    "parry": lambda: seq(
        (0, noise(0.03, 8000), 0.7),
        (0, bell([(1000, 0.5), (1520, 0.35), (2380, 0.25), (3110, 0.15)], 0.6), 1),
    ),
    "block": lambda: seq((0, noise(0.03, 5000), 0.6), (0, bell([(520, 0.5), (790, 0.35), (1230, 0.2)], 0.28), 1)),
    "guard_slide": lambda: seq((0, bell([(900, 0.4), (1400, 0.3)], 0.2), 0.8), (0, noise(0.32, 6000, power=1, high=True), 0.5)),
    "jump": lambda: osc(220, 440, 0.1, "square", power=2),
    "land": lambda: noise(0.07, 900, 300),
    "land_hard": lambda: seq((0, noise(0.22, 1200, 200), 1), (0, osc(90, 40, 0.25), 1)),
    "dash": lambda: noise(0.13, 2500, 7000, attack=0.02, power=1.5),
    "step": lambda: noise(0.035, 1200, 400, power=3),
    "heal": lambda: seq(*[(i * 0.09, osc(f, f, 0.4, "sine", power=2), 0.6) for i, f in enumerate([523, 659, 784, 1046])]),
    "player_hurt": lambda: seq((0, osc(320, 150, 0.16, "square"), 0.6), (0, noise(0.1, 2500, 500), 0.8)),
    "player_death": lambda: seq((0, osc(400, 70, 1.0, "saw", power=1), 0.5), (0, noise(0.6, 1500, 150, power=1), 0.6)),
    "enemy_death": lambda: seq((0, noise(0.2, 2000, 300), 0.8), (0, osc(250, 60, 0.4, "triangle"), 0.8)),
    "shot": lambda: seq((0, noise(0.3, 7000, 900, power=3), 1), (0, osc(110, 40, 0.25), 0.9)),
    "duma": lambda: seq(*[(0, osc(f, f * 1.01, 0.9, "sine", attack=0.3, power=1.5), 0.4) for f in [294, 440, 587, 880]]),
    "execution": lambda: seq((0, noise(0.15, 4000, 400), 1), (0, osc(120, 35, 0.6), 1), (0.05, bell([(700, 0.3), (1050, 0.2)], 0.4), 0.6)),
    "item": lambda: seq(*[(i * 0.07, osc(f, f, 0.22, "square", power=2), 0.5) for i, f in enumerate([784, 988, 1175, 1568])]),
    "coin": lambda: seq((0, osc(1320, 1320, 0.08, "square"), 0.5), (0.06, osc(1760, 1760, 0.16, "square"), 0.5)),
    "upgrade": lambda: seq(*[(i * 0.12, osc(f, f, 0.5, "triangle", power=1.5), 0.7) for i, f in enumerate([392, 523, 659, 784, 1046])]),
    "rest": lambda: seq(
        *[(0, osc(f, f, 1.4, "sine", attack=0.4, power=1.2), 0.4) for f in [147, 220, 294, 370]],
        (0, noise(1.2, 3000, power=1, high=True), 0.08),
    ),
    "denied": lambda: seq((0, osc(110, 110, 0.08, "square"), 0.6), (0.11, osc(110, 110, 0.1, "square"), 0.6)),
    "break": lambda: seq(*[(i * 0.05, seq((0, noise(0.06, 3500, 600), 1), (0, osc(260 - i * 30, 120, 0.08, "triangle"), 0.8)), 0.8) for i in range(4)]),
    "boss_death": lambda: seq((0, noise(1.4, 2500, 80, power=1.2), 0.8), (0, osc(80, 25, 1.5, "sine", power=1), 1)),
}


# --- music --------------------------------------------------------------------

# Ukrainian Dorian on D: D E F G# A B C.
SCALE = [146.83, 164.81, 174.61, 207.65, 220.0, 246.94, 261.63]


def note(degree, octave=0):
    return SCALE[degree % 7] * 2 ** (octave + degree // 7)


def drone(seconds, freqs, gain=0.15):
    out = silence(seconds)
    n = len(out)
    for f in freqs:
        for i in range(n):
            lfo = 0.75 + 0.25 * math.sin(2 * math.pi * i / n * 2)
            out[i] += math.sin(2 * math.pi * f * i / RATE) * gain * lfo
    return out


def kick(seconds=0.25):
    return seq((0, osc(120, 40, seconds, "sine", power=2), 1), (0, noise(0.02, 3000), 0.4))


def tom(freq):
    return seq((0, osc(freq, freq * 0.7, 0.2, "sine", power=2), 0.8), (0, noise(0.04, 2500), 0.3))


def melody(track, beat, notes, octave, gain, damping=0.996):
    for step, degree in enumerate(notes):
        if degree is not None:
            mix(track, pluck(note(degree, octave), beat * 3, damping), step * beat, gain, wrap=True)


def steppe():
    beat = 60 / 84 / 2
    bars = 8
    track = drone(beat * 8 * bars, [73.42, 110.0], 0.12)
    tune = [0, 2, 3, 4, 3, 2, 1, 0, 4, 5, 6, 7, 6, 4, 3, 4] * 2 + [7, 6, 4, 3, 4, 3, 2, 1, 0, None, 2, 1, 0, None, None, None] * 2
    melody(track, beat, tune, 1, 0.5)
    melody(track, beat * 4, [0, 4, 3, 0, 5, 4, 3, 0] * 2, 0, 0.35, 0.998)
    mix(track, noise(len(track) / RATE, 400, power=0.01), 0, 0.15, wrap=True)
    return track


def kurgan():
    beat = 60 / 60
    track = drone(beat * 20, [73.42, 103.83, 146.83], 0.12)
    melody(track, beat, [7, None, None, 3, None, None, None, None, 6, None, 3, None, None, None, None, None, 2, None, None, None], 1, 0.35, 0.998)
    mix(track, noise(20.0, 600, power=0.01), 0, 0.25, wrap=True)
    return track


def boss(bpm, extra):
    beat = 60 / bpm / 2
    bars = 8
    track = drone(beat * 8 * bars, [73.42, 110.0], 0.1)
    riff = [0, 0, 3, 0, 4, 0, 3, 2] * 4 + [0, 0, 3, 0, 5, 4, 3, 1] * 4
    melody(track, beat, riff, 0, 0.5, 0.993)
    for i in range(8 * bars):
        if i % 4 == 0:
            mix(track, kick(), i * beat, 0.9, wrap=True)
        if i % 8 == 6 or (extra and i % 4 == 2):
            mix(track, tom(180), i * beat, 0.7, wrap=True)
        if extra:
            mix(track, noise(0.04, 7000, high=True), i * beat, 0.25, wrap=True)
    if extra:
        melody(track, beat * 2, [7, 6, 7, 9, 8, 7, 6, 4] * 4, 1, 0.35)
    return track


MUSIC = {"steppe": steppe, "kurgan": kurgan, "boss_1": lambda: boss(116, False), "boss_2": lambda: boss(136, True)}


def encode_ogg(wav_path):
    ogg_path = wav_path[:-4] + ".ogg"
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-ac", "2", "-c:a", "vorbis", "-strict", "-2", "-q:a", "3", ogg_path]
    subprocess.run(cmd, check=True)
    os.remove(wav_path)
    return ogg_path


def main():
    for name, make in SFX.items():
        write_wav(os.path.join(ROOT, "sfx", name + ".wav"), normalize(make(), 0.7))
    can_encode = shutil.which("ffmpeg") is not None
    for name, make in MUSIC.items():
        path = os.path.join(ROOT, "music", name + ".wav")
        write_wav(path, normalize(make(), 0.6))
        print(encode_ogg(path) if can_encode else path)
    print("%d sounds, %d tracks" % (len(SFX), len(MUSIC)))


if __name__ == "__main__":
    main()
