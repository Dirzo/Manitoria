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
 desk.text(top, "DEPTH %d OF %d · %s" % [int(d.act), Dungeon.ACTS, Dungeon.stage_label(c).to_upper()], 19, desk.GOLD)
 desk.text(desk.body, dep.text, 15, desk.MUTED)
 var nav = desk.horizontal(desk.body)
 desk.action(nav, "Champion's vault · %d chests" % TrophyVault.unopened(c).size(), func(): TournamentRewardsUI.open_screen(game, "vault"), true)
 desk.action(nav, "How the dungeon works", func(): guide(game))
 if not c.state.report.is_empty(): desk.action(nav, "Last fight · Damage & healing", func(): desk.report_dialog(c.state.report))
 if c.state.tour.get("complete", false):
  var done = desk.card(desk.body); desk.text(done, "THE LAST FLAME ENDURES", 40, desk.GOLD)
  if not c.headliner().is_empty(): HeadlinerUI.portrait(done, c.headliner(), 200)
  desk.text(done, "All three Wardens have fallen. %d fights · %d won · %d flame%s still burning." % [int(d.fights), int(d.wins), int(d.flames), "" if int(d.flames) == 1 else "s"], 22)
  return
 if c.state.tour.get("intermission", false):
  var stairs = desk.card(desk.body)
  desk.text(stairs, "THE STAIRS TO %s" % str(dep.name).to_upper(), 26, desk.GOLD)
  desk.text(stairs, "Fresh recruits wait on the landing. Visit the Market, set your formation and tactics, then descend.", 17, desk.MUTED)
  desk.action(stairs, "Descend  ▶", func():
   if WorldTour.end_intermission(c): game.render(); FlowUI.banner(game, str(dep.name).to_upper(), Color(Dungeon.region(c).color), "Depth %d of %d" % [int(d.act), Dungeon.ACTS])
   else: game.toast(c.last_error), true)
 map_view(game, desk.body, c)
 status(desk, c)
 # Anything waiting in the current room opens straight away.
 if not d.loot.is_empty(): game.get_tree().process_frame.connect(func(): loot_modal(game), CONNECT_ONE_SHOT)
 elif not d.event.is_empty(): game.get_tree().process_frame.connect(func(): event_modal(game), CONNECT_ONE_SHOT)

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
  desk.text(box, "Your power %d  ·  their power %d%s" % [ours, theirs, "  ·  Losing a Warden fight costs a flame and you must face it again." if kind == "boss" else "  ·  Losing costs a flame; the guild still pushes past."], 16, desk.MUTED)
  var actions = desk.horizontal(box)
  desk.action(actions, "Scout", func(): ScoutUI.open(game, rival))
  desk.action(actions, "Formation", func(): game.phase = "prep"; game.render())
  FlowUI.cta(game, actions, "Fight  ▶", game.introduce_match, not c.lineup_ready() or not c.pending_heroes().is_empty(), 260)
 elif c.state.get("run_over", false):
  desk.text(box, "THE FLAME HAS GONE OUT", 26, Color("ff8a7a"))
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
 var dialog = GearUI.modal(game, "The Dungeon", Vector2(900, 560))
 for line in [
  "Three depths, each ending at a Warden. Pick one room at a time along the glowing paths.",
  "Flames are your lives. Losing a fight snuffs one out; lose them all and the run ends. Campfires and defeated Wardens rekindle them.",
  "Skirmishes reward one of three components. Elites and Wardens reward one of three finished items, and every Warden drops a medal chest.",
  "Outfitters are the only shops. Unknown rooms hold events with a choice. Treasure is free.",
  "Between depths a fresh recruit board waits on the stairs, and your squad trains on the way down.",
 ]: game.label(dialog.box, "•  " + line, 17, game.WHITE)
