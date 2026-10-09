extends Node3D

const GOLD = Color("f1cf85")
const INK = Color("0e1b26")
const WHITE = Color("fff5df")
const MUTED = Color("c2c4d6")
var campaign = Campaign.new()
var speedrun_lab: SpeedrunLab
var arena: ArenaView
var sound: SoundDesign
var ui: Control
var layer: CanvasLayer
var sim: BattleSim
var phase = "menu"
var tab = "overview"
var selected_id = ""
var paused = false
var speed = 1.0
const COUNTDOWN = 2.8
## Base combat tempo: "1x" plays this much faster than the simulation clock (pure presentation; balance is unchanged).
const TEMPO = 1.3
## Which recorded battle call plays for each moment (the four shouted lines from the voice-over recording).
const STREAK_CALLS := {2: "call_1", 3: "call_2", 4: "call_3", 5: "call_4"}   # double, triple, quadra, penta kill
var freeze_left = 0.0 # hit-stop: a few frames of near-freeze on heavy blows and knock-outs
var countdown = 0.0
var countdown_shown = -1
var countdown_label: Label
var legend_left = 0.0 # Legendary moment: brief slow-motion while a legendary skill lands
var legend_total = 1.0
var tactical = false # Tactical view: 0.75x with footprints, target lines and status tags
var hud_stats = true # combat HUD: team damage panels shown (toggled by the stats medallion)
var accumulator = 0.0
var match_label: Label
var toast_label: Label
var event_box: VBoxContainer
var event_history: Array = []
var exhibition = false
var exhibition_rivals: Array = []
var last_rendered_phase = ""
var presentation_tween: Tween
var showcase_index = 0
var new_slot = 1
var new_difficulty = "Keeper"
var new_mode = "guild" # "guild" (World Tour) or "dungeon"
var new_challenge_rank = 0
var new_ascension = 0 # dungeon ladder rank for the next dungeon run
var new_name: LineEdit
var new_club_draft = "Ravenmoor Menagerie"
var new_crest: Dictionary = {}
var new_motto = "Fortune favours the bold"
var new_motto_funny = false
var dragged_id = ""
var drag_offset = Vector2.ZERO
var orbiting = false
var qa = ""
var qa_capture = ""
var qa_level = 1
var qa_elapsed = 0.0
var qa_taken = false
var resolving = false
var desk_state = {"role": "All", "sort": "Board", "view": "Grid", "metric": "impact", "per_bout": true, "intel": "Rankings", "club": "Identity", "compare": []}

