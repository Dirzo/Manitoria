class_name ManagementDesk
extends Control
## Native club management. Every action works on the campaign used by the arena.

var game: Node
var campaign: Campaign
var state: Dictionary
var prefs: Dictionary
var body: VBoxContainer
const GOLD = Color("e3c589")
const WHITE = Color("eef0e8")
const MUTED = Color("9aafb9")
const TEAL = Color("82c7bc")

func build() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 campaign = game.campaign; state = campaign.state; prefs = game.desk_state
 var nav = HBoxContainer.new(); add_child(nav); nav.position = Vector2(26, 122); nav.size = Vector2(1548, 48)
 for item in [["overview", "Overview"], ["matches", "Matches"], ["roster", "Roster"], ["club", "Club"], ["market", "Market"], ["intel", "Intel"]]:
  var b = action(nav, ("World Tour" if item[0]=="overview" else "Journal" if item[0]=="matches" else "League" if item[0]=="intel" else item[1]) if state.has("tour") else item[1], func(): navigate(item[0]), game.tab == item[0]); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var scroll = ScrollContainer.new(); add_child(scroll); scroll.position = Vector2(26, 184); scroll.size = Vector2(1548, 618)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 body = VBoxContainer.new(); body.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation", 18); scroll.add_child(body)
 match game.tab:
  "market": market()
  "roster": roster()
  "matches": matches_page()
  "club": club_page()
  "intel", "league": intel()
  _: overview()
 var dock = FantasyFrame.new(); add_child(dock); dock.position = Vector2(26, 827); dock.size = Vector2(1548, 61)
 dock.add_theme_stylebox_override("panel", game.style(Color(.055,.10,.12,.97),Color("aa8c60"),4,8,2))
 var row = horizontal(dock)
 var help = action(row, "?", game.show_guide); help.tooltip_text = "Keeper's guide"; help.custom_minimum_size.x = 48
 var spacer = Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(spacer)
 var next = "Draft squad  ▶" if state.roster.size() < Campaign.MIN_SQUAD else "Fight  ▶"
 if state.get("tour",{}).get("shop",false): next = "Shop  ▶"
 if state.get("tour",{}).get("intermission",false): next = "Start next cup  ▶"
 if state.get("tour",{}).get("complete",false): next = "Tour complete"
 if not campaign.pending_heroes().is_empty(): next = "Level ups  ▶"
 elif not state.has("tour") and state.round >= 17: next = "Next season  ▶"
 if state.roster.size() < Campaign.MIN_SQUAD and game.tab != "market":
  # Point at the draft board rather than a match the player can't play yet.
  FlowUI.cta(game, row, next, func(): navigate("market"))
  return
 if state.roster.size() < Campaign.MIN_SQUAD: next = "Sign %d more" % (Campaign.MIN_SQUAD - state.roster.size())
 FlowUI.cta(game, row, next, func():
  if not state.has("tour") and state.round >= 17 and campaign.pending_heroes().is_empty(): campaign.new_season(); game.render()
  elif state.get("tour",{}).get("shop",false) or not campaign.pending_heroes().is_empty() or not campaign.lineup_ready(): game.prepare_match()
  else: game.introduce_match(), state.roster.size() < Campaign.MIN_SQUAD or state.get("tour",{}).get("complete",false))

func navigate(tab: String) -> void:
 game.tab = tab; game.render()

func text(parent: Node, value: String, size: int = 18, color: Color = WHITE) -> Label:
 return game.label(parent, value, size, color, not (parent is HBoxContainer or parent is GridContainer))

func action(parent: Node, title: String, callback: Callable, primary: bool = false, disabled: bool = false) -> Button:
 var b = game.button(parent, title, callback, primary, disabled)
 b.add_theme_font_size_override("font_size", 16)
 return b

func horizontal(parent: Node) -> HBoxContainer:
 var row = HBoxContainer.new(); parent.add_child(row); row.add_theme_constant_override("separation", 16); return row

func column(parent: Node, expand: bool = true) -> VBoxContainer:
 var col = VBoxContainer.new(); parent.add_child(col); col.add_theme_constant_override("separation", 9)
 if expand: col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 return col

func card(parent: Node) -> VBoxContainer:
 var panel = FantasyFrame.new(); panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; parent.add_child(panel)
 panel.add_theme_stylebox_override("panel", game.style(Color(.045,.095,.115,.97),Color("aa8c60"),5,18,2))
 return column(panel)

func heading(title: String, subtitle: String) -> void:
 text(body, title, 32)
 text(body, subtitle, 17, MUTED)

func portrait(parent: Node, sp: String, height: int = 120) -> Control:
 # Element splash art, cover-cropped around the creature's head.
 return SplashArt.make(parent, sp, Vector2(0, height), true)

func team_power(heroes: Array, quality: float = 1.0) -> int:
 var total = 0
 for h in heroes: total += HeroData.power(h)
 return roundi(total * quality)

