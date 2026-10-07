"""Validate built-in deliverables and merge durable per-asset progress records."""
import hashlib,json,re,struct,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
jobs=json.loads((root/'data/skill-art-prompts.json').read_text(encoding='utf-8-sig'))
records={r['id']:r for f in (root/'art-progress').glob('*.json') for r in [json.loads(f.read_text())]}
errors=[];hashes={};complete=0
for job in jobs:
 record=records.get(job['id'])
 if not record:
  job['status']='pending';continue
 path=root/'assets/abilities'/job['file']
 if not path.exists():errors.append(job['id']+': generated file missing');continue
 raw=path.read_bytes()
 if raw[:8]!=b'\x89PNG\r\n\x1a\n':errors.append(job['id']+': invalid PNG');continue
 width,height=struct.unpack('>II',raw[16:24])
 if width!=height or width<256:errors.append(job['id']+': icon dimensions invalid')
 digest=hashlib.sha256(raw).hexdigest()
 if digest in hashes:errors.append(job['id']+': duplicate image of '+hashes[digest])
 hashes[digest]=job['id'];job.update(status='complete',sha256=digest,width=width,height=height,mode='built-in');complete+=1
 settings=path.with_suffix('.png.import')
 if settings.exists():
  text=settings.read_text().replace('process/size_limit=0','process/size_limit=256').replace('mipmaps/generate=false','mipmaps/generate=true')
  settings.write_text(text)
 if '--require-imported' in sys.argv:
  match=re.search(r'path="res://(.+\.ctex)"',settings.read_text()) if settings.exists() else None
  stamp=(root/match[1]).with_suffix('.md5') if match else None
  imported=stamp.read_text() if stamp and stamp.exists() else ''
  if 'source_md5="'+hashlib.md5(raw).hexdigest()+'"' not in imported:
   errors.append(job['id']+': imported texture does not match current source PNG')
(root/'data/skill-art-prompts.json').write_text(json.dumps(jobs,indent=2)+'\n',encoding='utf-8')
revisions=json.loads((root/'data/skill-art-revisions.json').read_text())
pending_revisions=[r['id'] for r in revisions if not records.get(r['id'],{}).get('revised',False)]
report={'complete':complete,'total':len(jobs),'pending':len(jobs)-complete,'pending_revisions':pending_revisions,'errors':errors,'mode':'built-in'}
(root/'data/skill-art-status.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))
if errors:raise SystemExit(1)
if '--require-complete' in sys.argv and (complete!=len(jobs) or pending_revisions):raise SystemExit(1)