func _ready() -> void:
 HeroData.load_data()
 arena = ArenaView.new(); add_child(arena)
 arena.legendary_moment.connect(func(d): legend_left = d; legend_total = d)
 arena.hitstop.connect(func(d): freeze_left = maxf(freeze_left, d))
 sound = SoundDesign.new(); add_child(sound)
 UIFeel.attach(self)
 layer = CanvasLayer.new(); add_child(layer)
 ui = Control.new(); layer.add_child(ui); ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.mouse_filter = Control.MOUSE_FILTER_IGNORE; ui.theme = make_theme()
 for arg in OS.get_cmdline_user_args():
  if arg=="--disable-card-particles":CardParticles.enabled=false
  if arg.begins_with("--qa="): qa = arg.trim_prefix("--qa=")
  if arg.begins_with("--capture="): qa_capture = arg.trim_prefix("--capture=")
  if arg.begins_with("--qa_tab="): set_meta("qa_tab", arg.trim_prefix("--qa_tab="))
  if arg.begins_with("--qa_mouse="): set_meta("qa_mouse", Vector2(float(arg.trim_prefix("--qa_mouse=").get_slice(",", 0)), float(arg.trim_prefix("--qa_mouse=").get_slice(",", 1))))
  if arg.begins_with("--qa_level="): qa_level = int(arg.trim_prefix("--qa_level="))
  if arg.begins_with("--qa_view="): desk_state.view = arg.trim_prefix("--qa_view=")
  if arg.begins_with("--qa_scroll="): set_meta("qa_scroll", int(arg.trim_prefix("--qa_scroll=")))
 if not qa.is_empty():
  campaign.new_run("Ravenmoor Menagerie", 97, 731)
  League.run_tiers = {}; campaign.state.tiers = {}; campaign.create_market()   # QA uses the classic tiers
  # QA club: Jackalope headliner plus a full five from the draft board (exactly the 8-unit budget).
  var qa_picks = ["jackalope", "golem", "troll", "harpy", "naga"]
  for i in range(qa_picks.size()):
   var h = campaign.draft_prospect(qa_picks[i]); h.slot = Campaign.FORMATION[i]
   campaign.state.roster.append(h)
  campaign.state.headliner = campaign.state.roster[0].id
  campaign.draft_rivals()
  campaign.state.gold = 200
  if qa_level > 1: campaign.state.tour.level = qa_level; campaign.state.trophies = qa_level - 1
  selected_id = campaign.state.roster[0].id
  if qa in ["speedrun","speedrun_results"]:
   start_speedrun();campaign.state.speedrun_memory=true
   campaign.choose_starter(League.tiers().Legendary[0]);campaign.recruit(campaign.state.market.filter(func(h):return League.tier(h.sp)=="Epic")[0].id)
   for i in range(3):campaign.recruit(campaign.state.market.filter(func(h):return League.tier(h.sp)=="Common")[0].id)
   for h in campaign.lineup():
    for id in Forge.recommended(h.sp,h):speedrun_lab.plan.items.append({"id":id,"target":h.id})
   if qa=="speedrun_results":
    var records=JSON.parse_string(FileAccess.get_file_as_string(SpeedrunLab.RESULTS_PATH))
    if records is Array and records.any(func(r):return r.complete):speedrun_lab.result=records.filter(func(r):return r.complete)[0]
   phase="speedrun";render()
   print("PACKED SPEEDRUN: ready=",campaign.lineup_ready()," priorities=",speedrun_lab.plan.items.size()," simulate_button=",ui.find_child("SpeedrunSimulate",true,false)!=null," copy_button_removed=",ui.find_child("ShopChampionCopy",true,false)==null)
  elif qa.begins_with("dungeon"):
   Dungeon.start(campaign); campaign.state.gold = 420
   var dg = campaign.state.dungeon
   # QA_INSTANCE=magma_depths picks the instance; "dungeon_paths" stays on the choice screen.
   if OS.get_environment("QA_INSTANCE") != "":
    var other = dg.instance_choices[1] if dg.instance_choices[1] != OS.get_environment("QA_INSTANCE") else dg.instance_choices[0]
    dg.instance_choices = [OS.get_environment("QA_INSTANCE"), other]
   if qa != "dungeon_paths": Dungeon.choose_instance(campaign, dg.instance_choices[0])
   if qa in ["dungeon_trail", "dungeon_fight", "dungeon_loot", "dungeon_event", "dungeon_menu"]:
    for i in range(3 if qa == "dungeon_trail" else 1):
     Dungeon.enter(campaign, Dungeon.reachable(campaign)[0])
     dg.fight = false; dg.loot = []; dg.event = {}; Dungeon.node(campaign).done = true; campaign.state.tour.shop = false
    if qa == "dungeon_fight":
     dg.row = int(dg.row) - 1; dg.col = 0; dg.trail.pop_back()
     Dungeon.enter(campaign, Dungeon.reachable(campaign)[0])
    if qa == "dungeon_loot": Dungeon.offer_loot(campaign, "relic")
    if qa == "dungeon_event": dg.event = Dungeon.EVENTS[1].duplicate(true)
   if qa == "dungeon_draft":
    while campaign.state.roster.size() > 2: campaign.state.roster.pop_back()
    for h in campaign.state.roster: h.pending = []; h.rewards = []
    Dungeon.offer_draft(campaign, "checkpoint", 0)
   if qa in ["dungeon_intro", "dungeon_result"]:
    for h in campaign.state.roster: h.pending = []; h.rewards = []
    Dungeon.enter(campaign, Dungeon.reachable(campaign)[0])
   if qa == "dungeon_result":
    var test_sim = BattleSim.new(); test_sim.silent = true
    test_sim.setup(campaign.lineup(), campaign.opponent().roster, campaign.match_seed(), campaign.quality()); test_sim.run_to_end(); campaign.resolve(test_sim)
    sim = test_sim
   if qa in ["dungeon_trail", "dungeon_boss", "dungeon_endless", "dungeon_market"]:
    dg.relics = ["giants_belt", "vampiric_chalice", "headliner_crown", "trait_emblem:" + str(dg.traits.active[0]), "ember_heart"]
   if qa == "dungeon_endless":
    dg.awaiting_endless = true; dg.score = 6120; dg.wardens = 3
   if qa == "dungeon_boss":
    for h in campaign.state.roster: h.pending = []; h.rewards = []; h.level = 6
    dg.row = Dungeon.ROWS - 2; dg.col = 0; dg.trail = [0, 0, 0, 0, 0, 0, 0]; dg.event = {}; dg.loot = []
    Dungeon.enter(campaign, 0)
   if qa == "dungeon_scores":
    for i in range(4):
     campaign.state.dungeon.final_score = null; campaign.state.dungeon.erase("final_score"); campaign.state.name = ["Ravenmoor Menagerie", "Ashfall Lodge", "The Gilded Paw", "Moonlit Wardens"][i]; dg.score = [6120, 4210, 2890, 950][i]; dg.wardens = [3, 2, 1, 0][i]; dg.act = [4, 3, 2, 1][i]
     Dungeon.bank_score(campaign, ["Retired", "Fallen", "Fallen", "Fallen"][i])
   if qa == "dungeon_boss":
    phase = "prep"; render(); begin_battle()
   elif qa == "dungeon_stage":
    for h in campaign.state.roster: h.pending = []; h.rewards = []
    Dungeon.enter(campaign, 0); ArenaView.set_follow(false); phase = "prep"; render(); begin_battle(); paused = true
    arena.target_distance = 50; arena.camera_distance = 50; arena.target_pitch = 0.72; arena.camera_pitch = 0.72; arena.target_yaw = 0.0; arena.camera_yaw = 0.0
   elif qa == "dungeon_menu": phase = "menu"
   elif qa == "dungeon_intro": phase = "intro"
   elif qa == "dungeon_result": phase = "result"
   elif qa == "dungeon_market": phase = "hub"; tab = "market"
   else: phase = "hub"; tab = "overview"
   if qa not in ["dungeon_boss", "dungeon_stage"]: render()
   if qa == "dungeon_scores": DungeonUI.high_scores(self)
   if has_meta("qa_scroll"):
    await get_tree().process_frame
    for sc in ui.find_children("*","ScrollContainer",true,false): sc.scroll_vertical=int(get_meta("qa_scroll"))
  elif qa == "starter":
   campaign.new_run("Ravenmoor Menagerie",97,731);phase="starter";render()
  elif qa in ["skill_preview","heal_preview"]:
   var h=campaign.state.roster[0];h.sp="golem" if qa=="skill_preview" else "unicorn";h.level=3
   var rng=RandomNumberGenerator.new();rng.seed=103;HeroData.queue_reward(h,3,true,103)
   phase="upgrade";render()
   var key=0 if qa=="skill_preview" else 2
   var demo=AbilityPreview.new();demo.game=self;demo.hero=h.duplicate(true);demo.card={"type":"ability","key":str(key),"name":HeroData.learned_ability(h.sp,key).name,"description":HeroData.learned_ability(h.sp,key).description,"rarity":"Rare","bonus":1.1};ui.add_child(demo);demo.build()
  elif qa=="ascension_preview":
   var h=campaign.state.roster[0];h.sp="kirin";h.level=10;h.awakened=true;h.learned={}
   phase="hub";tab="overview";render()
   var demo=AbilityPreview.new();demo.game=self;demo.hero=h;var ability=ChampionEvolution.action(h.sp)
   demo.card={"type":"ability","key":"12","name":ability.name,"description":ability.description,"rarity":"Legendary","bonus":1.0};ui.add_child(demo);demo.build()
  elif qa in ["bracket","vault"]:
   if qa=="vault":
    TrophyVault.award(campaign,"Gold");campaign.state.tour.level+=1;TrophyVault.award(campaign,"Silver");campaign.state.tour.level+=1;TrophyVault.award(campaign,"Bronze")
   phase="hub";tab="overview";render();TournamentRewardsUI.open_screen(self,qa)
  elif qa == "intro":
   phase="intro";render()
  elif qa.begins_with("attacks_"):
   var themes={"attacks_claw":["owlbear","maul"],"attacks_bite":["cerberus","triplebite"],"attacks_weapon":["minotaur","whirl"],"attacks_slam":["troll","smash"],"attacks_thrust":["minotaur","gore"],"attacks_breath":["salamander","fire"]}
   var theme=themes.get(qa,themes.attacks_claw);var h=campaign.state.roster[0];h.sp=theme[0];h.level=7
   HeroData.queue_reward(h,5,true,103);phase="upgrade";render()
   var card={"type":"signature","key":"signature","name":HeroData.species[h.sp].ability_name,"description":"Signature attack","rarity":"Rare","bonus":1.1}
   if HeroData.species[h.sp].ab!=theme[1]:
    for i in range(HeroData.DISCOVERY_CHOICES):
     var ability=HeroData.learned_ability(h.sp,i)
     if ability.effect==theme[1]:
      card={"type":"ability","key":str(i),"name":ability.name,"description":ability.description,"rarity":"Rare","bonus":1.1};break
   var demo=AbilityPreview.new();demo.game=self;demo.hero=h.duplicate(true);demo.card=card;ui.add_child(demo);demo.build()
  elif qa.begins_with("particles_"):
   var themes={"particles_fire":["phoenix","beam"],"particles_ward":["golem","ward"],"particles_frost":["kirin","frost"],"particles_nature":["treant","roots"],"particles_storm":["kirin","storm"]}
   var theme=themes.get(qa,themes.particles_fire);var h=campaign.state.roster[0];h.sp=theme[0];h.level=7
   HeroData.queue_reward(h,5,true,103);phase="upgrade";render()
   var key=0
   for i in range(HeroData.DISCOVERY_CHOICES):
    if HeroData.learned_ability(h.sp,i).effect==theme[1]:key=i;break
   var a=HeroData.learned_ability(h.sp,key)
   var demo=AbilityPreview.new();demo.game=self;demo.hero=h.duplicate(true);demo.card={"type":"ability","key":str(key),"name":a.name,"description":a.description,"rarity":"Legendary","bonus":1.25};ui.add_child(demo);demo.build()
  elif qa in ["new", "new_dungeon"]:
   if qa == "new_dungeon": new_mode = "dungeon"; new_ascension = DungeonAscension.unlocked()
   phase = "new"; render()
  elif qa == "runover":
   campaign.state.run_over = true; phase = "runover"; render()
  elif qa == "arena":
   for h in campaign.state.roster: h.level = 3; h.learned = {"0": 1}
   phase = "prep"; begin_battle()
  elif qa in ["tour_shop","role_catalog","tour_world","tour_legendary","tour_arena"]:
   campaign.state.tour.level=5;campaign.state.gold=1800
   for h in campaign.state.roster:h.level=10;h.learned={"0":2,"1":2,"2":2};h.skill_rarity={"0":"Legendary","1":"Rare","2":"Rare","signature":"Legendary"}
   if qa in ["tour_shop","role_catalog"]:
    campaign.state.inventory=["fang","ember","coin","moon","archmage","phoenixember","seed"]
    campaign.state.roster[0].equipment={"0":"bastion","1":"fang"}
    if qa=="role_catalog":set_meta("shop_catalog",true);set_meta("shop_category",1)
    campaign.state.tour.shop=true;campaign.state.tour.stock=WorldTour.stock(campaign);phase="shop";render()
   elif qa=="tour_arena":
    var outfits=[{"0":"bastion","1":"bell"},{"0":"berserker","1":"bloodmaw"},{"0":"archmage","1":"crown"},{"0":"tempest","1":"quiver"},{"0":"lifebloom","1":"swap"}]
    for i in range(campaign.state.roster.size()):campaign.state.roster[i].equipment=outfits[i%outfits.size()]
    phase="prep";begin_battle()
   elif qa=="tour_legendary":
    var h=campaign.state.roster[0];h.learned={};h.pending=[[{"type":"ability","key":"0","name":"Fault Line · Rank 1","description":"A devastating fracture. Legendary: +25% potency.","rarity":"Legendary","bonus":1.25},{"type":"ability","key":"1","name":"Granite Covenant · Rank 1","description":"Fortify your allies. Rare: +10% potency.","rarity":"Rare","bonus":1.1},{"type":"ability","key":"2","name":"Stone Golem Cyclone · Rank 1","description":"A sweeping strike.","rarity":"Uncommon","bonus":1.0}]];phase="upgrade";render()
   else:phase="hub";tab="overview";render()
  elif qa == "exhibition":
   start_exhibition()
  elif qa == "evolution":
   var h = campaign.state.roster[0]; h.level = 10; h.learned = {"0":2, "2":2, "4":2}; h.signature_rank = 2
   HeroData.queue_reward(h, 10, true, 918)
   phase = "upgrade"; preview_team(); render()
  elif qa == "evolved_arena":
   for i in range(campaign.state.roster.size()):
    var h = campaign.state.roster[i]; h.level = 10; h.learned = {"0":2, "2":2, "4":2}; h.evolution = "%s:%d" % [h.sp, i % 3]
   phase = "prep"; begin_battle()
  elif qa == "levelup":
   var h = campaign.state.roster[0]; h.learned = {"0": 1}; h.level = 3; h.pending = []; h.rewards = []
   HeroData.queue_reward(h, 3, true, 4242)
   phase = "upgrade"; preview_team(); render()
  elif qa == "guild_demo":
   phase = "new"; render()
   var rr = RandomNumberGenerator.new(); rr.seed = 7
   for k in range(5):
    get_tree().create_timer(0.45 + k * 0.55).timeout.connect(func():
     var r = GuildNames.roll(rr); new_club_draft = r.name; new_motto = r.motto; new_crest = Crest.default_for(str(k * 97) + r.name); render())
  elif qa == "draft_demo":
   phase = "hub"; tab = "market"; render()
   get_tree().create_timer(1.3).timeout.connect(func(): desk_state.view = "Table"; render())
   get_tree().create_timer(2.4).timeout.connect(func(): desk_state.sort = "Power"; render())
  elif qa == "builds_demo":
   campaign.state.tour.level=5;campaign.state.gold=1800
   campaign.state.inventory=["fang","ember","coin","moon","archmage","phoenixember","seed"]
   campaign.state.roster[0].equipment={"0":"bastion","1":"fang"}
   campaign.state.tour.shop=true;campaign.state.tour.stock=WorldTour.stock(campaign);phase="shop";render()
   get_tree().create_timer(2.0).timeout.connect(func(): GearUI.recipe_book(self))
  elif qa == "tree_demo":
   var hero=campaign.state.roster[0]; hero.level=7; hero.learned={"0":2,"3":1,"6":1}
   phase="hub"; tab="roster"; render()
   ui.find_children("*","ManagementDesk",true,false)[0].profile(hero,true)
   var sc = ui.find_children("*","ScrollContainer",true,false)
   for scroll in sc:
    if scroll.size.y > 500:
     var tw = create_tween(); tw.tween_interval(0.8); tw.tween_property(scroll, "scroll_vertical", 900, 2.4).set_trans(Tween.TRANS_SINE)
  elif qa == "chest":
   phase = "hub"; render()
   ChestOpening.play(self, {"medal":"Gold","location":"Cinderfall Caldera","rewards":[{"kind":"item","item":"fang","title":"Sharpened Fang","detail":"+15% damage"},{"kind":"item","item":"lifebloom","title":"Lifebloom","detail":"Heals"},{"kind":"item","item":"phoenixember","title":"Phoenix Ember","detail":"WILD: rise again"},{"kind":"gold","title":"150 gold","detail":"Prize purse"}]}, func(): pass)
  elif qa == "tour_intro":
   phase = "hub"; render(); TourIntro.present(self, func(): pass)
  elif qa in ["bracket_anim", "cup_progress", "shop_after"]:
   for h in campaign.state.roster: h.pending = []; h.rewards = []
   var rounds = 1 if qa == "bracket_anim" else 6
   for bout in range(rounds):
    if campaign.state.tour.get("bracket",{}).get("finished",false): break
    if campaign.state.tour.shop: WorldTour.leave_shop(campaign)
    WorldTour.end_intermission(campaign)
    var test_sim = BattleSim.new(); test_sim.silent = true
    test_sim.setup(campaign.lineup(), campaign.opponent().roster, campaign.match_seed(), campaign.quality()); test_sim.run_to_end(); campaign.resolve(test_sim)
    for h in campaign.state.roster: h.pending = []; h.rewards = []
   if qa == "shop_after": campaign.state.run_over = false; campaign.state.tour.shop = true; campaign.state.tour.stock = WorldTour.stock(campaign)
   phase = "shop" if qa == "shop_after" else "result"; render()
   if qa == "bracket_anim": show_bracket_then_shop()
   elif qa == "shop_after": pass
   else: TournamentRewardsUI.open_screen(self, "progress", func(): pass, "Shop  ▶")
  elif qa in ["result", "upgrade", "report_abilities", "report_healing"]:
   for bout in range(2 if qa == "upgrade" else 1):
    var test_sim = BattleSim.new(); test_sim.silent = true
    test_sim.setup(campaign.lineup(), campaign.opponent().roster, campaign.match_seed(), campaign.quality()); test_sim.run_to_end(); campaign.resolve(test_sim)
   phase = "upgrade" if qa == "upgrade" else "result"; preview_team(); render()
   if qa.begins_with("report_"):
    var report_ui = ui.find_children("*", "MatchAnalytics", true, false)[0]
    if qa == "report_abilities": report_ui.detail_mode = "Abilities"
    else: report_ui.metric = "healing"
    report_ui.rebuild()
  elif qa == "art_profile":
   var hero=campaign.state.roster[0]; hero.level=7; hero.learned={"0":2,"1":1,"2":1}
   phase="hub"; tab="roster"; render()
   ui.find_children("*","ManagementDesk",true,false)[0].profile(hero,true)
  elif qa in ["prep", "tactics"]:
   phase = "prep"; render()
   if qa == "tactics": show_tactics(selected_id)
  else:
   phase = "hub" if qa != "menu" else "menu"; tab = qa if qa in ["roster", "market", "matches", "club", "intel"] else "overview"
   if qa=="roster":
    campaign.state.inventory=["fang","ember","coin","moon","archmage","phoenixember","seed"]
    campaign.state.roster[0].equipment={"0":"bastion","1":"fang"};campaign.state.roster[2].equipment={"claw":"sunclaw"}
    campaign.state.roster_intro=true;campaign.state.roster[0].xp_priority="focus";campaign.state.roster[0].level=4;campaign.state.roster[0].xp=90;campaign.state.roster[3].xp_priority="rest"
    campaign.save_formation(0)
   render()
   if qa == "settings": FlowUI.settings(self)
   if qa == "scout": ScoutUI.open(self, campaign.opponent())
   if qa == "stats_help":
    var sh = campaign.state.roster[0].duplicate(true); sh.level = 9; StatHex.explain(self, sh)
   if has_meta("qa_scroll"):
    await get_tree().process_frame
    for sc in ui.find_children("*","ScrollContainer",true,false): sc.scroll_vertical=int(get_meta("qa_scroll"))
 else: render()
 sound.scene_music(music_now())
 get_tree().auto_accept_quit = false

const TITLE_FONT = "res://assets/fonts/uncialantiqua.ttf"
const MENU_FONT = "res://assets/fonts/uncialantiqua.ttf"

## Buttons use the book serif in a firm weight with a little tracking: clean and legible, like the
## menus of Baldur's Gate 3. The uncial display face is kept for titles.
func button_font() -> Font:
 if not ResourceLoader.exists("res://assets/fonts/ebgaramond.ttf"): return load(MENU_FONT)
 var f = FontVariation.new(); f.base_font = load("res://assets/fonts/ebgaramond.ttf"); f.variation_opentype = {"wght": 680}; f.spacing_glyph = 1
 return f