func team_strip(parent: Node, heroes: Array, yours: bool) -> void:
 var row = horizontal(parent)
 for i in range(5):
  var c = column(row); c.size_flags_stretch_ratio = 1
  if i < heroes.size():
   var h = heroes[i]; portrait(c, h.sp, 120)
   var l = text(c, h.name, 16, WHITE); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   var b = action(c, "Lv %d · %s" % [h.level, HeroData.line(h.sp)], func(): profile(h, yours)); b.custom_minimum_size.y = 32; b.add_theme_font_size_override("font_size", 12)
  else:
   var empty = text(c, "+", 42, MUTED); empty.custom_minimum_size.y = 96; empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
   action(c, "Recruit", func(): navigate("market"))

func next_fixture() -> void:
 var fixture = card(body)
 if state.round >= 17:
  text(fixture, "SEASON %d COMPLETE" % state.season, 14, GOLD)
  text(fixture, campaign.standings()[0].name + " take the crown.", 34)
  text(fixture, "Your club finished with %d league wins, %d draws and %d losses. Your heroes, equipment and learned abilities carry into the next season." % [state.league_wins, state.league_draws, state.league_losses], 21, MUTED)
  action(fixture, "Review the final league table", func(): prefs.intel = "Standings"; navigate("intel"))
  return
 var top = horizontal(fixture)
 var title = text(top, "THE NEXT FIXTURE" if state.round < 17 else "SEASON COMPLETE", 13, GOLD); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 text(top, game.stage_label() + "  /  5v5", 13, MUTED)
 var sides = horizontal(fixture)
 var home = column(sides); home.size_flags_stretch_ratio = 5
 text(home, state.name, 29)
 text(home, "%d W  ·  %d L  ·  %d D     /     POWER %d" % [state.wins, state.losses, state.draws, team_power(campaign.lineup())], 15, TEAL)
 team_strip(home, campaign.lineup(), true)
 var middle = column(sides); middle.custom_minimum_size.x = 160; middle.size_flags_stretch_ratio = 1
 var cup = TextureRect.new(); middle.add_child(cup); cup.texture = load("res://assets/league-cup.svg"); cup.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; cup.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; cup.custom_minimum_size = Vector2(0, 100)
 var vs = text(middle, "MANITORIA\nLEAGUE", 17, GOLD); vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var meta = text(middle, "110g victory\n70g defeat", 14, MUTED); meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var away = column(sides); away.size_flags_stretch_ratio = 5
 var rival = campaign.opponent()
 text(away, rival.name, 29)
 var their_power = team_power(rival.roster, campaign.quality())
 var ours = team_power(campaign.lineup())
 text(away, "%s     /     POWER %d" % ["DANGEROUS" if their_power > ours * 1.15 else "COMPETITIVE", their_power], 15, Color("dbaa83"))
 team_strip(away, rival.roster, false)

func overview() -> void:
 if state.has("tour"): tour_overview(); return
 var join = card(body)
 text(join,"Begin the World Tour with this club",24)
 text(join,"Keep your heroes, equipment, gold and reports. Start team level 1 in a new tournament circuit.",17,MUTED)
 action(join,"Enter World Tour",func(): WorldTour.start(campaign); campaign.save(); game.render(),true)
 next_fixture()
 var row = horizontal(body)
 var agenda = card(row); text(agenda, "CLUB AGENDA", 14, GOLD)
 if state.roster.size() < Campaign.MIN_SQUAD:
  text(agenda, "Draft your founding squad", 25)
  text(agenda, "%d signed. Field 4 or 5: a headliner with two Epics makes an elite four; one Epic and three Commons makes a full five." % state.roster.size(), 17, MUTED)
  action(agenda, "Open recruitment", func(): navigate("market"), true)
 elif campaign.lineup().size() < Campaign.MIN_SQUAD:
  text(agenda, "Your formation needs %d more heroes" % (Campaign.MIN_SQUAD - campaign.lineup().size()), 24)
  action(agenda, "Choose your starting five", func(): navigate("roster"), true)
 elif not campaign.pending_heroes().is_empty():
  text(agenda, "%d heroes have earned an upgrade" % campaign.pending_heroes().size(), 24)
  action(agenda, "Choose their abilities", func(): game.phase = "upgrade"; game.render(), true)
 else:
  text(agenda, "Your five are ready", 25)
  text(agenda, "Scout the opposition, set your formation, then let your heroes fight. Only fielded heroes earn XP.", 17, MUTED)
  action(agenda, "Review roster & formation", func(): navigate("roster"))
 text(agenda, "Armory opens after 300 arena gold  ·  %d / 300" % mini(300, state.earned_gold) if state.earned_gold < 300 else "Armory unlocked · equip your heroes in Club", 15, GOLD)
 var board = card(row); text(board, "AROUND THE LEAGUE  /  IMPACT PER BOUT", 14, GOLD)
 var leaders = campaign.season_leaders()
 if leaders.is_empty():
  text(board, "The next legends are unwritten.", 25)
  text(board, "Rankings begin with league matches after three proving bouts. Rival fixtures are simulated alongside yours.", 17, MUTED)
 for i in range(mini(3, leaders.size())):
  var h = leaders[i]
  text(board, "%02d   %s     %.1f IMP" % [i + 1, h.hero.name, h.score], 22, GOLD if h.club == state.name else WHITE)
  text(board, "%s · %d bouts" % [h.club, h.bouts], 14, MUTED)
 action(board, "Explore league intel  →", func(): navigate("intel"))
 var lower = horizontal(body)
 var feed = card(lower); text(feed, "CLUB FEED", 14, GOLD)
 for item in state.news.slice(0, 4):
  text(feed, item.title, 20)
  text(feed, item.detail, 15, MUTED)
 var objectives = card(lower); text(objectives, "SEASON OBJECTIVES", 14, GOLD)
 progress(objectives, "Sign your founding five", state.roster.size(), 5)
 progress(objectives, "Compete in your first arena match", state.wins + state.losses + state.draws, 1)
 progress(objectives, "Win four league matches", state.get("league_wins", 0), 4)

