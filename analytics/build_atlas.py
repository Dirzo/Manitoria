from pathlib import Path
from collections import defaultdict
from datetime import datetime, timezone
from statistics import mean
import argparse, json, hashlib, shutil
from PIL import Image

PROJECT=Path(__file__).resolve().parents[1]
ROOT=PROJECT.parent
SITE=PROJECT/'analytics'
parser=argparse.ArgumentParser();parser.add_argument('--partial',action='store_true');parser.add_argument('--dataset',default='pre');parser.add_argument('--labels',default='champions-a,champions-b,items-a,items-b,items-c,items-d');args=parser.parse_args()
labels=args.labels.split(',')
source=ROOT/'qa-analytics'
data_dir=PROJECT/'analytics/baseline-0.69' if args.dataset=='pre' else PROJECT/'godot/data'
species=json.loads((data_dir/'species.json').read_text(encoding='utf-8'))
skills=json.loads((data_dir/'skill-audit.json').read_text(encoding='utf-8'))
records=[];manifest=[]
for label in labels:
    files=list(source.rglob(f'analytics-{label}.jsonl'))
    if not files and args.partial:continue
    assert len(files)==1,(label,files)
    content=files[0].read_bytes();parsed=[]
    for line in content.decode('utf-8').splitlines():
        try:parsed.append(json.loads(line))
        except json.JSONDecodeError:
            if not args.partial:raise
    records.extend(parsed)
    manifest.append({'file':files[0].name,'games':len(parsed),'sha256':hashlib.sha256(content).hexdigest()})
champ_games=[r for r in records if r['kind']=='champions']
item_games=[r for r in records if r['kind']=='items']
keys=[(r['kind'],r['pair'],r['side'],r.get('condition','')) for r in records]
assert len(keys)==len(set(keys)), 'Duplicate battles in audit'
if not args.partial:
    assert len(champ_games)==1536,len(champ_games)
    assert len(item_games)==4352,len(item_games)
    assert all(r['seconds']>0 and r['winner'] in [-1,0,1] for r in records)
    assert all(min(r['wallets'])>=0 for r in champ_games)
    assert len({u['sp'] for r in champ_games for u in r['units']})==32
cat_files=list(source.rglob('analytics-catalog-*.json'))
assert cat_files,'Missing catalog'
catalog=json.loads(cat_files[0].read_text(encoding='utf-8'))['items']
for id,info in catalog.items():
    info['name']=info['name'].replace('\ufffd',"'")
    for key in ['description','text','tip']:
        if key in info:info[key]=info[key].replace('\ufffd','·')
    info['kind']='component' if info.get('kind')=='component' else 'forged' if 'recipe' in info else 'role item'
    info['cost']=140 if 'recipe' in info else info.get('price',70)

units=[];matches=[]
for r in champ_games:
    matches.append({k:r[k] for k in ['pair','side','cup','difficulty','winner','seconds','timeout','wallets','spent']})
    for u in r['units']:
        u=dict(u);u.update({k:r[k] for k in ['pair','side','cup','difficulty','seconds','timeout']});u['draw']=r['winner']==-1
        u['opponents']=[v['sp'] for v in r['units'] if v['team']!=u['team']]
        units.append(u)
paired=defaultdict(dict)
for r in item_games:paired[(r['item'],r['pair'],r['side'])][r['condition']]=r
effects=[]
for (id,pair,side),conditions in paired.items():
    if len(conditions)!=2:
        assert args.partial,'Missing paired control'
        continue
    test=conditions['item'];control=conditions['baseline']
    t=next(u for u in test['units'] if u['sp']==test['carrier'] and u['team']==side)
    b=next(u for u in control['units'] if u['sp']==control['carrier'] and u['team']==side)
    stats=t['skills'].get('item:'+id,{})
    effects.append({'id':id,'pair':pair,'side':side,'carrier':test['carrier'],'cup':test['cup'],'difficulty':test['difficulty'],'scenario':test['scenario'],'strategy':t['strategy'],'stars':t['stars'],'won':test['winner']==side,'baseline_won':control['winner']==side,'margin':test['margin']-control['margin'],'dps':t['damage']/test['seconds']-b['damage']/control['seconds'],'hps':t['healing']/test['seconds']-b['healing']/control['seconds'],'procs':stats.get('casts',0),'healing_denied':stats.get('healing_denied',0),'cooldown':stats.get('cooldown_recovered',0),'shielding':stats.get('shielding',0)})
