"""Genera los sonidos de MAGEC por síntesis (sin archivos de terceros).

Uso:  python3 tools/gen_audio.py      -> escribe audio/*.wav
Necesita numpy.
"""
import os
import wave

import numpy as np

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
rng = np.random.default_rng(7)


def t(sec):
    return np.arange(int(SR * sec)) / SR


def lowpass(x, cutoff):
    """Filtro de un polo; cutoff puede ser un array (variable en el tiempo)."""
    cutoff = np.broadcast_to(np.asarray(cutoff, dtype=float), x.shape)
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc = (1 - a[i]) * x[i] + a[i] * acc
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def norm(x, peak=0.9):
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def loopify(x, fade=0.5):
    """Funde el final con el principio para que el bucle no se note."""
    n = int(SR * fade)
    head, body = x[:n], x[n:].copy()
    ramp = np.linspace(0, 1, n)
    body[-n:] = body[-n:] * (1 - ramp) + head * ramp
    return body


def env(n, attack, decay):
    a = int(SR * attack)
    e = np.exp(-np.arange(n) / (SR * decay))
    e[:a] *= np.linspace(0, 1, a) if a > 0 else 1
    return e


def pluck(freq, sec, damp=0.996):
    """Cuerda pulsada (Karplus-Strong), suena parecido a un timple."""
    n = int(SR * sec)
    p = int(SR / freq)
    buf = rng.uniform(-1, 1, p)
    out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % p]
        buf[i % p] = damp * 0.5 * (buf[i % p] + buf[(i + 1) % p])
    return out


def save(name, x):
    os.makedirs(OUT, exist_ok=True)
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("audio/%s.wav  %.1fs" % (name, len(x) / SR))


# ---------- Ambiente ----------
def ocean():
    tt = t(12.5)
    noise = rng.normal(0, 1, len(tt))
    swell = 0.55 + 0.45 * np.sin(2 * np.pi * tt / 6.25) ** 2
    cut = 300 + 900 * swell
    x = lowpass(noise, cut) * swell
    x += 0.25 * highpass(lowpass(noise, 3000), 1200) * swell ** 3  # espuma
    return norm(loopify(x), 0.7)


def wind():
    tt = t(12.5)
    noise = rng.normal(0, 1, len(tt))
    gust = 0.5 + 0.5 * np.sin(2 * np.pi * tt / 12.0) * np.sin(2 * np.pi * tt / 4.1)
    band = highpass(lowpass(noise, 500 + 700 * gust), 250)
    return norm(loopify(band * (0.4 + 0.6 * gust)), 0.6)


def engine():
    tt = t(2.5)
    putt = (np.sin(2 * np.pi * 9 * tt) > 0.3).astype(float)
    putt = lowpass(putt, 60)
    tone = np.sign(np.sin(2 * np.pi * 52 * tt)) * 0.5 + np.sin(2 * np.pi * 104 * tt) * 0.3
    x = lowpass(tone, 400) * (0.4 + putt) + 0.15 * lowpass(rng.normal(0, 1, len(tt)), 800) * putt
    return norm(loopify(x, 0.2), 0.6)


def heartbeat():
    tt = t(1.1)
    x = np.zeros(len(tt))
    for start, amp in ((0.0, 1.0), (0.22, 0.7)):
        s = int(start * SR)
        n = int(0.18 * SR)
        k = np.arange(n) / SR
        x[s:s + n] += amp * np.sin(2 * np.pi * (55 - 60 * k) * k) * np.exp(-k * 22)
    return norm(x, 0.9)


# ---------- Música ----------
def mtof(m):
    return 440 * 2 ** ((m - 69) / 12)


def reverb(x, secs=2.6, mix=0.35):
    """Reverberación por convolución con una cola de ruido que decae."""
    n = int(SR * secs)
    ir = rng.normal(0, 1, n) * np.exp(-np.arange(n) / (SR * secs / 6))
    ir = lowpass(ir, 3500)
    ir /= np.sqrt(np.sum(ir ** 2))
    size = 1 << int(np.ceil(np.log2(len(x) + n)))
    wet = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)[: len(x) + n]
    # la cola vuelve al principio para que el bucle sea continuo
    tail = wet[len(x):]
    wet = wet[: len(x)].copy()
    wet[: len(tail)] += tail
    return x * (1 - mix) + norm(wet, np.max(np.abs(x)) or 1) * mix


