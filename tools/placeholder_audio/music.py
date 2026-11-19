"""Music: a few folk-flavoured instruments and four looping tracks.

Every track is a stereo pair built on a grid of beats. Notes are mixed
with wrap-around, so whatever rings past the end comes in at the start,
and the reverb runs over two passes of the loop, so the seam is silent."""

import math

from dsp import (
    RATE, add_stereo, adsr, biquad, fm, layer, loop_freq, master, midi, mul,
    n_of, noise, osc, perc, reverb, saturate, scale,
)


# --- instruments ----------------------------------------------------------------


def bandura(freq, length, r, bright=0.55, t60=2.2):
    """Karplus-Strong string, excited by a soft noise burst, with a
    wooden body resonance under it."""
    period = max(2, int(RATE / freq))
    rho = 10.0 ** (-3.0 / (t60 * freq))
    buf = [r.uniform(-1.0, 1.0) for _ in range(period)]
    for i in range(1, period):
        buf[i] = buf[i - 1] + bright * (buf[i] - buf[i - 1])
    n = n_of(length)
    out = [0.0] * n
    j = 0
    for i in range(n):
        a = buf[j]
        k = j + 1 if j + 1 < period else 0
        out[i] = a
        buf[j] = rho * 0.5 * (a + buf[k])
        j = k
    body = biquad(out, "band", 220.0, q=1.5)
    return biquad(layer((0, out, 1.0), (0, body, 0.6)), "high", 70.0)


def sopilka(freq, length, r):
    """A wooden flute: a soft tone, a little breath and late vibrato."""
    tone = layer(
        (0, osc("sine", freq, length, vibrato=0.18, vib_rate=5.2, vib_delay=0.25), 1.0),
        (0, osc("sine", freq * 2.0, length, vibrato=0.18, vib_rate=5.2, vib_delay=0.25), 0.18),
        (0, osc("triangle", freq * 3.0, length), 0.05),
    )
    breath = biquad(noise(length, r), "band", freq * 2.0, q=3.0)
    return mul(layer((0, tone, 1.0), (0, breath, 0.25)), adsr(length, 0.06, 0.1, 0.85, min(0.25, length * 0.4)))


def strings(freqs, length, attack=0.6, cutoff=1600.0):
    """A section pad: three detuned saws per note, darkened."""
    out = []
    for f in freqs:
        for cents in (-8.0, 0.0, 7.0):
            out = layer((0, out, 1.0), (0, osc("saw", f * 2.0 ** (cents / 1200.0), length), 0.25))
    out = biquad(out, "low", cutoff, q=0.8)
    return mul(out, adsr(length, attack, 0.3, 0.85, min(1.0, length * 0.4)))


def choir(freqs, length, r, vowel=(800, 1150), attack=1.0):
    out = []
    for f in freqs:
        for cents in (-6.0, 6.0):
            src = osc("saw", f * 2.0 ** (cents / 1200.0), length, vibrato=0.12, vib_rate=r.uniform(4.5, 5.5))
            out = layer((0, out, 1.0), (0, biquad(src, "band", vowel[0], q=5.0), 0.5), (0, biquad(src, "band", vowel[1], q=6.0), 0.3))
    return mul(out, adsr(length, attack, 0.3, 0.9, min(1.5, length * 0.4)))


def bass(freq, length):
    tone = layer((0, osc("triangle", freq, length), 1.0), (0, osc("saw", freq, length), 0.25))
    return mul(biquad(tone, "low", 500.0), adsr(length, 0.005, 0.15, 0.7, 0.08))


def kick(r):
    body = mul(osc("sine", 140, 0.35, 45, glide=0.06), perc(0.35, 0.001, 0.3))
    beater = mul(biquad(noise(0.01, r), "band", 3000, q=1.0), perc(0.01, 0.0005))
    return saturate(layer((0, body, 1.0), (0, beater, 0.3)), 1.5)


def frame_drum(r, tone=190.0):
    skin = mul(biquad(noise(0.2, r), "band", 1600, 900, q=1.2), perc(0.2, 0.001, 0.15))
    shell = mul(osc("sine", tone, 0.2, tone * 0.8), perc(0.2, 0.001, 0.16))
    return layer((0, skin, 1.2), (0, shell, 0.7))


def tom(r, freq):
    return layer((0, mul(osc("sine", freq, 0.35, freq * 0.7), perc(0.35, 0.001, 0.3)), 1.0), (0, frame_drum(r, freq * 1.5), 0.3))


def hat(r, length=0.04):
    return mul(biquad(noise(length, r), "high", 7000), perc(length, 0.0005))


def bell(freq, length):
    return fm(freq, length, [3.51], 1.4, length * 0.25, length)


# --- arranging --------------------------------------------------------------------


class Track:
    def __init__(self, bpm, bars, beats_per_bar=4):
        self.beat = 60.0 / bpm
        self.length = self.beat * beats_per_bar * bars
        n = n_of(self.length)
        self.dry = ([0.0] * n, [0.0] * n)
        self.send = ([0.0] * n, [0.0] * n)

    def put(self, sig, beat, gain=1.0, pan=0.0, wet=0.3, r=None, humanize=0.0):
        at = beat * self.beat
        if r and humanize:
            at += r.uniform(-humanize, humanize)
            gain *= r.uniform(0.85, 1.0)
        add_stereo(self.dry, sig, at, gain, pan)
        if wet:
            add_stereo(self.send, sig, at, gain * wet, pan)

    def bed(self, sig, gain, pan=0.0, wet=0.3):
        self.put(sig, 0.0, gain, pan, wet)

    def finish(self, t60, damp=0.4, size=1.0, target_rms=0.11):
        wl, wr = reverb(self.send[0], self.send[1], t60=t60, damp=damp, size=size, predelay=0.02, loop=True)
        left = [a + b for a, b in zip(self.dry[0], wl)]
        right = [a + b for a, b in zip(self.dry[1], wr)]
        return master([left, right], target_rms)


def wind(track, r, gain):
    """A slowly breathing band of noise, its own loop on each side."""
    for side, pan in ((0, -0.7), (1, 0.7)):
        gust = biquad(noise(track.length, r, "pink"), "band", 500.0, q=0.7)
        rate = loop_freq(0.11 + side * 0.04, track.length)
        swell = [0.55 + 0.45 * math.sin(2 * math.pi * rate * i / RATE + side) for i in range(len(gust))]
        track.put(mul(gust, swell), 0.0, gain, pan, wet=0.1)


def drone(track, note, gain, cutoff=600.0):
    f = loop_freq(midi(note), track.length)
    tone = layer((0, osc("saw", f, track.length), 0.5), (0, osc("sine", f, track.length), 1.0))
    track.bed(biquad(tone, "low", cutoff), gain, wet=0.3)


def play_chords(track, chords, bar_beats, gain, attack=0.6, cutoff=1600.0, wet=0.35):
    for i, chord in enumerate(chords):
        pad = strings([midi(n) for n in chord], bar_beats * track.beat + 0.6, attack, cutoff)
        track.put(pad, i * bar_beats, gain, pan=-0.1 if i % 2 else 0.1, wet=wet)


def play_notes(track, notes, make, gain, pan=0.0, wet=0.3, r=None, humanize=0.008):
    """`notes`: (beat, beats long, midi note) triples."""
    for beat, beats, note in notes:
        if note is None:
            continue
        track.put(make(midi(note), beats * track.beat), beat, gain, pan, wet, r, humanize)
