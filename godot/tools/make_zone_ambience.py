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

# ================================================================== The other seven zones (0.75.4)
I = f"{K}/kenney_impact-sounds/Audio"; R = f"{K}/kenney_rpg-audio/Audio"; C = f"{K}/kenney_casino-audio/Audio"
glass = [load(f"{I}/impactGlass_light_00{i}.ogg") for i in range(5)]
mining = [load(f"{I}/impactMining_00{i}.ogg") for i in range(5)]
bell = [load(f"{I}/impactBell_heavy_00{i}.ogg") for i in range(3)]
metal = [load(f"{I}/impactMetal_light_00{i}.ogg") for i in range(5)]
plate = [load(f"{I}/impactPlate_light_00{i}.ogg") for i in range(3)]
dice = [load(f"{C}/dice-shake-{i}.ogg") for i in (1, 2, 3)]
wood = [load(f"{I}/impactWood_light_00{i}.ogg") for i in range(5)]
CAVE = [(0.11, 0.45), (0.23, 0.32), (0.37, 0.22), (0.55, 0.14), (0.8, 0.08)]
def drone(freqs, beat=0.3, amp=1.0):
    return sum(np.sin(2 * np.pi * f * t + np.sin(2 * np.pi * beat * (k + 1) * 0.37 * t)) / (k + 1) for k, f in enumerate(freqs)) * amp
def scatter(n, clips, count, fn=lambda c: c, gain=(0.4, 1.0)):
    out = np.zeros(n)
    for k in range(count): place(out, fn(clips[rng.integers(0, len(clips))]), rng.uniform(0, n / SR - 1.5), rng.uniform(*gain))
    return out
def howl(n, lo, hi, rate):
    # Resonant wind: a few fixed bands of noise, with slow overlapping weights so the "pitch" of the
    # wind glides up and down without any filter restarts (which would click).
    x = rng.normal(0, 1, n); tt = np.arange(n) / SR; out = np.zeros(n); bands = 5
    for k in range(bands):
        f = lo * (hi / lo) ** (k / (bands - 1))
        pos = 0.5 * (1 + np.sin(2 * np.pi * rate * tt + rng.uniform(0, 6.28))) * (bands - 1)
        w = np.exp(-((pos - k) ** 2) / 0.8)
        out += bp(x, f * 0.85, f * 1.18) * w
    return lp(out, 2500)
def thunder(seconds=3.5):
    n = int(SR * seconds); tt = np.arange(n) / SR
    body = lp(rng.normal(0, 1, n), 160, 4) * np.exp(-tt / 1.1) * (1 - np.exp(-tt / 0.06))
    crack = bp(rng.normal(0, 1, n), 400, 2500) * np.exp(-tt / 0.18) * 0.4
    return body + crack
rain_bed = load(f"{D}/dark_rainy_night.ogg")[: M]

# Mana Caverns: a beating crystal hum, shimmering glass chimes, distant picks mining crystal, cave drips.
hum = drone([220, 277.2, 329.6, 440], beat=0.21) * lfo(M, 0.06, 0.6)
chimes = echo(scatter(M, glass, int(L * 0.5), lambda c: pitch(c, rng.choice([1.5, 2.0, 2.25, 3.0])), (0.2, 0.7)), CAVE)
picks = echo(scatter(M, mining, int(L * 0.25), lambda c: lp(pitch(c, rng.uniform(0.8, 1.0)), 2500), (0.3, 0.8)), CAVE)
drip2 = echo(scatter(M, singles, int(L * 0.4), lambda c: pitch(c, rng.uniform(1.8, 2.4))), CAVE)
save_ogg("mana_caverns", loopify(norm(hum, .06) + norm(lp(rng.normal(0, 1, M), 200), .08) + norm(chimes, .05) + norm(picks, .05) + norm(drip2, .03)))
x = np.zeros(int(SR * 1.6)); place(x, pitch(glass[2], 2.0), 0); place(x, pitch(glass[4], 3.0) * 0.6, 0.05); save_fx("amb_crystal", echo(x, CAVE), 0.6)
x = np.zeros(int(SR * 1.6)); place(x, lp(mining[1], 3000), 0); save_fx("amb_pick", echo(x, CAVE), 0.7)

