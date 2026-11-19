"""The four placeholder tracks, written as note lists (MIDI numbers).

steppe   84 bpm, D minor: bandura arpeggios, sopilka tune, strings, bass, wind
kurgan   60 bpm: low drone, dark choir (D minor, E flat), far bells, wind
boss_1  120 bpm, D harmonic minor: drums, bass, bandura riff, string stabs
boss_2  140 bpm: boss_1 driven harder, hats, choir and a high sopilka lead
"""

from dsp import midi, new_rng
from music import (
    Track, bandura, bass, bell, choir, drone, frame_drum, hat, kick, play_chords,
    play_notes, sopilka, strings, tom, wind,
)

DM, C, BB, A, GM, EB = [50, 57, 62, 65], [48, 55, 60, 64], [46, 53, 58, 62], [45, 52, 57, 61], [43, 50, 55, 58], [51, 58, 63, 67]


def arpeggio(chords, beats_per_chord, pattern, octave=0):
    notes = []
    for c, chord in enumerate(chords):
        tones = chord[1:] + [chord[2] + 12]
        steps = int(beats_per_chord * 2)
        for s in range(steps):
            notes.append((c * beats_per_chord + s * 0.5, 1.5, tones[pattern[s % len(pattern)]] + octave))
    return notes


def roots(chords, beats_per_chord, every, octave=-12, length=None):
    notes = []
    for c, chord in enumerate(chords):
        for b in range(int(beats_per_chord / every)):
            notes.append((c * beats_per_chord + b * every, length or every * 0.9, chord[0] + octave))
    return notes


def steppe():
    r = new_rng(11)
    t = Track(84, 8)
    chords = [DM, DM, C, C, BB, BB, A, A]
    play_chords(t, chords, 4, 0.16, attack=0.9, cutoff=1300)
    play_notes(t, roots(chords, 4, 2), lambda f, l: bass(f, l), 0.5, wet=0.1)
    play_notes(t, arpeggio(chords, 4, [0, 1, 2, 3, 2, 1, 2, 1]), lambda f, l: bandura(f, l, r), 0.32, pan=-0.35, r=r)
    tune = [
        (0, 1.5, 69), (1.5, 0.5, 67), (2, 1, 65), (3, 1, 64), (4, 3.5, 62),
        (8, 1.5, 67), (9.5, 0.5, 69), (10, 1, 72), (11, 1, 69), (12, 3.5, 67),
        (16, 1, 65), (17, 1, 67), (18, 1.5, 69), (19.5, 0.5, 70), (20, 2, 69), (22, 1, 67), (23, 1, 65),
        (24, 1.5, 64), (25.5, 0.5, 65), (26, 1, 64), (27, 1, 61), (28, 3.5, 64),
    ]
    play_notes(t, tune, lambda f, l: sopilka(f, l, r), 0.3, pan=0.3, wet=0.4, r=r, humanize=0.01)
    wind(t, r, 0.05)
    return t.finish(t60=2.6, target_rms=0.1)


def kurgan():
    r = new_rng(23)
    t = Track(60, 5)
    drone(t, 38, 0.3, cutoff=350)
    for i, chord in enumerate([DM, EB, DM, GM, EB]):
        t.put(choir([midi(n) for n in chord], 5.2, r, vowel=(500, 900), attack=1.6), i * 4, 0.11, pan=-0.2 if i % 2 else 0.2, wet=0.6)
    for beat, note, pan in [(1, 81, 0.5), (5.5, 77, -0.5), (9, 74, 0.3), (12.5, 82, -0.4), (16.5, 79, 0.6)]:
        t.put(bell(midi(note), 3.0), beat, 0.12, pan, wet=0.8)
    wind(t, r, 0.12)
    return t.finish(t60=4.5, damp=0.5, size=1.4, target_rms=0.09)


BOSS_CHORDS = [DM, DM, BB, A, DM, DM, GM, A]
RIFFS = {
    50: [50, 50, 57, 50, 58, 57, 53, 57],
    46: [46, 46, 53, 46, 58, 57, 53, 50],
    45: [45, 45, 52, 45, 49, 52, 57, 61],
    43: [43, 43, 50, 43, 55, 53, 50, 55],
}


def boss_drums(t, r, bars, hard):
    for bar in range(bars):
        b = bar * 4
        for beat in (0, 1.5, 2) if not hard else (0, 0.75, 1.5, 2, 2.75):
            t.put(kick(r), b + beat, 0.9, wet=0.05, r=r, humanize=0.003)
        for beat in (1, 3):
            t.put(frame_drum(r), b + beat, 0.65, wet=0.2, r=r, humanize=0.004)
        steps = 16 if hard else 8
        for s in range(steps):
            t.put(hat(r), b + s * 4 / steps, 0.12 if s % 2 else 0.2, pan=0.3, wet=0.05, r=r, humanize=0.003)
        if bar % 4 == 3:
            for k, f in enumerate((220, 180, 150, 120)):
                t.put(tom(r, f), b + 3 + k * 0.25, 0.6, pan=0.4 - k * 0.25, wet=0.2)


def boss(bpm, hard, seed):
    r = new_rng(seed)
    t = Track(bpm, 8)
    for i, chord in enumerate(BOSS_CHORDS):
        for hit in (0, 2.5):
            stab = strings([midi(n) for n in chord], t.beat * 1.2, attack=0.02, cutoff=2600 if hard else 2000)
            t.put(stab, i * 4 + hit, 0.18, pan=0.15, wet=0.3)
    riff = []
    for i, chord in enumerate(BOSS_CHORDS):
        riff += [(i * 4 + s * 0.5, 0.6, n) for s, n in enumerate(RIFFS[chord[0]])]
    play_notes(t, riff, lambda f, l: bandura(f, l, r, bright=0.7, t60=0.9), 0.4, pan=-0.3, wet=0.15, r=r, humanize=0.004)
    play_notes(t, roots(BOSS_CHORDS, 4, 0.5, length=0.4), lambda f, l: bass(f, l), 0.45, wet=0.0)
    boss_drums(t, r, 8, hard)
    if hard:
        for i, chord in enumerate(BOSS_CHORDS):
            t.put(choir([midi(n + 12) for n in chord[1:]], t.beat * 4.3, r, attack=0.3), i * 4, 0.07, wet=0.5)
        lead = [74, 77, 76, 74, 73, None, 69, None, 70, 72, 74, 76, 77, 76, 74, 73,
                74, 77, 81, 79, 77, 76, 74, None, 76, 77, 79, 76, 73, None, 69, None]
        play_notes(t, [(i, 0.95, n) for i, n in enumerate(lead)], lambda f, l: sopilka(f, l, r), 0.2, pan=0.35, wet=0.35, r=r)
    return t.finish(t60=1.6, damp=0.45, target_rms=0.13)


TRACKS = {
    "steppe": steppe,
    "kurgan": kurgan,
    "boss_1": lambda: boss(120, False, 31),
    "boss_2": lambda: boss(140, True, 37),
}
