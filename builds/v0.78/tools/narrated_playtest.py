"""Opt-in local mic capture; event metadata shares the Godot playtest session."""
import argparse, gzip, json, queue, subprocess, sys, time, uuid, wave
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools/narration-deps'))

def atomic_json(path, value):
    temp = path.with_suffix('.tmp')
    temp.write_text(json.dumps(value), encoding='utf-8'); temp.replace(path)

class Narration:
    def __init__(self, archive, session, build, rate=16000, seconds=30, automated=False):
        self.archive, self.session, self.build = Path(archive), session, build
        self.folder = self.archive / 'narration' / session
        self.folder.mkdir(parents=True, exist_ok=True)
        self.rate, self.limit = rate, int(rate * seconds)
        self.facts, self.clips, self.handle = [], [], None
        self.frames, self.index, self.started = 0, 0, 0
        self.paused, self.level = False, 0.0
        self.who = 'agent' if automated else 'human'
    def fact(self, kind, **data):
        self.facts.append(dict(kind=kind,t=int(time.time()*1000),session=self.session,
                               build=self.build,actor='1',who=self.who,schema=1,**data))
    def add(self, pcm, start_ms):
        if self.handle:
            expected=self.started+round(self.frames/self.rate*1000)
            if abs(start_ms-expected)>50:
                self.fact('narration_gap',expected_ms=expected,actual_ms=start_ms,gap_ms=start_ms-expected)
                self.close_clip()
        if not self.handle:
            self.index += 1; self.frames=0; self.started=start_ms
            self.path=self.folder/f'{self.index:04d}.wav'
            self.handle=wave.open(str(self.path)+'.partial','wb')
            self.handle.setnchannels(1); self.handle.setsampwidth(2); self.handle.setframerate(self.rate)
        # Split exactly at the configured frame count, including oversized callback blocks.
        take=min(len(pcm)//2,self.limit-self.frames)
        self.handle.writeframesraw(pcm[:take*2]); self.frames+=take
        if self.frames==self.limit: self.close_clip()
        if take*2<len(pcm): self.add(pcm[take*2:],start_ms+round(take/self.rate*1000))
    def close_clip(self):
        if not self.handle: return
        self.handle.close(); self.handle=None
        Path(str(self.path)+'.partial').replace(self.path)
        duration=self.frames/self.rate
        clip=dict(file=self.path.relative_to(self.archive).as_posix(),start_ms=self.started,
                  duration_seconds=duration,sample_rate=self.rate,frames=self.frames)
        self.clips.append(clip); self.fact('narration_clip',**clip)
    def status(self, state, detail=''):
        atomic_json(self.folder/'status.json',dict(state=state,detail=detail,updated_ms=int(time.time()*1000)))
    def save_facts(self):
        if not self.facts: return
        path=self.archive/f'{int(time.time()*1000):013d}-{self.session}-narration-{uuid.uuid4().hex[:8]}.jsonl.gz'
        temp=Path(str(path)+'.partial')
        with gzip.open(temp,'wt',encoding='utf-8') as output:
            for fact in self.facts: output.write(json.dumps(fact,ensure_ascii=False)+'\n')
        temp.replace(path); self.facts=[]
    def transcribe(self):
        manifest=self.folder/'clips.json'
        atomic_json(manifest,self.clips)
        result=subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',
                               str(ROOT/'tools/transcribe_narration.ps1'),'-Manifest',str(manifest)],
                              capture_output=True,timeout=max(60,len(self.clips)*90))
        if result.returncode:
            self.fact('narration_error',stage='transcription',reason='offline_recognizer_failed')
            print('Offline transcription failed; WAV recordings are preserved.'); return
        transcript=self.folder/'transcript.json'
        utterances=json.loads(transcript.read_text(encoding='utf-8-sig'))
        for item in utterances: self.fact('narration_transcript',**item,engine='windows-offline',review_required=True)
        self.fact('narration_transcription_complete',utterances=len(utterances))

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--device'); ap.add_argument('--devices',action='store_true')
    ap.add_argument('--game', type=Path, help='Packaged Manitoria executable to narrate')
    args=ap.parse_args()
    import sounddevice as sd
    if args.devices: print(sd.query_devices()); return
    project=ROOT/'godot' if (ROOT/'godot/project.godot').exists() else ROOT/'existing-manitoria/godot'
    packaged_stamp=args.game.resolve().parent/'playtest-build.json' if args.game else None
    if packaged_stamp and packaged_stamp.exists():
        build=json.loads(packaged_stamp.read_text())['build']
    else:
        subprocess.run([sys.executable,str(ROOT/'tools/stamp_playtest.py')],check=True)
        build=json.loads((project/'data/playtest-build.json').read_text())['build']
    session=uuid.uuid4().hex; rec=Narration(ROOT/'facts-archive',session,build)
    command=([str(args.game.resolve())] if args.game else
             [str(ROOT/'tools/editor/Godot_v4.7.2-stable_win64.exe'),'--path',str(project)])
    command+=['--','--playtest',f'--playtest-session={session}',f'--facts-dir={rec.archive}','--narration']
    blocks=queue.Queue(maxsize=100); dropped=0; stream=None; game=None
    def callback(data,frames,timing,status):
        nonlocal dropped
        # PortAudio's stream clock estimates the first sample's wall-clock timestamp.
        start=int(time.time()*1000-(timing.currentTime-timing.inputBufferAdcTime)*1000)
        try: blocks.put_nowait((bytes(data),start,bool(status)))
        except queue.Full: dropped+=frames
    def drain():
        while True:
            try: pcm,start,overflow=blocks.get_nowait()
            except queue.Empty: break
            if overflow: rec.fact('narration_error',stage='capture',reason='input_overflow')
            rec.add(pcm,start)
    print('Narrated playtest: requesting microphone. F8 pauses/resumes. Audio stays local.')
    try:
        game=subprocess.Popen(command)
        try:
            stream=sd.RawInputStream(samplerate=16000,channels=1,dtype='int16',device=args.device,
                                     blocksize=1600,callback=callback)
            stream.start(); rec.fact('narration_start',sample_rate=16000); rec.status('recording')
            print('Microphone recording is ON.')
        except Exception as exc:
            if stream:
                try: stream.close()
                except Exception: pass
            stream=None
            rec.fact('narration_error',stage='capture',reason='microphone_unavailable')
            rec.status('error','Microphone unavailable'); print('Microphone unavailable:',exc)
        control=rec.folder/'control.json'; last_request=None; heartbeat=0
        while game.poll() is None:
            if stream:
                if control.exists():
                    try:
                        request=json.loads(control.read_text())
                        if request.get('id')!=last_request:
                            last_request=request.get('id')
                            if not rec.paused:
                                stream.stop();drain();rec.close_clip();rec.paused=True
                                rec.fact('narration_pause');rec.status('paused')
                            else:
                                stream.start();rec.paused=False
                                rec.fact('narration_resume');rec.status('recording')
                    except (OSError,ValueError): pass
                drain()
                if time.monotonic()-heartbeat>1:
                    rec.status('paused' if rec.paused else 'recording');heartbeat=time.monotonic()
            if rec.facts: rec.save_facts()
            time.sleep(.05)
    finally:
        if stream:
            try: stream.stop()
            except Exception: rec.fact('narration_error',stage='capture',reason='stop_failed')
            try: stream.close()
            except Exception: rec.fact('narration_error',stage='capture',reason='close_failed')
        drain();rec.close_clip()
        rec.fact('narration_end',dropped_frames=dropped);rec.status('stopped');rec.save_facts()
        if game and game.poll() is None: game.wait()
    if rec.clips:
        print('Generating offline transcript...')
        try: rec.transcribe()
        except Exception as exc:
            rec.fact('narration_error',stage='transcription',reason='transcription_failed')
            print('Audio preserved; transcript unavailable:',exc)
        rec.save_facts()
    print('Narration saved:',rec.folder)
if __name__=='__main__': main()