func make_theme() -> Theme:
 var theme = Theme.new(); theme.default_font_size = 18
 if ResourceLoader.exists("res://assets/fonts/ebgaramond.ttf"):
  var body_font=FontVariation.new();body_font.base_font=load("res://assets/fonts/ebgaramond.ttf");body_font.variation_opentype={"wght":550};theme.default_font=body_font
 theme.set_font("font","Button",button_font())
 theme.set_font_size("font_size","Button",18)
 theme.set_color("font_color", "Label", WHITE)
 theme.set_color("font_outline_color", "Label", Color(0.01, 0.02, 0.03, 0.85))
 theme.set_constant("outline_size", "Label", 4)
 theme.set_color("font_color", "Button", Color("f1e6cc"))
 theme.set_color("font_hover_color", "Button", Color.WHITE)
 theme.set_color("font_pressed_color", "Button", GOLD)
 theme.set_color("font_disabled_color", "Button", Color("7d7364"))
 theme.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.8))
 theme.set_constant("outline_size", "Button", 4)
 # Carved buttons: dark lacquer, bronze rim, gold when hovered. Nothing flat or form-like.
 theme.set_stylebox("normal", "Button", DungeonUI.skin(Color("8a6a3a"), Color("1d1820"), 7, true, 2))
 theme.set_stylebox("hover", "Button", DungeonUI.skin(Color("e3c589"), Color("2c2228"), 7, true, 2))
 theme.set_stylebox("pressed", "Button", DungeonUI.skin(Color("e3c589"), Color("120e12"), 7, false, 2))
 theme.set_stylebox("disabled", "Button", DungeonUI.skin(Color(0.54, 0.42, 0.23, 0.35), Color(0.08, 0.07, 0.09, 0.8), 7, false, 1))
 theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
 for kind in ["normal", "hover", "pressed", "disabled"]:
  for b in [theme.get_stylebox(kind, "Button")]: b.content_margin_left = 14; b.content_margin_right = 14; b.content_margin_top = 6; b.content_margin_bottom = 6
 for kind in ["normal", "hover", "pressed", "disabled", "focus"]: theme.set_stylebox(kind, "OptionButton", theme.get_stylebox(kind, "Button"))
 theme.set_stylebox("normal", "LineEdit", DungeonUI.skin(Color("6b5434"), Color(0.04, 0.035, 0.05, 0.95), 6, false, 2))
 theme.set_stylebox("focus", "LineEdit", DungeonUI.skin(Color("e3c589"), Color(0, 0, 0, 0), 6, false, 2))
 for kind in ["normal", "focus"]: var e = theme.get_stylebox(kind, "LineEdit"); e.content_margin_left = 14; e.content_margin_right = 14; e.content_margin_top = 8; e.content_margin_bottom = 8
 theme.set_color("font_color", "LineEdit", Color("f1e6cc"))
 theme.set_color("caret_color", "LineEdit", GOLD)
 theme.set_constant("separation", "VBoxContainer", 14)
 theme.set_constant("separation", "HBoxContainer", 12)
 var plate = DungeonUI.skin(Color("6b5232"), Color(0.055, 0.045, 0.06, 0.95), 8, true, 2); plate.set_content_margin_all(20)
 theme.set_stylebox("panel", "PanelContainer", plate)
 # Tooltips and popups: parchment-dark scrolls with a gold rim.
 var tip = DungeonUI.skin(Color("b08a4a"), Color(0.05, 0.04, 0.05, 0.97), 6, true, 1); tip.set_content_margin_all(10)
 theme.set_stylebox("panel", "TooltipPanel", tip)
 theme.set_color("font_color", "TooltipLabel", Color("f1e6cc"))
 theme.set_font_size("font_size", "TooltipLabel", 15)
 theme.set_stylebox("panel", "PopupMenu", tip)
 theme.set_stylebox("hover", "PopupMenu", DungeonUI.skin(Color(0, 0, 0, 0), Color(0.89, 0.77, 0.54, 0.18), 4, false, 0))
 theme.set_color("font_color", "PopupMenu", Color("f1e6cc")); theme.set_color("font_hover_color", "PopupMenu", Color.WHITE)
 # Scrollbars: a thin bronze rod, no gutter.
 for bar in ["VScrollBar", "HScrollBar"]:
  theme.set_stylebox("scroll", bar, DungeonUI.skin(Color(0, 0, 0, 0), Color(0, 0, 0, 0.25), 4, false, 0))
  theme.set_stylebox("grabber", bar, DungeonUI.skin(Color(0, 0, 0, 0), Color(0.54, 0.42, 0.23, 0.75), 4, false, 0))
  theme.set_stylebox("grabber_highlight", bar, DungeonUI.skin(Color(0, 0, 0, 0), Color("e3c589"), 4, false, 0))
  theme.set_stylebox("grabber_pressed", bar, DungeonUI.skin(Color(0, 0, 0, 0), Color("e3c589"), 4, false, 0))
 theme.set_stylebox("background", "ProgressBar", DungeonUI.skin(Color("5a4a34"), Color(0.05, 0.04, 0.06, 0.9), 4, false, 1))
 theme.set_stylebox("fill", "ProgressBar", DungeonUI.skin(Color(0, 0, 0, 0), Color("c9a25a"), 4, false, 0))
 theme.set_stylebox("slider", "HSlider", DungeonUI.skin(Color(0, 0, 0, 0), Color(0.54, 0.42, 0.23, 0.6), 3, false, 0))
 theme.set_stylebox("grabber_area", "HSlider", DungeonUI.skin(Color(0, 0, 0, 0), Color("c9a25a"), 3, false, 0))
 theme.set_stylebox("grabber_area_highlight", "HSlider", DungeonUI.skin(Color(0, 0, 0, 0), Color("e3c589"), 3, false, 0))
 return theme

## Moves the old cold slate/teal surfaces onto the warm lacquer-and-bronze palette, so every
## screen shares one material instead of reading like stacked form boxes. Bright accents
## (health teal, rarity colours, team tints) are left alone.
static func warm(c: Color) -> Color:
 if c.a <= 0.0 or c.s > 0.8 or c.v > 0.55: return c
 if c.h < 0.38 or c.h > 0.88: return c   # cool blues and purples join the bronze-and-umber palette
 return Color.from_hsv(0.08 + 0.02 * c.v, c.s * 0.55, c.v * 0.9, c.a)

func style(fill: Color, border: Color, radius: int, margin: int, width: int = 1) -> StyleBoxFlat:
 fill = warm(fill); border = warm(border) if border.v < 0.55 else border
 var s = StyleBoxFlat.new(); s.bg_color = fill; s.border_color = border; s.anti_aliasing = true
 if margin>=10 and fill.a>.5:
  s.shadow_color=Color(0.0,0.0,0.0,0.35);s.shadow_size=10;s.shadow_offset=Vector2(0,4)
 # Clean look: no decorative outlines. Only emphasis survives (thick rims, or vivid accents
 # like selection gold), everything else is soft filled shapes.
 if width < 3 and (border.s < 0.45 or border.v < 0.7): width = 0
 s.set_border_width_all(width); s.set_corner_radius_all(maxi(radius, 8))
 s.content_margin_left = margin; s.content_margin_right = margin; s.content_margin_top = margin; s.content_margin_bottom = margin
 return s

func label(parent: Node, text_value: String, size: int = 18, color: Color = WHITE, wrap: bool = true) -> Label:
 var l = Label.new(); l.text = text_value; l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", color)
 if size >= 22: l.text = uncial_text(text_value)
 if size >= 40: l.add_theme_font_override("font", load(TITLE_FONT))
 elif size >= 22: l.add_theme_font_override("font", load(MENU_FONT))
 if wrap: l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 parent.add_child(l); return l

# Uncial Antiqua's lowercase g reads like a 5 next to numbers ("450g"), so spell gold out in display text.
static var _gold_re: RegEx
static func uncial_text(value: String) -> String:
 if _gold_re == null: _gold_re = RegEx.create_from_string("(\\d)g\\b")
 return _gold_re.sub(value, "$1 gold", true)

func button(parent: Node, text_value: String, callback: Callable, primary: bool = false, disabled: bool = false) -> Button:
 var b = Button.new(); b.text = uncial_text(text_value); b.custom_minimum_size.y = 44; b.disabled = disabled
 if primary:
  DungeonUI.restyle(self, b, true)
 b.pressed.connect(callback); parent.add_child(b); return b

func panel(rect: Rect2) -> VBoxContainer:
 var p = FantasyFrame.new(); ui.add_child(p); p.position = rect.position; p.size = rect.size
 var box = VBoxContainer.new(); p.add_child(box)
 return box

func scroll_panel(rect: Rect2) -> VBoxContainer:
 var p = FantasyFrame.new(); ui.add_child(p); p.position = rect.position; p.size = rect.size
 var scroll = ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; p.add_child(scroll)
 var box = VBoxContainer.new(); box.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(box)
 return box

func divider(parent: Node) -> void:
 var line = HSeparator.new(); parent.add_child(line)

func initials(name_value: String) -> String:
 var words = name_value.split(" ", false)
 var text_value = ""
 for w in words.slice(0, 3): text_value += w[0].to_upper()
 return text_value if not text_value.is_empty() else "M"

## Shop music also plays through the break between cups. The title screens play the intro theme,
## and inside a dungeon zone its own song plays everywhere but the outfitter.
func music_now() -> String:
 if phase in ["menu", "new"]: return SoundDesign.TITLE_TRACK
 var zone = zone_music()
 if zone != "" and phase != "shop": return zone
 if phase == "hub" and not campaign.state.is_empty() and campaign.state.get("tour", {}).get("intermission", false): return "shop"
 return SoundDesign.music_for_phase(phase)

func zone_music() -> String:
 if exhibition or campaign == null or campaign.state.is_empty() or not Dungeon.active(campaign): return ""
 var id = str(campaign.state.dungeon.get("instance", ""))
 return ("zone_" + id) if id != "" and sound.music_cache.has("zone_" + id) else ""

func render() -> void:
 if phase != last_rendered_phase:
  if presentation_tween: presentation_tween.kill()
  ui.modulate.a = 0.0
  presentation_tween = create_tween(); presentation_tween.tween_property(ui,"modulate:a",1.0,0.20)
  last_rendered_phase = phase
 sound.set_combat_paused(phase == "battle" and paused)
 sound.scene_music(music_now())
 if has_meta("retained_shop_carousel"):
  get_meta("retained_shop_carousel").queue_free();remove_meta("retained_shop_carousel")
 for child in ui.get_children():
  if phase=="shop" and child is ChampionCarousel and child.heroes.map(func(h):return h.id)==(campaign.lineup()+campaign.state.roster.filter(func(h):return h.slot<0)).map(func(h):return h.id):
   ui.remove_child(child);set_meta("retained_shop_carousel",child)
  else:child.queue_free();ui.remove_child(child)
 match_label = null; event_box = null
 arena.visible = phase not in ["hub", "menu", "new", "shop", "starter", "intro", "runover", "speedrun"]
 if phase in ["hub", "menu", "new", "shop", "starter", "intro", "runover", "speedrun"]:
  sim = null
  var backdrop=ClubBackdrop.new();backdrop.theme_name=ClubBackdrop.theme_for(self);backdrop.shade=.22 if phase=="menu" else .30;ui.add_child(backdrop)
  if phase in ["hub","shop","intro"] and not campaign.state.is_empty() and Dungeon.active(campaign) and not exhibition:
   # Inside the dungeon the colosseum disappears: the zone's own painting, deep in shadow.
   var zone=Dungeon.instance_id(campaign);var info=DungeonInstances.info(zone)
   var under=ColorRect.new();ui.add_child(under);under.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);under.color=Color(0.012,0.01,0.018);under.mouse_filter=Control.MOUSE_FILTER_IGNORE
   DungeonUI.painted(ui,zone,Rect2(0,0,1600,900),0.34)
   DungeonUI.vignette(ui,Rect2(0,0,1600,900),Color(info.fog).darkened(0.75),0.95)
 # Between cups: land on the recruit board with the new champions (once per break).
 var tour_state = campaign.state.get("tour", {}) if not campaign.state.is_empty() else {}
 if phase == "hub" and tour_state.get("intermission", false) and not tour_state.get("intermission_seen", false):
  tour_state.intermission_seen = true; tab = "market"
  get_tree().process_frame.connect(func(): FlowUI.banner(self, "NEW RECRUITS", Color("ffd36e"), "Recruit, set your roster and tactics, then descend" if Dungeon.active(campaign) else "Recruit, set your roster and tactics, then start the next cup"), CONNECT_ONE_SHOT)
 if phase == "hub" and campaign.state.get("goto_roster", false):
  campaign.state.erase("goto_roster"); tab = "roster"
  get_tree().process_frame.connect(func(): FlowUI.banner(self, "SQUAD READY", Color("ffd36e"), "Set formation, tactics and XP focus"), CONNECT_ONE_SHOT)
 build_header()
 if phase == "menu": build_menu()
 elif phase == "new": build_new()
 elif phase == "runover": build_runover()
 elif phase == "battle": build_battle_hud()
 elif phase == "result": build_result()
 elif phase == "upgrade": build_upgrade()
 elif phase == "speedrun": SpeedrunUI.build(self,speedrun_lab)
 elif phase == "shop": TournamentShop.build(self)
 elif phase == "starter": HeadlinerUI.starter(self)
 elif phase == "intro":
  var introduction=ContestantIntro.new();introduction.game=self;ui.add_child(introduction);introduction.build()
 elif phase == "prep": build_prep(); preview_formation()
 else:
  var desk = ManagementDesk.new(); desk.game = self; ui.add_child(desk); desk.build()
 toast_label = label(ui, "", 18, GOLD)
 toast_label.position = Vector2(350, 737 if phase == "battle" else 115); toast_label.size = Vector2(900, 45); toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func build_header() -> void:
 FantasyUI.header(self)

