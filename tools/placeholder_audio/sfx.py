"""Sound effect recipes. Each takes a random generator (one per take, so
takes differ) and returns a mono signal. Most are layered the way a
recorded effect would be: a short transient, a body and a tail."""

from dsp import (
    adsr, biquad, fm, layer, mono_reverb, mul, noise, osc, perc, saturate, scale,
)


# --- shared layers --------------------------------------------------------------


def click(r, length=0.006, cutoff=3000.0):
    return mul(biquad(noise(length, r), "high", cutoff), perc(length, 0.0005))


def thump(f0, f1, length, t60=None):
    return mul(osc("sine", f0, length, f1, glide=length * 0.4), perc(length, 0.001, t60 or length))


def whoosh(r, length, f0, f1, q=1.2, attack=0.35):
    """Air moving past: band-passed noise sweeping up, swelling then gone."""
    body = biquad(noise(length, r, "pink"), "band", f0, f1, q)
    env = adsr(length, length * attack, length * 0.2, 0.6, length * 0.45)
    return mul(scale(body, 3.0), env)


def grains(r, length, count, cutoff, grain=0.012):
    """Scattered tiny bursts: gravel, splinters, debris."""
    out = [0.0] * int(length * 44100)
    for _ in range(count):
        g = mul(biquad(noise(grain, r), "band", cutoff * r.uniform(0.6, 1.6), q=2.0), perc(grain, 0.0005))
        layer_at = r.uniform(0.0, length - grain)
        start = int(layer_at * 44100)
        for i, s in enumerate(g):
            if start + i < len(out):
                out[start + i] += s * r.uniform(0.3, 1.0)
    return out


def metal(r, freq, length, bright=4.0):
    """A struck steel blade: inharmonic FM partials plus a bright tick."""
    ring = fm(freq, length, [1.414 * r.uniform(0.99, 1.01), 2.76], bright, length * 0.25, length)
    shimmer = fm(freq * 2.03, length * 0.7, [3.17], bright * 0.5, length * 0.15, length * 0.6)
    return layer((0, click(r, 0.004, 5000), 0.8), (0, ring, 0.6), (0, shimmer, 0.25))


def voice(r, f0, f1, length, formants=(700, 1150), breath=0.2):
    """A grunt: a buzzing source through two vocal formants."""
    src = osc("saw", f0, length, f1, vibrato=0.3, vib_rate=r.uniform(6, 9))
    body = layer((0, biquad(src, "band", formants[0], q=4.0), 1.0), (0, biquad(src, "band", formants[1], q=5.0), 0.6))
    air = biquad(noise(length, r), "band", formants[1] * 1.5, q=1.0)
    return mul(layer((0, body, 1.0), (0, air, breath)), adsr(length, 0.02, length * 0.3, 0.6, length * 0.5))


def bell(freq, length, gain=1.0):
    return scale(fm(freq, length, [3.5], 1.6, length * 0.3, length), gain)


def chord_swell(freqs, length, attack):
    out = []
    for f in freqs:
        tone = layer((0, osc("triangle", f, length, vibrato=0.08, vib_rate=4.5), 0.6), (0, osc("sine", f * 2.0, length), 0.2))
        out = layer((0, out, 1.0), (0, tone, 1.0))
    return mul(out, adsr(length, attack, 0.2, 0.8, length * 0.5))


# --- the cues ---------------------------------------------------------------------


def swing(r):
    return whoosh(r, r.uniform(0.15, 0.19), r.uniform(500, 700), r.uniform(2600, 3400), q=1.4)


def swing_heavy(r):
    air = whoosh(r, 0.3, r.uniform(250, 350), r.uniform(1300, 1700), q=1.1, attack=0.45)
    sub = mul(osc("sine", 70, 0.3, 110), adsr(0.3, 0.12, 0.05, 0.6, 0.12))
    return layer((0, air, 1.0), (0, sub, 0.35))


def hit(r):
    body = mul(biquad(noise(0.1, r), "low", 2200, 350, q=1.2), perc(0.1, 0.001, 0.09))
    return saturate(layer((0, click(r), 0.7), (0, body, 0.9), (0, thump(r.uniform(150, 175), 55, 0.16), 1.0)), 1.8)


def hit_critical(r):
    return layer((0, hit(r), 1.0), (0.005, metal(r, 1180, 0.45, 3.0), 0.5))


