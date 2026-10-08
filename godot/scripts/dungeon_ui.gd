class_name DungeonUI
extends RefCounted
## The dungeon's map screen: the depth's branching rooms, the path you took, the rooms you can
## step into next, and the choices waiting in them (spoils, events and campfires).

class DungeonMap extends Control:
 var game: Node
 var points := {}      # Vector2i(row, col) -> centre
 var trail := []
 var map := []
 func _draw() -> void:
  for r in range(map.size() - 1):
   for i in range(map[r].size()):
    for j in map[r][i].links:
     var a = points[Vector2i(r, i)]; var b = points[Vector2i(r + 1, j)]
     var walked = r + 1 < trail.size() and int(trail[r]) == i and int(trail[r + 1]) == j
     draw_dashed_line(a, b, Color("ffd36e") if walked else Color(1, 1, 1, 0.22), 4.0 if walked else 2.0, 10.0 if not walked else 1.0, true, true)

static func overview(desk: ManagementDesk) -> void:
 var game = desk.game; var c: Campaign = desk.campaign; var d = c.state.dungeon; var dep = Dungeon.depth(c)
 var top = desk.horizontal(desk.body)
 desk.text(top, dep.name, 34).size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var depth_text = "ENDLESS DEPTH %d" % (int(d.act) - Dungeon.ACTS) if int(d.act) > Dungeon.ACTS else "DEPTH %d OF %d" % [int(d.act), Dungeon.ACTS]
 desk.text(top, "%s · %s · %d POINTS" % [depth_text, Dungeon.stage_label(c).to_upper(), int(d.score)], 19, desk.GOLD)
 desk.text(desk.body, dep.text, 15, desk.MUTED)
 var nav = desk.horizontal(desk.body)
 desk.action(nav, "Champion's vault · %d chests" % TrophyVault.unopened(c).size(), func(): TournamentRewardsUI.open_screen(game, "vault"), true)
 desk.action(nav, "Run traits", func(): traits_modal(game))
 desk.action(nav, "High scores", func(): high_scores(game))
 desk.action(nav, "How the dungeon works", func(): guide(game))
 if not c.state.report.is_empty(): desk.action(nav, "Last fight", func(): desk.report_dialog(c.state.report))
 if d.endless and not c.state.tour.get("complete", false) and not c.state.get("run_over", false) and not d.fight:
  desk.action(nav, "Retire · bank %d points" % Dungeon.final_score(c), func(): confirm_retire(game))
 if c.state.tour.get("complete", false):
  var done = desk.card(desk.body); desk.text(done, "RUN COMPLETE · %d POINTS" % int(d.get("final_score", 0)), 40, desk.GOLD)
  if not c.headliner().is_empty(): HeadlinerUI.portrait(done, c.headliner(), 200)
  var place = Dungeon.rank_of(c)
  desk.text(done, "%s · %d Warden%s defeated · %d fights · %d won · %d relics · %d li%s left%s" % [str(d.get("outcome", "Conquered")), int(d.wardens), "" if int(d.wardens) == 1 else "s", int(d.fights), int(d.wins), d.relics.size(), int(d.lives), "fe" if int(d.lives) == 1 else "ves", ("  ·  #%d on your high scores" % place) if place > 0 else ""], 22)
  return
 if d.awaiting_endless:
  var gate = desk.card(desk.body)
  desk.text(gate, "THE DUNGEON IS CONQUERED", 34, desk.GOLD)
  desk.text(gate, "All three Wardens have fallen. Bank your score now, or descend into the endless depths: every depth is harder and worth more points, but if you run out of lives there, the run ends where you fall.", 17, desk.MUTED)
  var row = desk.horizontal(gate)
  desk.action(row, "Bank score · %d points" % Dungeon.final_score(c), func():
   if Dungeon.retire(c): game.render(); FlowUI.banner(game, "%d POINTS" % int(d.final_score), Color("ffd36e"), "Score banked")
   else: game.toast(c.last_error), true).name = "DungeonBankScore"
  FlowUI.cta(game, row, "Into the endless depths  ▶", func():
   if Dungeon.go_endless(c): game.render(); FlowUI.banner(game, "ENDLESS", Color("b9a2ff"), str(Dungeon.depth(c).name))
   else: game.toast(c.last_error), false, 420).name = "DungeonGoEndless"
 if c.state.tour.get("intermission", false):
  var stairs = desk.card(desk.body)
  desk.text(stairs, "THE STAIRS TO %s" % str(dep.name).to_upper(), 26, desk.GOLD)
  desk.text(stairs, "Fresh recruits wait on the landing. Visit the Market, set your formation and tactics, then descend.", 17, desk.MUTED)
  desk.action(stairs, "Descend  ▶", func():
   if WorldTour.end_intermission(c): game.render(); FlowUI.banner(game, str(dep.name).to_upper(), Color(Dungeon.region(c).color), depth_text)
   else: game.toast(c.last_error), true)
 map_view(game, desk.body, c)
 var extras = desk.horizontal(desk.body)
 relic_bar(desk, extras, c)
 traits_panel(desk, extras, c)
 status(desk, c)
 # Anything waiting in the current room opens straight away.
 if not d.loot.is_empty(): game.get_tree().process_frame.connect(func(): loot_modal(game), CONNECT_ONE_SHOT)
 elif not d.event.is_empty(): game.get_tree().process_frame.connect(func(): event_modal(game), CONNECT_ONE_SHOT)