func stage_label() -> String:
 if campaign.state.has("tour"):
  return "TEAM LEVEL %d · %s" % [campaign.state.tour.level,WorldTour.region(campaign).name.to_upper()]
 if campaign.state.round < 3: return "PROVING GROUNDS %d / 3" % (campaign.state.round + 1)
 if campaign.state.round >= 17: return "SEASON COMPLETE"
 return "LEAGUE WEEK %d / 14" % (campaign.state.round - 2)

var welcomed = false
func build_menu() -> void:
 FantasyUI.menu(self)
 if not welcomed and qa.is_empty():
  welcomed = true
  get_tree().create_timer(0.6).timeout.connect(func(): sound.announce("guild"))

func build_showcase() -> void:
 var gallery = ["kirin", "minotaur", "phoenix", "griffin", "unicorn", "golem"]
 var sp = gallery[showcase_index % gallery.size()]
 var box = panel(Rect2(640,158,905,670))
 box.get_parent().add_theme_stylebox_override("panel",style(Color(0.045,0.09,0.12,0.75),Color("365c68"),20,24))
 label(box,"THE MENAGERIE  /  32 CREATURES. COUNTLESS BUILDS.",13,GOLD)
 var stage = Control.new(); stage.custom_minimum_size = Vector2(0,420); stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL; box.add_child(stage)
 var backdrop = SplashArt.new(); backdrop.sp = sp; backdrop.backdrop_only = true; stage.add_child(backdrop); backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var preview = HeroPreview.new(); preview.species_id = sp; stage.add_child(preview); preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); preview.stretch = true
 label(box,HeroData.species[sp].n,30)
 label(box,HeroData.species[sp].role + "  ·  " + HeroData.species[sp].ability_name,17,GOLD)
 var row = HBoxContainer.new(); box.add_child(row)
 button(row,"← Previous",func(): showcase_index = posmod(showcase_index-1,gallery.size()); render())
 for clip in ["idle","attack","cast"]: button(row,clip.capitalize(),func(): preview.play(clip))
 button(row,"Next →",func(): showcase_index = (showcase_index+1)%gallery.size(); render())

func build_new() -> void:
 if new_crest.is_empty(): new_crest = Crest.default_for(new_club_draft)
 # The great title.
 var title = Title3D.new(); ui.add_child(title); title.position = Vector2(150, 8); title.size = Vector2(1300, 180)
 var sub = label(ui, "FOUND YOUR GUILD" if new_mode != "dungeon" else "FOUND A GUILD · DESCEND INTO THE DUNGEON", 26, Color("fff2d0"), false)
 sub.position = Vector2(0, 190); sub.size = Vector2(1600, 40); sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 sub.add_theme_font_override("font", load(MENU_FONT)); sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85)); sub.add_theme_constant_override("outline_size", 6)
 # Charter (left): name, motto, difficulty, slot. One big button carries you on.
 var box = panel(Rect2(150, 252, 560, 520))
 box.add_theme_constant_override("separation", 10)
 var roller = RandomNumberGenerator.new(); roller.randomize()
 label(box, "NAME", 15, GOLD)
 var name_row = HBoxContainer.new(); box.add_child(name_row)
 new_name = LineEdit.new(); new_name.text = new_club_draft; new_name.max_length = 36; new_name.placeholder_text = "Your guild name"; new_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL; name_row.add_child(new_name)
 new_name.add_theme_font_size_override("font_size", 22); new_name.custom_minimum_size.y = 50
 var dice = button(name_row, "🎲", func():
  var r = GuildNames.roll(roller); new_club_draft = r.name; new_motto = r.motto; new_motto_funny = r.funny; render())
 dice.tooltip_text = "Roll a name and motto"; dice.custom_minimum_size = Vector2(56, 50); dice_icon(dice)
 var tone = HBoxContainer.new(); tone.add_theme_constant_override("separation", 8); box.add_child(tone)
 button(tone, "Epic name", func(): new_club_draft = GuildNames.roll(roller, 0).name; render()).add_theme_font_size_override("font_size", 14)
 button(tone, "Silly name", func(): new_club_draft = GuildNames.roll(roller, 1).name; render()).add_theme_font_size_override("font_size", 14)
 label(box, "MOTTO", 15, GOLD)
 var motto_row = HBoxContainer.new(); box.add_child(motto_row)
 var motto = LineEdit.new(); motto.text = new_motto; motto.max_length = 48; motto.placeholder_text = "Words to fight by"; motto.size_flags_horizontal = Control.SIZE_EXPAND_FILL; motto_row.add_child(motto)
 var mdice = button(motto_row, "🎲", func(): new_motto = GuildNames.motto(roller, randf() < 0.5); render()); mdice.custom_minimum_size.x = 56; mdice.tooltip_text = "Roll a motto"; dice_icon(mdice)
 motto.text_changed.connect(func(v): new_motto = v)
 label(box, "DIFFICULTY", 15, GOLD)
 var diff = HBoxContainer.new(); diff.add_theme_constant_override("separation", 8); box.add_child(diff)
 var diff_tips = [["Keeper", "Relaxed · finish top 5 to survive a cup"], ["Standard", "Fair fights · finish top 4"], ["Champion", "Brutal rivals · finish top 3"]]
 if new_mode == "dungeon": diff_tips = [["Keeper", "Relaxed · 4 lives · score ×0.8"], ["Standard", "Fair fights · 3 lives · score ×1"], ["Champion", "Brutal rivals · 2 lives · score ×1.35"]]
 for d in diff_tips:
  var db = button(diff, d[0], func(): new_difficulty = d[0]; new_challenge_rank=0; render(), new_difficulty == d[0]); db.tooltip_text = d[1]; db.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 if new_mode == "dungeon":
  # The dungeon ladder: each cleared rank unlocks the next; modifiers stack.
  var top = DungeonAscension.unlocked(); new_ascension = clampi(new_ascension, 0, top)
  var asc = OptionButton.new(); box.add_child(asc); asc.name = "DungeonAscensionPick"
  for rank in range(0, top + 1): asc.add_item("No Ascension · clear the dungeon to unlock rank 1" if rank == 0 else "Ascension %d · %s · score ×%.2f" % [rank, DungeonAscension.info(rank).name, 1.0 + 0.15 * rank])
  asc.selected = new_ascension
  asc.tooltip_text = "\n".join(DungeonAscension.lines(new_ascension)) if new_ascension > 0 else "Clear all three Wardens to unlock Ascension 1. Every rank adds a modifier and +15% score."
  asc.item_selected.connect(func(i): new_ascension = i; render())
  if new_ascension > 0:
   var mods = range(1, new_ascension + 1).map(func(i): return DungeonAscension.info(i).text.trim_suffix("."))
   label(box, "  ·  ".join(mods), 13, Color("e8b07a"))
 else:
  var challenge=OptionButton.new();box.add_child(challenge);challenge.add_item("Standard difficulty rules · no challenge modifier")
  for rank in range(1,RunDatabase.unlocked_rank()+1):challenge.add_item("Ascension %d · Champion rules · +%d%% rival combat strength"%[rank,rank*2])
  challenge.selected=new_challenge_rank
  challenge.item_selected.connect(func(i):new_challenge_rank=i;new_difficulty="Champion" if i>0 else new_difficulty;render())
 label(box, "SAVE SLOT", 15, GOLD)
 var slots = HBoxContainer.new(); slots.add_theme_constant_override("separation", 8); box.add_child(slots)
 for slot in range(1, 4):
  var saved = Campaign.new(); var occupied = saved.load_slot(slot)
  var b = button(slots, "%d%s" % [slot, " · used" if occupied else ""], func(): new_slot = slot; render(), new_slot == slot)
  b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; b.tooltip_text = "Replaces the saved run" if occupied else "Empty slot"
 # Footer: back on the left, the obvious way forward on the right.
 var back = button(ui, "◀  Menu", func(): phase = "menu"; render()); back.position = Vector2(150, 804); back.custom_minimum_size = Vector2(160, 58)
 var fwd = HBoxContainer.new(); ui.add_child(fwd); fwd.position = Vector2(1000, 800); fwd.size = Vector2(450, 64); fwd.alignment = BoxContainer.ALIGNMENT_END
 FlowUI.cta(self, fwd, "Enter the dungeon  ▶" if new_mode == "dungeon" else "Found guild  ▶", found_club, false, 450).tooltip_text = "Next: sign your Legendary headliner (you start with 1,200 gold)"
 # Crest forge (right).
 var right = panel(Rect2(740, 252, 710, 520))
 label(right, "CREST", 15, GOLD)
 var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 22); right.add_child(row)
 var crest_col = VBoxContainer.new(); row.add_child(crest_col)
 var crest = Crest.make(crest_col, new_crest, new_club_draft, Vector2(250, 290))
 var banner = label(crest_col, new_club_draft, 20, GOLD, false); banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; FlowUI.fit_label(banner, 250, 20, 11); banner.custom_minimum_size.x = 250
 var motto_label = label(crest_col, "“%s”" % new_motto, 14, MUTED); motto_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; motto_label.custom_minimum_size.x = 250
 motto.text_changed.connect(func(v): motto_label.text = "“%s”" % v)
 new_name.text_changed.connect(func(value): new_club_draft = value; crest.guild_name = value; banner.text = value; FlowUI.fit_label(banner, 250, 20, 11); banner.custom_minimum_size.x = 250; crest._place_emblem())
 var opts = VBoxContainer.new(); opts.size_flags_horizontal = Control.SIZE_EXPAND_FILL; opts.add_theme_constant_override("separation", 8); row.add_child(opts)
 var cycle = func(parent: Node, title_text: String, key: String, values: Array) -> void:
  var line = HBoxContainer.new(); parent.add_child(line)
  label(line, title_text, 14, MUTED, false).custom_minimum_size.x = 82
  button(line, "◀", func(): new_crest[key] = values[posmod(values.find(new_crest[key]) - 1, values.size())]; render())
  var shown = str(new_crest[key]); if key == "emblem" and shown != "Monogram": shown = HeroData.species[shown].n
  var v = label(line, shown, 17, WHITE, false); v.custom_minimum_size.x = 150; v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  button(line, "▶", func(): new_crest[key] = values[(values.find(new_crest[key]) + 1) % values.size()]; render())
 cycle.call(opts, "Shape", "shape", Crest.SHAPES)
 cycle.call(opts, "Division", "pattern", Crest.PATTERNS)
 cycle.call(opts, "Emblem", "emblem", Crest.emblems())
 cycle.call(opts, "Trim", "metal", Crest.METAL_ORDER)
 for pair in [["Field", "primary"], ["Charge", "secondary"]]:
  label(opts, pair[0], 14, MUTED, false)
  var grid = GridContainer.new(); grid.columns = 6; grid.add_theme_constant_override("h_separation", 6); grid.add_theme_constant_override("v_separation", 6); opts.add_child(grid)
  for t in Crest.TINCTURE_ORDER:
   var sw = Button.new(); sw.custom_minimum_size = Vector2(44, 30); sw.tooltip_text = t; grid.add_child(sw)
   var chosen = new_crest[pair[1]] == t
   for st in ["normal", "hover", "pressed"]: sw.add_theme_stylebox_override(st, style(Color(Crest.TINCTURES[t]), GOLD if chosen else (Color("ffffff") if st == "hover" else Color(0, 0, 0, 0.6)), 4, 0, 3 if chosen else 1))
   var key = pair[1]
   sw.pressed.connect(func(): new_crest[key] = t; render())
 var crest_dice = HBoxContainer.new(); opts.add_child(crest_dice)
 button(crest_dice, "Randomize crest", func(): new_crest = Crest.default_for(str(randi()) + new_club_draft); render())

func dice_icon(b: Button) -> void:
 b.text = ""
 var c = CenterContainer.new(); c.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(c); c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 FlowUI.glyph(c, "roll", 28)

