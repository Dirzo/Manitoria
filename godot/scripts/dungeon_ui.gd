class_name DungeonUI
extends RefCounted
## The dungeon's map screen: the instance's branching rooms, the path you took, the rooms you can
## step into next, and the choices waiting in them (instances, spoils, events and campfires).

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

## One screen, no scrolling: the instance's map on the left (framed by its painting), and a
## sidebar on the right with what to do next, relics, run traits and the run's tools.
## Choices that block the map (which instance to enter, bank or go endless, the end of the run)
## appear as an overlay across the whole screen.
const W := 1548.0
const H := 600.0
const MAP_W := 1068.0
const SIDE_X := 1084.0
const PANEL := Color(0.035, 0.045, 0.06, 0.94)

static func overview(desk: ManagementDesk) -> void:
 var game = desk.game; var c: Campaign = desk.campaign; var d = c.state.dungeon
 var stage = Control.new(); stage.custom_minimum_size = Vector2(W, H); stage.mouse_filter = Control.MOUSE_FILTER_IGNORE; desk.body.add_child(stage)
 map_panel(game, stage, c)
 sidebar(desk, stage, c)
 if not d.get("instance_choices", []).is_empty(): path_overlay(game, stage, c)
 elif c.state.tour.get("complete", false) or c.state.get("run_over", false): end_overlay(game, stage, c)
 elif d.awaiting_endless: endless_overlay(game, stage, c)
 # Anything waiting in the current room opens straight away.
 elif not d.loot.is_empty(): game.get_tree().process_frame.connect(func(): loot_modal(game), CONNECT_ONE_SHOT)
 elif not d.event.is_empty(): game.get_tree().process_frame.connect(func(): event_modal(game), CONNECT_ONE_SHOT)

static func box_at(game: Node, parent: Control, rect: Rect2, border: Color, fill := PANEL) -> Control:
 var p = Panel.new(); parent.add_child(p); p.position = rect.position; p.size = rect.size
 p.add_theme_stylebox_override("panel", game.style(fill, border, 10, 0, 2))
 return p

static func text_at(game: Node, parent: Control, value: String, pos: Vector2, size_px: int, color: Color, width := 0.0, title := false) -> Label:
 var l = game.label(parent, value, size_px, color, width > 0.0); l.position = pos
 if width > 0.0: l.size.x = width; l.custom_minimum_size.x = width
 if title:
  l.add_theme_font_override("font", load(game.TITLE_FONT))
  l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85)); l.add_theme_constant_override("outline_size", 7)
 return l

static func painted(parent: Control, id: String, rect: Rect2, dim := 0.42) -> TextureRect:
 var art = TextureRect.new(); parent.add_child(art); art.position = rect.position; art.size = rect.size
 art.texture = DungeonInstances.art(id); art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 art.mouse_filter = Control.MOUSE_FILTER_IGNORE; art.clip_contents = true
 var accent = Color(DungeonInstances.info(id).accent)
 art.modulate = Color(dim, dim, dim).lerp(accent * dim, 0.35)
 return art

# ------------------------------------------------------------------ Map
static func map_panel(game: Node, stage: Control, c: Campaign) -> void:
 var d = c.state.dungeon; var info = Dungeon.depth(c); var accent = Color(info.accent)
 var frame = box_at(game, stage, Rect2(0, 0, MAP_W, H), accent.darkened(0.3), Color(0.02, 0.02, 0.03, 1.0))
 frame.clip_contents = true
 painted(frame, Dungeon.instance_id(c), Rect2(0, 0, MAP_W, H), 0.38)
 var shade = ColorRect.new(); frame.add_child(shade); shade.size = Vector2(MAP_W, 120); shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 shade.color = Color(0, 0, 0, 0.45)
 text_at(game, frame, "%s  ·  %s" % [str(info.depth_label).to_upper(), Dungeon.stage_label(c).to_upper()], Vector2(26, 16), 14, accent.lightened(0.3))
 text_at(game, frame, str(info.name), Vector2(24, 34), 36, Color("ffe9b8"), 0.0, true)
 text_at(game, frame, str(info.tagline), Vector2(26, 84), 15, Color(1, 1, 1, 0.75))
 if not d.map.is_empty(): map_view(game, frame, c, Rect2(0, 128, MAP_W, 420))
 var key = Control.new(); frame.add_child(key); key.position = Vector2(0, H - 44); key.size = Vector2(MAP_W, 34); key.mouse_filter = Control.MOUSE_FILTER_IGNORE
 legend(game, key)

