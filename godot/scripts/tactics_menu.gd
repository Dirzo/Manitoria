class_name TacticsMenu
extends Control

var game: Node
var hero_id = ""
var status_label: Label

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 build()

func build() -> void:
 for child in get_children(): remove_child(child); child.queue_free()
 var h = game.campaign.hero_by_id(hero_id)
 var shade = ColorRect.new(); shade.color = Color(0.015, 0.03, 0.05, 0.97); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(shade)
 var shell = PanelContainer.new(); shell.position = Vector2(100, 45); shell.size = Vector2(1400, 810); add_child(shell)
 shell.add_theme_stylebox_override("panel", game.style(Color("10232e"), Color("9b885e"), 16, 24))
 var body = VBoxContainer.new(); body.add_theme_constant_override("separation", 12); shell.add_child(body)
 var heading = HBoxContainer.new(); body.add_child(heading)
 var portrait = SplashArt.make(heading, h.sp, Vector2(96, 120))
 var identity = VBoxContainer.new(); identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL; heading.add_child(identity)
 game.label(identity, "BATTLE ORDERS  /  %s" % HeroData.species[h.sp].role.to_upper(), 13, game.GOLD)
 game.label(identity, h.name + " · " + HeroData.species[h.sp].n, 30)
 game.label(identity, "Choose how this hero fights. Orders are saved with your campaign.", 16, game.MUTED)
 game.button(heading, "Done  ×", func(): queue_free(); game.render(), true)
 var heroes = HBoxContainer.new(); body.add_child(heroes)
 var choices = game.campaign.lineup()
 if h not in choices: choices.append(h)
 for other in choices:
  var b = game.button(heroes, other.name, func(): hero_id = other.id; build(), other.id == hero_id)
  b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 var presets = HBoxContainer.new(); body.add_child(presets)
 game.label(presets, "QUICK SETUP", 13, game.GOLD, false)
 for key in BattleTactics.PRESETS:
  game.button(presets, key, func():
   if game.campaign.set_tactics(hero_id, BattleTactics.PRESETS[key]): build()
   else: status_label.text = game.campaign.last_error)
 var scroll = ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; body.add_child(scroll)
 var grid = GridContainer.new(); grid.columns = 3; grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL; grid.add_theme_constant_override("h_separation", 16); grid.add_theme_constant_override("v_separation", 14); scroll.add_child(grid)
 var settings = BattleTactics.for_hero(h)
 for field in BattleTactics.FIELDS:
  var panel = PanelContainer.new(); panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; panel.custom_minimum_size = Vector2(0, 147); grid.add_child(panel)
  panel.add_theme_stylebox_override("panel", game.style(Color("182f3b"), Color("365462"), 10, 14))
  var col = VBoxContainer.new(); panel.add_child(col)
  game.label(col, field[1].to_upper(), 13, game.GOLD)
  var picker = OptionButton.new(); picker.name = "Tactic_" + field[0]; picker.custom_minimum_size.y = 38; picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL; col.add_child(picker)
  for title in field[3]: picker.add_item(title)
  picker.selected = field[2].find(settings[field[0]])
  var explanation = game.label(col, field[4][picker.selected], 14, game.MUTED)
  picker.item_selected.connect(func(index):
   var values = BattleTactics.for_hero(h); values[field[0]] = field[2][index]
   if game.campaign.set_tactics(hero_id, values):
    explanation.text = field[4][index]; status_label.text = "Saved · " + h.name + " · " + BattleTactics.summary(h)
   else:
    picker.selected = field[2].find(BattleTactics.for_hero(h)[field[0]]); status_label.text = game.campaign.last_error)
 status_label = game.label(body, "Saved · " + h.name + " · " + BattleTactics.summary(h), 15, game.GOLD)

func _input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled(); queue_free(); game.render()