func build_runover() -> void:
 var st = campaign.state; var t = st.get("tour", {})
 var title = label(ui, "THE RUN IS OVER", 84, Color("ffcfb8"), false)
 title.position = Vector2(0, 120); title.size = Vector2(1600, 120); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 title.add_theme_color_override("font_outline_color", Color("2a0c0c")); title.add_theme_constant_override("outline_size", 14)
 var box = panel(Rect2(400, 270, 800, 360))
 var row = HBoxContainer.new(); row.add_theme_constant_override("separation", 26); box.add_child(row)
 Crest.make(row, Crest.of_campaign(campaign), st.name, Vector2(170, 200))
 var col = VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
 label(col, st.name, 32, GOLD)
 if str(st.get("motto", "")) != "": label(col, "“%s”" % st.motto, 16, MUTED)
 var hist: Array = t.get("history", [])
 var best = 9
 for h in hist: best = mini(best, int(h.get("place", 9)))
 if Dungeon.active(campaign):
  var dg = st.dungeon
  label(col, "%s difficulty · Dungeon · reached %s, room %d" % [st.difficulty, Dungeon.depth(campaign).name, int(dg.row) + 1], 18)
  label(col, "%d fights · %d won · %d elites · %d Warden%s defeated · %d relics" % [int(dg.fights), int(dg.wins), int(dg.elites), dg.history.size(), "" if dg.history.size() == 1 else "s", dg.get("relics", []).size()], 18)
  var place = Dungeon.rank_of(campaign)
  label(col, "FINAL SCORE %d%s" % [int(dg.get("final_score", Dungeon.final_score(campaign))), ("  ·  #%d ON YOUR HIGH SCORES" % place) if place > 0 else ""], 22, GOLD)
 else:
  label(col, "%s difficulty · %d cups contested · %d cup%s won" % [st.difficulty, hist.size(), int(st.get("trophies", 0)), "" if int(st.get("trophies", 0)) == 1 else "s"], 18)
  label(col, "Best finish: %s · Reached %s" % [TournamentRewardsUI._place_text(best) if best < 9 else "—", WorldTour.region(campaign).place if not t.is_empty() else "—"], 18)
 var face = campaign.headliner()
 if not face.is_empty(): label(col, "Headliner: %s the %s · Level %d" % [face.name, HeroData.species[face.sp].n, int(face.level)], 16, GOLD)
 label(box, "Your legacy boosts and unlocked evolutions carry over to your next guild.", 15, MUTED)
 var actions = HBoxContainer.new(); box.add_child(actions)
 button(actions, "Found a new guild", func(): new_crest = {}; new_mode = "dungeon" if Dungeon.active(campaign) else "guild"; phase = "new"; render(), true).size_flags_horizontal = Control.SIZE_EXPAND_FILL
 button(actions, "Main menu", func(): phase = "menu"; render()).size_flags_horizontal = Control.SIZE_EXPAND_FILL

func found_club() -> void:
 var name_value = new_name.text
 if FileAccess.file_exists(Campaign.save_path(new_slot)):
  var dialog = ConfirmationDialog.new(); ui.add_child(dialog)
  dialog.title = "Replace this campaign slot?"; dialog.dialog_text = "Slot %d already has a campaign. Replace it with your new club?\nThe previous file will be kept as a recovery backup." % new_slot
  dialog.confirmed.connect(func(): start_club(name_value, new_slot)); dialog.popup_centered(Vector2i(520, 180))
 else: start_club(name_value, new_slot)

func start_speedrun() -> void:
 if is_instance_valid(speedrun_lab) and speedrun_lab.running:
  phase="speedrun";render();return
 if not is_instance_valid(speedrun_lab):
  speedrun_lab=SpeedrunLab.new();speedrun_lab.game=self;add_child(speedrun_lab)
 exhibition=false
 campaign=Campaign.new();campaign.new_run("Speedrun laboratory",98,0,"Standard")
 campaign.state.speedrun_lab=true;campaign.state.challenge_rank=0
 campaign.save();speedrun_lab.reset_plan();selected_id="";tab="market";phase="starter";render()

func resume_speedrun() -> void:
 if is_instance_valid(speedrun_lab) and speedrun_lab.running:phase="speedrun";render();return
 var data=JSON.parse_string(FileAccess.get_file_as_string("user://speedrun_draft.json"))
 if not Campaign.valid(data) or not data.get("speedrun_lab",false):toast("The speedrun draft could not be read.");return
 if not is_instance_valid(speedrun_lab):speedrun_lab=SpeedrunLab.new();speedrun_lab.game=self;add_child(speedrun_lab)
 campaign=Campaign.new();campaign.state=data;HeroData.run_salt=str(data.get("salt",data.seed));League.run_tiers=data.get("tiers",{});campaign.ensure_management()
 speedrun_lab.reset_plan()
 if data.get("speedrun_plan") is Dictionary:speedrun_lab.plan=data.speedrun_plan.duplicate(true)
 exhibition=false;selected_id=str(data.get("selected",""));tab="market"
 phase="speedrun" if campaign.lineup_ready() else "starter" if campaign.state.roster.is_empty() else "hub";render()

func start_club(name_value: String, slot: int) -> void:
 exhibition = false
 campaign.new_run(name_value, slot, 0, new_difficulty)
 if new_mode == "dungeon": Dungeon.start(campaign, clampi(new_ascension, 0, DungeonAscension.unlocked()))
 campaign.state.challenge_rank=0 if new_mode == "dungeon" else clampi(new_challenge_rank,0,RunDatabase.unlocked_rank())
 RunDatabase.ensure_id(campaign)
 campaign.state.crest = new_crest.duplicate() if not new_crest.is_empty() else Crest.default_for(name_value)
 campaign.state.motto = new_motto.strip_edges().left(48)
 desk_state.compare = []; desk_state.role = "All"
 if not campaign.save(): toast(campaign.last_error); return
 phase = "starter"; tab = "market"; selected_id = ""; render()

func load_campaign(slot: int) -> void:
 exhibition = false
 if not campaign.load_slot(slot): toast(campaign.last_error); return
 desk_state.compare = []; desk_state.role = "All"
 sound.set_music(campaign.state.get("music", true)); sound.effects_enabled = campaign.state.get("effects", true)
 sound.apply_levels()
 selected_id = campaign.state.get("selected", "")
 phase = "upgrade" if not campaign.pending_heroes().is_empty() else "shop" if campaign.state.get("tour",{}).get("shop",false) else "hub"
 if campaign.state.roster.is_empty() and campaign.state.has("tour"):phase="starter"
 if campaign.state.get("run_over", false): phase = "runover"
 tab = "overview"; render(); sound.scene_music(music_now())

func controls_hint() -> void:
 var l = label(ui, "RIGHT DRAG TO ORBIT    ·    SCROLL TO ZOOM    ·    F11 FULLSCREEN", 13, Color("c1cfcc"))
 l.position = Vector2(400, 820); l.size = Vector2(790, 25); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func prepare_match() -> void:
 if campaign.state.get("speedrun_lab",false):
  if not campaign.lineup_ready():toast("Draft four or five champions first.");return
  phase="speedrun";render();return
 if not campaign.pending_heroes().is_empty(): phase = "upgrade"; render(); return
 if campaign.state.get("tour",{}).get("shop",false): phase="shop"; render(); return
 if campaign.state.get("tour",{}).get("complete",false) or (not campaign.state.has("tour") and campaign.state.round >= 17): tab = "overview"; phase = "hub"; render(); return
 if campaign.state.roster.size() < Campaign.MIN_SQUAD and not Dungeon.active(campaign): tab = "market"; phase = "hub"; render(); return
 phase = "prep"; render()

func build_prep() -> void:
 var box = scroll_panel(Rect2(26, 135, 350, 602))
 label(box, "Formation", 28)
 var select = OptionButton.new()
 for h in campaign.state.roster:
  select.add_item(h.name + " · " + HeroData.species[h.sp].n)
  if h.id == selected_id: select.selected = select.item_count - 1
 if selected_id.is_empty(): selected_id = campaign.state.roster[0].id
 select.item_selected.connect(func(i): selected_id = campaign.state.roster[i].id; render())
 box.add_child(select)
 label(box, "BACK         MIDDLE         FRONT →", 12, GOLD)
 var grid = Control.new(); grid.custom_minimum_size = Vector2(250, 418); box.add_child(grid)
 for slot in range(15):
  var cell = FormationCell.new(); cell.destination = slot; cell.size = Vector2(94, 76)
  cell.position = Vector2((slot % 3) * 78, int(slot / 3) * 76 + (38 if slot % 3 == 1 else 0))
  var heroes = campaign.lineup().filter(func(h): return h.slot == slot)
  cell.hero_id = heroes[0].id if not heroes.is_empty() else ""
  cell.caption = heroes[0].name if not heroes.is_empty() else "+"
  cell.selected = cell.hero_id == selected_id
  cell.tooltip_text = cell.caption + " · deployment hex"
  cell.placed.connect(place_hero)
  cell.pressed.connect(func(): place_hero(selected_id, slot))
  grid.add_child(cell)
 var footer = panel(Rect2(26, 749, 350, 127))
 var actions = HBoxContainer.new(); footer.add_child(actions)
 button(actions, "◀", func(): phase = "hub"; render()).tooltip_text = "Back"
 var enter = FlowUI.cta(self, actions, "FIGHT  ▶", begin_battle, not campaign.lineup_ready(), 250)
 enter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 enter.tooltip_text = "%d / 5 ready · %s" % [campaign.lineup().size(), campaign.state.difficulty]
 var opp = campaign.opponent()
 var scout = panel(Rect2(406, 126, 784, 86))
 var scout_heading = HBoxContainer.new(); scout.add_child(scout_heading)
 label(scout_heading, "NEXT  /  " + opp.name.to_upper(), 15, GOLD, false).size_flags_horizontal = Control.SIZE_EXPAND_FILL
 button(scout_heading, "Scout rivals", show_opponent_scout)
 var orders = scroll_panel(Rect2(1220, 135, 354, 741))
 label(orders, "ORDERS", 24)
 for hero in campaign.lineup():
  var card = PanelContainer.new(); orders.add_child(card)
  card.add_theme_stylebox_override("panel", style(Color("17303b"), Color("365662"), 10, 10))
  var stack = VBoxContainer.new(); card.add_child(stack)
  var identity = HBoxContainer.new(); stack.add_child(identity)
  var portrait = SplashArt.make(identity, hero.sp, Vector2(50, 52))
  var info = VBoxContainer.new(); info.size_flags_horizontal = Control.SIZE_EXPAND_FILL; identity.add_child(info)
  label(info, hero.name, 18)
  label(info, HeroData.species[hero.sp].role, 12, MUTED)
  var tactics = button(identity, "Tactics", func(): selected_id = hero.id; show_tactics(hero.id))
  tactics.name = "StarterTactics_" + hero.id; tactics.add_theme_font_size_override("font_size", 14)
  label(stack, BattleTactics.summary(hero), 13, GOLD)

 controls_hint()

func place_hero(id: String, destination: int) -> void:
 if campaign.place_hero(id, destination): selected_id = id; render()
 else: toast("Swap with a starter, or move a starter to the bench first.")

func preview_formation() -> void:
 arena.set_region(WorldTour.region(campaign) if campaign.state.has("tour") else {})
 arena.clear_fighters(); arena.target_distance = 49.0 * ArenaGrid.LINEAR_SCALE; arena.camera.h_offset = 0; arena.target_pitch = 0.95; arena.target_yaw = 0.0
 sim = BattleSim.new(); sim.silent = true
 sim.setup(campaign.lineup(), campaign.opponent().roster, campaign.match_seed(), campaign.quality())
 arena.sync(sim, 1.0, 1.0)

func preview_team() -> void:
 arena.clear_fighters(); arena.target_distance = 24.0; arena.camera.h_offset = -3.7; arena.target_pitch = 0.52
 sim = BattleSim.new(); sim.silent = true
 var list = campaign.lineup()
 if list.is_empty(): demo_stage(); return
 for i in range(list.size()): sim.add_unit(list[i], 0, Vector2((i % 3 - 1) * 2.8 + 1, (i / 3) * 3.6 - 1.6))
 arena.sync(sim, 1.0)

func demo_stage() -> void:
 arena.clear_fighters(); arena.target_distance = 16; arena.camera.h_offset = -3.8; arena.target_pitch = 0.36
 sim = BattleSim.new(); sim.silent = true
 for i in range(3):
  var h = HeroData.make_hero(["minotaur", "kirin", "griffin"][i], "demo" + str(i), ["THE VANGUARD", "THE TEMPEST", "THE SOVEREIGN"][i])
  var u = sim.add_unit(h, 0, Vector2((i - 1) * 2.8 + 0.3, i % 2 * 1.2) / ArenaView.FLOOR_SCALE); u.heading = 0.2
 arena.sync(sim, 1.0)

