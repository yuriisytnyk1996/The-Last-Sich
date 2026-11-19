"""Signal building blocks: oscillators, envelopes, filters, reverb and
mastering. Signals are plain lists of floats at RATE (mono); stereo is a
pair of lists. Standard library only, so loops are written for speed."""

import math
import random
from collections import deque

RATE = 44100
TAU = 2.0 * math.pi


def n_of(seconds):
    return max(1, int(seconds * RATE))


def zeros(seconds):
    return [0.0] * n_of(seconds)


def midi(note):
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def loop_freq(freq, length):
    """The nearest frequency with a whole number of cycles in `length` s,
    so a tone that runs through a loop has no click at the seam."""
    return max(1, round(freq * length)) / length


# --- mixing -------------------------------------------------------------------


def add(dst, src, at=0.0, gain=1.0, wrap=False):
    start = int(at * RATE)
    n = len(dst)
    if wrap:
        for i, s in enumerate(src):
            dst[(start + i) % n] += s * gain
        return dst
    if start + len(src) > n:
        dst.extend([0.0] * (start + len(src) - n))
    for i, s in enumerate(src):
        dst[start + i] += s * gain
    return dst


def scale(sig, g):
    return [s * g for s in sig]


def mul(sig, env):
    return [a * b for a, b in zip(sig, env)]


def layer(*parts):
    """Mixes (at, signal, gain) parts into one mono signal."""
    out = []
    for at, sig, g in parts:
        add(out, sig, at, g)
    return out


def pan_gains(pan):
    angle = (pan + 1.0) * math.pi / 4.0
    return math.cos(angle), math.sin(angle)


def add_stereo(dst, src, at=0.0, gain=1.0, pan=0.0, wrap=True):
    gl, gr = pan_gains(pan)
    add(dst[0], src, at, gain * gl, wrap)
    add(dst[1], src, at, gain * gr, wrap)


# --- envelopes ----------------------------------------------------------------


def perc(seconds, attack=0.002, t60=None):
    """Linear attack, then an exponential fall reaching -60 dB at `t60`."""
    n = n_of(seconds)
    a = max(1, int(attack * RATE))
    k = 6.9 / ((t60 or seconds) * RATE)
    return [i / a if i < a else math.exp(-(i - a) * k) for i in range(n)]


def adsr(seconds, attack, decay, sustain, release):
    n = n_of(seconds)
    a, d, r = n_of(attack), n_of(decay), n_of(release)
    out = []
    for i in range(n):
        if i < a:
            v = i / a
        elif i < a + d:
            v = 1.0 - (1.0 - sustain) * (i - a) / d
        else:
            v = sustain
        if i > n - r:
            v *= (n - i) / r
        out.append(v)
    return out


def fade_edges(sig, fade_in=0.001, fade_out=0.01):
    a, b = n_of(fade_in), n_of(fade_out)
    n = len(sig)
    for i in range(min(a, n)):
        sig[i] *= i / a
    for i in range(min(b, n)):
        sig[n - 1 - i] *= i / b
    return sig


# --- sources ------------------------------------------------------------------


def _blep(t, dt):
    if t < dt:
        t /= dt
        return t + t - t * t - 1.0
    if t > 1.0 - dt:
        t = (t - 1.0) / dt
        return t * t + t + t + 1.0
    return 0.0


def osc(shape, f0, seconds, f1=None, glide=None, vibrato=0.0, vib_rate=5.0, vib_delay=0.0, phase=0.0):
    """Band-limited oscillator. Pitch glides exponentially from f0 to f1
    over `glide` s (the whole length by default); vibrato is in semitones."""
    n = n_of(seconds)
    f1 = f1 or f0
    g = n_of(glide) if glide else n
    ratio = f1 / f0
    out = [0.0] * n
    p = phase
    vd = n_of(vib_delay) if vib_delay else 0
    for i in range(n):
        f = f0 * ratio ** min(1.0, i / g)
        if vibrato and i > vd:
            f *= 2.0 ** (vibrato * math.sin(TAU * vib_rate * i / RATE) / 12.0)
        dt = f / RATE
        p += dt
        p -= int(p)
        if shape == "sine":
            v = math.sin(TAU * p)
        elif shape == "saw":
            v = 2.0 * p - 1.0 - _blep(p, dt)
        elif shape == "square":
            v = (1.0 if p < 0.5 else -1.0) + _blep(p, dt) - _blep((p + 0.5) % 1.0, dt)
        else:
            v = 4.0 * abs(p - 0.5) - 1.0
        out[i] = v
    return out


def fm(freq, seconds, ratios, index, index_t60, amp_t60, attack=0.001):
    """FM: a sine carrier bent by sine modulators at `ratios` of `freq`.
    Inharmonic ratios ring like struck metal; the brightness (`index`)
    dies away faster than the sound itself."""
    n = n_of(seconds)
    a = max(1, int(attack * RATE))
    ki = 6.9 / (index_t60 * RATE)
    ka = 6.9 / (amp_t60 * RATE)
    w = TAU * freq / RATE
    mods = [TAU * freq * r / RATE for r in ratios]
    out = [0.0] * n
    for i in range(n):
        idx = index * math.exp(-i * ki)
        m = 0.0
        for wm in mods:
            m += math.sin(wm * i)
        env = (i / a if i < a else 1.0) * math.exp(-max(0, i - a) * ka)
        out[i] = math.sin(w * i + idx * m) * env
    return out


def noise(seconds, rng, color="white"):
    n = n_of(seconds)
    u = rng.uniform
    if color == "white":
        return [u(-1.0, 1.0) for _ in range(n)]
    b0 = b1 = b2 = 0.0
    out = [0.0] * n
    for i in range(n):
        w = u(-1.0, 1.0)
        b0 = 0.99765 * b0 + w * 0.0990460
        b1 = 0.96300 * b1 + w * 0.2965164
        b2 = 0.57000 * b2 + w * 1.0526913
        out[i] = (b0 + b1 + b2 + w * 0.1848) * 0.2
    return out