static func map_view(game: Node, parent: Control, c: Campaign, rect: Rect2) -> void:
 var d = c.state.dungeon
 var view = DungeonMap.new(); view.game = game; view.map = d.map; view.trail = d.get("trail", []); parent.add_child(view)
 view.position = rect.position; view.size = rect.size; view.mouse_filter = Control.MOUSE_FILTER_PASS
 var w = rect.size.x; var h = rect.size.y
 for r in range(d.map.size()):
  for i in range(d.map[r].size()):
   view.points[Vector2i(r, i)] = Vector2(70 + r * (w - 140) / (Dungeon.ROWS - 1), 26 + (i + 0.5) / d.map[r].size() * (h - 52))
 var options = Dungeon.reachable(c)
 for r in range(d.map.size()):
  for i in range(d.map[r].size()):
   var n = d.map[r][i]; var info = Dungeon.ROOMS[str(n.type)]
   var here = r == int(d.row) and i == int(d.col)
   var open = r == int(d.row) + 1 and i in options
   var walked = r < view.trail.size() and int(view.trail[r]) == i
   var px = 74 if str(n.type) == "boss" else 56
   var b = Button.new(); view.add_child(b); b.size = Vector2(px, px); b.position = view.points[Vector2i(r, i)] - b.size * 0.5
   b.focus_mode = Control.FOCUS_NONE
   var tint = Color(info.color)
   var fill = Color(.06, .05, .09, .92) if not (walked or here) else Color(tint.darkened(.6), .96)
   var border = Color("fff3cf") if here else (tint if open else (tint.darkened(.3) if walked else Color(1, 1, 1, .2)))
   for st in ["normal", "hover", "pressed", "disabled"]:
    b.add_theme_stylebox_override(st, game.style(fill.lightened(.14) if st == "hover" and open else fill, border, px / 2, 0, 4 if open or here else 2))
   var holder = CenterContainer.new(); holder.mouse_filter = Control.MOUSE_FILTER_IGNORE; b.add_child(holder); holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
   var g = FlowUI.glyph(holder, str(info.glyph), px * 0.55, true)
   if not (open or here): g.modulate = Color(1, 1, 1, .4 if n.done or r <= int(d.row) else .62)
   var tip = "%s · Room %d\n%s" % [info.name, r + 1, info.text]
   if str(n.type) == "boss": tip += "\n\n%s\n%s" % [Dungeon.warden(c).name, Dungeon.warden(c).text]
   b.tooltip_text = tip
   b.disabled = not open
   if open:
    b.name = "DungeonRoom_%d_%d" % [r, i]
    var pulse = b.create_tween().set_loops(); pulse.set_trans(Tween.TRANS_SINE)
    pulse.tween_property(b, "modulate", Color(1.3, 1.25, 1.1), 0.8); pulse.tween_property(b, "modulate", Color.WHITE, 0.8)
    var col = i
    b.pressed.connect(func(): step(game, col))
 view.queue_redraw()

static func legend(game: Node, parent: Node) -> void:
 var row = HBoxContainer.new(); row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 20); parent.add_child(row)
 for key in ["battle", "elite", "event", "shop", "rest", "treasure", "boss"]:
  var info = Dungeon.ROOMS[key]; var item = HBoxContainer.new(); item.add_theme_constant_override("separation", 6); row.add_child(item)
  item.mouse_filter = Control.MOUSE_FILTER_STOP; item.tooltip_text = info.text
  FlowUI.glyph(item, str(info.glyph), 20)
  game.label(item, info.name, 14, Color(info.color), false).mouse_filter = Control.MOUSE_FILTER_IGNORE