# The contestant intro screen is retired: matches start straight in the arena with a countdown.
func introduce_match() -> void:
 if campaign.state.get("speedrun_lab",false):prepare_match();return
 if not campaign.lineup_ready() or not campaign.pending_heroes().is_empty():return
 if Dungeon.active(campaign):
  # The dungeon has no bracket board: only a room with a pending fight leads to the arena.
  if campaign.state.tour.get("intermission",false): WorldTour.end_intermission(campaign)
  if not campaign.state.dungeon.fight or campaign.state.tour.get("shop",false): phase = "hub"; tab = "overview"; render(); return
  phase = "intro"; render(); return
 if campaign.state.has("tour"): WorldTour.end_intermission(campaign)
 if campaign.state.get("tour",{}).get("shop",false) or campaign.state.get("tour",{}).get("complete",false):return
 # Every tour fight walks up to the tournament board first, then the matchup, then the arena.
 var t = campaign.state.get("tour", {})
 # A new stop on the World Tour gets its own arrival card first.
 if not t.is_empty() and int(t.get("intro_level", 0)) != int(t.get("level", 1)):
  t.intro_level = int(t.get("level", 1))
  phase = "hub"; tab = "overview"; render()
  TourIntro.present(self, introduce_match)
  return
 if not t.is_empty() and int(t.get("board_seen", -1)) != int(t.get("serial", 0)):
  t.board_seen = int(t.get("serial", 0))
  phase = "hub"; tab = "overview"; render()
  TournamentRewardsUI.open_screen(self, "bracket", func(): phase = "intro"; render(), "Matchup  ▶")
  return
 phase = "intro"; render()

func begin_battle() -> void:
 campaign.state.erase("roster_intro")
 if not campaign.lineup_ready() or not campaign.pending_heroes().is_empty(): return
 if not exhibition and (campaign.state.get("tour",{}).get("shop",false) or campaign.state.get("tour",{}).get("complete",false)): return
 if not exhibition and campaign.state.has("tour"):campaign.state.tour.cup_started=true
 if exhibition or not qa.is_empty() or campaign.save():
  phase = "battle"; paused = false; speed = 0.75 if tactical else 1.0; accumulator = 0.0; event_history.clear(); resolving = false
  sound.reset_battle()
  arena.set_region(WorldTour.region(campaign) if not exhibition and campaign.state.has("tour") else {})
  arena.clear_fighters(); arena.live = true; arena.camera.h_offset = 0; arena.target_distance = 31 if tactical else 34; arena.target_pitch = 0.95; arena.target_yaw = 0.0
  if arena.clarity: arena.clarity.tactical = tactical
  sim = BattleSim.new(); sim.action.connect(on_battle_event)
  if not exhibition: sim.team_mods = campaign.battle_mods(); sim.elite_squads = not Dungeon.active(campaign)
  sim.setup(campaign.lineup(), exhibition_rivals if exhibition else campaign.opponent().roster, campaign.match_seed(), 1.0 if exhibition else campaign.quality())
  sound.announce("battle", true)
  countdown = COUNTDOWN; countdown_shown = -1; arena.target_yaw = 0.55; arena.camera_yaw = 0.55; arena.target_distance += 6.0
  arena.sync(sim, 1.0); render(); sound.scene_music(zone_music() if zone_music() != "" else "arena"); pass # Music supplies the arena entrance; avoid a competing pitched stinger.
 else: toast(campaign.last_error)

func update_countdown() -> void:
 if not is_instance_valid(countdown_label): return
 var step = 3 - int(floor((COUNTDOWN - countdown) / 0.7))
 if countdown <= 0.0: countdown_label.visible = false; return
 if step != countdown_shown:
  countdown_shown = step
  countdown_label.text = str(step) if step > 0 else "FIGHT!"
  countdown_label.add_theme_color_override("font_color", GOLD if step > 0 else Color("ff8a5c"))
  countdown_label.pivot_offset = countdown_label.size * 0.5
  countdown_label.scale = Vector2.ONE * 1.8; countdown_label.modulate.a = 1.0
  var tw = create_tween().set_parallel(true)
  tw.tween_property(countdown_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  if step <= 0: tw.tween_property(countdown_label, "modulate:a", 0.0, 0.7).set_delay(0.25)
  sound.cue("contest_versus" if step <= 0 else "contest_reveal", step <= 0)
  sound.announce("fight" if step <= 0 else "count_%d" % step, true)

func build_battle_hud() -> void:
 if not exhibition and Dungeon.active(campaign):
  # Dungeon chambers close in at the edges of the screen.
  DungeonUI.vignette(ui, Rect2(0, 0, 1600, 900), Color(DungeonInstances.info(Dungeon.instance_id(campaign)).fog).darkened(0.55), 0.85)
 var dashboard = BattleDashboard.new(); dashboard.game = self; ui.add_child(dashboard)
 if countdown > 0.0:
  countdown_label = Label.new(); ui.add_child(countdown_label)
  countdown_label.size = Vector2(600, 220); countdown_label.position = Vector2(500, 300)
  countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  countdown_label.add_theme_font_size_override("font_size", 150)
  countdown_label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02)); countdown_label.add_theme_constant_override("outline_size", 22)
  countdown_label.add_theme_font_override("font", load(TITLE_FONT))
  countdown_shown = -1
 # Scoreboard: a carved banner, not a box.
 var banner = HudKit.banner(ui, Rect2(540, 124, 520, 62))
 match_label = label(banner, "THE GATES ARE OPEN", 26, Color("f1e6cc"), false); match_label.position = Vector2(0, 12); match_label.size = Vector2(520, 40)
 match_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; match_label.add_theme_font_override("font", load(TITLE_FONT))
 match_label.add_theme_constant_override("outline_size", 6)
 # Controls: medallions resting on the battlefield, bottom right.
 var dock = HBoxContainer.new(); ui.add_child(dock); dock.add_theme_constant_override("separation", 10); dock.position = Vector2(1600 - 6 * 64 - 26, 812)
 HudKit.medallion(dock, self, "play" if paused else "pause", "", "Resume" if paused else "Pause", func(): paused = not paused; render(), paused)
 var speed_text = "¾" if tactical else ("%d×" % int(speed))
 HudKit.medallion(dock, self, "", speed_text, "Speed: %s. Click to cycle 1× → 2× → 4× → tactical ¾× (footprints, target lines and status tags)." % speed_text, cycle_speed, speed > 1.0 or tactical)
 HudKit.medallion(dock, self, "camera", "", "Reset camera", func(): arena.target_yaw = 0.0; arena.target_distance = 31 if tactical else 34; arena.target_pitch = 0.95; arena.follow_bias = 0.0)
 HudKit.medallion(dock, self, "follow", "", "Follow the action: pan to the fight and zoom to fit it. Scroll still zooms.", func(): ArenaView.set_follow(not ArenaView.follow_on); render(), ArenaView.follow_on)
 HudKit.medallion(dock, self, "stats", "", ("Hide" if hud_stats else "Show") + " team damage panels", func(): hud_stats = not hud_stats; render(), hud_stats)
 HudKit.medallion(dock, self, "eye", "", "Tactical view", func(): set_tactical(not tactical), tactical)
 # Combat log: floating lines over the arena.
 event_box = VBoxContainer.new(); ui.add_child(event_box); event_box.add_theme_constant_override("separation", 2)
 event_box.position = Vector2(1210, 700); event_box.size = Vector2(370, 100); event_box.alignment = BoxContainer.ALIGNMENT_END; event_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
 refresh_feed()

func on_battle_event(e: Dictionary) -> void:
 arena.handle_event(e)
 var unit = sim.find_unit(int(e.get("uid", -1)))
 var pan = 0.0
 if e.has("pos"):
  var screen = arena.camera.unproject_position(ArenaView.world_point(e.pos, 1.0))
  pan = clampf(screen.x / get_viewport().get_visible_rect().size.x * 2.0 - 1.0, -1.0, 1.0)
 sound.battle_event(e, unit, pan)
 if e.type == "cast":
  var h = sim.find_unit(e.uid)
  event_history.append(h.hero.name + " · " + e.name)
 elif e.type == "multikill":
  sound.announce(STREAK_CALLS[mini(5, int(e.count))], true)
  var phrase = ["", "", "DOUBLE KILL", "TRIPLE KILL", "QUADRA KILL", "PENTA KILL"][mini(5, e.count)]
  event_history.append(e.name + " · " + phrase); sound.cue("multikill", true)
  toast(e.name.to_upper() + "  ·  " + phrase)
 elif e.type == "death":
  var hero = sim.find_unit(e.uid)
  if not hero.is_empty() and not hero.summon: event_history.append(hero.hero.name + " has fallen")
 if event_history.size() > 4: event_history.pop_front()
 if e.type in ["cast", "death", "multikill"]: refresh_feed()

func refresh_feed() -> void:
 if not is_instance_valid(event_box): return
 for child in event_box.get_children(): child.queue_free(); event_box.remove_child(child)
 var lines = event_history.slice(-3)
 for i in range(lines.size()):
  var l = label(event_box, lines[i], 14, Color("f1e6cc"), false); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
  l.add_theme_constant_override("outline_size", 6); l.modulate.a = 0.45 + 0.55 * float(i + 1) / lines.size()

## Speed medallion: 1× → 2× → 4× → tactical ¾× → 1×.
func cycle_speed() -> void:
 if tactical: set_tactical(false); speed = 1.0
 elif speed < 2.0: speed = 2.0
 elif speed < 4.0: speed = 4.0
 else: set_tactical(true); return
 render()

var resolve_thread: Thread
var resolve_wait := 0.0

func finish_battle() -> void:
 if resolving: return
 resolving = true
 if not qa.is_empty(): return
 if exhibition:
  var rows = sim.report_rows()
  campaign.state.report = {"winner":sim.winner,"opponent":"The Crown Challengers","gold":0,"duration":sim.time,"rows":rows}
  show_result(); return
 # Recording the result also plays out the rest of the bracket (several full simulations). That runs
 # on a worker thread so the arena keeps animating instead of freezing before the stats screen.
 resolve_wait = 0.0
 resolve_thread = Thread.new(); resolve_thread.start(campaign.resolve.bind(sim))

func poll_resolve(dt: float) -> void:
 if resolve_thread == null: return
 resolve_wait += dt
 if resolve_wait > 0.5 and is_instance_valid(match_label) and not match_label.text.ends_with("…"): match_label.text += "   ·   Tallying results…"
 if resolve_thread.is_alive(): return
 var ok = resolve_thread.wait_to_finish(); resolve_thread = null
 if not ok:
  paused=true
  var retry=AcceptDialog.new();ui.add_child(retry);retry.title="Match result not saved";retry.dialog_text=campaign.last_error+" Your result is still available. Retry saving to continue."
  retry.get_ok_button().text="Retry save";retry.confirmed.connect(func():resolving=false;finish_battle());retry.popup_centered(Vector2i(560,180));return
 show_result()

func show_result() -> void:
 phase = "result"; sound.scene_music(music_now()); sound.cue("victory" if sim.winner == 0 else "honor", true)
 render()
 FlowUI.banner(self, "VICTORY" if sim.winner == 0 else "DRAW" if sim.winner == -1 else "DEFEAT", Color("ffd36e") if sim.winner == 0 else Color("ff8a7a"))

