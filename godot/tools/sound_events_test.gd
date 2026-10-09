extends SceneTree
## Death layers and gold income sounds load and play without errors.
var failures=0
func check(ok: bool,msg: String) -> void:
 if not ok:failures+=1;push_error(msg)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://scripts/main.gd").new();root.add_child(game)
 await create_timer(1.0).timeout;game.qa=""
 var s: SoundDesign=game.sound
 for k in ["gold_clink_1","gold_clink_4","gold_payout","fall_light_1","fall_heavy_3","fall_boss"]:check(s.cache.has(k),"Loaded "+k)
 var before=s.played_cues
 s.gold(40);await create_timer(0.4).timeout
 check(s.played_cues>=before+2,"Small income plays climbing clinks")
 before=s.played_cues;s.gold(300);await create_timer(0.1).timeout
 check(s.last_cue=="gold_payout","Big income plays the payout")
 var hero=HeroData.make_hero("golem","g","G",5)
 before=s.played_cues;s.death_layers({"uid":3,"hero":hero},0.0);await create_timer(0.2).timeout
 check(s.played_cues>=before+2,"A death plays a body fall and a cry")
 var boss=HeroData.make_hero("treant","b","Rootmother",8);boss.monster="rootmother"
 s.death_layers({"uid":4,"hero":boss,"boss":true},0.0);await process_frame
 check(s.played_cues>before+2,"A Warden death plays the long fall")
 for zone in ["magma_depths","drowned_sanctum","blight_forest"]:
  check(SoundDesign.has_ambience(zone),zone+" has an ambience bed")
 s.set_ambience("magma_depths");await create_timer(1.6).timeout
 check(s.ambience_name=="magma_depths" and s.ambience_player.playing,"Zone ambience plays")
 s.sweetener_in=0.0;var c=s.played_cues;s._tick_ambience(0.1)
 check(s.played_cues>c,"Zone sweeteners play")
 s.set_ambience("");await create_timer(1.5).timeout
 check(not s.ambience_player.playing,"Ambience stops outside the zone")
 print("SOUND EVENTS: 16 checks, ",failures," failures")
 quit(1 if failures else 0)