def pad(freqs, sec, cutoff=1400, attack=1.5):
    """Colchón de cuerdas: sierras desafinadas y filtradas."""
    tt = t(sec)
    x = np.zeros(len(tt))
    for f in freqs:
        for d in (-0.12, 0.0, 0.11):
            ph = rng.uniform(0, 1)
            x += 2 * ((tt * f * (1 + d / 100) + ph) % 1) - 1
    x = lowpass(x, cutoff)
    e = np.minimum(tt / attack, 1) * np.minimum((sec - tt) / attack, 1)
    return x * np.clip(e, 0, 1)


def compose(chords, bpm, beats_per_chord, arp, melody, pad_vol=0.25, pluck_vol=0.55, bass_vol=0.35, mel_vol=0.4):
    beat = 60 / bpm
    total = len(chords) * beats_per_chord * beat
    x = np.zeros(int(SR * (total + 3)))
    for ci, ch in enumerate(chords):
        start = ci * beats_per_chord * beat
        s0 = int(start * SR)
        p = pad([mtof(m) for m in ch[1:]], beats_per_chord * beat + 1.0)
        x[s0:s0 + len(p)] += p * pad_vol / 3
        # bajo
        b = t(beats_per_chord * beat)
        bass = np.sin(2 * np.pi * mtof(ch[0]) * b) * np.exp(-b / 3.0)
        x[s0:s0 + len(bass)] += bass * bass_vol
        # arpegio de timple
        steps = int(beats_per_chord * 2)
        for k in range(steps):
            m = ch[1:][arp[k % len(arp)] % (len(ch) - 1)] + (12 if arp[k % len(arp)] >= len(ch) - 1 else 0)
            tone = pluck(mtof(m), 1.6, 0.996) * (1.0 if k % 4 == 0 else 0.7)
            i0 = int((start + k * beat / 2) * SR)
            x[i0:i0 + len(tone)] += tone * pluck_vol
    # melodía (nota, inicio en pulsos, duración en pulsos)
    for m, st, du in melody:
        tt = t(du * beat + 0.5)
        f = mtof(m)
        vib = 1 + 0.004 * np.sin(2 * np.pi * 5 * tt) * np.minimum(tt / 0.4, 1)
        tone = np.sin(2 * np.pi * f * np.cumsum(vib) / SR) + 0.3 * np.sin(4 * np.pi * f * np.cumsum(vib) / SR)
        tone *= np.minimum(tt / 0.08, 1) * np.exp(-np.maximum(tt - du * beat, 0) / 0.2) * (0.85 + 0.15 * np.exp(-tt))
        i0 = int(st * beat * SR)
        x[i0:i0 + len(tone)] += tone * mel_vol
    x = x[: int(SR * total)]
    return x


def menu_music():
    # La menor, lenta y melancólica: Am - F - C - G - Am - F - Dm - E
    A = [45, 57, 60, 64]
    F = [41, 57, 60, 65]
    C = [36, 55, 60, 64]
    G = [43, 55, 59, 62]
    Dm = [38, 57, 62, 65]
    E = [40, 56, 59, 64]
    chords = [A, F, C, G, A, F, Dm, E]
    mel = [(76, 0, 3), (74, 3, 1), (72, 4, 4), (69, 8, 3), (67, 11, 1), (69, 12, 4),
           (72, 16, 2), (74, 18, 2), (76, 20, 4), (79, 24, 3), (77, 27, 1), (76, 28, 4)]
    x = compose(chords, 66, 4, [0, 1, 2, 1, 3, 2, 1, 2], mel, pad_vol=0.3, pluck_vol=0.45, mel_vol=0.22)
    return norm(reverb(lowpass(x, 5000), 3.2, 0.42), 0.75)