if not args.partial:assert len(effects)==2176 and len({r['id'] for r in effects})==136

evo_files=list(source.rglob('analytics-evolutions.json'))
evolutions=json.loads(evo_files[0].read_text(encoding='utf-8')) if evo_files else {}
data={'version':'0.69' if args.dataset=='pre' else '0.70','dataset':args.dataset,'complete':not args.partial,'generated':'2026-10-07','battle_count':len(records),'champion_battles':len(champ_games),'item_battles':len(item_games),'item_tests':len(effects),'pairs':len({r['pair'] for r in champ_games}),'draws':sum(r['winner']==-1 for r in champ_games),'timeouts':sum(r['timeout'] for r in records),'species':species,'skills':skills,'evolutions':evolutions,'items':catalog,'units':units,'matches':matches,'effects':effects,'manifest':manifest}
SITE.mkdir(exist_ok=True)
(SITE/'data.js').write_text('window.ATLAS_DATA='+json.dumps(data,ensure_ascii=False,separators=(',',':'))+';\n',encoding='utf-8')
(SITE/'summary.json').write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
(SITE/f'audit-manifest-{args.dataset}.json').write_text(json.dumps({k:v for k,v in data.items() if k not in ['units','matches','effects','skills','species','items']},indent=2)+'\n',encoding='utf-8')
for folder in ['portraits','items','abilities']:
    target=SITE/'assets'/folder;target.mkdir(parents=True,exist_ok=True)
    for file in (PROJECT/'godot/assets'/folder).glob('*.png'):
        output=target/(file.stem+'.webp')
        if output.exists():continue
        img=Image.open(file);img.thumbnail((180,180) if folder=='portraits' else (96,96));img.save(output,'WEBP',quality=85)
for id,info in catalog.items():
    if info['kind']!='role item':continue
    initials=''.join(word[0] for word in info['name'].replace("'",'').split()[:2])
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96"><rect width="96" height="96" rx="12" fill="#14283b"/><path d="M48 7 82 27v42L48 89 14 69V27Z" fill="#1d3c4b" stroke="#c4ad73" stroke-width="2"/><text x="48" y="57" font-family="Segoe UI,sans-serif" font-weight="600" font-size="27" text-anchor="middle" fill="#d9ca98">{initials}</text></svg>'
    (SITE/'assets/items'/(id+'.svg')).write_text(svg,encoding='utf-8')
main=(SITE/'index.html').read_text(encoding='utf-8')
for sp in species:
    path=SITE/'champions'/sp;path.mkdir(parents=True,exist_ok=True)
    page=main.replace('<head>','<head><base href="../../">').replace('<body>',f'<body data-champion="{sp}">').replace('<title>Manitoria Atlas · Arena statistics</title>',f'<title>{species[sp]["n"]} builds &amp; skills · Manitoria Atlas</title>')
    (path/'index.html').write_text(page,encoding='utf-8')
print(f'Atlas {args.dataset}: {len(records)} complete battles; {len(units)} champion appearances; {len(effects)} matched item tests; {len(species)} champion detail pages')
if champ_games:
    rates=[]
    for sp in species:
        us=[u for u in units if u['sp']==sp]
        if us:rates.append((species[sp]['n'],len(us),round(mean(u['won'] for u in us)*100,1),round(mean(u['damage']/u['seconds'] for u in us),1),round(mean(u['healing']/u['seconds'] for u in us),1)))
    print('Champion screening (appearances, team win%, DPS, HPS):',sorted(rates,key=lambda r:-r[2]))