# --- filters ------------------------------------------------------------------


def _coeffs(kind, f, q):
    f = min(max(f, 10.0), RATE * 0.45)
    w = TAU * f / RATE
    cw, sw = math.cos(w), math.sin(w)
    alpha = sw / (2.0 * q)
    if kind == "low":
        b0, b1, b2 = (1 - cw) / 2, 1 - cw, (1 - cw) / 2
    elif kind == "high":
        b0, b1, b2 = (1 + cw) / 2, -(1 + cw), (1 + cw) / 2
    else:
        b0, b1, b2 = alpha, 0.0, -alpha
    a0 = 1 + alpha
    return b0 / a0, b1 / a0, b2 / a0, -2 * cw / a0, (1 - alpha) / a0


def biquad(sig, kind, f0, f1=None, q=0.707):
    """Resonant low, high or band pass; the cutoff sweeps exponentially
    from f0 to f1 over the signal."""
    n = len(sig)
    out = [0.0] * n
    x1 = x2 = y1 = y2 = 0.0
    b0, b1, b2, a1, a2 = _coeffs(kind, f0, q)
    sweep = f1 is not None and f1 != f0
    ratio = (f1 / f0) if sweep else 1.0
    for i in range(n):
        if sweep and i % 32 == 0:
            b0, b1, b2, a1, a2 = _coeffs(kind, f0 * ratio ** (i / n), q)
        x = sig[i]
        y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, x, y1, y
        out[i] = y
    return out


def saturate(sig, drive=2.0):
    norm = math.tanh(drive)
    return [math.tanh(s * drive) / norm for s in sig]


# --- space --------------------------------------------------------------------


def reverb(left, right=None, t60=2.0, damp=0.35, size=1.0, predelay=0.015, loop=False):
    """Feedback delay network reverb. Returns the wet signal only (L, R).
    With `loop` the input is run twice and the second pass kept, so the
    tail of the end rings on into the start of a seamless loop."""
    right = right if right is not None else left
    n = len(left)
    if loop:
        left, right = left + left, right + right
    lens = [int(l * size) for l in (1687, 1601, 2053, 2251)]
    gains = [10.0 ** (-3.0 * l / (t60 * RATE)) for l in lens]
    bufs = [[0.0] * l for l in lens]
    idx = [0, 0, 0, 0]
    lp = [0.0, 0.0, 0.0, 0.0]
    pd = max(1, n_of(predelay))
    pre_l, pre_r = [0.0] * pd, [0.0] * pd
    total = len(left)
    out_l, out_r = [0.0] * total, [0.0] * total
    keep = 1.0 - damp
    for i in range(total):
        j = i % pd
        il, ir = pre_l[j], pre_r[j]
        pre_l[j], pre_r[j] = left[i], right[i]
        o = [bufs[k][idx[k]] for k in range(4)]
        out_l[i] = o[0] + o[2]
        out_r[i] = o[1] + o[3]
        h0, h1 = o[0] + o[1], o[0] - o[1]
        h2, h3 = o[2] + o[3], o[2] - o[3]
        mixed = (h0 + h2, h1 + h3, h0 - h2, h1 - h3)
        ins = (il, ir, il, ir)
        for k in range(4):
            lp[k] = mixed[k] * 0.5 * keep + lp[k] * damp
            bufs[k][idx[k]] = ins[k] + lp[k] * gains[k]
            idx[k] = (idx[k] + 1) % lens[k]
    if loop:
        return out_l[n:], out_r[n:]
    return out_l, out_r


def mono_reverb(sig, wet=0.2, tail=0.6, **kw):
    """A dry mono sound with a short room around it, mixed back to mono."""
    padded = sig + [0.0] * n_of(tail)
    wl, wr = reverb(padded, **kw)
    return [d + (a + b) * 0.5 * wet for d, a, b in zip(padded, wl, wr)]


# --- mastering ----------------------------------------------------------------


def dc_block(sig):
    return biquad(sig, "high", 25.0)


def rms(chs):
    total = sum(s * s for c in chs for s in c)
    return math.sqrt(total / max(1, sum(len(c) for c in chs)))


def limit(chs, ceiling=0.89, release=0.08, look=0.004):
    """Look-ahead peak limiter over one or two channels."""
    n = len(chs[0])
    need = [1.0] * n
    for i in range(n):
        peak = max(abs(c[i]) for c in chs)
        if peak > ceiling:
            need[i] = ceiling / peak
    # Sliding minimum of `need` over the next `look` seconds.
    la = n_of(look)
    gain = [1.0] * n
    window = deque()
    for i in range(n - 1, -1, -1):
        while window and need[window[-1]] >= need[i]:
            window.pop()
        window.append(i)
        if window[0] > i + la:
            window.popleft()
        gain[i] = need[window[0]]
    rel = 1.0 / n_of(release)
    g = 1.0
    for i in range(n):
        g = gain[i] if gain[i] < g else min(gain[i], g + (1.0 - g) * rel * 4)
        for c in chs:
            c[i] *= g
    return chs


def master(chs, target_rms=0.12, ceiling=0.89):
    chs = [dc_block(c) for c in chs]
    level = rms(chs) or 1.0
    chs = [scale(c, target_rms / level) for c in chs]
    return limit(chs, ceiling)


def normalize(sig, peak=0.89):
    top = max((abs(s) for s in sig), default=0.0) or 1.0
    return [s * peak / top for s in sig]


def new_rng(seed):
    return random.Random(seed)
