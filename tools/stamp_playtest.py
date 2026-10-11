from pathlib import Path
import datetime, hashlib, json, subprocess
root = Path(__file__).resolve().parents[1]
project = root/'godot' if (root/'godot/project.godot').exists() else root/'existing-manitoria/godot'
h = hashlib.sha256()
for p in sorted(project.rglob('*')):
    if not p.is_file() or '.godot' in p.parts or p.name == 'playtest-build.json': continue
    if p.suffix in {'.import','.uid'}: continue
    h.update(p.relative_to(project).as_posix().encode())
    with p.open('rb') as source:
        for chunk in iter(lambda:source.read(1048576),b''): h.update(chunk)
stamp = {'build':'local-'+datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d')+'-'+h.hexdigest()[:16], 'source_sha256':h.hexdigest()}
(project/'data/playtest-build.json').write_text(json.dumps(stamp)+'\n',encoding='utf-8')
print(stamp['build'])
eras_path=root/'facts-eras.json'
eras=json.loads(eras_path.read_text(encoding='utf-8')) if eras_path.exists() else []
if not any(e['build']==stamp['build'] for e in eras):
    eras.append({'id':stamp['build'],'build':stamp['build'],'from':0,'environment':'local-playtest','change':'Source content hash; schema 1 playtest recorder'})
    eras_path.write_text(json.dumps(eras,indent=2)+'\n',encoding='utf-8')