func progress(parent: Node, title: String, value: int, target: int) -> void:
 text(parent, "%s    %d / %d" % [title, mini(value, target), target], 17, TEAL if value >= target else WHITE)
 var bar = ProgressBar.new(); parent.add_child(bar); bar.max_value = target; bar.value = value; bar.show_percentage = false; bar.custom_minimum_size.y = 6
 bar.add_theme_stylebox_override("background", game.style(Color("263c46"), Color.TRANSPARENT, 3, 0, 0))
 bar.add_theme_stylebox_override("fill", game.style(TEAL, Color.TRANSPARENT, 3, 0, 0))

func filters(parent: Node, key: String, values: Array) -> void:
 var row = horizontal(parent)
 for value in values:
  action(row, value.capitalize(), func(): prefs[key] = value; game.render(), prefs[key] == value)

func market() -> void:
 text(body, "DRAFT BOARD", 32)
 var open_slots = maxi(0, Campaign.MAX_SQUAD - campaign.lineup().size())
 var counts = {"Front": 0, "Flank": 0, "Back": 0}
 for h in campaign.lineup(): counts[HeroData.line(h.sp)] += 1
 var info = horizontal(card(body))
 var slots_label = text(info, "%d open slot%s  ·  %d front · %d flank · %d back  ·  %d/12 signed  ·  drafted champions leave the board; a fresh board arrives after each cup" % [open_slots, "" if open_slots == 1 else "s", counts.Front, counts.Flank, counts.Back, state.roster.size()], 17, GOLD)
 slots_label.mouse_filter = Control.MOUSE_FILTER_STOP
 slots_label.tooltip_text = "Common %dg · Epic %dg · Legendary %dg\nAfter your headliner, %dg buys an elite four (2 Epics + 1 Common, elite-squad bonus) or a full five (1 Epic + 3 Commons)." % [League.COST_UNIT, League.COST_UNIT * 2, League.COST_UNIT * 3, League.START_GOLD - League.COST_UNIT * 3]
 var bars = horizontal(body)
 filters(bars, "role", ["All", "Front", "Flank", "Back"])
 var gap = Control.new(); gap.custom_minimum_size.x = 30; bars.add_child(gap)
 DraftBoard.view_bar(game, bars)
 var sort = prefs.get("sort", "Board")
 var pool = state.market.filter(func(h): return prefs.role == "All" or HeroData.line(h.sp) == prefs.role)
 if pool.is_empty(): text(body, "No creatures in this role. Choose another filter.", 20, MUTED); return
 var opts = func(h):
  return {"on_scout": func(): game.sound.announce(h.sp); profile(h, false),
   "draft_text": "Draft · %d gold" % h.price if DraftBoard.view(game) == "Grid" else "%d gold" % h.price,
   "on_draft": func(): draft_with_check(h),
   "draft_disabled": state.gold < h.price or state.roster.size() >= 12 or state.roster.is_empty()}
 # Once the headliner and an Epic are signed (or Epics are out of reach), Commons lead the board.
 var has_epic = state.roster.any(func(h): return League.tier(h.sp) == "Epic")
 var tier_order = ["Common", "Epic"] if not state.roster.is_empty() and (has_epic or state.gold < League.COST_UNIT * 2) else ["Epic", "Common"]
 if DraftBoard.view(game) == "Table":
  var ordered = []
  for t in tier_order: ordered.append_array(pool.filter(func(h): return League.tier(h.sp) == t))
  DraftBoard.table(game, body, TraitUI.sorted(ordered, sort), opts)
  return
 for t in tier_order:
  var heroes = TraitUI.sorted(pool.filter(func(h): return League.tier(h.sp) == t), sort)
  if heroes.is_empty(): continue
  var prices = heroes.map(func(x): return int(x.price))
  var price_text = "%d gold" % prices.min() if prices.min() == prices.max() else "%d–%d gold · priced by rolls & level" % [prices.min(), prices.max()]
  text(body, "%s  ·  %s" % [t.to_upper(), price_text], 22, Color(League.TIER_COLOR[t]))
  DraftBoard.grid(game, body, heroes, opts, 4, 372, 220)

## Warn when a pick would leave too little gold to field a full five.
func draft_with_check(h: Dictionary) -> void:
 var go = func():
  if campaign.recruit(h.id):
   game.selected_id = h.id; game.sound.cue("upgrade", true)
   game.render()
   game.toast("%s joined your roster and left the draft board · %d gold left" % [h.name, int(state.gold)])
  else: game.toast(campaign.last_error if not campaign.last_error.is_empty() else "Not enough gold or your roster is full.")
 var starters = campaign.lineup().size() + 1
 var left = int(state.gold) - int(h.price)
 var more = left / League.COST_UNIT
 var can_field = mini(Campaign.MAX_SQUAD, starters + more)
 if starters < Campaign.MAX_SQUAD and can_field < Campaign.MAX_SQUAD:
  FlowUI.confirm(game, "Short-handed warning", "After drafting %s you'll have %d gold left, which buys %d more Common.\n\nYou could only field %d of 5 starters. A four-creature squad gets the elite bonus, but you'll be outnumbered." % [h.name, left, more, can_field], "Draft anyway", go, "Keep shopping")
 else: go.call()