def hit_wood(r):
    modes = [biquad(click(r, 0.02, 200), "band", f * r.uniform(0.95, 1.05), q=12.0) for f in (420, 960, 1730)]
    knock = layer(*[(0, m, g) for m, g in zip(modes, (4.0, 2.5, 1.5))])
    return layer((0, knock, 1.0), (0, thump(230, 160, 0.06), 0.5), (0, click(r, 0.004, 2500), 0.4))


def parry(r):
    return mono_reverb(layer((0, metal(r, 1240, 0.9, 5.0), 1.0), (0, whoosh(r, 0.08, 3000, 7000), 0.3)), wet=0.35, tail=0.5, t60=1.2)


def block(r):
    dull = fm(520, 0.3, [1.37, 2.41], 2.5, 0.06, 0.25)
    return layer((0, click(r, 0.005, 2500), 0.6), (0, dull, 0.6), (0, thump(140, 80, 0.12), 0.7))


def guard_slide(r):
    scrape = biquad(noise(0.38, r), "band", 2400, 1500, q=3.0)
    scrape = mul(scale(scrape, 2.5), adsr(0.38, 0.01, 0.1, 0.7, 0.2))
    return layer((0, metal(r, 980, 0.4, 2.5), 0.6), (0, scrape, 0.7))


def jump(r):
    cloth = whoosh(r, 0.11, 400, 1400, q=0.9, attack=0.2)
    return layer((0, cloth, 0.8), (0, thump(110, 70, 0.06), 0.4))


def land(r):
    return layer((0, thump(120, 50, 0.1), 0.9), (0, grains(r, 0.08, 9, 2500), 0.5), (0, click(r, 0.004, 1500), 0.3))


def land_hard(r):
    rumble = mul(biquad(noise(0.35, r), "low", 900, 150), perc(0.35, 0.002, 0.3))
    return saturate(layer((0, thump(90, 35, 0.35), 1.0), (0, rumble, 0.8), (0, grains(r, 0.3, 24, 2000), 0.5)), 1.5)


def dash(r):
    return layer((0, whoosh(r, 0.16, 900, 5000, q=0.9, attack=0.15), 1.0), (0, grains(r, 0.05, 5, 2200), 0.3))


def step(r):
    return layer((0, thump(r.uniform(90, 120), 60, 0.05), 0.6), (0, grains(r, 0.04, r.randint(3, 6), r.uniform(1500, 2600)), 0.7))


def heal(r):
    sparkle = layer(*[(i * 0.08, bell(f, 0.8), 0.35) for i, f in enumerate([1046.5, 1318.5, 1568.0, 2093.0])])
    return mono_reverb(layer((0, chord_swell([261.6, 329.6, 392.0], 1.0, 0.25), 0.5), (0, sparkle, 1.0)), wet=0.5, tail=1.0, t60=2.0)


def player_hurt(r):
    return layer((0, hit(r), 0.7), (0.01, voice(r, r.uniform(150, 170), 110, 0.22), 0.7))


def player_death(r):
    groan = voice(r, 140, 75, 0.9, (600, 1000), breath=0.3)
    fall = layer((0, thump(80, 30, 0.5), 1.0), (0, grains(r, 0.4, 20, 1500), 0.4))
    return mono_reverb(layer((0, hit(r), 0.8), (0.05, groan, 0.7), (0.7, fall, 0.8)), wet=0.35, tail=1.2, t60=2.0)


def enemy_death(r):
    groan = voice(r, r.uniform(105, 125), 65, 0.5, (550, 900), breath=0.3)
    fall = layer((0, thump(90, 35, 0.3), 1.0), (0, grains(r, 0.25, 14, 1800), 0.4))
    return layer((0, groan, 0.7), (0.32, fall, 0.8))


def shot(r):
    crack = mul(biquad(noise(0.03, r), "high", 1800), perc(0.03, 0.0003))
    boom = mul(biquad(noise(0.25, r), "low", 1800, 200, q=1.0), perc(0.25, 0.001, 0.2))
    dry = saturate(layer((0, crack, 1.0), (0, boom, 1.0), (0, thump(110, 40, 0.3), 1.0)), 2.5)
    return mono_reverb(dry, wet=0.45, tail=0.9, t60=1.6, damp=0.5)


