"""Builds the dungeon zone ambience beds and one-shot sweeteners.
Usage (from the repo root): python3 godot/tools/make_zone_ambience.py <oga_dir> <kenney_dir>
Sources (see godot/assets/audio/CREDITS.md): OpenGameArt CC0 bubbles + forest loop, a CC-BY 3.0 running-water
loop, Kenney RPG Audio creaks (CC0), plus synthesised rumble, crackle, wind, swells and room echo."""
import sys, os, subprocess, wave
import numpy as np
from scipy.signal import butter, sosfilt

D, K = sys.argv[1], sys.argv[2]
OUT = "godot/assets/audio/ambience"; FX = "godot/assets/audio/fx"
os.makedirs(OUT, exist_ok=True)
SR = 44100; L = 48.0; N = int(SR * L); M = N + int(SR * 3)
rng = np.random.default_rng(75)

def load(p):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", p, "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"], capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).astype(np.float64)
def lp(x, c, o=2): return sosfilt(butter(o, c / (SR / 2), output='sos'), x)
def bp(x, a, b, o=2): return sosfilt(butter(o, [a / (SR / 2), b / (SR / 2)], 'band', output='sos'), x)
def pitch(x, f): n = int(len(x) / f); return np.interp(np.linspace(0, len(x) - 1, n), np.arange(len(x)), x)
def rms(x): return np.sqrt(np.mean(x ** 2)) + 1e-12
def norm(x, target): return x * (target / rms(x))
def tile(x, n):
    out = np.zeros(n); i = 0
    while i < n:
        k = min(len(x), n - i); out[i:i + k] += x[:k]; i += k
    return out
def place(base, x, t, g=1.0):
    i = int(t * SR); k = min(len(x), len(base) - i)
    if k > 0: base[i:i + k] += x[:k] * g
def lfo(n, rate, depth, phase=0.0):
    t = np.arange(n) / SR; return 1 - depth + depth * 0.5 * (1 + np.sin(2 * np.pi * rate * t + phase))
def loopify(x, fade=3.0):
    # The last 3 s fade into the first 3 s, so the loop point is seamless.
    f = int(SR * fade); head = x[:f].copy(); body = x[f:].copy()
    r = np.linspace(0, 1, f); body[-f:] = body[-f:] * (1 - r) + head * r
    return body
def write_wav(path, x, peak):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak; d = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    w = wave.open(path, 'wb'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(d.tobytes()); w.close()
def save_ogg(name, x):
    tmp = f"{OUT}/{name}.tmp.wav"; write_wav(tmp, x, 0.7)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", tmp, "-c:a", "libvorbis", "-q:a", "4", f"{OUT}/{name}.ogg"], check=True)
    os.remove(tmp); print(name, round(len(x) / SR, 1), "s")
def save_fx(name, x, peak=0.8): write_wav(f"{FX}/{name}.wav", x, peak); print(name)
def crackle(n, per_sec, lo, hi):
    out = np.zeros(n)
    for _ in range(int(n / SR * per_sec)):
        ln = int(SR * rng.uniform(0.002, 0.012)); i = rng.integers(0, n - ln)
        out[i:i + ln] += rng.normal(0, 1, ln) * np.exp(-np.linspace(0, 6, ln)) * rng.uniform(0.2, 1.0) ** 2
    return bp(out, lo, hi)
def echo(x, taps):
    out = x.copy()
    for dl, g in taps:
        s = int(dl * SR); out[s:] += x[:-s] * g
    return out
HALL = [(0.09, 0.5), (0.17, 0.35), (0.29, 0.25), (0.43, 0.15), (0.6, 0.1)]

bub1 = load(f"{D}/bubbles-loop1-amp.wav"); bub2 = load(f"{D}/bubbles-loop2-amp.wav")
singles = [load(f"{D}/bubbles-single{i}.wav") for i in (1, 2, 3)]
creaks = [load(f"{K}/kenney_rpg-audio/Audio/creak{i}.ogg") for i in (1, 2, 3)]
t = np.arange(M) / SR

# Magma Depths: deep rumble with a sub drone, slow lava blorps, fire crackle and steam hiss.
rum = lp(rng.normal(0, 1, M), 90, 4) * lfo(M, 0.07, 0.5)
sub = np.sin(2 * np.pi * 38 * t + 0.6 * np.sin(2 * np.pi * 0.05 * t))
blorp = lp(tile(pitch(bub1, 0.42), M), 900) + 0.8 * lp(tile(pitch(bub2, 0.36), M), 700)
crack = crackle(M, 9, 1500, 7000) * lfo(M, 0.13, 0.6, 1.0)
hiss = bp(rng.normal(0, 1, M), 3000, 9000) * lfo(M, 0.031, 0.9)
save_ogg("magma_depths", loopify(norm(rum, .25) + norm(sub, .12) + norm(blorp, .16) + norm(crack, .05) + norm(hiss, .015)))

# Drowned Sanctum: muffled flowing water, slow swells, underwater bubbles, drips echoing in a stone hall.
flow = lp(tile(load(f"{D}/bg_water_running.wav"), M), 1800) * lfo(M, 0.045, 0.5)
swell = lp(rng.normal(0, 1, M), 300) * lfo(M, 0.09, 0.95)
under = lp(tile(pitch(bub2, 0.8), M), 2500) * lfo(M, 0.06, 0.7, 2.0)
drips = np.zeros(M)
for _ in range(int(L * 0.9)): place(drips, pitch(singles[rng.integers(0, 3)], rng.uniform(1.6, 2.3)), rng.uniform(0, L + 2.5), rng.uniform(0.3, 1.0))
save_ogg("drowned_sanctum", loopify(norm(flow, .18) + norm(swell, .1) + norm(under, .06) + norm(echo(drips, HALL), .05)))

# Blight Forest: the CC0 forest bed darkened, cold wind gusts, toxic pools bubbling, dead trees creaking.
forest = load(f"{D}/forest_2.ogg"); forest = lp(tile(forest, M), 5000)
wind = bp(rng.normal(0, 1, M), 180, 900) * lfo(M, 0.05, 0.9) * lfo(M, 0.13, 0.5, 2.0)
toxic = lp(tile(pitch(bub1, 0.6), M), 1400) * lfo(M, 0.07, 0.8, 1.5)
cr = np.zeros(M)
for k in range(9): place(cr, lp(pitch(creaks[k % 3], rng.uniform(0.55, 0.8)), 2500), rng.uniform(1, L - 2), rng.uniform(0.5, 1.0))
save_ogg("blight_forest", loopify(norm(forest, .12) + norm(wind, .12) + norm(toxic, .05) + norm(cr, .05)))

# One-shot sweeteners, played now and then in each zone.
x = np.zeros(int(SR * 0.8)); place(x, lp(pitch(singles[0], 0.5), 1200), 0)
n = int(SR * 0.25); place(x, bp(rng.normal(0, 1, n), 1500, 6000) * np.exp(-np.linspace(0, 8, n)) * 0.3, 0.05)
save_fx("amb_lava_pop", x)
x = np.zeros(int(SR * 1.2)); place(x, pitch(singles[2], 2.0), 0); save_fx("amb_drip", echo(x, HALL), 0.6)
save_fx("amb_creak", lp(pitch(creaks[1], 0.6), 2200), 0.7)