# ------------------------------------------------------------------ Sidebar
static func sidebar(desk: ManagementDesk, stage: Control, c: Campaign) -> void:
 var game = desk.game; var d = c.state.dungeon; var accent = Color(Dungeon.depth(c).accent)
 var sw = W - SIDE_X
 # Next step
 var next = box_at(game, stage, Rect2(SIDE_X, 0, sw, 196), accent.darkened(0.2))
 next_card(desk, next, c, sw)
 # Relics
 var relics = box_at(game, stage, Rect2(SIDE_X, 206, sw, 150), Color("aa8c60"))
 text_at(game, relics, "RELICS  ·  %d" % Relics.owned(c).size(), Vector2(16, 10), 14, game.GOLD)
 if Relics.owned(c).is_empty():
  text_at(game, relics, "Elites, treasure, some events and every Warden offer relics. They last the whole run.", Vector2(16, 36), 14, game.MUTED, sw - 32)
 else:
  var grid = GridContainer.new(); grid.columns = 8; grid.add_theme_constant_override("h_separation", 6); grid.add_theme_constant_override("v_separation", 6); relics.add_child(grid); grid.position = Vector2(14, 36)
  for id in Relics.owned(c).slice(0, 16):
   var r = Relics.info(id)
   var slot = PanelContainer.new(); grid.add_child(slot); slot.custom_minimum_size = Vector2(46, 46)
   slot.add_theme_stylebox_override("panel", game.style(Color(.08, .06, .12, .95), rarity_color(r.rarity), 6, 2, 2))
   slot.tooltip_text = "%s · %s relic\n%s" % [r.name, r.rarity, r.text]; slot.mouse_filter = Control.MOUSE_FILTER_STOP
   AbilityArt.icon(slot, str(r.art), 40).mouse_filter = Control.MOUSE_FILTER_IGNORE
 # Run traits
 var traits = box_at(game, stage, Rect2(SIDE_X, 366, sw, 172), Color("6a8aa8"))
 text_at(game, traits, "RUN TRAITS  ·  YOUR SQUAD", Vector2(16, 10), 14, game.GOLD)
 var list = GridContainer.new(); list.columns = 2; list.add_theme_constant_override("h_separation", 24); list.add_theme_constant_override("v_separation", 2); traits.add_child(list); list.position = Vector2(16, 34)
 var shown = 0
 for row in RunTraits.summary(c, c.lineup()):
  if int(row.count) == 0 or shown >= 8: continue
  shown += 1
  var t = RunTraits.info(row.id); var lit = int(row.tier) >= 0
  var l = game.label(list, "%s%s  %d/%d" % ["● " if lit else "○ ", t.name, int(row.count), RunTraits.THRESHOLDS[mini(int(row.tier) + 1, RunTraits.THRESHOLDS.size() - 1)]], 15, Color(t.color) if lit else game.MUTED, false)
  l.mouse_filter = Control.MOUSE_FILTER_STOP; l.tooltip_text = trait_tooltip(row.id)
 if shown == 0: text_at(game, traits, "Draft champions that share a trait to unlock it.", Vector2(16, 36), 14, game.MUTED, sw - 32)
 # Tools
 var tools = HBoxContainer.new(); stage.add_child(tools); tools.position = Vector2(SIDE_X, 548); tools.size = Vector2(sw, 46); tools.add_theme_constant_override("separation", 6)
 for entry in [["Traits", func(): traits_modal(game)], ["Scores", func(): high_scores(game)], ["Vault (%d)" % TrophyVault.unopened(c).size(), func(): TournamentRewardsUI.open_screen(game, "vault")], ["Guide", func(): guide(game)]]:
  var b = desk.action(tools, entry[0], entry[1]); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; b.custom_minimum_size.y = 46