def duma(r):
    choir = []
    for f in (293.7, 440.0, 587.3):
        choir = layer((0, choir, 1.0), (0, voice(r, f, f, 1.1, (800, 1150), breath=0.1), 0.5))
    choir = mul(choir, adsr(1.1, 0.35, 0.2, 0.8, 0.5))
    return mono_reverb(layer((0, choir, 1.0), (0.15, bell(1174.7, 0.9), 0.3)), wet=0.5, tail=1.2, t60=2.5)


def execution(r):
    return mono_reverb(
        layer((0, swing_heavy(r), 0.7), (0.12, hit(r), 1.0), (0.12, thump(70, 28, 0.7, 0.6), 1.0)),
        wet=0.3, tail=0.8, t60=1.5,
    )


def item(r):
    notes = [783.99, 987.77, 1174.66, 1567.98]
    return mono_reverb(layer(*[(i * 0.07, bell(f, 0.7), 0.5) for i, f in enumerate(notes)]), wet=0.4, tail=0.8, t60=1.6)


def coin(r):
    return mono_reverb(layer((0, bell(2093.0, 0.25), 0.5), (0.055, bell(2793.8, 0.35), 0.5)), wet=0.25, tail=0.4, t60=0.9)


def upgrade(r):
    notes = [392.0, 523.25, 659.25, 783.99, 1046.5]
    arp = layer(*[(i * 0.11, bell(f, 0.9), 0.45) for i, f in enumerate(notes)])
    return mono_reverb(layer((0, arp, 1.0), (0.45, chord_swell([523.25, 659.25, 783.99], 1.0, 0.1), 0.4)), wet=0.45, tail=1.2, t60=2.2)


def rest(r):
    pad = chord_swell([146.8, 220.0, 293.7, 370.0], 1.8, 0.5)
    fire = grains(r, 1.8, 40, 3500, grain=0.006)
    return mono_reverb(layer((0, pad, 0.6), (0, fire, 0.25)), wet=0.4, tail=1.0, t60=2.0)


def denied(r):
    tone = lambda: mul(biquad(osc("square", 130.8, 0.09), "low", 900), perc(0.09, 0.003, 0.09))
    return layer((0, tone(), 0.6), (0.11, tone(), 0.6))


def break_(r):
    cracks = [(i * r.uniform(0.03, 0.06), hit_wood(r), r.uniform(0.6, 1.0)) for i in range(4)]
    return layer(*cracks, (0, grains(r, 0.45, 40, 2200), 0.6), (0, thump(100, 45, 0.2), 0.6))


def boss_death(r):
    rumble = mul(biquad(noise(2.2, r, "pink"), "low", 1200, 80, q=0.9), perc(2.2, 0.005, 2.0))
    boom = thump(65, 22, 2.0, 1.8)
    return mono_reverb(saturate(layer((0, boom, 1.0), (0, rumble, 1.2), (0, hit(r), 0.8)), 1.6), wet=0.4, tail=1.5, t60=3.0)


def ui_move(r):
    return layer((0, mul(osc("sine", 1760, 0.03), perc(0.03, 0.001, 0.03)), 0.6), (0, click(r, 0.002, 4000), 0.2))


def ui_accept(r):
    return layer((0, bell(880.0, 0.18), 0.5), (0.045, bell(1318.5, 0.25), 0.5))


def ui_back(r):
    return layer((0, bell(880.0, 0.15), 0.45), (0.045, bell(659.25, 0.22), 0.45))


SFX = {
    "swing": swing, "swing_heavy": swing_heavy, "hit": hit, "hit_critical": hit_critical,
    "hit_wood": hit_wood, "parry": parry, "block": block, "guard_slide": guard_slide,
    "jump": jump, "land": land, "land_hard": land_hard, "dash": dash, "step": step,
    "heal": heal, "player_hurt": player_hurt, "player_death": player_death,
    "enemy_death": enemy_death, "shot": shot, "duma": duma, "execution": execution,
    "item": item, "coin": coin, "upgrade": upgrade, "rest": rest, "denied": denied,
    "break": break_, "boss_death": boss_death, "ui_move": ui_move, "ui_accept": ui_accept,
    "ui_back": ui_back,
}

# Sounds heard over and over get several takes (name_1.wav, name_2.wav...).
TAKES = {"step": 4, "hit": 3, "swing": 3, "swing_heavy": 2, "hit_wood": 2, "land": 2, "player_hurt": 2, "enemy_death": 2}