static func confirm_retire(game: Node) -> void:
 var c: Campaign = game.campaign
 var dialog = ConfirmationDialog.new(); game.ui.add_child(dialog)
 dialog.title = "Retire from the dungeon?"; dialog.dialog_text = "End the run now and bank %d points?" % Dungeon.final_score(c)
 dialog.confirmed.connect(func():
  if Dungeon.retire(c): game.render()
  else: game.toast(c.last_error))
 dialog.popup_centered(Vector2i(460, 160))

static func relic_bar(desk: ManagementDesk, parent: Node, c: Campaign) -> void:
 var game = desk.game; var box = desk.card(parent)
 box.get_parent().custom_minimum_size.x = 740
 desk.text(box, "RELICS · %d" % Relics.owned(c).size(), 16, desk.GOLD)
 if Relics.owned(c).is_empty():
  desk.text(box, "None yet. Elites, treasure, some events and every Warden offer relics.", 14, desk.MUTED); return
 var grid = GridContainer.new(); grid.columns = 9; grid.add_theme_constant_override("h_separation", 8); grid.add_theme_constant_override("v_separation", 8); box.add_child(grid)
 for id in Relics.owned(c):
  var r = Relics.info(id)
  var frame = PanelContainer.new(); grid.add_child(frame); frame.custom_minimum_size = Vector2(66, 66)
  frame.add_theme_stylebox_override("panel", game.style(Color(.08, .06, .12, .95), rarity_color(r.rarity), 8, 3, 2))
  frame.tooltip_text = "%s · %s relic\n%s" % [r.name, r.rarity, r.text]; frame.mouse_filter = Control.MOUSE_FILTER_STOP
  var art = AbilityArt.icon(frame, str(r.art), 58); art.mouse_filter = Control.MOUSE_FILTER_IGNORE

static func rarity_color(rarity: String) -> Color:
 return Color({"Common": "9fd4c6", "Rare": "8fb8ff", "Boss": "ffb35c"}.get(rarity, "ffffff"))

static func traits_panel(desk: ManagementDesk, parent: Node, c: Campaign) -> void:
 var game = desk.game; var box = desk.card(parent)
 desk.text(box, "RUN TRAITS · YOUR SQUAD", 16, desk.GOLD)
 var grid = GridContainer.new(); grid.columns = 2; grid.add_theme_constant_override("h_separation", 22); grid.add_theme_constant_override("v_separation", 4); box.add_child(grid)
 for row in RunTraits.summary(c, c.lineup()):
  if int(row.count) == 0: continue
  var t = RunTraits.info(row.id); var lit = int(row.tier) >= 0
  var l = game.label(grid, "%s  %d / %d" % [t.name, int(row.count), RunTraits.THRESHOLDS[mini(int(row.tier) + 1, RunTraits.THRESHOLDS.size() - 1)]], 16, Color(t.color) if lit else desk.MUTED, false)
  l.mouse_filter = Control.MOUSE_FILTER_STOP; l.tooltip_text = trait_tooltip(row.id)
 desk.text(box, "Each species carries two traits this run. Field 2 or 4 different champions that share a trait to unlock it.", 13, desk.MUTED)

