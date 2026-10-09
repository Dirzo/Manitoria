extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> void:
 await create_timer(.35).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("user://"+name+".png")
func run() -> void:
 var game=load("res://scripts/main.gd").new();root.add_child(game);await create_timer(.6).timeout
 # Since 0.75 the speedrun lab lives under Statistics & achievements.
 game.ui.find_child("StatsMenuButton",true,false).pressed.emit();await process_frame
 check(game.ui.find_child("SpeedrunlabButton",true,false)!=null,"Menu has speedrun entry")
 game.start_speedrun();await process_frame
 var c: Campaign=game.campaign;c.choose_starter(League.tiers().Legendary[0]);c.recruit(c.state.market.filter(func(h):return League.tier(h.sp)=="Epic")[0].id)
 for i in range(3):c.recruit(c.state.market.filter(func(h):return League.tier(h.sp)=="Common")[0].id)
 check(c.lineup_ready() and c.state.speedrun_lab,"Uses the normal paid draft")
 game.introduce_match();await process_frame
 check(game.phase=="speedrun","Draft CTA routes directly into planner")
 check(game.ui.find_child("SpeedrunSimulate",true,false)!=null,"Simulate button visible")
 check(game.ui.find_children("*","FormationCell",true,false).size()==15,"Planner exposes fifteen deployment hexes")
 var lab: SpeedrunLab=game.speedrun_lab
 for h in c.lineup():
  lab.plan.goals[h.id]="Ability power" if SkillScaling.audited(h.sp,"signature").get("build_path","ap")=="ap" else "Attack damage"
  for id in Forge.recommended(h.sp,h):lab.plan.items.append({"id":id,"target":h.id})
 game.render();await capture("speedrun-planner-073")
 check(lab.plan.items.size()==15,"Suggested team priority list shown")
 check(game.ui.find_child("ShopChampionCopy",true,false)==null,"No copy purchase in planner")
 var saved=JSON.parse_string(FileAccess.get_file_as_string(SpeedrunLab.RESULTS_PATH))
 if saved is Array and saved.any(func(r):return r.complete):
  lab.result=saved.filter(func(r):return r.complete)[0];lab.status="Completed benchmark · saved database result";game.render();await capture("speedrun-results-073")
  check(game.ui.find_children("*","StatHex",true,false).size()==5,"Final squad stat hexes shown")
  SpeedrunUI.cup_detail(game,lab.result.cups[0],lab.result.matches.filter(func(m):return int(m.cup)==1));await capture("speedrun-cup-detail-073")
 else:check(false,"Saved benchmark available for results UI")
 # Cancellation is tested at the real coroutine boundary.
 game.phase="speedrun";lab.result={};lab.start();await process_frame;lab.cancelled=true
 while lab.running:await process_frame
 check(lab.result.cancelled and not lab.result.complete,"Cancel returns partial results without completing a run")
 var original_heroes=game.campaign.lineup().map(func(h):return h.id)
 game.resume_speedrun();await process_frame
 check(game.phase=="speedrun" and game.campaign.lineup().map(func(h):return h.id)==original_heroes,"Saved lab draft resumes with the same champions")
 check(game.speedrun_lab.plan.items.size()==15,"Saved priority list restores after resuming")
 check(FileAccess.file_exists("user://speedrun_draft.json"),"Lab draft saved separately")
 check(not FileAccess.file_exists(Campaign.save_path(1)),"Regular campaign slot untouched")
 game.sound.stop_all();game.queue_free();await process_frame
 print("SPEEDRUN UI: %d checks; %d failures"%[checks,failures]);quit(1 if failures else 0)
