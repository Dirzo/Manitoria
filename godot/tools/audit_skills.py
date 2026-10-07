import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
inventory=json.loads((root/'data/skill-inventory.json').read_text())
species=json.loads((root/'data/species.json').read_text())
# Every champion has an intentional identity, including alternative build paths.
themes={
'minotaur':'bronze horns, labyrinth masonry, blood-red banners and charging bull strength',
'golem':'granite fists, blue crystal shards and protective engraved runes',
'troll':'mossy hide, bog sludge, bone clubs and stubborn regeneration',
'wendigo':'gaunt antlers, frozen hunger, soul frost and predatory claws',
'direwolf':'silver moonlight, wolf fangs, a coordinated hunting pack and winter trails',
'manticore':'lion claws, scorpion barbs, violet venom and desert ambushes',
'griffin':'golden eagle talons, lion courage, feather blades and diving wind',
'kitsune':'violet foxfire, spectral tails, shrine charms and trickster illusions',
'wyvern':'acid-green breath, stinging tail spikes and caustic wingbeats',
'harpy':'teal storm feathers, curved talons and disorienting siren song',
'phoenix':'solar fire, golden feathers, healing embers and rebirth from ash',
'kirin':'jade antlers, celestial lightning, thunder hooves and benevolent blessings',
'basilisk':'emerald serpent eyes, petrified stone, venom fangs and heavy coils',
'treant':'living roots, thorn branches, amber sap and protective ancient bark',
'naga':'turquoise tides, pearl magic, serpent coils and siren currents',
'unicorn':'silver horn, opalescent starlight, purifying radiance and healing moonlight',
'cerberus':'three infernal canine heads, iron gate chains and brimstone breath',
'nemean':'golden lion mane, impervious hide, royal claws and commanding roars',
'yeti':'ice-crusted fists, snowballs, glacial armor and avalanches',
'zaratan':'island turtle shell, coral reefs, kelp snares and crushing tides',
'owlbear':'feathered bear claws, forest instincts, heavy mauling and protective den',
'hydra':'multiple emerald serpent heads, swamp venom and regenerating flesh',
'chimera':'lion claws, goat horns, serpent venom and dragon flame',
'gargoyle':'gothic stone wings, cathedral bells, granite skin and violet runes',
'nekomata':'twin ghost-cat tails, cursed claws, violet spirit fire and shadow ambushes',
'jackalope':'briar antlers, swift rabbit kicks, burrow trails and lucky clover charms',
'cyclops':'one burning eye, massive thrown boulders, forge iron and titan strength',
'thunderbird':'blue lightning, bronze talons, charged feather volleys and thunderclouds',
'sphinx':'golden hieroglyphs, ancient riddles, desert sand and oracle starlight',
'pegasus':'white wings, aurora trails, celestial hooves and healing cloud winds',
'arachne':'violet silken webs, emerald venom sacs, spiderlings and protective cocoons',
'salamander':'molten scales, orange magma, volcanic ash and burning firebolts'}
spell={'ap':1.0}; strike={'ad':1.0}; rapid={'ad':.85,'ap':.15,'as':.40}
guard={'armor':.45,'hp':.45,'ap':.10}; heal={'ap':.75,'hp':.25}
physical={'ambush','execute','drain','whirl','barrage','quake','fissure','meteor','beam'}
# This is an explicit per-champion audit, not a shared animation deciding scaling.
families={
'minotaur':('bruiser',{'fear','rally','ward','renew'}),
'golem':('stone',{'beam','silence','roots'}),
'troll':('brawler',{'toxic','renew','ward','rally'}),
'wendigo':('hybrid',{'frost','beam','wisps','storm','silence','fear'}),
'direwolf':('hunter',set()),'manticore':('hybrid',{'toxic','frost','wisps','gust','meteor'}),
'griffin':('hunter',{'silence'}),'kitsune':('mage',set()),
'wyvern':('hybrid',{'toxic','gust','beam','fire','storm','meteor'}),
'harpy':('hybrid',{'gust','storm','silence','fear','roots'}),
'phoenix':('mage',set()),'kirin':('mage',set()),'basilisk':('mage',set()),
'treant':('grove',{'toxic','roots','wisps','beam','renew'}),
'naga':('mage',set()),'unicorn':('mage',set()),
'cerberus':('hybrid',{'fire','roots','fear','silence','gust','meteor'}),
'nemean':('bruiser',set()),'yeti':('ice',{'beam','silence','fear'}),
'zaratan':('stone',{'gust','roots','storm'}),'owlbear':('brawler',set()),
'hydra':('hybrid',{'toxic','roots','meteor','beam','fear','silence'}),
'chimera':('hybrid',{'fire','roots','beam','fear','meteor','toxic'}),
'gargoyle':('stone',{'silence','fear','fire'}),
'nekomata':('hybrid',{'silence','fire','wisps','fear','roots','toxic'}),
'jackalope':('hunter',{'renew','gust','beam'}),'cyclops':('bruiser',{'storm','fire','beam'}),
'thunderbird':('hybrid',{'storm','gust','beam','silence','meteor','wisps'}),
'sphinx':('mage',set()),'pegasus':('mage',set()),
'arachne':('mage',set()),'salamander':('mage',set())}
# Replace misleading verbs/behaviors while preserving saved skill indices.
changes={
('arachne','2'):('Silk Bind','roots','weaken'),
('arachne','3'):('Spider Swarm','brood','none'),
('arachne','4'):('Web Volley','barrage','root'),
('arachne','5'):('Venomfang Injection','execute','venom'),
('arachne','7'):('Venom Sac Rupture','meteor','venom'),
('arachne','8'):('Weaver\'s Lure','roots','silence'),
('arachne','9'):('Brood Mother','brood','guard'),
('arachne','10'):('Silken Spiral','roots','venom'),
('arachne','11'):('Poison Nest','toxic','root'),
('direwolf','8'):('Pack Flurry','barrage','weaken'),
('direwolf','9'):('Shadow Stalk','ambush','root'),
('direwolf','10'):('Lunar Bite','execute','leech'),
('nekomata','6'):('Shadow Pounce','ambush','stun'),
('basilisk','8'):('Toxic Pool','toxic','weaken'),
('chimera','11'):('Venom Smoke','toxic','weaken'),
('zaratan','6'):('Ancient Warning','fear','guard'),
('cyclops','5'):('Unerring Gaze','beam','echo'),
('owlbear','8'):('Moonlit Hunt','execute','weaken'),
('salamander','3'):('Lava Pool','magma','chill'),
('naga','11'):('Brine Spray','gust','weaken'),
}
actions={
'quake':'Release a close shockwave for 150% skill power and stun nearby foes for 0.8s.',
'rally':'Rally nearby allies for +22% attack and speed for 4s; grant an 8% base-health shield.',
'fissure':'Send a piercing ground surge through a line for 150% skill power and root for 1s.',
'ward':'Shield nearby allies for 22% of your base health for 5s, amplified by this skill’s scaling.',
'meteor':'Drop a heavy themed projectile on a cluster for 180% skill power and stun.',
'renew':'Heal the three most wounded allies for 130% skill power plus 8% of each ally’s health.',
'drain':'Drain the target for 170% skill power and heal for damage actually dealt.',
'fear':'Unleash an intimidating aura that weakens nearby enemies for 4s.',
'ambush':'Leap to the target, strike for 190% skill power and gain a 12% maximum-health shield.',
'toxic':'Afflict a cluster with a lingering toxin for 40% skill power per second for 4s.',
'execute':'Strike for 140% skill power; double it against targets below 35% health.',
'gust':'Blast a cluster for 130% skill power, push foes one hex and slow for 2s.',
'wisps':'Launch three seeking projectiles at different foes for 85% skill power each.',
'barrage':'Launch five rapid projectiles at one target for 45% skill power each.',
'silence':'Disrupt a cluster for 90% skill power and silence it for 2.5s.',
'beam':'Fire a piercing line for 180% skill power.',
'storm':'Strike three enemies with elemental bolts for 110% skill power each.',
'frost':'Immobilize a cluster for 0.8s and deal 110% skill power.',
'roots':'Bind a cluster for 1.8s and deal 100% skill power.',
'fire':'Blast a cluster for 120% skill power, then burn for 30% per second for 3s.',
'whirl':'Sweep nearby enemies for 200% skill power and gain a 12% maximum-health shield.',
'brood':'Hatch two spiderlings for 16s, up to three active. AP strengthens their health and bites; bites slow.',
'magma':'Erupt a molten pool for 60% skill power on impact and 35% per second for 4s. The pool slows foes.',
}
out={}
for row in inventory:
 sp=row['species'];idx=row['index'];name=row['name'];effect=row['effect'];rider=row.get('rider','none')
 if (sp,idx) in changes:name,effect,rider=changes[sp,idx]
 redundant={'fire':{'burn':'echo'},'toxic':{'venom':'weaken'},'quake':{'stun':'weaken','root':'weaken'},'fissure':{'root':'weaken'},'roots':{'root':'weaken'},'fear':{'weaken':'guard'},'gust':{'chill':'echo'},'frost':{'stun':'weaken'}}
 rider=redundant.get(effect,{}).get(rider,rider)
 family,magic=families[sp]
 if effect in {'ward','rally','fear'}:
  p=guard if family in {'stone','bruiser','ice','brawler','grove'} else heal
 elif effect=='renew':p={'hp':.75,'ap':.25} if family in {'brawler','stone'} or sp=='hydra' else heal
 elif family=='mage' or effect in magic or effect not in physical:p=spell
 elif family in {'stone','ice','grove'}:p={'armor':.65,'ad':.35} if effect in {'quake','fissure','whirl','meteor','barrage'} else {'ap':.55,'armor':.45}
 elif family=='bruiser':p={'ad':.70,'hp':.30} if effect in {'quake','fissure','meteor','whirl'} else strike
 elif family=='brawler':p={'ad':.70,'hp':.30} if effect in {'quake','meteor','fissure'} else rapid if effect in {'whirl','barrage'} else strike
 else:p=rapid if effect in {'whirl','barrage'} else strike
 if sp=='manticore' and effect in magic:p={'ap':.75,'ad':.25}
 if sp=='yeti' and effect in {'meteor','frost'}:p={'ap':.55,'armor':.45}
 if sp=='thunderbird' and effect=='whirl':p={'ap':.80,'ad':.20,'as':.25}
 if sp=='thunderbird' and effect=='barrage':p={'ad':.85,'ap':.15,'as':.50}
 # Signature powers retain established behavior, with deliberate species-specific channels.
 if idx=='signature':
  if sp in {'minotaur','troll'}:p={'ad':.70,'hp':.30}
  elif sp in {'golem','nemean','yeti','zaratan'}:p=guard
  elif sp=='hydra':p={'hp':.80,'ap':.20}
  elif sp=='gargoyle':p={'armor':.70,'ad':.30}
  elif sp in {'direwolf','wendigo','manticore','griffin','owlbear','nekomata','jackalope','cyclops'}:p=rapid if sp in {'direwolf','wendigo','jackalope'} else strike
  elif sp in {'treant','naga','unicorn','pegasus'}:p=heal
  elif sp=='chimera':p={'ad':.55,'ap':.45,'as':.35}
  elif sp=='cerberus':p={'ad':.85,'ap':.15,'as':.40}
  else:p=spell
 magical=p.get('ad',0)<.5 and p.get('armor',0)<.5
 # Utility skills have no offensive damage; classification only governs actual hits.
 text=row['description'] if idx=='signature' else actions[effect]
 if sp=='arachne' and effect=='ward':p={'ap':.85,'hp':.15}
 if sp=='arachne' and effect=='brood':p=spell
 theme=themes[sp]
 if idx!='signature':text=name+': '+text
 base_cds={'quake':10,'rally':14,'fissure':11,'ward':13,'meteor':12,'renew':12,'drain':10,'fear':14,'ambush':12,'toxic':11,'execute':10,'gust':11,'wisps':10,'barrage':10,'silence':13,'beam':12,'storm':12,'frost':12,'roots':12,'fire':11,'whirl':10,'brood':16,'magma':14}
 cd=float(row.get('cooldown',species[sp]['cd'])) if idx=='signature' or int(idx)>=12 else float(base_cds[effect])
 power=1.0 # Remove hash-derived hidden bonuses; rider skills pay a visible cooldown premium.
 if rider!='none':cd=round(cd*1.08,1)
 if effect=='brood':cd=18.0 if idx=='9' else 16.0
 if effect=='rally' and rider=='haste':rider='guard' # self rally is already included: no redundant haste rider.
 out.setdefault(sp,{})[idx]={'name':name,'effect':effect,'rider':rider,'scaling':p,'magical':magical,'description':text,'cooldown':cd,'power':power,'theme':theme}
 close_strikes={'direwolf':{'barrage','execute','drain'},'owlbear':{'barrage','execute','drain'},'hydra':{'barrage','execute'},'minotaur':{'execute','drain'},'nemean':{'execute','drain'},'griffin':{'drain'},'wendigo':{'execute','drain'}}
 if idx!='signature' and effect in close_strikes.get(sp,set()):out[sp][idx]['range']=3.0
from build_paths import rebalance
balance=rebalance(out)
assert balance['counts']['ad']==174 and balance['counts']['ap']==174,balance
(root/'data/build-path-audit.json').write_text(json.dumps(balance,indent=2)+'\n')
(root/'data/skill-audit.json').write_text(json.dumps(out,indent=2)+'\n',encoding='utf-8')
print('Audited',sum(map(len,out.values())),'actions across',len(out),'champions')