# Frostbound Crypt: howling wind through the tomb, ice cracking and settling, a cold low drone.
wind_f = howl(M, 300, 1400, 0.06) * lfo(M, 0.08, 0.7)
ice = scatter(M, glass, int(L * 0.3), lambda c: lp(pitch(c, rng.uniform(0.45, 0.7)), 3000), (0.3, 0.8))
cold = drone([55, 82.4], beat=0.1) * lfo(M, 0.04, 0.5)
save_ogg("frostbound_crypt", loopify(norm(wind_f, .16) + norm(echo(ice, HALL), .04) + norm(cold, .06) + norm(bp(rng.normal(0, 1, M), 4000, 9000), .01)))
x = np.zeros(int(SR * 1.2)); place(x, lp(pitch(glass[0], 0.5), 3500), 0); place(x, lp(pitch(glass[3], 0.62), 3500) * 0.7, 0.07); save_fx("amb_ice_crack", echo(x, HALL), 0.65)

# Fungal Hollows: damp cave air, soft spore puffs, wet squelches, a chittering insect bed.
damp = lp(rng.normal(0, 1, M), 400) * lfo(M, 0.05, 0.6)
def puff():
    n = int(SR * rng.uniform(0.25, 0.5)); tt = np.arange(n) / SR
    return bp(rng.normal(0, 1, n), 500, 3000) * np.exp(-tt / 0.08) * (1 - np.exp(-tt / 0.01))
puffs = np.zeros(M)
for _ in range(int(L * 0.5)): place(puffs, puff(), rng.uniform(0, L + 2), rng.uniform(0.3, 1.0))
squelch = scatter(M, singles, int(L * 0.4), lambda c: lp(pitch(c, rng.uniform(0.55, 0.8)), 1800))
chit = np.zeros(M)
for _ in range(int(L * 0.6)):
    n = int(SR * rng.uniform(0.3, 0.8)); tt = np.arange(n) / SR
    f = rng.uniform(3500, 6000); burst = np.sin(2 * np.pi * f * tt) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * rng.uniform(18, 30) * tt))) * np.hanning(n)
    place(chit, burst, rng.uniform(0, L + 2), rng.uniform(0.1, 0.4))
save_ogg("fungal_hollows", loopify(norm(damp, .1) + norm(echo(puffs, CAVE), .05) + norm(squelch, .04) + norm(chit, .015) + norm(lp(tile(pitch(bub2, 0.7), M), 1500), .03)))
x = np.zeros(int(SR * 1.0)); place(x, puff(), 0); place(x, puff() * 0.6, 0.12); save_fx("amb_spore", echo(x, CAVE), 0.6)

# Ossuary of Kings: a low tomb drone with a ghostly choir hum, bones rattling, coffins creaking, distant chains.
choir = sum(lp(np.sign(np.sin(2 * np.pi * f * t)) * 0.3, 900) for f in (110, 130.8, 164.8)) * lfo(M, 0.05, 0.7)
tomb = drone([41.2, 61.7], beat=0.08)
bones = scatter(M, dice, int(L * 0.2), lambda c: lp(pitch(c, rng.uniform(0.6, 0.8)), 3000), (0.3, 0.8)) + scatter(M, wood, int(L * 0.3), lambda c: pitch(c, rng.uniform(1.2, 1.6)), (0.2, 0.6))
creak2 = scatter(M, creaks, 6, lambda c: lp(pitch(c, rng.uniform(0.5, 0.7)), 2200))
chains = scatter(M, metal, int(L * 0.25), lambda c: lp(pitch(c, rng.uniform(0.7, 0.9)), 4000), (0.2, 0.5))
save_ogg("ossuary_of_kings", loopify(norm(choir, .05) + norm(tomb, .07) + norm(echo(bones, HALL), .05) + norm(echo(creak2, HALL), .04) + norm(echo(chains, HALL), .025)))
x = np.zeros(int(SR * 1.5)); place(x, lp(pitch(dice[0], 0.7), 3000), 0); save_fx("amb_bones", echo(x, HALL), 0.65)
save_fx("amb_coffin", echo(np.concatenate([lp(pitch(creaks[2], 0.5), 2000), np.zeros(int(SR * 0.6))]), HALL), 0.7)