func roster() -> void:
 ChampionWardrobe.build(self)

func roster_card(parent: Node, h: Dictionary) -> void:
 var box = card(parent); box.get_parent().custom_minimum_size.x = 270
 portrait(box, h.sp, 210)
 if not h.get("evolution", "").is_empty(): text(box,HeroData.evolution_info(h).name.to_upper(),12,HeroData.evolution_color(h))
 text(box, h.name, 23); text(box, HeroData.species[h.sp].n + " · " + HeroData.line(h.sp), 14, MUTED)
 text(box,"%d / 4 abilities · %s" % [h.learned.size()+1,"Evolved" if not h.get("evolution", "").is_empty() else "Evolution at Lv 10"],12,GOLD)
 progress(box, "Level %d" % h.level, h.xp, HeroData.xp_needed(h.level))
 action(box, "Inspect hero", func(): profile(h, true))
 if h.slot >= 0: action(box, "Bench", func(): campaign.bench(h.id); game.render())
 else: action(box, "Field / replace", func(): field_hero(h), true)

func overlay(title: String) -> Dictionary:
 var shade = ColorRect.new(); game.ui.add_child(shade); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); shade.color = Color(0.01, 0.025, 0.04, 0.94)
 var panel = FantasyFrame.new(); shade.add_child(panel); panel.position = Vector2(165, 80); panel.size = Vector2(1270, 740)
 var stack = column(panel); var top = horizontal(stack)
 var name_label = text(top, title, 30); name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 action(top, "Close ×", func(): shade.queue_free())
 var scroll = ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; stack.add_child(scroll)
 var content = column(scroll); content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 return {"root": shade, "body": content}

