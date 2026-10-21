#!/usr/bin/env python3
"""
Procedural sound generator for Cyberpong.
Generates 16-bit 44.1kHz mono WAV files for the cyberpunk arcade retro-synth aesthetic.
No external dependencies required (uses standard library math, struct, wave).
"""

import math
import os
import struct
import wave
import random

SAMPLE_RATE = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")

def save_wav(filename: str, samples: list[float]):
    os.makedirs(OUT_DIR, exist_ok=True)
    filepath = os.path.join(OUT_DIR, filename)
    with wave.open(filepath, "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        # Soft-clip and convert to 16-bit signed integer
        data = bytearray()
        for s in samples:
            # Soft tanh-style compression
            val = math.tanh(s)
            int_val = int(val * 32767.0)
            int_val = max(-32768, min(32767, int_val))
            data.extend(struct.pack("<h", int_val))
        wf.writeframes(data)
    print(f"Generated: {filepath} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.2f}s)")

def make_envelope(num_samples: int, attack_samples: int, decay_type: str = "exp", decay_factor: float = 4.0):
    env = []
    for i in range(num_samples):
        if i < attack_samples:
            a = i / max(1, attack_samples)
        else:
            rel_i = (i - attack_samples) / max(1, (num_samples - attack_samples))
            if decay_type == "exp":
                a = math.exp(-decay_factor * rel_i)
            elif decay_type == "linear":
                a = max(0.0, 1.0 - rel_i)
            else:
                a = 0.5 * (1.0 + math.cos(math.pi * rel_i))
        env.append(a)
    return env

def gen_hit_cyan():
    # Punchy, crisp cyber click/laser hit with sharp attack and fast pitch sweep
    duration = 0.08
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    env = make_envelope(num_samples, attack_samples=int(0.003 * SAMPLE_RATE), decay_factor=5.5)
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Sweep from 720 Hz down to 180 Hz
        freq = 180.0 + 540.0 * math.exp(-t * 55.0)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        # Sine + subtle square harmonic
        s = math.sin(phase) + 0.25 * math.copysign(1.0, math.sin(phase * 2.0))
        # Punch transient click in first 4ms
        click = 0.0
        if i < int(0.005 * SAMPLE_RATE):
            click = math.sin(2.0 * math.pi * 1800.0 * t) * (1.0 - i / (0.005 * SAMPLE_RATE))
        samples.append((s * 0.85 + click * 0.4) * env[i])
    save_wav("hit_cyan.wav", samples)

def gen_hit_magenta():
    # Slightly warmer, deeper cyber-impact with sub-harmonic punch
    duration = 0.09
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    env = make_envelope(num_samples, attack_samples=int(0.004 * SAMPLE_RATE), decay_factor=5.0)
    phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Sweep from 560 Hz down to 110 Hz
        freq = 110.0 + 450.0 * math.exp(-t * 45.0)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        # Sine + triangle harmonic
        tri = 2.0 * abs(2.0 * ((phase / (2.0 * math.pi)) % 1.0) - 1.0) - 1.0
        s = 0.75 * math.sin(phase) + 0.35 * tri
        # Sub kick transient
        sub = math.sin(2.0 * math.pi * 95.0 * t) * math.exp(-t * 35.0)
        samples.append((s * 0.7 + sub * 0.5) * env[i])
    save_wav("hit_magenta.wav", samples)

def gen_wall_bounce():
    # Crisp, short metallic deflection
    duration = 0.055
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    env = make_envelope(num_samples, attack_samples=int(0.002 * SAMPLE_RATE), decay_factor=7.0)
    phase = 0.0
    phase2 = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 380.0 + 620.0 * math.exp(-t * 70.0)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        phase2 += 2.0 * math.pi * (freq * 2.37) / SAMPLE_RATE
        s = 0.7 * math.sin(phase) + 0.4 * math.sin(phase2)
        samples.append(s * env[i] * 0.8)
    save_wav("wall_bounce.wav", samples)

def gen_serve():
    # Ascending laser chirp into release
    duration = 0.20
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    env = make_envelope(num_samples, attack_samples=int(0.02 * SAMPLE_RATE), decay_factor=3.2)
    phase = 0.0
    for i in range(num_samples):
        t = i / duration
        # Frequency rises then peaks and settles
        freq = 240.0 + 720.0 * (t ** 1.6)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        # FM modulation
        mod = math.sin(phase * 2.0) * 0.25
        s = math.sin(phase + mod)
        samples.append(s * env[i] * 0.85)
    save_wav("serve.wav", samples)

def gen_score():
    # Cybernetic goal explosion + triumphant digital chord chime
    duration = 0.55
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    # Bass explosion thump + triad chord (C5=523.25, E5=659.25, G5=783.99)
    env_thump = make_envelope(num_samples, attack_samples=int(0.005 * SAMPLE_RATE), decay_factor=6.0)
    env_chord = make_envelope(num_samples, attack_samples=int(0.02 * SAMPLE_RATE), decay_factor=2.8)
    rng = random.Random(42)
    p_thump = 0.0
    p1 = 0.0
    p2 = 0.0
    p3 = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Thump sweep 160 Hz -> 40 Hz
        f_thump = 40.0 + 120.0 * math.exp(-t * 20.0)
        p_thump += 2.0 * math.pi * f_thump / SAMPLE_RATE
        noise = (rng.random() * 2.0 - 1.0) * math.exp(-t * 30.0)
        thump = (math.sin(p_thump) * 0.8 + noise * 0.3) * env_thump[i]

        # Chord chime
        p1 += 2.0 * math.pi * 523.25 / SAMPLE_RATE
        p2 += 2.0 * math.pi * 659.25 / SAMPLE_RATE
        p3 += 2.0 * math.pi * 783.99 / SAMPLE_RATE
        chord = (math.sin(p1) + math.sin(p2) + math.sin(p3)) / 3.0 * env_chord[i]

        samples.append((thump * 0.65 + chord * 0.75))
    save_wav("score.wav", samples)

def gen_power_up_spawn():
    # Holographic shimmer / warp-in
    duration = 0.32
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    env = make_envelope(num_samples, attack_samples=int(0.03 * SAMPLE_RATE), decay_factor=3.0)
    phase = 0.0
    mod_phase = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 380.0 + 480.0 * (t / duration)
        mod_phase += 2.0 * math.pi * 28.0 / SAMPLE_RATE
        mod = math.sin(mod_phase) * 120.0
        phase += 2.0 * math.pi * (freq + mod) / SAMPLE_RATE
        s = math.sin(phase) * 0.7 + 0.3 * math.sin(phase * 1.5)
        samples.append(s * env[i] * 0.8)
    save_wav("power_up_spawn.wav", samples)

def gen_power_up_collect():
    # Bright arpeggio chime (C5 -> E5 -> G5 -> C6)
    duration = 0.28
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    notes = [523.25, 659.25, 783.99, 1046.5]
    step_samples = num_samples // len(notes)
    phase = 0.0
    for i in range(num_samples):
        note_idx = min(len(notes) - 1, i // step_samples)
        freq = notes[note_idx]
        note_t = (i % step_samples) / step_samples
        env_note = math.exp(-3.5 * note_t)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        s = math.sin(phase) + 0.25 * math.sin(phase * 2.0)
        overall_env = math.sin((i / num_samples) * math.pi * 0.5)
        samples.append(s * env_note * overall_env * 0.85)
    save_wav("power_up_collect.wav", samples)

def gen_power_up_double():
    # Expanding majestic chord (ascending double octave)
    duration = 0.30
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    env = make_envelope(num_samples, attack_samples=int(0.02 * SAMPLE_RATE), decay_factor=2.5)
    p1 = 0.0
    p2 = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        f1 = 330.0 + 220.0 * (t / duration)
        f2 = f1 * 2.0
        p1 += 2.0 * math.pi * f1 / SAMPLE_RATE
        p2 += 2.0 * math.pi * f2 / SAMPLE_RATE
        s = 0.6 * math.sin(p1) + 0.4 * math.sin(p2)
        samples.append(s * env[i] * 0.85)
    save_wav("pu_double.wav", samples)

def gen_power_up_half():
    # Penalty down-glitch (bitcrush / descending steps)
    duration = 0.25
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    env = make_envelope(num_samples, attack_samples=int(0.005 * SAMPLE_RATE), decay_factor=3.0)
    phase = 0.0
    for i in range(num_samples):
        t = i / duration
        freq = 460.0 - 280.0 * (t ** 0.8)
        # Add jitter/glitch
        freq += 40.0 * math.sin(2.0 * math.pi * 60.0 * (i / SAMPLE_RATE))
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        # Square wave with slight noise
        sq = 1.0 if math.sin(phase) > 0 else -1.0
        samples.append(sq * env[i] * 0.55)
    save_wav("pu_half.wav", samples)

def gen_power_up_brake():
    # Magnetic brake / friction whoosh
    duration = 0.26
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    env = make_envelope(num_samples, attack_samples=int(0.03 * SAMPLE_RATE), decay_factor=3.2)
    phase = 0.0
    rng = random.Random(123)
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        f = 500.0 * math.exp(-t * 9.0) + 70.0
        phase += 2.0 * math.pi * f / SAMPLE_RATE
        noise = (rng.random() * 2.0 - 1.0) * math.exp(-t * 12.0)
        s = 0.65 * math.sin(phase) + 0.35 * noise
        samples.append(s * env[i] * 0.85)
    save_wav("pu_brake.wav", samples)

def gen_power_up_bounce():
    # Powerful heavy sonic boom / overdrive laser punch
    duration = 0.32
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    env = make_envelope(num_samples, attack_samples=int(0.005 * SAMPLE_RATE), decay_factor=4.0)
    phase = 0.0
    p_sub = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        freq = 650.0 * math.exp(-t * 35.0) + 120.0
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        # Sub drop
        p_sub += 2.0 * math.pi * (80.0 * math.exp(-t * 15.0)) / SAMPLE_RATE
        # Overdriven punch
        raw = math.sin(phase) * 1.6 + math.sin(p_sub) * 1.2
        dist = math.tanh(raw)
        samples.append(dist * env[i] * 0.9)
    save_wav("pu_bounce.wav", samples)

def gen_power_up_defense():
    # Energy barrier force-field deflection
    duration = 0.30
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    env = make_envelope(num_samples, attack_samples=int(0.003 * SAMPLE_RATE), decay_factor=3.5)
    p1 = 0.0
    p2 = 0.0
    p3 = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        p1 += 2.0 * math.pi * 920.0 / SAMPLE_RATE
        p2 += 2.0 * math.pi * 1440.0 / SAMPLE_RATE
        p3 += 2.0 * math.pi * 2100.0 / SAMPLE_RATE
        shimmer = math.sin(2.0 * math.pi * 40.0 * t)
        s = (0.5 * math.sin(p1) + 0.3 * math.sin(p2) + 0.2 * math.sin(p3)) * (1.0 + 0.3 * shimmer)
        samples.append(s * env[i] * 0.85)
    save_wav("pu_defense.wav", samples)

def gen_power_up_expire():
    # Power down / discharge
    duration = 0.22
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    env = make_envelope(num_samples, attack_samples=int(0.01 * SAMPLE_RATE), decay_factor=3.8)
    phase = 0.0
    for i in range(num_samples):
        t = i / duration
        freq = 620.0 - 450.0 * (t ** 1.3)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        s = math.sin(phase) + 0.2 * math.sin(phase * 2.0)
        samples.append(s * env[i] * 0.75)
    save_wav("power_up_expire.wav", samples)

def gen_ui_move():
    # Very soft, gentle cyber tick/blip
    duration = 0.035
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    env = make_envelope(num_samples, attack_samples=int(0.002 * SAMPLE_RATE), decay_factor=8.0)
    phase = 0.0
    for i in range(num_samples):
        phase += 2.0 * math.pi * 1150.0 / SAMPLE_RATE
        s = math.sin(phase)
        samples.append(s * env[i] * 0.45)
    save_wav("ui_move.wav", samples)

def gen_ui_select():
    # Affirmative two-tone cyber chime (A5 -> E6)
    duration = 0.16
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    half = num_samples // 2
    p1 = 0.0
    p2 = 0.0
    env1 = make_envelope(half, attack_samples=int(0.003 * SAMPLE_RATE), decay_factor=4.5)
    env2 = make_envelope(num_samples - half, attack_samples=int(0.003 * SAMPLE_RATE), decay_factor=4.5)
    for i in range(half):
        p1 += 2.0 * math.pi * 880.0 / SAMPLE_RATE
        s = math.sin(p1) + 0.2 * math.sin(p1 * 2.0)
        samples.append(s * env1[i] * 0.65)
    for i in range(num_samples - half):
        p2 += 2.0 * math.pi * 1318.5 / SAMPLE_RATE
        s = math.sin(p2) + 0.2 * math.sin(p2 * 2.0)
        samples.append(s * env2[i] * 0.70)
    save_wav("ui_select.wav", samples)

def gen_pause_open():
    # Stasis low-pass cutoff swoop
    duration = 0.18
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    env = make_envelope(num_samples, attack_samples=int(0.005 * SAMPLE_RATE), decay_factor=4.0)
    phase = 0.0
    for i in range(num_samples):
        t = i / duration
        freq = 780.0 * math.exp(-t * 4.0) + 100.0
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        s = math.sin(phase)
        samples.append(s * env[i] * 0.6)
    save_wav("pause_open.wav", samples)

def gen_pause_close():
    # Spin up / resume sweep
    duration = 0.16
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    env = make_envelope(num_samples, attack_samples=int(0.008 * SAMPLE_RATE), decay_factor=3.5)
    phase = 0.0
    for i in range(num_samples):
        t = i / duration
        freq = 150.0 + 550.0 * (t ** 1.5)
        phase += 2.0 * math.pi * freq / SAMPLE_RATE
        s = math.sin(phase)
        samples.append(s * env[i] * 0.6)
    save_wav("pause_close.wav", samples)

def gen_win():
    # Synthwave victory fanfare (ascending arpeggio into bold synth chord)
    duration = 1.3
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    # Arpeggio notes: C4 (261.63), E4 (329.63), G4 (392.00), B4 (493.88), C5 (523.25), E5 (659.25), G5 (783.99)
    notes = [261.63, 329.63, 392.00, 523.25, 659.25, 783.99]
    arp_time = 0.6
    arp_samples = int(arp_time * SAMPLE_RATE)
    note_len = arp_samples // len(notes)
    phase_arp = 0.0

    for i in range(arp_samples):
        n_idx = min(len(notes) - 1, i // note_len)
        freq = notes[n_idx]
        sub_t = (i % note_len) / note_len
        env_n = math.exp(-4.0 * sub_t)
        phase_arp += 2.0 * math.pi * freq / SAMPLE_RATE
        s = (math.sin(phase_arp) + 0.3 * math.sin(phase_arp * 2.0)) * env_n
        samples.append(s * 0.7)

    chord_samples = num_samples - arp_samples
    env_chord = make_envelope(chord_samples, attack_samples=int(0.04 * SAMPLE_RATE), decay_factor=2.0)
    p1 = 0.0
    p2 = 0.0
    p3 = 0.0
    p_bass = 0.0
    for i in range(chord_samples):
        p1 += 2.0 * math.pi * 523.25 / SAMPLE_RATE # C5
        p2 += 2.0 * math.pi * 659.25 / SAMPLE_RATE # E5
        p3 += 2.0 * math.pi * 783.99 / SAMPLE_RATE # G5
        p_bass += 2.0 * math.pi * 130.81 / SAMPLE_RATE # C3
        s = (math.sin(p1) + math.sin(p2) + math.sin(p3)) * 0.3 + math.sin(p_bass) * 0.4
        samples.append(s * env_chord[i] * 0.85)

    save_wav("win.wav", samples)

def gen_credits_sting():
    # Deep atmospheric analog chord / Moron Souls sting
    duration = 1.4
    num_samples = int(duration * SAMPLE_RATE)
    samples = []
    env = make_envelope(num_samples, attack_samples=int(0.25 * SAMPLE_RATE), decay_factor=1.8)
    p_sub = 0.0
    p1 = 0.0
    p2 = 0.0
    p_detune = 0.0
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        p_sub += 2.0 * math.pi * 55.0 / SAMPLE_RATE # A1 sub
        p1 += 2.0 * math.pi * 220.0 / SAMPLE_RATE   # A3
        p2 += 2.0 * math.pi * 330.0 / SAMPLE_RATE   # E4
        p_detune += 2.0 * math.pi * 221.2 / SAMPLE_RATE # A3 slight chorus detune
        # Chorus shimmer
        s = 0.45 * math.sin(p_sub) + 0.25 * math.sin(p1) + 0.25 * math.sin(p_detune) + 0.2 * math.sin(p2)
        samples.append(s * env[i] * 0.8)
    save_wav("credits_sting.wav", samples)

def main():
    print("Generating audio assets...")
    gen_hit_cyan()
    gen_hit_magenta()
    gen_wall_bounce()
    gen_serve()
    gen_score()
    gen_power_up_spawn()
    gen_power_up_collect()
    gen_power_up_double()
    gen_power_up_half()
    gen_power_up_brake()
    gen_power_up_bounce()
    gen_power_up_defense()
    gen_power_up_expire()
    gen_ui_move()
    gen_ui_select()
    gen_pause_open()
    gen_pause_close()
    gen_win()
    gen_credits_sting()
    print("Audio assets generated successfully!")

if __name__ == "__main__":
    main()