static func trait_tooltip(id: String) -> String:
 var t = RunTraits.info(id)
 var lines = ["%s · %s" % [t.name, t.text]]
 for i in range(t.tiers.size()): lines.append("(%d) %s" % [RunTraits.THRESHOLDS[i], t.tiers[i][2]])
 return "\n".join(lines)

static func traits_modal(game: Node) -> void:
 var c: Campaign = game.campaign
 var dialog = GearUI.modal(game, "Run traits · rolled for this run", Vector2(1300, 760))
 var scroll = ScrollContainer.new(); scroll.custom_minimum_size = Vector2(1260, 680); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; dialog.box.add_child(scroll)
 var list = VBoxContainer.new(); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; list.add_theme_constant_override("separation", 10); scroll.add_child(list)
 var counts = RunTraits.counts(c, c.lineup())
 for id in RunTraits.data(c).get("active", []):
  var t = RunTraits.info(id)
  var head = HBoxContainer.new(); head.add_theme_constant_override("separation", 14); list.add_child(head)
  game.label(head, t.name, 22, Color(t.color), false).custom_minimum_size.x = 190
  game.label(head, "%d in squad · %s" % [int(counts.get(id, 0)), " · ".join(range(t.tiers.size()).map(func(i): return "(%d) %s" % [RunTraits.THRESHOLDS[i], t.tiers[i][2]]))], 14, game.WHITE)
  var holders = HeroData.species.keys().filter(func(sp): return id in RunTraits.of(c, sp))
  holders.sort()
  game.label(list, "    " + ", ".join(holders.map(func(sp): return HeroData.species[sp].n)), 13, game.MUTED)

static func high_scores(game: Node) -> void:
 var dialog = GearUI.modal(game, "Dungeon high scores", Vector2(1100, 640))
 var table = Dungeon.scores()
 if table.is_empty():
  game.label(dialog.box, "No banked runs yet. A run's score is banked when you run out of lives, conquer the dungeon or retire from the endless depths.", 17, game.MUTED); return
 var grid = GridContainer.new(); grid.columns = 7; grid.add_theme_constant_override("h_separation", 26); grid.add_theme_constant_override("v_separation", 6); dialog.box.add_child(grid)
 for head in ["#", "Guild", "Score", "Reached", "Wardens", "Difficulty", "Result"]: game.label(grid, head, 14, game.GOLD, false)
 for i in range(mini(15, table.size())):
  var e = table[i]
  game.label(grid, str(i + 1), 16, game.WHITE, false)
  game.label(grid, str(e.get("name", "?")), 16, game.WHITE, false)
  game.label(grid, str(int(e.get("score", 0))), 18, Color("ffd36e"), false)
  var depth_n = int(e.get("depth", 1))
  game.label(grid, ("Endless %d" % (depth_n - Dungeon.ACTS)) if depth_n > Dungeon.ACTS else "Depth %d · room %d" % [depth_n, int(e.get("room", 1))], 16, game.WHITE, false)
  game.label(grid, str(int(e.get("wardens", 0))), 16, game.WHITE, false)
  game.label(grid, str(e.get("difficulty", "")) + (" · A%d" % int(e.challenge) if int(e.get("challenge", 0)) > 0 else ""), 16, game.MUTED, false)
  game.label(grid, "%s · %s" % [str(e.get("outcome", "")), str(e.get("date", ""))], 15, game.MUTED, false)