func profile(h: Dictionary, yours: bool) -> void:
 var dialog = overlay(h.name + "  /  " + HeroData.species[h.sp].n)
 var split = horizontal(dialog.body)
 # Three columns: who it is (left), how its stats compare (middle), what it does (right).
 var left = column(split, false); left.custom_minimum_size.x = 340
 var stage = Control.new(); stage.custom_minimum_size = Vector2(340, 220); left.add_child(stage)
 var backdrop = SplashArt.new(); backdrop.sp = h.sp; backdrop.backdrop_only = true; stage.add_child(backdrop); backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var preview = HeroPreview.new(); preview.species_id = h.sp; stage.add_child(preview); preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var poses = horizontal(left)
 for clip in ["idle", "walk", "attack", "cast"]: action(poses, clip.capitalize(), func(): preview.play(clip))
 var stats = HeroData.stats(h)
 text(left, "LEVEL %d  /  %s  /  %s" % [h.level, HeroData.species[h.sp].role.to_upper(), League.tier(h.sp).to_upper()], 16, TEAL)
 TraitUI.line(game, left, h)
 TraitUI.rolls(game, left, h, true)
 GearUI.recommended_row(game, left, h, 40)
 if h.has("ais_history"): text(left, "Arena Impact form: %d  ·  last match %d  ·  %d matches" % [roundi(League.form(h)), int(h.get("ais_last", 0)), int(h.get("ais_games", 0))], 15, GOLD)
 text(left, "%d HP  ·  %d DMG  ·  %d%% armor  ·  %.1fs per attack  ·  %.1f range" % [stats.hp, stats.attack, stats.armor * 100, stats.interval, stats.range], 14)
 text(left, "%d bouts  ·  %d kills  ·  %.1f career impact/bout" % [h.bouts, h.kills, h.impact / maxf(1, h.bouts)], 15, MUTED)
 if yours:
  action(left,"Team headliner" if h.id==state.get("headliner","") else "Make team headliner",func():
   if campaign.set_headliner(h.id):game.sound.cue("contest_lock");game.render()
   else:game.toast(campaign.last_error),false,h.id==state.get("headliner",""))
  action(left, "Battle tactics  →", func(): dialog.root.queue_free(); game.show_tactics(h.id), true)
  text(left, BattleTactics.summary(h), 15, GOLD)
  progress(left, "Arena experience", h.xp, HeroData.xp_needed(h.level))
  action(left, "Bench hero" if h.slot >= 0 else "Field / replace", func():
   if h.slot >= 0: campaign.bench(h.id); game.render()
   else: dialog.root.queue_free(); field_hero(h))
  var refund = campaign.sell_price(h)
  var sell_b = action(left, "Sell for %d gold (50%%)" % refund, func():
   FlowUI.confirm(game, "Sell " + h.name + "?", "%s leaves the guild for %d gold (half of the %d paid). Equipped items go to your bag." % [h.name, refund, int(h.get("price", League.cost(h.sp)))], "Sell for %d gold" % refund, func():
    if campaign.sell(h.id): dialog.root.queue_free(); game.sound.cue("contest_lock"); game.render(); game.toast("%s sold · +%d gold" % [h.name, refund])
    else: game.toast(campaign.last_error)), false, h.id == str(state.get("headliner", "")))
  if h.id == str(state.get("headliner", "")): sell_b.tooltip_text = "Your headliner can't be sold."
 # Middle: the stat hexagon, what each stat does, and how this champion grows.
 var mid = column(split, false); mid.custom_minimum_size.x = 440
 var hex_head = horizontal(mid)
 text(hex_head, "STATS  ·  vs every champion at level %d" % int(h.level), 13, GOLD).size_flags_horizontal = Control.SIZE_EXPAND_FILL
 text(hex_head, "outline = average rolls", 11, MUTED)
 StatHex.make(mid, h, Vector2(440, 270))
 StatHex.guide(game, mid, h)
 StatHex.scaling(game, mid, h)
 # Right: every skill on one screen, then the skill book.
 var right = column(split)
 var full_text = FlowUI.detailed(game)
 var kit_head = HBoxContainer.new(); right.add_child(kit_head)
 text(kit_head, "ABILITIES · %d / %d" % [h.learned.size()+1, HeroData.ABILITY_SLOTS], 13, GOLD).size_flags_horizontal = Control.SIZE_EXPAND_FILL
 for entry in ChampionKit.entries(h): ChampionKit.row(game, right, entry, full_text)
 if h.learned.size()+1 < HeroData.ABILITY_SLOTS:
  text(right, "%d empty slot%s · level up in the arena to learn more" % [HeroData.ABILITY_SLOTS-h.learned.size()-1, "" if HeroData.ABILITY_SLOTS-h.learned.size()-1 == 1 else "s"], 13, MUTED)
 # The full skill book: every skill this species can learn (hover for details).
 text(right, "SKILL BOOK · %d skills · hover for details" % HeroData.DISCOVERY_CHOICES, 13, GOLD)
 var book = GridContainer.new(); book.columns = 2; book.add_theme_constant_override("h_separation", 8); book.add_theme_constant_override("v_separation", 4); right.add_child(book)
 for i in range(HeroData.DISCOVERY_CHOICES):
  var sk = HeroData.learned_ability(h.sp, i); var owned = h.learned.has(str(i))
  var cell = HBoxContainer.new(); cell.custom_minimum_size.x = 186; cell.add_theme_constant_override("separation", 6); book.add_child(cell); cell.mouse_filter = Control.MOUSE_FILTER_STOP
  cell.tooltip_text = sk.name + " · " + sk.summary + "\n" + sk.description
  var ic = AbilityArt.icon(cell, "discovery:%s:%d" % [h.sp, i], 30); ic.modulate = Color.WHITE if owned else Color(0.7, 0.7, 0.75); ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
  var nm = game.label(cell, sk.name + ("  ✓" if owned else ""), 13, TEAL if owned else WHITE, false); nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
  nm.clip_text = true; nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS; nm.custom_minimum_size.x = 140
 var evolution = h.get("evolution", "")
 text(right, "EVOLUTION · " + (HeroData.evolution_info(h).name if not evolution.is_empty() else "Unlocks at level 10"), 15, GOLD)
 text(right, HeroData.evolution_info(h).description if not evolution.is_empty() else "Choose Ravager, Guardian or Arcanist to change combat strengths and visual effects.", 16, MUTED)
 text(right, "Fill four ability slots, then raise chosen abilities to Rank 2. Wins slightly improve rare-card odds.", 15, GOLD)
 if yours:
  text(right, "ITEMS · up to 3", 13, GOLD)
  if not state.has("tour") and state.earned_gold < 300: text(right, "Unlock the armory by earning 300 gold in the arena.", 16, MUTED)
  else:
   var slots=horizontal(right)
   for key in GearUI.SLOT_KEYS:GearUI.slot(game,slots,h,key,78)
   GearUI.bag(game,right,h)

 if h in state.market:
  action(left, "Recruit · %dg" % h.price, func(): campaign.recruit(h.id); game.render(), true, state.gold < h.price or state.roster.size() >= 12)

func field_hero(h: Dictionary) -> void:
 if campaign.lineup().size() < 5:
  for slot in Campaign.FORMATION:
   if not campaign.lineup().any(func(other): return other.slot == slot): campaign.place_hero(h.id, slot); game.render(); return
 var dialog = overlay("Who should %s replace?" % h.name)
 text(dialog.body, "The replaced hero moves to your reserves. You keep their progress and equipment.", 20, MUTED)
 for other in campaign.lineup(): action(dialog.body, other.name + " · " + HeroData.species[other.sp].n, func(): campaign.place_hero(h.id, other.slot); game.render())

func compare_heroes() -> void:
 var dialog = overlay("Compare your champions")
 var row = horizontal(dialog.body)
 for id in prefs.compare:
  var h = campaign.hero_by_id(id)
  if h.is_empty(): continue
  var box = card(row); portrait(box, h.sp, 190); text(box, h.name + " · " + HeroData.species[h.sp].n, 26)
  var s = HeroData.stats(h)
  text(box, "Level %d    /    %d power" % [h.level, HeroData.power(h)], 21, TEAL)
  text(box, "%d health\n%d attack\n%d%% armor\n%.2fs attack interval\n%.1f attack range\n%d learned abilities" % [s.hp, s.attack, s.armor * 100, s.interval, s.range, h.learned.size()], 21)
  text(box, HeroData.species[h.sp].ability_name, 22, GOLD)
  text(box, HeroData.species[h.sp].ability_description, 17, MUTED)

