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
 check(s.played_cues==before,"Small income stays silent")
 before=s.played_cues;s.gold(300);await create_timer(0.1).timeout
 check(s.played_cues==before,"Big income stays silent")
 var hero=HeroData.make_hero("golem","g","G",5)
 before=s.played_cues;s.death_layers({"uid":3,"hero":hero},0.0);await create_timer(0.2).timeout
 check(s.played_cues==before,"A death stays silent")
 var boss=HeroData.make_hero("treant","b","Rootmother",8);boss.monster="rootmother"
 s.death_layers({"uid":4,"hero":boss,"boss":true},0.0);await process_frame
 check(s.played_cues==before,"A Warden death stays silent")
 for zone in DungeonInstances.ORDER:
  check(SoundDesign.has_ambience(zone) and SoundDesign.SWEETENERS.has(zone) and SoundDesign.SWEETENERS[zone].all(func(k):return s.cache.has(k)),zone+" has an ambience bed and sweeteners")
 s.set_ambience("magma_depths");await create_timer(1.6).timeout
 check(s.ambience_name=="magma_depths" and not s.ambience_player.playing,"Zone ambience stays silent")
 s.sweetener_in=0.0;var c=s.played_cues;s._tick_ambience(0.1)
 check(s.played_cues==c,"Zone sweeteners stay silent")
 s.set_ambience("");await create_timer(1.5).timeout
 check(not s.ambience_player.playing,"Ambience stops outside the zone")
 print("SOUND EVENTS: 23 checks, ",failures," failures")
 quit(1 if failures else 0)
