import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
book=json.loads((root/'data/skill-audit.json').read_text())
subjects={
'quake':'a powerful impact shockwave cracking the earth in a radial burst',
'rally':'an inspiring crest emanating protective rays toward allied silhouettes',
'fissure':'a dramatic diagonal ground fracture surging toward a foe',
'ward':'a luminous layered protective barrier surrounding a single clear emblem',
'meteor':'one heavy descending projectile with an explosive impact trail',
'renew':'restorative energy gathering around a wounded ally, bright healing core',
'drain':'a hungry tether pulling life energy from a foe into the caster',
'fear':'a looming menacing visage releasing a rippling intimidating aura',
'ambush':'a predatory leaping strike emerging from shadow in a sharp diagonal',
'toxic':'a bursting venom sac spreading a luminous toxic pool',
'execute':'one lethal empowered strike with a sharp pointed focal silhouette',
'gust':'a forceful curling blast of wind pushing a foe away',
'wisps':'three luminous seeking projectiles sweeping forward in separate arcs',
'barrage':'five razor projectiles streaking forward in a concentrated volley',
'silence':'a powerful disruptive ripple shattering a magical sigil',
'beam':'one piercing focused lance of power crossing the square diagonally',
'storm':'three descending elemental bolts branching from a turbulent cloud',
'frost':'a target trapped inside a crystalline binding burst',
'roots':'a tightly bound silhouette caught in the champion’s thematic snares',
'fire':'an explosive elemental blast with curling lingering flame trails',
'whirl':'a broad spiraling sweep of the champion’s thematic weapon or magic',
'brood':'spiderlings emerging from a torn luminous silk egg sac',
'magma':'an eruption of orange molten lava spreading into a glowing volcanic pool across cracked black ground',
}
jobs=[]
for sp in ['arachne','thunderbird']+[s for s in book if s not in ['arachne','thunderbird']]:
 for key,a in book[sp].items():
  file=f'signature-{sp}.png' if key=='signature' else f'{sp}-{key}.png'
  subject=a['description'] if key=='signature' else subjects[a['effect']]
  if sp=='arachne':subject=subject.replace('crystalline','silken').replace('flame','venom')
  if sp=='naga' and key=='11':subject='a forceful curling jet of turquoise seawater spraying outward and pushing a dark foe back, with foaming white surf and bright pearlescent highlights; no fire, lava or wind blades'
  prompt=f'''Use case: stylized-concept.
Asset type: ONE square fantasy MOBA ability icon for Manitoria.
Skill: {sp.title()} — {a['name']}. Depict this exact concept, never write its name in the image.
Subject: {subject}
Champion motifs: {a['theme']}. Use only motifs relevant to this named skill; avoid piling unrelated motifs together.
Composition: one strong focal silhouette filling 80% of the square; distinguish this ability by its action and named theme; readable at 48 pixels.
Style: premium polished painterly fantasy spell art comparable in finish to League of Legends, Dota and Auto Chess ability icons, original design. Sculptural materials, rich color, dramatic colored rim light, sharp focal detail and restrained peripheral effects. Match the quality of ornate gold-and-blue fantasy item renders.
Background: opaque, dark atmospheric background tinted to the champion’s element. One finished square image.
Avoid: text, lettering, numbers, UI, frames, borders, logos, watermark, grids, multiple panels, generic weapon standing alone if the skill depicts an action.'''
  jobs.append({'id':f'{sp}:{key}','species':sp,'key':key,'name':a['name'],'file':file,'prompt':prompt,'status':'complete' if (root/'art-progress'/f'{sp}-{key}.json').exists() else 'pending'})
(root/'data/skill-art-prompts.json').write_text(json.dumps(jobs,indent=2)+'\n',encoding='utf-8')
status=root/'art-progress';status.mkdir(exist_ok=True)
if not (status/'arachne-signature.json').exists():
 (status/'arachne-signature.json').write_text(json.dumps({'id':'arachne:signature','file':'signature-arachne.png','status':'complete','mode':'built-in'}))
print('Prepared',len(jobs),'individual built-in image prompts')