func fixture_name(round_index: int) -> String:
 if round_index < 3: return ["The Old Keepers", "The Practice Pack", "The Gate Wardens"][round_index]
 for pair in state.schedule[round_index - 3]:
  if pair.has(0): return state.clubs[int(pair[1] if pair[0] == 0 else pair[0]) - 1].name
 return ""

func matches_page() -> void:
 if state.has("tour"): tour_history(); return
 heading("The season calendar", "Three proving bouts, then fourteen league fixtures. Every main campaign match is five against five.")
 var box = card(body)
 for i in range(17):
  if state.season > 1 and i < 3: continue
  var row = horizontal(box)
  var caption = "PROVING %d" % (i + 1) if i < 3 else "WEEK %02d" % (i - 2)
  var index_label = text(row, caption, 15, GOLD); index_label.custom_minimum_size.x = 140
  var rival = text(row, fixture_name(i), 21); rival.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  var reports = state.archive.filter(func(r): return r.get("season", 1) == state.season and r.round == i)
  if not reports.is_empty():
   var report = reports[0]
   text(row, "%s  ·  +%dg" % ["WIN" if report.winner == 0 else "DRAW" if report.winner == -1 else "LOSS", report.gold], 17, TEAL if report.winner == 0 else MUTED)
   action(row, "Match report", func(): report_dialog(report))
  elif i < state.round: text(row, "Played · report unavailable in older save", 15, MUTED)
  elif i == state.round: action(row, "NEXT · Prepare match", game.prepare_match, true)
  else: text(row, "UPCOMING  /  5v5", 15, MUTED)
  game.divider(box)
 if not state.history.is_empty():
  var history = card(body); text(history, "PAST SEASONS", 14, GOLD)
  for season in state.history: text(history, "Season %d · Champion: %s · Your record %d W / %d L" % [season.season, season.champion, season.wins, season.losses], 19)
  for report in state.archive:
   if report.get("season", 1) < state.season:
    action(history, "Season %d · %s · %s" % [report.get("season", 1), report.opponent, "Win" if report.winner == 0 else "Draw" if report.winner == -1 else "Loss"], func(): report_dialog(report))

func report_dialog(report: Dictionary) -> void:
 var dialog = overlay("Match report · " + report.opponent)
 text(dialog.body, "%s  /  +%d gold  /  %.1f seconds" % ["Victory" if report.winner == 0 else "Draw" if report.winner == -1 else "Defeat", report.gold, report.duration], 24, GOLD)
 var analytics = MatchAnalytics.new(); analytics.game = game; analytics.report = report; dialog.body.add_child(analytics)

func intel() -> void:
 if state.has("tour"):
  league_page(); return
 heading("League intelligence", "Follow the clubs and heroes shaping this season. Scores come from simulated league bouts, including the other clubs' fixtures.")
 filters(body, "intel", ["Rankings", "Standings", "Bestiary"])
 if prefs.intel == "Standings":
  var box = card(body); var grid = GridContainer.new(); grid.columns = 6; grid.add_theme_constant_override("h_separation", 45); grid.add_theme_constant_override("v_separation", 24); box.add_child(grid)
  for caption in ["RANK", "CLUB", "WINS", "DRAWS", "LOSSES", "POINTS"]: text(grid, caption, 14, GOLD)
  var rank = 0
  for club in campaign.standings():
   rank += 1; var color = TEAL if club.name == state.name else WHITE
   for value in [str(rank), club.name, str(club.wins), str(club.draws), str(club.losses), str(club.wins * 3 + club.draws)]: text(grid, value, 23, color).size_flags_horizontal = Control.SIZE_EXPAND_FILL
  text(box, "3 points for a win · 1 for a draw · 0 for a loss. Proving bouts do not count toward the league table.", 17, MUTED)
 elif prefs.intel == "Bestiary":
  var grid = GridContainer.new(); grid.columns = 4; grid.add_theme_constant_override("h_separation", 16); grid.add_theme_constant_override("v_separation", 16); body.add_child(grid)
  for sp in HeroData.species:
   var box = card(grid); box.get_parent().custom_minimum_size.x = 363
   var art = portrait(box, sp, 200); art.caption = HeroData.species[sp].n
   text(box, HeroData.species[sp].role + " · " + HeroData.line(sp), 15, TEAL)
   action(box, "Abilities & 3D model", func(): profile(HeroData.make_hero(sp, "catalog", HeroData.species[sp].n), false))
 else:
  var row = horizontal(body)
  for metric in ["impact", "damage", "healing", "blocked", "kills"]: action(row, "Shielding" if metric == "blocked" else metric.capitalize(), func(): prefs.metric = metric; game.render(), prefs.metric == metric)
  action(row, "Per bout" if prefs.per_bout else "Season total", func(): prefs.per_bout = not prefs.per_bout; game.render(), true)
  var box = card(body)
  text(box, "Impact = damage ÷ 60 + healing ÷ 45 + absorbed shields ÷ 120 + kills × 4. Only this season's league matches count.", 16, MUTED)
  var leaders = campaign.season_leaders(prefs.metric, prefs.per_bout)
  if leaders.is_empty(): text(box, "No recorded league appearances yet. Complete the proving grounds to open the rankings.", 24, MUTED)
  for i in range(leaders.size()):
   var h = leaders[i]; var entry = horizontal(box)
   text(entry, "%02d" % (i + 1), 22, GOLD).custom_minimum_size.x = 40
   var thumb = portrait(entry, h.hero.sp, 50); thumb.custom_minimum_size.x = 80; thumb.size_flags_horizontal = Control.SIZE_FILL
   var info = column(entry); text(info, h.hero.name + " · " + HeroData.species[h.hero.sp].n, 20, TEAL if h.club == state.name else WHITE); text(info, h.club, 14, MUTED)
   text(entry, "%d bouts     %.1f" % [h.bouts, h.score], 21, GOLD)
   action(entry, "Scout", func(): profile(h.hero, h.club == state.name))
   game.divider(box)