def day_music():
    # Re mixolidio, luminoso: D - C - G - D
    D = [38, 62, 66, 69]
    C = [36, 60, 64, 67]
    G = [43, 62, 67, 71]
    A = [45, 61, 64, 69]
    chords = [D, C, G, D, D, C, G, A]
    mel = [(74, 2, 1), (76, 3, 1), (78, 4, 2), (76, 6, 2), (74, 8, 3), (72, 11, 1), (71, 12, 4),
           (74, 18, 1), (76, 19, 1), (78, 20, 2), (81, 22, 2), (79, 24, 3), (76, 27, 1), (73, 28, 4)]
    x = compose(chords, 92, 4, [0, 1, 2, 3, 2, 1, 2, 3], mel, pad_vol=0.18, pluck_vol=0.6, mel_vol=0.18)
    return norm(reverb(lowpass(x, 5500), 2.0, 0.25), 0.75)


def _old_day_music():
    # Arpegio de timple en Re mixolidio, tranquilo y luminoso.
    bpm = 84
    beat = 60 / bpm
    notes = [62, 66, 69, 74, 72, 69, 66, 69, 60, 64, 67, 72, 71, 67, 64, 67,
             62, 66, 69, 74, 76, 74, 69, 66, 67, 71, 74, 79, 78, 74, 71, 74]
    total = len(notes) * beat / 2
    x = np.zeros(int(SR * (total + 2)))
    for i, m in enumerate(notes):
        f = 440 * 2 ** ((m - 69) / 12)
        s = int(i * beat / 2 * SR)
        tone = pluck(f, 1.6, 0.995) * (0.9 if i % 4 == 0 else 0.6)
        x[s:s + len(tone)] += tone
    # bajo suave
    for i, m in enumerate([38, 36, 38, 43]):
        f = 440 * 2 ** ((m - 69) / 12)
        s = int(i * 8 * beat / 2 * SR)
        k = t(beat * 4)
        x[s:s + len(k)] += 0.35 * np.sin(2 * np.pi * f * k) * env(len(k), 0.05, 1.2)
    x = x[: int(SR * total) + int(SR * 0.5)]
    return norm(loopify(lowpass(x, 3500), 0.5), 0.6)


def night_drone():
    # Pedal grave en menor con batidos lentos y un silbido lejano.
    tt = t(16.5)
    x = np.zeros(len(tt))
    for f, a in ((55.0, 0.5), (55.4, 0.4), (82.4, 0.25), (65.4, 0.3), (130.8, 0.08)):
        x += a * np.sin(2 * np.pi * f * tt + rng.uniform(0, 6))
    x *= 0.7 + 0.3 * np.sin(2 * np.pi * tt / 8.25)
    whistle = np.sin(2 * np.pi * (880 + 40 * np.sin(2 * np.pi * tt / 3)) * tt)
    whistle *= np.clip(np.sin(2 * np.pi * (tt - 5) / 16.5), 0, 1) ** 6 * 0.08
    x += whistle + 0.05 * lowpass(rng.normal(0, 1, len(tt)), 200)
    return norm(reverb(loopify(x, 1.0), 4.0, 0.4), 0.7)


# ---------- Efectos ----------
def rumble():
    tt = t(6.0)
    e = np.minimum(tt / 1.2, 1) * np.exp(-np.maximum(tt - 2.5, 0) / 1.3)
    x = lowpass(rng.normal(0, 1, len(tt)), 90) * 4 + 0.6 * np.sin(2 * np.pi * 31 * tt)
    return norm(x * e, 0.95)


def splash():
    n = int(SR * 0.7)
    x = highpass(lowpass(rng.normal(0, 1, n), 4000), 500) * env(n, 0.01, 0.15)
    return norm(x, 0.7)


def catch():
    x = np.zeros(int(SR * 1.4))
    for i, m in enumerate((74, 78, 81)):
        tone = pluck(440 * 2 ** ((m - 69) / 12), 1.0)
        s = int(i * 0.12 * SR)
        x[s:s + len(tone)] += tone
    return norm(x, 0.7)


def mutant():
    tt = t(1.8)
    x = np.sin(2 * np.pi * (220 - 70 * tt) * tt) + np.sin(2 * np.pi * (233 - 80 * tt) * tt)
    x += 0.5 * np.sin(2 * np.pi * (311 - 120 * tt) * tt)
    return norm(x * env(len(tt), 0.05, 0.7), 0.6)


