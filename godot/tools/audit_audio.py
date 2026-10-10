"""Decode every shipped WAV/OGG and measure levels; write reproducible evidence.
Requires numpy and ffmpeg. Run: python3 godot/tools/audit_audio.py
"""
from pathlib import Path
import hashlib, json, subprocess, wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]

def audit():
    rows=[]; errors=[]; groups={}
    for path in sorted((ROOT/'assets/audio').rglob('*')):
        if path.suffix not in ['.ogg','.wav']: continue
        try:
            if path.suffix=='.wav':
                with wave.open(str(path),'rb') as f:
                    if f.getsampwidth()!=2: raise ValueError('Expected PCM16 WAV')
                    rate=f.getframerate(); channels=f.getnchannels()
                    pcm=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').astype(np.float32)/32768
            else:
                # Use a common rate/channel count for decoded comparison and level inspection.
                data=subprocess.run(['ffmpeg','-v','error','-i',str(path),'-f','f32le','-ar','44100','-ac','2','pipe:1'],capture_output=True,check=True).stdout
                pcm=np.frombuffer(data,dtype='<f4'); rate=44100; channels=2
            if not pcm.size or not np.isfinite(pcm).all(): raise ValueError('Empty/non-finite samples')
            peak=float(np.max(abs(pcm))); rms=float(np.sqrt(np.mean(pcm.astype(np.float64)**2)))
            if rms<1e-6: raise ValueError('Silent asset')
            key=str(path.relative_to(ROOT)); digest=hashlib.sha256(pcm.tobytes()).hexdigest()
            groups.setdefault(digest,[]).append(key)
            rows.append({'file':key,'seconds':round(pcm.size/rate/channels,3),'channels':channels,'sample_rate':rate,
                         'peak_dbfs':round(20*np.log10(max(peak,1e-9)),2),'rms_dbfs':round(20*np.log10(max(rms,1e-9)),2),
                         'full_scale_samples':int(np.count_nonzero(abs(pcm)>=.9999)), 'decoded_sha256':digest})
        except Exception as e: errors.append({'file':str(path.relative_to(ROOT)),'error':str(e)})
    report={'files':len(rows),'decode_errors':errors,'full_scale_files':[r['file'] for r in rows if r['full_scale_samples']],
            'identical_audio':[v for v in groups.values() if len(v)>1], 'assets':rows,
            'limitations':'Decoded sample peaks and RMS, not integrated LUFS, true peak or a listening/playback-device audit.'}
    out=ROOT/'data/audio-audit.json';out.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k not in ['assets','identical_audio']},indent=2))
    print('Identical audio groups:',len(report['identical_audio']))
    return bool(errors)
if __name__=='__main__': raise SystemExit(int(audit()))