static func next_card(desk: ManagementDesk, card: Control, c: Campaign, sw: float) -> void:
 var game = desk.game; var d = c.state.dungeon
 var col = VBoxContainer.new(); card.add_child(col); col.position = Vector2(16, 12); col.size = Vector2(sw - 32, 200); col.add_theme_constant_override("separation", 6)
 if d.fight:
  var kind = str(Dungeon.node(c).type); var rival = c.opponent(); var info = Dungeon.ROOMS[kind]
  var head = HBoxContainer.new(); head.add_theme_constant_override("separation", 10); col.add_child(head)
  FlowUI.glyph(head, str(info.glyph), 30)
  game.label(head, str(info.name).to_upper(), 22, Color(info.color), false)
  var name_label = game.label(col, str(rival.name), 18, game.WHITE); name_label.custom_minimum_size.x = sw - 32
  var ours = League.team_power(c.lineup()); var theirs = League.team_power(rival.roster)
  game.label(col, "Power %d vs %d  ·  %s" % [ours, theirs, "lose a life and face it again" if kind == "boss" else "losing costs a life"], 14, game.MUTED)
  if kind == "boss":
   var mech = game.label(col, str(Bestiary.BOSSES[rival.boss].text), 13, Color("ffb3a8")); mech.custom_minimum_size.x = sw - 32
  var actions = HBoxContainer.new(); actions.add_theme_constant_override("separation", 6); col.add_child(actions)
  desk.action(actions, "Scout", func(): ScoutUI.open(game, rival))
  desk.action(actions, "Formation", func(): game.phase = "prep"; game.render())
  var go = FlowUI.cta(game, actions, "Fight  ▶", game.introduce_match, not c.lineup_ready() or not c.pending_heroes().is_empty(), 190)
  go.custom_minimum_size.y = 48; go.add_theme_font_size_override("font_size", 22)
  return
 game.label(col, "NEXT", 13, game.GOLD)
 if not Dungeon.reachable(c).is_empty():
  game.label(col, "Choose a glowing room on the map.", 20, game.WHITE)
  var preview = Dungeon.opponent(c)
  game.label(col, "Nearest fight ahead: %s · power %d" % [preview.name, League.team_power(preview.roster)], 14, game.MUTED)
 elif not d.loot.is_empty() or not d.event.is_empty():
  game.label(col, "Something waits in this room.", 20, game.WHITE)
  desk.action(col, "Open it", func(): game.render(), true)
 else:
  game.label(col, Dungeon.stage_label(c), 20, game.WHITE)
 var w = Dungeon.warden(c)
 var warden = game.label(col, "Warden of this depth: %s" % w.name, 14, Color("ffb3a8")); warden.custom_minimum_size.x = sw - 32
 warden.mouse_filter = Control.MOUSE_FILTER_STOP; warden.tooltip_text = str(w.text)
 if d.endless and not c.state.tour.get("complete", false) and not c.state.get("run_over", false):
  desk.action(col, "Retire · bank %d points" % Dungeon.final_score(c), func(): confirm_retire(game))

static func rarity_color(rarity: String) -> Color:
 return Color({"Common": "9fd4c6", "Rare": "8fb8ff", "Boss": "ffb35c"}.get(rarity, "ffffff"))

static func confirm_retire(game: Node) -> void:
 var c: Campaign = game.campaign
 var dialog = ConfirmationDialog.new(); game.ui.add_child(dialog)
 dialog.title = "Retire from the dungeon?"; dialog.dialog_text = "End the run now and bank %d points?" % Dungeon.final_score(c)
 dialog.confirmed.connect(func():
  if Dungeon.retire(c): game.render()
  else: game.toast(c.last_error))
 dialog.popup_centered(Vector2i(460, 160))

# ------------------------------------------------------------------ Overlays
static func overlay(game: Node, stage: Control) -> Control:
 var dim = ColorRect.new(); stage.add_child(dim); dim.size = Vector2(W, H); dim.color = Color(0.01, 0.01, 0.02, 0.78); dim.mouse_filter = Control.MOUSE_FILTER_STOP
 return dim

