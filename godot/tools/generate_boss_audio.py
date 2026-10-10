"""Deterministic original Warden cues. No source recordings or runtime synthesis.
Run from any directory; only writes boss_*.ogg and boss-audio-manifest.json.
"""
from pathlib import Path
import hashlib, json, subprocess, tempfile, wave
import numpy as np
RATE = 44100
ROOT = Path(__file__).resolve().parents[1] / 'assets/audio'
PROFILES = {
 'rootmother': (73, 430, [1, 1.49, 2.01]),
 'prismatic_archon': (294, 3600, [1, 2.01, 2.76, 4.03]),
 'forge_tyrant': (49, 1900, [1, 1.59, 2.14]),
 'frost_matriarch': (196, 5200, [1, 2.71, 4.09]),
 'leviathan': (55, 650, [1, 1.33, 2.0]),
 'spore_queen': (139, 1200, [1, 1.17, 1.41]),
 'bone_king': (98, 2700, [1, 1.5, 2.11]),
 'tempest_roc': (247, 6800, [1, 1.41, 2.83]),
 'sun_pharaoh': (165, 2300, [1, 1.25, 1.5]),
 'abyssal_keeper': (41, 900, [1, 1.059, 1.414]),
}
ACTIONS = {'entrance':2.1, 'warning':1.25, 'attack':.95, 'summon':1.15,
           'phase':1.35, 'enrage':1.4, 'death':2.6}

def synth(boss, action):
    f, cutoff, ratios = PROFILES[boss]
    duration = ACTIONS[action]
    t = np.arange(round(duration*RATE))/RATE
    seed = int.from_bytes(hashlib.sha256((boss+action).encode()).digest()[:8], 'little')
    rng = np.random.default_rng(seed)
    white = rng.normal(0, 1, len(t))
    freqs = np.fft.rfftfreq(len(t), 1/RATE)
    noise = np.fft.irfft(np.fft.rfft(white) / (1+(freqs/cutoff)**4), n=len(t))
    noise /= max(1e-9, np.sqrt(np.mean(noise**2)))
    x = t / duration
    if action == 'warning':
        # Rising three-beat inhale: clearly different from the release transient.
        sweep = 0.65 + x*.75
        env = (0.25+.75*x)*(0.25+.75*np.sin(np.pi*np.minimum(1,x*3))**2)
        noise_env = .1*x
    elif action == 'death':
        sweep = 1.1-.7*x; env = np.exp(-x*3.8); noise_env = .25*np.exp(-x*5)
    elif action == 'attack':
        sweep = 1.6-.9*x; env = np.exp(-x*5); noise_env = .48*np.exp(-x*10)
    elif action == 'enrage':
        sweep = 1+x*.4; env = (0.65+.35*np.sin(t*18))*np.exp(-x*1.4); noise_env = .24*env
    else:
        sweep = 0.8+x*.3; env = np.sin(np.pi*x)**.8
        noise_env = (.18 if action == 'summon' else .09)*env
    phase = 2*np.pi*np.cumsum(f*sweep)/RATE
    tonal = sum(np.sin(phase*r+i*.7) * (0.42/(i+1)) for i,r in enumerate(ratios))
    tonal += .08*np.sin(phase*.5)
    if boss in ['rootmother','bone_king']: noise_env *= 0.4+0.6*np.sin(t*47)**8
    if boss == 'leviathan': tonal *= 0.7+0.3*np.sin(t*9+np.sin(t*3))
    if boss == 'spore_queen': tonal *= .65+.35*np.sin(t*33)**2
    if boss == 'tempest_roc': noise_env *= .3+.7*np.sin(t*63)**12
    if boss == 'abyssal_keeper': tonal += .10*np.sin(phase*1.018)*np.sin(t*6)
    fade = np.minimum(1,t/.012)*np.minimum(1,(duration-t)/.065)
    y = np.tanh((tonal*env + noise*noise_env)*1.3)*fade
    y *= 10**(-4/20)/max(1e-9,np.max(abs(y)))
    return np.round(y*32767).astype('<i2')

def main():
    fx=ROOT/'fx'; fx.mkdir(parents=True,exist_ok=True); report=[]
    for boss in PROFILES:
        for action in ACTIONS:
            pcm=synth(boss,action); name=f'boss_{boss}_{action}.ogg'
            with tempfile.TemporaryDirectory() as tmp:
                source=Path(tmp)/'cue.wav'
                with wave.open(str(source),'wb') as out:
                    out.setnchannels(1);out.setsampwidth(2);out.setframerate(RATE);out.writeframes(pcm.tobytes())
                subprocess.run(['ffmpeg','-v','error','-y','-i',str(source),'-c:a','libvorbis','-q:a','5',str(fx/name)],check=True)
            report.append({'file':'fx/'+name,'seconds':len(pcm)/RATE,
                           'sha256':hashlib.sha256(pcm.tobytes()).hexdigest()})
    (ROOT/'boss-audio-manifest.json').write_text(json.dumps({'original':True,'rate':RATE,'cues':report},indent=2)+'\n')
    print(f'Generated {len(report)} unique original Warden cues')
if __name__=='__main__': main()