## The league: power rankings, Madden-style ratings and their weekly movement, Arena Impact leaders.
func league_page() -> void:
 heading("Around the league", "Ratings update after every cup from each creature's level, kit and Arena Impact form.")
 if prefs.intel not in ["Ratings", "Power", "Impact"]: prefs.intel = "Ratings"
 filters(body, "intel", ["Ratings", "Power", "Impact"])
 if prefs.intel == "Power":
  var clubs = [{"name": state.name, "roster": campaign.lineup(), "wins": state.wins, "losses": state.losses, "headliner": state.get("headliner", "")}] + state.clubs
  clubs.sort_custom(func(a, b): return League.team_ovr(a.roster) > League.team_ovr(b.roster))
  var rank = 0
  for cl in clubs:
   rank += 1
   var box = card(body); var row = horizontal(box)
   text(row, "%d" % rank, 30, GOLD).custom_minimum_size.x = 44
   var face = cl.roster.filter(func(h): return h.id == cl.get("headliner", ""))
   if not face.is_empty(): thumb(row, face[0].sp, 70)
   var info = column(row); info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   text(info, cl.name, 24, TEAL if cl.name == state.name else WHITE)
   text(info, "Headliner: %s  ·  Record %d–%d" % [HeroData.species[face[0].sp].n if not face.is_empty() else "—", cl.wins, cl.losses], 15, MUTED)
   var strip = horizontal(row)
   for h in cl.roster:
    var tile = column(strip); thumb(tile, h.sp, 46); text(tile, str(HeroData.power(h)), 13, TraitUI.power_color(h))
   text(row, "%d power" % League.team_power(cl.roster), 28, GOLD)
  return
 if prefs.intel == "Impact":
  var box = card(body)
  text(box, "ARENA IMPACT SCORE (AIS) · 1–100 per match. Shares of team damage, healing & shields, front-line soak and takedowns, plus survival. 50 is average, 80+ is an MVP performance.", 15, MUTED)
  var rows = League.all_heroes(campaign).filter(func(h): return int(h.get("season_ais_games", 0)) >= 1)
  rows.sort_custom(func(a, b): return float(a.season_ais) / a.season_ais_games > float(b.season_ais) / b.season_ais_games)
  if rows.is_empty(): text(box, "No matches played yet.", 22, MUTED)
  for i in range(mini(20, rows.size())):
   var h = rows[i]; var line = horizontal(box)
   text(line, "%02d" % (i + 1), 20, GOLD).custom_minimum_size.x = 40
   thumb(line, h.sp, 44)
   var info = column(line); info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   var cl = League.club_of(campaign, h)
   text(info, "%s · %s" % [h.name, HeroData.species[h.sp].n], 19, TEAL if cl == state.name else WHITE); text(info, cl, 13, MUTED)
   text(line, "%d AIS  ·  %d games" % [roundi(float(h.season_ais) / h.season_ais_games), h.season_ais_games], 19, GOLD)
  return
 var moves: Array = state.get("rating_moves", [])
 if not moves.is_empty():
  var mv = card(body); text(mv, "THIS WEEK'S MOVERS", 14, GOLD)
  var row = horizontal(mv)
  for m in moves.slice(0, 6):
   var tile = column(row); thumb(tile, m.sp, 54)
   text(tile, "%s %s%d" % [HeroData.species[m.sp].n, "+" if m.to > m.from else "-", absi(m.to - m.from)], 15, Color("8fe08a") if m.to > m.from else Color("ff9a8a"))
   text(tile, "%d → %d · %s" % [m.from, m.to, m.club], 12, MUTED)
 var box = card(body)
 var heroes = League.all_heroes(campaign)
 heroes.sort_custom(func(a, b): return League.ovr(a) > League.ovr(b))
 var grid = GridContainer.new(); grid.columns = 10; grid.add_theme_constant_override("h_separation", 22); grid.add_theme_constant_override("v_separation", 8); box.add_child(grid)
 for caption in ["#", "", "CREATURE", "CLUB", "TIER", "POWER", "POW", "DUR", "SPD", "SKL / IMP"]: text(grid, caption, 13, GOLD)
 for i in range(mini(30, heroes.size())):
  var h = heroes[i]; var r = League.ratings(h); var cl = League.club_of(campaign, h)
  text(grid, str(i + 1), 17, GOLD)
  thumb(grid, h.sp, 36)
  text(grid, "%s · %s" % [h.name, HeroData.species[h.sp].n], 17, TEAL if cl == state.name else WHITE)
  text(grid, cl, 14, MUTED)
  text(grid, League.tier(h.sp), 14, League.tier_color(h.sp))
  text(grid, League.rating_badge_text(h), 18, GOLD)
  for k in ["POW", "DUR", "SPD"]: text(grid, str(r[k]), 15, WHITE)
  text(grid, "%d / %d" % [r.SKL, r.IMP], 15, WHITE)