static func map_view(game: Node, parent: Node, c: Campaign) -> void:
 var d = c.state.dungeon
 var frame = FantasyFrame.new(); frame.custom_minimum_size = Vector2(1500, 440); parent.add_child(frame)
 frame.add_theme_stylebox_override("panel", game.style(Color(.03, .035, .06, .96), Color(Dungeon.region(c).color).darkened(.35), 8, 0, 2))
 var view = DungeonMap.new(); view.game = game; view.map = d.map; view.trail = d.get("trail", []); frame.add_child(view)
 view.custom_minimum_size = Vector2(1500, 440); view.mouse_filter = Control.MOUSE_FILTER_PASS
 var w = 1500.0; var h = 392.0
 for r in range(d.map.size()):
  for i in range(d.map[r].size()):
   view.points[Vector2i(r, i)] = Vector2(80 + r * (w - 160) / (Dungeon.ROWS - 1), 30 + (i + 0.5) / d.map[r].size() * (h - 60))
 var options = Dungeon.reachable(c)
 for r in range(d.map.size()):
  for i in range(d.map[r].size()):
   var n = d.map[r][i]; var info = Dungeon.ROOMS[str(n.type)]
   var here = r == int(d.row) and i == int(d.col)
   var open = r == int(d.row) + 1 and i in options
   var walked = r < view.trail.size() and int(view.trail[r]) == i
   var px = 76 if str(n.type) == "boss" else 60
   var b = Button.new(); view.add_child(b); b.size = Vector2(px, px); b.position = view.points[Vector2i(r, i)] - b.size * 0.5
   b.focus_mode = Control.FOCUS_NONE
   var tint = Color(info.color)
   var fill = Color(.10, .08, .14, .96) if not (walked or here) else Color(tint.darkened(.55), .98)
   var border = Color("fff3cf") if here else (tint if open else (tint.darkened(.25) if walked else Color(1, 1, 1, .18)))
   for st in ["normal", "hover", "pressed", "disabled"]:
    var sb = game.style(fill.lightened(.12) if st == "hover" and open else fill, border, px / 2, 0, 4 if open or here else 2)
    b.add_theme_stylebox_override(st, sb)
   var holder = CenterContainer.new(); holder.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(holder); holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
   var g = FlowUI.glyph(holder, str(info.glyph), px * 0.55, open or here or walked or r > int(d.row))
   if not (open or here) and r > int(d.row): g.modulate = Color(1, 1, 1, .55)
   if n.done and not here: g.modulate = Color(1, 1, 1, .4)
   b.tooltip_text = "%s · Room %d\n%s" % [info.name, r + 1, info.text]
   b.disabled = not open
   if open:
    b.name = "DungeonRoom_%d_%d" % [r, i]
    var pulse = b.create_tween().set_loops(); pulse.set_trans(Tween.TRANS_SINE)
    pulse.tween_property(b, "modulate", Color(1.25, 1.2, 1.05), 0.8); pulse.tween_property(b, "modulate", Color.WHITE, 0.8)
    var col = i
    b.pressed.connect(func(): step(game, col))
 var key = Control.new(); view.add_child(key); key.position = Vector2(0, 400); key.size = Vector2(w, 34); key.mouse_filter = Control.MOUSE_FILTER_IGNORE
 legend(game, key)
 view.queue_redraw()

static func legend(game: Node, parent: Node) -> void:
 var row = HBoxContainer.new(); row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 22); parent.add_child(row)
 for key in ["battle", "elite", "event", "shop", "rest", "treasure", "boss"]:
  var info = Dungeon.ROOMS[key]; var item = HBoxContainer.new(); item.add_theme_constant_override("separation", 6); row.add_child(item)
  item.mouse_filter = Control.MOUSE_FILTER_STOP; item.tooltip_text = info.text
  FlowUI.glyph(item, str(info.glyph), 22)
  game.label(item, info.name, 15, Color(info.color), false).mouse_filter = Control.MOUSE_FILTER_IGNORE