## The top of the stairs: two instances to choose from for the next depth.
static func path_overlay(game: Node, stage: Control, c: Campaign) -> void:
 var d = c.state.dungeon; var dim = overlay(game, stage)
 var act = int(d.act)
 var kicker = ("ENDLESS DEPTH %d" % (act - Dungeon.ACTS)) if act > Dungeon.ACTS else "DEPTH %d OF %d" % [act, Dungeon.ACTS]
 var title = text_at(game, dim, "CHOOSE YOUR PATH", Vector2(0, 6), 40, Color("ffe9b8"), W, true); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var sub = text_at(game, dim, kicker + ("  ·  New recruits wait in the Market before you go" if c.state.tour.get("intermission", false) else "  ·  Each instance has its own monsters, Warden and arena"), Vector2(0, 58), 15, game.MUTED, W)
 sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var choices: Array = d.instance_choices
 for i in range(choices.size()):
  var id = str(choices[i]); var info = DungeonInstances.info(id); var accent = Color(info.accent)
  var x = 64 + i * 724
  var card = box_at(game, dim, Rect2(x, 92, 696, 500), accent, Color(0.03, 0.03, 0.05, 0.98)); card.clip_contents = true
  painted(card, id, Rect2(0, 0, 696, 220), 0.75)
  var band = ColorRect.new(); card.add_child(band); band.position = Vector2(0, 150); band.size = Vector2(696, 70); band.color = Color(0, 0, 0, 0.55); band.mouse_filter = Control.MOUSE_FILTER_IGNORE
  text_at(game, card, str(info.name), Vector2(22, 158), 34, Color("ffe9b8"), 0.0, true)
  text_at(game, card, str(info.tagline), Vector2(22, 232), 16, Color(1, 1, 1, 0.85), 652)
  var boss = Bestiary.BOSSES[str(info.boss)]
  text_at(game, card, "WARDEN  ·  " + str(boss.name).to_upper(), Vector2(22, 286), 15, Color("ffb3a8"))
  text_at(game, card, str(boss.text), Vector2(22, 310), 14, game.MUTED, 652)
  text_at(game, card, "MONSTERS", Vector2(22, 372), 14, game.GOLD)
  var mobs = HBoxContainer.new(); card.add_child(mobs); mobs.position = Vector2(22, 396); mobs.add_theme_constant_override("separation", 8)
  for key in info.mobs:
   var m = Bestiary.MOBS[key]
   var chip = PanelContainer.new(); mobs.add_child(chip); chip.mouse_filter = Control.MOUSE_FILTER_STOP; chip.tooltip_text = str(m.text)
   chip.add_theme_stylebox_override("panel", game.style(Color(m.tint).darkened(0.65), Color(m.tint).lightened(0.2), 6, 6, 1))
   game.label(chip, str(m.name), 13, Color(m.tint).lightened(0.45), false)
  var go = FlowUI.cta(game, card, "Enter  ▶", func():
   if Dungeon.choose_instance(c, id):
    game.render(); FlowUI.banner(game, str(info.name).to_upper(), accent, kicker)
   else: game.toast(c.last_error), false, 300)
  go.position = Vector2(374, 432); go.name = "DungeonEnter_%d" % i

