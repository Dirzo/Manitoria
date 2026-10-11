extends SceneTree
var checks = 0
var failures = 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures += 1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var game = load("res://scripts/main.gd").new(); root.add_child(game)
 await create_timer(.5).timeout
 var c: Campaign = game.campaign
 for hero in c.state.roster: hero.pending = []; hero.rewards = []
 c.state.tour.shop = false
 game.phase = "hub"; game.tab = "roster"; game.render()
 var d = c.state.dungeon
 d.fight = false; d.loot = []; d.loot_queue = []; d.event = {}; d.instance_choices = []
 Dungeon.offer_draft(c, "checkpoint", 0)
 var offered_ids = d.draft.offers.map(func(hero): return hero.id)
 check(c.save(), "Blocked room persists successfully")
 var loaded = Campaign.new()
 check(loaded.load_slot(int(c.state.slot)), "Existing blocked save loads")
 check(loaded.state.dungeon.draft.offers.map(func(hero): return hero.id) == offered_ids, "Reload preserves the exact champion offers")
 c.state = loaded.state; d = c.state.dungeon
 var band = Control.new(); game.ui.add_child(band)
 DungeonUI.next_card(game, band, c)
 var reopen = band.find_child("DungeonRoomContinue",true,false)
 check(reopen != null and not reopen.disabled, "Closed champion draft has a usable map continuation")
 check(Dungeon.reachable(c).is_empty(), "Unresolved draft still blocks walking past the room")
 if reopen != null:
  reopen.pressed.emit(); await process_frame
  var dialog = game.ui.find_child("DungeonDraftDialog",true,false)
  check(dialog != null, "Continuation reopens current champion offer")
  if dialog: dialog.queue_free(); await process_frame
  reopen.pressed.emit(); await process_frame
  check(game.ui.find_child("DungeonDraftDialog",true,false) != null, "Closing and reopening a second time also works")
  check(Dungeon.skip_draft(c), "Passing on reopened draft settles it")
  check(not Dungeon.reachable(c).is_empty(), "Path unlocks after settling champion choice")
 d.draft = {}; d.fight = true
 var rng = RandomNumberGenerator.new(); rng.seed = 42
 c.gain_xp(c.lineup()[0], 1000, true, true, rng)
 check(not c.pending_heroes().is_empty(), "Fixture has a pending level choice inside a fight room")
 band = Control.new(); game.ui.add_child(band); DungeonUI.next_card(game, band, c)
 var level_button = band.find_child("DungeonLevelUps",true,false)
 check(level_button != null and not level_button.disabled, "Fight room exposes enabled level-up continuation")
 if level_button:
  level_button.pressed.emit(); await process_frame
  check(game.phase == "upgrade", "Map continuation opens skill choices")
  var guard = 0
  while not c.pending_heroes().is_empty() and guard < 100:
   check(c.choose(c.pending_heroes()[0].id,0), "Pending skill choice resolves"); guard += 1
  game.build_upgrade(); await process_frame
  check(game.phase == "hub", "Final skill choice returns to map")
  var prepare = game.ui.find_child("DungeonPrepareFight",true,false)
  check(prepare != null and not prepare.disabled, "Fight can be prepared after level choices")
  if prepare:
   prepare.pressed.emit(); await process_frame
   check(game.phase == "prep", "Fight resumes at equipment and formation")
 # Reopening other blockers must preserve their contents, not skip the room.
 for kind in ["loot", "event"]:
  d = c.state.dungeon; d.fight = false; d.draft = {}
  d.event = Dungeon.EVENTS[1].duplicate(true) if kind == "event" else {}
  d.loot = []; d.loot_queue = []
  if kind == "loot": Dungeon.offer_loot(c,"component")
  game.phase = "hub"; game.tab = "roster"; game.render()
  band = Control.new(); game.ui.add_child(band); DungeonUI.next_card(game,band,c)
  var action = band.find_child("DungeonRoomContinue",true,false)
  check(action != null and not action.disabled, kind + " has a continuation")
  if action:
   action.pressed.emit(); await process_frame
   check(game.ui.find_child("DungeonLootDialog" if kind == "loot" else "DungeonEventDialog",true,false) != null, kind + " continuation reopens the modal")
 game.sound.stop_all(); game.queue_free(); await process_frame
 print("DUNGEON CONTINUATION: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
