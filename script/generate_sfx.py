#!/usr/bin/env python3
"""Original Noche Live cues. Named sounds only — no file paths in game logic."""

from __future__ import annotations

import math
import os
import struct
import wave

RATE = 22050
ROOT = os.path.join(os.path.dirname(__file__), "..", "public", "sfx")


def clamp(sample: float) -> int:
    return max(-32767, min(32767, int(sample * 32767)))


def write(name: str, samples: list[float]) -> None:
    os.makedirs(ROOT, exist_ok=True)
    path = os.path.join(ROOT, f"{name}.wav")
    with wave.open(path, "w") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes(b"".join(struct.pack("<h", clamp(sample)) for sample in samples))


def env(index: int, total: int, attack: float = 0.01, release: float = 0.2) -> float:
    t = index / RATE
    duration = total / RATE
    if t < attack:
        return t / attack
    remain = duration - t
    if remain < release:
        return max(0.0, remain / release)
    return 1.0


def tone(freq: float, duration: float, volume: float = 0.2, kind: str = "sine") -> list[float]:
    total = int(duration * RATE)
    samples = []
    for i in range(total):
        phase = 2 * math.pi * freq * i / RATE
        if kind == "square":
            wave_s = 1.0 if math.sin(phase) > 0 else -1.0
        elif kind == "triangle":
            wave_s = 2 * abs(2 * ((i * freq / RATE) % 1) - 1) - 1
        else:
            wave_s = math.sin(phase)
        samples.append(wave_s * volume * env(i, total))
    return samples


def noise(duration: float, volume: float = 0.12) -> list[float]:
    total = int(duration * RATE)
    seed = 7919
    samples = []
    for i in range(total):
        seed = (1103515245 * seed + 12345) & 0x7FFFFFFF
        samples.append(((seed / 0x7FFFFFFF) * 2 - 1) * volume * env(i, total, 0.002, duration * 0.7))
    return samples


def mix(*parts: list[float]) -> list[float]:
    length = max(len(part) for part in parts)
    out = [0.0] * length
    for part in parts:
        for i, sample in enumerate(part):
            out[i] += sample
    peak = max((abs(sample) for sample in out), default=1.0)
    if peak > 0.95:
        out = [sample * 0.95 / peak for sample in out]
    return out


def concat(*parts: list[float]) -> list[float]:
    out: list[float] = []
    for part in parts:
        out.extend(part)
    return out


def main() -> None:
    write("round_start", mix(tone(196, 0.22, 0.16, "triangle"), tone(294, 0.28, 0.12)))
    write("buzzer_hit", mix(noise(0.09, 0.18), tone(110, 0.16, 0.22, "triangle"), tone(330, 0.08, 0.08, "square")))
    write(
        "correct_gold",
        concat(tone(523, 0.12, 0.16), tone(659, 0.12, 0.16), mix(tone(784, 0.28, 0.18), tone(1046, 0.28, 0.08))),
    )
    write("wrong_soft", concat(tone(247, 0.12, 0.1), tone(196, 0.18, 0.08)))
    write(
        "royal_fanfare",
        concat(
            mix(tone(392, 0.12, 0.14, "triangle"), tone(196, 0.12, 0.1)),
            mix(tone(523, 0.12, 0.14, "triangle"), tone(262, 0.12, 0.1)),
            mix(tone(784, 0.32, 0.16, "triangle"), tone(392, 0.32, 0.1)),
        ),
    )
    write("level_up", concat(tone(392, 0.1, 0.14), tone(523, 0.1, 0.14), mix(tone(784, 0.3, 0.16), tone(1175, 0.3, 0.06))))
    write("chest", mix(tone(180, 0.08, 0.16, "triangle"), tone(720, 0.22, 0.1), tone(1080, 0.18, 0.06)))
    write("dramatic_fire", mix(noise(0.28, 0.14), tone(155, 0.3, 0.1, "triangle"), tone(311, 0.22, 0.08)))
    write("fire_whoosh", mix(noise(0.18, 0.12), tone(440, 0.2, 0.1, "triangle")))


if __name__ == "__main__":
    main()
