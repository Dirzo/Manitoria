
'use strict';
/* ============ DATA ============ */
const TIERS=[{n:'Mud Pits',q:36},{n:'Bronze Ring',q:48},{n:'Silver Colosseum',q:60},{n:'Mythic Arena',q:72}];
const ATTR=['pow','vit','grd','agi','ins'];
const ATTR_N={pow:'Power',vit:'Vitality',grd:'Guard',agi:'Agility',ins:'Instinct'};
const SPECIES={
 minotaur:{n:'Minotaur',role:'Bruiser',hp:1.25,atk:1.1,def:1.05,as:.9,mv:62,range:26,size:17,hue:18,ab:'gore',cd:7,b:[6,4,2,-4,-6]},
 golem:{n:'Stone Golem',role:'Tank',hp:1.6,atk:.72,def:1.5,as:.7,mv:48,range:26,size:19,hue:220,ab:'bulwark',cd:9,b:[-4,8,10,-10,-4]},
 troll:{n:'Cave Troll',role:'Bruiser',hp:1.45,atk:1,def:.9,as:.85,mv:55,range:28,size:18,hue:95,ab:'smash',cd:8,b:[4,10,0,-4,-8]},
 wendigo:{n:'Wendigo',role:'Bruiser',hp:1.1,atk:1.18,def:.8,as:1,mv:72,range:24,size:16,hue:190,ab:'hunger',cd:10,b:[8,2,-6,4,-4]},
 direwolf:{n:'Direwolf',role:'Skirmisher',hp:.95,atk:.95,def:.8,as:1.35,mv:88,range:22,size:14,hue:30,ab:'howl',cd:12,b:[2,-2,-4,8,2]},
 manticore:{n:'Manticore',role:'Assassin',hp:.85,atk:1.3,def:.7,as:1.1,mv:80,range:24,size:15,hue:0,ab:'venom',cd:8,b:[8,-4,-8,6,2]},
 griffin:{n:'Griffin',role:'Diver',hp:1,atk:1.12,def:.9,as:1,mv:90,range:24,size:16,hue:42,ab:'skystrike',cd:9,b:[4,0,-2,6,0]},
 kitsune:{n:'Kitsune',role:'Trickster',hp:.8,atk:1.1,def:.65,as:1.15,mv:86,range:22,size:13,hue:320,ab:'foxfire',cd:11,b:[0,-6,-6,8,6]},
 wyvern:{n:'Wyvern',role:'Ranged',hp:.85,atk:1.05,def:.7,as:.95,mv:64,range:190,size:15,hue:140,ab:'acid',cd:9,b:[4,-2,-4,2,4]},
 harpy:{n:'Harpy',role:'Ranged',hp:.75,atk:.95,def:.6,as:1.3,mv:80,range:160,size:13,hue:270,ab:'shriek',cd:10,b:[2,-4,-6,10,2]},
 phoenix:{n:'Phoenix',role:'Caster',hp:.75,atk:1,def:.6,as:.8,mv:66,range:170,size:14,hue:12,ab:'flamewave',cd:8,b:[2,-4,-6,0,10]},
 kirin:{n:'Storm Kirin',role:'Caster',hp:.8,atk:1.05,def:.65,as:.85,mv:66,range:180,size:15,hue:205,ab:'chain',cd:7,b:[0,-4,-6,2,10]},
 basilisk:{n:'Basilisk',role:'Controller',hp:1,atk:.95,def:.95,as:.85,mv:58,range:120,size:16,hue:75,ab:'gaze',cd:9,b:[0,2,4,-6,6]},
 treant:{n:'Elder Treant',role:'Support',hp:1.3,atk:.7,def:1.1,as:.7,mv:50,range:120,size:18,hue:110,ab:'rootbloom',cd:7,b:[-4,8,6,-10,4]},
 naga:{n:'Naga',role:'Support',hp:.9,atk:.85,def:.8,as:.9,mv:62,range:150,size:15,hue:175,ab:'tidal',cd:10,b:[-4,0,2,0,8]},
 unicorn:{n:'Unicorn',role:'Support',hp:.95,atk:.8,def:.85,as:.85,mv:70,range:140,size:15,hue:55,ab:'radiance',cd:10,b:[-6,0,0,4,8]}
};
Object.assign(SPECIES,{
 cerberus:{n:'Cerberus',role:'Warden',hp:1.3,atk:1,def:1.1,as:.95,mv:64,range:26,size:17,hue:350,ab:'triplebite',cd:8,b:[4,6,4,-4,-6]},
 nemean:{n:'Nemean Lion',role:'Warden',hp:1.35,atk:1.05,def:1.2,as:.95,mv:66,range:26,size:17,hue:45,ab:'prideroar',cd:10,b:[4,4,8,-4,-8]},
 yeti:{n:'Yeti',role:'Tank',hp:1.55,atk:.8,def:1.35,as:.75,mv:52,range:26,size:18,hue:200,ab:'frostroar',cd:9,b:[0,8,8,-8,-4]},
 zaratan:{n:'Zaratan',role:'Tank',hp:1.75,atk:.65,def:1.6,as:.65,mv:42,range:26,size:20,hue:80,ab:'shellup',cd:10,b:[-6,10,12,-12,0]},
 owlbear:{n:'Owlbear',role:'Bruiser',hp:1.3,atk:1.12,def:1,as:.9,mv:66,range:24,size:17,hue:30,ab:'maul',cd:8,b:[6,6,2,-4,-6]},
 hydra:{n:'Hydra',role:'Bruiser',hp:1.35,atk:1.05,def:.95,as:.9,mv:54,range:30,size:18,hue:165,ab:'regrowth',cd:11,b:[4,8,0,-6,-2]},
 chimera:{n:'Chimera',role:'Duelist',hp:1.05,atk:1.2,def:.85,as:1.05,mv:78,range:24,size:16,hue:25,ab:'threefold',cd:8,b:[8,0,-2,4,-2]},
 gargoyle:{n:'Gargoyle',role:'Diver',hp:1.1,atk:1.05,def:1.15,as:.9,mv:84,range:24,size:15,hue:260,ab:'stonedive',cd:10,b:[2,2,6,2,-4]},
 nekomata:{n:'Nekomata',role:'Assassin',hp:.8,atk:1.35,def:.65,as:1.15,mv:88,range:22,size:13,hue:280,ab:'vanish',cd:10,b:[6,-6,-8,10,4]},
 jackalope:{n:'Jackalope',role:'Skirmisher',hp:.85,atk:.95,def:.75,as:1.3,mv:98,range:20,size:12,hue:35,ab:'antlerrush',cd:8,b:[2,-4,-2,12,0]},
 cyclops:{n:'Cyclops',role:'Artillery',hp:1.2,atk:1.3,def:.9,as:.55,mv:50,range:210,size:18,hue:20,ab:'boulder',cd:10,b:[10,6,0,-10,-4]},
 thunderbird:{n:'Thunderbird',role:'Artillery',hp:.8,atk:1.05,def:.65,as:.8,mv:74,range:200,size:15,hue:215,ab:'stormcall',cd:9,b:[2,-4,-6,4,8]},
 sphinx:{n:'Sphinx',role:'Controller',hp:1.05,atk:.95,def:1,as:.8,mv:60,range:150,size:16,hue:40,ab:'riddle',cd:11,b:[-2,2,4,-4,10]},
 pegasus:{n:'Pegasus',role:'Support',hp:.9,atk:.85,def:.8,as:.9,mv:82,range:140,size:15,hue:195,ab:'tailwind',cd:11,b:[-4,0,0,8,4]},
 arachne:{n:'Arachne',role:'Summoner',hp:.85,atk:.9,def:.75,as:.9,mv:62,range:150,size:15,hue:300,ab:'brood',cd:12,b:[0,-2,0,2,8]},
 salamander:{n:'Salamander',role:'Caster',hp:.85,atk:1.05,def:.75,as:.85,mv:62,range:160,size:15,hue:15,ab:'magma',cd:9,b:[2,-2,-2,2,8]}
});
const LORE={
 minotaur:{pro:['Gore Charge stuns and hits hard from range','Sturdy health and defense'],con:['The charge needs a run-up: useless on foes already beside it','Low Instinct means long cooldowns and few crits']},
 golem:{pro:['Very high defense','Bulwark taunts whole groups off your backline'],con:['Slow, and hits softly','Magic cracks stone: takes 20% more ability damage'],q:{ab:.2}},
 troll:{pro:['Regenerates health constantly','Club Smash slows a whole cluster'],con:['Dim-witted: stuns, roots and slows last 25% longer','Soft defense for a front-liner'],q:{cc:.25}},
 wendigo:{pro:['Frenzy lifesteal sustains long fights','Strong attack for a front-liner'],con:['Thin hide for the front','Fears fire and spirit: takes 15% more ability damage'],q:{ab:.15}},
 direwolf:{pro:['Very fast attacks','Pups add bodies that soak enemy attention'],con:['Low damage per bite','Pups melt to area abilities'],},
 manticore:{pro:['Highest attack of any beast','Leaps onto the most wounded foe and poisons it'],con:['The leap often strands it deep in enemy lines','Loose hide: takes 10% more from basic attacks'],q:{atk:.1}},
 griffin:{pro:['Fast diver that stuns a backliner on landing','Well-rounded stats'],con:['Dives alone and can be isolated','Average damage for a flanker']},
 kitsune:{pro:['Illusions draw attacks away from the team','Blinks straight to the weakest backliner'],con:['Very fragile','Weak once its illusions are gone']},
 wyvern:{pro:['Long range','Acid pools punish enemies that clump'],con:['Fragile against divers','Slow to reposition when caught']},
 harpy:{pro:['Fastest attack speed at range','Shriek silences casters in a wide circle'],con:['Lowest health of the ranged beasts','Light damage per shot']},
 phoenix:{pro:['Rises once from its ashes each bout','Flame Wave keeps burning'],con:['Very low health and defense','Slow attacks between casts']},
 kirin:{pro:['Chain Lightning hits up to four foes','Short cooldown'],con:['Fragile','Needs clustered enemies for full value']},
 basilisk:{pro:['Petrifies a single threat for two seconds','Tough for a backliner'],con:['Slow mover','Modest damage']},
 treant:{pro:['Big heal plus a root on the nearest foe','Very tough for a support'],con:['Slowest support in the game','Dry bark burns: takes 20% more ability damage'],q:{ab:.2}},
 naga:{pro:['Shields the whole team at once','Good range'],con:['Low damage','Shields are wasted if the team spreads out']},
 unicorn:{pro:['Group heal that also cleanses stuns and roots','Quick on its feet'],con:['Weak attack','Short heal radius: allies must stay close']},
 cerberus:{pro:['Bites three foes at once and makes them bleed','Hard to kill'],con:['Needs to be surrounded to shine','Average speed']},
 nemean:{pro:['Takes 20% less damage from everything','Pride Roar taunts and rallies allies'],con:['Low Instinct: long cooldowns','Unremarkable damage']},
 yeti:{pro:['Mass slow plus an ice shield','Thick fur: takes 15% less ability damage'],con:['Slow, and hits softly','Clumsy: takes 10% more from basic attacks'],q:{ab:-.15,atk:.1}},
 zaratan:{pro:['Enormous health and defense','Shell Up cuts damage by 80% and taunts'],con:['Slowest beast in the arena','Barely deals damage']},
 owlbear:{pro:['Maul pins a target in place','Strong all-round bruiser'],con:['No area damage','Average defense']},
 hydra:{pro:['Bites cleave foes beside the target','Regrowth heals it when wounded'],con:['Slow','So many necks to hit: takes 10% more from basic attacks'],q:{atk:.1}},
 chimera:{pro:['Burst: three hits plus a burn','Good speed'],con:['Single-target only','Middling defense']},
 gargoyle:{pro:['Stone hide: takes 15% less from basic attacks','Hardens after every dive'],con:['Low damage for a diver','Magic cracks stone: takes 15% more ability damage'],q:{atk:-.15,ab:.15}},
 nekomata:{pro:['Untargetable while it stalks the weakest foe','Its ambush hits for 2.4 times its attack'],con:['Paper-thin','Deals no damage while hidden']},
 jackalope:{pro:['Fastest beast in the arena','Antler Rush gores a whole line'],con:['Low damage per hit','Its charge ends deep in enemy lines']},
 cyclops:{pro:['Very long range and heavy hits','Boulders stun a whole area'],con:['Slowest attack speed','One eye, easily dazed: stuns, roots and slows last 20% longer'],q:{cc:.2}},
 thunderbird:{pro:['Lightning ignores positioning and walls','Long range'],con:['Strikes land on random foes','Fragile']},
 sphinx:{pro:['Turns enemies against their own allies','Tough for a controller'],con:['Long cooldown','Low damage']},
 pegasus:{pro:['Team-wide attack and movement speed boost','Fast and mobile'],con:['No healing until it learns its Signature','Low damage']},
 arachne:{pro:['Spiderlings slow everything they bite','Summons soak attacks meant for others'],con:['Fragile','Long cooldown']},
 salamander:{pro:['Lava pools burn and slow','Good range'],con:['Fragile','Lava is wasted on spread-out enemies']}
};
['arachne','wendigo','hydra','pegasus'].forEach(k=>LORE[k].pro.push('Shines in the small 2v2 and 3v3 cups'));
['zaratan','gargoyle','kirin','yeti'].forEach(k=>LORE[k].con.push('Needs a full team: struggles in the small cups'));
Object.keys(LORE).forEach(k=>{if(SPECIES[k])SPECIES[k].q=LORE[k].q||{}});
/* Tuned by simulation: every species wins about half its bouts in an average 5v5 lineup. [health, attack] multipliers. */
const BAL={"minotaur":[1.353,1.192],"golem":[1.271,0.573],"troll":[1.228,0.849],"wendigo":[1.211,1.299],"direwolf":[0.747,0.747],"manticore":[1.103,1.685],"griffin":[1.153,1.289],"kitsune":[0.756,1.039],"wyvern":[0.785,0.971],"harpy":[0.745,0.945],"phoenix":[0.693,0.924],"kirin":[0.802,1.051],"basilisk":[1.084,1.03],"treant":[1.455,0.783],"naga":[0.993,0.941],"unicorn":[1.028,0.866],"cerberus":[1.309,1.009],"nemean":[1.145,0.891],"yeti":[1.659,0.856],"zaratan":[2.022,0.749],"owlbear":[1.411,1.218],"hydra":[1.279,0.995],"chimera":[0.867,0.99],"gargoyle":[0.985,0.939],"nekomata":[0.861,1.455],"jackalope":[1.008,1.127],"cyclops":[1.199,1.302],"thunderbird":[0.798,1.039],"sphinx":[1.06,0.958],"pegasus":[1.091,1.031],"arachne":[0.627,0.665],"salamander":[0.848,1.046]};
for(const k in BAL)if(SPECIES[k]){SPECIES[k].hp=BAL[k][0];SPECIES[k].atk=BAL[k][1]}
const SPK=Object.keys(SPECIES);
const ROLE_LINE={Warden:'front',Duelist:'flank',Artillery:'back',Summoner:'back',Tank:'front',Bruiser:'front',Skirmisher:'flank',Assassin:'flank',Diver:'flank',Trickster:'flank',Ranged:'back',Caster:'back',Support:'back',Controller:'back'};
const ABINFO={
 gore:['Gore Charge','Charges a distant foe, goring it for heavy damage and a stun.'],
 bulwark:['Bulwark','Taunts every nearby foe and raises a stone shield.'],
 smash:['Club Smash','Slams the ground around its target, damaging and slowing all there. Regenerates health constantly.'],
 hunger:['Endless Hunger','Frenzies for 5s: +30% attack and heals for half the damage dealt.'],
 howl:['Pack Howl','Summons two wolf pups that hunt the weakest foes.'],
 venom:['Tail Venom','Leaps onto the most wounded foe in reach and poisons it.'],
 skystrike:['Skystrike','Swoops onto an enemy backliner and stuns it.'],
 foxfire:['Foxfire Illusions','Conjures two decoys that draw attacks, then blinks behind enemy lines.'],
 acid:['Acid Pool','Spits a pool of acid that burns every foe standing in it.'],
 shriek:['Shriek','Silences and slows every foe close by.'],
 flamewave:['Flame Wave','Engulfs a cluster in lingering fire. Rises once from its ashes each bout.'],
 chain:['Chain Lightning','Lightning leaps between up to four foes.'],
 gaze:['Petrifying Gaze','Turns one foe to stone for two seconds.'],
 rootbloom:['Rootbloom','Heals the most wounded ally and roots the nearest foe.'],
 tidal:['Tidal Ward','Shields every nearby ally.'],
 radiance:['Radiant Horn','Heals nearby allies and cleanses stuns, roots, slows and poison.']
};
Object.assign(ABINFO,{
 triplebite:['Triple Bite','Bites the three closest foes at once and leaves them bleeding.'],
 prideroar:['Pride Roar','Taunts nearby foes and rallies nearby allies with +15% attack. Its hide shrugs off 20% of all damage.'],
 frostroar:['Frost Roar','Chills every foe nearby, slowing them hard, and grows a shield of ice.'],
 shellup:['Shell Up','Taunts close foes and withdraws into its shell, taking 80% less damage for 3 seconds.'],
 maul:['Maul','Pounces on its target, pinning it in place while it claws.'],
 regrowth:['Regrowth','When wounded, regrows a quarter of its health and bites harder. Its heads cleave foes beside the target.'],
 threefold:['Threefold Strike','Lion, goat and serpent strike at once: three rapid hits and a burn.'],
 stonedive:['Stone Dive','Plummets onto the enemy backline, crushing all around it, then hardens to stone.'],
 vanish:['Vanish','Slips into shadow, untargetable for 1.5 seconds, then ambushes the weakest foe.'],
 antlerrush:['Antler Rush','Charges through the enemy line, goring everything in its path.'],
 boulder:['Boulder Toss','Hurls a boulder that crushes and stuns everything where it lands.'],
 stormcall:['Storm Call','Calls lightning down on three random foes.'],
 riddle:['Riddle of Ruin','Confounds a foe so it turns on its own allies for 2.5 seconds.'],
 tailwind:['Tailwind','Nearby allies gain 30% attack and movement speed for 5 seconds.'],
 brood:['Brood','Summons three spiderlings whose bites slow.'],
 magma:['Magma Burst','Erupts a pool of lava that burns and slows foes standing in it.']
});
const AOE=new Set(['bulwark','smash','acid','shriek','flamewave','chain','triplebite','frostroar','boulder','magma']);
const TRAITS={
 'Bloodthirsty':'+12% attack for 6s after a takedown.',
 'Thick Hide':'+15% defense.',
 'Swift':'+12% movement and attack speed.',
 'Clutch':'+25% damage while below 35% health.',
 'Iron Lungs':'Spends 30% less energy per bout.',
 'Quick Study':'+25% experience.',
 'Showboat':'+6% crit chance. Each takedown earns the club renown.',
 'Stalwart':'Stuns and roots on it last 40% shorter.',
 'Hot-Blooded':'Ability cooldown 15% shorter.',
 'Glass Bones':'-12% health, +10% attack.',
 'Lazy':'-20% experience.',
 'Late Bloomer':'Grows 30% faster from its third season on.',
 'Pack Soul':'Builds bonds with partners twice as fast.'
};
const NEG_TRAITS=new Set(['Glass Bones','Lazy']);
const SKILLS={
 claws:{n:'Sharpened Claws',br:'off',max:3,d:r=>`+${6*r}% attack`,m:r=>({atk:.06*r})},
 instinct:{n:'Killer Instinct',br:'off',max:3,d:r=>`+${5*r}% crit chance`,m:r=>({crit:.05*r})},
 frenzy:{n:'Frenzy',br:'off',max:3,d:r=>`+${6*r}% attack speed`,m:r=>({as:.06*r})},
 exec:{n:'Executioner',br:'off',max:3,req:3,d:r=>`+${12*r}% damage to foes below 35% health`,m:r=>({exec:.12*r})},
 breaker:{n:'Armor Breaker',br:'off',max:3,req:3,d:r=>`Ignores ${10*r}% of the target's defense`,m:r=>({pen:.1*r})},
 coat:{n:'Thick Coat',br:'def',max:3,d:r=>`+${7*r}% health`,m:r=>({hp:.07*r})},
 scales:{n:'Iron Scales',br:'def',max:3,d:r=>`+${8*r}% defense`,m:r=>({def:.08*r})},
 fleet:{n:'Fleet-footed',br:'def',max:3,d:r=>`+${7*r}% movement speed`,m:r=>({mv:.07*r})},
 wind:{n:'Second Wind',br:'def',max:3,req:3,d:r=>`Once per bout, heals ${10*r}% health on dropping below 30%`,m:r=>({wind:.1*r})},
 unshake:{n:'Unshakable',br:'def',max:3,req:3,d:r=>`Stuns, roots and slows on it last ${15*r}% shorter`,m:r=>({cc:.15*r})},
 empower:{n:'Empowered',br:'abl',max:3,d:r=>`+${10*r}% ability power`,m:r=>({ap:.1*r})},
 quicken:{n:'Quickened',br:'abl',max:3,d:r=>`${7*r}% shorter ability cooldown`,m:r=>({cd:.07*r})},
 opening:{n:'Opening Move',br:'abl',max:3,d:r=>`Ability starts each bout ${25*r}% more charged`,m:r=>({open:.25*r})},
 sig:{n:'Signature',br:'abl',max:1,req:5,d:()=>'',m:()=>({sig:1})}
};
const BRANCH={off:'Offense',def:'Defense',abl:'Ability'};
const SIG={gore:['Trample','Gore Charge also tramples every foe near the target.'],bulwark:['Stone Skin','Bulwark raises a shield twice as strong.'],smash:['Aftershock','Club Smash also stuns everything it hits.'],hunger:['Gorge','Endless Hunger lasts 8 seconds instead of 5.'],howl:['Alpha Call','Pack Howl summons three pups.'],venom:['Deathstalker','Tail Venom deals double damage to foes below half health.'],skystrike:['Talon Dive','Skystrike stuns for 1.5 seconds.'],foxfire:['Nine Tails','Foxfire conjures three illusions.'],acid:['Corrosion','Acid Pool spreads wider and lasts longer.'],shriek:['Banshee Wail','Shriek reaches farther and silences for 3 seconds.'],flamewave:['Inferno','Flame Wave burns twice as hot.'],chain:['Storm Surge','Chain Lightning jumps to six foes and never weakens.'],gaze:['Medusa','Petrifying Gaze also petrifies a second foe nearby.'],rootbloom:['Overgrowth','Rootbloom roots every foe around its victim.'],tidal:['Riptide','Tidal Ward shields are 60% stronger.'],radiance:['Sanctuary','Radiant Horn heals 50% more.']};
Object.assign(SIG,{triplebite:['Hellhound','Each bite heals Cerberus for 8% of its health.'],prideroar:['King of Beasts','Pride Roar rallies allies with +30% attack.'],frostroar:['Deep Freeze','Frost Roar freezes foes solid for a moment.'],shellup:['Ancient Shell','Heals 20% health on withdrawing.'],maul:['Bear Hug','Maul pins for longer and claws twice.'],regrowth:['Two for One','Regrowth heals 40% instead of 25%.'],threefold:['Fivefold Strike','Strikes five times instead of three.'],stonedive:['Shatterfall','Stone Dive stuns everything it lands on.'],vanish:['Nine Lives','Ambushes also leave the victim bleeding.'],antlerrush:['Trample Run','Antler Rush also slows everything it hits.'],boulder:['Avalanche','Hurls a second boulder at another foe.'],stormcall:['Tempest','Calls five strikes that briefly stun.'],riddle:['Enigma','Confounds a second foe nearby.'],tailwind:['Gale Wings','Tailwind also cleanses and heals allies.'],brood:['Broodmother','Summons five spiderlings.'],magma:['Caldera','Magma pools are wider and burn 50% hotter.']});
const PTIER=[null,{n:'Common',c:'#a9b3a0'},{n:'Rare',c:'#6fa8e8'},{n:'Epic',c:'#b77fe0'},{n:'Legendary',c:'#f0b93a'}];
const PERKS={
 claws:{n:'Sharpened Claws',t:1,max:3,d:'+6% attack',m:{atk:.06}},
 hide:{n:'Tough Hide',t:1,max:3,d:'+7% health',m:{hp:.07}},
 scales:{n:'Iron Scales',t:1,max:3,d:'+8% defense',m:{def:.08}},
 reflex:{n:'Quick Reflexes',t:1,max:3,d:'+6% attack speed',m:{as:.06}},
 fleet:{n:'Fleet-footed',t:1,max:3,d:'+7% movement speed',m:{mv:.07}},
 keen:{n:'Keen Eye',t:1,max:3,d:'+4% crit chance',m:{crit:.04}},
 focus:{n:'Focused Mind',t:1,max:3,d:'+8% ability power',m:{ap:.08}},
 recovery:{n:'Swift Recovery',t:1,max:3,d:'6% shorter ability cooldown',m:{cd:.06}},
 stamina:{n:'Stamina Training',t:1,max:2,d:'15% less energy and fatigue per bout',m:{energy:.15}},
 bleed:{n:'Bloodletter',t:2,max:1,d:'Basic attacks make the target bleed for 3 seconds',m:{bleed:.12}},
 executioner:{n:'Executioner',t:2,max:2,d:'+18% damage to foes below 35% health',m:{exec:.18}},
 breaker:{n:'Armor Breaker',t:2,max:2,d:"Ignores 15% of the target's defense",m:{pen:.15}},
 wind:{n:'Second Wind',t:2,max:2,d:'Once per bout, heals 15% health on dropping below 30%',m:{wind:.15}},
 unshake:{n:'Unshakable',t:2,max:2,d:'Stuns, roots and slows on it last 20% shorter',m:{cc:.2}},
 opening:{n:'Opening Move',t:2,max:2,d:'Ability starts each bout 35% more charged',m:{open:.35}},
 thorns:{n:'Thorned Hide',t:2,max:2,d:'Reflects 15% of melee damage taken back at the attacker',m:{thorns:.15}},
 fangs:{n:'Vampiric Fangs',t:2,max:2,d:'Heals for 8% of the damage it deals',m:{ls:.08}},
 hardened:{n:'Battle Hardened',t:2,max:2,d:'+10% health and +6% defense',m:{hp:.1,def:.06}},
 rally:{n:'Rallying Presence',t:2,max:1,d:'Every ally in the bout gains +4% attack',m:{rally:.04}},
 berserk:{n:'Berserker',t:3,max:1,d:'Gains up to +30% attack as its health drops',m:{berserk:1}},
 twin:{n:'Twin Strike',t:3,max:1,d:'20% chance to attack twice',m:{double:.2}},
 echo:{n:'Echo',t:3,max:1,d:'25% chance its ability recharges almost instantly',m:{echo:.25}},
 sig:{n:'Signature',t:3,max:1,d:'',m:{sig:1}},
 ironwill:{n:'Iron Will',t:3,max:1,d:'Shrugs off the first stun of every bout',m:{stunImm:1}},
 juggernaut:{n:'Juggernaut',t:3,max:1,d:'+18% health and cannot be slowed',m:{hp:.18,noslow:1}},
 mark:{n:"Assassin's Mark",t:3,max:1,d:'+6% crit chance, and critical hits deal 40% more',m:{crit:.06,critDmg:.4}},
 surge:{n:'Arcane Surge',t:3,max:1,d:'+22% ability power and 10% shorter cooldown',m:{ap:.22,cd:.1}},
 undying:{n:'Undying',t:4,max:1,d:'Once per bout, survives a killing blow and gains a shield',m:{undying:1}},
 apex:{n:'Apex Predator',t:4,max:1,d:'Each takedown recharges its ability and heals 15% health',m:{apex:1}},
 colossus:{n:'Colossus',t:4,max:1,d:'+30% health and +15% defense',m:{hp:.3,def:.15}},
 blades:{n:'Storm of Blades',t:4,max:1,d:'Melee attacks also hit foes beside the target for 40%',m:{cleave:.4}},
 chrono:{n:'Chronomancer',t:4,max:1,d:'30% shorter ability cooldown and +10% ability power',m:{cd:.3,ap:.1}}
};
function tierW(b){return[60-b.pot*3,26+b.pot,9+b.pot*1.4,1.5+b.pot*.6]}
function rollOffer(b){b.perks=b.perks||{};const w=tierW(b),pk=b.perks,melee=SPECIES[b.sp].range<60,ok=k=>(pk[k]||0)<PERKS[k].max&&!(k==='blades'&&!melee),out=[];let g=0;while(out.length<3&&g++<60){const t=wpick([1,2,3,4],w),pool=Object.keys(PERKS).filter(k=>PERKS[k].t===t&&ok(k)&&!out.includes(k));if(pool.length)out.push(pick(pool))}b.offer=out.length?out:null;b.rerolls=0}
function takePerk(b,k){if(!b.offer||!b.offer.includes(k))return false;b.perks[k]=(b.perks[k]||0)+1;b.rolls=Math.max(0,(b.rolls||0)-1);b.offer=null;if(b.rolls>0)rollOffer(b);return true}
function autoPick(b){b.perks=b.perks||{};let g=0;while((b.rolls||0)>0&&g++<60){if(!b.offer)rollOffer(b);if(!b.offer){b.rolls=0;break}const best=b.offer.slice().sort((x,y)=>PERKS[y].t-PERKS[x].t)[0];takePerk(b,best)}}
function perkName(b,k){return k==='sig'?`Signature: ${SIG[SPECIES[b.sp].ab][0]}`:PERKS[k].n}
function perkDesc(b,k){return k==='sig'?SIG[SPECIES[b.sp].ab][1]:PERKS[k].d}
function rerollCost(b){return 25*((b.rerolls||0)+1)}
const PRESETS={
 brawler:{n:'Brawler',d:'Wades in and uses its ability the moment it can.',t:{stance:'advance',target:'nearest',ability:'eager',retreatAt:0,kite:false}},
 hunter:{n:'Hunter',d:'Skips the front line and goes for the backline.',t:{stance:'advance',target:'backline',ability:'eager',retreatAt:0}},
 guardian:{n:'Bodyguard',d:'Stays beside a chosen ally and punishes whoever attacks it.',t:{stance:'guard',target:'nearest',ability:'clutch',retreatAt:0}},
 sniper:{n:'Sniper',d:'Holds its ground at range, keeps distance and shoots the biggest threat.',t:{stance:'hold',target:'threat',ability:'group',kite:true,retreatAt:25}},
 cautious:{n:'Cautious',d:'Keeps distance, saves its ability and falls back early.',t:{stance:'advance',ability:'clutch',kite:true,retreatAt:40}}
};
const CASTS=[
 {id:'storm',n:'Storm & Shadow',d:'A lightning caster freecasts behind a stone wall while shadow cats wreck the enemy backline. Stop one and the other spirals.',m:[['kirin',{stance:'hold'}],['nekomata',{target:'casters'}],['golem',{stance:'guard',partner:0}],['kitsune',{target:'casters'}],['thunderbird',{stance:'hold'}],['unicorn',{ability:'clutch',stance:'guard',partner:0}],['direwolf'],['salamander']]},
 {id:'hunt',n:'The Wild Hunt',d:'All teeth and claws. Bruisers and divers overrun the enemy before their casters get going.',m:[['minotaur'],['owlbear'],['chimera',{target:'weakest'}],['griffin',{target:'backline'}],['manticore'],['hydra'],['harpy',{stance:'assist',partner:0}],['jackalope']]},
 {id:'wall',n:'The Iron Wall',d:'Outlast everyone. Heavy fronts, healers and control. Slow to win, very hard to beat.',m:[['zaratan',{stance:'guard',partner:4}],['nemean'],['cerberus'],['basilisk',{stance:'hold'}],['naga',{ability:'clutch'}],['treant',{ability:'clutch'}],['cyclops',{stance:'hold'}],['yeti']]},
 {id:'tricks',n:'Menagerie of Tricks',d:'Confusion, summons and crowd control. Enemies fight each other and never quite reach you.',m:[['sphinx',{stance:'hold'}],['arachne'],['troll',{stance:'guard',partner:0}],['pegasus'],['wyvern',{stance:'hold'}],['gargoyle'],['wendigo'],['phoenix']]}
];
const CREST_HUES=[38,0,210,140,280,20,180,330];
const SLOTS={claw:'Claws & horns',armor:'Barding',charm:'Charm'};
const ITEMS={
 capsIron:{n:'Iron Claw Caps',slot:'claw',price:60,tier:0,m:{atk:.06}},
 fangGuard:{n:'Serrated Fang Guards',slot:'claw',price:140,tier:0,m:{atk:.1,crit:.03}},
 hornStorm:{n:'Stormglass Horn Cap',slot:'claw',price:220,tier:1,m:{ap:.12,cd:.08}},
 obsidian:{n:'Obsidian Talons',slot:'claw',price:340,tier:2,m:{atk:.15,pen:.12}},
 wyrmfang:{n:'Wyrmfang Blades',slot:'claw',price:560,tier:3,m:{atk:.2,crit:.06,exec:.15}},
 leather:{n:'Leather Barding',slot:'armor',price:60,tier:0,m:{hp:.08}},
 scale:{n:'Scale Barding',slot:'armor',price:150,tier:0,m:{def:.12,hp:.06}},
 wardweave:{n:'Wardweave Silk',slot:'armor',price:240,tier:1,m:{hp:.08,cc:.25}},
 trollhide:{n:'Troll-hide Mantle',slot:'armor',price:340,tier:2,m:{hp:.15,regen:.005}},
 dragonplate:{n:'Dragonscale Plate',slot:'armor',price:560,tier:3,m:{hp:.15,def:.18}},
 knuckle:{n:'Lucky Knucklebone',slot:'charm',price:70,tier:0,m:{crit:.05}},
 totem:{n:"Hunter's Totem",slot:'charm',price:120,tier:0,m:{mv:.08,as:.06}},
 bell:{n:'Stamina Bell',slot:'charm',price:150,tier:0,m:{energy:.35}},
 seal:{n:"Scholar's Seal",slot:'charm',price:160,tier:1,m:{xp:.25}},
 ribbon:{n:'Bond Ribbon',slot:'charm',price:180,tier:1,m:{bond:1}},
 ember:{n:'Ember Feather',slot:'charm',price:300,tier:2,m:{shield:.15,ap:.06}},
 sunstone:{n:'Sunstone Heart',slot:'charm',price:520,tier:3,m:{hp:.08,atk:.08,ap:.08}}
};
const CONS={
 tonic:{n:'Restorative Tonic',price:30,d:'Restores 40 energy.'},
 salt:{n:'Mineral Salt Lick',price:45,d:'Removes 30 fatigue.'},
 poultice:{n:'Bone-knit Poultice',price:80,d:'Heals an injury at once.'},
 manual:{n:'Training Manual',price:90,d:'Grants 150 experience.'},
 tome:{n:'Tome of Forgetting',price:120,d:'Clears every learned skill and gives the picks back to choose again.'},
 dice:{n:'Loaded Dice',price:40,d:'Rerolls the skill cards on offer for free.'}
};
const MOD_N={atk:'attack',hp:'health',def:'defense',as:'attack speed',mv:'movement speed',crit:'crit chance',ap:'ability power',pen:'armor pierce',exec:'damage to wounded foes',cc:'shorter stuns and roots',xp:'experience',shield:'health as a shield at bout start'};
function modText(m){return Object.entries(m).map(([k,v])=>k==='bond'?'Bond bonuses count double':k==='energy'?`${Math.round(v*100)}% less energy and fatigue per bout`:k==='cd'?`${Math.round(v*100)}% shorter ability cooldown`:k==='regen'?`Regenerates ${(v*100).toFixed(1)}% health per second`:`+${Math.round(v*100)}% ${MOD_N[k]}`).join(' · ')}
const TAC_OPTS={
 target:[['nearest','Nearest foe'],['weakest','Finish the weak'],['backline','Dive the backline'],['casters','Hunt healers & casters'],['threat','Biggest threat']],
 pos:[['front','Frontline'],['flank','Flank'],['back','Backline']],
 ability:[['eager','Use on cooldown'],['group','Wait for clusters'],['clutch','Save for emergencies']],
 stance:[['advance','Advance'],['hold','Hold ground'],['guard','Bodyguard an ally'],['assist','Focus with an ally']],
 retreatAt:[['0','Never fall back'],['25','Fall back at 25%'],['40','Fall back at 40%']]
};
const TAC_HELP={
 target:{nearest:'Engages whatever is closest. Steady, easy to predict.',weakest:'Picks off low-health foes. Good for finishing blows.',backline:'Ignores the front and goes for ranged and casters.',casters:'Chases healers, casters and controllers specifically.',threat:'Targets whichever foe has done the most damage.'},
 pos:{front:'Starts in the front rank.',flank:'Starts wide on the wings.',back:'Starts behind the front rank.'},
 ability:{eager:'Fires the ability as soon as it is ready.',group:'Area abilities wait until two or more foes are caught.',clutch:'Holds the ability until someone is badly hurt.'},
 stance:{advance:'Moves in on its target.',hold:'Stays near its starting spot and fights whatever comes close.',guard:'Sticks beside its partner and attacks whatever threatens it.',assist:'Attacks whatever its partner is attacking.'},
 retreatAt:{0:'Fights to the end.',25:'Backs away from the nearest foe when below 25% health.',40:'Backs away from the nearest foe when below 40% health.'}
};
const DEF_TAC={Warden:['nearest','front','group'],Duelist:['threat','flank','eager'],Artillery:['nearest','back','group'],Summoner:['nearest','back','eager'],Tank:['nearest','front','group'],Bruiser:['nearest','front','eager'],Skirmisher:['weakest','flank','eager'],Assassin:['backline','flank','eager'],Diver:['backline','flank','eager'],Trickster:['casters','flank','eager'],Ranged:['nearest','back','group'],Caster:['nearest','back','group'],Support:['nearest','back','clutch'],Controller:['threat','back','eager']};
const FOCUS={Balanced:null,Power:'pow',Vitality:'vit',Guard:'grd',Agility:'agi',Instinct:'ins'};
const NAMES=['Ashfang','Brannoc','Cinder','Dulcet','Ember','Fenwick','Grisk','Halvard','Ivo','Jorra','Kestrel','Lumen','Moloch','Nyx','Oro','Pell','Quill','Rook','Saffi','Tamsin','Ulric','Vesper','Wick','Yara','Zeph','Bramble','Cato','Dagny','Esker','Fable','Gorse','Hobb','Isolde','Juniper','Korrin','Lark','Marrow','Nettle','Onyx','Pike','Rune','Sable','Thistle','Umber','Vex','Wren','Ysolde','Zorn','Barnaby','Cobalt','Draven','Elowen','Ferro','Gideon','Hester','Inka','Jasper','Kodiak','Lysander','Mab','Nimue','Ottilie','Percival','Rhiannon','Silas','Tobias','Una','Valko','Wystan','Xanthe','Bastian','Corvin','Delphine','Eamon','Faye','Grimsby','Hawthorn','Ignatius','Juno','Kaspar','Leopold','Mordecai','Nell','Orrin','Pip','Rosalind','Sorrel','Tibalt','Varga','Wilder','Agnar','Bexley','Caspian','Dorn','Edda','Fitch','Gunnar','Hollis','Ingrid','Jax'];
const CLUB_NAMES=['Ironhorn Pit','Saltmarsh Wyrms','The Ember Court','Hollowmoor Pack','Gilded Talons','Mirefang Collective','Thornwall Keepers','Obsidian Menagerie','Duskridge Rovers','Cinder Vale Beasts','Frostgate Howlers','Brackwater Coil','Sunspire Aerie','Gravelmouth Brutes','Vellum Street Stable','Old Quarry Maulers','Ravenscar Circus','Tidecaller Pens','Blackbriar Hunt','Copperkiln Claws','Lanternfen Guild','Highmoor Chimeras','Stormhollow Kennel','Redmarrow Brood','Glasswater Keep','Wolfsbane Society'];
const EPITHETS=['the Relentless','Bonebreaker','the Unbowed','Stormcaller','the Red','Nightstalker','the Patient','Ironjaw','the Wild','Ashborn','the Undying','Grimhowl','the Quiet','Skyrender','Kingslayer','the Wall'];
const PAT=['L','L','L','C2','L','L','L','L','D','L','L','L','C3','L','L','L','L'];
const CUPN={2:'Twin Fangs Cup',3:'Trident Cup',5:'Wildcard Draft Cup'};
const RNAME=['Quarterfinal','Semifinal','Final'];
const EMB={
 Tank:'M-6-6h12v4c0 5-3 8-6 9-3-1-6-4-6-9z',
 Bruiser:'M-6-6L6 6M6-6L-6 6',
 Skirmisher:'M-7-5l5 5-5 5M0-5l5 5-5 5',
 Assassin:'M0-8L3 3h-6zM0 3v5',
 Diver:'M-8-3L0 5 8-3M0-7v12',
 Trickster:'M-6 0a6 6 0 1 0 12 0a6 6 0 1 0-12 0M-1.5 0a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0-3 0',
 Ranged:'M-7 7L6-6M6-6h-5M6-6v5',
 Caster:'M0-8L2-2 8 0 2 2 0 8-2 2-8 0-2-2z',
 Support:'M0-7v14M-7 0h14',
 Controller:'M-8 0q8-8 16 0q-8 8-16 0zM-2 0a2 2 0 1 0 4 0a2 2 0 1 0-4 0',
 Pup:'M-7-5l5 5-5 5M0-5l5 5-5 5'
};

/* ============ UTIL ============ */
const $=s=>document.querySelector(s);
const rnd=(a,b)=>a+Math.random()*(b-a);
const ri=(a,b)=>Math.floor(rnd(a,b+1));
const pick=a=>a[Math.floor(Math.random()*a.length)];
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const shuffle=a=>{for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]]}return a};
const esc=s=>String(s==null?'':s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const fmt=n=>Math.round(n).toLocaleString('en-US');
function wpick(items,w){let s=w.reduce((a,b)=>a+b,0),r=Math.random()*s;for(let i=0;i<items.length;i++){r-=w[i];if(r<=0)return items[i]}return items[items.length-1]}

/* ============ STATE ============ */
let G=null;
const UI={intro:{name:'Ravenmoor Menagerie',hue:38,cast:'storm',rand:null},tab:'club',mode:'hub',ctx:null,sel:[],result:null,lead:'imp',round:null,modal:null,rsort:'ovr'};
const SAVE_KEY='beastbound-save-v1';
function save(){try{localStorage.setItem(SAVE_KEY,JSON.stringify(G))}catch(e){}}
function migrate(g){if(g.v===1){Object.values(g.beasts).forEach(b=>{b.skills=b.skills||{};b.skp=b.skp!=null?b.skp:Math.max(0,b.lvl-1);b.gear=b.gear||{claw:null,armor:null,charm:null};b.fat=b.fat||0;b.inj=b.inj||0;b.awaken=b.awaken||[];if(b.clubId!=='P'&&b.clubId!=='MKT')autoSpend(b)});g.stash=[];g.cons={};g.ledger=[];g.v=2}if(g.v===2){const MAP={claws:'claws',instinct:'keen',frenzy:'reflex',exec:'executioner',breaker:'breaker',coat:'hide',scales:'scales',fleet:'fleet',wind:'wind',unshake:'unshake',empower:'focus',quicken:'recovery',opening:'opening',sig:'sig'};Object.values(g.beasts).forEach(b=>{b.perks={};for(const k in (b.skills||{})){const pk=MAP[k];if(pk&&b.skills[k])b.perks[pk]=Math.min(PERKS[pk].max,(b.perks[pk]||0)+b.skills[k])}b.skills={};b.rolls=b.skp||0;b.skp=0;b.offer=null;const t=b.tactics;t.retreatAt=t.retreat?25:(t.retreatAt||0);t.stance=t.stance||'advance';t.partner=t.partner||null;if(b.clubId!=='P'&&b.clubId!=='MKT')autoPick(b)});g.v=3}return g}
function load(){try{const s=localStorage.getItem(SAVE_KEY);if(s){const g=JSON.parse(s);if(g&&(g.v>=1&&g.v<=3))return migrate(g)}}catch(e){}return null}
function ledger(label,amt){if(!amt)return;G.ledger.unshift({s:G.season,d:Math.min(G.day+1,PAT.length),label,amt});if(G.ledger.length>40)G.ledger.length=40}
function news(text,kind){G.news.unshift({s:G.season,d:Math.min(G.day+1,PAT.length),text,kind:kind||''});if(G.news.length>90)G.news.length=90}

function blankStats(){return{m:0,w:0,k:0,d:0,a:0,dmg:0,tank:0,heal:0,cc:0,imp:0,bestK:0,bestDmg:0}}
function defTac(role){const d=DEF_TAC[role];return{target:d[0],pos:d[1],ability:d[2],stance:'advance',partner:null,retreatAt:0,kite:ROLE_LINE[role]==='back'}}
function newName(){const used=new Set(Object.values(G.beasts).map(b=>b.name));for(let i=0;i<40;i++){const n=pick(NAMES);if(!used.has(n))return n}return pick(NAMES)+' '+pick(['II','III','the Younger'])}
function genBeast(q,o={}){
 const sp=o.sp||pick(SPK),D=SPECIES[sp],young=!!o.prospect;
 const age=o.age!=null?o.age:young?ri(0,1):ri(1,6);
 const pot=young?wpick([1,2,3,4,5],[3,12,30,33,22]):wpick([1,2,3,4,5],[14,30,30,18,8]);
 const base=q+(young?-10:0)+rnd(-5,6)+Math.min(age,5)*.8;
 const attrs={};ATTR.forEach((k,i)=>attrs[k]=Math.round(clamp(base+D.b[i]+rnd(-7,7),8,99)));
 const tk=Object.keys(TRAITS),traits=[];
 if(Math.random()<.8)traits.push(pick(tk));
 if(Math.random()<.25){const t2=pick(tk);if(!traits.includes(t2))traits.push(t2)}
 const b={id:'b'+(G.nid++),name:o.name||newName(),sp,age,pot,pj:ri(-1,1),lvl:young?1:clamp(ri(1,3)+age,1,10+pot*4),xp:0,skills:{},skp:0,perks:{},rolls:0,offer:null,gear:{claw:null,armor:null,charm:null},fat:0,inj:0,awaken:[],attrs,traits,energy:100,focus:'Balanced',tactics:defTac(D.role),season:blankStats(),career:blankStats(),form:[],notes:[],titles:[],epithet:'',clubId:o.clubId||null,draft:!!o.draft,joined:o.joined||'',peak:0,seasons:0};
 b.peak=ovr(b);b.rolls=b.lvl-1;if(b.clubId!=='P'&&b.clubId!=='MKT')autoPick(b);
 G.beasts[b.id]=b;return b;
}
function lineSpecies(line){return SPK.filter(s=>ROLE_LINE[SPECIES[s].role]===line)}
function rosterPlan(){return[pick(lineSpecies('front')),pick(lineSpecies('front')),pick(lineSpecies('flank')),pick(lineSpecies('flank')),pick(lineSpecies('back')),pick(lineSpecies('back')),pick(lineSpecies('back')),pick(SPK)]}
function makeAIClub(tier){
 const used=new Set(Object.values(G.clubs).map(c=>c.name));
 const name=pick(CLUB_NAMES.filter(n=>!used.has(n)))||('Club '+G.nid);
 const id='c'+(G.nid++);
 const c={id,name,hue:ri(0,359),roster:[],str:rnd(-5,4)};G.clubs[id]=c;
 rosterPlan().forEach((sp,i)=>{const b=genBeast(TIERS[tier].q+c.str,{sp,clubId:id,prospect:i===7&&Math.random()<.5});b.joined=name;aiGear(b,tier);c.roster.push(b.id)});
 if(Math.random()<.5){const bs=c.roster.map(i=>G.beasts[i]),fr=bs.find(b=>ROLE_LINE[roleOf(b)]==='front'),bk=bs.find(b=>ROLE_LINE[roleOf(b)]==='back');if(fr&&bk){fr.tactics.stance='guard';fr.tactics.partner=bk.id}}
 if(Math.random()<.4){const bk=c.roster.map(i=>G.beasts[i]).find(b=>['Ranged','Artillery','Caster'].includes(roleOf(b)));if(bk){bk.tactics.stance='hold'}}
 return id;
}
function newGame(name,members,hue){
 G={v:3,stash:[],cons:{},ledger:[],name:name||'Ravenmoor Menagerie',gold:350,renown:0,tier:0,season:1,day:0,nid:1,beasts:{},clubs:{},div:[],lineups:{5:[],3:[],2:[]},news:[],bonds:{},trophies:[],history:[],records:{},alumni:[],market:[],league:null,cup:null,draft:null,streak:0,bestStreak:0,cupLog:[],sched:[]};
 const pc={id:'P',name:G.name,hue:hue!=null?hue:38,roster:[],player:true};G.clubs.P=pc;
 members=members||randomCast();
 const ids=members.map(([sp],i)=>{const b=genBeast(TIERS[0].q+1,{sp,clubId:'P',prospect:i===7,joined:'Founding member, Season 1'});pc.roster.push(b.id);return b.id});
 members.forEach(([sp,t],i)=>{if(!t)return;const b=G.beasts[ids[i]];Object.assign(b.tactics,t);b.tactics.partner=t.partner!=null?ids[t.partner]:null});
 ids.forEach(id=>{const b=G.beasts[id];if(b.rolls>0)rollOffer(b)});
 G.div=['P'];for(let i=0;i<7;i++)G.div.push(makeAIClub(0));
 startSeason();
 news('The club opens its gates. Eight beasts, one arena, and no reputation yet.','season');
}
function startSeason(){
 G.div.forEach(cid=>G.clubs[cid].roster.forEach(id=>{const b=G.beasts[id];if(b){b.season=blankStats();b.energy=100;b.fat=0;b.inj=0;b._played=false}}));
 G.league={fix:roundRobin(G.div),res:[]};
 let r=0;G.sched=PAT.map(p=>p==='L'?{t:'league',r:r++}:p==='D'?{t:'draft'}:{t:'cup',fmt:+p[1]});
 G.day=0;G.cupLog=[];G.cup=null;G.draft=null;
 refreshMarket(true);
 news(`Season ${G.season} opens in the ${TIERS[G.tier].n}.`,'season');
}
function randomCast(){const used=new Set(),pu=l=>{const pool=(l?lineSpecies(l):SPK).filter(x=>!used.has(x)),x=pick(pool);used.add(x);return x};return['front','front','flank','flank','back','back','back',null].map(l=>[pu(l)])}
function castMembers(){const I=UI.intro;if(I.cast==='random'){if(!I.rand)I.rand=randomCast();return I.rand}return CASTS.find(c=>c.id===I.cast).m}
function roundRobin(ids){const t=shuffle([...ids]),n=t.length,rounds=[];for(let r=0;r<n-1;r++){const pr=[];for(let i=0;i<n/2;i++){const a=t[i],b=t[n-1-i];pr.push(r%2?[b,a]:[a,b])}rounds.push(pr);t.splice(1,0,t.pop())}return rounds.concat(rounds.map(p=>p.map(([a,b])=>[b,a])))}

/* ============ DERIVED ============ */
function ovr(b){return Math.round(ATTR.reduce((s,k)=>s+b.attrs[k],0)/5)}
function xpNeed(l){return 80+l*40}
function lvlCap(b){return 10+b.pot*4}
function energyFactor(e){return e>=50?1:1-(50-e)/50*.25}
function value(b){const o=ovr(b);const af=b.age<=1?1.1:b.age>=8?.5:b.age>=6?.8:1;return Math.max(20,Math.round(o*o/9*(.65+b.pot*.12)*af/5)*5)}
function sellPrice(b){return Math.round(value(b)*.6/5)*5}
function upkeep(b){return 2+Math.floor(ovr(b)/20)}
function playerUpkeep(){return G.clubs.P.roster.reduce((s,id)=>s+upkeep(G.beasts[id]),0)}
function ageLabel(a){return a<=1?'Whelp':a<=5?'Prime':a<=7?'Seasoned':'Elder'}
function potRange(b){const w=Math.max(0,2-Math.floor(b.career.m/6));let lo,hi;if(w===2){lo=b.pot-1+b.pj;hi=b.pot+1+b.pj}else if(w===1){lo=b.pj>=0?b.pot:b.pot-1;hi=lo+1}else{lo=hi=b.pot}lo=clamp(lo,1,5);hi=clamp(hi,1,5);return lo===hi?`${lo}★`:`${lo}–${hi}★`}
function roleOf(b){return SPECIES[b.sp].role}
function bkey(a,b){return a<b?a+'|'+b:b+'|'+a}
function bondLvl(a,b){const x=G.bonds[bkey(a,b)];if(!x)return 0;return x.w>=15?3:x.w>=8?2:x.w>=3?1:0}
const BOND_N=['','Familiar','Trusted','Blood-sworn'];
function impactOf(st){return st.dmg/60+st.tank/150+st.heal/45+st.k*4+st.a*2+st.cc*2.5-st.d*1.5}
function combatStats(b){
 const D=SPECIES[b.sp],a=b.attrs,t=b.traits;
 let hp=(380+a.vit*9)*D.hp,atk=(14+a.pow*.55)*D.atk,def=(5+a.grd*.6)*D.def,as=D.as*(.8+a.agi/250),mv=D.mv*(.85+a.agi/400),crit=.05+a.ins/600,ap=1+a.ins/150,cdm=1-a.ins/400;
 if(t.includes('Thick Hide'))def*=1.15;
 if(t.includes('Swift')){mv*=1.12;as*=1.12}
 if(t.includes('Showboat'))crit+=.06;
 if(t.includes('Hot-Blooded'))cdm*=.85;
 if(t.includes('Glass Bones')){hp*=.88;atk*=1.1}
 const m=mods(b);
 hp*=1+(m.hp||0);atk*=1+(m.atk||0);def*=1+(m.def||0);as*=1+(m.as||0);mv*=1+(m.mv||0);crit+=m.crit||0;ap*=1+(m.ap||0);cdm*=1-Math.min(.5,m.cd||0);
 const e=b.draft?1:energyFactor(b.energy)*(b.inj>0?.7:1);
 return{hp:hp*e,atk:atk*e,def,as,mv,crit,ap,cd:D.cd*cdm,range:D.range,m};
}
function mods(b){const m={};const add=o=>{for(const k in o)m[k]=(m[k]||0)+o[k]};const sk=b.skills||{};for(const k in sk)if(sk[k]&&SKILLS[k])add(SKILLS[k].m(sk[k]));const pk=b.perks||{};for(const k in pk)if(pk[k]&&PERKS[k])for(const mk in PERKS[k].m)m[mk]=(m[mk]||0)+PERKS[k].m[mk]*pk[k];const g=b.gear||{};for(const sl in g){const it=g[sl]&&ITEMS[g[sl].key];if(it)add(it.m)}if(b.traits.includes('Stalwart'))add({cc:.4});return m}
function brPts(b,br){const sk=b.skills||{};return Object.keys(sk).reduce((s,k)=>s+(SKILLS[k]&&SKILLS[k].br===br?sk[k]:0),0)}
function canLearn(b,k){const sk=SKILLS[k],r=(b.skills||{})[k]||0;return(b.skp||0)>0&&r<sk.max&&(!sk.req||brPts(b,sk.br)>=sk.req)}
function learn(b,k){if(!canLearn(b,k))return false;b.skills[k]=(b.skills[k]||0)+1;b.skp--;return true}
function autoSpend(b){b.skills=b.skills||{};const pref={front:['def','def','off','abl'],flank:['off','off','def','abl'],back:['abl','abl','off','def']}[ROLE_LINE[roleOf(b)]];let guard=0;while((b.skp||0)>0&&guard++<80){const opts=Object.keys(SKILLS).filter(k=>canLearn(b,k));if(!opts.length)break;let k=opts.includes('sig')?'sig':null;if(!k){const br=pick(pref),o2=opts.filter(x=>SKILLS[x].br===br);k=pick(o2.length?o2:opts)}learn(b,k)}}
function offerAwaken(b){const pool=Object.keys(TRAITS).filter(t=>!NEG_TRAITS.has(t)&&!b.traits.includes(t));b.awaken=shuffle(pool).slice(0,3);if(b.clubId==='P')news(`${b.name} reached level ${b.lvl} and is ready to awaken a new trait.`,'mile')}
function aiGear(b,tier){b.gear=b.gear||{claw:null,armor:null,charm:null};Object.keys(SLOTS).forEach(sl=>{if(Math.random()<.15+tier*.22){const pool=Object.keys(ITEMS).filter(k=>ITEMS[k].slot===sl&&ITEMS[k].tier<=tier);if(pool.length)b.gear[sl]={id:'i'+(G.nid++),key:pick(pool)}}})}

/* ============ SIMULATION ============ */
const W=1280,H=740,CX=640,CY=372,RX=592,RY=330;
function dist(a,b){return Math.hypot(a.x-b.x,a.y-b.y)}
function clampArena(u){const ex=RX-u.r,ey=RY-u.r,dx=(u.x-CX)/ex,dy=(u.y-CY)/ey,d=dx*dx+dy*dy;if(d>1){const s=1/Math.sqrt(d);u.x=CX+dx*s*ex;u.y=CY+dy*s*ey}}
function freshStatus(){return{stun:0,slow:0,slowMul:1,root:0,silence:0,taunt:0,tauntBy:null,poison:0,poisonDps:0,poisonSrc:null,burn:0,burnDps:0,burnSrc:null,shield:0,shieldT:0,ls:0,lsT:0,buff:1,buffT:0,tint:'',tintT:0,pk:'',confuse:0,stealth:0,haste:1,hasteT:0,dr:0,drT:0}}
function baseUnit(S,o){const u=Object.assign({id:S.nid++,bid:null,owner:null,summon:false,lure:false,alive:true,st:{k:0,d:0,a:0,dmg:0,tank:0,heal:0,cc:0},s:freshStatus(),target:null,retT:0,atkT:rnd(0,.4),hitBy:{},rebirth:false,regen:0,dash:null,bloodT:0,traits:new Set(),face:1,animAtk:0,animCast:0,flash:0,walk:0,moved:0,ab:null,cd:99,cdT:99,crit:.05,ap:1},o);S.byId[u.id]=u;return u}
function bondBonus(list){const out={};const mine=list.every(b=>b.clubId==='P'&&!b.draft);list.forEach(b=>{let best=0;if(mine)list.forEach(o=>{if(o!==b)best=Math.max(best,bondLvl(b.id,o.id))});out[b.id]=best*.03*(1+(mods(b).bond||0))});return out}
function createSim(A,B,opts={}){
 const S={t:0,parts:[],shake:0,units:[],proj:[],zones:[],fx:[],feed:[],done:false,winner:-1,headless:!!opts.headless,nid:1,byId:{},maxT:90};
 [A,B].forEach((list,team)=>{
  const bb=bondBonus(list);
  const lines={front:[],flank:[],back:[]};
  list.forEach(b=>lines[b.tactics.pos||ROLE_LINE[roleOf(b)]].push(b));
  Object.keys(lines).forEach(line=>{const arr=lines[line];arr.forEach((b,i)=>{
   const c=combatStats(b),D=SPECIES[b.sp],bn=1+(bb[b.id]||0);
   const u=baseUnit(S,{bid:b.id,name:b.name,sp:b.sp,role:D.role,line:ROLE_LINE[D.role],team,r:D.size,hp:c.hp*bn,maxHp:c.hp*bn,atk:c.atk*bn,def:c.def,as:c.as,mv:c.mv,range:c.range,crit:c.crit,ap:c.ap,cd:c.cd,cdT:c.cd*rnd(.3,.6)*(1-Math.min(.75,c.m.open||0)),ab:D.ab,tac:Object.assign({},b.tactics),traits:new Set(b.traits),rebirth:b.sp==='phoenix',abVul:D.q.ab||0,atkVul:D.q.atk||0,ccVul:D.q.cc||0,regen:(b.sp==='troll'?.012:0)+(c.m.regen||0),hue:D.hue,bond:bb[b.id]||0,pen:Math.min(.6,c.m.pen||0),exec:c.m.exec||0,wind:c.m.wind||0,ccRed:Math.min(.7,c.m.cc||0),sig:!!c.m.sig,dr:b.sp==='nemean'?.2:0,cleave:Math.max(b.sp==='hydra'?.35:0,c.m.cleave||0),bleed:c.m.bleed||0,thorns:c.m.thorns||0,lsPerm:c.m.ls||0,berserk:!!c.m.berserk,double:c.m.double||0,echo:c.m.echo||0,stunImm:!!c.m.stunImm,noslow:!!c.m.noslow,critDmg:c.m.critDmg||0,undying:!!c.m.undying,apex:!!c.m.apex,rally:c.m.rally||0,partnerBid:b.tactics.partner||null});if(c.m.shield){u.s.shield=u.maxHp*c.m.shield;u.s.shieldT=30}
   const xo={front:150,flank:250,back:360}[line];
   u.x=team===0?CX-xo:CX+xo;u.face=team===0?1:-1;
   if(line==='flank'){u.y=CY+(i%2===0?-1:1)*(120+Math.floor(i/2)*60)}else u.y=CY+(i-(arr.length-1)/2)*76;
   clampArena(u);S.units.push(u);
  })});
 });
 S.units.forEach(u=>{u.ax=u.x;u.ay=u.y;if(u.partnerBid)u.partnerU=S.units.find(v=>v.bid===u.partnerBid&&v.team===u.team&&v!==u)||null});
 [0,1].forEach(tm=>{const r=S.units.filter(u=>u.team===tm).reduce((a,u)=>a+(u.rally||0),0);if(r)S.units.forEach(u=>{if(u.team===tm)u.atk*=1+r})});
 if(!S.headless)S.units.forEach(u=>{if(u.rally){fx(S,{k:'txt',x:u.x,y:u.y-u.r-16,s:'RALLY',c:'#f0c870',z:12,ttl:1.6});fx(S,{k:'ring',x:u.x,y:u.y,r0:u.r,r1:90,c:'#f0c870',ttl:.9})}});
 return S;
}
function atkHit(S,u,t,raw){hit(S,u,t,raw);if(u.bleed&&t.alive){poison(S,u,t,u.atk*u.bleed,3);t.s.pk='bleed'}}
function burst(S,x,y,n,o){if(S.headless)return;for(let i=0;i<n&&S.parts.length<700;i++){const a=(o.ang!=null?o.ang:0)+(Math.random()-.5)*(o.spread!=null?o.spread:6.283),sp=rnd(o.sp?o.sp[0]:20,o.sp?o.sp[1]:80);S.parts.push({x:x+rnd(-(o.jx||0),o.jx||0),y:y+rnd(-(o.jy||0),o.jy||0),z:o.z!=null?o.z:10,vx:Math.cos(a)*sp,vy:Math.sin(a)*sp*.6,vz:o.up?rnd(o.up*.4,o.up):0,g:o.g||0,t:0,ttl:rnd(o.ttl?o.ttl[0]:.3,o.ttl?o.ttl[1]:.6),c:pick(o.c),s:o.s||1,to:o.to||null})}}
function shake(S,d){if(!S.headless)S.shake=Math.max(S.shake||0,d)}
const TRAIL={gore:['#b39868','#8a7350'],venom:['#b86bff','#6a3aa8'],skystrike:['#e0bf82','#ffffff'],maul:['#9c7a52','#d8c8a8'],stonedive:['#4e4a5a','#8e8a9a'],antlerrush:['#d0ae86','#b39868']};
function dashTrail(S,u,ab){burst(S,u.x,u.y,1,{c:TRAIL[ab]||['#e0ac48'],sp:[5,25],up:18,g:40,ttl:[.25,.5],s:2,z:2})}
const DUST=['#b39868','#8a7350','#d8c49a'],ROCK=['#9a9088','#6e665e','#b9a27a'];
const IMPACT={
 gore(S,u,t){shake(S,.22);burst(S,t.x,t.y,16,{c:DUST,sp:[40,120],up:70,g:280,ttl:[.4,.8],s:2,z:0});fx(S,{k:'crescent',x:t.x,y:t.y,a:u.face>0?0:Math.PI,c:'#f3e6c8',r:16,ttl:.3})},
 venom(S,u,t){burst(S,t.x,t.y,14,{c:['#9be35a','#6fbf2a','#c8ff7a'],sp:[30,90],up:60,g:220,ttl:[.4,.9],s:2});fx(S,{k:'crescent',x:t.x,y:t.y,a:u.face>0?0:Math.PI,c:'#c89aff',r:13,ttl:.3})},
 skystrike(S,u,t){shake(S,.15);burst(S,t.x,t.y,12,{c:['#e0bf82','#ffffff','#b99466'],sp:[40,120],up:50,g:200,ttl:[.4,.8]});fx(S,{k:'ring',x:t.x,y:t.y,r0:6,r1:44,c:'#ffffff',ttl:.35})},
 maul(S,u,t){fx(S,{k:'crescent',x:t.x,y:t.y,a:u.face>0?0:Math.PI,c:'#f3e6c8',r:15,ttl:.35});burst(S,t.x,t.y,10,{c:['#9c7a52','#d8c8a8','#553d26'],sp:[30,90],up:50,g:160,ttl:[.4,.9],s:2})},
 stonedive(S,u,t){shake(S,.3);burst(S,t.x,t.y,22,{c:ROCK,sp:[40,150],up:110,g:320,ttl:[.5,1],s:2,z:0});fx(S,{k:'scorch',x:t.x,y:t.y,ttl:3,ground:1,rx:10,c:'#3a3040'})},
 antlerrush(S,u,t){burst(S,t.x,t.y,10,{c:DUST,sp:[30,100],up:40,g:200,ttl:[.3,.7],s:2,z:0});fx(S,{k:'crescent',x:t.x,y:t.y,a:u.face>0?0:Math.PI,c:'#e8dcc0',r:12,ttl:.3})},
 vanish(S,u,t){burst(S,t.x,t.y,16,{c:['#b86bff','#6a3aa8','#e0b0ff'],sp:[40,120],ttl:[.3,.6]});fx(S,{k:'crescent',x:t.x,y:t.y,a:u.face>0?0:Math.PI,c:'#e0b0ff',r:16,ttl:.35})}
};
const CAST={
 bulwark(S,u){fx(S,{k:'dome',u,c:'#9fb6d8',ttl:4});burst(S,u.x,u.y,12,{c:['#7d8494','#a2a9b6'],sp:[40,100],up:60,g:260,ttl:[.4,.7],s:2,z:0});S.units.forEach(v=>{if(v.alive&&v.s.tauntBy===u&&v.s.taunt>0)fx(S,{k:'txt',x:v.x,y:v.y-v.r-12,s:'!',c:'#ff5a3d',z:16,ttl:.8})})},
 smash(S,u){const t=u.target||u;shake(S,.2);burst(S,t.x,t.y,20,{c:['#8a7350','#6b4a2a','#b39868'],sp:[40,150],up:100,g:300,ttl:[.5,.9],s:2,z:0});fx(S,{k:'scorch',x:t.x,y:t.y,ttl:2.5,ground:1,rx:12,c:'#5a4428'})},
 hunger(S,u){burst(S,u.x,u.y,16,{c:['#9ad7e6','#e6f6ff','#5aa0b8'],sp:[5,30],up:70,g:-30,ttl:[.6,1.1],jx:8})},
 howl(S,u){for(let i=0;i<3;i++)fx(S,{k:'wave',x:u.x,y:u.y-12,a:u.face>0?0:Math.PI,w:.8,r0:10+i*8,r1:60+i*14,c:'#f2d7a0',ttl:.5+i*.1});burst(S,u.x,u.y,10,{c:['#d8d0e0','#a8a0b0'],sp:[20,60],up:20,g:30,ttl:[.3,.6],s:2,z:0})},
 foxfire(S,u){burst(S,u.x,u.y,18,{c:['#7fb6ff','#c89aff','#f39ad2'],sp:[20,70],up:40,g:-20,ttl:[.5,1],jx:6})},
 acid(S,u){const t=u.target;if(t)burst(S,t.x,t.y,16,{c:['#9be35a','#4f8a2a','#c8ff7a'],sp:[30,90],up:70,g:260,ttl:[.4,.8],s:2,z:0})},
 shriek(S,u){for(let i=0;i<3;i++)fx(S,{k:'ring',x:u.x,y:u.y,r0:10+i*10,r1:120+i*30,c:'#c6a6f0',ttl:.45+i*.12});burst(S,u.x,u.y,10,{c:['#c6a6f0','#ffffff'],sp:[60,140],ttl:[.3,.5]})},
 flamewave(S,u){const t=u.target;if(t){burst(S,t.x,t.y,30,{c:['#ff8a3d','#ffd35a','#d9482b','#fff2b8'],sp:[40,160],up:40,g:-30,ttl:[.4,.9],s:2});fx(S,{k:'scorch',x:t.x,y:t.y,ttl:3,ground:1,rx:18,c:'#3a1a10'})}},
 chain(S,u){burst(S,u.x,u.y,8,{c:['#a9d4ff','#ffffff'],sp:[20,80],up:30,ttl:[.2,.4]})},
 rootbloom(S,u){burst(S,u.x,u.y,12,{c:['#5f9a3f','#86c25a','#c8e87a'],sp:[20,60],up:50,g:40,ttl:[.6,1.1],jx:6})},
 tidal(S,u){for(let i=0;i<2;i++)fx(S,{k:'ring',x:u.x,y:u.y,r0:10,r1:200+i*30,c:i?'#bfefff':'#6fd2d0',ttl:.6+i*.15});alliesOf(S,u).filter(v=>dist(u,v)<230).forEach(v=>{fx(S,{k:'dome',u:v,c:'#6fd2d0',ttl:1.2});burst(S,v.x,v.y,5,{c:['#6fd2d0','#bfefff'],sp:[10,40],up:50,g:120,ttl:[.4,.8]})})},
 radiance(S,u){fx(S,{k:'pillar',x:u.x,y:u.y,c:'#fff1b0',ttl:.7,w:16});alliesOf(S,u).filter(v=>dist(u,v)<200).forEach(v=>burst(S,v.x,v.y,6,{c:['#fff1b0','#ffffff','#f3d77a'],sp:[5,30],up:60,g:-10,ttl:[.6,1],jx:8}))},
 triplebite(S,u){enemiesOf(S,u).filter(v=>dist(u,v)<u.r+v.r+u.range+25).slice(0,3).forEach(v=>burst(S,v.x,v.y,6,{c:['#c8243a','#ff5a6a'],sp:[20,70],up:40,g:220,ttl:[.4,.8]}))},
 prideroar(S,u){fx(S,{k:'wave',x:u.x,y:u.y-12,a:u.face>0?0:Math.PI,w:1.1,r0:14,r1:150,c:'#f0c870',ttl:.55});alliesOf(S,u).filter(v=>dist(u,v)<180).forEach(v=>burst(S,v.x,v.y,4,{c:['#f0c870','#fff2b8'],sp:[5,20],up:50,g:-10,ttl:[.6,1]}))},
 frostroar(S,u){burst(S,u.x,u.y,28,{c:['#bfe6ff','#ffffff','#7fb6e0'],sp:[80,200],up:20,g:60,ttl:[.4,.8],s:2});fx(S,{k:'dome',u,c:'#bfe6ff',ttl:4})},
 shellup(S,u){fx(S,{k:'dome',u,c:'#c9b98a',ttl:3})},
 regrowth(S,u){burst(S,u.x,u.y,18,{c:['#80d9aa','#c8f0a0','#3f8a7a'],sp:[10,40],up:80,g:-10,ttl:[.6,1.2],jx:10})},
 threefold(S,u){const t=u.target;if(t)burst(S,t.x,t.y,10,{c:['#ff8a3d','#ffd35a','#8fcf6a'],sp:[30,90],up:40,g:100,ttl:[.3,.7]})},
 tailwind(S,u){alliesOf(S,u).filter(v=>dist(u,v)<220).forEach(v=>burst(S,v.x-20*(v.face||1),v.y,6,{c:['#e6f6ff','#ffffff','#cfefff'],ang:(v.face||1)>0?0:Math.PI,spread:.4,sp:[120,200],ttl:[.25,.45]}));burst(S,u.x,u.y,8,{c:['#ffffff','#e2e8f4'],sp:[20,60],up:40,g:60,ttl:[.6,1.1]})},
 brood(S,u){burst(S,u.x,u.y,16,{c:['#f2f0ff','#c8b8d8','#6a4a6a'],sp:[30,110],up:30,g:120,ttl:[.4,.8]});for(let i=0;i<5;i++){const a=i/5*6.283;fx(S,{k:'beam',x1:u.x,y1:u.y,x2:u.x+Math.cos(a)*40,y2:u.y+Math.sin(a)*26,c:'#f2f0ff',ttl:.5})}},
 magma(S,u){const t=u.target;if(t){shake(S,.12);burst(S,t.x,t.y,24,{c:['#ffb030','#ff5a2a','#fff27a','#8a2a10'],sp:[30,100],up:140,g:320,ttl:[.5,1],s:2,z:0})}},
 gaze(S,u){const t=u.target;if(t)burst(S,t.x,t.y,10,{c:['#d7e36a','#9a9a9a','#c8c8c8'],sp:[10,50],up:30,g:100,ttl:[.4,.8],s:2})},
 riddle(S,u){burst(S,u.x,u.y,8,{c:['#e0c060','#d6a6ff'],sp:[10,40],up:40,g:-10,ttl:[.5,.9]})},
 venom(){},gore(){},skystrike(){},maul(){},stonedive(){},antlerrush(){},vanish(S,u){burst(S,u.x,u.y,14,{c:['#3b2f4a','#6a3aa8','#b86bff'],sp:[20,70],up:30,g:20,ttl:[.4,.8],s:2})},boulder(S,u){burst(S,u.x,u.y,6,{c:ROCK,sp:[10,40],up:30,g:120,ttl:[.3,.6],s:2})},stormcall(S,u){fx(S,{k:'ring',x:u.x,y:u.y,r0:8,r1:60,c:'#fff27a',ttl:.4})},cerberus(){}
};
function tintOf(o,f,kind){o.tn=o.tn||{};const key=f+kind;if(o.tn[key])return o.tn[key];const c=document.createElement('canvas');c.width=SW;c.height=SH;const g=c.getContext('2d');g.drawImage(o.f[f],0,0);const d=g.getImageData(0,0,SW,SH),a=d.data;for(let i=0;i<a.length;i+=4){if(!a[i+3])continue;const l=a[i]*.3+a[i+1]*.59+a[i+2]*.11;if(kind==='ice'){a[i]=l*.55+70;a[i+1]=l*.7+95;a[i+2]=Math.min(255,l*.5+150)}else{a[i]=a[i+1]=a[i+2]=l*.75+45}}g.putImageData(d,0,0);o.tn[key]=c;return c}
function inward(x,y){const ex=(x-CX)/RX,ey=(y-CY)/RY,e=Math.hypot(ex,ey);let nx=-(x-CX)/(RX*RX),ny=-(y-CY)/(RY*RY);const l=Math.hypot(nx,ny)||1;return[nx/l,ny/l,e]}
function safeDir(S,u,th,fx,fy){
 const al=S.units.filter(v=>v.alive&&v.team===u.team&&v!==u&&!v.summon&&ROLE_LINE[v.role]!=='back');
 if(th&&al.length){let cx=0,cy=0;al.forEach(v=>{cx+=v.x;cy+=v.y});cx/=al.length;cy/=al.length;const ax=cx-u.x,ay=cy-u.y,l=Math.hypot(ax,ay)||1,tx=th.x-u.x,ty=th.y-u.y,tl=Math.hypot(tx,ty)||1;if((ax*tx+ay*ty)/(l*tl)<.35&&l>40){fx+=ax/l*.55;fy+=ay/l*.55}}
 const[nx,ny,e]=inward(u.x,u.y);
 if(e>.7){const out=-(fx*nx+fy*ny);if(out>0){fx+=nx*out*1.15;fy+=ny*out*1.15;const tx=-ny,ty=nx,side=th?((tx*(u.x-th.x)+ty*(u.y-th.y))>=0?1:-1):1;fx+=tx*side;fy+=ty*side}fx+=nx*(e-.7)*2.5;fy+=ny*(e-.7)*2.5}
 const l=Math.hypot(fx,fy)||1;return[fx/l,fy/l]}
function enemiesOf(S,u){return S.units.filter(v=>v.alive&&v.team!==u.team&&!(v.s.stealth>0))}
function segDist(v,ax,ay,bx,by){const dx=bx-ax,dy=by-ay,l=dx*dx+dy*dy||1,t=clamp(((v.x-ax)*dx+(v.y-ay)*dy)/l,0,1);return Math.hypot(v.x-(ax+dx*t),v.y-(ay+dy*t))}
function confuse(S,src,t,d){if(!t.alive)return;d*=(1-(t.ccRed||0))*(1+(t.ccVul||0));t.s.confuse=Math.max(t.s.confuse,d);t.target=null;fx(S,{k:'glyph',u:t,c:'#e0c060',ttl:d});cred(S,src).st.cc+=d;fx(S,{k:'txt',x:t.x,y:t.y-t.r-14,s:'CONFUSED',c:'#d6a6ff',z:12,ttl:1.1})}
function alliesOf(S,u){return S.units.filter(v=>v.alive&&v.team===u.team)}
function nearestEnemy(S,u){let b=null,bd=1e9;for(const v of S.units){if(!v.alive||v.team===u.team||v.s.stealth>0)continue;const d=dist(u,v);if(d<bd){bd=d;b=v}}return b}
function cred(S,u){return u.summon?(S.byId[u.owner]||u):u}
function fx(S,o){if(!S.headless){o.t=0;S.fx.push(o)}}
function atkMul(u){return(u.berserk?1+Math.min(.3,(1-u.hp/u.maxHp)*.4):1)*u.s.buff*(u.bloodT>0?1.12:1)*(u.traits.has('Clutch')&&u.hp/u.maxHp<.35?1.25:1)}
function hit(S,src,t,raw,o={}){
 if(!t.alive)return 0;
 const cs=cred(S,src);
 let dmg=raw,crit=false;
 if(!o.dot){dmg*=atkMul(src);if(src.exec&&t.hp/t.maxHp<.35)dmg*=1+src.exec;if(!o.noCrit&&Math.random()<src.crit){dmg*=1.6+(src.critDmg||0);crit=true}dmg*=rnd(.92,1.08)}
 dmg*=100/(100+t.def*(o.dot?.5:1)*(1-(cs.pen||0)));dmg*=1-Math.min(.9,(t.dr||0)+(t.s.drT>0?t.s.dr:0));if(o.ab)dmg*=1+(t.abVul||0);else if(!o.dot)dmg*=1+(t.atkVul||0);
 const pre=dmg;
 if(t.s.shield>0){const a=Math.min(t.s.shield,dmg);t.s.shield-=a;dmg-=a}
 dmg=Math.min(dmg,t.hp);t.hp-=dmg;if(t.wind&&!t.windUsed&&t.hp>.5&&t.hp/t.maxHp<.3){t.windUsed=1;t.hp=Math.min(t.maxHp,t.hp+t.maxHp*t.wind);fx(S,{k:'txt',x:t.x,y:t.y-t.r-18,s:'SECOND WIND',c:'#80d9aa',z:12,ttl:1.1});burst(S,t.x,t.y,14,{c:['#80d9aa','#ffffff'],sp:[20,60],up:80,g:-10,ttl:[.5,1]})}
 cs.st.dmg+=dmg;if(!t.summon)t.st.tank+=pre;
 t.hitBy[cs.id]=S.t;if(!o.dot)t.flash=.09;if(!o.dot&&t.thorns&&src.alive&&src!==t&&src.range<60&&dmg>0){hit(S,t,src,dmg*t.thorns,{dot:1});burst(S,src.x,src.y,4,{c:['#8fbf5a','#d8e8a0'],sp:[40,90],up:20,ttl:[.15,.3],z:12})}
 {const l=(src.s.ls||0)+(o.dot?0:(src.lsPerm||0));if(l>0&&dmg>0){heal(S,src,src,dmg*l,true);if(Math.random()<.6)burst(S,t.x,t.y,2,{c:['#e0405a','#ff7a8a'],to:src,sp:[10,30],ttl:[.5,.8],z:12})}}
 if(!o.dot&&!S.headless)fx(S,{k:'txt',x:t.x+rnd(-6,6),y:t.y-t.r-6,s:String(Math.round(pre)),c:crit?'#ffd25e':(o.ab?'#f4c7a8':'#f3e6c8'),z:crit?17:(o.ab?14:12),ttl:.85});
 if(crit&&!S.headless)burst(S,t.x,t.y,6,{c:['#ffd25e','#ffffff'],sp:[50,120],up:30,ttl:[.15,.3],z:14});
 if(t.hp<=.5)die(S,t,src);
 return dmg;
}
function heal(S,src,t,amt,quiet){if(!t.alive)return;const e=Math.min(amt,t.maxHp-t.hp);if(e<=0)return;t.hp+=e;cred(S,src).st.heal+=e;if(!quiet&&!S.headless){fx(S,{k:'txt',x:t.x,y:t.y-t.r-6,s:'+'+Math.round(e),c:'#80d9aa',z:13,ttl:.9});burst(S,t.x,t.y,5,{c:['#80d9aa','#c8f0d8'],sp:[5,20],up:50,g:-10,ttl:[.5,.9],jx:6})}}
function stun(S,src,t,d){if(!t.alive)return;if(t.stunImm&&!t.stunUsed){t.stunUsed=1;fx(S,{k:'txt',x:t.x,y:t.y-t.r-14,s:'RESIST',c:'#f3e6c8',z:12,ttl:1});fx(S,{k:'ring',x:t.x,y:t.y,r0:t.r+14,r1:t.r,c:'#ffffff',ttl:.35});return}d*=(1-(t.ccRed||0))*(1+(t.ccVul||0));t.s.stun=Math.max(t.s.stun,d);t.dash=null;cred(S,src).st.cc+=d}
function root(S,src,t,d){if(!t.alive)return;d*=(1-(t.ccRed||0))*(1+(t.ccVul||0));t.s.root=Math.max(t.s.root,d);cred(S,src).st.cc+=d*.6}
function slow(S,src,t,m,d){if(t.noslow)return;d*=(1-(t.ccRed||0))*(1+(t.ccVul||0));t.s.slow=Math.max(t.s.slow,d);t.s.slowMul=m;cred(S,src).st.cc+=d*.3}
function silence(S,src,t,d){t.s.silence=Math.max(t.s.silence,d);cred(S,src).st.cc+=d*.4}
function poison(S,src,t,dps,d){t.s.poison=d;t.s.poisonDps=dps;t.s.poisonSrc=src;t.s.pk=''}
function burn(S,src,t,dps,d){t.s.burn=d;t.s.burnDps=dps;t.s.burnSrc=src}
function shield(S,src,t,amt,d){t.s.shield=Math.min(t.maxHp*.6,t.s.shield+amt);t.s.shieldT=d;cred(S,src).st.heal+=amt*.5}
function dash(u,t,speed,cb){u.dash={t,speed,cb,time:1.3,ab:u.ab}}
function die(S,v,killer){
 if(v.undying&&!v.undyUsed){v.undyUsed=1;v.hp=1;v.s.shield=v.maxHp*.25;v.s.shieldT=4;fx(S,{k:'txt',x:v.x,y:v.y-30,s:'UNDYING',c:'#f0b93a',z:15,ttl:1.3});fx(S,{k:'pillar',x:v.x,y:v.y,c:'#f0b93a',ttl:.8,w:14});burst(S,v.x,v.y,18,{c:['#f0b93a','#fff2b8'],sp:[20,80],up:80,g:-10,ttl:[.6,1.1]});S.feed.push({txt:`${v.name} refuses to fall`,team:v.team});return}
 if(v.rebirth){v.rebirth=false;v.hp=v.maxHp*.4;v.s=freshStatus();fx(S,{k:'ring',x:v.x,y:v.y,r0:8,r1:70,c:'#ffb347',ttl:.8});fx(S,{k:'txt',x:v.x,y:v.y-30,s:'REBORN',c:'#ffb347',z:15,ttl:1.3});S.feed.push({txt:`${v.name} rises from the ashes`,team:v.team});return}
 v.alive=false;v.hp=0;v.deadT=S.t;if(!v.summon)S.cheer=1.6;
 if(v.summon){fx(S,{k:'ring',x:v.x,y:v.y,r0:4,r1:18,c:'rgba(240,230,210,.6)',ttl:.4});return}
 v.st.d++;
 const k=cred(S,killer);
 if(k&&k.team!==v.team){k.st.k++;if(k.traits.has('Bloodthirsty'))k.bloodT=6;if(k.apex&&k.alive){k.cdT=0;heal(S,k,k,k.maxHp*.15);fx(S,{k:'txt',x:k.x,y:k.y-k.r-24,s:'APEX',c:'#f0b93a',z:14,ttl:1});burst(S,k.x,k.y,12,{c:['#f0b93a','#fff2b8'],sp:[40,100],ttl:[.3,.6]})}S.feed.push({txt:`${k.name} took down ${v.name}`,team:k.team})}
 for(const id in v.hitBy){const a=S.byId[id];if(a&&a!==k&&a.team!==v.team&&S.t-v.hitBy[id]<6)a.st.a++}
 S.units.forEach(s=>{if(s.summon&&s.owner===v.id&&s.alive){s.alive=false}});
 fx(S,{k:'ring',x:v.x,y:v.y,r0:6,r1:40,c:v.team===0?'#e0ac48':'#d2503f',ttl:.6});burst(S,v.x,v.y,14,{c:DUST.concat([v.team===0?'#e0ac48':'#d2503f']),sp:[30,90],up:60,g:220,ttl:[.4,.8],s:2,z:0});
}
function summon(S,o,d){const u=baseUnit(S,Object.assign({summon:true,owner:o.id,team:o.team,face:o.face,sp:o.sp,hue:o.hue,line:'flank',role:'Pup',tac:{target:'weakest',pos:'flank',ability:'eager',retreat:false,kite:false},crit:.05},d));u.maxHp=u.hp;clampArena(u);S.units.push(u);fx(S,{k:'ring',x:u.x,y:u.y,r0:2,r1:20,c:'rgba(240,230,210,.7)',ttl:.4});burst(S,u.x,u.y,8,{c:['#d8d0e0','#a8a0b0'],sp:[20,60],up:20,g:30,ttl:[.3,.6],s:2,z:0});return u}
const ABIL={
 gore(S,u){const t=u.target;if(!t)return 0;const d=dist(u,t);if(d<60||d>300)return 0;dash(u,t,430,()=>{hit(S,u,t,u.atk*1.8*u.ap,{ab:1});stun(S,u,t,1.2);if(u.sig)enemiesOf(S,u).filter(v=>v!==t&&dist(t,v)<75).forEach(v=>hit(S,u,v,u.atk*.9*u.ap,{ab:1}));fx(S,{k:'ring',x:t.x,y:t.y,r0:6,r1:34,c:'#f2d7a0',ttl:.4})});return 1},
 bulwark(S,u,m){const es=enemiesOf(S,u).filter(v=>dist(u,v)<150);if(!es.length||es.length<m)return 0;es.forEach(v=>{v.s.taunt=2.5;v.s.tauntBy=u;v.target=u;cred(S,u).st.cc+=1.2});shield(S,u,u,u.maxHp*.22*u.ap*(u.sig?2:1),4);fx(S,{k:'ring',x:u.x,y:u.y,r0:u.r,r1:150,c:'#9fb6d8',ttl:.6});return 1},
 smash(S,u,m){const t=u.target;if(!t||dist(u,t)>u.range+u.r+t.r+12)return 0;const es=enemiesOf(S,u).filter(v=>dist(t,v)<85);if(es.length<m)return 0;es.forEach(v=>{hit(S,u,v,u.atk*1.5*u.ap,{ab:1});slow(S,u,v,.55,1.6);if(u.sig)stun(S,u,v,.6)});fx(S,{k:'ring',x:t.x,y:t.y,r0:10,r1:85,c:'#b9a27a',ttl:.5,fill:1});return 1},
 hunger(S,u){const t=u.target;if(!t||dist(u,t)>u.range+u.r+t.r+60)return 0;u.s.ls=.5;u.s.lsT=u.sig?8:5;u.s.buff=1.3;u.s.buffT=u.sig?8:5;fx(S,{k:'txt',x:u.x,y:u.y-u.r-14,s:'HUNGER',c:'#9ad7e6',z:13,ttl:1});fx(S,{k:'ring',x:u.x,y:u.y,r0:u.r,r1:u.r+22,c:'#9ad7e6',ttl:.5});return 1},
 howl(S,u){const n=nearestEnemy(S,u);if(!n||dist(u,n)>320)return 0;for(let i=0;i<(u.sig?3:2);i++)summon(S,u,{name:'Pup',skin:'direwolf',skinSc:.62,x:u.x+rnd(-24,24),y:u.y+(i-.5)*28,r:9,hp:u.maxHp*.3,atk:u.atk*.45,def:u.def*.6,as:1.3,mv:98,range:20,life:9});fx(S,{k:'txt',x:u.x,y:u.y-u.r-14,s:'HOWL',c:'#f2d7a0',z:13,ttl:1});return 1},
 venom(S,u){const es=enemiesOf(S,u).filter(v=>dist(u,v)<380&&!v.lure);if(!es.length)return 0;const t=es.reduce((a,b)=>a.hp/a.maxHp<b.hp/b.maxHp?a:b);u.target=t;dash(u,t,520,()=>{hit(S,u,t,u.atk*1.3*u.ap*(u.sig&&t.hp/t.maxHp<.5?2:1),{ab:1});poison(S,u,t,.5*u.atk*u.ap,4)});return 1},
 skystrike(S,u){const es=enemiesOf(S,u).filter(v=>dist(u,v)<440&&!v.summon);if(!es.length)return 0;const back=es.filter(v=>v.line==='back'),pool=back.length?back:es;const t=pool.reduce((a,b)=>dist(u,a)<dist(u,b)?a:b);u.target=t;dash(u,t,480,()=>{hit(S,u,t,u.atk*1.4*u.ap,{ab:1});stun(S,u,t,u.sig?1.5:.9);fx(S,{k:'ring',x:t.x,y:t.y,r0:4,r1:40,c:'#f2d7a0',ttl:.4})});return 1},
 foxfire(S,u){const n=nearestEnemy(S,u);if(!n||dist(u,n)>360)return 0;for(let i=0;i<(u.sig?3:2);i++)summon(S,u,{name:'Illusion',skin:'kitsune',skinSc:.8,lure:true,x:(u.x+n.x)/2+rnd(-30,30),y:(u.y+n.y)/2+(i?34:-34),r:11,hp:u.maxHp*.35,atk:u.atk*.35,def:u.def,as:1,mv:80,range:22,life:7});const es=enemiesOf(S,u).filter(v=>!v.summon);const back=es.filter(v=>v.line==='back');const pool=back.length?back:es;if(pool.length){const t=pool.reduce((a,b)=>a.hp<b.hp?a:b);fx(S,{k:'ring',x:u.x,y:u.y,r0:4,r1:26,c:'#f39ad2',ttl:.4});u.x=t.x+(t.team===1?30:-30);u.y=t.y+rnd(-10,10);clampArena(u);u.target=t;u.retT=2;fx(S,{k:'ring',x:u.x,y:u.y,r0:26,r1:4,c:'#f39ad2',ttl:.4})}return 1},
 acid(S,u,m){const t=u.target;if(!t||dist(u,t)>u.range+50)return 0;if(enemiesOf(S,u).filter(v=>dist(t,v)<80).length<m)return 0;S.zones.push({x:t.x,y:t.y,r:u.sig?110:80,t:u.sig?5:3.5,ttl:u.sig?5:3.5,dps:.6*u.atk*u.ap,src:u,team:u.team,hue:120});return 1},
 shriek(S,u,m){const es=enemiesOf(S,u).filter(v=>dist(u,v)<(u.sig?210:160));if(!es.length||es.length<m)return 0;es.forEach(v=>{hit(S,u,v,u.atk*.5*u.ap,{ab:1});slow(S,u,v,.5,2.5);silence(S,u,v,u.sig?3:2)});fx(S,{k:'ring',x:u.x,y:u.y,r0:u.r,r1:160,c:'#c6a6f0',ttl:.55});fx(S,{k:'ring',x:u.x,y:u.y,r0:u.r,r1:110,c:'#c6a6f0',ttl:.45});return 1},
 flamewave(S,u,m){const t=u.target;if(!t||dist(u,t)>u.range+40)return 0;const es=enemiesOf(S,u).filter(v=>dist(t,v)<95);if(es.length<m)return 0;es.forEach(v=>{hit(S,u,v,u.atk*1.2*u.ap,{ab:1});burn(S,u,v,.3*u.atk*u.ap*(u.sig?2:1),3)});fx(S,{k:'ring',x:t.x,y:t.y,r0:10,r1:95,c:'#ff8a3d',ttl:.6,fill:1});return 1},
 chain(S,u,m){const t=u.target;if(!t||dist(u,t)>u.range+40)return 0;if(enemiesOf(S,u).filter(v=>dist(t,v)<170).length<m)return 0;let cur=t,dmg=1.15*u.atk*u.ap;const seen=new Set([t]),pts=[[u.x,u.y],[t.x,t.y]];hit(S,u,t,dmg,{ab:1});for(let i=0;i<(u.sig?5:3);i++){const nx=enemiesOf(S,u).filter(v=>!seen.has(v)&&dist(cur,v)<170).sort((a,b)=>dist(cur,a)-dist(cur,b))[0];if(!nx)break;if(!u.sig)dmg*=.85;seen.add(nx);pts.push([nx.x,nx.y]);hit(S,u,nx,dmg,{ab:1});cur=nx}fx(S,{k:'bolt',pts,c:'#a9d4ff',ttl:.35});pts.slice(1).forEach(q=>burst(S,q[0],q[1],6,{c:['#a9d4ff','#ffffff'],sp:[30,100],up:20,ttl:[.15,.35]}));return 1},
 gaze(S,u){const t=u.target;if(!t||dist(u,t)>u.range+50)return 0;hit(S,u,t,u.atk*.7*u.ap,{ab:1});stun(S,u,t,2);if(t.s.stun>0){t.s.tint='stone';t.s.tintT=t.s.stun}if(u.sig){const o2=enemiesOf(S,u).filter(v=>v!==t&&dist(t,v)<130)[0];if(o2){stun(S,u,o2,1.2);if(o2.s.stun>0){o2.s.tint='stone';o2.s.tintT=o2.s.stun}fx(S,{k:'beam',x1:u.x,y1:u.y,x2:o2.x,y2:o2.y,c:'#d7e36a',ttl:.45})}}fx(S,{k:'beam',x1:u.x,y1:u.y,x2:t.x,y2:t.y,c:'#d7e36a',ttl:.45});fx(S,{k:'txt',x:t.x,y:t.y-t.r-16,s:'PETRIFIED',c:'#d7e36a',z:12,ttl:1.2});return 1},
 rootbloom(S,u){const al=alliesOf(S,u).filter(v=>!v.summon&&dist(u,v)<260);const w=al.reduce((a,b)=>a.hp/a.maxHp<b.hp/b.maxHp?a:b,al[0]);if(!w||w.hp/w.maxHp>.8)return 0;heal(S,u,w,3.2*u.atk*u.ap);fx(S,{k:'beam',x1:u.x,y1:u.y,x2:w.x,y2:w.y,c:'#80d9aa',ttl:.4});const n=nearestEnemy(S,u);if(n&&dist(u,n)<220){root(S,u,n,1.6);if(u.sig)enemiesOf(S,u).filter(v=>v!==n&&dist(n,v)<120).forEach(v=>root(S,u,v,1.2));fx(S,{k:'ring',x:n.x,y:n.y,r0:n.r+10,r1:n.r+2,c:'#8fbf5a',ttl:.5})}return 1},
 tidal(S,u){const n=nearestEnemy(S,u);if(!n||dist(u,n)>320)return 0;alliesOf(S,u).filter(v=>dist(u,v)<230).forEach(v=>shield(S,u,v,1.6*u.atk*u.ap*(u.sig?1.6:1),5));fx(S,{k:'ring',x:u.x,y:u.y,r0:u.r,r1:230,c:'#6fd2d0',ttl:.6});return 1},
 radiance(S,u){const al=alliesOf(S,u).filter(v=>dist(u,v)<200);if(!al.some(v=>v.hp/v.maxHp<.8||v.s.stun>0||v.s.root>0))return 0;al.forEach(v=>{heal(S,u,v,2*u.atk*u.ap*(u.sig?1.5:1));v.s.stun=0;v.s.root=0;v.s.poison=0;v.s.slow=0});fx(S,{k:'ring',x:u.x,y:u.y,r0:u.r,r1:200,c:'#fff1b0',ttl:.6,fill:1});return 1}
};
Object.assign(ABIL,{
 triplebite(S,u,m){const es=enemiesOf(S,u).filter(v=>dist(u,v)<u.r+v.r+u.range+25).sort((a,b)=>dist(u,a)-dist(u,b)).slice(0,3);if(!es.length||es.length<m)return 0;es.forEach(v=>{hit(S,u,v,u.atk*.9*u.ap,{ab:1});poison(S,u,v,.35*u.atk*u.ap,3);v.s.pk='bleed';if(u.sig)heal(S,u,u,u.maxHp*.08);fx(S,{k:'slash',x:v.x,y:v.y,r:v.r+5,a:Math.atan2(u.y-v.y,u.x-v.x),c:'#ff6b5a',ttl:.25})});return 1},
 prideroar(S,u){const n=nearestEnemy(S,u);if(!n||dist(u,n)>220)return 0;enemiesOf(S,u).filter(v=>dist(u,v)<150).forEach(v=>{v.s.taunt=2;v.s.tauntBy=u;v.target=u;cred(S,u).st.cc+=.8});alliesOf(S,u).filter(v=>dist(u,v)<180).forEach(v=>{v.s.buff=Math.max(v.s.buff,u.sig?1.3:1.15);v.s.buffT=Math.max(v.s.buffT,5)});fx(S,{k:'ring',x:u.x,y:u.y,r0:u.r,r1:180,c:'#f0c870',ttl:.6});fx(S,{k:'txt',x:u.x,y:u.y-u.r-16,s:'ROAR',c:'#f0c870',z:14,ttl:1});return 1},
 frostroar(S,u,m){const es=enemiesOf(S,u).filter(v=>dist(u,v)<150);if(!es.length||es.length<m)return 0;es.forEach(v=>{slow(S,u,v,.4,2.5);if(u.sig){stun(S,u,v,.9);if(v.s.stun>0){v.s.tint='ice';v.s.tintT=v.s.stun}}});shield(S,u,u,u.maxHp*.15*u.ap,4);fx(S,{k:'ring',x:u.x,y:u.y,r0:u.r,r1:150,c:'#bfe6ff',ttl:.6,fill:1});return 1},
 shellup(S,u){const n=nearestEnemy(S,u);if(!n||dist(u,n)>140||u.hp/u.maxHp>.9)return 0;enemiesOf(S,u).filter(v=>dist(u,v)<110).forEach(v=>{v.s.taunt=2;v.s.tauntBy=u;v.target=u;cred(S,u).st.cc+=.8});u.s.dr=.8;u.s.drT=3;if(u.sig)heal(S,u,u,u.maxHp*.2);fx(S,{k:'ring',x:u.x,y:u.y,r0:u.r+10,r1:u.r,c:'#c9b98a',ttl:.5});fx(S,{k:'txt',x:u.x,y:u.y-u.r-16,s:'SHELL',c:'#c9b98a',z:13,ttl:1});return 1},
 maul(S,u){const t=u.target;if(!t)return 0;const d=dist(u,t);if(d<40||d>260)return 0;dash(u,t,460,()=>{hit(S,u,t,u.atk*1.5*u.ap,{ab:1});root(S,u,t,u.sig?2.5:1.5);if(u.sig)hit(S,u,t,u.atk*.8*u.ap,{ab:1});fx(S,{k:'slash',x:t.x,y:t.y,r:t.r+6,a:Math.atan2(u.y-t.y,u.x-t.x),c:'#f3d58f',ttl:.3})});return 1},
 regrowth(S,u){if(u.hp/u.maxHp>.7)return 0;heal(S,u,u,u.maxHp*(u.sig?.4:.25));u.s.buff=Math.max(u.s.buff,1.2);u.s.buffT=5;fx(S,{k:'ring',x:u.x,y:u.y,r0:u.r+14,r1:u.r,c:'#80d9aa',ttl:.5});return 1},
 threefold(S,u){const t=u.target;if(!t||dist(u,t)>u.range+u.r+t.r+15)return 0;const n=u.sig?5:3;for(let i=0;i<n;i++){hit(S,u,t,u.atk*.75*u.ap,{ab:1});fx(S,{k:'slash',x:t.x,y:t.y,r:t.r+4+i*2,a:Math.atan2(u.y-t.y,u.x-t.x)+i*.5,c:['#f3d58f','#d8d8d8','#8fcf6a','#f3d58f','#d8d8d8'][i],ttl:.3})}burn(S,u,t,.25*u.atk*u.ap,3);return 1},
 stonedive(S,u){const es=enemiesOf(S,u).filter(v=>dist(u,v)<440&&!v.summon);if(!es.length)return 0;const back=es.filter(v=>v.line==='back'),pool=back.length?back:es;const t=pool.reduce((a,b)=>dist(u,a)<dist(u,b)?a:b);u.target=t;dash(u,t,500,()=>{enemiesOf(S,u).filter(v=>dist(t,v)<70).forEach(v=>{hit(S,u,v,u.atk*1.1*u.ap,{ab:1});if(u.sig)stun(S,u,v,.8)});u.s.dr=.6;u.s.drT=1.5;fx(S,{k:'ring',x:t.x,y:t.y,r0:6,r1:70,c:'#a9a3b8',ttl:.5,fill:1})});return 1},
 vanish(S,u){const es=enemiesOf(S,u).filter(v=>!v.summon&&dist(u,v)<420);if(!es.length)return 0;const t=es.reduce((a,b)=>a.hp<b.hp?a:b);u.s.stealth=1.5;u.ambush=t;u.target=t;fx(S,{k:'ring',x:u.x,y:u.y,r0:u.r+10,r1:2,c:'#b86bff',ttl:.4});return 1},
 antlerrush(S,u){const t=u.target;if(!t)return 0;const d=dist(u,t);if(d<50||d>300)return 0;const ax=u.x,ay=u.y,line=enemiesOf(S,u).filter(v=>segDist(v,ax,ay,t.x,t.y)<v.r+14);dash(u,t,560,()=>{line.forEach(v=>{if(v.alive){hit(S,u,v,u.atk*1.1*u.ap,{ab:1});if(u.sig)slow(S,u,v,.5,2)}})});return 1},
 boulder(S,u,m){const t=u.target;if(!t||dist(u,t)>u.range+40)return 0;if(enemiesOf(S,u).filter(v=>dist(t,v)<70).length<m)return 0;const toss=tg=>S.proj.push({x:u.x,y:u.y,t:tg,src:u,spd:300,sp:'boulder',c:'#9a9088',lob:1,d0:Math.max(1,dist(u,tg)),cb:()=>{enemiesOf(S,u).filter(v=>dist(tg,v)<70).forEach(v=>{hit(S,u,v,u.atk*1.4*u.ap,{ab:1});stun(S,u,v,.8)});fx(S,{k:'ring',x:tg.x,y:tg.y,r0:8,r1:70,c:'#b9a27a',ttl:.5,fill:1});shake(S,.25);burst(S,tg.x,tg.y,20,{c:ROCK,sp:[40,140],up:110,g:320,ttl:[.5,1],s:2,z:0});fx(S,{k:'scorch',x:tg.x,y:tg.y,ttl:3,ground:1,rx:14,c:'#4a3a28'})}});toss(t);if(u.sig){const o2=enemiesOf(S,u).filter(v=>v!==t)[0];if(o2)toss(o2)}return 1},
 stormcall(S,u){const es=enemiesOf(S,u);if(!es.length)return 0;const n=u.sig?5:3;for(let i=0;i<n;i++){const v=pick(es);if(!v.alive)continue;hit(S,u,v,u.atk*u.ap,{ab:1});if(u.sig)stun(S,u,v,.4);fx(S,{k:'pillar',x:v.x,y:v.y,c:'#fff27a',ttl:.4,jag:1});fx(S,{k:'scorch',x:v.x,y:v.y,ttl:2.5,ground:1,rx:6,c:'#2a1a10'});burst(S,v.x,v.y,8,{c:['#fff27a','#ffffff','#a9d4ff'],sp:[30,110],up:40,g:200,ttl:[.2,.5]});shake(S,.08)}return 1},
 riddle(S,u){const t=u.target;if(!t||t.summon||dist(u,t)>u.range+60)return 0;confuse(S,u,t,2.5);fx(S,{k:'beam',x1:u.x,y1:u.y,x2:t.x,y2:t.y,c:'#d6a6ff',ttl:.4});if(u.sig){const o2=enemiesOf(S,u).filter(v=>v!==t&&!v.summon&&dist(t,v)<150)[0];if(o2)confuse(S,u,o2,2)}return 1},
 tailwind(S,u){const n=nearestEnemy(S,u);if(!n||dist(u,n)>320)return 0;alliesOf(S,u).filter(v=>dist(u,v)<220).forEach(v=>{v.s.haste=1.3;v.s.hasteT=5;if(u.sig){v.s.stun=0;v.s.root=0;v.s.slow=0;heal(S,u,v,u.atk*.8*u.ap)}});fx(S,{k:'ring',x:u.x,y:u.y,r0:u.r,r1:220,c:'#cfefff',ttl:.6});return 1},
 brood(S,u){const n=nearestEnemy(S,u);if(!n||dist(u,n)>340)return 0;const k=u.sig?5:3;for(let i=0;i<k;i++)summon(S,u,{name:'Spiderling',skin:'arachne',skinSc:.5,x:u.x+rnd(-20,20),y:u.y+rnd(-20,20),r:8,hp:u.maxHp*.22,atk:u.atk*.35,def:u.def*.5,as:1.2,mv:92,range:18,life:10,slowHit:1});return 1},
 magma(S,u,m){const t=u.target;if(!t||dist(u,t)>u.range+40)return 0;if(enemiesOf(S,u).filter(v=>dist(t,v)<85).length<m)return 0;S.zones.push({x:t.x,y:t.y,r:u.sig?115:85,t:4,ttl:4,dps:.5*u.atk*u.ap*(u.sig?1.5:1),src:u,team:u.team,hue:18,slow:1});return 1}
});
function pickTarget(S,u){
 const es=enemiesOf(S,u);if(!es.length)return null;
 const m=u.tac.target;
 if(m!=='backline'&&m!=='casters'){const l=es.find(v=>v.lure&&dist(u,v)<170);if(l)return l}
 let best=null,bs=1e9;
 for(const v of es){const d=dist(u,v);let s=d;
  if(m==='weakest')s=v.hp*.6+d*1.2;
  else if(m==='backline')s=d-(v.line==='back'?380:0)+(v.summon?300:0);
  else if(m==='casters')s=d-(['Support','Caster','Controller','Artillery','Summoner'].includes(v.role)?420:0)+(v.summon?300:0);
  else if(m==='threat')s=d*.8-(v.st.dmg*.25+v.atk*4)+(v.summon?300:0);
  else if(v.summon)s+=20;
  if(ROLE_LINE[u.role]==='front'&&(m==='nearest'||m==='threat')&&S.units.some(a=>a.alive&&a.team===u.team&&ROLE_LINE[a.role]==='back'&&dist(a,v)<110))s-=120;
  if(v.range<80&&u.range>80&&v.target===u)s-=60;
  if(s<bs){bs=s;best=v}}
 return best;
}
function gate(S,u){if(u.tac.ability!=='clutch')return true;return u.hp/u.maxHp<.5||alliesOf(S,u).some(v=>!v.summon&&v.hp/v.maxHp<.45)||(u.target&&u.target.hp/u.target.maxHp<.35)}
function think(S,u,dt){
 const s=u.s;
 if(u.atkT>0)u.atkT-=dt;
 if(u.cdT>0)u.cdT-=dt;
 if(s.stun>0)return;
 if(u.dash){const d=u.dash;d.time-=dt;const t=d.t;if(!t.alive||d.time<=0){u.dash=null;return}const dd=dist(u,t),reach=u.r+t.r+4;if(dd<=reach){d.cb();if(IMPACT[d.ab]&&!S.headless)IMPACT[d.ab](S,u,t);u.dash=null;u.atkT=.3;return}const st=Math.min(dd-reach+.1,d.speed*dt);u.x+=(t.x-u.x)/dd*st;u.y+=(t.y-u.y)/dd*st;u.moved=.12;u.walk+=st;u.face=t.x>=u.x?1:-1;if(!S.headless&&Math.random()<.7)dashTrail(S,u,d.ab);return}
 u.retT-=dt;
 if(s.confuse>0){const al=S.units.filter(v=>v.alive&&v.team===u.team&&v!==u);u.target=al.length?al.reduce((a,b)=>dist(u,a)<dist(u,b)?a:b):null}
 else if(s.taunt>0&&s.tauntBy&&s.tauntBy.alive)u.target=s.tauntBy;
 else if(!u.target||!u.target.alive||u.retT<=0||u.target.team===u.team||u.target.s.stealth>0){u.target=pickTarget(S,u);u.retT=.8}
 if(!u.target)return;
 const stc=u.tac.stance,pu=u.partnerU;
 if(!(s.confuse>0)&&!(s.taunt>0)&&pu&&pu.alive){
  if(stc==='assist'&&pu.target&&pu.target.alive&&pu.target.team!==u.team&&!(pu.target.s.stealth>0))u.target=pu.target;
  else if(stc==='guard'){const e=enemiesOf(S,u).filter(v=>dist(v,pu)<170).sort((a,b)=>dist(a,pu)-dist(b,pu))[0];if(e)u.target=e}}
 if(u.ab&&u.cdT<=0&&s.silence<=0&&s.confuse<=0&&s.stealth<=0){
  if(gate(S,u)){const m=(u.tac.ability==='group'&&AOE.has(u.ab))?2:1;if(ABIL[u.ab](S,u,m)){u.cdT=u.cd;u.animCast=.45;if(!S.headless&&CAST[u.ab])CAST[u.ab](S,u);if(u.echo&&Math.random()<u.echo){u.cdT=.6;fx(S,{k:'ring',x:u.x,y:u.y,r0:u.r+16,r1:u.r,c:'#b77fe0',ttl:.4});fx(S,{k:'txt',x:u.x,y:u.y-u.r-30,s:'ECHO',c:'#b77fe0',z:11,ttl:1})}if(!S.headless&&u.ab!=='hunger'&&u.ab!=='howl')fx(S,{k:'txt',x:u.x,y:u.y-u.r-20,s:ABINFO[u.ab][0],c:'#86abde',z:11,ttl:1})}else u.cdT=.25}else u.cdT=.25;
  if(u.dash)return;
 }
 const tt=u.target;if(!tt||!tt.alive)return;
 const d=dist(u,tt),reach=u.range+u.r+tt.r;
 let mx=0,my=0,urgent=false;
 const hpf=u.hp/u.maxHp,ranged=u.range>80;
 const n=nearestEnemy(S,u);
 let th=null;if(ranged&&!u.summon){let bd=1e9;for(const v of S.units){if(!v.alive||v.team===u.team||v.range>80||v.s.stun>0||v.s.stealth>0)continue;const dv=dist(u,v),danger=v.r+u.r+v.range+(v.target===u?70:40);if(dv<danger&&dv<bd){bd=dv;th=v}}}
 if((u.tac.retreatAt||0)>0&&hpf<u.tac.retreatAt/100&&!u.summon&&n&&dist(u,n)<190){const dn=dist(u,n)||1;[mx,my]=safeDir(S,u,n,(u.x-n.x)/dn,(u.y-n.y)/dn);urgent=true}
 else if(u.tac.kite&&th&&!(s.taunt>0)&&!(s.confuse>0)){const dn=dist(u,th)||1;[mx,my]=safeDir(S,u,th,(u.x-th.x)/dn,(u.y-th.y)/dn);urgent=dn<th.r+u.r+th.range+8}
 else if(stc==='guard'&&pu&&pu.alive&&!(s.confuse>0)&&!(s.taunt>0)&&dist(tt,pu)>=170&&dist(u,pu)>55){const dp=dist(u,pu);mx=(pu.x-u.x)/dp;my=(pu.y-u.y)/dp}
 else if(stc==='hold'&&!(s.confuse>0)&&!(s.taunt>0)&&Math.hypot(tt.x-u.ax,tt.y-u.ay)>u.range+200){const da=Math.hypot(u.x-u.ax,u.y-u.ay);if(da>12){mx=(u.ax-u.x)/da;my=(u.ay-u.y)/da}}
 else if(ranged){const want=reach*.85;
  if(d>reach-6){mx=(tt.x-u.x)/d;my=(tt.y-u.y)/d}
  else if(u.tac.kite&&d<want*.6){[mx,my]=safeDir(S,u,tt,(u.x-tt.x)/d,(u.y-tt.y)/d);mx*=.6;my*=.6}
  else{const tx=-(tt.y-u.y)/d,ty=(tt.x-u.x)/d,sd=(u.id%2?1:-1);const[nx,ny,e]=inward(u.x,u.y);if(e<.78){mx=tx*sd*.25;my=ty*sd*.25}}}
 else if(d>reach-3){const ang=Math.atan2(u.y-tt.y,u.x-tt.x)+((u.id%5)-2)*.32,rr=tt.r+u.r+Math.min(u.range,24)*.6,px=tt.x+Math.cos(ang)*rr,py=tt.y+Math.sin(ang)*rr,dx=px-u.x,dy=py-u.y,l=Math.hypot(dx,dy)||1;if(d>reach+40){mx=(tt.x-u.x)/d;my=(tt.y-u.y)/d}else{mx=dx/l;my=dy/l}}
 // soft separation from allies, stay off the wall
 if(mx||my){for(const v of S.units){if(v===u||!v.alive||v.team!==u.team)continue;const dx=u.x-v.x,dy=u.y-v.y,dd=Math.hypot(dx,dy),mn=u.r+v.r+10;if(dd<mn&&dd>.01){mx+=dx/dd*(mn-dd)/mn*.8;my+=dy/dd*(mn-dd)/mn*.8}}
  const[nx,ny,e]=inward(u.x,u.y);if(e>.9){mx+=nx*(e-.9)*6;my+=ny*(e-.9)*6}}
 const ml=Math.hypot(mx,my);if(ml>1){mx/=ml;my/=ml}
 // orb-walk: ranged beasts plant their feet for the shot unless in real danger
 if(ranged&&u.animAtk>.16&&!urgent){mx=0;my=0}
 const spd=u.mv*(s.slow>0?s.slowMul:1)*(s.hasteT>0?s.haste:1);
 const k=Math.min(1,dt*(ml?10:14));u.vx=(u.vx||0)+(mx*spd-(u.vx||0))*k;u.vy=(u.vy||0)+(my*spd-(u.vy||0))*k;
 if(s.root>0){u.vx=0;u.vy=0}
 const vs=Math.hypot(u.vx,u.vy);
 if(vs>4){u.x+=u.vx*dt;u.y+=u.vy*dt;clampArena(u);u.moved=.12;u.walk+=vs*dt}
 if(u.animAtk>0||vs<25)u.face=tt.x>=u.x?1:-1;else if(Math.abs(u.vx)>12)u.face=u.vx>0?1:-1;
 if(d<=reach+2&&u.atkT<=0&&s.stealth<=0){
  u.atkT=1/(u.as*(s.hasteT>0?s.haste:1));u.animAtk=.32;u.face=tt.x>=u.x?1:-1;
  if(u.range>60){S.proj.push({x:u.x,y:u.y,t:tt,src:u,raw:u.atk,spd:470,sp:u.sp,c:`hsl(${u.hue} 75% 66%)`})}
  else{atkHit(S,u,tt,u.atk);if(u.cleave)enemiesOf(S,u).filter(v=>v!==tt&&dist(tt,v)<42).forEach(v=>hit(S,u,v,u.atk*u.cleave));if(u.slowHit)slow(S,u,tt,.7,1.2);fx(S,{k:'slash',x:tt.x,y:tt.y,r:tt.r+5,a:Math.atan2(u.y-tt.y,u.x-tt.x),c:u.team===0?'#f3d58f':'#f19a8c',ttl:.22})}
  if(u.double&&tt.alive&&Math.random()<u.double){fx(S,{k:'slash',x:tt.x,y:tt.y,r:tt.r+8,a:Math.atan2(u.y-tt.y,u.x-tt.x)+.6,c:'#b77fe0',ttl:.25});if(u.range>60)S.proj.push({x:u.x,y:u.y-4,t:tt,src:u,raw:u.atk,spd:470,sp:u.sp,c:`hsl(${u.hue} 75% 66%)`});else atkHit(S,u,tt,u.atk)}
 }
}
function tickStatus(S,u,dt){
 const s=u.s;
 for(const k of ['stun','slow','root','silence','taunt','confuse'])if(s[k]>0)s[k]-=dt;
 if(s.hasteT>0)s.hasteT-=dt;if(s.drT>0)s.drT-=dt;if(s.tintT>0)s.tintT-=dt;
 if(s.stealth>0){s.stealth-=dt;if(s.stealth<=0&&u.ambush){const t=u.ambush;u.ambush=null;if(t.alive){u.x=t.x+(t.team===1?24:-24);u.y=t.y;clampArena(u);u.face=t.x>=u.x?1:-1;u.animAtk=.32;fx(S,{k:'ring',x:u.x,y:u.y,r0:4,r1:28,c:'#b86bff',ttl:.4});hit(S,u,t,u.atk*2.4*u.ap,{ab:1,noCrit:1});if(!S.headless)IMPACT.vanish(S,u,t);if(u.sig)poison(S,u,t,.5*u.atk*u.ap,4);u.target=t}}}
 if(s.poison>0){s.poison-=dt;hit(S,s.poisonSrc,u,s.poisonDps*dt,{dot:1})}
 if(u.alive&&s.burn>0){s.burn-=dt;hit(S,s.burnSrc,u,s.burnDps*dt,{dot:1})}
 if(s.shieldT>0){s.shieldT-=dt;if(s.shieldT<=0)s.shield=0}
 if(s.lsT>0){s.lsT-=dt;if(s.lsT<=0)s.ls=0}
 if(s.buffT>0){s.buffT-=dt;if(s.buffT<=0)s.buff=1}
 if(u.bloodT>0)u.bloodT-=dt;
 if(u.alive&&u.regen&&u.hp<u.maxHp)u.hp=Math.min(u.maxHp,u.hp+u.maxHp*u.regen*dt);
 if(u.summon&&u.alive){u.life-=dt;if(u.life<=0){u.alive=false;fx(S,{k:'ring',x:u.x,y:u.y,r0:4,r1:16,c:'rgba(240,230,210,.5)',ttl:.35})}}
}
function step(S,dt){
 if(S.done)return;
 S.t+=dt;
 for(const u of S.units){if(u.animAtk>0)u.animAtk-=dt;if(u.animCast>0)u.animCast-=dt;if(u.flash>0)u.flash-=dt;if(u.moved>0)u.moved-=dt}if(S.cheer>0)S.cheer-=dt;
 for(const u of S.units)if(u.alive)tickStatus(S,u,dt);
 for(const u of S.units)if(u.alive)think(S,u,dt);
 for(const z of S.zones){z.t-=dt;for(const v of S.units)if(v.alive&&v.team!==z.team&&Math.hypot(v.x-z.x,v.y-z.y)<z.r){hit(S,z.src,v,z.dps*dt,{dot:1});if(z.slow){v.s.slow=Math.max(v.s.slow,.25);v.s.slowMul=.65}}}
 if(!S.headless)for(const z of S.zones)if(Math.random()<.35)burst(S,z.x+rnd(-z.r*.6,z.r*.6),z.y+rnd(-z.r*.4,z.r*.4),1,{c:z.hue<60?['#ffb030','#ff5a2a','#fff27a']:['#9be35a','#c8ff7a'],sp:[0,8],up:35,g:0,ttl:[.5,.9],z:0});
 S.zones=S.zones.filter(z=>z.t>0);
 for(const p of S.proj){if(!p.t.alive){p.dead=1;continue}const d=Math.hypot(p.t.x-p.x,p.t.y-p.y);const st=p.spd*dt;if(d<=st+p.t.r*.5){if(p.cb)p.cb();else atkHit(S,p.src,p.t,p.raw);p.dead=1}else{p.px=p.x;p.py=p.y;p.x+=(p.t.x-p.x)/d*st;p.y+=(p.t.y-p.y)/d*st}}
 S.proj=S.proj.filter(p=>!p.dead);
 const al=S.units.filter(u=>u.alive);
 for(let i=0;i<al.length;i++)for(let j=i+1;j<al.length;j++){const a=al[i],b=al[j];const dx=b.x-a.x,dy=b.y-a.y,d=Math.hypot(dx,dy),mn=a.r+b.r;if(d<mn&&d>.01){const p=(mn-d)/2;if(!a.dash){a.x-=dx/d*p;a.y-=dy/d*p}if(!b.dash){b.x+=dx/d*p;b.y+=dy/d*p}}}
 al.forEach(clampArena);
 if(!S.headless){for(const f of S.fx)f.t+=dt;S.fx=S.fx.filter(f=>f.t<f.ttl)}
 const a=S.units.some(u=>u.alive&&!u.summon&&u.team===0),b=S.units.some(u=>u.alive&&!u.summon&&u.team===1);
 if(!a||!b){S.done=true;S.winner=a?0:b?1:(Math.random()<.5?0:1)}
 else if(S.t>=S.maxT){const f=tm=>S.units.filter(u=>!u.summon&&u.team===tm).reduce((s,u)=>s+(u.alive?u.hp/u.maxHp:0),0);const fa=f(0),fb=f(1);S.done=true;S.timeout=true;S.winner=fa>=fb?0:1}
}
function runHeadless(S){let g=0;const h=S.headless;S.headless=true;while(!S.done&&g++<6000)step(S,1/30);S.headless=h}
function killsOf(S,team){return S.units.filter(u=>u.team===team&&!u.summon).reduce((s,u)=>s+u.st.k,0)}

/* ============ RECORDING ============ */
function addStats(o,st,imp,won){o.m++;if(won)o.w++;o.k+=st.k;o.d+=st.d;o.a+=st.a;o.dmg+=st.dmg;o.tank+=st.tank;o.heal+=st.heal;o.cc+=st.cc;o.imp+=imp;o.bestK=Math.max(o.bestK||0,st.k);o.bestDmg=Math.max(o.bestDmg||0,st.dmg)}
function gainXp(b,amt){let m=1;if(b.traits.includes('Quick Study'))m+=.25;if(b.traits.includes('Lazy'))m-=.2;m+=mods(b).xp||0;b.xp+=Math.round(amt*m);let ups=0;const cap=lvlCap(b);while(b.lvl<cap&&b.xp>=xpNeed(b.lvl)){b.xp-=xpNeed(b.lvl);b.lvl++;ups++;grow(b);b.rolls=(b.rolls||0)+1;if(b.lvl===10||b.lvl===20)offerAwaken(b)}if(b.lvl>=cap)b.xp=Math.min(b.xp,xpNeed(b.lvl));b.peak=Math.max(b.peak||0,ovr(b));if(ups&&b.clubId!=='P'&&b.clubId!=='MKT'){autoPick(b);if(b.awaken&&b.awaken.length){b.traits.push(b.awaken[0]);b.awaken=[]}}if(b.clubId==='P'&&b.rolls>0&&!b.offer)rollOffer(b);return ups}
function grow(b){const g=(.45+b.pot*.22)*(b.traits.includes('Late Bloomer')&&b.age>=3?1.3:1)*(b.age>=7?.5:1);const f=FOCUS[b.focus];ATTR.forEach(k=>{const w=f?(k===f?2.2:.7):1;b.attrs[k]=Math.min(99,Math.round((b.attrs[k]+g*w*rnd(.5,1.5))*10)/10)})}
function recordMatch(S,meta){
 const drain={5:22,3:18,2:15}[meta.fmt]||20;
 const rows=[];
 S.units.filter(u=>!u.summon).forEach(u=>{
  const b=G.beasts[u.bid];if(!b)return;
  const won=u.team===S.winner,imp=impactOf(u.st);
  addStats(b.season,u.st,imp,won);addStats(b.career,u.st,imp,won);
  b.form=(b.form||[]).concat([Math.round(imp)]).slice(-5);
  let inj=0;
  if(!b.draft&&!meta.training){const m=mods(b),ec=(1-(m.energy||0))*(b.traits.includes('Iron Lungs')?.7:1);b.energy=Math.max(0,Math.round(b.energy-drain*ec));b.fat=Math.min(100,Math.round((b.fat||0)+({5:7,3:6,2:5}[meta.fmt]||6)*(1-(m.energy||0))));b._played=true;
   const ch=(b.fat>55?(b.fat-55)/250:0)+(u.alive?0:.02);
   if(!b.inj&&Math.random()<ch){b.inj=ri(1,3);b._injToday=true;inj=b.inj;b.notes.push({s:G.season,d:G.day+1,t:`injured, out for ${inj} day${inj>1?'s':''}`});if(b.clubId==='P')news(`${b.name} picked up an injury and will miss ${inj} day${inj>1?'s':''}.`,'loss')}}
  const lv0=b.lvl,a0=Object.assign({},b.attrs),xp=Math.round(30+(won?20:0)+clamp(imp*.4,0,30));
  const ups=gainXp(b,xp);
  const gains={};if(ups)ATTR.forEach(k=>{const d=b.attrs[k]-a0[k];if(d>.05)gains[k]=d});
  rows.push({bid:b.id,name:b.name,sp:b.sp,team:u.team,st:Object.assign({},u.st),imp,alive:u.alive,xp,ups,lvl:b.lvl,lv0,gains,inj,aw:!!(b.awaken&&b.awaken.length)});
 });
 [0,1].forEach(team=>{
  const us=S.units.filter(u=>!u.summon&&u.team===team).map(u=>G.beasts[u.bid]).filter(b=>b&&b.clubId==='P'&&!b.draft);
  const won=S.winner===team;
  for(let i=0;i<us.length;i++)for(let j=i+1;j<us.length;j++){const a=us[i],c=us[j],k=bkey(a.id,c.id);const x=G.bonds[k]||(G.bonds[k]={m:0,w:0});const before=bondLvl(a.id,c.id);x.m++;if(won)x.w+=(a.traits.includes('Pack Soul')||c.traits.includes('Pack Soul'))?2:1;const after=bondLvl(a.id,c.id);if(after>before)news(`${a.name} and ${c.name} are now ${BOND_N[after]} partners (+${after*3}% when fielded together).`,'bond')}
 });
 return rows;
}
function teamFor(cid,fmt,draft){return draft?G.cup.teams[cid].map(id=>G.beasts[id]).filter(Boolean):pickLineup(cid,fmt)}
function lineScore(b){return ovr(b)*energyFactor(b.energy)*(b.energy<40?.8:1)*((b.fat||0)>60?.85:1)}
function pickLineup(cid,n){const all=G.clubs[cid].roster.map(id=>G.beasts[id]).filter(Boolean),fit=all.filter(b=>!b.inj),pool=fit.length>=n?fit:all;return pool.sort((a,b)=>(a.inj?1:0)-(b.inj?1:0)||lineScore(b)-lineScore(a)).slice(0,n)}
function simAIMatch(a,b,fmt,draft){const S=createSim(teamFor(a,fmt,draft),teamFor(b,fmt,draft),{headless:true});runHeadless(S);recordMatch(S,{fmt,draft});return{w:S.winner===0?a:b,ka:killsOf(S,0),kb:killsOf(S,1)}}

/* ============ FLOW ============ */
function curEvent(){return G.sched[G.day]}
function leagueRoundNow(){let r=0;for(let i=0;i<G.day&&i<G.sched.length;i++)if(G.sched[i].t==='league')r++;return Math.min(r,13)}
function leagueOpp(r){const p=G.league.fix[r].find(p=>p.includes('P'));return p[0]==='P'?p[1]:p[0]}
function standings(){const t={};G.div.forEach(id=>t[id]={id,p:0,w:0,l:0,pts:0,kd:0,form:[]});G.league.res.forEach(round=>round&&round.forEach(m=>{const A=t[m.a],B=t[m.b];if(!A||!B)return;A.p++;B.p++;const wa=m.w===m.a;(wa?A:B).w++;(wa?B:A).l++;(wa?A:B).pts+=3;A.kd+=m.ka-m.kb;B.kd+=m.kb-m.ka;A.form.push(wa?'W':'L');B.form.push(wa?'L':'W')}));return Object.values(t).sort((x,y)=>y.pts-x.pts||y.kd-x.kd||x.id.localeCompare(y.id))}
function refreshMarket(full){
 const q=TIERS[G.tier].q+Math.min(6,G.renown/40)-2;
 const drop=full?G.market.slice():shuffle(G.market.slice()).slice(0,2);
 drop.forEach(id=>{delete G.beasts[id]});
 G.market=G.market.filter(id=>!drop.includes(id));
 while(G.market.length<6){const prospect=G.market.filter(id=>G.beasts[id].age<=1).length<2&&Math.random()<.6;const b=genBeast(q,{prospect,clubId:'MKT'});G.market.push(b.id)}
}
function openNext(){
 const e=curEvent();if(!e)return;
 if(e.t==='league'){const opp=leagueOpp(e.r);setPrematch({kind:'league',r:e.r,opp,fmt:5})}
 else if(e.t==='cup'){if(!G.cup)initCup(e.fmt,false);gotoCupStage()}
 else if(e.t==='draft'){if(!G.draft)initDraft();if(G.draft.picks.length<5){UI.mode='draft';music('prelude');render()}else gotoCupStage()}
}
function setPrematch(ctx){
 UI.ctx=ctx;UI.mode='prematch';music('prelude');
 if(ctx.draft){UI.sel=G.cup.teams.P.slice()}
 else{const roster=G.clubs.P.roster;let sel=(G.lineups[ctx.fmt]||[]).filter(id=>roster.includes(id)&&G.beasts[id]&&!G.beasts[id].inj).slice(0,ctx.fmt);if(sel.length<ctx.fmt){const all=roster.map(id=>G.beasts[id]).filter(b=>b&&!sel.includes(b.id)).sort((a,b)=>(a.inj?1:0)-(b.inj?1:0)||lineScore(b)-lineScore(a));sel=sel.concat(all.map(b=>b.id)).slice(0,ctx.fmt)}UI.sel=sel}
 render();window.scrollTo(0,0);
}
function initCup(fmt,draft){const ids=shuffle([...G.div]);const pairs=[];for(let i=0;i<8;i+=2)pairs.push([ids[i],ids[i+1]]);G.cup={fmt,draft,name:CUPN[draft?5:fmt],rounds:[pairs],res:[[]],ri:0,champ:null,out:false,lostIn:null,teams:draft?G.draft.teams:null};news(`The ${G.cup.name} draw is made.`,'cup')}
function gotoCupStage(){
 const c=G.cup;
 if(c.champ){UI.mode='cupdone';render();return}
 if(c.out){while(!c.champ)resolveCupRound();UI.mode='cupdone';render();return}
 const pr=c.rounds[c.ri].find(p=>p.includes('P'));
 const opp=pr[0]==='P'?pr[1]:pr[0];
 setPrematch({kind:'cup',opp,fmt:c.fmt,draft:c.draft,round:RNAME[c.ri]});
}
function resolveCupRound(){const c=G.cup,rr=c.rounds[c.ri],res=c.res[c.ri];rr.forEach((p,i)=>{if(res[i])return;res[i]=simAIMatch(p[0],p[1],c.fmt,c.draft)});if(rr.length===1){c.champ=res[0].w;return}const nx=[];for(let i=0;i<rr.length;i+=2)nx.push([res[i].w,res[i+1].w]);c.rounds.push(nx);c.res.push([]);c.ri++}
function initDraft(){
 G.draft={picks:[],offers:[],teams:{}};
 const q=TIERS[G.tier].q+4;
 G.div.forEach(cid=>{if(cid==='P')return;G.draft.teams[cid]=rosterPlan().slice(0,5).map(sp=>genBeast(q,{sp,draft:true,clubId:'DRAFT'}).id)});
 newOffers();
}
function newOffers(){const q=TIERS[G.tier].q+4;const have=G.draft.picks.map(id=>ROLE_LINE[roleOf(G.beasts[id])]);const need=['front','flank','back'].filter(l=>!have.includes(l));const sps=[];if(need.length)sps.push(pick(lineSpecies(need[0])));while(sps.length<4){const s=pick(SPK);if(!sps.includes(s))sps.push(s)}G.draft.offers=shuffle(sps).map(sp=>genBeast(q+rnd(-3,4),{sp,draft:true,clubId:'DRAFT',age:ri(1,6)}).id)}
function draftPick(id){const d=G.draft;d.picks.push(id);d.offers.filter(x=>x!==id).forEach(x=>delete G.beasts[x]);d.offers=[];if(d.picks.length<5){newOffers();save();render()}else{d.teams.P=d.picks.slice();initCup(5,true);save();gotoCupStage()}}

function startMatch(watch){
 const c=UI.ctx;
 if(UI.sel.length!==c.fmt)return;
 if(!c.draft)G.lineups[c.fmt]=UI.sel.slice();
 const A=UI.sel.map(id=>G.beasts[id]);
 const B=c.draft?G.cup.teams[c.opp].map(id=>G.beasts[id]):pickLineup(c.opp,c.fmt);
 const S=createSim(A,B,{headless:!watch});
 if(!watch){runHeadless(S);finishMatch(S);return}
 UI.mode='battle';music('battle');renderTop();renderTabs();$('#view').innerHTML=viewBattle(c,S);startBattle(S);window.scrollTo(0,0);
}
function milestonesFor(b,prev,st,out){
 const add=t=>{b.notes.push({s:G.season,d:G.day+1,t});out.push(`${b.name}: ${t}`);news(`${b.name}: ${t}.`,'mile')};
 if(prev.k===0&&b.career.k>0)add('first career takedown');
 [10,25,50,100,200,350,500].forEach(k=>{if(prev.k<k&&b.career.k>=k)add(`${k} career takedowns`)});
 [10,25,50,100,150,200].forEach(m=>{if(prev.m<m&&b.career.m>=m)add(`${m} career bouts`)});
 if(st.k>=5)add('five takedowns in a single bout');else if(st.k===4)add('four takedowns in a single bout');else if(st.k===3)add('triple takedown');
 if(b.career.k>=100&&!b.epithet){b.epithet=pick(EPITHETS);add(`now known as ${b.name} ${b.epithet}`)}
}
function setRecord(key,v,b){const r=G.records[key];if(!r||v>r.v){G.records[key]={v:Math.round(v),name:b.name,s:G.season};return true}return false}
function finishMatch(S){
 stopBattle();
 const c=UI.ctx,pWon=S.winner===0;
 const prev={};S.units.forEach(u=>{if(!u.summon){const b=G.beasts[u.bid];prev[u.bid]={k:b.career.k,m:b.career.m}}});
 const rows=recordMatch(S,{fmt:c.fmt,draft:!!c.draft});
 const mult=1+G.tier*.4;let gold=0,ren=0,label='';const mil=[],notes=[],purse=[];let upset=false;if(c.kind==='league'){const st0=standings();upset=st0.findIndex(r=>r.id===c.opp)<st0.findIndex(r=>r.id==='P')}
 rows.filter(r=>r.team===0).forEach(r=>{const b=G.beasts[r.bid];if(!b)return;milestonesFor(b,prev[r.bid],r.st,mil);if(b.traits.includes('Showboat'))ren+=r.st.k;
  if(b.clubId==='P'){if(setRecord('k',r.st.k,b)&&r.st.k>=3)notes.push(`Club record: ${r.st.k} takedowns in a bout by ${b.name}`);if(setRecord('dmg',r.st.dmg,b))notes.push(`Club record: ${fmt(r.st.dmg)} damage in a bout by ${b.name}`);if(r.st.heal>0)setRecord('heal',r.st.heal,b)}
  if(r.ups)notes.push(`${b.name} reached level ${b.lvl}`)});
 const mine=S.units.filter(u=>u.team===0&&!u.summon);
 if(pWon&&mine.filter(u=>u.alive).length===1&&mine.length>1){const u=mine.find(u=>u.alive),b=G.beasts[u.bid];b.notes.push({s:G.season,d:G.day+1,t:'last one standing in a win'});mil.push(`${b.name}: last one standing`);news(`${b.name} was the last one standing as ${G.name} edged ${G.clubs[c.opp].name}.`,'mile')}
 const ka=killsOf(S,0),kb=killsOf(S,1);
 if(c.kind==='league'){
  purse.push([pWon?'League win':'League loss',Math.round((pWon?70:30)*mult)]);ren+=pWon?3:1;label=`Matchday ${c.r+1} vs ${G.clubs[c.opp].name}`;
  G.league.res[c.r]=G.league.res[c.r]||[];G.league.res[c.r].push({a:'P',b:c.opp,w:pWon?'P':c.opp,ka,kb});
  G.league.fix[c.r].forEach(p=>{if(p.includes('P'))return;const r=simAIMatch(p[0],p[1],5,false);G.league.res[c.r].push({a:p[0],b:p[1],w:r.w,ka:r.ka,kb:r.kb})});
  G.streak=pWon?G.streak+1:0;if(G.streak>(G.records.streak?G.records.streak.v:0))G.records.streak={v:G.streak,name:G.name,s:G.season};
  news(`${pWon?'Win':'Loss'} vs ${G.clubs[c.opp].name}, ${ka}–${kb} in takedowns.`,pWon?'win':'loss');
 }else{
  const cu=G.cup,idx=cu.rounds[cu.ri].findIndex(p=>p.includes('P'));
  cu.res[cu.ri][idx]={w:pWon?'P':c.opp,ka,kb,player:true};
  label=`${cu.name} ${c.round}`;if(pWon){purse.push([`${c.round} win`,Math.round(45*mult)]);ren+=2}else{purse.push(['Cup appearance',Math.round(15*mult)]);cu.out=true;cu.lostIn=RNAME[cu.ri]}
  resolveCupRound();
  if(cu.out)while(!cu.champ)resolveCupRound();
  if(cu.champ==='P'){purse.push(['Cup champions',Math.round(160*mult)]);ren+=12;G.trophies.push({s:G.season,name:cu.name,tier:G.tier});notes.push(`${cu.name} champions`)}
  news(`${cu.name} ${c.round}: ${pWon?'beat':'lost to'} ${G.clubs[c.opp].name}.`,pWon?'win':'loss');
 }
 const tdv=Math.round(5*mult);if(ka)purse.push([`Takedown bonus (${ka} × ${tdv})`,ka*tdv]);
 if(pWon&&mine.every(u=>u.alive))purse.push(['Flawless victory',Math.round(25*mult)]);
 if(pWon&&upset)purse.push(['Upset over a higher-ranked club',Math.round(20*mult)]);
 gold=purse.reduce((s,x)=>s+x[1],0);
 rows.filter(r=>r.team===0&&r.inj).forEach(r=>notes.push(`${r.name} was injured and will miss ${r.inj} day${r.inj>1?'s':''}`));
 G.gold+=gold;G.renown+=ren;ledger(label,gold);
 UI.lvq=rows.filter(r=>r.team===0&&r.ups&&G.beasts[r.bid]&&G.beasts[r.bid].clubId==='P'&&(G.beasts[r.bid].rolls>0||(G.beasts[r.bid].awaken||[]).length)).map(r=>r.bid);UI.lvTotal=UI.lvq.length;
 UI.result={ctx:c,winner:S.winner,t:S.t,timeout:!!S.timeout,rows,gold,ren,mil,notes,ka,kb,purse};
 UI.mode='result';music(pWon?'victory':'honor');save();render();window.scrollTo(0,0);
}
function advanceLv(){while(UI.lvq&&UI.lvq.length){const b=G.beasts[UI.lvq[0]];if(b&&(b.rolls>0||(b.awaken||[]).length))break;UI.lvq.shift()}if(UI.lvq&&UI.lvq.length){render();window.scrollTo(0,0)}else{UI.mode='result';resultNext()}}
function resultNext(){
 const c=UI.result.ctx;
 if(c.kind==='league'){endDay(true);return}
 if(G.cup.champ){UI.mode='cupdone';music(G.cup.champ==='P'?'victory':'honor');render();return}
 gotoCupStage();
}
function finishCupDay(keepId){
 const cu=G.cup;
 if(keepId){const b=G.beasts[keepId];b.draft=false;b.clubId='P';b.energy=100;b.joined=`Signed after winning the ${cu.name}, Season ${G.season}`;b.notes.push({s:G.season,d:G.day+1,t:`joined the club from the ${cu.name}`});G.clubs.P.roster.push(b.id);news(`${b.name} the ${SPECIES[b.sp].n} signs with ${G.name} after the ${cu.name} triumph.`,'mile')}
 G.cupLog.push({name:cu.name,res:cu.champ==='P'?'Champions':cu.lostIn?`Lost in the ${cu.lostIn}`:'—'});
 if(cu.champ!=='P')news(`${G.clubs[cu.champ].name} won the ${cu.name}.`,'cup');
 if(cu.draft)Object.keys(G.beasts).forEach(id=>{if(G.beasts[id].draft)delete G.beasts[id]});
 G.cup=null;G.draft=null;
 endDay(false);
}
function endDay(league){
 G.div.forEach(cid=>G.clubs[cid].roster.forEach(id=>{const b=G.beasts[id];if(!b)return;const f=b.fat||0;b.energy=Math.min(100,Math.round(b.energy+(b._played?14:30)*(1-f/160)));b.fat=Math.max(0,f-(b._played?1:6));if(b.inj>0&&!b._injToday){b.inj--;if(!b.inj&&cid==='P')news(`${b.name} is fit again.`,'')}b._injToday=false;b._played=false}));
 if(league){const up=playerUpkeep();G.gold-=up;ledger('Kennel upkeep',-up);refreshMarket(false)}
 G.day++;
 if(G.day>=G.sched.length){UI.seasonSum=endSeason();UI.mode='season';music(UI.seasonSum.pos<=2||UI.seasonSum.move===1?'victory':'honor')}else{UI.mode='hub';UI.tab='club';music(null)}
 save();render();window.scrollTo(0,0);
}
function snapshot(b,why){return{name:b.name,epithet:b.epithet,sp:b.sp,career:Object.assign({},b.career),titles:b.titles.slice(),joined:b.joined,left:why,peak:b.peak||ovr(b),notes:b.notes.slice(-6)}}
function removeFromPlayer(b){Object.keys(b.gear||{}).forEach(sl=>{if(b.gear[sl]){G.stash.push(b.gear[sl]);b.gear[sl]=null}});const c=G.clubs.P;c.roster=c.roster.filter(x=>x!==b.id);[2,3,5].forEach(f=>G.lineups[f]=G.lineups[f].filter(x=>x!==b.id));Object.keys(G.bonds).forEach(k=>{if(k.split('|').includes(b.id))delete G.bonds[k]})}
function retire(b,cid){if(cid==='P'){G.alumni.unshift(snapshot(b,`Retired after Season ${G.season}`));removeFromPlayer(b);news(`${b.name} retires after ${b.career.m} bouts and ${b.career.k} takedowns.`,'mile')}else{const c=G.clubs[cid];c.roster=c.roster.filter(x=>x!==b.id)}delete G.beasts[b.id]}
function removeClub(id){const c=G.clubs[id];if(!c)return;c.roster.forEach(x=>delete G.beasts[x]);delete G.clubs[id]}
function endSeason(){
 const st=standings(),pos=st.findIndex(r=>r.id==='P')+1,me=st[pos-1];
 const divB=[];G.div.forEach(cid=>G.clubs[cid].roster.forEach(id=>{const b=G.beasts[id];if(b)divB.push(b)}));
 const award=(key,label)=>{const top=divB.slice().sort((a,b)=>b.season[key]-a.season[key])[0];if(!top||top.season[key]<=0)return null;top.titles.push(`Season ${G.season} ${label}, ${TIERS[G.tier].n}`);if(top.clubId==='P'){news(`${top.name} named ${label} of the ${TIERS[G.tier].n}.`,'mile');top.notes.push({s:G.season,d:17,t:`named ${label}`});if(!top.epithet)top.epithet=pick(EPITHETS)}return{name:top.name,club:G.clubs[top.clubId].name,mine:top.clubId==='P',v:top.season[key],label,key,sp:top.sp}};
 const awards=[award('imp','Most Valuable'),award('k','Top Slayer'),award('tank','Iron Wall'),award('heal','Lifebinder')].filter(Boolean);
 if(st[0].id==='P')G.trophies.push({s:G.season,name:`${TIERS[G.tier].n} Champions`,tier:G.tier});
 const prize=Math.round([500,400,320,260,200,160,120,100][pos-1]*(1+G.tier*.5)),renown=[25,18,12,8,5,3,1,0][pos-1];
 G.gold+=prize;G.renown+=renown;ledger(`Season ${G.season} prize`,prize);
 const myB=G.clubs.P.roster.map(id=>G.beasts[id]).filter(Boolean);
 const mvp=myB.slice().sort((a,b)=>b.season.imp-a.season.imp)[0];
 let move=0;if(pos<=2&&G.tier<3)move=1;else if(pos>=7&&G.tier>0)move=-1;
 G.history.unshift({s:G.season,tier:G.tier,pos,w:me.w,l:me.l,pts:me.pts,cups:G.cupLog.slice(),mvp:mvp?mvp.name:'—',move});
 const sum={s:G.season,tier:G.tier,pos,st:st.map(r=>Object.assign({},r,{name:G.clubs[r.id].name,hue:G.clubs[r.id].hue})),awards,move,prize,renown,retired:[],cups:G.cupLog.slice()};
 G.div.forEach(cid=>{G.clubs[cid].roster.slice().forEach(id=>{const b=G.beasts[id];if(!b)return;b.age++;b.seasons=(b.seasons||0)+1;if(b.age>=7)ATTR.forEach(k=>b.attrs[k]=Math.max(8,Math.round((b.attrs[k]-rnd(1,3.5))*10)/10));if(b.age>=10||(b.age>=8&&Math.random()<.25)){if(cid==='P')sum.retired.push(b.name);retire(b,cid)}})});
 const ai=st.map(r=>r.id).filter(id=>id!=='P');
 if(move!==0){ai.forEach(removeClub);G.tier+=move;G.div=['P'];for(let i=0;i<7;i++)G.div.push(makeAIClub(G.tier))}
 else{const out=[...st.slice(0,2),...st.slice(6)].map(r=>r.id).filter(id=>id!=='P');out.forEach(removeClub);G.div=G.div.filter(id=>!out.includes(id));while(G.div.length<8)G.div.push(makeAIClub(G.tier))}
 G.div.forEach(cid=>{if(cid==='P')return;const c=G.clubs[cid];while(c.roster.length<8){const b=genBeast(TIERS[G.tier].q+c.str,{clubId:cid,prospect:Math.random()<.5});aiGear(b,G.tier);c.roster.push(b.id)}});
 const pc=G.clubs.P;while(pc.roster.length<5){const b=genBeast(TIERS[G.tier].q-4,{clubId:'P',prospect:true,joined:`Stable-bred, Season ${G.season+1}`});pc.roster.push(b.id);news(`The stable master brings up ${b.name}, a young ${SPECIES[b.sp].n}, to fill the roster.`,'season')}
 if(move===1)news(`Promoted to the ${TIERS[G.tier].n}!`,'mile');if(move===-1)news(`Relegated to the ${TIERS[G.tier].n}.`,'loss');
 G.season++;startSeason();
 return sum;
}

/* ============ PIXEL SPRITES ============ */
const LW=640,LH=370,SW=84,SH=78,OX=42,OY=72,SC0=1.35;
const HOVER={phoenix:5,harpy:4,thunderbird:6};
const FLY=new Set(['phoenix','harpy','griffin','wyvern','pegasus','gargoyle','thunderbird']);
const FR=['i0','i1','w0','w1','w2','w3','w4','w5','a1','a2','c'];
function poseOf(f){if(f[0]==='i')return{ph:null,bob:f==='i1'?1:0,atk:0,cast:0,fl:f==='i0'?1:-1};if(f[0]==='w'){const ph=(+f[1])/6*Math.PI*2;return{ph,bob:0,atk:0,cast:0,fl:Math.sin(ph)}}if(f==='a1')return{ph:null,bob:0,atk:1,cast:0,fl:1};if(f==='a2')return{ph:null,bob:0,atk:2,cast:0,fl:-1};return{ph:null,bob:0,atk:0,cast:1,fl:1}}
const pE=(g,x,y,rx,ry,c,rot)=>{g.fillStyle=c;g.beginPath();g.ellipse(x,y,Math.max(.5,rx),Math.max(.5,ry),rot||0,0,Math.PI*2);g.fill()};
const pR=(g,x,y,w,h,c)=>{g.fillStyle=c;g.fillRect(x,y,w,h)};
const pP=(g,pts,c)=>{g.fillStyle=c;g.beginPath();pts.forEach(([x,y],i)=>i?g.lineTo(x,y):g.moveTo(x,y));g.closePath();g.fill()};
const pL=(g,x1,y1,x2,y2,w,c)=>{g.strokeStyle=c;g.lineWidth=w;g.lineCap='round';g.beginPath();g.moveTo(x1,y1);g.lineTo(x2,y2);g.stroke()};
function pLeg(g,x,y,len,a,w,c,foot){const fx=x+Math.sin(a)*len,fy=y+Math.cos(a)*len;pL(g,x,y,fx,fy,w,c);if(foot)pE(g,fx+.6,fy-.2,w*.7,w*.45,foot);return[fx,fy]}
function pArm(g,x,y,a,len,w,c){const ex=x+Math.sin(a)*len,ey=y+Math.cos(a)*len;pL(g,x,y,ex,ey,w,c);return[ex,ey]}
function wingShape(g,x,y,ang,sz,c1,c2){g.save();g.translate(x,y);g.rotate(ang);g.scale(sz,sz);pP(g,[[0,0],[-5,-8],[-11,-11],[-15,-9],[-13,-6],[-14,-3],[-9,-2],[-10,0],[-4,1]],c1);pP(g,[[-2,-1],[-6,-6],[-11,-8],[-12,-5],[-7,-2]],c2);g.restore()}
function flapA(p){return p.fl>0?.35:-.7}
function snoutHead(g,x,y,p,o){
 const h=o.hd,c=o.c,ny=y+(p.atk===2?1:p.atk===1?-1:0)+(p.cast?-1:0);
 if(h.mane)pE(g,x-.5,ny,h.r+2.4,h.r+2.2,h.mane);
 pE(g,x-1,ny+1,h.r*.8,h.r*.9,c.b);
 if(h.ear==='point')pP(g,[[x-1.5,ny-h.r*.4],[x-.2,ny-h.r-3.2],[x+1.6,ny-h.r*.5]],c.s);
 if(h.ear==='round')pE(g,x-.5,ny-h.r*.85,1.6,1.7,c.s);
 pE(g,x+1.5,ny,h.r,h.r*.85,c.b);
 pP(g,[[x+h.r*.6,ny-h.r*.55],[x+h.r+h.sn,ny-h.snH*.3],[x+h.r+h.sn,ny+h.snH*.5],[x+h.r*.4,ny+h.r*.55]],c.b);
 pE(g,x+h.r*.4,ny-h.r*.45,h.r*.5,h.r*.25,c.l);
 if(p.atk===2){pP(g,[[x+h.r*.5,ny+h.r*.35],[x+h.r+h.sn-.5,ny+h.snH*.5+2.4],[x+h.r*.5,ny+h.r*.9]],c.s);pR(g,x+h.r+.6,ny+h.snH*.5,h.sn-1.4,1,'#7a1e24')}
 pR(g,x+h.r+h.sn-1.3,ny-h.snH*.3,1.4,1.3,h.nose||'#1a1418');
 pR(g,x+h.r*.85,ny-h.r*.4,1.3,1.3,h.eye||'#f4d35e');
 if(h.horn)h.horn(g,x,ny,p,o);
}
function eagleHead(g,x,y,p){const ny=y+(p.atk===2?1.5:p.atk===1?-1.5:0)+(p.cast?-1:0);pE(g,x-1,ny+1,3.4,3.8,'#efe9dc');pE(g,x+1.5,ny-1,3.6,3.2,'#efe9dc');pP(g,[[x-1,ny-3.5],[x-3,ny-7],[x+1,ny-4.5]],'#d8d0c0');pP(g,[[x+4,ny-2],[x+8.5,ny-.5],[x+8,ny+1.5],[x+6.5,ny+.5],[x+4,ny+1]],'#e0a832');if(p.atk===2)pR(g,x+5,ny+.6,3,1,'#7a1e24');pR(g,x+3,ny-2.4,1.3,1.3,'#1a1418')}
function tailBushy(g,x,y,p,o){const w=(p.ph!=null?Math.sin(p.ph*2)*.25:0)+(p.bob?.12:0);g.save();g.translate(x,y);g.rotate(-.55+w);pE(g,-4,0,5,2.3,o.c.b);pE(g,-7.5,0,2,1.6,o.c.l);g.restore()}
function tailFox(g,x,y,p,o){[-1,-.55,-.1].forEach((a,i)=>{const w=(p.ph!=null?Math.sin(p.ph*2+i)*.2:0)+(p.bob?.1:0);g.save();g.translate(x,y);g.rotate(a+w);pE(g,-5,0,5.5,2.2,i===1?o.c.s:o.c.b);pE(g,-9.5,0,2,1.8,'#f3eee6');g.restore()})}
function tailScorp(g,x,y,p){const pts=[[0,0],[-3,-2],[-5,-6],[-4,-10],[-1,-13],[3,-13.5]];if(p.atk===2){pts[4]=[2,-12];pts[5]=[7,-9]}if(p.atk===1){pts[4]=[-3,-14];pts[5]=[0,-16]}pts.forEach(([a,b],i)=>pE(g,x+a,y+b,2.3-i*.18,2.1-i*.18,i%2?'#5a2640':'#7a3a58'));const[a,b]=pts[5];pP(g,[[x+a,y+b-1.5],[x+a+4,y+b+1],[x+a,y+b+1.5]],'#e8dcc0')}
function tailLizard(g,x,y,p,o){const w=p.ph!=null?Math.sin(p.ph)*1.5:0;pP(g,[[x+2,y-2],[x-13,y+3+w],[x-14,y+4+w],[x+2,y+3]],o.c.b);pP(g,[[x+1,y+1],[x-12,y+3.5+w],[x+1,y+3]],o.c.s)}
function tailFlow(c1,c2){return(g,x,y,p)=>{const w=p.ph!=null?Math.sin(p.ph*2)*.3:0;g.save();g.translate(x,y);g.rotate(.5+w);pE(g,-1,4,2.2,5,c1);pE(g,-1.5,6,1.2,3,c2);g.restore()}}
function maneFn(c1,c2){return(g,bx,by,p,o)=>{const x=bx+o.len*.36,y=by-o.h*.35;for(let i=0;i<4;i++)pE(g,x-i*2.2,y-1+i*.6,2,2.6,i%2?c2:c1)}}
function spineCrest(g,bx,by,p,o){for(let i=0;i<5;i++){const x=bx-o.len*.3+i*3,y=by-o.h*.42;pP(g,[[x-1.2,y+1],[x,y-3-(i%2)],[x+1.2,y+1]],'#b53a2a')}}
function hornGold(g,x,y){pL(g,x+2.5,y-2.5,x+6,y-9.5,1.6,'#f3d77a');pR(g,x+4,y-6,1,1,'#fff2b8')}
function quad(g,p,o){
 const s=p.ph!=null?Math.sin(p.ph)*.6:0,up=p.ph!=null?Math.abs(Math.sin(p.ph))*.8:0;
 const dx=p.atk===1?-1.5:p.atk===2?2.5:0,by=-o.leg-o.h*.35-up+(p.bob?.6:0);
 g.save();
 if(p.cast){g.translate(-o.len*.35,-o.leg*.3);g.rotate(-.28);g.translate(o.len*.35,o.leg*.3)}
 const bx=dx,hf={x:bx+o.len*.3,y:by+o.h*.25},hb={x:bx-o.len*.3,y:by+o.h*.25},lw=o.lw||2.4,ll=o.leg+o.h*.1;
 pLeg(g,hf.x+1.5,hf.y,ll,-s*.9,lw,o.c.s,o.c.f);pLeg(g,hb.x+1.5,hb.y,ll,s*.9,lw,o.c.s,o.c.f);
 if(o.tail)o.tail(g,bx-o.len*.45,by-o.h*.1,p,o);
 if(o.farWing)o.farWing(g,bx,by-o.h*.3,p,o);
 pE(g,bx,by,o.len/2,o.h/2,o.c.b);
 pE(g,bx+o.len*.05,by+o.h*.22,o.len*.36,o.h*.24,o.c.belly||o.c.s);
 pE(g,bx-o.len*.05,by-o.h*.22,o.len*.32,o.h*.15,o.c.l);
 if(o.back)o.back(g,bx,by,p,o);
 pLeg(g,hf.x,hf.y,ll,s*.9,lw,o.c.b,o.c.f);pLeg(g,hb.x,hb.y,ll,-s*.9,lw,o.c.b,o.c.f);
 o.head(g,bx+o.len*.42,by-o.h*.25,p,o);
 if(o.wing)o.wing(g,bx,by-o.h*.3,p,o);
 g.restore();
}
function biped(g,p,o){
 const s=p.ph!=null?Math.sin(p.ph)*.55:0,up=p.ph!=null?Math.abs(Math.sin(p.ph))*.8:0;
 const lean=(p.atk===1?-.15:p.atk===2?.22:0)+(o.hunch||0)+(p.cast?-.12:0),hy=-o.leg-up+(p.bob?.6:0);
 pLeg(g,1.5,hy,o.leg,s,o.lw,o.c.s,o.c.f);
 const arms=p.cast?[-2.7,-2.5]:p.atk===1?[.4,-2.5]:p.atk===2?[-.3,1.3]:[-s*.9,s*.9+(p.bob?.06:0)];
 const sy=-o.th*.85;
 g.save();g.translate(0,hy);g.rotate(lean);if(o.arm)o.arm(g,-1,sy,arms[0],false,p,o);g.restore();
 pLeg(g,-1,hy,o.leg,-s,o.lw,o.c.b,o.c.f);
 g.save();g.translate(0,hy);g.rotate(lean);o.torso(g,p,o);o.head(g,o.hx!=null?o.hx:1.5,-o.th-(o.hy!=null?o.hy:1),p,o);if(o.arm)o.arm(g,1,sy,arms[1],true,p,o);g.restore();
}
function torsoE(g,p,o){pE(g,0,-o.th/2,o.tw/2,o.th/2,o.c.b);pE(g,1,-o.th*.55,o.tw*.3,o.th*.25,o.c.l);if(o.belt)pR(g,-o.tw/2+1,-3,o.tw-2,2.5,o.belt)}
function armStd(len,w,hand){return(g,x,y,a,near,p,o)=>{const c=near?o.c.b:o.c.s;const[ex,ey]=pArm(g,x,y,a,len,w,c);if(hand)hand(g,ex,ey,a,near,p,o);else pE(g,ex,ey,w*.6,w*.6,c)}}
function axe(g,x,y,a){const d=a+.6,dx=Math.sin(d),dy=Math.cos(d),ex=x+dx*8,ey=y+dy*8,nx=dy,ny=-dx;pL(g,x-dx*2,y-dy*2,ex,ey,1.3,'#6b4a2a');pP(g,[[ex+nx*3.5,ey+ny*3.5],[ex+dx*2.2+nx*1.5,ey+dy*2.2+ny*1.5],[ex-nx*.8,ey-ny*.8],[ex-dx*2.2+nx*1.5,ey-dy*2.2+ny*1.5]],'#c3c7cf');pL(g,ex+nx*3,ey+ny*3,ex+nx*1.5+dx*1.8,ey+ny*1.5+dy*1.8,.7,'#eef0f4')}
function bullHead(g,x,y,p){const ny=y+(p.atk===2?1:0);pE(g,x,ny,3.6,3.8,'#6a3e25');pE(g,x+2.5,ny+1.5,2.6,2,'#b98a68');pR(g,x+3.8,ny+.8,1,1,'#2a1a12');pR(g,x+1.2,ny-1.5,1.3,1.3,'#ff5a3d');pP(g,[[x-2,ny-2],[x-5,ny-4],[x-5.5,ny-7.5],[x-3.5,ny-4.5],[x-1,ny-3.5]],'#e8dcc0');pP(g,[[x+.5,ny-3],[x+2.5,ny-5.5],[x+2.5,ny-8.5],[x+4.5,ny-5],[x+2.5,ny-2.5]],'#e8dcc0');pE(g,x+3,ny+3.2,1.1,.9,'#f3d77a')}
const RIG={
 direwolf:(g,p)=>quad(g,p,{len:15,h:8,leg:6,lw:2.2,c:{b:'#7b7f8c',s:'#545866',l:'#a3a7b3',belly:'#959aa6',f:'#3b3e48'},hd:{r:3.6,sn:4,snH:3,ear:'point',eye:'#f4d35e'},head:snoutHead,tail:tailBushy}),
 kitsune:(g,p)=>quad(g,p,{len:13,h:7,leg:5.5,lw:2,c:{b:'#e07a34',s:'#b1561f',l:'#f4a060',belly:'#f3eee6',f:'#3a2418'},hd:{r:3.3,sn:3.4,snH:2.3,ear:'point',eye:'#ffe27a'},head:snoutHead,tail:tailFox}),
 manticore:(g,p)=>quad(g,p,{len:17,h:9,leg:6,lw:2.6,c:{b:'#c08a3e',s:'#8e6128',l:'#dcae62',f:'#5a3a1a'},hd:{r:3.8,sn:2.4,snH:3,ear:'round',eye:'#ff6b3d',mane:'#7a3b22'},head:snoutHead,tail:tailScorp}),
 griffin:(g,p)=>quad(g,p,{len:16,h:9,leg:6,lw:2.4,c:{b:'#c29a5a',s:'#8f6c38',l:'#e0bf82',f:'#e0a832'},head:eagleHead,farWing:(g,x,y,p)=>wingShape(g,x+1,y,flapA(p)-.15,1,'#6e5234','#8a6a44'),wing:(g,x,y,p)=>wingShape(g,x-1,y+1,flapA(p),1.05,'#8a6a44','#b99466')}),
 unicorn:(g,p)=>quad(g,p,{len:17,h:9,leg:8,lw:2,c:{b:'#eeeaf2',s:'#c7c1d2',l:'#ffffff',f:'#8b7fa0'},hd:{r:3.3,sn:4.2,snH:3.2,ear:'point',eye:'#5a4a7a',nose:'#b7a9c9',horn:hornGold},head:snoutHead,back:maneFn('#b79bd8','#d8c4f0'),tail:tailFlow('#b79bd8','#d8c4f0')}),
 kirin:(g,p)=>quad(g,p,{len:17,h:9,leg:8,lw:2,c:{b:'#8fb8e0',s:'#5f86b3',l:'#c7ddf5',f:'#f2f5ff'},hd:{r:3.3,sn:4,snH:3,ear:'point',eye:'#fff27a',nose:'#3b5680',horn:hornGold},head:snoutHead,back:maneFn('#f2f5ff','#fff6a8'),tail:tailFlow('#f2f5ff','#fff6a8')}),
 basilisk:(g,p)=>quad(g,p,{len:20,h:7,leg:4,lw:2.6,c:{b:'#7f8f3a',s:'#58651f',l:'#a3b35a',belly:'#c9c47a',f:'#3a4015'},hd:{r:3.3,sn:5,snH:2.6,ear:'none',eye:'#ffe600'},head:snoutHead,back:spineCrest,tail:tailLizard}),
 minotaur:(g,p)=>biped(g,p,{leg:8,lw:3.2,tw:11,th:12,c:{b:'#7a4a2e',s:'#55301c',l:'#9b6440',f:'#2a1a12'},belt:'#a8322d',torso:torsoE,head:bullHead,arm:armStd(7,3,(g,x,y,a,near)=>{pE(g,x,y,2,2,near?'#7a4a2e':'#55301c');if(near)axe(g,x,y,a)})}),
 golem:(g,p)=>biped(g,p,{leg:7,lw:4.6,tw:15,th:13,hy:-1,c:{b:'#7d8494',s:'#596070',l:'#a2a9b6',f:'#3e4350'},torso:(g,p,o)=>{pR(g,-7.5,-13,15,13,o.c.b);pR(g,-6,-12,8,4,o.c.l);pR(g,-7.5,-3,15,3,o.c.s);pR(g,2,-10,3,2,'#6f9a4a');pR(g,-5,-6,2,2,'#6f9a4a');pL(g,-1,-9,1,-5,1,'#8fd3ff')},head:(g,x,y)=>{pR(g,x-3,y-3,7,6,'#7d8494');pR(g,x-2,y-3,4,2,'#a2a9b6');pR(g,x+1,y,1.5,1,'#8fd3ff');pR(g,x+3,y,1,1,'#8fd3ff')},arm:armStd(8,4.2,(g,x,y,a,near)=>pR(g,x-2.5,y-2.5,5,5,near?'#7d8494':'#596070'))}),
 troll:(g,p)=>biped(g,p,{leg:7,lw:3.6,tw:13,th:13,hunch:.25,c:{b:'#6f8f4a',s:'#4f6a33',l:'#8fae62',f:'#3a4a22'},belt:'#6b4a2a',torso:torsoE,hx:4,hy:-2,head:(g,x,y,p)=>{pE(g,x,y,3.4,3.2,'#6f8f4a');pE(g,x+3,y+.5,1.8,1.5,'#8fae62');pR(g,x+.5,y-1.5,1.2,1.2,'#ffde59');pR(g,x+1.5,y+2,1,1.6,'#eee3c4');pR(g,x+3.5,y+2,1,1.4,'#eee3c4');if(p.atk===2)pR(g,x+1.5,y+2.2,3,.8,'#3a1a14')},arm:armStd(8,3,(g,x,y,a,near)=>{pE(g,x,y,2,2,near?'#6f8f4a':'#4f6a33');if(near){const d=a+.6,ex=x+Math.sin(d)*9,ey=y+Math.cos(d)*9;pL(g,x,y,ex,ey,2,'#6b4a2a');pE(g,ex,ey,2.5,2.5,'#5a3d22');pR(g,ex-.5,ey-1.5,1,1,'#8a6a44')}})}),
 wendigo:(g,p)=>biped(g,p,{leg:11,lw:2.2,tw:8,th:13,hunch:.12,c:{b:'#3b3f47',s:'#2a2d33',l:'#555b66',f:'#cfd6d8'},torso:(g,p,o)=>{torsoE(g,p,o);for(let i=0;i<3;i++)pR(g,-2+i*2,-9+i*.5,1,3,'#cfd6d8')},hx:2,hy:0,head:(g,x,y)=>{pL(g,x-1,y-2,x-4,y-9,1.2,'#6e5a45');pL(g,x-3,y-6,x-6,y-7,1,'#6e5a45');pL(g,x+1,y-2,x+3,y-9,1.2,'#6e5a45');pL(g,x+2.5,y-6,x+5,y-7.5,1,'#6e5a45');pE(g,x+1,y,3,3.2,'#e6e2d6');pP(g,[[x+2,y-1],[x+6,y+1],[x+2,y+3]],'#e6e2d6');pR(g,x+1.5,y-1,1.3,1.3,'#7ff0ff')},arm:armStd(9,2,(g,x,y,a)=>{const d=a+.3;for(let i=-1;i<=1;i++)pL(g,x,y,x+Math.sin(d+i*.3)*3.5,y+Math.cos(d+i*.3)*3.5,.8,'#cfd6d8')})}),
 treant:(g,p)=>biped(g,p,{leg:8,lw:4,tw:13,th:15,c:{b:'#6b4c32',s:'#4a321f',l:'#8a6848',f:'#3a2616'},torso:(g,p,o)=>{pE(g,0,-7.5,6.5,7.5,o.c.b);pL(g,-2,-13,-1,-3,1,o.c.s);pL(g,2,-12,2.5,-4,1,o.c.s);pR(g,1,-10,1.3,1.3,'#ffb347');pR(g,3.5,-10,1.3,1.3,'#ffb347')},hx:0,hy:1,head:(g,x,y,p)=>{[[0,-3,6,4,'#4f8a35'],[-4,-1,4,3,'#5f9a3f'],[4,-1,4,3,'#5f9a3f'],[-1,-6,4.5,3,'#86c25a'],[3,-4,3,2.5,'#86c25a']].forEach(([a,b,rx,ry,c])=>pE(g,x+a,y+b-(p.bob?.5:0),rx,ry,c))},arm:armStd(9,2.6,(g,x,y,a,near)=>{pL(g,x,y,x+Math.sin(a+.8)*3,y+Math.cos(a+.8)*3,1.2,'#6b4c32');pE(g,x,y,2.4,2,near?'#5f9a3f':'#4f8a35')})}),
 harpy:(g,p)=>biped(g,p,{leg:7,lw:1.5,tw:8,th:9,c:{b:'#6d5a8f',s:'#4c3e66',l:'#8f7bb3',f:'#e0a832'},torso:torsoE,hx:1.5,hy:1,head:(g,x,y,p)=>{pE(g,x-1,y+1,3,3.6,'#2c2338');pE(g,x+.5,y,2.6,2.8,'#d7b08c');pR(g,x+1.5,y-.8,1.2,1.2,'#2c2338');pP(g,[[x-3,y-2],[x-7,y+2+(p.bob?1:0)],[x-2,y+2]],'#2c2338')},arm:(g,x,y,a,near,p)=>wingShape(g,x,y+1,flapA(p)+(near?0:-.2),near?.85:.8,near?'#6d5a8f':'#4c3e66',near?'#a08cc4':'#6d5a8f')}),
 naga:(g,p)=>{const w=p.ph!=null?Math.sin(p.ph):0,sw=p.bob?.5:0;
  pE(g,-6,-2.5,6,2.6,'#1f6660');pE(g,2,-2.5,7,2.8,'#2f8f86');pE(g,-3+w,-5.5,6,2.6,'#2f8f86');pE(g,-9,-1.5-w*.5,3.5,1.6,'#1f6660');pE(g,1,-3.3,5,1,'#5fc2b8');
  const lean=p.atk===1?-.2:p.atk===2?.25:p.cast?-.15:0;g.save();g.translate(2,-6-sw);g.rotate(lean);
  pE(g,0,-3,3.2,4,'#2f8f86');pE(g,.5,-8,3,4,'#c89a7a');pR(g,-2.5,-9,5.5,1.6,'#e0a832');
  pE(g,.5,-14,2.8,3,'#c89a7a');pE(g,-1.2,-14.5,2.6,3.4,'#2a2a3a');pP(g,[[-3,-15],[-6,-9],[-2,-11]],'#2a2a3a');pR(g,2,-14.5,1.2,1.2,'#1a1418');
  const a=p.cast?-2.6:p.atk===1?-2.2:p.atk===2?1.2:.3;const[ex,ey]=pArm(g,2,-9,a,5,1.6,'#c89a7a');
  const d=a+.9,tx=ex+Math.sin(d)*9,ty=ey+Math.cos(d)*9,bx=ex-Math.sin(d)*4,by=ey-Math.cos(d)*4,nx=Math.cos(d),ny=-Math.sin(d);
  pL(g,bx,by,tx,ty,1,'#e0a832');[-1,0,1].forEach(k=>pL(g,tx+nx*k*1.5,ty+ny*k*1.5,tx+Math.sin(d)*2.5+nx*k*1.5,ty+Math.cos(d)*2.5+ny*k*1.5,.8,'#f3d77a'));
  g.restore()},
 wyvern:(g,p)=>{const s=p.ph!=null?Math.sin(p.ph)*.55:0,up=p.ph!=null?Math.abs(Math.sin(p.ph))*.8:0,by=-9-up+(p.bob?.5:0),c={b:'#4f8a5a',s:'#35623e',l:'#7fb888'};
  pLeg(g,1,by+2,7,s,2.4,c.s,'#2a3a22');
  wingShape(g,0,by-3,flapA(p)-.2,1.15,'#2d4f35','#3d6a47');
  const w=p.ph!=null?Math.sin(p.ph)*1.5:0;pP(g,[[-4,by-1],[-17,by+4+w],[-18,by+5+w],[-4,by+3]],c.b);pP(g,[[-16,by+3.5+w],[-19.5,by+2+w],[-18.5,by+6.5+w]],c.s);
  pE(g,0,by,8,5,c.b);pE(g,1,by+2,5.5,2.5,'#c8c07a');pE(g,-1,by-2,5,1.8,c.l);
  pLeg(g,-1,by+2,7,-s,2.4,c.b,'#2a3a22');
  const hx=p.atk===2?12:p.atk===1?7:9,hy=by-(p.atk===2?7:p.cast?12:10);
  pL(g,5,by-2,hx,hy+1,3.2,c.b);
  snoutHead(g,hx,hy,p,{c,hd:{r:2.8,sn:4,snH:2.2,ear:'none',eye:'#ffe600',horn:(g,x,y)=>pL(g,x-1,y-2,x-4,y-5,1,'#e8dcc0')}});
  wingShape(g,0,by-2,flapA(p),1.2,'#4f8a5a','#6fae78')},
 phoenix:(g,p)=>{const y=-9+(p.bob?1:0),ang=flapA(p),tl=p.ph!=null?Math.sin(p.ph*2):(p.bob?1:0);
  [['#d9482b',0],['#f08a2a',2],['#ffd35a',4]].forEach(([c,i])=>pP(g,[[-2,y],[-11-i,y+3+i+tl],[-9-i,y+5+i*.8+tl],[-3,y+2]],c));
  wingShape(g,0,y-1,ang-.25,1.05,'#a3321f','#d9482b');
  const tilt=p.atk===2?.3:p.atk===1?-.2:0;g.save();g.translate(0,y);g.rotate(tilt);
  pE(g,0,0,5,3.8,'#d9482b');pE(g,1,1.5,3.2,2,'#ffb347');pE(g,4.5,-3,2.8,2.6,'#d9482b');
  pP(g,[[3,-5],[2,-9],[4.5,-6],[5,-10],[6,-5.5]],'#ffd35a');pP(g,[[6.5,-3.5],[9.5,-2.5],[6.5,-1.5]],'#ffd35a');pR(g,5,-4,1.2,1.2,'#1a1418');
  g.restore();wingShape(g,0,y,ang,1.15,'#f08a2a','#ffd35a')}
};
function tailTuft(g,x,y,p,o){const w=p.ph!=null?Math.sin(p.ph*2)*1.5:0;pL(g,x,y,x-6,y+3+w,1.2,o.c.s);pE(g,x-6.5,y+3.5+w,1.7,1.7,o.tuft||'#6a3a1a')}
function tailSnake(g,x,y,p){const w=p.ph!=null?Math.sin(p.ph*2)*1.5:0;pL(g,x,y,x-5,y-3+w,1.7,'#4f7a3a');pL(g,x-5,y-3+w,x-8,y-7,1.7,'#4f7a3a');pE(g,x-8.5,y-7.5,1.9,1.5,'#5f8f45');pR(g,x-9.5,y-8.5,1,1,'#ffe600');if(p.atk===2)pL(g,x-10,y-7,x-12,y-6,.7,'#d9362b')}
function tailPuff(g,x,y){pE(g,x,y,2.2,2.2,'#f3eee6')}
function tailTwin(g,x,y,p,o){[-1.15,-.65].forEach((a,i)=>{const w=p.ph!=null?Math.sin(p.ph*2+i)*.25:(p.bob?.08:0);g.save();g.translate(x,y);g.rotate(a+w);pL(g,0,0,-9,0,1.5,o.c.b);pE(g,-10,0,1.9,1.9,'#b86bff');pR(g,-10.5,-2.8,1,1.6,'#e0b0ff');g.restore()})}
function tailFlame(g,x,y,p,o){tailLizard(g,x,y,p,o);const w=p.ph!=null?Math.sin(p.ph)*1.5:0,k=p.bob?1:0;pP(g,[[x-12,y+3+w],[x-16,y+1+w-k],[x-15,y+5+w]],'#ffb030')}
function flameCrest(g,bx,by,p,o){const k=p.bob?1:0;for(let i=0;i<5;i++){const x=bx-o.len*.3+i*3,y=by-o.h*.42,hh=3+((i+k)%2)*1.5;pP(g,[[x-1.3,y+1],[x,y-hh],[x+1.3,y+1]],i%2?'#ffb030':'#ff5a2a')}}
function shellBack(g,bx,by,p,o){pE(g,bx-1,by-2,o.len*.55,o.h*.8,'#6b5a3a');pE(g,bx-2,by-4,o.len*.42,o.h*.5,'#8a7650');[[-6,-5],[-1,-6.5],[4,-5],[-3,-2],[2,-2]].forEach(([a,b])=>pR(g,bx+a-1,by+b,2.6,1.6,'#5a4a2e'));pE(g,bx+2,by-8,2.2,1,'#6f9a4a');pE(g,bx-7,by-6.5,1.6,1,'#6f9a4a')}
function goatBack(g,bx,by,p,o){const x=bx+1,y=by-o.h*.62-(p.atk===2?1:0);pE(g,x,y,2.3,2.5,'#9a9a9a');pE(g,x+1.5,y+.8,1.6,1.2,'#b8b8b8');pL(g,x-1,y-1.5,x-3,y-4,1,'#5a5048');pL(g,x-3,y-4,x-1.5,y-5,1,'#5a5048');pR(g,x+.8,y-.8,1,1,'#ffe600')}
function sphinxWings(g,bx,by){wingShape(g,bx+1,by-3,.15,.72,'#c8a050','#e8c878')}
function cerbHead(g,x,y,p,o){const hd={r:3.1,sn:3.3,snH:2.5,ear:'point',eye:'#ff3b2a'};snoutHead(g,x-3,y-4.5,p,{c:{b:o.c.s,s:'#141114',l:o.c.b},hd});snoutHead(g,x+1,y-1.5,p,{c:o.c,hd});snoutHead(g,x-1.5,y+2.5,p,{c:o.c,hd});for(let i=0;i<3;i++)pR(g,x-5+i*2,y+.5-i*.3,1,1.4,'#c8c8c8');pR(g,x-5.5,y+1.4,6,1.2,'#8a2a2a')}
function hydraHeads(g,x,y,p,o){const sw=p.ph!=null?Math.sin(p.ph):(p.bob?.6:0),k=p.atk===2?3:p.atk===1?-2:0;[[-4,-10,o.c.s],[1,-12.5,o.c.b],[5,-8,o.c.b]].forEach(([dx,dy,c],i)=>{const hx=x+dx+(i===2?k:k*.5),hy=y+dy+(i===1?sw:-sw*.6)+(p.cast?-2:0);pL(g,x-1,y+1,hx-1,hy+1,2.4,c);snoutHead(g,hx,hy,p,{c:{b:c,s:o.c.s,l:o.c.l},hd:{r:2.3,sn:2.6,snH:1.8,ear:'none',eye:'#ffe600'}})})}
function sphinxHead(g,x,y,p){const ny=y-1+(p.atk===2?1:p.atk===1?-1:0)+(p.cast?-1:0);pE(g,x-1,ny+2,2.6,3,'#d6b27a');pP(g,[[x-3.5,ny-3],[x+2.5,ny-4.2],[x+3.5,ny+4.5],[x-4.2,ny+4.5]],'#3a5aa8');pR(g,x-3.3,ny-1,6,1,'#e0c060');pR(g,x-3.8,ny+1.8,7,1,'#e0c060');pE(g,x+2.3,ny+.5,2.4,2.8,'#c89a6a');pR(g,x+3.2,ny-.5,1,1,'#1a1418');pR(g,x+1.8,ny-4.6,1.6,1.4,'#e0c060')}
function jackHorn(g,x,y){pE(g,x-1.5,y-5,1.1,3.4,'#b08a62',-.35);pE(g,x-1.3,y-5,.5,2.4,'#e8b8a0',-.35);pL(g,x+1,y-3,x+2,y-8,1,'#e8dcc0');pL(g,x+1.8,y-6,x+4,y-7.2,.8,'#e8dcc0');pL(g,x+1.6,y-7.4,x+.2,y-9.2,.8,'#e8dcc0')}
function owlHead(g,x,y,p){const ny=y+(p.atk===2?1:0);pE(g,x,ny,4,4,'#7a5a3a');pP(g,[[x-2,ny-3],[x-3.5,ny-7],[x,ny-4]],'#553d26');pP(g,[[x+2,ny-3.5],[x+2.5,ny-7.5],[x+4,ny-4]],'#553d26');pE(g,x+1.5,ny+.5,3,3.2,'#d8c8a8');pR(g,x,ny-1.5,1.6,1.6,'#ffb020');pR(g,x+2.6,ny-1.5,1.6,1.6,'#ffb020');pR(g,x+.4,ny-1.1,.8,.8,'#1a1418');pR(g,x+3,ny-1.1,.8,.8,'#1a1418');pP(g,[[x+1.8,ny+.5],[x+4.8,ny+1.5],[x+2.2,ny+3.2]],'#e0a832')}
function yetiHead(g,x,y,p){pE(g,x,y,4,3.8,'#e8eef2');pP(g,[[x-2,y-3],[x-3,y-6.5],[x-.5,y-3.5]],'#b9c6d0');pE(g,x+1.8,y+.5,2.6,2.4,'#7fa6c8');pR(g,x+1,y-.5,1,1,'#1a2a3a');pR(g,x+3,y-.5,1,1,'#1a2a3a');if(p.atk===2||p.cast)pR(g,x+1.2,y+1.5,2.6,1,'#3a1a24')}
function gargHead(g,x,y,p){pE(g,x,y,3,3,'#6e6a7a');pP(g,[[x-2,y-2],[x-3,y-6],[x-.5,y-2.5]],'#3a3644');pP(g,[[x+1,y-2.5],[x+2.5,y-6],[x+2.5,y-2]],'#3a3644');pP(g,[[x+2,y-.5],[x+5,y+.5],[x+2,y+2]],'#6e6a7a');pR(g,x+1.5,y-1,1.2,1.2,'#ff4a3a');if(p.atk===2)pR(g,x+2.5,y+1.2,2,.8,'#1a1418')}
function cycHead(g,x,y,p){pE(g,x,y,4,4,'#c79a7a');pE(g,x+1.6,y-.8,2.2,1.9,'#ffffff');pR(g,x+2,y-1.4,1.5,1.5,'#2a5a9a');pE(g,x+2.4,y+2.4,1.6,.6,'#7a3a2a');pR(g,x-3,y-3,1.2,1,'#9a7358')}
function makeBird(C){return(g,p)=>{g.save();if(C.sc)g.scale(C.sc,C.sc);const y=-9+(p.bob?1:0),ang=flapA(p),tl=p.ph!=null?Math.sin(p.ph*2):(p.bob?1:0);
 C.tail.forEach((c,i)=>{i*=2;pP(g,[[-2,y],[-11-i,y+3+i+tl],[-9-i,y+5+i*.8+tl],[-3,y+2]],c)});
 wingShape(g,0,y-1,ang-.25,1.05,C.fw[0],C.fw[1]);
 const tilt=p.atk===2?.3:p.atk===1?-.2:0;g.save();g.translate(0,y);g.rotate(tilt);
 pE(g,0,0,5,3.8,C.body);pE(g,1,1.5,3.2,2,C.belly);pE(g,4.5,-3,2.8,2.6,C.body);
 pP(g,[[3,-5],[2,-9],[4.5,-6],[5,-10],[6,-5.5]],C.crest);pP(g,[[6.5,-3.5],[9.5,-2.5],[6.5,-1.5]],C.beak);pR(g,5,-4,1.2,1.2,C.eye||'#1a1418');if(C.mark)C.mark(g);
 g.restore();wingShape(g,0,y,ang,1.15,C.nw[0],C.nw[1]);g.restore()}}
Object.assign(RIG,{
 cerberus:(g,p)=>quad(g,p,{len:17,h:9,leg:6.5,lw:2.6,c:{b:'#3a3438',s:'#262226',l:'#5a5058',belly:'#4a3f46',f:'#1a1618'},head:cerbHead,tail:tailBushy}),
 nemean:(g,p)=>quad(g,p,{len:18,h:10,leg:6.5,lw:2.8,c:{b:'#d9a441',s:'#a8772a',l:'#f0c870',f:'#6a4a1a'},hd:{r:4.2,sn:2.5,snH:3.2,ear:'round',eye:'#6a2a10',mane:'#b8742a'},head:snoutHead,tail:tailTuft,tuft:'#8a4a1a'}),
 chimera:(g,p)=>quad(g,p,{len:17,h:9,leg:6,lw:2.6,c:{b:'#b0783a',s:'#825626',l:'#d09a5a',f:'#4a2e14'},hd:{r:3.8,sn:2.4,snH:3,ear:'round',eye:'#ff9a2a',mane:'#7a3a1e'},head:snoutHead,back:goatBack,tail:tailSnake}),
 nekomata:(g,p)=>quad(g,p,{len:14,h:7,leg:5.5,lw:2,c:{b:'#3b2f4a',s:'#271f33',l:'#5a4a70',belly:'#4a3d5c',f:'#1a1422'},hd:{r:3.3,sn:2,snH:2.4,ear:'point',eye:'#b8ff5a'},head:snoutHead,tail:tailTwin}),
 jackalope:(g,p)=>quad(g,p,{len:11,h:7,leg:4.5,lw:2,c:{b:'#b08a62',s:'#86664a',l:'#d0ae86',belly:'#efe2cc',f:'#5a4230'},hd:{r:3.4,sn:1.8,snH:2.4,ear:'none',eye:'#1a1418',nose:'#c8707a',horn:jackHorn},head:snoutHead,tail:tailPuff}),
 zaratan:(g,p)=>quad(g,p,{len:20,h:9,leg:4,lw:3.6,c:{b:'#8a9a6a',s:'#5f6b45',l:'#aebc8a',f:'#4a5236'},hd:{r:2.7,sn:2.2,snH:2.2,ear:'none',eye:'#1a1418'},head:snoutHead,back:shellBack}),
 hydra:(g,p)=>quad(g,p,{len:18,h:10,leg:5,lw:3,c:{b:'#3f8a7a',s:'#2a6358',l:'#6fb8a4',belly:'#c8c07a',f:'#1f3a34'},head:hydraHeads,tail:tailLizard}),
 sphinx:(g,p)=>quad(g,p,{len:17,h:9,leg:6,lw:2.5,c:{b:'#d6b27a',s:'#a88652',l:'#ecd2a0',f:'#6a4a24'},head:sphinxHead,back:sphinxWings,tail:tailTuft,tuft:'#8a6a3a'}),
 pegasus:(g,p)=>quad(g,p,{len:17,h:9,leg:8,lw:2,c:{b:'#f2f2f8',s:'#c9cfe0',l:'#ffffff',f:'#7f8aa0'},hd:{r:3.3,sn:4.2,snH:3.2,ear:'point',eye:'#3a4a7a',nose:'#b0b8cc'},head:snoutHead,back:maneFn('#9fd0f0','#d6ecfa'),tail:tailFlow('#9fd0f0','#d6ecfa'),farWing:(g,x,y,p)=>wingShape(g,x+1,y,flapA(p)-.15,1,'#c9cfe0','#e2e8f4'),wing:(g,x,y,p)=>wingShape(g,x-1,y+1,flapA(p),1.05,'#f2f2f8','#ffffff')}),
 salamander:(g,p)=>quad(g,p,{len:18,h:7,leg:4.5,lw:2.4,c:{b:'#d9542b',s:'#a33a1c',l:'#f58a4a',belly:'#ffc25a',f:'#5a200e'},hd:{r:3.2,sn:4,snH:2.5,ear:'none',eye:'#fff27a'},head:snoutHead,back:flameCrest,tail:tailFlame}),
 yeti:(g,p)=>biped(g,p,{leg:7,lw:4,tw:14,th:13,hunch:.1,c:{b:'#e8eef2',s:'#b9c6d0',l:'#ffffff',f:'#8fa0ae'},torso:torsoE,hx:2,hy:0,head:yetiHead,arm:armStd(8,3.6,(g,x,y,a,near)=>pE(g,x,y,2.4,2.4,near?'#e8eef2':'#b9c6d0'))}),
 owlbear:(g,p)=>biped(g,p,{leg:7,lw:3.6,tw:13,th:12,hunch:.12,c:{b:'#7a5a3a',s:'#553d26',l:'#9c7a52',f:'#2a1e14'},torso:(g,p,o)=>{torsoE(g,p,o);pE(g,2,-6,3.5,4,'#d8c8a8')},hx:2,hy:0,head:owlHead,arm:armStd(7,3.2,(g,x,y,a,near)=>{pE(g,x,y,2,2,near?'#7a5a3a':'#553d26');if(near)for(let i=-1;i<=1;i++)pL(g,x,y,x+Math.sin(a+i*.35)*3,y+Math.cos(a+i*.35)*3,.7,'#e8dcc0')})}),
 gargoyle:(g,p)=>biped(g,p,{leg:6,lw:3,tw:10,th:11,hunch:.2,c:{b:'#6e6a7a',s:'#4e4a5a',l:'#8e8a9a',f:'#3a3644'},torso:(g,p,o)=>{wingShape(g,-2,-o.th*.8,flapA(p)-.2,.95,'#4e4a5a','#6e6a7a');torsoE(g,p,o);wingShape(g,-1,-o.th*.75,flapA(p),.9,'#6e6a7a','#8e8a9a')},hx:2,hy:-1,head:gargHead,arm:armStd(6,2.4,(g,x,y,a)=>{for(let i=-1;i<=1;i++)pL(g,x,y,x+Math.sin(a+i*.35)*2.6,y+Math.cos(a+i*.35)*2.6,.7,'#2a2630')})}),
 cyclops:(g,p)=>biped(g,p,{leg:8,lw:3.8,tw:14,th:13,c:{b:'#c79a7a',s:'#9a7358',l:'#e0b898',f:'#4a3020'},belt:'#6b4a2a',torso:torsoE,hx:1.5,hy:0,head:cycHead,arm:armStd(8,3.4,(g,x,y,a,near,p)=>{pE(g,x,y,2,2,near?'#c79a7a':'#9a7358');if(near&&(p.atk===1||p.cast)){pE(g,x,y-2,4,3.6,'#8a8078');pE(g,x-1,y-3,2,1.5,'#aaa196')}})}),
 thunderbird:makeBird({sc:1.12,tail:['#1f3558','#3f6aa8','#f3d23a'],fw:['#16284a','#1f3558'],body:'#2d4a7a',belly:'#e8eef6',crest:'#f3d23a',beak:'#e8dcc0',eye:'#fff27a',nw:['#3f6aa8','#f3d23a'],mark:g=>{pL(g,-2,-1,0,1,.9,'#f3d23a');pL(g,0,1,-1.5,2.8,.9,'#f3d23a')}}),
 phoenix:makeBird({tail:['#d9482b','#f08a2a','#ffd35a'],fw:['#a3321f','#d9482b'],body:'#d9482b',belly:'#ffb347',crest:'#ffd35a',beak:'#ffd35a',nw:['#f08a2a','#ffd35a']}),
 arachne:(g,p)=>{const w=p.ph!=null?p.ph:0,by=-6+(p.bob?.4:0),ln=p.atk===2?2:p.atk===1?-1:0;
  const legs=(side,c)=>{for(let i=0;i<4;i++){const hx=ln+(i-1.5)*2.2,ph=w+i*1.6+(side?Math.PI:0),lift=p.ph!=null?Math.max(0,Math.sin(ph))*1.5:0,kx=hx+(i-1.5)*3.2,ky=by-5-lift,fx=hx+(i-1.5)*5.4+(p.ph!=null?Math.cos(ph)*1.2:0),fy=-lift*.3;pL(g,hx,by,kx,ky,1.3,c);pL(g,kx,ky,fx,fy,1.1,c)}};
  legs(1,'#2a1a2a');
  pE(g,-5+ln*.5,by-1,6,4.6,'#4a2f4a');pE(g,-6+ln*.5,by-2.8,3.4,1.8,'#6a4a6a');pP(g,[[-6,by-1],[-5,by-3.2],[-4,by-1],[-5,by+1.2]],'#d9362b');
  pE(g,2+ln,by,3.4,3,'#3a2440');pR(g,3.5+ln,by-1.5,1,1,'#ff3b3b');pR(g,4.6+ln,by-.6,1,1,'#ff3b3b');pR(g,3+ln,by+.4,.8,.8,'#ff3b3b');
  if(p.atk===2)pL(g,5+ln,by+1,7.5+ln,by+2.5,1,'#e8dcc0');if(p.cast)pE(g,-5,by-8,1.8,1.8,'#f2f0ff');
  legs(0,'#3a2440')}
});
function pixelize(c){const g=c.getContext('2d'),w=c.width,h=c.height,d=g.getImageData(0,0,w,h),a=d.data;
 for(let i=3;i<a.length;i+=4)a[i]=a[i]>100?255:0;
 const out=new Uint8ClampedArray(a);
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){const i=(y*w+x)*4;if(a[i+3])continue;if((x>0&&a[i-1])||(x<w-1&&a[i+7])||(y>0&&a[i-w*4+3])||(y<h-1&&a[i+w*4+3])){out[i]=20;out[i+1]=15;out[i+2]=24;out[i+3]=255}}
 d.data.set(out);g.putImageData(d,0,0)}
const SPR={};
function getSpr(sp,sc){sc=sc||1;const k=sp+'@'+sc;if(SPR[k])return SPR[k];const o={f:{},w:{},top:0,box:null};let x0=SW,y0=SH,x1=0,y1=0;
 FR.forEach(f=>{const c=document.createElement('canvas');c.width=SW;c.height=SH;const g=c.getContext('2d');g.translate(OX,OY);g.scale(sc,sc);RIG[sp](g,poseOf(f));pixelize(c);o.f[f]=c;
  if(f==='i0'||f==='i1'){const d=g.getImageData(0,0,SW,SH).data;for(let y=0;y<SH;y++)for(let x=0;x<SW;x++)if(d[(y*SW+x)*4+3]){if(x<x0)x0=x;if(x>x1)x1=x;if(y<y0)y0=y;if(y>y1)y1=y}}});
 o.box={x:x0,y:y0,w:x1-x0+1,h:y1-y0+1};o.top=OY-y0;SPR[k]=o;return o}
function whiteOf(o,f){if(o.w[f])return o.w[f];const c=document.createElement('canvas');c.width=SW;c.height=SH;const g=c.getContext('2d');g.drawImage(o.f[f],0,0);g.globalCompositeOperation='source-atop';g.fillStyle='#fff';g.fillRect(0,0,SW,SH);o.w[f]=c;return c}
function spriteCss(){if(document.getElementById('sprcss'))return;let css='';SPK.forEach(sp=>{const o=getSpr(sp,SC0),b=o.box,size=Math.max(b.w,b.h)+2,c=document.createElement('canvas');c.width=size*2;c.height=size;const g=c.getContext('2d');const sx=Math.round(b.x-(size-b.w)/2),sy=b.y+b.h-size;['i0','i1'].forEach((f,i)=>g.drawImage(o.f[f],sx,sy,size,size,i*size,0,size,size));css+=`.spr-${sp}{background-image:url(${c.toDataURL()})}\n`});const st=document.createElement('style');st.id='sprcss';st.textContent=css;document.head.appendChild(st)}

/* ============ MUSIC (synthesized with Web Audio) ============ */
const MUS={ctx:null,bus:null,master:null,on:true,vol:.55,node:null,timer:null,next:0,bar:0,name:null,track:null};
try{const a=JSON.parse(localStorage.getItem('beastbound-audio')||'null');if(a){MUS.on=!!a.on;MUS.vol=a.vol!=null?a.vol:.55}}catch(e){}
function musSave(){try{localStorage.setItem('beastbound-audio',JSON.stringify({on:MUS.on,vol:MUS.vol}))}catch(e){}}
function impulse(c,dur,decay){const len=Math.floor(c.sampleRate*dur),b=c.createBuffer(2,len,c.sampleRate);for(let ch=0;ch<2;ch++){const d=b.getChannelData(ch);for(let i=0;i<len;i++)d[i]=(Math.random()*2-1)*Math.pow(1-i/len,decay)}return b}
function actx(){if(MUS.ctx){if(MUS.ctx.state==='suspended')MUS.ctx.resume();return MUS.ctx}const AC=window.AudioContext||window.webkitAudioContext;if(!AC)return null;let c;try{c=new AC()}catch(e){return null}MUS.ctx=c;
 const comp=c.createDynamicsCompressor();comp.threshold.value=-18;comp.knee.value=14;comp.ratio.value=4;comp.attack.value=.008;comp.release.value=.25;
 const master=c.createGain();master.gain.value=MUS.on?MUS.vol:0;const bus=c.createGain();const rev=c.createConvolver();rev.buffer=impulse(c,2.8,2.6);const rg=c.createGain();rg.gain.value=.3;
 bus.connect(comp);bus.connect(rev);rev.connect(rg);rg.connect(comp);comp.connect(master);master.connect(c.destination);MUS.bus=bus;MUS.master=master;return c}
let NBUF=null;function noiseBuf(c){if(NBUF&&NBUF.sampleRate===c.sampleRate)return NBUF;const b=c.createBuffer(1,c.sampleRate,c.sampleRate),d=b.getChannelData(0);for(let i=0;i<d.length;i++)d[i]=Math.random()*2-1;NBUF=b;return b}
const mf=n=>440*Math.pow(2,(n-69)/12);
function aenv(g,t,a,peak,hold,rel){g.gain.setValueAtTime(0,t);g.gain.linearRampToValueAtTime(peak,t+a);g.gain.setValueAtTime(peak,t+a+hold);g.gain.exponentialRampToValueAtTime(.0004,t+a+hold+rel)}
function aosc(c,type,f,t,end,det){const o=c.createOscillator();o.type=type;o.frequency.setValueAtTime(f,t);if(det)o.detune.value=det;o.start(t);o.stop(end);return o}
function anoise(c,t,dur){const n=c.createBufferSource();n.buffer=noiseBuf(c);n.start(t);n.stop(t+dur);return n}
function iDrum(c,o,t,v,f0){f0=f0||90;const s=aosc(c,'sine',f0,t,t+.9),g=c.createGain();s.frequency.exponentialRampToValueAtTime(f0*.42,t+.32);aenv(g,t,.004,.9*v,.02,.65);s.connect(g);g.connect(o);const n=anoise(c,t,.2),lp=c.createBiquadFilter();lp.type='lowpass';lp.frequency.value=650;const ng=c.createGain();aenv(ng,t,.002,.4*v,0,.1);n.connect(lp);lp.connect(ng);ng.connect(o)}
function iSnare(c,o,t,v){const n=anoise(c,t,.3),bp=c.createBiquadFilter();bp.type='bandpass';bp.frequency.value=1800;bp.Q.value=.8;const g=c.createGain();aenv(g,t,.002,.42*v,0,.16);n.connect(bp);bp.connect(g);g.connect(o);const s=aosc(c,'triangle',200,t,t+.15),sg=c.createGain();aenv(sg,t,.002,.2*v,0,.07);s.connect(sg);sg.connect(o)}
function iHat(c,o,t,v){const n=anoise(c,t,.08),hp=c.createBiquadFilter();hp.type='highpass';hp.frequency.value=7200;const g=c.createGain();aenv(g,t,.001,.12*v,0,.04);n.connect(hp);hp.connect(g);g.connect(o)}
function iSwell(c,o,t,dur,v){const n=anoise(c,t,dur+.5),hp=c.createBiquadFilter();hp.type='highpass';hp.frequency.setValueAtTime(2500,t);hp.frequency.linearRampToValueAtTime(6000,t+dur);const g=c.createGain();g.gain.setValueAtTime(0,t);g.gain.linearRampToValueAtTime(.14*v,t+dur);g.gain.exponentialRampToValueAtTime(.0004,t+dur+.35);n.connect(hp);hp.connect(g);g.connect(o)}
function iCrash(c,o,t,v){const n=anoise(c,t,1),hp=c.createBiquadFilter();hp.type='highpass';hp.frequency.value=3800;const g=c.createGain();aenv(g,t,.003,.3*v,0,1.4);n.connect(hp);hp.connect(g);g.connect(o)}
function iBrass(c,o,t,n,dur,v,br){br=br==null?1:br;const f=mf(n),end=t+dur+.4,lp=c.createBiquadFilter(),g=c.createGain();lp.type='lowpass';lp.Q.value=1.4;lp.frequency.setValueAtTime(f*1.1,t);lp.frequency.linearRampToValueAtTime(f*(2.4+4*br),t+.1);lp.frequency.linearRampToValueAtTime(f*(1.8+2.6*br),t+Math.max(.12,dur));
 [-7,6].forEach(d=>{const s=aosc(c,'sawtooth',f,t,end,d);if(dur>.45){const l=aosc(c,'sine',5.3,t,end),lg=c.createGain();lg.gain.setValueAtTime(0,t);lg.gain.linearRampToValueAtTime(f*.007,t+.45);l.connect(lg);lg.connect(s.frequency)}s.connect(lp)});
 lp.connect(g);g.gain.setValueAtTime(0,t);g.gain.linearRampToValueAtTime(.15*v,t+.045);g.gain.linearRampToValueAtTime(.11*v,t+.18);g.gain.setValueAtTime(.11*v,t+Math.max(.2,dur));g.gain.exponentialRampToValueAtTime(.0004,t+dur+.32);g.connect(o)}
function iStrings(c,o,t,notes,dur,v){const g=c.createGain(),lp=c.createBiquadFilter();lp.type='lowpass';lp.frequency.value=1400;lp.connect(g);g.connect(o);const a=Math.min(.6,dur*.3);g.gain.setValueAtTime(0,t);g.gain.linearRampToValueAtTime(.045*v,t+a);g.gain.setValueAtTime(.045*v,t+dur);g.gain.linearRampToValueAtTime(0,t+dur+.7);notes.forEach(n=>[-10,0,9].forEach(d=>aosc(c,'sawtooth',mf(n),t,t+dur+.8,d).connect(lp)))}
function iPluck(c,o,t,n,v){const s=aosc(c,'sawtooth',mf(n),t,t+.32),lp=c.createBiquadFilter(),g=c.createGain();lp.type='lowpass';lp.frequency.setValueAtTime(3200,t);lp.frequency.exponentialRampToValueAtTime(320,t+.2);aenv(g,t,.003,.13*v,0,.22);s.connect(lp);lp.connect(g);g.connect(o)}
function iBass(c,o,t,n,dur,v){const g=c.createGain();aenv(g,t,.006,.3*v,dur*.55,dur*.45+.06);aosc(c,'triangle',mf(n),t,t+dur+.2).connect(g);const s=aosc(c,'sine',mf(n-12),t,t+dur+.2),sg=c.createGain();sg.gain.value=.7;s.connect(sg);sg.connect(g);g.connect(o)}
function iChoir(c,o,t,notes,dur,v){const g=c.createGain(),bp=c.createBiquadFilter();bp.type='bandpass';bp.frequency.value=900;bp.Q.value=.7;const lp=c.createBiquadFilter();lp.type='lowpass';lp.frequency.value=2200;bp.connect(g);lp.connect(g);g.connect(o);const a=Math.min(.9,dur*.4);g.gain.setValueAtTime(0,t);g.gain.linearRampToValueAtTime(.075*v,t+a);g.gain.setValueAtTime(.075*v,t+dur);g.gain.linearRampToValueAtTime(0,t+dur+1);notes.forEach(n=>[-11,0,10].forEach((d,i)=>{const s=aosc(c,i===1?'sawtooth':'triangle',mf(n),t,t+dur+1.1,d);s.connect(i===1?bp:lp)}))}
const CH={Dm:[62,65,69],Bb:[58,62,65],C:[60,64,67],Gm:[58,62,67],A:[57,61,64],F:[60,65,69],D:[62,66,69],G:[59,62,67],Bm:[59,62,66],Am:[57,60,64]};
const RT={Dm:38,Bb:34,C:36,Gm:31,A:33,F:29,D:38,G:31,Bm:35,Am:33};
function seq(arr){let st=0;return arr.map(([n,d])=>{const r=[n,d,st];st+=d;return r})}
const MEL_B=[[[70,1.5],[69,.5],[67,1],[65,1]],[[64,1.5],[65,.5],[67,2]],[[69,3],[65,1]],[[62,4]],[[67,1.5],[69,.5],[70,1],[72,1]],[[73,2],[69,2]],[[74,3],[72,.5],[70,.5]],[[69,2],[61,1],[64,1]]].map(seq);
const MEL_V=[[[62,.5],[66,.5],[69,1],[74,2]],[[71,1],[74,1],[79,1.5],[78,.5]],[[76,1.5],[74,.5],[73,1],[76,1]],[[74,4]],[[71,1],[74,1],[78,2]],[[79,1.5],[78,.5],[76,1],[74,1]],[[73,1],[76,1],[81,2]],[[78,1],[74,1],[78,.5],[81,1.5]],[[79,2],[74,2]],[[76,1],[73,1],[69,2]],[[74,4]],[[74,4]]].map(seq);
const MEL_H=[[[69,2],[67,1],[65,1]],[[65,2],[62,2]],[[60,1],[65,1],[69,2]],[[69,1],[67,1],[61,2]],[[62,2],[65,2]],[[67,2],[70,1],[69,1]],[[69,2],[64,2]],[[62,4]]].map(seq);
const TRACKS={
 prelude:{bpm:76,bar(c,o,t,b,i){const k=i%8,ch=['Dm','Dm','Bb','Bb','Gm','Gm','A','A'][k];
  if(k%4===0)iStrings(c,o,t,[38,45,50],b*16-.3,1.2);
  iDrum(c,o,t,.5,68);iDrum(c,o,t+b*.42,.32,74);iDrum(c,o,t+b*2,.46,68);iDrum(c,o,t+b*2.42,.3,74);
  if(k===3||k===7){iDrum(c,o,t+b*3,.85,105);iDrum(c,o,t+b*3.5,.65,110)}
  if(k%2===0){const br=.25+k*.09;CH[ch].forEach((n,j)=>iBrass(c,o,t+b*.5,n-12,b*3.1,.45+k*.05-j*.05,br))}
  if(k>=4)iChoir(c,o,t,CH[ch],b*3.8,.9);
  if(k>=4)for(let s=0;s<8;s++)iPluck(c,o,t+s*b/2,[74,69,77,69][s%4],.3+(k-4)*.12);
  if(k===7){iSwell(c,o,t+b*2,b*2,1);for(let s=0;s<8;s++)iDrum(c,o,t+b*2+s*b/4,.25+s*.07,118)}}},
 battle:{bpm:136,bar(c,o,t,b,i){const k=i%16,ch=k<8?['Dm','Dm','Bb','C','Dm','Dm','Gm','A'][k]:['Bb','C','Dm','Dm','Gm','A','Dm','A'][k-8],r=RT[ch],sx=b/4,tones=CH[ch];
  [[0,1,82],[3,.5,118],[6,.7,98],[8,1,82],[11,.5,118],[12,.8,92],[14,.6,120],[15,.45,128]].forEach(([st,v,f])=>iDrum(c,o,t+st*sx,v,f));
  iSnare(c,o,t+4*sx,.7);iSnare(c,o,t+12*sx,.8);if(k%4===3){iSnare(c,o,t+14*sx,.5);iSnare(c,o,t+15*sx,.65)}
  for(let st=0;st<16;st+=2)iHat(c,o,t+st*sx,st%4?.55:1);
  [0,0,12,0,0,0,12,7].forEach((d,j)=>iBass(c,o,t+j*b/2,r+d,b*.42,.9));
  const pat=k<8?[0,1,2,1,0,1,2,1]:[0,1,2,1,2,1,0,2,0,1,2,1,2,1,0,2],stp=k<8?b/2:sx;pat.forEach((ix,j)=>iPluck(c,o,t+j*stp,tones[ix]+12,k<8?.65:.8));
  iStrings(c,o,t,tones.map(n=>n-12),b*3.9,k<8?.8:1.1);
  if(k>=8)iChoir(c,o,t,tones,b*3.9,.65);
  if(k<8){tones.forEach(n=>iBrass(c,o,t,n-12,b*.32,.6,.8));if(k===3||k===7)tones.forEach(n=>iBrass(c,o,t+b*2,n-12,b*1.8,.55,.6))}
  else MEL_B[k-8].forEach(([n,d,st])=>iBrass(c,o,t+st*b,n,d*b*.95,1,1));
  if(k===7||k===15)iSwell(c,o,t+b*2,b*2,1);
  if(k===0||k===8)iCrash(c,o,t,.8)}},
 victory:{bpm:100,bar(c,o,t,b,i){
  if(i<12){const ch=['D','G','A','D','Bm','G','A','D','G','A','D','D'][i],tones=CH[ch];
   if(i===0)iCrash(c,o,t,.9);
   iDrum(c,o,t,.9,80);iDrum(c,o,t+b*2,.7,80);
   [1,1.5,3,3.5].forEach(x=>iSnare(c,o,t+x*b,.35));if(i%4===3)for(let s=0;s<8;s++)iSnare(c,o,t+b*2+s*b/4,.2+s*.05);
   iBass(c,o,t,RT[ch],b*1.9,.9);iBass(c,o,t+b*2,RT[ch]+7,b*1.9,.8);
   iStrings(c,o,t,tones.map(n=>n-12),b*3.9,1.2);iChoir(c,o,t,tones,b*3.9,.7);
   MEL_V[i].forEach(([n,d,st])=>{iBrass(c,o,t+st*b,n,d*b*.95,1,1);iBrass(c,o,t+st*b,n-12,d*b*.95,.5,.6)});
   tones.forEach(n=>iBrass(c,o,t,n-12,b*.5,.45,.7));
   if(i===11){iSwell(c,o,t,b*3,1);iCrash(c,o,t+b*3.5,1);iDrum(c,o,t+b*3.5,1,70)}}
  else if((i-12)%4===0){iChoir(c,o,t,CH.D,b*15,.45);iStrings(c,o,t,[50,57,62],b*15,.5)}}},
 honor:{bpm:66,bar(c,o,t,b,i){
  if(i<8){const ch=['Dm','Bb','F','A','Dm','Gm','A','Dm'][i],tones=CH[ch];
   iDrum(c,o,t,.55,62);if(i%2)iDrum(c,o,t+b*2,.35,62);
   iStrings(c,o,t,tones.map(n=>n-12),b*3.9,1);iChoir(c,o,t,tones.map(n=>n-12),b*3.9,.6);
   iBass(c,o,t,RT[ch],b*3.8,.7);
   MEL_H[i].forEach(([n,d,st])=>iBrass(c,o,t+st*b,n,d*b*.97,.85,.45));
   if(i===7)iSwell(c,o,t+b*2,b*2,.5)}
  else if((i-8)%4===0){iChoir(c,o,t,[50,53,57],b*15,.4);iStrings(c,o,t,[38,45,50],b*15,.5)}}}
};
function music(name){
 if(MUS.name===name&&MUS.node)return;MUS.name=name;
 const c=actx();if(!c)return;
 if(MUS.node){const old=MUS.node;try{old.gain.cancelScheduledValues(c.currentTime);old.gain.setValueAtTime(old.gain.value,c.currentTime);old.gain.linearRampToValueAtTime(0,c.currentTime+1.1)}catch(e){}setTimeout(()=>{try{old.disconnect()}catch(e){}},1600)}
 clearInterval(MUS.timer);MUS.node=null;MUS.track=null;
 if(!name||!TRACKS[name])return;
 const g=c.createGain();g.gain.setValueAtTime(0,c.currentTime);g.gain.linearRampToValueAtTime(1,c.currentTime+.9);g.connect(MUS.bus);
 MUS.node=g;MUS.track=TRACKS[name];MUS.bar=0;MUS.next=c.currentTime+.12;
 const tick=()=>{if(MUS.node!==g)return;const tr=MUS.track;while(MUS.next<c.currentTime+.9){const spb=60/tr.bpm;try{tr.bar(c,g,MUS.next,spb,MUS.bar)}catch(e){}MUS.next+=spb*4;MUS.bar++}};
 tick();MUS.timer=setInterval(tick,150);
}
function musToggle(){MUS.on=!MUS.on;musSave();const n=MUS.name;const c=actx();if(c&&MUS.master)MUS.master.gain.setTargetAtTime(MUS.on?MUS.vol:0,c.currentTime,.08);if(MUS.on&&n&&!MUS.node){MUS.name=null;music(n)}}

/* ============ BATTLE RENDER ============ */
let BT=null,ARENA=null,CROWD=null,LR=null,LRg=null;
const TORCH=[.35,1.2,1.95,2.75,3.55,4.35,5.1,5.85].map(a=>({x:CX+Math.cos(a)*(RX+16),y:CY+Math.sin(a)*(RY+12)}));
function arenaBg(){
 if(ARENA)return ARENA;
 const c=document.createElement('canvas');c.width=LW;c.height=LH;const g=c.getContext('2d');
 const cx=CX/2,cy=CY/2,rx=RX/2,ry=RY/2;
 g.fillStyle='#120f17';g.fillRect(0,0,LW,LH);
 ['#2e2638','#29222f','#241e2b','#1f1a25','#1a1620'].map((col,k)=>[col,k]).reverse().forEach(([col,k])=>{g.fillStyle=col;g.beginPath();g.ellipse(cx,cy,rx+6+k*3.2,ry+5+k*2.8,0,0,Math.PI*2);g.fill()});
 g.fillStyle='#4a3f57';g.beginPath();g.ellipse(cx,cy,rx+3.5,ry+3.5,0,0,Math.PI*2);g.fill();
 g.fillStyle='#665775';g.beginPath();g.ellipse(cx,cy-1,rx+2.5,ry+2,0,0,Math.PI*2);g.fill();
 for(let i=0;i<64;i++){const a=i/64*Math.PI*2;g.fillStyle='#3a3046';g.fillRect(Math.round(cx+Math.cos(a)*(rx+3)),Math.round(cy+Math.sin(a)*(ry+3)),1,2)}
 g.fillStyle='#b09565';g.beginPath();g.ellipse(cx,cy,rx,ry,0,0,Math.PI*2);g.fill();
 for(let y=0;y<LH;y++)for(let x=0;x<LW;x++){const dx=(x-cx)/rx,dy=(y-cy)/ry,dd=dx*dx+dy*dy;if(dd>.97)continue;const r=Math.random();let col=null;
  if(dd>.8&&r<.4)col='#98804f';else if(r<.07)col='#a2885a';else if(r<.1)col='#c2a878';else if(r<.104)col='#7d6844';if(col){g.fillStyle=col;g.fillRect(x,y,1,1)}}
 g.strokeStyle='rgba(90,66,36,.3)';g.lineWidth=1;for(let k=2;k<6;k++){g.beginPath();g.ellipse(cx,cy,rx*k/6,ry*k/6,0,0,Math.PI*2);g.stroke()}
 g.strokeStyle='rgba(80,52,24,.6)';g.beginPath();g.arc(cx,cy,21,0,Math.PI*2);g.stroke();g.beginPath();g.arc(cx,cy,13,0,Math.PI*2);g.stroke();
 for(let i=0;i<8;i++){const a=i/8*Math.PI*2;g.beginPath();g.moveTo(cx+Math.cos(a)*13,cy+Math.sin(a)*13);g.lineTo(cx+Math.cos(a)*21,cy+Math.sin(a)*21);g.stroke()}
 [[cx-rx-3,'#d9a441'],[cx+rx+3,'#c9493d']].forEach(([x,col])=>{x=Math.round(x);g.fillStyle='#0b0910';g.fillRect(x-4,cy-11,8,22);g.fillStyle='#3a3046';g.fillRect(x-5,cy-13,10,2);g.fillRect(x-5,cy-11,1,22);g.fillRect(x+4,cy-11,1,22);g.fillStyle=col;g.fillRect(x-3,cy-9,6,8);g.fillStyle='rgba(0,0,0,.3)';g.fillRect(x-3,cy-3,6,2)});
 ARENA=c;
 CROWD=[];const cols=['#c98d5c','#8b6b52','#d2b48c','#6f5345','#a07a64','#e0c9a6','#b58ab8','#7fa2c6','#c67f7f','#8faf7f'],bodies=['#3a2d4a','#4a3a2a','#2d3a4a','#4a2d2d','#2f4232'];
 for(let k=0;k<4;k++){const rr=rx+8+k*3.2,rry=ry+7+k*2.8,n=Math.round(rr*2*Math.PI/3.3);for(let i=0;i<n;i++){const a=i/n*Math.PI*2;if(Math.abs(Math.cos(a))>.95||Math.random()<.18)continue;CROWD.push({x:Math.round(cx+Math.cos(a)*rr),y:Math.round(cy+Math.sin(a)*rry),c:pick(cols),b:pick(bodies),ph:Math.random()*6.3})}}
 CROWD.sort((a,b)=>a.y-b.y);
 return c;
}
function drawCrowd(q,S,T){const ch=S.cheer>0;for(const p of CROWD){const j=(ch&&Math.sin(T*18+p.ph)>0)||Math.sin(T*2+p.ph*3)>.97?1:0;q.fillStyle=p.b;q.fillRect(p.x-1,p.y+1-j,3,2);q.fillStyle=p.c;q.fillRect(p.x,p.y-1-j,2,2);if(ch&&j&&p.ph>5.4){q.fillStyle=p.c;q.fillRect(p.x-1,p.y-2,1,1);q.fillRect(p.x+2,p.y-2,1,1)}}}
function drawTorches(q,T){TORCH.forEach((p,i)=>{const x=Math.round(p.x/2),y=Math.round(p.y/2),f=.26+.08*Math.sin(T*9+i*2);const gr=q.createRadialGradient(x,y-3,1,x,y-3,24);gr.addColorStop(0,`rgba(255,170,70,${f})`);gr.addColorStop(1,'rgba(255,140,50,0)');q.fillStyle=gr;q.fillRect(x-24,y-27,48,48);q.fillStyle='#2a2230';q.fillRect(x-1,y-1,3,5);q.fillStyle='#4a3f57';q.fillRect(x-2,y-2,5,1);const k=Math.floor(T*8+i)%2;q.fillStyle='#ff7a2a';q.fillRect(x-1,y-5-k,3,3+k);q.fillStyle='#ffd35a';q.fillRect(x,y-4,1,2)})}
function sprKey(u){return u.summon?[u.skin||'direwolf',(u.skinSc||.62)*SC0]:[u.sp,SC0]}
function frameOf(u,T){if(u.animCast>0)return'c';if(u.animAtk>0)return u.animAtk>.17?'a1':'a2';if(u.dash)return'a2';if(u.moved>0)return'w'+(Math.floor(u.walk/6)%6);return'i'+(Math.floor(T*(FLY.has(u.sp)?3:1.4)+u.id*.37)%2)}
function drawGround(q,u){const px=Math.round(u.x/2),py=Math.round(u.y/2),rx=Math.round(u.r*.62)+(u.summon?0:1),ry=Math.max(2,Math.round(rx*.45));q.globalAlpha=u.summon?.55:1;q.fillStyle='rgba(20,12,6,.32)';q.beginPath();q.ellipse(px,py,rx,ry,0,0,Math.PI*2);q.fill();q.strokeStyle=u.team===0?'#e0ac48':'#d2503f';q.lineWidth=1;q.beginPath();q.ellipse(px+.5,py+.5,rx,ry,0,0,Math.PI*2);q.stroke();q.globalAlpha=1}
function drawSprite(q,u,S,T){
 const[sp,sc]=sprKey(u),o=getSpr(sp,sc),f=frameOf(u,T),px=Math.round(u.x/2),py=Math.round(u.y/2);
 const hov=u.summon?0:(HOVER[sp]||0),hb=hov?Math.floor(T*3+u.id)%2:0;
 let ox=0;if(f==='a2'&&u.range<60)ox=2*u.face;if(u.flash>0)ox-=u.face;
 if(u.animCast>0){q.fillStyle=`hsl(${u.hue} 90% 72%)`;const r=Math.round(u.r*.7)+3;for(let i=0;i<8;i++){const a=T*6+i*.785;q.fillRect(Math.round(px+Math.cos(a)*r),Math.round(py-o.top*.45+Math.sin(a)*r*.6),1,1)}}
 if(u.berserk&&u.hp/u.maxHp<.5){q.fillStyle='#ff3b2a';for(let i=0;i<2;i++)q.fillRect(px+ri(-6,6),py-ri(2,o.top),1,1)}
 if(u.s.buffT>0||u.bloodT>0){q.fillStyle='#ff5a3d';for(let i=0;i<3;i++)q.fillRect(px+ri(-6,6),py-ri(2,o.top),1,1)}
 q.save();q.globalAlpha=u.s.stealth>0?.28:(u.summon&&u.lure?.6:1);q.translate(px+ox,py-hov-hb);q.scale(u.face||1,1);q.drawImage(u.flash>0?whiteOf(o,f):(u.s.tintT>0&&u.s.tint?tintOf(o,u.s.tint==='stone'?'i0':f,u.s.tint):o.f[f]),-OX,-OY);q.restore();
 const top=o.top+hov+hb;
 if(u.s.stun>0)for(let i=0;i<3;i++){const a=T*5+i*2.09;q.fillStyle='#ffd25e';q.fillRect(Math.round(px+Math.cos(a)*5),Math.round(py-top-7+Math.sin(a)*1.5),1,1)}
 if(u.s.shield>0){q.strokeStyle='rgba(150,230,240,.7)';q.lineWidth=1;q.beginPath();q.ellipse(px+.5,py-top/2+.5,Math.round(u.r*.7)+3,Math.round(top/2)+2,0,0,Math.PI*2);q.stroke()}
 if(u.s.root>0){q.fillStyle='#6f9a3f';for(let i=-2;i<=2;i++)q.fillRect(px+i*2,py-1-(i&1),1,2)}
 if(u.s.poison>0||u.s.burn>0){q.fillStyle=u.s.poison>0?(u.s.pk==='bleed'?'#e0405a':'#9be35a'):'#ff8a3d';const k=Math.floor(T*10);for(let i=0;i<2;i++)q.fillRect(px-4+((k+i*5)%9),py-((k*2+i*7)%Math.max(4,top)),1,1)}
 if(u.s.silence>0){q.fillStyle='#c6a6f0';q.fillRect(px+6,py-top,2,1)}
 if(u.s.confuse>0){q.fillStyle='#d6a6ff';const a=T*6;q.fillRect(Math.round(px+Math.cos(a)*5),py-top-7,1,1);q.fillRect(Math.round(px-Math.cos(a)*5),py-top-8,1,1);q.fillRect(px,py-top-10,1,2)}
 if(u.s.hasteT>0){q.fillStyle='rgba(220,240,255,.85)';const k=Math.floor(T*12)%4;q.fillRect(px-(u.face||1)*(7+k),py-4-k,3,1)}
 if(u.s.drT>0){q.strokeStyle='rgba(220,205,160,.8)';q.lineWidth=1;q.beginPath();q.ellipse(px+.5,py-top/2+.5,Math.round(u.r*.7)+2,Math.round(top/2)+1,0,0,Math.PI*2);q.stroke()}
}
function drawBars(q,u){const[sp,sc]=sprKey(u),o=getSpr(sp,sc),px=Math.round(u.x/2),py=Math.round(u.y/2),hov=u.summon?0:(HOVER[sp]||0),bw=u.summon?8:14,bx=px-(bw>>1),by=py-o.top-hov-5;
 q.fillStyle='#120e16';q.fillRect(bx-1,by-1,bw+2,u.summon?3:4);
 q.fillStyle=u.team===0?'#e0ac48':'#d2503f';q.fillRect(bx,by,Math.max(0,Math.round(bw*clamp(u.hp/u.maxHp,0,1))),u.summon?1:2);
 if(u.s.shield>0){q.fillStyle='#bfeff5';q.fillRect(bx,by,Math.round(bw*clamp(u.s.shield/u.maxHp,0,1)),1)}
 if(!u.summon&&u.ab){const f=1-clamp(u.cdT/u.cd,0,1);q.fillStyle=f>=1?'#a9d0ff':'#4d6d99';q.fillRect(bx,by+2,Math.round(bw*f),1)}}
function drawCorpse(q,u,S){const o=getSpr(u.sp,SC0),age=S.t-(u.deadT||0),px=Math.round(u.x/2),py=Math.round(u.y/2);q.save();q.globalAlpha=age<.3?1:Math.max(.42,1-(age-.3)*1.2);q.translate(px,py);q.scale(u.face||1,1);q.rotate(Math.PI/2*Math.min(1,age/.2));q.drawImage(age<.1?whiteOf(o,'i0'):o.f.i0,-OX,-OY);q.restore()}
function drawBattle(g,S,msg){
 if(!LR){LR=document.createElement('canvas');LR.width=LW;LR.height=LH;LRg=LR.getContext('2d')}
 const q=LRg,T=S.vt||S.t;q.setTransform(1,0,0,1,0,0);q.imageSmoothingEnabled=false;q.globalAlpha=1;
 q.drawImage(arenaBg(),0,0);drawCrowd(q,S,T);drawTorches(q,T);
 for(const z of S.zones){const a=Math.min(1,z.t/.5),zx=Math.round(z.x/2),zy=Math.round(z.y/2);q.fillStyle=`hsla(${z.hue},70%,38%,${.38*a})`;q.beginPath();q.ellipse(zx,zy,z.r/2,z.r/2*.7,0,0,Math.PI*2);q.fill();q.fillStyle=`hsla(${z.hue},85%,62%,${a})`;for(let i=0;i<7;i++){const an=T*1.5+i;q.fillRect(Math.round(zx+Math.cos(an)*z.r/2*.6),Math.round(zy+Math.sin(an*1.3)*z.r/2*.4),1,1)}}
 for(const f of S.fx)if(f.ground){const a=1-f.t/f.ttl;q.globalAlpha=.55*Math.min(1,a*2);q.fillStyle=f.c||'#2a1a10';q.beginPath();q.ellipse(Math.round(f.x/2),Math.round(f.y/2),f.rx||7,Math.max(2,(f.rx||7)*.45),0,0,Math.PI*2);q.fill();q.globalAlpha=1}
 for(const u of S.units)if(!u.alive&&!u.summon)drawCorpse(q,u,S);
 const live=S.units.filter(u=>u.alive).sort((a,b)=>a.y-b.y);
 for(const u of live)drawGround(q,u);
 for(const u of live)drawSprite(q,u,S,T);
 for(const p of S.proj){if(p.lob){const pr=clamp(1-Math.hypot(p.t.x-p.x,p.t.y-p.y)/p.d0,0,1),h=Math.sin(pr*Math.PI)*34,x=Math.round(p.x/2),y=Math.round(p.y/2);q.fillStyle='rgba(20,12,6,.35)';q.fillRect(x-2,y,5,2);q.fillStyle='#6e665e';q.fillRect(x-3,y-8-h,6,6);q.fillStyle='#9a9088';q.fillRect(x-2,y-8-h,4,3);continue}const x=Math.round(p.x/2),y=Math.round(p.y/2)-7;if(p.px!=null){q.globalAlpha=.55;q.fillStyle=p.c;q.fillRect(Math.round(p.px/2),Math.round(p.py/2)-7,1,1);q.globalAlpha=1}q.fillStyle=p.c;const pz=p.sp==='boulder'?4:p.sp==='phoenix'?3:2;q.fillRect(x-(pz>>1),y-(pz>>1),pz,pz);q.fillStyle='#fff6d8';q.fillRect(x,y-1,1,1)}
 q.setTransform(.5,0,0,.5,0,0);
 for(const f of S.fx){if(f.k==='txt'||f.ground)continue;const k=f.t/f.ttl,a=1-k;q.save();q.globalAlpha=Math.max(0,a);
  if(f.k==='ring'){const r=f.r0+(f.r1-f.r0)*k;q.strokeStyle=f.c;q.lineWidth=2;q.beginPath();q.ellipse(f.x,f.y,Math.max(1,r),Math.max(1,r*.7),0,0,Math.PI*2);q.stroke();if(f.fill){q.globalAlpha=a*.22;q.fillStyle=f.c;q.fill()}}
  else if(f.k==='slash'){q.strokeStyle=f.c;q.lineWidth=2;q.beginPath();q.arc(f.x,f.y-10,f.r,f.a-.9,f.a+.9);q.stroke()}
  else if(f.k==='bolt'){q.strokeStyle=f.c;q.lineWidth=2;q.beginPath();f.pts.forEach((p,i)=>{if(!i){q.moveTo(p[0],p[1]-12);return}const pr=f.pts[i-1];for(let st=1;st<=4;st++){const tt=st/4;q.lineTo(pr[0]+(p[0]-pr[0])*tt+(st<4?rnd(-8,8):0),pr[1]-12+(p[1]-pr[1])*tt+(st<4?rnd(-8,8):0))}});q.stroke()}
  else if(f.k==='beam'){q.strokeStyle=f.c;q.lineWidth=2;q.beginPath();q.moveTo(f.x1,f.y1-14);q.lineTo(f.x2,f.y2-12);q.stroke()}
  else if(f.k==='dot'){q.fillStyle=f.c;q.fillRect(f.x-2,f.y-2,4,4)}
  else if(f.k==='dome'){const u=f.u;if(u&&u.alive){const fade=Math.min(1,(f.ttl-f.t)/.4,f.t/.15);q.globalAlpha=.22*fade;q.fillStyle=f.c;q.beginPath();q.ellipse(u.x,u.y-u.r*1.5,u.r*2,u.r*2.2,0,0,Math.PI*2);q.fill();q.globalAlpha=.85*fade;q.strokeStyle=f.c;q.lineWidth=2;q.stroke();q.fillStyle='#ffffff';for(let i=0;i<5;i++){const an=T*2+i*1.26;q.fillRect(u.x+Math.cos(an)*u.r*1.6,u.y-u.r*1.5+Math.sin(an)*u.r*1.8,2,2)}}}
  else if(f.k==='pillar'){const w=f.w||10;if(f.jag){q.strokeStyle=f.c;q.lineWidth=4;q.beginPath();q.moveTo(f.x+rnd(-6,6),f.y-340);for(let yy=f.y-300;yy<f.y;yy+=34)q.lineTo(f.x+rnd(-10,10),yy);q.lineTo(f.x,f.y);q.stroke();q.strokeStyle='#ffffff';q.lineWidth=2;q.stroke();q.globalAlpha=a*.35;q.fillStyle=f.c;q.beginPath();q.ellipse(f.x,f.y,26,12,0,0,Math.PI*2);q.fill()}else{q.globalAlpha=a*.45;q.fillStyle=f.c;q.fillRect(f.x-w/2,f.y-320,w,320);q.globalAlpha=a*.9;q.fillStyle='#ffffff';q.fillRect(f.x-w/6,f.y-320,w/3,320)}}
  else if(f.k==='glyph'){const u=f.u;if(u&&u.alive&&u.s.confuse>0){const cy=u.y-u.r*3.2;q.strokeStyle=f.c;q.lineWidth=2;q.globalAlpha=.9;q.beginPath();q.ellipse(u.x,cy,14,6,0,0,Math.PI*2);q.stroke();q.fillStyle=f.c;for(let i=0;i<6;i++){const an=T*3+i*1.047;q.fillRect(u.x+Math.cos(an)*14-1.5,cy+Math.sin(an)*6-1.5,3,3)}q.fillStyle='#d6a6ff';q.fillRect(u.x-2,cy-10,4,6);q.fillRect(u.x-2,cy-2,4,3)}}
  else if(f.k==='wave'){const r=f.r0+(f.r1-f.r0)*k;q.strokeStyle=f.c;q.lineWidth=3;q.beginPath();q.ellipse(f.x,f.y,Math.max(1,r),Math.max(1,r*.7),0,f.a-f.w,f.a+f.w);q.stroke()}
  else if(f.k==='crescent'){q.strokeStyle=f.c;q.lineWidth=2.5;for(let i=-1;i<=1;i++){q.beginPath();q.arc(f.x+i*5,f.y-12+i*4,f.r,f.a-1.1,f.a+1.1);q.stroke()}}
  q.restore()}
 q.setTransform(1,0,0,1,0,0);
 const dtv=Math.min(.05,Math.max(0,(S.vt||0)-(S.pvt||0)));S.pvt=S.vt;
 S.parts=S.parts.filter(p=>(p.t+=dtv)<p.ttl);
 for(const p of S.parts){if(p.to){if(!p.to.alive){p.t=p.ttl;continue}const dx=p.to.x-p.x,dy=p.to.y-p.y,d=Math.hypot(dx,dy)||1;p.x+=dx/d*140*dtv;p.y+=dy/d*140*dtv;if(d<8)p.t=p.ttl}else{p.x+=p.vx*dtv;p.y+=p.vy*dtv;p.z+=p.vz*dtv;p.vz-=p.g*dtv;if(p.z<0){p.z=0;p.vz*=-.3;p.vx*=.55;p.vy*=.55}}
  q.globalAlpha=Math.min(1,(1-p.t/p.ttl)*3);q.fillStyle=p.c;q.fillRect(Math.round(p.x/2),Math.round((p.y-p.z)/2),p.s,p.s)}
 q.globalAlpha=1;
 for(const u of live)drawBars(q,u);
 g.imageSmoothingEnabled=false;let shx=0,shy=0;if(S.shake>0){S.shake-=dtv;shx=ri(-3,3);shy=ri(-2,2)}g.fillStyle='#120f17';g.fillRect(0,0,W,H);g.drawImage(LR,shx,shy,W,H);
 g.textAlign='center';g.lineJoin='round';
 for(const u of live){if(u.summon)continue;const nm=u.name.toUpperCase();g.font='10px "Silkscreen",monospace';g.lineWidth=3;g.strokeStyle='rgba(18,14,22,.9)';g.strokeText(nm,u.x,u.y+16);g.fillStyle=u.team===0?'#f3dca0':'#f3b7ad';g.fillText(nm,u.x,u.y+16)}
 for(const f of S.fx){if(f.k!=='txt')continue;const k=f.t/f.ttl;g.globalAlpha=Math.max(0,1-k*k);g.font=`${Math.max(10,Math.round(f.z*.9))}px "Silkscreen",monospace`;const y=f.y-k*20-14;g.lineWidth=3;g.strokeStyle='rgba(18,14,22,.9)';g.strokeText(f.s,f.x,y);g.fillStyle=f.c;g.fillText(f.s,f.x,y)}
 g.globalAlpha=1;
 const big=S.done?(S.winner===0?'VICTORY':'DEFEAT'):msg;
 if(big){g.fillStyle='rgba(14,11,17,.55)';g.fillRect(0,CY-44,W,88);g.font='48px "Silkscreen",monospace';g.lineWidth=6;g.strokeStyle='#120e16';g.strokeText(big,CX,CY+17);g.fillStyle=S.done?(S.winner===0?'#e8b44d':'#d9584a'):'#f3e6c8';g.fillText(big,CX,CY+17)}
}
function startBattle(S){
 const cv=$('#cv'),dpr=Math.min(2,window.devicePixelRatio||1);cv.width=W*dpr;cv.height=H*dpr;const g=cv.getContext('2d');g.setTransform(dpr,0,0,dpr,0,0);
 BT={S,speed:1,paused:false,raf:0,frame:0,endAt:0,feedN:-1,t0:0};
 const loop=now=>{
  if(!BT||BT.S!==S)return;
  if(!BT.t0)BT.t0=now;S.vt=(now-BT.t0)/1000;
  const intro=now-BT.t0<1500;
  if(!intro&&!BT.paused&&!S.done)for(let i=0;i<BT.speed;i++){step(S,1/60);if(S.done)break}
  drawBattle(g,S,intro?(now-BT.t0<850?'READY':'FIGHT!'):null);
  if(BT.frame++%6===0)updateSides(S);
  if(S.done){if(!BT.endAt)BT.endAt=now;if(now-BT.endAt>1600){finishMatch(S);return}}
  BT.raf=requestAnimationFrame(loop)};
 BT.raf=requestAnimationFrame(loop);
}
function stopBattle(){if(BT){cancelAnimationFrame(BT.raf);BT=null}}
function updateSides(S){
 const side=team=>S.units.filter(u=>u.team===team&&!u.summon).map(u=>`<div class="srow ${team?'b':'a'} ${u.alive?'':'dead'}"><span style="overflow:hidden;text-overflow:ellipsis">${esc(u.name)} <span class="mute">${SPECIES[u.sp].n}</span></span><span class="bar"><i style="width:${clamp(u.hp/u.maxHp*100,0,100)}%"></i></span><span class="num" style="font-size:11px;text-align:right">${u.st.k}/${u.st.d}/${u.st.a}</span></div>`).join('');
 const a=$('#sideA'),b=$('#sideB');if(!a)return;a.innerHTML=side(0);b.innerHTML=side(1);
 const cl=$('#clock');if(cl)cl.textContent=`${Math.floor(S.t)}s / ${S.maxT}s`;
 const sa=$('#scoreA'),sb=$('#scoreB');if(sa){sa.textContent=S.units.filter(u=>u.team===0&&!u.summon&&u.alive).length;sb.textContent=S.units.filter(u=>u.team===1&&!u.summon&&u.alive).length}
 if(BT&&BT.feedN!==S.feed.length){BT.feedN=S.feed.length;$('#feed').innerHTML=S.feed.slice(-5).map(f=>`<div class="${f.team?'b':'a'}">${esc(f.txt)}</div>`).join('')}
}

/* ============ VIEW HELPERS ============ */
function tok(b,cls){const sp=b.sp||b,D=SPECIES[sp];return`<span class="tok ${cls||''}" style="--h:${D.hue}" aria-hidden="true"><span class="spr spr-${sp}"></span></span>`}
function crest(c,size){const ini=c.name.replace(/^The /,'').split(/\s+/).map(w=>w[0]).join('').slice(0,2).toUpperCase();return`<svg class="crest" width="${size}" height="${Math.round(size*1.15)}" viewBox="0 0 40 46" aria-hidden="true"><path d="M2 2h36v18c0 13-9 20-18 24C11 40 2 33 2 20z" fill="hsl(${c.hue} 38% 30%)" stroke="hsl(${c.hue} 55% 62%)" stroke-width="2"/><path d="M8 8h24" stroke="hsl(${c.hue} 55% 62%)" stroke-opacity=".5"/><text x="20" y="29" text-anchor="middle" font-family="Grenze Gotisch,Georgia,serif" font-weight="700" font-size="17" fill="#f3e6c8">${esc(ini)}</text></svg>`}
function ebar(e){return`<span class="bar ${e<35?'low':e<60?'warn':''}" title="Energy ${e}"><i style="width:${e}%"></i></span>`}
function fbar(f){return`<span class="bar fat ${f>70?'low':f>50?'warn':''}" title="Fatigue ${f}"><i style="width:${f}%"></i></span>`}
function traitChips(b){return b.traits.map(t=>`<span class="trait ${NEG_TRAITS.has(t)?'neg':''}" title="${esc(TRAITS[t])}">${esc(t)}</span>`).join('')}
function fullName(b){return esc(b.name)+(b.epithet?` <span class="dust" style="font-weight:500">${esc(b.epithet)}</span>`:'')}
function clubName(id){return G.clubs[id]?G.clubs[id].name:'Unknown'}
function eventLabel(e){if(!e)return'';if(e.t==='league')return`Matchday ${e.r+1}`;if(e.t==='draft')return CUPN[5];return CUPN[e.fmt]}
function formStr(f){return f.slice(-5).map(x=>`<span class="${x==='W'?'good':'bad'}">${x}</span>`).join(' ')}

/* ============ VIEWS ============ */
function renderTop(){
 const e=curEvent(),pc=G.clubs.P;
 $('#top').innerHTML=`<div class="brand">${crest(pc,44)}<div style="min-width:0"><div class="club-name">${esc(G.name)}</div><div class="sub">${TIERS[G.tier].n} · Season ${G.season} · ${e?`Day ${G.day+1} of ${G.sched.length}`:'Season complete'}</div></div></div>
 <div class="purse"><span class="chip">Gold <b class="${G.gold<0?'bad':''}">${fmt(G.gold)}</b></span><span class="chip">Renown <b>${fmt(G.renown)}</b></span><span class="chip">Trophies <b>${G.trophies.length}</b></span><button class="btn sm" data-act="music" aria-pressed="${MUS.on}">${MUS.on?'Music on':'Music off'}</button><button class="btn sm" data-act="settings">Club office</button></div>`;
}
function renderTabs(){
 const lock=['battle','result','draft','season','cupdone','levelup'].includes(UI.mode);
 const tabs=[['club','Club'],['roster','Roster'],['market','Beast market'],['shop','Item shop'],['league','League'],['leaders','Leaders'],['bestiary','Bestiary'],['legacy','Legacy']];
 $('#tabs').innerHTML=lock?'':tabs.map(([k,n])=>`<button class="tab ${UI.mode==='hub'&&UI.tab===k?'on':''}" data-act="tab" data-k="${k}">${n}</button>`).join('')+(UI.mode==='prematch'?`<button class="tab on" data-act="toPrematch">Match prep</button>`:'');
}
function render(){
 if(UI.mode==='menu'){$('#top').innerHTML='';$('#tabs').innerHTML='';$('#view').innerHTML=viewRunMenu();$('#modal').innerHTML='';return}
 if(UI.mode==='intro'){$('#top').innerHTML='';$('#tabs').innerHTML='';$('#view').innerHTML=viewIntro();$('#modal').innerHTML='';return}
 renderTop();renderTabs();
 const v=$('#view');
 const m=UI.mode;
 if(m==='prematch')v.innerHTML=viewPrematch();
 else if(m==='levelup')v.innerHTML=viewLevelUp();
 else if(m==='result')v.innerHTML=viewResult();
 else if(m==='draft')v.innerHTML=viewDraft();
 else if(m==='cupdone')v.innerHTML=viewCupDone();
 else if(m==='season')v.innerHTML=viewSeason();
 else v.innerHTML=({club:viewClub,roster:viewRoster,market:viewMarket,shop:viewShop,league:viewLeague,leaders:viewLeaders,bestiary:viewBestiary,legacy:viewLegacy})[UI.tab]();
 renderModal();
}
function viewClub(){
 const e=curEvent(),st=standings(),pos=st.findIndex(r=>r.id==='P')+1,me=st[pos-1],pc=G.clubs.P;
 let bill='';
 if(e&&e.t==='league'){const opp=leagueOpp(e.r),oc=G.clubs[opp],os=st.find(r=>r.id===opp),op=st.indexOf(os)+1;
  bill=`<div class="kicker">${TIERS[G.tier].n} · Matchday ${e.r+1} of 14 · 5v5</div>
  <div class="versus"><div class="side">${crest(pc,52)}<div><div class="nm">${esc(G.name)}</div><div class="dust">${ordinal(pos)} · ${me.w}–${me.l} · ${formStr(me.form)||'<span class="mute">no bouts yet</span>'}</div></div></div>
  <div class="vs">vs</div>
  <div class="side r"><div><div class="nm">${esc(oc.name)}</div><div class="dust">${ordinal(op)} · ${os.w}–${os.l} · ${formStr(os.form)||'<span class="mute">no bouts yet</span>'}</div></div>${crest(oc,52)}</div></div>
  <p>A win pays ${Math.round(70*(1+G.tier*.4))} gold and a loss ${Math.round(30*(1+G.tier*.4))}, plus ${Math.round(5*(1+G.tier*.4))} per takedown and bonuses for flawless wins and upsets.</p><div class="acts"><button class="btn pri" data-act="next">Scout and set the lineup</button></div>`}
 else if(e&&e.t==='cup'){bill=`<div class="kicker">Cup day · ${e.fmt}v${e.fmt} knockout</div><h2 style="font-size:40px;margin-top:10px">${CUPN[e.fmt]}</h2><p>Eight clubs, three rounds, ${e.fmt} beasts a side. Energy carries from round to round with no rest in between, so this is where the rest of your roster earns its keep. Rotate pairs, or ride your best combination and hope it holds.</p><div class="acts"><button class="btn pri" data-act="next">${G.cup?'Continue the cup':'Enter the cup'}</button></div>`}
 else if(e&&e.t==='draft'){bill=`<div class="kicker">Cup day · 5v5 draft knockout</div><h2 style="font-size:40px;margin-top:10px">${CUPN[5]}</h2><p>Draft five loaned beasts from the open pool and fight a three-round knockout. Your own roster rests for the day. Win it and one beast from your draft can sign with the club for good.</p><div class="acts"><button class="btn pri" data-act="next">${G.draft?'Continue the draft':'Open the draft'}</button></div>`}
 const up=G.sched.slice(G.day,G.day+8).map((x,i)=>`<span class="pill ${i===0?'now':''} ${x.t!=='league'?'cup':''}">${eventLabel(x)}${x.t==='league'?` · ${esc(clubName(leagueOpp(x.r)))}`:''}</span>`).join('');
 const mine=pc.roster.map(id=>G.beasts[id]).filter(Boolean);
 const stand=mine.slice().sort((a,b)=>b.season.imp-a.season.imp).slice(0,3);
 const bonds=Object.entries(G.bonds).map(([k,v])=>{const[a,b]=k.split('|');return{a:G.beasts[a],b:G.beasts[b],v}}).filter(x=>x.a&&x.b&&x.a.clubId==='P'&&x.b.clubId==='P').sort((x,y)=>y.v.w-x.v.w||y.v.m-x.v.m).slice(0,4);
 const tired=mine.filter(b=>b.energy<50),skpN=mine.reduce((s,b)=>s+(b.rolls||0),0),injd=mine.filter(b=>b.inj),awk=mine.filter(b=>b.awaken&&b.awaken.length);
 return`<div class="stack">
 <section class="bill">${bill}</section>
 <div class="strip" aria-label="Upcoming">${up}</div>
 <div class="grid2">
  <section class="panel"><div class="row between"><h3>Club dispatch</h3><span class="lbl">Latest first</span></div>
   <ul class="news" style="margin-top:8px">${G.news.slice(0,14).map(n=>`<li><span class="when">S${n.s}·D${n.d}</span><span class="${n.kind==='mile'?'mile':n.kind==='bond'?'bond':''}">${esc(n.text)}</span></li>`).join('')}</ul></section>
  <div class="stack">
   <section class="panel"><div class="row between"><h3>Standouts this season</h3><button class="linkbtn" data-act="tab" data-k="leaders">Leaders</button></div>
    ${stand.some(b=>b.season.m)?stand.map(b=>`<div class="row" style="margin-top:10px;cursor:pointer" data-act="profile" data-id="${b.id}">${tok(b)}<div style="min-width:0"><div style="font-weight:700">${fullName(b)}</div><div class="dust" style="font-size:13px">${b.season.k} takedowns · ${Math.round(b.season.imp)} impact · ${b.season.m} bouts</div></div></div>`).join(''):'<p class="empty">No bouts fought yet.</p>'}</section>
   <section class="panel"><h3>Trusted combinations</h3>
    ${bonds.length?bonds.map(x=>{const l=bondLvl(x.a.id,x.b.id);return`<div class="row between" style="margin-top:10px"><div class="row" style="gap:6px">${tok(x.a,'sm')}${tok(x.b,'sm')}<span>${esc(x.a.name)} &amp; ${esc(x.b.name)}</span></div><span class="dust" style="font-size:13px">${l?`<span class="gold">${BOND_N[l]}</span> · `:''}${x.v.w}W in ${x.v.m}</span></div>`}).join(''):'<p class="empty">Beasts who win together build bonds. Familiar, Trusted and Blood-sworn pairs fight harder side by side.</p>'}</section>
   <section class="panel"><h3>Kennel report</h3>
    <p style="margin:8px 0 0;color:var(--dust)">${mine.length}/12 beasts · upkeep ${playerUpkeep()} gold per matchday.${tired.length?` <span class="bad">${tired.map(b=>esc(b.name)).join(', ')} ${tired.length>1?'are':'is'} tired and fight${tired.length>1?'':'s'} below full strength.</span>`:' Everyone is fresh.'}</p>
    ${skpN?`<p style="margin:8px 0 0" class="gold">${skpN} skill pick${skpN>1?'s':''} waiting. Open a beast's Skills tab to choose.</p>`:''}${awk.length?`<p style="margin:8px 0 0" class="gold">Ready to awaken: ${awk.map(b=>esc(b.name)).join(', ')}.</p>`:''}${injd.length?`<p class="bad" style="margin:8px 0 0">Injured: ${injd.map(b=>`${esc(b.name)} (${b.inj} day${b.inj>1?'s':''})`).join(', ')}.</p>`:''}
    <p style="margin:8px 0 0"><button class="linkbtn" data-act="guide">Read the field guide</button></p></section>
   <section class="panel"><div class="row between"><h3>Purse</h3><button class="linkbtn" data-act="tab" data-k="shop">Item shop</button></div>
    ${G.ledger.length?G.ledger.slice(0,8).map(l=>`<div class="row between" style="padding:5px 0;border-bottom:1px solid #2a2532;font-size:14px"><span class="dust">${esc(l.label)}</span><span class="num ${l.amt>0?'good':'bad'}">${l.amt>0?'+':''}${fmt(l.amt)}</span></div>`).join(''):'<p class="empty">Income and spending will show here.</p>'}</section>
  </div></div></div>`;
}
function ordinal(n){const s=['th','st','nd','rd'],v=n%100;return n+(s[(v-20)%10]||s[v]||s[0])}
function bcard(b,extra){const s=b.season;return`<button class="bcard" data-act="profile" data-id="${b.id}">
 <div class="bhead">${tok(b,'md')}<div style="min-width:0"><div class="bname">${fullName(b)}</div><div class="bmeta">${SPECIES[b.sp].n} · ${roleOf(b)} · ${ageLabel(b.age)}</div></div><div class="ovr"><b>${ovr(b)}</b><span>OVR</span></div></div>
 <div class="row" style="gap:8px;font-size:12px;color:var(--mute)"><span>Lv ${b.lvl}</span><span>Pot ${potRange(b)}</span>${b.inj?`<span class="bad">Injured · ${b.inj}d</span>`:''}${b.rolls&&b.clubId==='P'?`<span class="gold">${b.rolls} skill${b.rolls>1?'s':''} to pick</span>`:''}${b.awaken&&b.awaken.length&&b.clubId==='P'?'<span class="gold">Awakening</span>':''}</div>
 <div class="meters"><span>Energy</span>${ebar(b.energy)}<span class="num">${b.energy}</span><span>Fatigue</span>${fbar(b.fat||0)}<span class="num">${b.fat||0}</span></div>
 <div class="kv"><span><b>${s.m}</b>Bouts</span><span><b>${s.k}</b>Takedowns</span><span><b>${s.m?Math.round(s.imp/s.m):'–'}</b>Imp/bout</span><span><b>${b.career.k}</b>Career TD</span></div>
 ${b.traits.length?`<div class="traits">${traitChips(b)}</div>`:''}${extra||''}</button>`}
function viewRoster(){
 const bs=G.clubs.P.roster.map(id=>G.beasts[id]).filter(Boolean);
 const sorts={ovr:(a,b)=>ovr(b)-ovr(a),imp:(a,b)=>b.season.imp-a.season.imp,energy:(a,b)=>b.energy-a.energy,age:(a,b)=>a.age-b.age,career:(a,b)=>b.career.imp-a.career.imp};
 bs.sort(sorts[UI.rsort]);
 return`<div class="row between" style="margin-bottom:14px"><div><h2>The kennels</h2><p class="dust" style="margin:4px 0 0">${bs.length}/12 beasts · upkeep ${playerUpkeep()} gold per matchday. Open a beast to set its tactics and training.</p></div>
 <div class="seg" role="group" aria-label="Sort">${[['ovr','Rating'],['imp','Season impact'],['career','Career'],['energy','Energy'],['age','Youngest']].map(([k,n])=>`<button class="${UI.rsort===k?'on':''}" data-act="rsort" data-k="${k}">${n}</button>`).join('')}</div></div>
 <div class="cards">${bs.map(b=>bcard(b)).join('')}</div>`;
}
function viewMarket(){
 const bs=G.market.map(id=>G.beasts[id]).filter(Boolean);const full=G.clubs.P.roster.length>=12;
 return`<div class="row between" style="margin-bottom:14px"><div><h2>Beast market</h2><p class="dust" style="margin:4px 0 0">Two listings turn over each matchday. Higher renown draws better stock. Whelps are cheap and raw; their potential shows as a range until they have fought a few bouts.</p></div><button class="btn" data-act="mrefresh" ${G.gold<25?'disabled':''}>Send scouts out · 25 gold</button></div>
 ${full?'<p class="bad">Your kennels are full (12). Sell a beast to make room.</p>':''}
 <div class="cards">${bs.map(b=>bcard(b,`<div class="row between" style="margin-top:2px"><span class="gold num" style="font-size:15px">${fmt(value(b))} gold</span><span class="mute" style="font-size:12px">Upkeep ${upkeep(b)}/day</span></div>`)).join('')}</div>`;
}
function viewLeague(){
 const st=standings(),cur=leagueRoundNow();if(UI.round==null)UI.round=Math.min(cur,13);const r=UI.round;
 const fix=G.league.fix[r],res=G.league.res[r]||[];
 const t=G.tier;
 return`<div class="grid2"><section class="panel"><div class="row between"><h3>${TIERS[t].n} table</h3><span class="lbl">Top 2 up${t>0?' · Bottom 2 down':''}</span></div>
 <div class="tw" style="margin-top:8px"><table><thead><tr><th>#</th><th>Club</th><th class="n">P</th><th class="n">W</th><th class="n">L</th><th class="n">TD±</th><th class="n">Pts</th><th>Form</th></tr></thead><tbody>
 ${st.map((x,i)=>`<tr class="${x.id==='P'?'me':''} ${i<2&&t<3?'zup':''} ${i>5&&t>0?'zdn':''}"><td class="num">${i+1}</td><td><span class="cell">${crest(G.clubs[x.id],18)}${esc(clubName(x.id))}</span></td><td class="n">${x.p}</td><td class="n">${x.w}</td><td class="n">${x.l}</td><td class="n">${x.kd>0?'+':''}${x.kd}</td><td class="n"><b>${x.pts}</b></td><td>${formStr(x.form)}</td></tr>`).join('')}
 </tbody></table></div></section>
 <section class="panel"><div class="row between"><h3>Matchday ${r+1}</h3><div class="row" style="gap:6px"><button class="btn sm" data-act="rnd" data-d="-1" ${r<=0?'disabled':''} aria-label="Previous matchday">‹</button><button class="btn sm" data-act="rnd" data-d="1" ${r>=13?'disabled':''} aria-label="Next matchday">›</button></div></div>
 <div style="margin-top:8px">${fix.map(p=>{const m=res.find(x=>(x.a===p[0]&&x.b===p[1])||(x.a===p[1]&&x.b===p[0]));const w=m&&m.w;const ka=m?(m.a===p[0]?m.ka:m.kb):null,kb=m?(m.a===p[0]?m.kb:m.ka):null;return`<div class="row between" style="padding:8px 0;border-bottom:1px solid #2a2532;font-size:14px;${p.includes('P')?'color:var(--bronze)':''}"><span class="${w===p[0]?'':'dust'}" style="flex:1;${w===p[0]?'font-weight:700':''}">${esc(clubName(p[0]))}</span><span class="num mute" style="font-size:12px;padding:0 8px">${m?`${ka}–${kb}`:'vs'}</span><span class="${w===p[1]?'':'dust'}" style="flex:1;text-align:right;${w===p[1]?'font-weight:700':''}">${esc(clubName(p[1]))}</span></div>`}).join('')}</div>
 <p class="note" style="margin-top:10px">Scores show takedowns. Ties on points break on takedown difference.</p></section></div>`;
}
const LEADS=[['imp','Impact'],['k','Takedowns'],['a','Assists'],['dmg','Damage'],['tank','Absorbed'],['heal','Healing & shields'],['cc','Control (s)']];
function viewLeaders(){
 const key=UI.lead;
 const bs=[];G.div.forEach(cid=>G.clubs[cid].roster.forEach(id=>{const b=G.beasts[id];if(b&&b.season.m)bs.push(b)}));
 bs.sort((a,b)=>b.season[key]-a.season[key]);
 const top=bs.slice(0,15);
 const car=G.clubs.P.roster.map(id=>G.beasts[id]).filter(Boolean).concat([]).sort((a,b)=>b.career[key]-a.career[key]).slice(0,6);
 return`<div class="row between" style="margin-bottom:14px"><div><h2>Division leaders</h2><p class="dust" style="margin:4px 0 0">Season ${G.season}, ${TIERS[G.tier].n}. Your beasts are highlighted.</p></div>
 <div class="seg">${LEADS.map(([k,n])=>`<button class="${key===k?'on':''}" data-act="lead" data-k="${k}">${n}</button>`).join('')}</div></div>
 <div class="grid2"><section class="panel"><div class="tw"><table><thead><tr><th>#</th><th>Beast</th><th>Club</th><th class="n">Bouts</th><th class="n">${LEADS.find(x=>x[0]===key)[1]}</th><th class="n">Per bout</th></tr></thead><tbody>
 ${top.length?top.map((b,i)=>`<tr class="${b.clubId==='P'?'me':''}"><td class="num">${i+1}</td><td><span class="cell" style="cursor:pointer" data-act="profile" data-id="${b.id}">${tok(b,'sm'+(b.clubId==='P'?'':' en'))}<span><b>${esc(b.name)}</b> <span class="mute">${SPECIES[b.sp].n}</span></span></span></td><td class="dust">${esc(clubName(b.clubId))}</td><td class="n">${b.season.m}</td><td class="n"><b>${fmt(b.season[key])}</b></td><td class="n">${(b.season[key]/b.season.m).toFixed(1)}</td></tr>`).join(''):'<tr><td colspan="6" class="empty">No bouts fought yet this season.</td></tr>'}
 </tbody></table></div></section>
 <section class="panel"><h3>Club career leaders</h3><p class="note" style="margin:4px 0 8px">${LEADS.find(x=>x[0]===key)[1]}, all seasons, current roster.</p>
 ${car.map((b,i)=>`<div class="row between" style="padding:6px 0;border-bottom:1px solid #2a2532;cursor:pointer" data-act="profile" data-id="${b.id}"><span class="cell"><span class="num mute" style="width:18px">${i+1}</span>${tok(b,'sm')}<span>${fullName(b)}</span></span><span class="num">${fmt(b.career[key])}</span></div>`).join('')}</section></div>`;
}
function viewLegacy(){
 const recs=[['k','Most takedowns in a bout'],['dmg','Most damage in a bout'],['heal','Most healing in a bout'],['streak','Longest league win streak']];
 const cur=G.clubs.P.roster.map(id=>G.beasts[id]).filter(b=>b&&b.career.m).sort((a,b)=>b.career.imp-a.career.imp).slice(0,6);
 return`<div class="stack"><div><h2>Legacy</h2><p class="dust" style="margin:4px 0 0">What ${esc(G.name)} has won, and the beasts who won it.</p></div>
 <section class="panel"><h3>Trophy cabinet</h3><div class="plaques" style="margin-top:10px">${G.trophies.length?G.trophies.slice().reverse().map(t=>`<div class="plaque"><b>${esc(t.name)}</b><span class="dust" style="font-size:13px">Season ${t.s} · ${TIERS[t.tier].n}</span></div>`).join(''):'<p class="empty">The cabinet is empty. Cups come around three times a season.</p>'}</div></section>
 <div class="grid2"><section class="panel"><h3>Seasons</h3><div class="tw" style="margin-top:8px"><table><thead><tr><th>Season</th><th>Division</th><th class="n">Finish</th><th class="n">W–L</th><th>Cups</th><th>Club MVP</th></tr></thead><tbody>
 ${G.history.length?G.history.map(h=>`<tr><td class="num">${h.s}</td><td>${TIERS[h.tier].n}${h.move===1?' <span class="good">↑</span>':h.move===-1?' <span class="bad">↓</span>':''}</td><td class="n">${ordinal(h.pos)}</td><td class="n">${h.w}–${h.l}</td><td style="white-space:normal;font-size:13px" class="dust">${h.cups.map(c=>`${esc(c.name.replace(' Cup',''))}: ${esc(c.res)}`).join('<br>')}</td><td>${esc(h.mvp)}</td></tr>`).join(''):'<tr><td colspan="6" class="empty">Your first season is under way.</td></tr>'}</tbody></table></div></section>
 <section class="panel"><h3>Club records</h3>${recs.map(([k,n])=>{const r=G.records[k];return`<div class="row between" style="padding:8px 0;border-bottom:1px solid #2a2532"><span class="dust">${n}</span><span>${r?`<b class="num">${fmt(r.v)}</b> · ${esc(r.name)} <span class="mute">S${r.s}</span>`:'<span class="mute">—</span>'}</span></div>`}).join('')}</section></div>
 <section class="panel"><h3>Pillars of the club</h3><p class="note" style="margin:4px 0 0">Current roster by career impact.</p><div class="cards" style="margin-top:10px">${cur.length?cur.map(b=>`<button class="bcard" data-act="profile" data-id="${b.id}"><div class="bhead">${tok(b)}<div><div class="bname">${fullName(b)}</div><div class="bmeta">${SPECIES[b.sp].n} · ${esc(b.joined)}</div></div></div><div class="kv"><span><b>${b.career.m}</b>Bouts</span><span><b>${b.career.w}</b>Wins</span><span><b>${b.career.k}</b>Takedowns</span><span><b>${Math.round(b.career.imp)}</b>Impact</span></div>${b.titles.length?`<div class="gold" style="font-size:13px">${b.titles.map(esc).join('<br>')}</div>`:''}</button>`).join(''):'<p class="empty">No careers written yet.</p>'}</div></section>
 <section class="panel"><h3>Hall of legends</h3><p class="note" style="margin:4px 0 0">Beasts who have left the club, sold or retired after at least ten bouts.</p>
 ${G.alumni.length?`<div class="tw" style="margin-top:8px"><table><thead><tr><th>Beast</th><th>Left</th><th class="n">Bouts</th><th class="n">TD</th><th class="n">Impact</th><th class="n">Peak</th><th>Honours</th></tr></thead><tbody>${G.alumni.map(a=>`<tr><td><span class="cell">${tok(a,'sm')}<span><b>${esc(a.name)}</b> ${esc(a.epithet)} <span class="mute">${SPECIES[a.sp].n}</span></span></span></td><td class="dust">${esc(a.left)}</td><td class="n">${a.career.m}</td><td class="n">${a.career.k}</td><td class="n">${Math.round(a.career.imp)}</td><td class="n">${a.peak}</td><td class="gold" style="white-space:normal;font-size:13px">${a.titles.map(esc).join('<br>')||'<span class="mute">—</span>'}</td></tr>`).join('')}</tbody></table></div>`:'<p class="empty" style="margin-top:8px">No one has left yet.</p>'}</section></div>`;
}
function scoutTips(mine,th){
 const tips=[],nm=a=>a.map(b=>b.name).join(' and ');
 const back=th.filter(b=>ROLE_LINE[roleOf(b)]==='back');if(back.length>=2)tips.push(`${back.length} of their beasts fight from the back. Divers and “Dive the backline” targeting will find soft targets.`);
 const heal=th.filter(b=>['treant','naga','unicorn'].includes(b.sp));if(heal.length)tips.push(`${nm(heal)} keeps them standing. “Hunt healers & casters” puts pressure on it.`);
 const dv=th.filter(b=>['Assassin','Diver','Trickster'].includes(roleOf(b)));if(dv.length>=2)tips.push(`Expect dives from ${nm(dv)}. Set your backliners to keep distance, or bring a Naga's shield.`);
 if(th.some(b=>b.sp==='golem'))tips.push('Their Stone Golem taunts anything close. Ranged beasts that keep distance stay out of its pull.');
 if(th.some(b=>b.sp==='phoenix'))tips.push('Their Phoenix rises once after falling. It has to be put down twice.');
 if(th.filter(b=>ROLE_LINE[roleOf(b)]==='front').length>=2&&mine.some(b=>AOE.has(SPECIES[b.sp].ab)))tips.push('They stack two bodies up front. Area abilities set to “Wait for clusters” should catch both.');
 th.filter(b=>b.energy<50&&!b.draft).forEach(b=>tips.push(`${b.name} is tired (${b.energy} energy) and fights below full strength.`));
 const tk=th.slice().sort((a,b)=>b.season.k-a.season.k)[0];if(tk&&tk.season.k>=3)tips.push(`Watch ${tk.name}: ${tk.season.k} takedowns this season.`);
 mine.filter(b=>b.energy<50&&!b.draft).forEach(b=>tips.push(`Your ${b.name} is tired (${b.energy} energy). A bench beast may do more.`));
 mine.filter(b=>(b.fat||0)>55&&!b.draft).forEach(b=>tips.push(`${b.name} carries ${b.fat} fatigue and risks injury. A day on the bench would help.`));
 return tips.slice(0,7);
}
function partnerSel(b,pool,ro,pre){const st=b.tactics.stance,on=st==='guard'||st==='assist';return`<select id="${pre||''}pt-${b.id}" data-chg="partner" data-id="${b.id}" aria-label="Partner" ${ro||!on?'disabled':''}><option value="">${st==='guard'?'Guard whom?':st==='assist'?'Assist whom?':'No partner'}</option>${pool.filter(o=>o&&o.id!==b.id).map(o=>`<option value="${o.id}" ${b.tactics.partner===o.id?'selected':''}>${esc(o.name)} · ${SPECIES[o.sp].n}</option>`).join('')}</select>`}
function tacSel(b,k,ro,pre){const label={target:'Target priority',pos:'Starting position',ability:'Ability use',stance:'Stance',retreatAt:'Fall back at'}[k]||k;return`<select id="${pre||''}t-${b.id}-${k}" data-chg="tac" data-id="${b.id}" data-k="${k}" aria-label="${label}" ${ro?'disabled':''}>${TAC_OPTS[k].map(([v,n])=>`<option value="${v}" ${String(b.tactics[k])===v?'selected':''}>${n}</option>`).join('')}</select>`}
function viewPrematch(){
 const c=UI.ctx,oc=G.clubs[c.opp],fmtN=c.fmt;
 const pool=c.draft?G.cup.teams.P.map(id=>G.beasts[id]):G.clubs.P.roster.map(id=>G.beasts[id]).filter(Boolean);
 const sel=UI.sel.map(id=>G.beasts[id]).filter(Boolean);
 const bench=pool.filter(b=>!UI.sel.includes(b.id)).sort((a,b)=>lineScore(b)-lineScore(a));
 const healthy=pool.filter(b=>!b.inj).length;const th=c.draft?G.cup.teams[c.opp].map(id=>G.beasts[id]):pickLineup(c.opp,fmtN);
 const st=standings(),os=st.find(r=>r.id===c.opp);
 const avg=a=>a.length?a.reduce((s,b)=>s+ovr(b)*(b.draft?1:energyFactor(b.energy)),0)/a.length:0;
 const ma=avg(sel),ta=avg(th),share=ma+ta?ma/(ma+ta)*100:50;
 const bb=bondBonus(sel),bonds=[];for(let i=0;i<sel.length;i++)for(let j=i+1;j<sel.length;j++){const l=c.draft?0:bondLvl(sel[i].id,sel[j].id);if(l)bonds.push(`${sel[i].name} & ${sel[j].name}: ${BOND_N[l]} (+${l*3}%)`)}
 const title=campaignLabel(c);
 return`<div class="row between" style="margin-bottom:14px"><div><div class="lbl">${title} · ${fmtN}v${fmtN}</div><h2 style="margin-top:4px">${esc(G.name)} vs ${esc(oc.name)}</h2></div>
 <div class="row"><button class="btn" data-act="go" data-w="0" ${sel.length!==fmtN?'disabled':''}>Sim result</button><button class="btn pri" data-act="go" data-w="1" ${sel.length!==fmtN?'disabled':''}>Enter the arena</button></div></div>
 <div class="grid2">
 <section class="panel"><div class="row between"><h3>Your lineup <span class="num dust" style="font-size:15px">${sel.length}/${fmtN}</span></h3>${c.draft?'<span class="lbl">Drafted five</span>':`<button class="btn sm" data-act="autopick">Best rested</button>`}</div>
  <div style="margin-top:6px">${sel.map(b=>`<div class="lrow">${tok(b)}<div style="min-width:0"><button class="linkbtn" style="color:var(--sand)" data-act="profile" data-id="${b.id}">${esc(b.name)}</button> <span class="dust" style="font-size:13px">${SPECIES[b.sp].n} · ${roleOf(b)} · OVR ${ovr(b)}</span>${b.draft?'':`<div class="row" style="gap:8px;margin-top:4px"><span style="width:90px">${ebar(b.energy)}</span><span class="mute" style="font-size:12px">${b.energy} energy · ${b.fat||0} fatigue${b.energy<50?' · tired':''}${b.inj?' · <span class="bad">injured, fights at 70%</span>':''}</span></div>`}</div>${c.draft?'':`<button class="btn sm" data-act="unsel" data-id="${b.id}" aria-label="Bench ${esc(b.name)}">Bench</button>`}
   <details class="quick-tactics" data-tactics="${b.id}" ${UI.quickTactics?.includes(b.id)?'open':''}><summary>Quick tactics · ${esc(b.name)}</summary><div class="tacs"><label>Target priority${tacSel(b,'target')}</label><label>Starting line${tacSel(b,'pos')}</label><label>Ability use${tacSel(b,'ability')}</label><label>Stance${tacSel(b,'stance')}</label><label>Partner${partnerSel(b,sel)}</label><label>Fall back at${tacSel(b,'retreatAt')}</label></div><p class="note">For posture, teamwork, and presets, open this beast’s Tactics tab.</p></details>${['guard','assist'].includes(b.tactics.stance)&&b.tactics.partner&&!UI.sel.includes(b.tactics.partner)?`<div class="note bad" style="grid-column:1/-1">${esc(G.beasts[b.tactics.partner]?G.beasts[b.tactics.partner].name:'Its partner')} is benched, so ${esc(b.name)} will just advance.</div>`:''}</div>`).join('')||'<p class="empty">Pick beasts from the bench below.</p>'}</div>
  ${c.draft?'':`<div class="lbl" style="margin:14px 0 8px">Bench</div><div class="bench">${bench.map(b=>`<button class="bchip" data-act="sel" data-id="${b.id}" ${sel.length>=fmtN||(b.inj&&healthy>=fmtN)?'disabled':''}>${tok(b,'sm')}<span>${esc(b.name)} <span class="mute">${ovr(b)} · ${b.energy}e · ${b.fat||0}f</span>${b.inj?` <span class="bad">injured ${b.inj}d</span>`:''}</span></button>`).join('')||'<span class="empty">Nobody on the bench.</span>'}</div>`}
  ${bonds.length?`<div class="lbl" style="margin:14px 0 6px">Bonds in play</div><div class="dust" style="font-size:14px">${bonds.map(esc).join('<br>')}</div>`:''}
 </section>
 <section class="panel"><div class="row">${crest(oc,40)}<div><h3>Scouting report</h3><div class="dust" style="font-size:14px">${os?`${ordinal(st.indexOf(os)+1)} · ${os.w}–${os.l} · ${formStr(os.form)}`:''}</div></div></div>
  <div class="tw" style="margin-top:10px"><table><thead><tr><th>Expected</th><th class="n">OVR</th><th>Plays</th><th class="n">TD</th></tr></thead><tbody>
  ${th.map(b=>`<tr><td><span class="cell" style="cursor:pointer" data-act="profile" data-id="${b.id}">${tok(b,'sm en')}<span><b>${esc(b.name)}</b> <span class="mute">${SPECIES[b.sp].n}</span></span></span></td><td class="n">${ovr(b)}</td><td class="dust" style="font-size:13px">${TAC_OPTS.target.find(x=>x[0]===b.tactics.target)[1]}${b.tactics.stance&&b.tactics.stance!=='advance'?' · '+TAC_OPTS.stance.find(x=>x[0]===b.tactics.stance)[1]+(b.tactics.partner&&G.beasts[b.tactics.partner]?' '+esc(G.beasts[b.tactics.partner].name):''):''}</td><td class="n">${b.season.k}</td></tr>`).join('')}</tbody></table></div>
  <div class="lbl" style="margin:14px 0 6px">Strength on paper</div>
  <div class="edge"><i style="width:${share}%"></i><i style="width:${100-share}%"></i></div>
  <div class="row between num" style="font-size:12px;margin-top:4px"><span class="gold">${ma.toFixed(1)}</span><span class="bad">${ta.toFixed(1)}</span></div>
  <div class="lbl" style="margin:14px 0 6px">Notes</div><ul class="tips">${scoutTips(sel,th).map(t=>`<li>${esc(t)}</li>`).join('')||'<li>Nothing unusual about this lineup.</li>'}</ul>
 </section></div>`;
}
function viewBattle(c,S){
 const oc=G.clubs[c.opp];
 return`<div class="bhdr"><div class="row">${crest(G.clubs.P,30)}<span class="t">${esc(G.name)}</span><span class="num gold" id="scoreA" style="font-size:20px">${c.fmt}</span></div><span class="lbl">${esc(campaignLabel(c))}</span><div class="row"><span class="num bad" id="scoreB" style="font-size:20px">${c.fmt}</span><span class="t">${esc(oc.name)}</span>${crest(oc,30)}</div></div>
 <div class="stage"><canvas id="cv" width="1280" height="740" aria-label="Arena"></canvas><div class="clock" id="clock">0s</div><div class="feed" id="feed"></div></div>
 <div class="row between" style="margin-top:10px"><div class="seg" role="group" aria-label="Speed"><button data-act="pause" id="bp">Pause</button>${[1,2,4].map(s=>`<button data-act="speed" data-s="${s}" class="${s===1?'on':''}">${s}×</button>`).join('')}</div><button class="btn sm" data-act="skip">Skip to result</button></div>
 <div class="sides"><div class="panel" style="padding:10px 12px"><div class="lbl" style="margin-bottom:4px">${esc(G.name)} · K/D/A</div><div id="sideA"></div></div><div class="panel" style="padding:10px 12px"><div class="lbl" style="margin-bottom:4px">${esc(oc.name)} · K/D/A</div><div id="sideB"></div></div></div>
 <p class="note">Bronze rings are yours, crimson are theirs. The thin blue line under each health bar fills as the ability charges.</p>`;
}
function boxTable(rows,team,mvpId){return`<div class="tw"><table><thead><tr><th>Beast</th><th class="n">K</th><th class="n">D</th><th class="n">A</th><th class="n">Dmg</th><th class="n">Absorbed</th><th class="n">Heal</th><th class="n">CC</th><th class="n">Impact</th>${team===0?'<th class="n">XP</th>':''}</tr></thead><tbody>
 ${rows.filter(r=>r.team===team).sort((a,b)=>b.imp-a.imp).map(r=>`<tr class="${r.bid===mvpId?'me':''}"><td><span class="cell">${tok(r,'sm'+(team?' en':''))}<span><b>${esc(r.name)}</b>${r.alive?'':' <span class="mute">fell</span>'}</span></span></td><td class="n">${r.st.k}</td><td class="n">${r.st.d}</td><td class="n">${r.st.a}</td><td class="n">${fmt(r.st.dmg)}</td><td class="n">${fmt(r.st.tank)}</td><td class="n">${fmt(r.st.heal)}</td><td class="n">${r.st.cc.toFixed(1)}</td><td class="n"><b>${Math.round(r.imp)}</b></td>${team===0?`<td class="n">+${r.xp}${r.ups?` <span class="gold">Lv${r.lvl}</span>`:''}</td>`:''}</tr>`).join('')}</tbody></table></div>`}
function viewResult(){
 const R=UI.result,c=R.ctx,won=R.winner===0,oc=G.clubs[c.opp];
 const mvp=R.rows.slice().sort((a,b)=>b.imp-a.imp)[0];
 const cu=G.cup;
 let next='Continue';if(c.kind==='cup'){if(cu.champ)next='See the cup result';else next=`On to the ${RNAME[cu.ri]}`}
 return`<div class="stack"><section class="bill"><div class="kicker">${esc(campaignLabel(c))} · ${Math.round(R.t)}s${R.timeout?' · decided on remaining health':''}</div>
 <div class="banner ${won?'gold':'bad'}" style="margin-top:8px">${won?'Victory':'Defeat'}</div>
 <p style="font-size:17px;color:var(--sand)">${esc(G.name)} ${R.ka} – ${R.kb} ${esc(oc.name)} <span class="dust">in takedowns</span></p>
 <div class="purse-list">${(R.purse||[]).map(([l,a])=>`<div><span>${esc(l)}</span><span class="num gold">+${fmt(a)}</span></div>`).join('')}<div class="tot"><b>Gold earned</b><b class="num gold">+${fmt(R.gold)}</b></div>${R.ren?`<div><span>Renown</span><span class="num">+${R.ren}</span></div>`:''}</div>
 ${mvp?`<div class="mvp" style="margin-top:16px">${tok(mvp,'big'+(mvp.team?' en':''))}<div><div class="lbl">Bout MVP</div><div style="font:700 26px var(--disp)">${esc(mvp.name)}</div><div class="dust">${esc(mvp.team?oc.name:G.name)} · ${mvp.st.k} takedowns · ${fmt(mvp.st.dmg)} damage · ${Math.round(mvp.imp)} impact</div></div></div>`:''}
 <div class="acts"><button class="btn pri" data-act="resnext">${UI.lvq&&UI.lvq.length?`Choose powers · ${UI.lvq.length} beast${UI.lvq.length>1?'s':''}`:next}</button></div></section>
 ${R.mil.length||R.notes.length?`<section class="panel"><h3>Written into the record</h3><ul class="tips" style="margin-top:8px">${R.notes.concat(R.mil).map(t=>`<li>${esc(t)}</li>`).join('')}</ul></section>`:''}
 ${(()=>{const gr=R.rows.filter(r=>r.team===0&&r.ups);return gr.length?`<section class="panel"><h3>Level ups</h3>${gr.map(r=>{const bb=G.beasts[r.bid],own=bb&&bb.clubId==='P';return`<div class="row" style="margin-top:12px">${tok(r)}<div style="flex:1;min-width:200px"><div><b>${esc(r.name)}</b> reached level ${r.lvl} <span class="dust">from ${r.lv0}</span></div><div class="dust" style="font-size:13px">${Object.entries(r.gains||{}).map(([k,v])=>`+${v.toFixed(1)} ${ATTR_N[k]}`).join(' · ')}${own?` · <span class="gold">+${r.ups} skill pick${r.ups>1?'s':''}</span>`:''}${own&&r.aw?' · <span class="gold">ready to awaken</span>':''}</div></div>${own?`<button class="btn sm" data-act="profile" data-id="${r.bid}" data-pt="skills">Pick skill</button>`:''}</div>`}).join('')}</section>`:''})()}
 <section class="panel"><h3>${esc(G.name)}</h3>${boxTable(R.rows,0,mvp&&mvp.bid)}</section>
 <section class="panel"><h3>${esc(oc.name)}</h3>${boxTable(R.rows,1,mvp&&mvp.bid)}</section></div>`;
}
function viewDraft(){
 const d=G.draft,n=d.picks.length+1;
 const picks=d.picks.map(id=>G.beasts[id]),offers=d.offers.map(id=>G.beasts[id]);
 return`<div class="stack"><div><div class="lbl">${CUPN[5]} · Pick ${n} of 5</div><h2 style="margin-top:4px">Choose a beast for the loan pool</h2><p class="dust" style="margin:4px 0 0;max-width:65ch">Each pick offers four beasts. Think about the whole five: a front to hold, flankers to break the line, and something at the back. Drafted beasts arrive fully rested.</p></div>
 <section class="panel"><div class="lbl" style="margin-bottom:8px">Your draft so far</div><div class="row">${picks.length?picks.map(b=>`<span class="bchip" style="cursor:default">${tok(b,'sm')}${esc(b.name)} <span class="mute">${roleOf(b)} · ${ovr(b)}</span></span>`).join(''):'<span class="empty">No picks yet.</span>'}</div></section>
 <div class="cards">${offers.map(b=>{const D=SPECIES[b.sp];return`<div class="bcard offer" style="cursor:default"><div class="bhead">${tok(b)}<div><div class="bname">${esc(b.name)}</div><div class="bmeta">${D.n} · ${D.role} · ${ageLabel(b.age)}</div></div><div class="ovr"><b>${ovr(b)}</b><span>OVR</span></div></div>
 <div style="font-size:13px"><b>${ABINFO[D.ab][0]}.</b> <span class="dust">${ABINFO[D.ab][1]}</span></div>${proCon(b.sp,true)}${b.traits.length?`<div class="traits">${traitChips(b)}</div>`:''}
 <div class="row"><button class="btn pri sm" data-act="dpick" data-id="${b.id}">Draft ${esc(b.name)}</button><button class="btn sm" data-act="profile" data-id="${b.id}">Details</button></div></div>`}).join('')}</div></div>`;
}
function viewCupDone(){
 const cu=G.cup,champ=cu.champ==='P';
 const drafted=cu.draft&&champ?G.cup.teams.P.map(id=>G.beasts[id]):[];
 const full=G.clubs.P.roster.length>=12;
 const br=cu.rounds.map((rr,ri)=>`<div><div class="lbl" style="margin-bottom:8px">${RNAME[ri]}</div>${rr.map((p,i)=>{const r=cu.res[ri][i];return`<div class="bm">${p.map(id=>`<div class="${r?(r.w===id?'w':'l'):''} ${id==='P'?'p':''}"><span>${esc(clubName(id))}</span></div>`).join('')}</div>`}).join('')}</div>`).join('');
 return`<div class="stack"><section class="bill"><div class="kicker">${esc(cu.name)} · ${cu.fmt}v${cu.fmt}</div>
 <h2 style="font-size:44px;margin-top:8px">${champ?'Champions':`${esc(clubName(cu.champ))} lift the cup`}</h2>
 <p>${champ?`${esc(G.name)} won all three rounds. The trophy goes in the cabinet.`:`${esc(G.name)} went out in the ${esc(cu.lostIn||'')}.`}</p>
 ${cu.draft&&champ?'':`<div class="acts"><button class="btn pri" data-act="cupfin">Back to the club</button></div>`}</section>
 ${cu.draft&&champ?`<section class="panel"><h3>Sign one of your draft</h3><p class="dust" style="margin:4px 0 12px">One beast from the winning draft may join the club permanently, keeping its stats from this cup.${full?' <span class="bad">Your kennels are full, so you can take 150 gold instead.</span>':''}</p>
  <div class="cards">${drafted.map(b=>bcard(b,`<div class="row" style="margin-top:2px"><span class="btn pri sm" data-act="keep" data-id="${b.id}" role="button" tabindex="0" ${full?'aria-disabled="true" style="opacity:.4;pointer-events:none"':''}>Sign ${esc(b.name)}</span></div>`)).join('')}</div>
  <div class="row" style="margin-top:12px"><button class="btn" data-act="keepnone">${full?'Take 150 gold':'Sign no one'}</button></div></section>`:''}
 <section class="panel"><h3>Bracket</h3><div class="tw" style="margin-top:10px"><div class="bracket">${br}</div></div></section></div>`;
}
function viewSeason(){
 const s=UI.seasonSum;
 const out=s.move===1?`Promoted to the ${TIERS[s.tier+1].n}.`:s.move===-1?`Relegated to the ${TIERS[s.tier-1].n}.`:`Staying in the ${TIERS[s.tier].n}.`;
 return`<div class="stack"><section class="bill"><div class="kicker">Season ${s.s} · ${TIERS[s.tier].n} · Final table</div>
 <h2 style="font-size:46px;margin-top:8px">${ordinal(s.pos)} place</h2><p>${out} Prize money ${fmt(s.prize)} gold, renown +${s.renown}.${s.retired.length?` Retired: ${s.retired.map(esc).join(', ')}.`:''}</p>
 <div class="acts"><button class="btn pri" data-act="seasonok">Begin Season ${s.s+1}</button></div></section>
 <div class="grid2"><section class="panel"><h3>Final table</h3><div class="tw" style="margin-top:8px"><table><thead><tr><th>#</th><th>Club</th><th class="n">W</th><th class="n">L</th><th class="n">Pts</th></tr></thead><tbody>${s.st.map((r,i)=>`<tr class="${r.id==='P'?'me':''} ${i<2&&s.tier<3?'zup':''} ${i>5&&s.tier>0?'zdn':''}"><td class="num">${i+1}</td><td>${esc(r.name)}</td><td class="n">${r.w}</td><td class="n">${r.l}</td><td class="n"><b>${r.pts}</b></td></tr>`).join('')}</tbody></table></div></section>
 <div class="stack"><section class="panel"><h3>Division awards</h3>${s.awards.map(a=>`<div class="row" style="margin-top:10px">${tok(a,'sm'+(a.mine?'':' en'))}<div><div><b>${esc(a.label)}</b> · ${esc(a.name)}</div><div class="dust" style="font-size:13px">${esc(a.club)} · ${fmt(a.v)}</div></div></div>`).join('')}</section>
 <section class="panel"><h3>Cups</h3>${s.cups.map(c=>`<div class="row between" style="padding:6px 0;border-bottom:1px solid #2a2532"><span>${esc(c.name)}</span><span class="${c.res==='Champions'?'gold':'dust'}">${esc(c.res)}</span></div>`).join('')}</section></div></div></div>`;
}

/* ============ MODALS ============ */
function renderModal(){
 const m=UI.modal,el=$('#modal');
 if(!m){el.innerHTML='';return}
 let html='';
 if(m.k==='profile')html=modalProfile(m);
 else if(m.k==='settings')html=modalSettings(m);
 else if(m.k==='guide')html=modalGuide();
 else if(m.k==='reward')html=modalReward();
 else if(m.k==='runmenu')html=modalRunMenu();
 el.innerHTML=`<div class="scrim" data-act="scrim"><div class="sheet" role="dialog" aria-modal="true">${html}<button class="btn sm xbtn" data-act="close" aria-label="Close">Close</button></div></div>`;
}
function pips(r,max){let h='';for(let i=0;i<max;i++)h+=`<i class="${i<r?'on':''}"></i>`;return`<span class="pips" aria-label="Rank ${r} of ${max}">${h}</span>`}
function skillsHtml(b,edit){
 const ab=SPECIES[b.sp].ab;
 const cols=Object.keys(BRANCH).map(br=>{const pts=brPts(b,br);
  const rows=Object.keys(SKILLS).filter(k=>SKILLS[k].br===br).map(k=>{const sk=SKILLS[k],r=(b.skills||{})[k]||0,locked=sk.req&&pts<sk.req;
   const name=k==='sig'?`Signature: ${SIG[ab][0]}`:sk.n;
   const desc=k==='sig'?SIG[ab][1]:(r?sk.d(r):sk.d(1))+(r&&r<sk.max?`. Next rank: ${sk.d(r+1)}`:'');
   return`<div class="skill ${r?'has':''} ${locked?'locked':''}"><div class="row between" style="gap:6px"><b>${esc(name)}</b>${pips(r,sk.max)}</div><div class="dust" style="font-size:13px">${esc(desc)}</div>${locked?`<div class="note">Needs ${sk.req} points in ${BRANCH[br]}</div>`:''}${edit&&canLearn(b,k)?`<div><button class="btn sm" data-act="learn" data-id="${b.id}" data-k="${k}">${r?'Rank up':'Learn'}</button></div>`:''}</div>`}).join('');
  return`<div><div class="row between"><h3 style="font-size:20px">${BRANCH[br]}</h3><span class="num dust" style="font-size:12px">${pts} pts</span></div>${rows}</div>`}).join('');
 return`<div class="row between">${edit?`<span><b class="gold num">${b.skp||0}</b> skill point${b.skp===1?'':'s'} to spend · one per level</span>`:'<span class="dust">Skills learned</span>'}${edit&&b.skp?`<button class="btn sm" data-act="autolearn" data-id="${b.id}">Spend for me</button>`:''}</div><div class="skillcols">${cols}</div>`;
}
function statRatings(sp){const D=SPECIES[sp];const all=SPK.map(k=>SPECIES[k]);const r=(f)=>{const v=all.map(f),lo=Math.min(...v),hi=Math.max(...v);return Math.max(1,Math.min(5,Math.round(1+(f(D)-lo)/(hi-lo||1)*4)))};return[['Health',r(x=>x.hp)],['Attack',r(x=>x.atk*x.as)],['Defense',r(x=>x.def)],['Speed',r(x=>x.mv)],['Range',D.range>60?(D.range>=190?5:D.range>=150?4:3):1]]}
function pipsRow(n){let h='';for(let i=0;i<5;i++)h+=`<i class="${i<n?'on':''}"></i>`;return`<span class="spips">${h}</span>`}
function proCon(sp,compact){const L=LORE[sp];if(!L)return'';return`<div class="procon ${compact?'compact':''}"><ul class="pros">${L.pro.map(x=>`<li>${esc(x)}</li>`).join('')}</ul><ul class="cons">${L.con.map(x=>`<li>${esc(x)}</li>`).join('')}</ul></div>`}
function viewBestiary(){
 const f=UI.bfilter||'all';
 const owned={};G.clubs.P.roster.forEach(id=>{const b=G.beasts[id];if(b)owned[b.sp]=(owned[b.sp]||0)+1});
 const list=SPK.filter(sp=>f==='all'||ROLE_LINE[SPECIES[sp].role]===f);
 return`<div class="row between" style="margin-bottom:14px"><div><h2>Bestiary</h2><p class="dust" style="margin:4px 0 0;max-width:68ch">All ${SPK.length} species with their strengths and weaknesses. Every species is tuned to win about half its bouts when dropped into an average lineup, so the choice is about fit, not raw power.</p></div>
 <div class="seg">${[['all','All'],['front','Front line'],['flank','Flanks'],['back','Back line']].map(([k,n])=>`<button class="${f===k?'on':''}" data-act="bfilter" data-k="${k}">${n}</button>`).join('')}</div></div>
 <div class="bgrid">${list.map((sp,i)=>{const D=SPECIES[sp];return`<article class="bent"><div class="row" style="gap:12px;align-items:flex-end;flex-wrap:nowrap"><span class="spr big spr-${sp}" style="animation-delay:-${(i*.29%1.2).toFixed(2)}s"></span><div style="min-width:0"><h3>${D.n}</h3><div class="dust" style="font-size:13px">${D.role} · ${{front:'Front line',flank:'Flanks',back:'Back line'}[ROLE_LINE[D.role]]}${owned[sp]?` · <span class="gold">you own ${owned[sp]}</span>`:''}</div></div></div>
  <div class="srat">${statRatings(sp).map(([n,v])=>`<span class="mute">${n}</span>${pipsRow(v)}`).join('')}</div>
  <div style="font-size:14px"><b>${ABINFO[D.ab][0]}</b> <span class="mute num" style="font-size:11px">${D.cd}s</span><div class="dust">${ABINFO[D.ab][1]}</div></div>
  ${proCon(sp)}
  <div class="note"><b style="color:var(--dust)">Signature · ${SIG[D.ab][0]}.</b> ${SIG[D.ab][1]}</div></article>`}).join('')}</div>`;
}
function upgradesHtml(b,edit){
 b.perks=b.perks||{};if(edit&&b.rolls>0&&!b.offer)rollOffer(b);
 const tag=t=>`<span class="ptier">${PTIER[t].n}</span>`;
 const card=(k,btn)=>{const P=PERKS[k],cnt=b.perks[k]||0;return`<div class="pcard" style="--pc:${PTIER[P.t].c}">${tag(P.t)}<b>${esc(perkName(b,k))}${P.max>1&&cnt?` <span class="mute num" style="font-size:12px">${cnt}/${P.max}</span>`:''}</b><div class="dust" style="font-size:13px;flex:1">${esc(perkDesc(b,k))}</div>${btn||''}</div>`};
 let h='';
 if(edit&&b.offer){const cost=rerollCost(b);h+=`<div class="row between"><h3 style="font-size:21px">Pick a new skill</h3><span class="dust">${b.rolls} to pick</span></div><div class="pcards" style="margin-top:8px">${b.offer.map(k=>card(k,`<button class="btn pri sm" data-act="perk" data-id="${b.id}" data-k="${k}">Take ${esc(perkName(b,k))}</button>`)).join('')}</div>
  <div class="row" style="margin-top:10px"><button class="btn sm" data-act="reroll" data-id="${b.id}" ${G.gold<cost?'disabled':''}>Reroll · ${cost} gold</button>${(G.cons.dice||0)>0?`<button class="btn sm" data-act="use" data-id="${b.id}" data-k="dice">Use Loaded Dice ×${G.cons.dice}</button>`:''}<button class="btn sm" data-act="autoperk" data-id="${b.id}">Pick for me${b.rolls>1?` (all ${b.rolls})`:''}</button></div>`}
 else if(edit)h+=`<p class="dust" style="margin:0">No skills to pick. Every level-up deals three new skill cards after the bout.</p>`;
 const owned=Object.keys(b.perks).filter(k=>b.perks[k]&&PERKS[k]).sort((x,y)=>PERKS[y].t-PERKS[x].t);
 h+=`<div class="lbl" style="margin:18px 0 8px">Learned · ${owned.length}</div>${owned.length?`<div class="pcards">${owned.map(k=>card(k)).join('')}</div>`:'<p class="empty" style="margin:0">Nothing learned yet.</p>'}`;
 h+=`<p class="note" style="margin-top:12px">Cards roll as <span style="color:${PTIER[1].c}">Common</span>, <span style="color:${PTIER[2].c}">Rare</span>, <span style="color:${PTIER[3].c}">Epic</span> or <span style="color:${PTIER[4].c}">Legendary</span>. Beasts with higher potential roll better tiers. Rerolls get pricier each time for the same pick.</p>`;
 return h;
}
function perkCard(b,k,btn){const P=PERKS[k],cnt=(b.perks||{})[k]||0;return`<div class="pcard" style="--pc:${PTIER[P.t].c}"><span class="ptier">${PTIER[P.t].n}</span><b>${esc(perkName(b,k))}${P.max>1&&cnt?` <span class="mute num" style="font-size:12px">${cnt}/${P.max}</span>`:''}</b><div class="dust" style="font-size:13px;flex:1">${esc(perkDesc(b,k))}</div>${btn||''}</div>`}
function viewLevelUp(){
 const id=UI.lvq[0],b=G.beasts[id],row=((UI.result&&UI.result.rows)||[]).find(r=>r.bid===id)||{},D=SPECIES[b.sp];
 if(b.rolls>0&&!b.offer)rollOffer(b);
 const tot=UI.lvTotal||UI.lvq.length,idx=Math.max(1,tot-UI.lvq.length+1),cost=rerollCost(b);
 const gains=Object.entries(row.gains||{}).map(([k,v])=>`<span class="gain">+${v.toFixed(1)} ${ATTR_N[k]}</span>`).join('');
 const owned=Object.keys(b.perks||{}).filter(k=>b.perks[k]&&PERKS[k]).sort((x,y)=>PERKS[y].t-PERKS[x].t);
 return`<div class="stack">
 <div class="row between"><div class="lbl gold">Level up · ${idx} of ${tot}</div><div class="row" style="gap:6px">${UI.lvq.length>1?`<button class="btn sm" data-act="lvall">Pick for everyone</button>`:''}<button class="btn sm" data-act="lvskip">Decide later</button></div></div>
 <section class="bill"><div class="row" style="gap:20px;flex-wrap:nowrap;align-items:flex-end"><span class="spr big spr-${b.sp} plinth"></span><div style="min-width:0">
  <div class="kicker">${D.n} · ${D.role}</div><h2 style="font-size:42px;margin-top:4px">${fullName(b)}</h2>
  <div class="lvnum">Level <span class="num">${row.lv0||b.lvl}</span> → <b class="num">${b.lvl}</b></div>
  ${gains?`<div class="row" style="gap:6px;margin-top:8px">${gains}</div>`:''}</div></div></section>
 ${b.awaken&&b.awaken.length?`<section class="awaken"><div class="lbl gold">Awakening</div><p style="margin:4px 0 8px">Level ${b.lvl>=20?20:10} unlocks a new trait. Choose one.</p><div class="pcards">${b.awaken.map(t=>`<div class="pcard" style="--pc:var(--bronze)"><span class="ptier">Trait</span><b>${esc(t)}</b><div class="dust" style="font-size:13px;flex:1">${esc(TRAITS[t])}</div><button class="btn pri sm" data-act="awaken" data-id="${b.id}" data-k="${esc(t)}">Awaken ${esc(t)}</button></div>`).join('')}</div></section>`:''}
 ${b.offer?`<section><div class="row between"><h3>Pick a new skill</h3>${b.rolls>1?`<span class="dust">${b.rolls} picks from this bout</span>`:''}</div>
  <div class="pcards lvcards" style="margin-top:10px">${b.offer.map(k=>perkCard(b,k,`<button class="btn pri" data-act="perk" data-id="${b.id}" data-k="${k}">Learn ${esc(perkName(b,k))}</button>`)).join('')}</div>
  <div class="row" style="margin-top:12px"><button class="btn sm" data-act="reroll" data-id="${b.id}" ${G.gold<cost?'disabled':''}>Reroll · ${cost} gold</button>${(G.cons.dice||0)>0?`<button class="btn sm" data-act="use" data-id="${b.id}" data-k="dice">Use Loaded Dice ×${G.cons.dice}</button>`:''}<button class="btn sm" data-act="autoperk" data-id="${b.id}">Pick for me</button><span class="note">Higher potential deals better tiers. Rerolls cost more each time.</span></div></section>`:''}
 <section class="panel"><div class="lbl" style="margin-bottom:8px">${esc(b.name)}'s skills · ${owned.length}</div>${owned.length?`<div class="traits">${owned.map(k=>`<span class="trait" style="border-color:${PTIER[PERKS[k].t].c};color:${PTIER[PERKS[k].t].c}" title="${esc(perkDesc(b,k))}">${esc(perkName(b,k))}${b.perks[k]>1?' ×'+b.perks[k]:''}</span>`).join('')}</div>`:'<p class="empty" style="margin:0">This will be its first skill.</p>'}</section>
 </div>`;
}
function viewIntro(){
 const I=UI.intro,mem=castMembers(),rnd={id:'random',n:'Random draw',d:'Eight beasts pulled from the pens at random: two front, two flank, three back and a whelp. Roll until you like what you see.',m:I.cast==='random'?mem:(I.rand||(I.rand=randomCast()))};
 const cards=CASTS.concat([rnd]).map(c=>`<button class="castcard ${I.cast===c.id?'on':''}" data-act="introCast" data-k="${c.id}" aria-pressed="${I.cast===c.id}"><div class="row between" style="gap:8px"><span class="ctitle">${c.n}</span>${I.cast===c.id?'<span class="lbl gold">Chosen</span>':''}</div><p>${c.d}</p><div class="castrow">${c.m.map(([sp],i)=>`<span class="spr mini spr-${sp}" style="animation-delay:-${(i*.37).toFixed(2)}s" title="${SPECIES[sp].n}"></span>`).join('')}</div></button>`).join('');
 const note=(t)=>{if(!t)return'';const bits=[];if(t.stance==='guard'&&t.partner!=null)bits.push(`Bodyguards the ${SPECIES[mem[t.partner][0]].n}`);if(t.stance==='assist'&&t.partner!=null)bits.push(`Focuses with the ${SPECIES[mem[t.partner][0]].n}`);if(t.stance==='hold')bits.push('Holds ground');if(t.target)bits.push(TAC_OPTS.target.find(x=>x[0]===t.target)[1]);if(t.ability==='clutch')bits.push('Saves its ability for emergencies');return bits.join(' · ')};
 const cast=I.cast==='random'?rnd:CASTS.find(c=>c.id===I.cast);
 return`<div class="intro stack">
 <div class="row between" style="align-items:flex-start"><div><div class="lbl gold">A beast-club manager</div><h1 class="ititle">Manitoria</h1></div>${G?`<button class="btn" data-act="introContinue">Continue ${esc(G.name)}</button>`:''}</div>
 <p class="lede">Four divisions stand between the Mud Pits and the Mythic Arena. Found a club of mythical beasts, decide how each one fights, and write their story one bout at a time.</p>
 <div class="ladder">${TIERS.map((t,i)=>`<span class="rung ${i===0?'start':''}"><span class="num mute">${['IV','III','II','I'][i]}</span> ${t.n}${i===0?' <span class="gold" style="font-size:12px">you start here</span>':''}</span>`).join('<span class="arrow" aria-hidden="true">→</span>')}</div>
 <div class="primer"><div><b>14 league matchdays</b><span>5v5 against seven rival clubs. Top two go up, bottom two go down.</span></div><div><b>3 cup days</b><span>A 2v2 cup, a 3v3 cup and a draft cup with loaned beasts. The bench matters.</span></div><div><b>Every beast has a story</b><span>Levels and skill picks after every fight, bonds with partners, injuries, awards and retirement.</span></div></div>
 <section class="panel"><div class="lbl" style="margin-bottom:10px">1 · Name your club</div>
  <div class="row" style="gap:14px">${crest({name:I.name||'Club',hue:I.hue},46)}<input type="text" id="iname" value="${esc(I.name)}" maxlength="32" aria-label="Club name" style="flex:1;min-width:200px;font:700 22px var(--disp);padding:6px 10px">
  <div class="row" style="gap:6px" role="group" aria-label="Crest color">${CREST_HUES.map(h=>`<button class="sw ${I.hue===h?'on':''}" style="--sh:${h}" data-act="introHue" data-k="${h}" aria-label="Crest color ${h}"></button>`).join('')}</div></div></section>
 <section><div class="lbl" style="margin-bottom:10px">2 · Choose your founding cast</div><div class="castgrid">${cards}</div></section>
 <section class="panel"><div class="row between"><div><div class="lbl">3 · Meet the founders</div><h3 style="margin-top:4px">${cast.n}</h3></div>${I.cast==='random'?'<button class="btn" data-act="introRoll">Roll again</button>':''}</div>
  <div class="sandstrip">${mem.map(([sp],i)=>`<span class="spr big spr-${sp}" style="animation-delay:-${(i*.41).toFixed(2)}s" title="${SPECIES[sp].n}"></span>`).join('')}</div>
  <div class="founders">${mem.map(([sp,t],i)=>{const D=SPECIES[sp];return`<div class="frow"><span class="num mute" style="width:18px">${i+1}</span><div style="min-width:0"><b>${D.n}</b> <span class="dust">${D.role}${i===7?' · whelp prospect':''}</span><div class="note">${ABINFO[D.ab][0]}. ${note(t)||`Default: ${TAC_OPTS.target.find(x=>x[0]===DEF_TAC[D.role][0])[1]}, ${TAC_OPTS.pos.find(x=>x[0]===DEF_TAC[D.role][1])[1].toLowerCase()}`}</div></div></div>`}).join('')}</div>
  <p class="note" style="margin-top:10px">Names, stats, traits and potential are rolled when the gates open. Every tactic can be changed later, beast by beast.</p>
  <div class="row" style="margin-top:12px"><button class="btn pri" data-act="introStart">Open the gates</button>${G?'<span class="note">This replaces your current club.</span>':''}</div></section>
 </div>`;
}
function consUsable(b,k){return k==='tonic'?b.energy<100:k==='salt'?(b.fat||0)>0:k==='poultice'?b.inj>0:k==='manual'?b.lvl<lvlCap(b):k==='tome'?Object.values(b.perks||{}).some(Boolean):k==='dice'?!!b.offer:false}
function gearHtml(b,edit){
 const slots=Object.keys(SLOTS).map(sl=>{const g=b.gear&&b.gear[sl],it=g&&ITEMS[g.key];const avail=edit?G.stash.filter(x=>ITEMS[x.key].slot===sl):[];
  return`<div class="skill"><div class="lbl">${SLOTS[sl]}</div>${it?`<div class="row between"><b>${esc(it.n)}</b>${edit?`<button class="btn sm" data-act="unequip" data-id="${b.id}" data-s="${sl}">Remove</button>`:''}</div><div class="dust" style="font-size:13px">${esc(modText(it.m))}</div>`:'<div class="empty">Empty</div>'}
  ${avail.length?`<div class="row" style="gap:6px;margin-top:4px">${avail.map(x=>`<button class="btn sm" data-act="equip" data-id="${b.id}" data-item="${x.id}" title="${esc(modText(ITEMS[x.key].m))}">Equip ${esc(ITEMS[x.key].n)}</button>`).join('')}</div>`:''}</div>`}).join('');
 const sup=edit&&b.clubId==='P'?`<div class="lbl" style="margin:16px 0 6px">Supplies</div>${Object.keys(CONS).filter(k=>!G.arenaRules||['tonic','salt','poultice'].includes(k)).map(k=>{const n=G.cons[k]||0,ok=n>0&&consUsable(b,k),reason=!n?'None owned':{tonic:'Energy is full',salt:'No fatigue',poultice:'No injury',manual:'Level cap reached',tome:'No powers to reset',dice:'No cards to reroll'}[k];return`<div class="row between" style="padding:6px 0;border-bottom:1px solid #2a2532;font-size:14px"><span><b>${CONS[k].n}</b> <span class="dust">${CONS[k].d}</span> <span class="mute num" style="font-size:12px">×${n}</span>${!ok?`<small class="supply-reason">${reason}</small>`:''}</span><button class="btn sm" data-act="use" data-id="${b.id}" data-k="${k}" aria-label="Use ${CONS[k].n} on ${esc(b.name)}" ${ok?'':'disabled'}>Use</button></div>`}).join('')}<p class="note">Buy gear and supplies in the Item shop.</p>`:'';
 return`<div class="gearcols">${slots}</div>${sup}`;
}
function modalProfile(m){
 const b=G.beasts[m.id];if(!b)return'<p>This beast is gone.</p>';
 const D=SPECIES[b.sp],c=combatStats(b);
 const mine=b.clubId==='P',draftMine=!!(b.draft&&G.cup&&G.cup.teams&&G.cup.teams.P&&G.cup.teams.P.includes(b.id));
 const edit=mine||draftMine,mkt=b.clubId==='MKT';
 const owner=mine?G.name:mkt?'On the market':b.draft?'Draft pool':clubName(b.clubId);
 const pt=m.pt||'overview';
 const tabs=[['overview','Overview'],['skills',`Skills${edit&&b.rolls?` · ${b.rolls}`:''}`],['gear','Gear'],['tactics','Tactics'],['story','Record & story']];
 let body='';
 if(pt==='overview'){const learnedSig=(b.perks||{}).sig;
  body=`<div class="twocol"><div><div class="lbl" style="margin-bottom:8px">Attributes</div><div class="attrs">${ATTR.map(k=>`<span class="dust">${ATTR_N[k]}</span><span class="bar"><i style="width:${b.attrs[k]}%"></i></span><span class="num" style="text-align:right">${Math.round(b.attrs[k])}</span>`).join('')}</div>
   <div class="lbl" style="margin:14px 0 6px">In the arena · with skills and gear</div>
   <div class="kv" style="grid-template-columns:repeat(3,1fr)"><span><b>${Math.round(c.hp)}</b>Health</span><span><b>${c.atk.toFixed(1)}</b>Attack</span><span><b>${Math.round(c.def)}</b>Defense</span><span><b>${c.as.toFixed(2)}/s</b>Attacks</span><span><b>${Math.round(c.mv)}</b>Speed</span><span><b>${c.range>60?c.range:'Melee'}</b>Range</span></div>
   ${mine?`<div class="lbl" style="margin:16px 0 6px">Training focus</div><select id="focus-${b.id}" data-chg="focus" data-id="${b.id}" aria-label="Training focus">${Object.keys(FOCUS).map(f=>`<option ${b.focus===f?'selected':''}>${f}</option>`).join('')}</select><div class="note" style="margin-top:4px">Each level-up grows the focused attribute about three times as fast as the others.</div>`:''}</div>
  <div><div style="font-size:14px"><b>${ABINFO[D.ab][0]}</b> <span class="mute num" style="font-size:11px">${c.cd.toFixed(1)}s</span><div class="dust">${ABINFO[D.ab][1]}</div></div>
   <div style="font-size:14px;margin-top:10px"><b class="${learnedSig?'gold':''}">Signature: ${SIG[D.ab][0]}</b> <span class="mute" style="font-size:12px">${learnedSig?'learned':'an Epic upgrade'}</span><div class="dust">${SIG[D.ab][1]}</div></div>
   <div class="lbl" style="margin:14px 0 6px">Strengths and weaknesses</div>${proCon(b.sp,true)}
   ${b.traits.length?`<div class="lbl" style="margin:14px 0 6px">Traits</div>${b.traits.map(t=>`<div style="font-size:14px"><span class="${NEG_TRAITS.has(t)?'bad':'gold'}" style="font-weight:700">${esc(t)}</span> <span class="dust">${esc(TRAITS[t])}</span></div>`).join('')}`:''}
   ${Object.values(b.gear||{}).some(Boolean)?`<div class="lbl" style="margin:14px 0 6px">Gear</div>${Object.values(b.gear).filter(Boolean).map(g=>`<div style="font-size:14px"><b>${esc(ITEMS[g.key].n)}</b> <span class="dust">${esc(modText(ITEMS[g.key].m))}</span></div>`).join('')}`:''}</div></div>`}
 else if(pt==='skills')body=upgradesHtml(b,edit);
 else if(pt==='gear')body=gearHtml(b,mine);
 else if(pt==='tactics'){
  const pool=(mine?G.clubs.P.roster:draftMine?G.cup.teams.P:(G.clubs[b.clubId]?G.clubs[b.clubId].roster:[])).map(id=>G.beasts[id]).filter(Boolean);
  const tl=(k,lbl)=>`<label for="mt-${b.id}-${k}">${lbl}${tacSel(b,k,!edit,'m')}<small>${TAC_HELP[k][b.tactics[k]]||''}</small></label>`;
  const pn=b.tactics.partner&&G.beasts[b.tactics.partner];
  body=`${edit?`<div class="lbl" style="margin-bottom:6px">Quick presets</div><div class="seg" style="margin-bottom:6px">${Object.keys(PRESETS).map(k=>`<button data-act="tpreset" data-id="${b.id}" data-k="${k}">${PRESETS[k].n}</button>`).join('')}</div><p class="note" style="margin:0 0 14px">${Object.values(PRESETS).map(x=>`<b>${x.n}</b>: ${x.d}`).join(' ')}</p>`:''}
  <div class="tacgrid2">${tl('target','Target priority')}${tl('stance','Stance')}
   <label for="mpt-${b.id}">Partner${partnerSel(b,pool,!edit,'m')}<small>${['guard','assist'].includes(b.tactics.stance)?(pn?`${b.tactics.stance==='guard'?'Protects':'Follows'} ${esc(pn.name)}. Only works when both are fielded.`:'Pick the ally to work with.'):'Used by the Bodyguard and Focus stances.'}</small></label>
   ${tl('pos','Starting position')}${tl('ability','Ability use')}${tl('retreatAt','Falling back')}
   <label style="flex-direction:row;align-items:center;gap:8px;color:var(--sand)"><input type="checkbox" id="kite-${b.id}" data-chg="tacb" data-id="${b.id}" data-k="kite" ${b.tactics.kite?'checked':''} ${edit?'':'disabled'}>Keep distance from melee <small>(ranged only)</small></label></div>
  ${edit?'':'<p class="note">Scouted tactics. You can see how this beast is set up but not change it.</p>'}`}
 else{const bonds=mine?G.clubs.P.roster.filter(id=>id!==b.id).map(id=>({o:G.beasts[id],v:G.bonds[bkey(b.id,id)]})).filter(x=>x.o&&x.v&&x.v.m).sort((x,y)=>y.v.w-x.v.w||y.v.m-x.v.m).slice(0,5):[];
  const statRow=(st,lbl)=>`<tr><td class="dust">${lbl}</td><td class="n">${st.m}</td><td class="n">${st.w}</td><td class="n">${st.k}</td><td class="n">${st.d}</td><td class="n">${st.a}</td><td class="n">${fmt(st.dmg)}</td><td class="n">${fmt(st.heal)}</td><td class="n">${Math.round(st.imp)}</td></tr>`;
  body=`<div class="tw"><table><thead><tr><th></th><th class="n">Bouts</th><th class="n">W</th><th class="n">TD</th><th class="n">D</th><th class="n">A</th><th class="n">Dmg</th><th class="n">Heal</th><th class="n">Impact</th></tr></thead><tbody>${statRow(b.season,'Season')}${statRow(b.career,'Career')}</tbody></table></div>
  ${b.form&&b.form.length?`<div class="note" style="margin-top:6px">Last ${b.form.length} bouts impact: <span class="num">${b.form.join(' · ')}</span></div>`:''}
  ${b.titles.length?`<div class="lbl" style="margin:16px 0 6px">Honours</div><div class="gold" style="font-size:14px">${b.titles.map(esc).join('<br>')}</div>`:''}
  ${mine?`<div class="lbl" style="margin:16px 0 6px">Partners</div>${bonds.length?bonds.map(x=>{const l=bondLvl(b.id,x.o.id);return`<div class="row between" style="font-size:14px;padding:4px 0"><span class="cell">${tok(x.o,'sm')}${esc(x.o.name)}</span><span class="dust">${l?`<span class="gold">${BOND_N[l]}</span> · `:''}${x.v.w} wins in ${x.v.m} together</span></div>`}).join(''):'<p class="empty" style="margin:0">Has not fought alongside anyone yet.</p>'}`:''}
  <div class="lbl" style="margin:16px 0 6px">Story so far</div>${b.notes.length?`<ul class="timeline">${b.notes.slice().reverse().map(n=>`<li><span class="mute num" style="font-size:11px">S${n.s}·D${n.d}</span><span>${esc(n.t)}</span></li>`).join('')}</ul>`:'<p class="empty" style="margin:0">Nothing written yet.</p>'}`}
 const awaken=mine&&b.awaken&&b.awaken.length?`<div class="awaken"><div class="lbl gold">Awakening</div><p style="margin:4px 0 8px">${esc(b.name)} can take on a new trait. Choose one.</p><div class="stack" style="gap:6px">${b.awaken.map(t=>`<button class="btn sm" style="white-space:normal;text-align:left" data-act="awaken" data-id="${b.id}" data-k="${esc(t)}"><span>${esc(t)} <span class="dust" style="font-weight:500">${esc(TRAITS[t])}</span></span></button>`).join('')}</div></div>`:'';
 return`<div class="row" style="gap:16px;padding-right:70px">${tok(b,'big'+(mine||mkt||draftMine?'':' en'))}<div style="min-width:0">
  ${mine?`<input type="text" id="rename" value="${esc(b.name)}" maxlength="24" data-chg="rename" data-id="${b.id}" aria-label="Name" style="font:700 26px var(--disp);background:transparent;border-color:transparent;padding:0 4px;margin-left:-4px;width:100%;max-width:320px">`:`<div style="font:700 28px var(--disp)">${esc(b.name)}</div>`}
  ${b.epithet?`<div class="gold" style="font-weight:700">${esc(b.name)} ${esc(b.epithet)}</div>`:''}
  <div class="dust">${D.n} · ${D.role} · ${ageLabel(b.age)}, season ${b.age+1} · ${esc(owner)}</div>
  ${b.joined?`<div class="mute" style="font-size:13px">${esc(b.joined)}</div>`:''}</div></div>
 <div class="row" style="margin-top:14px;gap:8px"><span class="chip">OVR <b>${ovr(b)}</b></span><span class="chip">Level <b>${b.lvl}/${lvlCap(b)}</b></span><span class="chip">Potential <b>${potRange(b)}</b></span>${b.draft?'':`<span class="chip">Energy <b>${b.energy}</b></span><span class="chip">Fatigue <b>${b.fat||0}</b></span>`}${b.inj?`<span class="chip bad">Injured <b>${b.inj}d</b></span>`:''}<span class="chip">Value <b>${fmt(value(b))}</b></span></div>
 <div style="margin-top:8px"><div class="row between" style="font-size:12px;color:var(--mute)"><span>Experience to level ${b.lvl+1}</span><span class="num">${b.xp}/${xpNeed(b.lvl)}</span></div><span class="bar xp"><i style="width:${clamp(b.xp/xpNeed(b.lvl)*100,0,100)}%"></i></span></div>
 ${awaken}
 <div class="seg" role="tablist" style="margin-top:16px">${tabs.map(([k,n])=>`<button role="tab" aria-selected="${pt===k}" class="${pt===k?'on':''}" data-act="ptab" data-k="${k}">${n}</button>`).join('')}</div>
 <div style="margin-top:14px">${body}</div>
 <div class="row" style="margin-top:18px">${mine?(m.confirm?`<div class="confirm"><span>Sell ${esc(b.name)} for ${fmt(sellPrice(b))} gold? Their gear goes back to your stash. This can't be undone.</span><button class="btn danger sm" data-act="sellok" data-id="${b.id}">Sell</button><button class="btn sm" data-act="sellno">Keep</button></div>`:`<button class="btn danger sm" data-act="sell" data-id="${b.id}" ${G.clubs.P.roster.length<=5?'disabled':''}>Sell for ${fmt(sellPrice(b))} gold</button>${G.clubs.P.roster.length<=5?'<span class="note">You need at least five beasts.</span>':''}`):''}
 ${mkt?`<button class="btn pri" data-act="buy" data-id="${b.id}" ${G.gold<value(b)||G.clubs.P.roster.length>=12?'disabled':''}>Sign for ${fmt(value(b))} gold</button>${G.gold<value(b)?'<span class="note">Not enough gold.</span>':G.clubs.P.roster.length>=12?'<span class="note">Kennels are full.</span>':''}`:''}</div>`;
}
function viewShop(){
 const mineB=G.clubs.P.roster.map(id=>G.beasts[id]).filter(Boolean);
 const owned=k=>G.stash.filter(x=>x.key===k).length+mineB.reduce((n,b)=>n+Object.values(b.gear||{}).filter(g=>g&&g.key===k).length,0);
 const slotSec=Object.keys(SLOTS).map(sl=>`<div><div class="lbl" style="margin:4px 0 8px">${SLOTS[sl]}</div><div class="icards">${Object.keys(ITEMS).filter(k=>ITEMS[k].slot===sl).map(k=>{const it=ITEMS[k],lock=it.tier>G.tier;return`<div class="icard ${lock?'locked':''}"><div class="row between" style="gap:6px;align-items:baseline"><b>${esc(it.n)}</b><span class="num gold">${it.price}</span></div><div class="dust" style="font-size:13px">${esc(modText(it.m))}</div><div class="row between" style="margin-top:auto"><span class="note">${lock?`Unlocks in the ${TIERS[it.tier].n}`:`Owned ${owned(k)}`}</span><button class="btn sm" data-act="ibuy" data-k="${k}" ${lock||G.gold<it.price?'disabled':''}>Buy</button></div></div>`}).join('')}</div></div>`).join('');
 const worn=mineB.filter(b=>Object.values(b.gear||{}).some(Boolean));
 return`<div class="row between" style="margin-bottom:14px"><div><h2>Item shop</h2><p class="dust" style="margin:4px 0 0;max-width:68ch">Each beast wears one claw or horn piece, one barding and one charm. Buy here, then equip from the beast's Gear tab. Better stock unlocks as the club climbs divisions. Items sell back for half.</p></div><span class="chip">Gold <b class="${G.gold<0?'bad':''}">${fmt(G.gold)}</b></span></div>
 <div class="grid2"><section class="panel stack" style="gap:10px"><h3>Gear</h3>${slotSec}</section>
 <div class="stack"><section class="panel"><h3>Supplies</h3><p class="note" style="margin:4px 0 6px">Used from a beast's Gear tab.</p>${Object.keys(CONS).filter(k=>!G.arenaRules||['tonic','salt','poultice'].includes(k)).map(k=>`<div class="row between" style="padding:8px 0;border-bottom:1px solid #2a2532;font-size:14px;flex-wrap:nowrap"><span><b>${CONS[k].n}</b> <span class="mute num" style="font-size:12px">×${G.cons[k]||0}</span><br><span class="dust">${CONS[k].d}</span></span><button class="btn sm" data-act="cbuy" data-k="${k}" ${G.gold<CONS[k].price?'disabled':''}>Buy · ${CONS[k].price}</button></div>`).join('')}</section>
 <section class="panel"><h3>Stash</h3>${G.stash.length?G.stash.map(x=>{const it=ITEMS[x.key];return`<div class="row between" style="padding:6px 0;border-bottom:1px solid #2a2532;font-size:14px;flex-wrap:nowrap"><span><b>${esc(it.n)}</b> <span class="mute">${SLOTS[it.slot]}</span></span><button class="btn sm" data-act="isell" data-item="${x.id}">Sell · ${Math.round(it.price*.5)}</button></div>`}).join(''):'<p class="empty">Nothing unequipped.</p>'}</section>
 <section class="panel"><h3>Worn by</h3>${worn.length?worn.map(b=>`<div class="row" style="padding:6px 0;border-bottom:1px solid #2a2532;cursor:pointer;flex-wrap:nowrap" data-act="profile" data-id="${b.id}" data-pt="gear">${tok(b,'sm')}<span style="font-size:14px"><b>${esc(b.name)}</b><br><span class="dust">${Object.values(b.gear).filter(Boolean).map(g=>esc(ITEMS[g.key].n)).join(', ')}</span></span></div>`).join(''):'<p class="empty">No one is geared up yet.</p>'}</section></div></div>`;
}
function modalSettings(m){
 return`<h2>Club office</h2>
 <div style="margin-top:14px"><label class="lbl" for="clubname">Club name</label><div class="row" style="margin-top:6px"><input type="text" id="clubname" value="${esc(G.name)}" maxlength="32" style="flex:1;min-width:200px"><button class="btn sm" data-act="rename">Rename</button></div></div>
 <div style="margin-top:18px"><label class="lbl" for="vol">Music volume</label><div class="row" style="margin-top:6px"><input type="range" id="vol" min="0" max="1" step="0.05" value="${MUS.vol}" style="flex:1;max-width:320px;accent-color:var(--bronze)"><span class="note">Anticipation before bouts, battle music during, and victory or honor music after. Toggle it from the top bar.</span></div></div>
 <div style="margin-top:18px"><div class="lbl">Save</div><p class="note" style="margin:4px 0 8px">Progress saves in this browser automatically. Copy this code to move the club to another device or keep a backup.</p><textarea id="exp" readonly>${esc(exportSave())}</textarea><div class="row" style="margin-top:6px"><button class="btn sm" data-act="copy">Copy save code</button><span id="copymsg" class="note"></span></div></div>
 <div style="margin-top:18px"><div class="lbl">Load</div><textarea id="imp" placeholder="Paste a save code here"></textarea><div class="row" style="margin-top:6px"><button class="btn sm" data-act="import">Load this club</button><span id="impmsg" class="note"></span></div></div>
 <div style="margin-top:18px"><div class="lbl">New club</div>${m.confirm?`<div class="confirm"><span>Start over? You'll pick a new founding cast, and this club and its history will be replaced once you open the gates.</span><button class="btn danger sm" data-act="newok">Start over</button><button class="btn sm" data-act="newno">Cancel</button></div>`:`<p class="note" style="margin:4px 0 8px">Found a new club in the Mud Pits with a fresh roster.</p><button class="btn danger sm" data-act="new">Found a new club</button>`}</div>`;
}
function modalGuide(){
 return`<h2>Field guide</h2><div style="max-width:65ch;color:var(--dust);font-size:15px">
 <p><b style="color:var(--sand)">The season.</b> Fourteen 5v5 league matchdays against seven rival clubs, plus three cup days: the Twin Fangs Cup (2v2), the Wildcard Draft Cup (5v5 with loaned beasts), and the Trident Cup (3v3). Top two go up a division, bottom two go down. There are four divisions, from the Mud Pits to the Mythic Arena.</p>
 <p><b style="color:var(--sand)">Bouts.</b> Beasts fight on their own. You decide who fights and how, beast by beast: target priority, starting position, stance (advance, hold ground, bodyguard an ally, or focus with an ally), when to use abilities, whether to keep distance, and when to fall back. A bout ends when one side is wiped out, or after 90 seconds on remaining health.</p>
 <p><b style="color:var(--sand)">Energy and fatigue.</b> Every bout costs energy. Below 50 energy a beast loses up to a quarter of its health and attack. Energy comes back each day, faster on the bench. Fatigue builds more slowly with every bout and only fades on days off. High fatigue slows energy recovery, and above 55 fatigue every bout risks an injury that keeps a beast out for one to three days. Cup rounds come back to back with no rest.</p>
 <p><b style="color:var(--sand)">Growth.</b> Beasts earn experience in every bout and level up toward a cap set by their potential. Potential shows as a range until a beast has fought enough to reveal it. Training focus steers which attributes grow. After every bout, beasts that level up deal you three skill cards to choose from, in four tiers: Common stat boosts, Rare techniques like Bloodletter or Thorned Hide, Epic powers like Berserker, Twin Strike or the species' Signature, and Legendary ones like Undying or Apex Predator. Higher potential rolls better tiers, and you can reroll for gold. At levels 10 and 20 a beast awakens and you choose a new trait for it. Past their seventh season beasts start to decline, and elders retire.</p>
 <p><b style="color:var(--sand)">Roles.</b> Tanks and Wardens hold the front; Wardens also taunt and rally. Bruisers trade blows up close. Duelists, Divers, Assassins, Skirmishers and Tricksters work the flanks and hunt the backline. Ranged beasts, Artillery, Casters, Controllers, Supports and Summoners fight from behind. "Hunt healers &amp; casters" targets Supports, Casters, Controllers, Artillery and Summoners.</p>
 <p><b style="color:var(--sand)">Bonds.</b> Pairs who win together become Familiar (3 wins), Trusted (8) and Blood-sworn (15), gaining 3% health and attack per level when fielded together.</p>
 <p><b style="color:var(--sand)">Money.</b> A league win pays 70 gold and a loss 30, plus 5 per takedown, 25 for a flawless win and 20 for beating a higher-ranked club. Cup rounds pay too. Higher divisions multiply all of it. Spend it in the Item shop on gear (claws or horns, barding and a charm per beast) and on supplies like tonics and poultices. Every beast costs upkeep each matchday. Sell beasts you've given up on; sign from the market when a gap appears.</p></div>`;
}
function exportSave(){try{return btoa(unescape(encodeURIComponent(JSON.stringify(G))))}catch(e){return''}}

/* ============ EVENTS ============ */
const ACT={
 tab:d=>{UI.mode='hub';UI.tab=d.k;if(d.k==='league')UI.round=null;render()},
 toPrematch:()=>{UI.mode='prematch';render()},
 next:()=>{if(UI.ctx&&UI.ctx.kind==='league'&&curEvent().t==='league'&&UI.ctx.r===curEvent().r){UI.mode='prematch';render()}else openNext()},
 profile:d=>{UI.modal={k:'profile',id:d.id,pt:d.pt||'overview'};renderModal()},
 ptab:d=>{UI.modal.pt=d.k;UI.modal.confirm=false;renderModal()},
 close:()=>{UI.modal=null;render()},
 scrim:(d,el,e)=>{if(e.target===el){UI.modal=null;render()}},
 settings:()=>{UI.modal={k:'settings'};renderModal()},
 guide:()=>{UI.modal={k:'guide'};renderModal()},
 rsort:d=>{UI.rsort=d.k;render()},
 lead:d=>{UI.lead=d.k;render()},
 rnd:d=>{UI.round=clamp((UI.round||0)+(+d.d),0,13);render()},
 sel:d=>{if(UI.sel.length<UI.ctx.fmt&&!UI.sel.includes(d.id))UI.sel.push(d.id);render()},
 unsel:d=>{UI.sel=UI.sel.filter(x=>x!==d.id);render()},
 autopick:()=>{UI.sel=pickLineup('P',UI.ctx.fmt).map(b=>b.id);render()},
 go:d=>startMatch(d.w==='1'),
 pause:()=>{if(!BT)return;BT.paused=!BT.paused;$('#bp').textContent=BT.paused?'Resume':'Pause';$('#bp').classList.toggle('on',BT.paused)},
 speed:(d,el)=>{if(!BT)return;BT.speed=+d.s;document.querySelectorAll('[data-act=speed]').forEach(b=>b.classList.toggle('on',b===el))},
 skip:()=>{if(!BT)return;const S=BT.S;runHeadless(S);finishMatch(S)},
 resnext:()=>{if(UI.lvq&&UI.lvq.length){UI.mode='levelup';render();window.scrollTo(0,0)}else resultNext()},
 lvskip:()=>{UI.lvq.shift();advanceLv()},
 lvall:()=>{UI.lvq.forEach(id=>{const b=G.beasts[id];if(b){autoPick(b);if(b.awaken&&b.awaken.length){b.traits.push(b.awaken[0]);b.awaken=[]}}});UI.lvq=[];save();advanceLv()},
 dpick:d=>draftPick(d.id),
 keep:d=>finishCupDay(d.id),
 keepnone:()=>{if(G.clubs.P.roster.length>=12)G.gold+=150;finishCupDay(null)},
 cupfin:()=>finishCupDay(null),
 seasonok:()=>{music(null);UI.mode='hub';UI.tab='club';UI.ctx=null;render();window.scrollTo(0,0)},
 mrefresh:()=>{if(G.gold<25)return;G.gold-=25;ledger('Market scouts',-25);G.market.slice(0,3).forEach(id=>delete G.beasts[id]);G.market=G.market.slice(3);refreshMarket(false);save();render()},
 buy:d=>{const b=G.beasts[d.id],v=value(b);if(G.gold<v||G.clubs.P.roster.length>=12)return;G.gold-=v;ledger(`Signed ${b.name}`,-v);G.market=G.market.filter(x=>x!==b.id);b.clubId='P';b.joined=`Signed from the market, Season ${G.season}`;b.energy=100;b.notes.push({s:G.season,d:G.day+1,t:`signed for ${v} gold`});G.clubs.P.roster.push(b.id);news(`${b.name} the ${SPECIES[b.sp].n} signs for ${v} gold.`,'');save();UI.modal={k:'profile',id:b.id};render()},
 sell:()=>{UI.modal.confirm=true;renderModal()},
 sellno:()=>{UI.modal.confirm=false;renderModal()},
 sellok:d=>{const b=G.beasts[d.id],p=sellPrice(b);G.gold+=p;ledger(`Sold ${b.name}`,p);if(b.career.m>=10)G.alumni.unshift(snapshot(b,`Sold in Season ${G.season}`));removeFromPlayer(b);UI.sel=UI.sel.filter(x=>x!==b.id);news(`${b.name} sold for ${p} gold after ${b.career.m} bouts.`,'');delete G.beasts[b.id];UI.modal=null;save();render()},
 learn:d=>{const b=G.beasts[d.id];if(learn(b,d.k)){save();render()}},
 autolearn:d=>{const b=G.beasts[d.id];autoSpend(b);save();render()},
 awaken:d=>{const b=G.beasts[d.id];if(!b.awaken||!b.awaken.includes(d.k))return;b.traits.push(d.k);b.awaken=[];b.notes.push({s:G.season,d:G.day+1,t:`awakened a new trait: ${d.k}`});news(`${b.name} awakened: ${d.k}.`,'mile');save();if(UI.mode==='levelup')advanceLv();else render()},
 equip:d=>{const b=G.beasts[d.id],i=G.stash.findIndex(x=>x.id===d.item);if(!b||i<0)return;const it=G.stash[i],sl=ITEMS[it.key].slot;G.stash.splice(i,1);if(b.gear[sl])G.stash.push(b.gear[sl]);b.gear[sl]=it;save();render()},
 unequip:d=>{const b=G.beasts[d.id];if(b&&b.gear[d.s]){G.stash.push(b.gear[d.s]);b.gear[d.s]=null;save();render()}},
 use:d=>{const b=G.beasts[d.id],k=d.k;if(!b||!(G.cons[k]>0)||!consUsable(b,k))return;G.cons[k]--;if(k==='tonic')b.energy=Math.min(100,b.energy+40);else if(k==='salt')b.fat=Math.max(0,(b.fat||0)-30);else if(k==='poultice'){b.inj=0;news(`${b.name} is patched up and fit to fight.`,'')}else if(k==='manual'){const u=gainXp(b,150);if(u)news(`${b.name} studied up to level ${b.lvl}.`,'')}else if(k==='tome'){const n=Object.values(b.perks||{}).reduce((s,v)=>s+v,0);b.perks={};b.rolls=(b.rolls||0)+n;b.offer=null;if(b.rolls)rollOffer(b)}else if(k==='dice'){const n=b.rerolls||0;rollOffer(b);b.rerolls=n}save();render()},
 ibuy:d=>{const it=ITEMS[d.k];if(!it||it.tier>G.tier||G.gold<it.price)return;G.gold-=it.price;G.stash.push({id:'i'+(G.nid++),key:d.k});ledger(`Bought ${it.n}`,-it.price);save();render()},
 cbuy:d=>{const c=CONS[d.k];if(!c||G.gold<c.price)return;G.gold-=c.price;G.cons[d.k]=(G.cons[d.k]||0)+1;ledger(`Bought ${c.n}`,-c.price);save();render()},
 isell:d=>{const i=G.stash.findIndex(x=>x.id===d.item);if(i<0)return;const it=ITEMS[G.stash[i].key],p=Math.round(it.price*.5);G.stash.splice(i,1);G.gold+=p;ledger(`Sold ${it.n}`,p);save();render()},
 rename:()=>{const v=$('#clubname').value.trim();if(v){G.name=v;G.clubs.P.name=v;save();render()}},
 copy:()=>{const t=$('#exp'),msg=$('#copymsg');const done=ok=>{msg.textContent=ok?'Copied.':'Select the text and copy it manually.'};try{navigator.clipboard.writeText(t.value).then(()=>done(true),()=>{t.select();done(false)})}catch(e){t.select();done(false)}},
 import:()=>{const msg=$('#impmsg');try{const g=JSON.parse(decodeURIComponent(escape(atob($('#imp').value.trim()))));if(!g||!(g.v>=1&&g.v<=3)||!g.clubs||!g.clubs.P)throw 0;G=migrate(g);UI.modal=null;UI.mode='hub';UI.tab='club';UI.ctx=null;save();render()}catch(e){msg.textContent='That code could not be read. Check it was copied in full.';msg.classList.add('bad')}},
 new:()=>{UI.modal.confirm=true;renderModal()},
 newno:()=>{UI.modal.confirm=false;renderModal()},
 newok:()=>{UI.modal=null;UI.mode='intro';render();window.scrollTo(0,0)},
 introCast:d=>{UI.intro.cast=d.k;render()},
 introRoll:()=>{UI.intro.rand=randomCast();render()},
 introHue:d=>{UI.intro.hue=+d.k;render()},
 introContinue:()=>{UI.mode='hub';UI.tab='club';render()},
 introStart:()=>{const nm=($('#iname').value||'').trim()||'Ravenmoor Menagerie';newGame(nm,castMembers(),UI.intro.hue);UI.intro.rand=null;UI.mode='hub';UI.tab='club';UI.ctx=null;UI.modal=null;save();render();window.scrollTo(0,0)},
 perk:d=>{const b=G.beasts[d.id],P=PERKS[d.k];if(!b||!takePerk(b,d.k))return;b.notes.push({s:G.season,d:G.day+1,t:`learned the ${PTIER[P.t].n} skill ${perkName(b,d.k)}`});if(P.t>=3)news(`${b.name} learned the ${PTIER[P.t].n} skill ${perkName(b,d.k)}.`,'mile');save();if(UI.mode==='levelup')advanceLv();else render()},
 reroll:d=>{const b=G.beasts[d.id],c=rerollCost(b);if(!b||G.gold<c)return;G.gold-=c;ledger(`Rerolled ${b.name}'s upgrades`,-c);const n=(b.rerolls||0)+1;rollOffer(b);b.rerolls=n;save();render()},
 autoperk:d=>{const b=G.beasts[d.id];if(!b)return;const before=Object.assign({},b.perks);autoPick(b);Object.keys(b.perks).forEach(k=>{if((b.perks[k]||0)>(before[k]||0)&&PERKS[k].t>=3)news(`${b.name} learned the ${PTIER[PERKS[k].t].n} skill ${perkName(b,k)}.`,'mile')});save();if(UI.mode==='levelup')advanceLv();else render()},
 music:()=>{musToggle();renderTop()},
 bfilter:d=>{UI.bfilter=d.k;render()},
 tpreset:d=>{const b=G.beasts[d.id];if(!b)return;Object.assign(b.tactics,PRESETS[d.k].t);save();render()}
};
document.addEventListener('click',e=>{const el=e.target.closest('[data-act]');if(!el)return;if(el.hasAttribute('disabled'))return;const f=ACT[el.dataset.act];if(f)f(el.dataset,el,e)});
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&UI.modal){UI.modal=null;render()}if((e.key==='Enter'||e.key===' ')&&e.target.matches('span[role=button][data-act]')){e.preventDefault();e.target.click()}});
document.addEventListener('change',e=>{const el=e.target,d=el.dataset;if(!d.chg)return;const b=G.beasts[d.id];if(!b)return;
 if(d.chg==='tac'){b.tactics[d.k]=d.k==='retreatAt'?+el.value:el.value}
 else if(d.chg==='partner'){b.tactics.partner=el.value||null}
 else if(d.chg==='tacb'){b.tactics[d.k]=el.checked}
 else if(d.chg==='focus'){b.focus=el.value}
 else if(d.chg==='rename'){const v=el.value.trim().slice(0,24);if(v)b.name=v}
 save();render();
});

