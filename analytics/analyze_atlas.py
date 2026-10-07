from pathlib import Path
from collections import defaultdict
from statistics import mean,stdev
import json,math
root=Path(__file__).resolve().parents[1].parent
d=json.loads((root/'Manitoria/analytics/summary.json').read_text(encoding='utf-8'))
def groups(rows,key):
    result=defaultdict(list)
    for row in rows:result[key(row)].append(row)
    return result
def estimate(rows):
    n=len(rows);p=mean(float(r['won']) for r in rows) if n else 0
    k=len(set(r['pair'] for r in rows));z=1.96
    c=(p+z*z/(2*k))/(1+z*z/k) if k else .5
    h=z*math.sqrt(p*(1-p)/k+z*z/(4*k*k))/(1+z*z/k) if k else .5
    return {'appearances':n,'pairs':k,'win_pct':round(100*p,2),'interval_pct':[round(100*(c-h),2),round(100*(c+h),2)],'dps':round(mean(r['damage']/r['seconds'] for r in rows),2),'hps':round(mean(r['healing']/r['seconds'] for r in rows),2)}
champions=[]
for sp,rows in groups(d['units'],lambda r:r['sp']).items():
    r={'species':sp,'name':d['species'][sp]['n'],**estimate(rows)}
    for field in ['cup','strategy','stars','difficulty']:
        r[field]={str(k):estimate(rs) for k,rs in groups(rows,lambda u:u[field]).items()}
    champions.append(r)
items=[]
for id,rows in groups(d['effects'],lambda r:r['id']).items():
    vals=[mean(r['margin'] for r in rs) for rs in groups(rows,lambda r:r['pair']).values()]
    n=len(vals);m=mean(vals);t={2:12.706,3:4.303,4:3.182,5:2.776,6:2.571,7:2.447,8:2.365}.get(n,1.96)
    half=t*stdev(vals)/math.sqrt(n) if n>1 else 999
    items.append({'id':id,'name':d['items'][id]['name'],'tests':len(rows),'setups':n,'hp_delta':round(m,3),'interval':[round(m-half,3),round(m+half,3)],'win_pct':100*mean(r['won'] for r in rows),'baseline_pct':100*mean(r['baseline_won'] for r in rows),'dps_delta':round(mean(r['dps'] for r in rows),2),'hps_delta':round(mean(r['hps'] for r in rows),2),'carriers':sorted(set(r['carrier'] for r in rows))})
skills=[]
for (sp,key),rows in groups([{'u':u,'key':key,'m':m} for u in d['units'] for key,m in u['skills'].items() if key=='signature' or key.startswith('ability:')],lambda r:(r['u']['sp'],r['key'])).items():
    casts=sum(r['m'].get('casts',0) for r in rows)
    info=d['skills'][sp].get(key.replace('ability:',''),{})
    if not casts:continue
    skills.append({'species':sp,'key':key,'name':info.get('name',key),'effect':info.get('effect'),'casts':casts,**estimate([r['u'] for r in rows]),'damage_per_cast':round(sum(r['m'].get('damage',0) for r in rows)/casts,2),'healing_per_cast':round(sum(r['m'].get('healing',0) for r in rows)/casts,2)})
output={'version':d['version'],'complete':d['complete'],'battles':d['battle_count'],'champions':sorted(champions,key=lambda r:-r['win_pct']),'items':sorted(items,key=lambda r:-r['hp_delta']),'skills':sorted(skills,key=lambda r:-r['damage_per_cast'])}
(root/'atlas-analysis.json').write_text(json.dumps(output,indent=2),encoding='utf-8')
print('Battles',output['battles'],'complete',output['complete'])
print('Champions',[(r['name'],r['win_pct'],r['interval_pct']) for r in output['champions']])
print('Items with intervals excluding zero',[(r['name'],r['hp_delta'],r['interval']) for r in output['items'] if r['interval'][0]>0 or r['interval'][1]<0])