func thumb(parent: Node, sp: String, px: int) -> Control:
 return SplashArt.make(parent, sp, Vector2(px, px))

func club_page() -> void:
 heading("The club house", "Your identity, earned equipment and campaign settings. Hero abilities develop through arena experience.")
 filters(body, "club", ["Identity", "Armory", "Settings"])
 if prefs.club == "Armory": armory(); return
 var box = card(body)
 if prefs.club == "Settings":
  text(box, "CAMPAIGN CHALLENGE", 14, GOLD)
  var difficulty = OptionButton.new(); box.add_child(difficulty)
  for name_value in ["Keeper", "Standard", "Champion"]: difficulty.add_item(name_value)
  difficulty.selected = ["Keeper", "Standard", "Champion"].find(state.difficulty)
  difficulty.item_selected.connect(func(index): state.difficulty = ["Keeper", "Standard", "Champion"][index]; campaign.save(); game.render())
  text(box, "Keeper offers a gentler start. Standard uses equal base stats. Champion strengthens the opposition. Current rival health and attack: %d%%." % roundi(campaign.quality() * 100), 19, MUTED)
  action(box, "Music: " + ("On" if game.sound.music_enabled else "Off"), game.toggle_music)
  action(box, "Battle sounds: " + ("On" if game.sound.effects_enabled else "Off"), game.toggle_effects)
  action(box, "⚙  Audio settings", func(): FlowUI.settings(game))
  action(box, "Save campaign", func(): game.toast("Campaign saved." if campaign.save() else campaign.last_error))
  action(box, "Save & return to main menu", game.quit_to_menu)
  text(box, "Start a fresh club or load one of three saved campaigns from the main menu. Replacing an occupied save slot asks first.", 17, MUTED)
 else:
  text(box, game.initials(state.name), 54, GOLD)
  text(box, "CLUB NAME & CREST", 14, GOLD)
  var name_field = LineEdit.new(); name_field.text = state.name; name_field.max_length = 36; box.add_child(name_field)
  action(box, "Update club identity", func():
   if name_field.text.strip_edges().is_empty(): game.toast("Give your club a name first."); return
   state.name = name_field.text.strip_edges(); campaign.save(); game.render(), true)
  text(box, "Team level %d / %d · %d tournament wins · %d arena gold" % [state.tour.level,WorldTour.MAX_LEVEL,state.trophies,state.earned_gold] if state.has("tour") else "Season %d    /    %d league titles    /    %d total arena gold earned" % [state.season, state.trophies, state.earned_gold], 22, TEAL)
  text(box, "Gold funds recruitment and equipment. Field five heroes to earn arena XP; reserves retain their progress until their next appearance.", 19, MUTED)
  action(box, "Open season calendar", func(): navigate("matches"))

func armory() -> void:
 if state.has("tour"):
  var intro=card(body); text(intro,"Tournament outfitter",28)
  text(intro,"The shop opens after every match. Equip three slots per hero: claws, armor and charm. Your inventory carries between locations.",18,MUTED)
  if state.tour.shop: action(intro,"Visit outfitter",func(): game.phase="shop";game.render(),true)
  else: action(intro,"Manage equipped items",func(): navigate("roster"))
  return
 var intro = card(body)
 if state.earned_gold < 300:
  text(intro, "Prove your club in the arena", 28)
  text(intro, "The armory unlocks after you earn 300 gold through matches. Your founding budget doesn't count. Focus on recruiting your first five.", 20, MUTED)
  progress(intro, "Arena gold earned", state.earned_gold, 300); return
 text(intro, "The Forge", 28)
 text(intro, "Items come from the outfitter between tournament matches and from medal chests. Open the recipe book to plan your combinations.", 18, MUTED)
 action(intro, "Recipe book", func(): GearUI.recipe_book(game), true)

func tour_overview() -> void:
 HeadlinerUI.overview(self)

func tour_history() -> void:
 heading("Tournament journal", "Your route, results and promotions are saved with your club.")
 for entry in state.tour.history:
  var box=card(body);text(box,"Level %d · %s" % [entry.level,entry.location],24)
  text(box,"%d wins · Finished %s · %s · Attempt %d" % [entry.wins,TournamentRewardsUI._place_text(int(entry.get("place",1 if entry.promoted else 0))),"CHAMPIONS" if entry.promoted else "ADVANCED",entry.attempt],17,GOLD)
 for report in state.archive:
  if report.has("tour_level"):
   var box=card(body);action(box,"Level %d · %s · %s · %s" % [report.tour_level,report.get("stage","Match %d" % report.bout),report.location,"WIN" if report.winner==0 else "DRAW" if report.winner==-1 else "LOSS"],func(): report_dialog(report))