static func status(desk: ManagementDesk, c: Campaign) -> void:
 var game = desk.game; var d = c.state.dungeon
 var box = desk.card(desk.body)
 if d.fight:
  var kind = str(Dungeon.node(c).type); var rival = c.opponent()
  desk.text(box, "%s · %s" % [Dungeon.ROOMS[kind].name.to_upper(), rival.name], 26, Color(Dungeon.ROOMS[kind].color))
  var ours = League.team_power(c.lineup()); var theirs = League.team_power(rival.roster)
  desk.text(box, "Your power %d  ·  their power %d%s" % [ours, theirs, "  ·  Losing a Warden fight costs a life and you must face it again." if kind == "boss" else "  ·  Losing costs a life; the guild still pushes past."], 16, desk.MUTED)
  if kind == "boss": desk.text(box, str(Bestiary.BOSSES[rival.boss].text), 15, Color("ffb3a8"))
  var actions = desk.horizontal(box)
  desk.action(actions, "Scout", func(): ScoutUI.open(game, rival))
  desk.action(actions, "Formation", func(): game.phase = "prep"; game.render())
  FlowUI.cta(game, actions, "Fight  ▶", game.introduce_match, not c.lineup_ready() or not c.pending_heroes().is_empty(), 260)
 elif c.state.get("run_over", false):
  desk.text(box, "OUT OF LIVES · FINAL SCORE %d" % int(d.get("final_score", 0)), 26, Color("ff8a7a"))
 elif not Dungeon.reachable(c).is_empty():
  desk.text(box, "Choose your next room on the map. Glowing rooms are on your path.", 18)
  var preview = Dungeon.opponent(c)
  desk.text(box, "Nearest fight ahead: %s · power %d" % [preview.name, League.team_power(preview.roster)], 15, desk.MUTED)

static func step(game: Node, col: int) -> void:
 var c: Campaign = game.campaign
 var kind = Dungeon.enter(c, col)
 if kind == "": game.toast(c.last_error if not c.last_error.is_empty() else "Could not enter that room."); return
 game.sound.cue("contest_reveal")
 var info = Dungeon.ROOMS[kind]
 if kind == "shop":
  game.phase = "shop"; game.render(); FlowUI.banner(game, "OUTFITTER", Color(info.color)); return
 game.render()
 if kind in ["battle", "elite", "boss"]: FlowUI.banner(game, str(info.name).to_upper(), Color(info.color), c.opponent().name)

static func loot_modal(game: Node) -> void:
 var c: Campaign = game.campaign; var d = c.state.dungeon
 if d.loot.is_empty(): return
 if d.loot_kind == "relic": relic_modal(game); return
 var dialog = GearUI.modal(game, "Spoils · choose one" if d.loot_kind == "component" else "Spoils · choose a finished item", Vector2(980, 470))
 dialog.box.add_theme_constant_override("separation", 12)
 game.label(dialog.box, "Take one into your bag, or skip it for 25 gold. Two components on one champion forge a finished item.", 15, game.MUTED)
 var row = HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 16); dialog.box.add_child(row)
 for i in range(d.loot.size()):
  var id = str(d.loot[i]); var item = Forge.info(id)
  var tile = FantasyFrame.new(); tile.custom_minimum_size = Vector2(290, 300); row.add_child(tile)
  var tint = Color("ff9be0") if item.get("wild", false) else (Color("9fd4c6") if item.kind == "component" else Color("ffd36e"))
  tile.accent = tint; tile.add_theme_stylebox_override("panel", game.style(Color(.09, .06, .17, .96), tint, 10, 12, 2))
  var box = VBoxContainer.new(); box.add_theme_constant_override("separation", 6); tile.add_child(box)
  var art = CenterContainer.new(); box.add_child(art); GearUI.token(game, art, item, 88)
  var name_label = game.label(box, item.name, 20, game.WHITE); name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  game.label(box, ("★ WILD ITEM" if item.get("wild", false) else "FINISHED ITEM") if item.kind == "item" else "COMPONENT", 12, tint).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  game.label(box, Forge.stat_line(id) if item.kind == "item" else str(item.get("short", "")), 13, game.MUTED)
  if item.kind == "item": game.label(box, str(item.get("text", "")), 12, Color("c8dcb1"))
  var index = i
  var take = game.button(box, "Take", func():
   if Dungeon.take_loot(c, index): dialog.root.queue_free(); game.sound.cue("upgrade"); game.render()
   else: game.toast(c.last_error), true)
  take.name = "DungeonLoot_%d" % i
 var skip = game.button(dialog.box, "Skip · +25 gold", func():
  if Dungeon.skip_loot(c): dialog.root.queue_free(); game.render())
 skip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

