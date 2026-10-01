"""Original procedural score and creature Foley. Requires numpy; no borrowed audio.
Run with --out PATH, or default to this project's assets/audio directory.
"""
from pathlib import Path
import argparse, hashlib, json, wave
import numpy as np

RATE = 44100
OUT = Path(__file__).resolve().parents[1] / 'assets/audio'
parser = argparse.ArgumentParser(); parser.add_argument('--out', type=Path, default=OUT); parser.add_argument('--music-only', action='store_true')
args = parser.parse_args(); OUT = args.out; OUT.mkdir(parents=True, exist_ok=True)
FX = OUT/'fx'; FX.mkdir(exist_ok=True)
rng = np.random.default_rng(806)
report = []

def envelope(t, attack=.008, release=.08):
    return np.minimum(1, t/max(.001,attack)) * np.minimum(1, (len(t)/RATE-t)/max(.001,release))

def filtered_noise(n, cutoff=1500, high=False):
    noise = rng.normal(0, 1, n)
    f = np.fft.rfftfreq(n, 1/RATE)
    response = 1 / np.sqrt(1+(f/cutoff)**6)
    if high: response = 1-response
    result = np.fft.irfft(np.fft.rfft(noise)*response, n)
    return result / max(.05, np.sqrt(np.mean(result**2)))

def instrument(freq, duration, kind):
    t = np.arange(int(duration*RATE))/RATE
    if kind in ['strings', 'short_strings']:
        # Bowed ensemble: several subtly detuned voices, harmonic rolloff,
        # gentle vibrato and a bow-shaped envelope, rather than bell transients.
        y = np.zeros_like(t)
        for v, cents in enumerate([-5, -1.5, 2, 5.5]):
            f = freq * 2**(cents/1200)
            phase = 2*np.pi*f*t + .035*np.sin(2*np.pi*(5.1+v*.17)*t)
            for k in range(1, 10):
                y += np.sin(k*phase + v*.7) * np.exp(-k*freq/7200) / k**1.35
        y /= 4
        short = kind == 'short_strings'
        return y*envelope(t,.018 if short else .065,.075 if short else .12)*(np.exp(-t*3) if short else 1)
    if kind == 'brass':
        y = sum(np.sin(2*np.pi*freq*k*t) / k**1.3 for k in range(1,7))
        return np.tanh(y*1.2)*envelope(t,.07,.16)*(1+.025*np.sin(t*34))
    if kind == 'bell':
        y = np.sin(2*np.pi*freq*t)+.32*np.sin(2*np.pi*freq*2.01*t)+.12*np.sin(2*np.pi*freq*3.98*t)
        return y*np.exp(-t*3)*envelope(t,.003,.10)
    if kind == 'bass':
        y = np.sin(2*np.pi*freq*t)+.28*np.sin(2*np.pi*freq*2*t)+.12*np.sin(2*np.pi*freq*3*t)
        return y*envelope(t,.008,.045)*np.exp(-t*2)
    y = np.sin(2*np.pi*freq*t)+.25*np.sin(2*np.pi*freq*2.003*t)
    return y*envelope(t,.3,.35)

def percussion(kind):
    t = np.arange(int(RATE*(.7 if kind in ['kick','tom'] else .38)))/RATE
    if kind in ['kick','tom']:
        freq = 48 if kind=='kick' else 86
        y = np.sin(2*np.pi*(freq*t + 5*(1-np.exp(-t*22))))*np.exp(-t*8)
        y += filtered_noise(len(t),800)*np.exp(-t*65)*.14
    elif kind=='snare':
        y = filtered_noise(len(t),1800,True)*np.exp(-t*19)*.38
        y += np.sin(2*np.pi*174*t)*np.exp(-t*24)*.23
    else:
        y = filtered_noise(len(t),5700,True)*np.exp(-t*38)*.20
    return y*envelope(t,.001,.02)

def write(path, data, peak=.82):
    data = np.asarray(data, dtype=np.float64)
    data -= data.mean(axis=0)
    data = np.tanh(data*1.15)
    data *= peak/max(1e-8, np.max(np.abs(data)))
    pcm = np.round(data*32767).astype('<i2')
    with wave.open(str(path),'wb') as f:
        f.setnchannels(1 if data.ndim==1 else 2); f.setsampwidth(2); f.setframerate(RATE); f.writeframes(pcm.tobytes())
    report.append({'file':str(path.relative_to(OUT)), 'seconds':round(len(data)/RATE,3),
                   'peak_dbfs':round(20*np.log10(np.max(abs(data))),2),
                   'rms_dbfs':round(20*np.log10(np.sqrt(np.mean(data**2))),2),
                   'sha256':hashlib.sha256(pcm.tobytes()).hexdigest()})