def hit():
    tone = pluck(880, 0.35)
    return norm(tone, 0.5)


def miss():
    tt = t(0.3)
    x = lowpass(rng.normal(0, 1, len(tt)), 600) + 0.6 * np.sin(2 * np.pi * 110 * tt)
    return norm(x * env(len(tt), 0.005, 0.07), 0.5)


def knock():
    x = np.zeros(int(SR * 1.2))
    for s in (0.0, 0.35):
        k = t(0.3)
        thump = np.sin(2 * np.pi * (90 - 120 * k) * k) * np.exp(-k * 18)
        thump += 0.4 * lowpass(rng.normal(0, 1, len(k)), 700) * np.exp(-k * 30)
        i = int(s * SR)
        x[i:i + len(k)] += thump
    return norm(x, 0.95)


def lamp():
    tt = t(0.8)
    x = np.sin(2 * np.pi * 660 * tt) * 0.4 + np.sin(2 * np.pi * 990 * tt) * 0.3
    x += 0.3 * highpass(rng.normal(0, 1, len(tt)), 2000) * np.exp(-tt * 30)
    return norm(x * env(len(tt), 0.01, 0.25), 0.4)


def rain():
    tt = t(10.5)
    noise = rng.normal(0, 1, len(tt))
    x = highpass(lowpass(noise, 6000), 1500) * 0.6 + lowpass(noise, 400) * 0.5
    drops = (rng.random(len(tt)) > 0.9993).astype(float)
    x += highpass(lowpass(drops, 3000), 800) * 6
    return norm(loopify(x), 0.6)


def growl():
    # gruñido del Tibicena: tono grave con aspereza
    tt = t(2.2)
    f = 70 + 15 * np.sin(2 * np.pi * 3 * tt)
    phase = np.cumsum(2 * np.pi * f / SR)
    x = np.sign(np.sin(phase)) * 0.6 + np.sin(phase * 2) * 0.3
    x *= 0.6 + 0.4 * lowpass(np.abs(rng.normal(0, 1, len(tt))), 30) * 3
    x = lowpass(x, 700)
    return norm(x * env(len(tt), 0.2, 0.9), 0.9)


def crack():
    # casco contra roca
    n = int(SR * 0.9)
    k = np.arange(n) / SR
    x = np.sin(2 * np.pi * (70 - 40 * k) * k) * np.exp(-k * 9)
    x += lowpass(rng.normal(0, 1, n), 2500) * np.exp(-k * 14) * 0.8
    return norm(x, 0.95)


def dolphin():
    tt = t(0.6)
    f = 2200 + 1400 * np.sin(2 * np.pi * 4 * tt)
    x = np.sin(np.cumsum(2 * np.pi * f / SR)) * env(len(tt), 0.02, 0.2)
    return norm(x, 0.35)


def gull():
    tt = t(0.7)
    f = 1400 - 600 * tt
    x = np.sin(np.cumsum(2 * np.pi * f / SR)) + 0.3 * highpass(rng.normal(0, 1, len(tt)), 2000)
    x *= np.clip(np.sin(np.pi * tt / 0.7), 0, 1) ** 0.5
    return norm(x, 0.3)


def stone():
    # La Piedra de Magec al encenderse: acorde que se abre.
    tt = t(4.0)
    x = np.zeros(len(tt))
    for i, m in enumerate((50, 57, 62, 66, 69, 74)):
        f = 440 * 2 ** ((m - 69) / 12)
        x += np.sin(2 * np.pi * f * tt) * np.clip((tt - i * 0.25) / 0.5, 0, 1)
    return norm(x * np.exp(-np.maximum(tt - 2.5, 0) / 0.6), 0.6)


if __name__ == "__main__":
    for fn in (ocean, wind, engine, heartbeat, day_music, night_drone,
               rumble, splash, catch, mutant, hit, miss, knock, lamp, stone,
               rain, growl, crack, dolphin, gull, menu_music):
        save(fn.__name__, fn())
