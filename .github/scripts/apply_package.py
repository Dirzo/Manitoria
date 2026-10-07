"""Apply a hash-checked source/assets package staged by the repository owner."""
from pathlib import Path, PurePosixPath
import hashlib, io, json, shutil, zipfile

root=Path.cwd().resolve()
transfer=(root/'.codex-transfer').resolve()
assert transfer.parent==root
manifest=json.loads((transfer/'manifest.json').read_text(encoding='utf-8'))
pending=[]
for archive in manifest['archives']:
    data=bytearray()
    for part in archive['parts']:
        path=(root/part['path']).resolve()
        assert path.parent==transfer
        raw=path.read_bytes()
        assert hashlib.sha256(raw).hexdigest()==part['sha256'],part['path']
        data.extend(raw)
    assert hashlib.sha256(data).hexdigest()==archive['sha256'],archive['name']
    expected={f['path']:f['sha256'] for f in archive['files']}
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        assert set(z.namelist())==set(expected),archive['name']
        for info in z.infolist():
            name=PurePosixPath(info.filename)
            assert not name.is_absolute() and '..' not in name.parts
            assert name.parts[0] in manifest['allowed_roots'] and '.git' not in name.parts
            assert '.github' not in name.parts,'Workflows are delivered separately'
            target=(root/info.filename).resolve()
            assert root in target.parents
            raw=z.read(info)
            assert hashlib.sha256(raw).hexdigest()==expected[info.filename],info.filename
            pending.append((target,raw))
for target,raw in pending:
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(raw)
print(f"Applied {len(pending)} verified files for Manitoria {manifest['version']}")
shutil.rmtree(transfer)