def war_drum(high=False):
    t = np.arange(int(RATE*.65))/RATE
    f = 108 if high else 63
    y = np.zeros_like(t)
    for ratio, gain, decay in [(1,1,7),(1.59,.48,10),(2.14,.24,16),(2.65,.12,22)]:
        phase=2*np.pi*f*ratio*(t+.0018*(1-np.exp(-t*35)))
        y += gain*np.sin(phase)*np.exp(-t*decay)
    y += filtered_noise(len(t),2400)*np.exp(-t*65)*.22
    return y*envelope(t,.002,.035)


def score(name, bpm, bars):
    beat=60/bpm; length=int(round(bars*4*beat*RATE)); mix=np.zeros((length,2))
    def add(y, at, gain, pan=0):
        indices=(np.arange(len(y))+int(round(at*RATE)))%length
        np.add.at(mix[:,0],indices,y*gain*np.sqrt((1-pan)/2))
        np.add.at(mix[:,1],indices,y*gain*np.sqrt((1+pan)/2))
    def hz(midi): return 440*2**((midi-69)/12)
    # D major / G major / D major / A major: a bright, resolved palette.
    chords=[[62,66,69],[59,62,67],[62,66,69],[61,64,69]]
    roots=[50,43,50,45]
    melodies=[[74,78,81,78,83,81,78,76],
              [79,83,86,83,81,79,78,79],
              [81,78,74,78,81,83,81,78],
              [76,81,85,81,83,81,76,73]]
    low,high=war_drum(),war_drum(True)
    arena=name=='arena'
    # Both arrangements share timing and melody, preserving seamless entry.
    for bar in range(bars):
        ci=(bar//4)%4; at=bar*4*beat; chord=chords[ci]
        # The main melody gets space: two bowed notes per bar.
        for step in range(2):
            note=melodies[ci][(bar%4)*2+step]
            add(instrument(hz(note),beat*1.85,'strings'),at+step*2*beat,.15,.12)
        for i,note in enumerate(chord):
            add(instrument(hz(note),beat*3.9,'strings'),at,.027,[-.5,0,.5][i])
        # Warm cello on the strong beats; no sustained sub-bass drone.
        for step in [0,2]:
            add(instrument(hz(roots[ci]),beat*.85,'short_strings'),at+step*beat,.065,-.15)
        if arena:
            for step in range(8):
                add(instrument(hz(chord[step%3]),beat*.40,'short_strings'),at+step*.5*beat,.040,-.3)
            # A grounded marching pattern, with a restrained answering drum.
            for step,gain in [(0,.34),(1.5,.19),(2,.29),(3.5,.15)]:
                add(low,at+step*beat,gain,-.12)
            for step,gain in [(1,.19),(3,.22)]:
                add(high,at+step*beat,gain,.2)
        else:
            add(low,at,.095,-.1)
    mix += np.roll(mix[:,::-1].copy(),int(RATE*beat*.5),axis=0)*.075
    write(OUT/f'{name}.wav',mix,.58 if arena else .42)
    print(name,bpm,'BPM',round(length/RATE,2),'seconds',flush=True)

FAMILIES=['beast','claw','stone','wing','fire','lightning','ice','venom','spirit','nature','water','holy','metal','shadow','bow','quake','shield','heal']
SPECIES={'minotaur':'beast','golem':'stone','troll':'stone','wendigo':'shadow','direwolf':'beast','manticore':'venom','griffin':'wing','kitsune':'spirit','wyvern':'venom','harpy':'wing','phoenix':'fire','kirin':'lightning','basilisk':'venom','treant':'nature','naga':'water','unicorn':'holy','cerberus':'beast','nemean':'beast','yeti':'ice','zaratan':'shield','owlbear':'claw','hydra':'nature','chimera':'fire','gargoyle':'stone','nekomata':'shadow','jackalope':'nature','cyclops':'quake','thunderbird':'lightning','sphinx':'spirit','pegasus':'wing','arachne':'venom','salamander':'fire'}

def effect(family, duration=.42, pitch=1):
    t=np.arange(int(RATE*duration))/RATE; n=len(t)
    lo=filtered_noise(n,650); hi=filtered_noise(n,2500,True)
    env=envelope(t,.008,.07)*np.exp(-t*2.7)
    if family in ['beast','claw']:
        phase=2*np.pi*(74*pitch*t + 9*np.sin(t*7))
        y=(np.sin(phase)+.35*np.sin(phase*2)+.3*lo)*(0.7+.3*np.sin(t*35))
        y+=hi*np.exp(-t*26)*.25
    elif family in ['stone','quake']:
        y=np.sin(2*np.pi*(43*pitch*t+3*(1-np.exp(-t*15))))*.8+lo*.42
        y+=hi*.18*(np.sin(t*173)>0.4)*np.exp(-t*7)
    elif family=='wing':
        y=lo*(.35+.45*np.sin(t*24)**4)+hi*.15*np.exp(-t*7)
        y+=np.sin(2*np.pi*(430*pitch*t-120*t*t))*np.exp(-t*5)*.2
    elif family=='fire': y=lo*.5+hi*.25*(.2+.8*np.sin(t*311)**8)+np.sin(2*np.pi*58*t)*.3
    elif family=='lightning': y=hi*np.exp(-t*13)+np.sin(2*np.pi*(1100*pitch*t-480*t*t))*np.exp(-t*9)*.35+lo*.3
    elif family in ['ice','holy','shield','heal','metal']:
        base={'ice':970,'holy':520,'shield':340,'heal':440,'metal':620}[family]*pitch
        y=sum(np.sin(2*np.pi*base*k*t)*np.exp(-t*(2+i))*.45/(i+1) for i,k in enumerate([1,1.5,2.01,3.98]))
        if family in ['ice','metal']: y+=hi*.24*np.exp(-t*28)
    elif family in ['venom','water']:
        y=lo*.3 + np.sin(2*np.pi*(170*pitch*t+9*np.sin(t*23)))*(.15+.35*np.sin(t*19)**6)
        y+=hi*.15*np.exp(-t*4)
    elif family in ['spirit','shadow']:
        base=260 if family=='spirit' else 105
        y=(np.sin(2*np.pi*base*pitch*t)+.35*np.sin(2*np.pi*base*1.503*t))*(.4+.3*np.sin(t*13))
        y+=lo*.18+hi*.07
    elif family=='nature': y=lo*.4+hi*.3*np.exp(-t*35)+np.sin(2*np.pi*230*pitch*t)*np.exp(-t*10)*.45
    else: y=hi*.3*np.exp(-t*18)+np.sin(2*np.pi*(490*pitch*t-200*t*t))*np.exp(-t*13)*.6
    return y*env

score('preparation',132,32)
score('arena',132,32)
if args.music_only:
    manifest_path=OUT/'audio-manifest.json'
    previous=json.loads(manifest_path.read_text()) if manifest_path.exists() else {'assets':[]}
    previous['assets']=[a for a in previous['assets'] if a['file'] not in ['preparation.wav','arena.wav']] + report
    previous['score']={'bpm':132,'key':'D major','bars':32,'version':'0.8.2'}
    manifest_path.write_text(json.dumps(previous,indent=2))
    raise SystemExit(0)
for family in FAMILIES:
    base=effect(family)
    write(FX/f'{family}.wav',base,.74)
    write(FX/f'attack_{family}.wav',effect(family,.14),.60)
    charge=effect(family,.48)[::-1].copy()*np.linspace(.05,.6,int(RATE*.48))
    charge*=envelope(np.arange(len(charge))/RATE,.04,.04)
    write(FX/f'charge_{family}.wav',charge,.38)
    death=effect(family,1.05,.7)*np.exp(-np.arange(int(RATE*1.05))/RATE*.6)
    write(FX/f'death_{family}.wav',death,.66)
for i,(species,family) in enumerate(SPECIES.items()):
    y=effect(family,.40+(i%3)*.04,.86+(i%7)*.045)
    # Distinct layered signatures for each creature, not just arbitrary beeps.
    partner={'lightning':'holy','fire':'quake','beast':'claw','stone':'metal','wing':'spirit','nature':'water','venom':'shadow'}.get(family,'spirit')
    y+=effect(partner,len(y)/RATE,1.1)*.27
    write(FX/f'hero_{species}.wav',y,.80)
for key,notes in {'victory':[440,523.25,659.25,880],'honor':[440,392,329.63],'upgrade':[523.25,659.25,880],'multikill':[220,440,659.25],'arena_gate':[110,164.81,220],'interrupt':[620,310]}.items():
    length=2.0 if key in ['victory','arena_gate'] else 1.2
    y=np.zeros(int(length*RATE))
    for i,note in enumerate(notes):
        sound=instrument(note,.7,'brass' if key in ['arena_gate','victory'] else 'bell');start=int(i*.16*RATE)
        count=min(len(sound),len(y)-start);y[start:start+count]+=sound[:count]*.35
    if key=='arena_gate':
        kick=percussion('kick');y[:len(kick)]+=kick*.6
    write(FX/f'{key}.wav',y,.78)
(OUT/'audio-manifest.json').write_text(json.dumps({'rate':RATE,'families':FAMILIES,'species':SPECIES,'assets':report},indent=2))
print('Generated',len(report),'original audio assets',flush=True)
