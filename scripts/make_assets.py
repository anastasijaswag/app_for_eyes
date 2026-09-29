#!/usr/bin/env python3
"""Генерирует звуки и иконку приложения. Нужны numpy и pillow.

    pip install numpy pillow && python3 scripts/make_assets.py
"""
import math
import os
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..", "Resources")
RATE = 44100


# ---------- звуки ----------

def env(n, attack=0.008, tau=0.45):
    t = np.arange(n) / RATE
    e = np.exp(-t / tau)
    a = int(attack * RATE)
    e[:a] *= np.linspace(0, 1, a)
    return e


def tone(freq, dur, tau, partials=((1, 1.0),), attack=0.008):
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    s = sum(amp * np.sin(2 * math.pi * freq * mult * t) for mult, amp in partials)
    return s * env(n, attack, tau)


def drop(dur=0.35, f0=520, f1=1300):
    n = int(dur * RATE)
    t = np.arange(n) / RATE
    f = f1 - (f1 - f0) * np.exp(-t / 0.018)  # быстрый подъём высоты — «кап»
    phase = 2 * math.pi * np.cumsum(f) / RATE
    return np.sin(phase) * env(n, 0.004, 0.07)


def mix(parts, total):
    out = np.zeros(int(total * RATE))
    for offset, s in parts:
        i = int(offset * RATE)
        out[i:i + len(s)] += s[: len(out) - i]
    return out


def save(name, s, peak):
    s = s / (np.max(np.abs(s)) or 1) * peak
    fade = int(0.03 * RATE)
    s[-fade:] *= np.linspace(1, 0, fade)
    data = (s * 32767).astype("<i2").tobytes()
    with wave.open(os.path.join(ROOT, "Sounds", name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)


BELL = ((1, 1.0), (2.76, 0.18), (5.4, 0.05))
save("bell.wav", tone(1046.5, 1.8, 0.55, BELL), 0.45)
save("bell-end.wav", tone(784.0, 1.6, 0.5, BELL), 0.3)

save("drop.wav", mix([(0, drop()), (0.22, drop(f0=620, f1=1550))], 0.7), 0.45)
save("drop-end.wav", mix([(0, drop(f0=440, f1=1050))], 0.45), 0.3)

SOFT = ((1, 1.0), (2, 0.12))
save("chime.wav", mix([(0.0, tone(1318.5, 1.2, 0.4, SOFT)),
                       (0.16, tone(1568.0, 1.2, 0.4, SOFT)),
                       (0.32, tone(1975.5, 1.3, 0.45, SOFT))], 1.7), 0.4)
save("chime-end.wav", mix([(0.0, tone(1568.0, 1.2, 0.4, SOFT)),
                           (0.18, tone(1318.5, 1.3, 0.45, SOFT))], 1.5), 0.28)


# ---------- иконка ----------

S = 1024
CREAM = (243, 236, 221)
INK = (98, 80, 104)


def blob(img, xy, r, color, blur):
    # размываем только альфу, иначе края «грязнятся» чёрным
    alpha = Image.new("L", img.size, 0)
    x, y = xy
    ImageDraw.Draw(alpha).ellipse((x - r, y - r, x + r, y + r), fill=color[3])
    layer = Image.new("RGBA", img.size, color[:3] + (0,))
    layer.putalpha(alpha.filter(ImageFilter.GaussianBlur(blur)))
    img.alpha_composite(layer)


bg = Image.new("RGBA", (S, S), CREAM + (255,))
blob(bg, (330, 330), 260, (233, 185, 181, 200), 120)   # пыльно-розовый
blob(bg, (700, 420), 250, (207, 198, 230, 210), 120)   # лаванда
blob(bg, (560, 780), 280, (168, 184, 148, 190), 130)   # шалфей
blob(bg, (520, 250), 70, (246, 197, 142, 200), 50)     # тёплый огонёк

rng = np.random.default_rng(7)
noise = rng.normal(0, 14, (S, S, 1))
arr = np.asarray(bg).astype(float)
arr[..., :3] = np.clip(arr[..., :3] + noise, 0, 255)
bg = Image.fromarray(arr.astype("uint8"), "RGBA")

# глаз рисуем в 4x и уменьшаем — так линии мягкие
K = 4
eye = Image.new("RGBA", (S * K, S * K), (0, 0, 0, 0))
d = ImageDraw.Draw(eye)


def bez(p0, p1, p2, p3, n=80):
    pts = []
    for i in range(n + 1):
        t = i / n
        x = (1 - t) ** 3 * p0[0] + 3 * (1 - t) ** 2 * t * p1[0] + 3 * (1 - t) * t ** 2 * p2[0] + t ** 3 * p3[0]
        y = (1 - t) ** 3 * p0[1] + 3 * (1 - t) ** 2 * t * p1[1] + 3 * (1 - t) * t ** 2 * p2[1] + t ** 3 * p3[1]
        pts.append((x * K, y * K))
    return pts


L, R, CY = (262, 540), (762, 540), 540
upper = bez(L, (380, 330), (644, 330), R)
lower = bez(R, (644, 730), (380, 730), L)
d.polygon(upper + lower, fill=(252, 248, 240, 255))
cx, cy, pr = 512 * K, 540 * K, 92 * K
d.ellipse((cx - pr, cy - pr, cx + pr, cy + pr), fill=(137, 112, 150, 255))
hr = 26 * K
d.ellipse((cx + 30 * K - hr, cy - 34 * K - hr, cx + 30 * K + hr, cy - 34 * K + hr), fill=(255, 255, 255, 235))
W = 30 * K
d.line(upper, fill=INK + (255,), width=W, joint="curve")
d.line(lower, fill=INK + (255,), width=W, joint="curve")
for a, b in [((380, 420), (340, 330)), ((512, 385), (512, 290)), ((644, 420), (684, 330))]:
    d.line([(a[0] * K, a[1] * K), (b[0] * K, b[1] * K)], fill=INK + (255,), width=W)
for p in [L, R, (340, 330), (512, 290), (684, 330)]:
    r = W // 2
    d.ellipse((p[0] * K - r, p[1] * K - r, p[0] * K + r, p[1] * K + r), fill=INK + (255,))
eye = eye.resize((S, S), Image.LANCZOS)
bg.alpha_composite(eye)

# маска «как у иконок macOS»: скруглённый квадрат 824px с отступом 100px
mask = Image.new("L", (S * K, S * K), 0)
ImageDraw.Draw(mask).rounded_rectangle((100 * K, 100 * K, 924 * K, 924 * K), radius=185 * K, fill=255)
mask = mask.resize((S, S), Image.LANCZOS)
icon = Image.new("RGBA", (S, S), (0, 0, 0, 0))
shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
shadow.paste((60, 40, 50, 70), (0, 12), mask)
icon.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(14)))
icon.paste(bg, (0, 0), mask)
icon.save(os.path.join(ROOT, "AppIcon.png"))
print("ok")