# Storm Spire: rain and wind on the tower, rolling thunder, electric crackle around the pylons.
rain = lp(tile(rain_bed, M), 7000)
gust = howl(M, 400, 1800, 0.09) * lfo(M, 0.11, 0.8)
rolls = np.zeros(M)
for k in range(4): place(rolls, thunder(rng.uniform(3, 5)), 3 + k * 11 + rng.uniform(0, 4), rng.uniform(0.5, 1.0))
buzz = crackle(M, 14, 2500, 9000) * lfo(M, 0.2, 0.9, 0.5)
save_ogg("storm_spire", loopify(norm(rain, .12) + norm(gust, .07) + norm(rolls, .1) + norm(buzz, .02)))
save_fx("amb_thunder", thunder(4.0), 0.8)
x = crackle(int(SR * 0.6), 120, 2000, 10000) * np.hanning(int(SR * 0.6)); save_fx("amb_spark", x, 0.6)

# Gilded Tomb: desert wind with sand hiss over a deep chamber hum, trickling sand, brazier fire.
desert = howl(M, 200, 900, 0.05) * lfo(M, 0.07, 0.6)
sand = bp(rng.normal(0, 1, M), 3000, 10000) * lfo(M, 0.13, 0.95, 1.2)
chamber = drone([49, 73.4, 98], beat=0.12)
fire = crackle(M, 7, 1200, 6000)
save_ogg("gilded_tomb", loopify(norm(desert, .12) + norm(sand, .02) + norm(chamber, .05) + norm(fire, .03)))
n = int(SR * 1.8); tt = np.arange(n) / SR
trickle = crackle(n, 400, 3000, 11000) * np.sin(np.pi * tt / 1.8) ** 2
grind = lp(pitch(plate[0], 0.45), 1500); x = np.zeros(n); place(x, trickle, 0); place(x, grind * 0.5, 0.2); save_fx("amb_sand", x, 0.6)

# Void Rift: a dark detuned drone, reversed swells, faint whispers, a slow low pulse.
void = drone([36.7, 37.3, 55.1, 110.6], beat=0.05) * lfo(M, 0.03, 0.5)
sw = np.zeros(M)
for k in range(5):
    n = int(SR * 3.5); tt = np.arange(n) / SR
    swell = lp(rng.normal(0, 1, n), 1200) * (tt / 3.5) ** 3
    place(sw, swell, rng.uniform(0, L - 3), rng.uniform(0.5, 1.0))
whisper = np.zeros(M)
for _ in range(int(L * 0.3)):
    n = int(SR * rng.uniform(0.6, 1.4)); f = rng.uniform(900, 2400)
    place(whisper, bp(rng.normal(0, 1, n), f, f * 1.3) * np.hanning(n), rng.uniform(0, L + 2), rng.uniform(0.2, 0.6))
pulse = np.zeros(M)
for k in range(int(L / 1.6)):
    n = int(SR * 0.4); tt = np.arange(n) / SR; place(pulse, np.sin(2 * np.pi * 45 * tt) * np.exp(-tt / 0.1), k * 1.6)
save_ogg("void_rift", loopify(norm(void, .08) + norm(sw, .05) + norm(echo(whisper, CAVE), .02) + norm(pulse, .03)))
n = int(SR * 2.0); tt = np.arange(n) / SR; x = lp(rng.normal(0, 1, n), 2000) * (tt / 2.0) ** 2.5; x[-int(SR * 0.05):] *= np.linspace(1, 0, int(SR * 0.05)); save_fx("amb_void", x, 0.6)

# Level every bed to the same loudness (-26 LUFS integrated) with a gentle limiter.
import re, glob
for path in sorted(glob.glob(f"{OUT}/*.ogg")):
    log = subprocess.run(["ffmpeg", "-nostats", "-i", path, "-af", "ebur128=framelog=quiet", "-f", "null", "-"], capture_output=True, text=True).stderr
    lufs = float(re.findall(r"I:\s+(-?[\d.]+) LUFS", log)[-1])
    tmp = path + ".tmp.ogg"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", path, "-af", f"volume={-26.0 - lufs:.2f}dB,alimiter=limit=0.89:level=false", "-c:a", "libvorbis", "-q:a", "4", tmp], check=True)
    os.replace(tmp, path); print("levelled", os.path.basename(path), f"{lufs:.1f} -> -26 LUFS")