static func endless_overlay(game: Node, stage: Control, c: Campaign) -> void:
 var d = c.state.dungeon; var dim = overlay(game, stage)
 var card = box_at(game, dim, Rect2(274, 110, 1000, 380), Color("ffd36e"), Color(0.03, 0.03, 0.05, 0.98))
 var t = text_at(game, card, "THE DUNGEON IS CONQUERED", Vector2(0, 36), 44, Color("ffe9b8"), 1000, true); t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var s = text_at(game, card, "All three Wardens have fallen. Bank your score now, or go into the endless depths, where every depth is harder and worth more points. If you run out of lives there, the run ends where you fall.", Vector2(80, 120), 17, game.MUTED, 840)
 s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var row = HBoxContainer.new(); card.add_child(row); row.position = Vector2(140, 250); row.size = Vector2(720, 70); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 20)
 var bank = game.button(row, "Bank score · %d points" % Dungeon.final_score(c), func():
  if Dungeon.retire(c): game.render(); FlowUI.banner(game, "%d POINTS" % int(c.state.dungeon.final_score), Color("ffd36e"), "Score banked")
  else: game.toast(c.last_error), false)
 bank.custom_minimum_size = Vector2(300, 58); bank.name = "DungeonBankScore"
 FlowUI.cta(game, row, "Into the endless depths  ▶", func():
  if Dungeon.go_endless(c): game.render()
  else: game.toast(c.last_error), false, 380).name = "DungeonGoEndless"

static func end_overlay(game: Node, stage: Control, c: Campaign) -> void:
 var d = c.state.dungeon; var dim = overlay(game, stage)
 var fallen = c.state.get("run_over", false)
 var card = box_at(game, dim, Rect2(274, 90, 1000, 420), Color("ff8a7a") if fallen else Color("ffd36e"), Color(0.03, 0.03, 0.05, 0.98))
 var t = text_at(game, card, ("OUT OF LIVES" if fallen else "RUN COMPLETE"), Vector2(0, 30), 46, Color("ffcfb8") if fallen else Color("ffe9b8"), 1000, true)
 t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var score = text_at(game, card, "%d POINTS" % int(d.get("final_score", Dungeon.final_score(c))), Vector2(0, 100), 40, Color("9fd8ff"), 1000, true); score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var place = Dungeon.rank_of(c)
 var line = text_at(game, card, "%s  ·  reached %s  ·  %d Warden%s  ·  %d fights won  ·  %d relics%s" % [str(d.get("outcome", "Fallen" if fallen else "Conquered")), Dungeon.depth(c).name, int(d.wardens), "" if int(d.wardens) == 1 else "s", int(d.wins), d.relics.size(), ("  ·  #%d on your high scores" % place) if place > 0 else ""], Vector2(60, 170), 17, game.WHITE, 880)
 line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var route = text_at(game, card, "Route: " + "  →  ".join(d.get("visited", []).map(func(id): return DungeonInstances.info(id).name)), Vector2(60, 230), 14, game.MUTED, 880)
 route.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var row = HBoxContainer.new(); card.add_child(row); row.position = Vector2(200, 320); row.size = Vector2(600, 60); row.alignment = BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation", 16)
 game.button(row, "High scores", func(): high_scores(game)).custom_minimum_size = Vector2(220, 54)
 FlowUI.cta(game, row, "New dungeon run  ▶", func(): game.new_crest = {}; game.new_mode = "dungeon"; game.phase = "new"; game.render(), false, 320)

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
 var dialog = GearUI.modal(game, "The Dungeon", Vector2(1000, 660))
 for line in [
  "Three depths, each one an instance you choose at the top of the stairs: ten in all, from the Blight Forest to the Void Rift. Each has its own monsters, Warden boss and arena.",
  "Pick one room at a time along the glowing paths. Lives: losing a fight costs one; lose them all and the run ends. Campfires, healing springs and defeated Wardens restore them.",
  "Skirmishes reward one of three components. Treasure gives gold and one of three finished items. Elites give one of three relics.",
  "Wardens give a finished item, a powerful Warden relic and a medal chest.",
  "Relics are passive bonuses for the whole run. Some boost the whole team, some a line or your headliner, a few change the rules.",
  "Run traits: every species carries two traits, re-rolled each run. Field 2 or 4 different champions with the same trait to unlock its bonus.",
  "Score: rooms, wins, elites, Wardens and relics earn points, multiplied by the depth. Lives left add a bonus; difficulty and Ascension multiply the total.",
  "After the third Warden, bank your score or go into the endless depths, where each depth is harder and worth more.",
 ]: game.label(dialog.box, "•  " + line, 17, game.WHITE)