static func relic_modal(game: Node) -> void:
 var c: Campaign = game.campaign; var d = c.state.dungeon
 var dialog = GearUI.modal(game, "Choose a relic", Vector2(980, 470))
 dialog.box.add_theme_constant_override("separation", 12)
 game.label(dialog.box, "Relics last for the whole run. Take one, or skip it for 25 gold.%s" % ("  ·  %d more reward%s waiting" % [d.loot_queue.size(), "" if d.loot_queue.size() == 1 else "s"] if not d.loot_queue.is_empty() else ""), 15, game.MUTED)
 var row = HBoxContainer.new(); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 16); dialog.box.add_child(row)
 for i in range(d.loot.size()):
  var id = str(d.loot[i]); var r = Relics.info(id); var tint = rarity_color(r.rarity)
  var tile = FantasyFrame.new(); tile.custom_minimum_size = Vector2(290, 300); row.add_child(tile)
  tile.accent = tint; tile.add_theme_stylebox_override("panel", game.style(Color(.09, .06, .17, .96), tint, 10, 12, 2))
  var box = VBoxContainer.new(); box.add_theme_constant_override("separation", 6); tile.add_child(box)
  var art = CenterContainer.new(); box.add_child(art); AbilityArt.icon(art, str(r.art), 96)
  var name_label = game.label(box, r.name, 20, game.WHITE); name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  game.label(box, "%s RELIC" % str(r.rarity).to_upper(), 12, tint).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  game.label(box, str(r.text), 15, Color("c8dcb1"))
  var index = i
  var take = game.button(box, "Take", func():
   if Dungeon.take_loot(c, index): dialog.root.queue_free(); game.sound.cue("upgrade"); game.render()
   else: game.toast(c.last_error), true)
  take.name = "DungeonLoot_%d" % i
 var skip = game.button(dialog.box, "Skip · +25 gold", func():
  if Dungeon.skip_loot(c): dialog.root.queue_free(); game.render())
 skip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

static func event_modal(game: Node) -> void:
 var c: Campaign = game.campaign; var d = c.state.dungeon
 if d.event.is_empty(): return
 var e = d.event
 var dialog = GearUI.modal(game, str(e.title), Vector2(860, 340))
 dialog.box.add_theme_constant_override("separation", 14)
 var top = HBoxContainer.new(); top.add_theme_constant_override("separation", 18); dialog.box.add_child(top)
 FlowUI.glyph(top, "flame" if e.id == "rest" else "roll", 64)
 game.label(top, str(e.text), 18, game.WHITE).size_flags_horizontal = Control.SIZE_EXPAND_FILL
 for i in range(e.choices.size()):
  var ch = e.choices[i]; var line = HBoxContainer.new(); line.add_theme_constant_override("separation", 14); dialog.box.add_child(line)
  var index = i
  var b = game.button(line, str(ch.label), func():
   var outcome = Dungeon.choose_event(c, index)
   if outcome == "": game.toast(c.last_error); return
   dialog.root.queue_free(); game.toast(outcome)
   if not c.pending_heroes().is_empty(): game.phase = "upgrade"
   game.render(), true, ch.get("disabled", false))
  b.custom_minimum_size = Vector2(300, 50); b.name = "DungeonChoice_%d" % i
  game.label(line, str(ch.detail), 15, game.MUTED if ch.get("disabled", false) else Color("c8dcb1")).size_flags_horizontal = Control.SIZE_EXPAND_FILL

static func guide(game: Node) -> void:
 var dialog = GearUI.modal(game, "The Dungeon", Vector2(1000, 640))
 for line in [
  "Three depths, each ending at a Warden boss. Pick one room at a time along the glowing paths.",
  "Lives: losing a fight costs one; lose them all and the run ends. Campfires, healing springs and defeated Wardens restore them.",
  "Skirmishes reward one of three components. Treasure gives gold and one of three finished items. Elites give one of three relics.",
  "Wardens give a finished item, a powerful Warden relic and a medal chest.",
  "Relics are passive bonuses for the whole run. Some boost the whole team, some a line or your headliner, a few change the rules.",
  "Run traits: every species carries two traits, re-rolled each run. Field 2 or 4 different champions with the same trait to unlock its bonus.",
  "Score: rooms, wins, elites, Wardens and relics earn points, multiplied by the depth. Lives left add a bonus; difficulty and Ascension multiply the total.",
  "After the third Warden, bank your score or go into the endless depths, where each depth is harder and worth more.",
 ]: game.label(dialog.box, "•  " + line, 17, game.WHITE)