func build_result() -> void:
 var report = campaign.state.report
 if report.is_empty(): phase = "hub"; render(); return
 var box = scroll_panel(Rect2(40, 130, 1520, 645))
 box.add_theme_constant_override("separation",8)
 var won = report.winner == 0; var draw = report.winner == -1
 var verdict = label(box, "VICTORY" if won else "DRAW" if draw else "DEFEAT", 64, Color("ffd36e") if won else Color("c9d6dc") if draw else Color("ff8a7a"))
 verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; verdict.add_theme_font_override("font", load(TITLE_FONT))
 verdict.add_theme_color_override("font_outline_color", Color("1a0f14")); verdict.add_theme_constant_override("outline_size", 10)
 var fallen = report.rows.filter(func(r): return r.team == 0 and not r.alive).size()
 var chips = HBoxContainer.new(); chips.alignment = BoxContainer.ALIGNMENT_CENTER; chips.add_theme_constant_override("separation", 34); box.add_child(chips)
 FlowUI.chip(self, chips, "swords", "vs " + str(report.opponent), "%.0f second fight" % report.duration)
 if not exhibition:
  FlowUI.chip(self, chips, "coin", "+%d" % report.gold, "Gold earned", Color("ffdf7e"))
  FlowUI.chip(self, chips, "heart", "%d/5 alive" % (5 - fallen), "Survivors · everyone recovers before the next fight", Color("ff9aa5"))
  var xp = label(chips, "+%d XP" % (80 if won else 65), 21, Color("9fd8ff"), false); xp.tooltip_text = "XP for every fielded hero"; xp.mouse_filter = Control.MOUSE_FILTER_STOP
 if not exhibition and report.get("dungeon", false):
  var lost = report.get("life_lost", false) or report.get("flame_lost", false)
  var verdict_text = ("%s · %d LEFT" % ["TWO LIVES LOST" if int(report.get("lives_lost", 1)) > 1 else "LIFE LOST", int(report.get("lives", 0))]) if lost else ("FLAWLESS · +50% POINTS · " if report.get("flawless", false) else "") + ("DUNGEON CONQUERED · BANK YOUR SCORE OR GO ENDLESS" if report.get("dungeon_cleared", false) else ("WARDEN DEFEATED · THE WAY DOWN IS OPEN" if report.get("warden_down", false) else "ROOM CLEARED · CHOOSE YOUR SPOILS ON THE MAP"))
  var fl = label(box, verdict_text, 26, Color("ff8a7a") if lost else GOLD); fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  if int(report.get("points", 0)) > 0:
   var pts = label(box, "+%d POINTS · %d TOTAL" % [int(report.points), int(campaign.state.dungeon.score)], 18, Color("9fd8ff")); pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 if not exhibition and report.has("tour_level"):
  if report.has("tournament_won"):
   var cup = label(box, ("CUP WON · GOLD CHEST" if report.tournament_won else "CUP OVER · %s%s" % [TournamentRewardsUI._place_text(int(report.get("place",0))).to_upper(), " · %s CHEST" % str(report.medal).to_upper() if report.has("medal") else ""]), 26, GOLD)
   cup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  if report.get("chest",false):
   var crow = HBoxContainer.new(); crow.alignment = BoxContainer.ALIGNMENT_CENTER; box.add_child(crow)
   FlowUI.cta(self, crow, "Open chest  ▶", func():
    var chests = TrophyVault.unopened(campaign)
    if chests.is_empty(): TournamentRewardsUI.open_screen(self,"vault"); return
    var got = TrophyVault.open(campaign, chests[-1].id)
    if got.is_empty(): toast(TrophyVault.error if not TrophyVault.error.is_empty() else "Could not open the chest."); return
    ChestOpening.play(self, got, render), false, 320)
 if report.has("ais"): impact_board(box, report)
 var stats_row = HBoxContainer.new(); box.add_child(stats_row)
 var holder = VBoxContainer.new(); box.add_child(holder)
 var toggle = button(stats_row, "Match stats  ▾", func(): pass)
 toggle.pressed.connect(func():
  if holder.get_child_count() > 0:
   for ch in holder.get_children(): ch.queue_free()
   toggle.text = uncial_text("Match stats  ▾")
  else:
   var analytics = MatchAnalytics.new(); analytics.game = self; analytics.report = report; holder.add_child(analytics)
   toggle.text = uncial_text("Hide stats  ▴"))
 # The graphs open straight away; the button hides them.
 toggle.pressed.emit()
 var pending = campaign.pending_heroes().size()
 if campaign.state.get("run_over", false) and not exhibition and report.get("dungeon", false):
  label(box, "OUT OF LIVES · THE RUN IS OVER", 30, Color("ff8a7a"))
  var place = Dungeon.rank_of(campaign)
  label(box, "%s fell in %s after %d fights. Final score: %d%s." % [campaign.state.name, Dungeon.depth(campaign).name, int(campaign.state.dungeon.fights), int(campaign.state.dungeon.get("final_score", 0)), (" · #%d on your high scores" % place) if place > 0 else ""], 17, MUTED)
  var dend = panel(Rect2(400,792,800,85))
  button(dend, "See the guild's final record  →", func(): phase = "runover"; render(), true)
  return
 if campaign.state.get("run_over", false) and not exhibition:
  var over = label(box, "KNOCKED OUT · THE RUN IS OVER", 30, Color("ff8a7a"))
  label(box, "%s runs must finish %s or better. Your guild finished %s." % [campaign.state.difficulty, TournamentRewardsUI._place_text(int(report.get("cutoff", 4))), TournamentRewardsUI._place_text(int(report.get("place", 0)))], 17, MUTED)
  var end = panel(Rect2(400,792,800,85))
  button(end, "See the guild's final record  →", func(): phase = "runover"; render(), true)
  return
 var footer = HBoxContainer.new(); ui.add_child(footer); footer.position = Vector2(560, 800); footer.size = Vector2(480, 62); footer.alignment = BoxContainer.ALIGNMENT_CENTER
 FlowUI.cta(self, footer, "Menu  ▶" if exhibition else "Map  ▶" if Dungeon.active(campaign) else "Bracket  ▶" if campaign.state.has("tour") else ("Level ups (%d)  ▶" % pending) if pending else "Continue  ▶", func():
  if exhibition: quit_to_menu()
  elif campaign.state.has("tour"): show_bracket_then_shop()
  else:
   phase = "upgrade" if pending else "hub"; tab = "overview"; render(), false, 480)

## After a tour match: replay the bracket, then (if the cup just ended) the progress screen, then shop.
func show_bracket_then_shop() -> void:
 if Dungeon.active(campaign):
  if campaign.state.get("run_over", false): phase = "runover"; render(); return
  phase = "upgrade" if not campaign.pending_heroes().is_empty() else "hub"; tab = "overview"; render()
  if campaign.state.tour.get("intermission", false) and phase == "hub": FlowUI.banner(self, "WARDEN DEFEATED", Color("ffd36e"), "Recruit on the stairs, then descend")
  return
 var to_shop = func():
  if campaign.state.get("run_over", false): phase = "runover"; render(); return
  if not campaign.pending_heroes().is_empty(): phase = "upgrade"; render(); return
  phase = "shop" if campaign.state.get("tour",{}).get("shop",false) else "hub"; tab = "overview"; render()
  if phase == "shop": FlowUI.banner(self, "SHOP", Color("c8ff9d"))
 var cup_over = campaign.state.tour.get("bracket",{}).get("finished",false)
 campaign.state.tour.board_seen = int(campaign.state.tour.get("serial", 0))
 var next_text = "Keep team  ▶" if campaign.state.tour.get("intermission", false) else "Shop  ▶"
 var after = (func(): render(); TournamentRewardsUI.open_screen(self, "progress", to_shop, next_text)) if cup_over else to_shop
 render()
 TournamentRewardsUI.open_screen(self, "bracket", after, "Cup results  ▶" if cup_over else "Shop  ▶", true)

## Arena Impact Score for every creature in the match, with the MVP called out.
func impact_board(box: Node, report: Dictionary) -> void:
 var rows: Array = report.ais
 var mvp = rows[0]
 for r in rows:
  if r.ais > mvp.ais: mvp = r
 label(box, "★ MVP  %s  ·  %d impact" % [mvp.name, mvp.ais], 20, GOLD).tooltip_text = "%s · Arena Impact Score" % HeroData.species[mvp.sp].n
 for team in [0, 1]:
  var line = HBoxContainer.new(); line.add_theme_constant_override("separation", 14); box.add_child(line)
  label(line, "YOU" if team == 0 else "RIVAL", 14, Color("86dbf2") if team == 0 else Color("ffa093"), false).custom_minimum_size.x = 60
  var team_rows = rows.filter(func(r): return r.team == team)
  team_rows.sort_custom(func(a, b): return a.ais > b.ais)
  for r in team_rows:
   var tile = VBoxContainer.new(); tile.custom_minimum_size.x = 250; line.add_child(tile)
   var top = HBoxContainer.new(); tile.add_child(top)
   var pic = SplashArt.make(top, r.sp, Vector2(48, 48))
   var words = VBoxContainer.new(); top.add_child(words)
   label(words, ("★ " if r == mvp else "") + r.name, 15, GOLD if r == mvp else WHITE, false)
   label(words, "%d AIS  ·  %d power" % [r.ais, int(r.get("power", r.ovr))], 15, Color("8fe08a") if r.ais >= 65 else Color("ff9a8a") if r.ais < 40 else MUTED, false)

