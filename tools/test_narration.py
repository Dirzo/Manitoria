"""Synthetic audio only: never opens a microphone or launches the game."""
import json, subprocess, tempfile, time, unittest, wave
import types,sys,uuid
from unittest import mock
from pathlib import Path
from narrated_playtest import Narration, ROOT

class RecordingTests(unittest.TestCase):
    def test_start_failure_never_claims_recording(self):
        import narrated_playtest as module
        states=[];stream=mock.Mock();stream.start.side_effect=RuntimeError('device refused')
        game=mock.Mock();game.poll.side_effect=[None,0,0]
        with tempfile.TemporaryDirectory(dir=ROOT/'tools') as folder:
            task_root=Path(folder);data=task_root/'existing-manitoria/godot/data';data.mkdir(parents=True)
            (data/'playtest-build.json').write_text(json.dumps({'build':'synthetic-test'}))
            original=module.atomic_json
            def status(path,value):
                if 'state' in value: states.append(value['state'])
                original(path,value)
            with mock.patch.object(module,'ROOT',task_root),mock.patch.object(sys,'argv',['test']), \
                 mock.patch.dict(sys.modules,{'sounddevice':types.SimpleNamespace(RawInputStream=lambda **kw:stream)}), \
                 mock.patch.object(module.subprocess,'Popen',return_value=game), \
                 mock.patch.object(module.subprocess,'run'),mock.patch.object(module,'atomic_json',side_effect=status):
                module.main()
        self.assertIn('error',states);self.assertNotIn('recording',states)
        stream.close.assert_called_once()
    def test_gap_keeps_real_time_alignment(self):
        with tempfile.TemporaryDirectory(dir=ROOT/'tools') as folder:
            rec=Narration(folder,'c'*32,'test-build')
            rec.add(b'\0\0'*1600,100000)
            rec.add(b'\0\0'*1600,105000)
            rec.close_clip()
            self.assertEqual([c['start_ms'] for c in rec.clips],[100000,105000])
            self.assertEqual(sum(f['kind']=='narration_gap' for f in rec.facts),1)
    def test_rotation_timing_and_final_flush(self):
        with tempfile.TemporaryDirectory(dir=ROOT/'tools') as folder:
            rec=Narration(folder,'a'*32,'test-build',rate=16000,seconds=1)
            rec.add(b'\x01\x00'*40000,100000)
            rec.close_clip();rec.save_facts()
            self.assertEqual([c['frames'] for c in rec.clips],[16000,16000,8000])
            self.assertEqual([c['start_ms'] for c in rec.clips],[100000,101000,102000])
            for c in rec.clips:
                with wave.open(str(Path(folder)/c['file'])) as audio:
                    self.assertEqual(audio.getnframes(),c['frames'])
                    self.assertEqual(audio.getsampwidth(),2)
            self.assertFalse(list(Path(folder).rglob('*.partial')))
    def test_offline_recognition(self):
        folder=ROOT/'tools/narration-fixture';folder.mkdir(exist_ok=True)
        rec=Narration(folder,uuid.uuid4().hex,'synthetic-narration-validation',automated=True)
        source=folder/'spoken.wav'
        # Paths are parameters, never interpolated as PowerShell code.
        subprocess.run(['powershell.exe','-NoProfile','-File',str(ROOT/'tools/synthesize_narration_test.ps1'),
                        '-Output',str(source)],check=True,capture_output=True)
        with wave.open(str(source)) as audio:
            self.assertEqual(audio.getframerate(),16000)
            rec.add(audio.readframes(audio.getnframes()),int(time.time()*1000))
        rec.close_clip();rec.transcribe();rec.save_facts()
        result=json.loads((rec.folder/'transcript.json').read_text(encoding='utf-8-sig'))
        self.assertGreater(len(result),0)
        self.assertTrue(all('confidence' in item and 'start_ms' in item for item in result))
        self.assertEqual(sorted(item['start_ms'] for item in result),[item['start_ms'] for item in result])
        print('Synthetic recognized narration:',result)
if __name__=='__main__': unittest.main()
