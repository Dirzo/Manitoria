extends SceneTree
var checks = 0
var failures = 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 HeroData.load_data()
 var h = HeroData.make_hero("cyclops","qa","Cyclops",6)
 h.learned={"1":2,"10":1,"6":1}
 var sim = BattleSim.new()
 var u = sim.add_unit(h,0,Vector2(-4,0))
 var enemy = sim.add_unit(HeroData.make_hero("golem","enemy","Enemy",6),1,Vector2(4,0))
 u.tactics.area="immediate"
 var roar = HeroData.learned_ability("cyclops",6)
 check(sim.cast_learned(u,enemy,roar,1),"Titan Roar's self-shield must not depend on a distant enemy entering its aura")
 u.casting_resolution=true
 sim.cast_learned(u,enemy,roar,1)
 check(u.shield>0,"Titan Roar resolves its existing self-shield")
 check(not sim.active(enemy,"weaken"),"Titan Roar's aura reach stays unchanged")
 var automatic=BattleSim.new();automatic.silent=true;automatic.rng.seed=17
 var caster=automatic.add_unit(h,0,Vector2(-4,0))
 var dummy=automatic.add_unit(HeroData.make_hero("golem","dummy","Dummy",6),1,Vector2(4,0))
 for unit in automatic.units:
  unit.speed=0;unit.max_hp*=100;unit.hp=unit.max_hp;unit.attack_timer=1000;unit.cd=1000;unit.attack_hexes=50;unit.tactics.distance="natural"
 caster.tactics.area="immediate"
 for tick in range(900):automatic.step(1.0/30.0)
 check(caster.ability_stats.get("ability:6",{}).get("casts",0)>0,"Titan Roar casts through the actual automatic combat loop with a full learned kit")
 var rng=RandomNumberGenerator.new();rng.seed=8751
 var drops=0
 for i in range(1500):
  var offers=HeroData.choices(h,true,rng)
  for card in offers:
   if card.rarity=="Legendary":
    drops+=1
    check(not card.get("upgrade",false) and not h.learned.has(card.key),"A legendary drop is a fresh skill, never an owned-skill upgrade")
    var copy=h.duplicate(true);HeroData.apply_choice(copy,card)
    check(copy.learned.has(card.key) and copy.learned.size()==4,"Full regular kits can learn their legendary without losing existing skills")
    var demo=AbilityDemo.new();demo.setup(h,card)
    for tick in range(150):demo.advance(1.0/30.0)
    check(demo.cast_started and demo.affected_ids.size()>1,"Legendary preview resolves genuine area behavior")
    var next=HeroData.choices(copy,true,rng)
    check(next.all(func(c):return c.rarity!="Legendary"),"Owned legendary skills are never offered as rank upgrades")
 check(drops>0 and drops<150,"Legendary offers exist and are rarer than regular skill rolls")
 for sp in HeroData.species:
  var source=HeroData.make_hero(sp,"qa","QA",6)
  var demo=AbilityDemo.new();demo.setup(source,HeroData.legendary_card(sp))
  for tick in range(150):demo.advance(1.0/30.0)
  check(demo.cast_started and demo.affected_ids.size()>1,"Every species has a functioning area legendary: "+sp)
 var legacy=HeroData.choices(h,true,rng)[0].duplicate(true)
 legacy.rarity="Legendary";legacy.description+=" Legendary: old multiplier."
 h.pending=[[legacy.duplicate(true)],[legacy.duplicate(true)]]
 h.progression_version=2
 HeroData.migrate_progression(h)
 check(h.pending[0][0].key=="100" and h.pending[1][0].rarity=="Rare","Saved queued offers receive one fresh legendary, never duplicate acquisitions")
 HeroData.apply_choice(h,h.pending[0][0])
 var reloaded=JSON.parse_string(JSON.stringify(h))
 HeroData.migrate_progression(reloaded)
 check(reloaded.learned.has("100") and HeroData.regular_learned_count(reloaded)==3,"Legendary ownership survives JSON save/reload without consuming regular slots")
 var timing=CombatPacing.opening(reloaded,rng)
 check(timing["100"]<timing["6"],"Legendary opens during combat rather than waiting behind a full regular kit")
 print("Playtest feedback: ",checks," checks; ",failures," failures")
 quit(1 if failures else 0)