func build_upgrade() -> void:
 var pending = campaign.pending_heroes()
 if pending.is_empty(): phase = "shop" if campaign.state.get("tour",{}).get("shop",false) else "hub"; tab = "overview"; render(); return
 var h = pending[0]
 var box = panel(Rect2(65, 130, 1470, 740))
 box.add_theme_constant_override("separation",10)
 var identity = HBoxContainer.new(); identity.add_theme_constant_override("separation", 24); box.add_child(identity)
 var portrait = SplashArt.make(identity, h.sp, Vector2(92, 116)); portrait.name = "UpgradeHeroPortrait"
 var details = VBoxContainer.new(); details.add_theme_constant_override("separation",4); details.size_flags_horizontal = Control.SIZE_EXPAND_FILL; identity.add_child(details)
 label(details, "ARENA LEVEL UP  ·  ONE HERO, ONE CHOICE", 14, GOLD)
 var reward_level = h.rewards[0].level if not h.get("rewards", []).is_empty() else h.level
 label(details, "%s · Level %d" % [h.name, reward_level], 28)
 label(details, "%s  /  %s  /  %s build" % [HeroData.species[h.sp].n, HeroData.species[h.sp].role,SkillScaling.audited(h.sp,"signature").get("build_path","ap").to_upper()], 20, GOLD)
 label(details, "Choose an evolution to define this hero’s build. Evolving also unlocks a 4th item slot." if h.pending[0][0].type == "evolution" else "APEX · the second evolution. Pick one permanent upgrade." if h.pending[0][0].type == "apex" else "%d / %d abilities · Discover your kit, then rank up your chosen abilities." % [h.learned.size()+1, HeroData.ABILITY_SLOTS], 18, MUTED)
 var row = HBoxContainer.new(); box.add_child(row)
 for index in range(h.pending[0].size()):
  var card = h.pending[0][index]
  var shell = PanelContainer.new(); shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL; shell.custom_minimum_size = Vector2(405, 510); row.add_child(shell)
  shell.add_theme_stylebox_override("panel", style(Color("1c3440"), HeroData.evolution_color({"evolution":card.key}) if card.type == "evolution" else RarityStyle.color(card.rarity), 12, 17, 2))
  var content = VBoxContainer.new(); content.add_theme_constant_override("separation",8); shell.add_child(content)
  label(content, "LEVEL %d · EVOLUTION" % HeroData.EVOLVE_LEVEL if card.type == "evolution" else "LEVEL %d · APEX EVOLUTION" % HeroData.APEX_LEVEL if card.type == "apex" else card.rarity.to_upper() + ("  ·  NEW ABILITY" if card.type == "ability" and not h.learned.has(card.key) else "  ·  EVOLUTION" if card.type == "evolution" else "  ·  RANK UP" if card.type in ["ability", "signature"] else "  ·  MASTERY"), 12, GOLD)
  var art = TextureRect.new(); art.name = "AbilityCardArt"; art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS; art.texture = AbilityArt.texture(AbilityArt.card_key(h,card)); art.custom_minimum_size = Vector2(0,244); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; content.add_child(art)
  RarityStyle.decorate(art,card.rarity)
  if card.get("rarity","") == "Legendary":
   # A legendary drop is an event: the card lands with a golden flash and a banner.
   var banner = label(content, "— LEGENDARY DROP —", 20, Color("ffd77a")); banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   shell.pivot_offset = Vector2(202, 255); shell.scale = Vector2(0.86, 0.86); shell.modulate = Color(2.2, 1.8, 1.0)
   var tw = create_tween().set_parallel(true)
   tw.tween_property(shell, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
   tw.tween_property(shell, "modulate", Color.WHITE, 0.9)
   var pulse = create_tween().set_loops(); pulse.tween_property(banner, "modulate:a", 0.55, 0.7); pulse.tween_property(banner, "modulate:a", 1.0, 0.7)
   pulse.bind_node(banner)
   sound.cue("upgrade", true)
  label(content, card.name, 23)
  var full_text = FlowUI.detailed(self)
  var description = label(content, card.description if full_text else card.get("summary", card.description), 15 if full_text else 17, WHITE)
  if not full_text: description.max_lines_visible = 3; description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
  description.tooltip_text = card.description; description.mouse_filter = Control.MOUSE_FILTER_STOP
  if card.get("upgrade", false): label(content, "▲ UPGRADES A SKILL YOU OWN", 12, Color("6fe08a"))
  if not full_text:
   var more = label(content, "Hover for full details", 11, MUTED); more.tooltip_text = card.description; more.mouse_filter = Control.MOUSE_FILTER_STOP
  var spacer = Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL; content.add_child(spacer)
  if card.type != "apex":
   button(content,"Preview in arena",func():
    var demo=AbilityPreview.new();demo.game=self;demo.hero=h.duplicate(true);demo.card=card.duplicate(true);ui.add_child(demo);demo.build())
  button(content, "Choose evolution" if card.type == "evolution" else "Choose apex" if card.type == "apex" else "Learn ability" if card.type == "ability" and not h.learned.has(card.key) else "Choose upgrade", func():
   var newly_learned=card.type=="ability" and not h.learned.has(card.key)
   var before_choice=h.duplicate(true)
   if campaign.choose(h.id, index):
    sound.cue("upgrade", true);render()
    if newly_learned:
     var demo=AbilityPreview.new();demo.game=self;demo.hero=before_choice;demo.card=card.duplicate(true);demo.unlocked=true;ui.add_child(demo);demo.build()
   else: toast(campaign.last_error), true)
 label(box, "%d heroes awaiting their own choice. Wins slightly improve rarity." % pending.size(), 15, MUTED)

func show_guide() -> void:
 var dialog = AcceptDialog.new(); ui.add_child(dialog); dialog.title = "Your first match · three steps"
 dialog.dialog_text = "1. DRAFT YOUR SQUAD\nSign a Legendary headliner (×3 cost), then build from the draft board: Epics cost ×2, Commons ×1. An elite four (2 Epics + 1 Common) gets the elite-squad bonus; a full five (1 Epic + 3 Commons) brings numbers.\n\n2. ARRANGE & SET TACTICS\nRoster → Arrange formation → drag your five into position.\nHero tactics → choose an approach and target priority.\n\n3. COMPETE, THEN DEVELOP\nEnter the arena. Fielded heroes earn XP; level-ups offer individual abilities.\n\nEach cup is a double-elimination bracket: lose twice and you're out. Every cup moves you on to the next; finish 1st, 2nd or 3rd for a Gold, Silver or Bronze chest.\n\n4. FORGE ITEMS\nBuy components at the outfitter after every match. Each champion carries 3 items (4 after its first evolution at level 8, 5 with the Apex Arsenal at level 16); drop a second component on a champion holding one to forge a finished item (see the Recipe book). Trickster's Coin forges WILD items that change how a champion fights.\n\n5. TEMPERAMENT & SCALING\nEvery champion has a temperament (a strength and a weakness) and a scaling curve: early scalers dominate the first cups, late scalers start weak and take over. Gold text marks a champion's perfect role and ideal temperaments. Club → Settings changes difficulty."
 dialog.popup_centered(Vector2i(650, 420))

func toggle_music() -> void:
 sound.set_music(not sound.music_enabled)
 if not exhibition and not campaign.state.is_empty(): campaign.state.music = sound.music_enabled; campaign.save()
 render()

func toggle_effects() -> void:
 sound.effects_enabled = not sound.effects_enabled
 if not exhibition and not campaign.state.is_empty(): campaign.state.effects = sound.effects_enabled; campaign.save()
 render()

func quit_to_menu() -> void:
 if is_instance_valid(speedrun_lab) and speedrun_lab.running:speedrun_lab.cancelled=true
 if exhibition:
  exhibition = false; campaign = Campaign.new(); phase = "menu"; paused = false; render(); return
 if not campaign.save(): toast(campaign.last_error); return
 var was_battle = phase == "battle"
 phase = "menu"; paused = false; sound.scene_music(music_now()); render()
 if was_battle: toast("Campaign saved. The unfinished bout restarts from preparation.")

func toast(text_value: String) -> void:
 if is_instance_valid(toast_label):
  toast_label.text = text_value; toast_label.modulate.a = 1.0
  var t = create_tween(); t.tween_interval(4.0); t.tween_property(toast_label, "modulate:a", 0.0, 0.6)

func _process(dt: float) -> void:
 if phase == "battle" and sim and not resolving and countdown > 0.0:
  # 3 · 2 · 1 · FIGHT! The camera sweeps in while both teams wait on their marks.
  countdown = maxf(0.0, countdown - dt)
  var k = 1.0 - countdown / COUNTDOWN
  arena.target_yaw = lerpf(0.55, 0.0, smoothstep(0.0, 0.8, k))
  arena.target_distance = (31.0 if tactical else 34.0) + 6.0 * (1.0 - smoothstep(0.0, 0.8, k))
  arena.sync(sim, dt, 0.0)
  update_countdown()
  return
 if phase == "battle" and sim and not resolving:
  var dilation = 1.0
  if legend_left > 0.0 and not paused:
   legend_left = maxf(0.0, legend_left - dt)
   var k = 1.0 - legend_left / legend_total
   dilation = 0.3 + 0.7 * k * k
  if freeze_left > 0.0 and not paused:
   freeze_left = maxf(0.0, freeze_left - dt); dilation *= 0.06
  dilation *= TEMPO
  if not paused:
   accumulator += minf(dt, 0.1) * speed * dilation
   while accumulator >= 1.0 / 30.0 and not sim.finished:
    sim.step(1.0 / 30.0); accumulator -= 1.0 / 30.0
  arena.sync(sim, dt, 0.0 if paused else speed * dilation)
  if is_instance_valid(match_label): match_label.text = "%d   —   %d      %02d:%02d%s" % [sim.living(0, false).size(), sim.living(1, false).size(), int(sim.time) / 60, int(sim.time) % 60, "  PAUSED" if paused else ""]
  if is_instance_valid(match_label) and sim.time>=CombatPacing.OVERTIME_START:
   match_label.text+=" · OVERTIME"
   match_label.tooltip_text="Healing and new shields reduced by %d%%"%roundi((1.0-CombatPacing.sustain_factor(sim.time))*100)
  if sim.finished: call_deferred("finish_battle")
 elif phase == "battle" and sim and resolving:
  # Fight over: the survivors keep breathing while the results are tallied.
  arena.sync(sim, dt, 1.0); poll_resolve(dt)
 elif sim and phase in ["menu", "new", "hub", "prep"]: arena.sync(sim, dt)
 if not qa.is_empty() and not qa_taken:
  qa_elapsed += dt
  if has_meta("qa_tab") and qa_elapsed > 0.5 and not has_meta("qa_tab_done"):
   set_meta("qa_tab_done", true); tab = str(get_meta("qa_tab")); render()
  if has_meta("qa_mouse") and qa_elapsed > 1.0 and not has_meta("qa_mouse_done"):
   set_meta("qa_mouse_done", true)
   var mm = InputEventMouseMotion.new(); mm.position = get_viewport().get_final_transform() * get_meta("qa_mouse"); mm.global_position = mm.position; get_viewport().push_input(mm)
  if qa_elapsed > (12 if qa in ["arena", "evolved_arena", "exhibition", "tour_arena", "dungeon_boss"] else 7 if qa in ["intro","chest"] else 4 if qa in ["guild_demo","draft_demo","builds_demo","tree_demo","evolution","levelup","tour_intro"] else 1.65 if qa in ["attacks_slam","attacks_weapon"] else 1.43 if qa.begins_with("attacks_") else 2 if qa.begins_with("particles_") else 3):
   qa_taken = true
   await RenderingServer.frame_post_draw
   if not qa_capture.is_empty():
    var image = get_viewport().get_texture().get_image(); image.save_png(qa_capture)
    print("CAPTURED ", qa_capture, " FPS ", Engine.get_frames_per_second(), " AUDIO_CUES ", sound.played_cues)
   close_game()

func close_game() -> void:
 sound.stop_all()
 await get_tree().create_timer(0.3).timeout
 get_tree().quit()

func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_CLOSE_REQUEST:
  if not exhibition and not campaign.state.is_empty() and qa.is_empty() and not campaign.save(): toast(campaign.last_error); return
  close_game()

func _input(event: InputEvent) -> void:
 if resolve_thread != null: get_viewport().set_input_as_handled(); return   # results are being written; ignore input for that moment
 if event is InputEventMouseMotion and not dragged_id.is_empty() and phase == "prep":
  var point = arena.ground_position(event.position)
  point.x += drag_offset.x; point.z += drag_offset.y
  for u in sim.units:
   if u.hero.id == dragged_id: u.pos = Vector2(clampf(point.x, ArenaGrid.FORMATION_COLUMNS[0], ArenaGrid.FORMATION_COLUMNS[2]), clampf(point.z, -ArenaGrid.BOUNDS.y, ArenaGrid.BOUNDS.y))
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and not dragged_id.is_empty():
  var point = arena.ground_position(event.position)
  point.x += drag_offset.x; point.z += drag_offset.y
  var slot = ArenaGrid.nearest_formation_slot(Vector2(point.x, point.z))
  var id = dragged_id; dragged_id = ""; place_hero(id, slot)

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and phase != "hub":
  if event.button_index == MOUSE_BUTTON_RIGHT: orbiting = event.pressed
  if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP: arena.zoom(-1.8)
  if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN: arena.zoom(1.8)
  if phase == "prep" and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
   var pos = arena.ground_position(event.position)
   var best = 1.0
   for u in sim.units:
    var center = arena.camera.unproject_position(ArenaView.world_point(u.pos, 1.15))
    var feet = arena.camera.unproject_position(ArenaView.world_point(u.pos, 0))
    var radius = maxf(18.0, center.distance_to(feet) * 1.3)
    var distance = event.position.distance_to(center) / radius
    if u.team == 0 and distance < best:
     dragged_id = u.hero.id; best = distance; drag_offset = u.pos - Vector2(pos.x, pos.z)
   if event.double_click and not dragged_id.is_empty():
    selected_id = dragged_id; dragged_id = ""; show_tactics(selected_id)
 if event is InputEventMouseMotion and orbiting: arena.orbit(-event.relative.x * 0.005)
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_F11: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
  if event.keycode == KEY_SPACE and phase == "battle": paused = not paused; render()
  if event.keycode == KEY_ENTER and phase=="intro":
   var introduction=ui.find_children("*","ContestantIntro",true,false)
   if not introduction.is_empty():introduction[0].launch()
  if event.keycode == KEY_ESCAPE:
   if phase=="intro":phase="prep";render()
   elif phase=="starter":quit_to_menu()
   elif phase == "battle": paused = not paused; render()
   elif exhibition: quit_to_menu()
   elif phase not in ["menu", "new"]: phase = "hub"; tab = "overview"; render()
  if phase == "battle" and event.keycode in [KEY_1, KEY_2, KEY_4]: set_tactical(false); speed = {KEY_1: 1.0, KEY_2: 2.0, KEY_4: 4.0}[event.keycode]; render()
  if phase == "battle" and event.keycode == KEY_T: set_tactical(not tactical)

# Tactical view slows the fight to 0.75x and turns on the clarity overlay: stronger skill
# footprints, who-is-attacking-whom lines, status tags and fewer small numbers.
func set_tactical(on: bool) -> void:
 tactical = on
 if arena and arena.clarity: arena.clarity.tactical = on
 if on:
  speed = 0.75
  if arena and arena.target_distance > 31: arena.target_distance = 31
 elif speed < 1.0: speed = 1.0
 render()

func show_tactics(id: String) -> void:
 if phase == "battle": return
 var hero = campaign.hero_by_id(id)
 if hero.is_empty(): return
 var editor = TacticsMenu.new(); editor.game = self; editor.hero_id = id; ui.add_child(editor)

func show_opponent_scout() -> void:
 ScoutUI.open(self, campaign.opponent())

func start_exhibition() -> void:
 exhibition = true; campaign = Campaign.new(); campaign.new_run("The Dawn Champions",99,7913); League.run_tiers = {}; campaign.state.tiers = {}; campaign.create_market()
 campaign.state.roster = []; exhibition_rivals = []
 for team in range(2):
  for i in range(5):
   var sp = ["golem","minotaur","direwolf","kirin","unicorn"][i] if team == 0 else ["yeti","owlbear","griffin","phoenix","naga"][i]
   var h = HeroData.make_hero(sp,"show_%d_%d" % [team,i],HeroData.themed_name(sp,"show_%d_%d" % [team,i]),10)
   h.slot = Campaign.FORMATION[i]; h.learned = {"0":2,"1":2,"2":2}; h.signature_rank = 2
   h.evolution = ["guardian","ravager","ravager","arcanist","guardian"][i]
   if team == 0: campaign.state.roster.append(h)
   else: exhibition_rivals.append(h)
 selected_id = campaign.state.roster[0].id; begin_battle()
