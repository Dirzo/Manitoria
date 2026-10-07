extends SceneTree
## Run with -- --qa=tour_shop, in an isolated APPDATA directory.
var checks = 0
var failures = 0

func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures += 1; push_error(message)

func _init() -> void:
 call_deferred("run")

func capture(path: String) -> void:
 await RenderingServer.frame_post_draw
 get_root().get_texture().get_image().save_png(path)

func run() -> void:
 var game = load("res://scripts/main.gd").new()
 get_root().add_child(game); game.qa = ""
 await create_timer(0.8).timeout
 var carousel = game.ui.find_child("ChampionCarousel", true, false)
 check(carousel != null and carousel.entries.size() == 5, "Shop shows all five champions")
 var centered = carousel.entries.filter(func(e): return e.offset == 0)[0]
 check(centered.target.target_hero == game.selected_id and centered.root.scale.y > 1.3, "Selected champion is centered and enlarged")
 check(carousel.entries.filter(func(e): return e.offset != 0).all(func(e): return e.root.scale.y < 0.8 and e.root.position.z < 0), "Other champions recede into the background")
 await capture("user://shop-preview.png")
 var next_id = carousel.heroes[1].id
 carousel.rotate(1)
 await create_timer(0.6).timeout
 carousel = game.ui.find_child("ChampionCarousel", true, false)
 check(game.selected_id == next_id and GearUI.selected(game).id == next_id, "Rotation changes the actual equipment recipient")
 check(carousel.entries.filter(func(e): return e.offset == 0)[0].target.target_hero == next_id, "Rotated hero steps into the foreground")
 await capture("user://shop-rotated-preview.png")
 # Buy two compatible components onto the newly featured champion, then unequip.
 var hero = GearUI.selected(game); hero.equipment = {}
 game.campaign.state.tour.stock[0] = "fang"; game.campaign.state.tour.stock[1] = "ember"
 var before = game.campaign.state.gold
 var price = Forge.info("fang").price + Forge.info("ember").price
 check(GearUI.apply_drop(game, {"kind":"offer", "id":"fang", "index":0}, hero.id), "Shop offer buys and equips on the featured champion")
 check(GearUI.apply_drop(game, {"kind":"offer", "id":"ember", "index":1}, hero.id), "Second component forges on the featured champion")
 var made = Forge.combine("fang", "ember")
 check(made in hero.equipment.values() and game.campaign.state.gold == before - price, "Forging preserves inventory and charges the two component prices")
 check(game.campaign.state.tour.stock[0] == "" and game.campaign.state.tour.stock[1] == "", "Purchased offers remain sold")
 var slot = str(hero.equipment.find_key(made))
 check(GearUI.apply_drop(game, {"kind":"equipped", "owner":hero.id, "slot":slot, "id":made}, "", "", true), "Unequip drop still returns gear to the bag")
 check(made in game.campaign.state.inventory and hero.equipment.is_empty(), "Bag receives the forged item")
 var bag_button=game.ui.find_child("ShopBagButton",true,false)
 check(bag_button!=null and bag_button.text.begins_with("● NEW"),"New bag contents highlight the button")
 GearUI.open_bag(game)
 check(game.campaign.state.bag_seen==game.campaign.state.inventory,"Opening bag acknowledges its new items")
 var other=game.campaign.state.roster.filter(func(h):return h.id!=hero.id)[0]
 hero.equipment={"0":"archmage","1":"crown","2":"bell"}
 other.equipment={"0":"bastion","1":"quiver","2":"lifebloom"}
 var data={"kind":"equipped","owner":hero.id,"slot":"0","id":"archmage"}
 check(GearUI.can_drop(game,data,other.id,"0"),"Full champions accept an explicit slot swap")
 check(GearUI.apply_drop(game,data,other.id,"0"),"Occupied slot swap succeeds")
 check(hero.equipment["0"]=="bastion" and other.equipment["0"]=="archmage","Swap exchanges both items without losing gear")
 game.campaign.state.report={"rows":[],"winner":0,"opponent":"QA rival","duration":32.0}
 for i in range(game.campaign.state.roster.size()):
  var h=game.campaign.state.roster[i]
  game.campaign.state.report.rows.append({"team":0,"name":h.name,"damage":1000+i*350,"cc":i*1.5,"healing":i*200,"taken":700+i*150,"alive":true})
 game.render();await create_timer(0.6).timeout
 var graphs=game.ui.find_child("ShopGraphs",true,false)
 check(graphs!=null and graphs.find_children("*","LastRoundGraph",true,false).size()==1,"Four last-round graphs replace the bottom bag panel")
 await capture("user://shop-updated-preview.png")
 GearUI.manage_team(game);await create_timer(0.3).timeout
 await capture("user://shop-swap-preview.png")
 game.render()
 var fit_dialog=GearUI.modal(game,"Draft · Fit description",Vector2(850,400))
 var fit_hero=HeroData.make_hero("harpy","fit-qa","Long description",1)
 for key in HeroData.ROLL_KEYS:fit_hero.rolls[key]=25
 var fit_table=DraftBoard.table(game,fit_dialog.box,[fit_hero],func(_h):return {},[["Champion","Board",200],["Power","Power",74],["Fit","Fit",200],["Cost","Price",66]])
 await create_timer(0.3).timeout
 var fit_description=fit_table.find_child("FitDescription",true,false)
 check(fit_description!=null and fit_description.get_line_count()>1 and fit_description.size.x<=200,"Long Fit descriptions wrap inside their column")
 check(fit_description!=null and fit_description.size.y>=44 and fit_description.get_global_rect().end.y<=fit_description.get_parent().get_parent().get_global_rect().end.y,"Wrapped Fit description has visible space inside its row")
 await capture("user://fit-column-preview.png")
 game.render()
 game.phase = "prep"; game.render()
 await create_timer(0.6).timeout
 check(game.arena.get_node("HexFloor").multimesh.instance_count > 50, "Arena renders an instanced hex floor")
 for unit in game.sim.units:
  check(unit.pos.is_equal_approx(ArenaGrid.formation_position(unit.hero.slot, unit.team)), "Preview models use the same hex placement as combat")
 await capture("user://arena-preview.png")
 game.campaign.state.tour.cup_started=true;game.phase="hub";game.tab="roster";game.render()
 await create_timer(0.4).timeout
 check(not game.ui.find_children("*","Button",true,false).any(func(button):return button.text.contains("Recruit") or button.text=="Market"),"Recruitment controls disappear during a cup")
 game.tab="market";game.render();await create_timer(0.2).timeout
 check(game.ui.find_children("*","Label",true,false).any(func(label):return label.text.to_upper().contains("ROSTER LOCKED")),"Direct market navigation shows the cup roster lock")
 game.campaign.state.tour.intermission=true;game.campaign.state.tour.intermission_seen=true;game.render()
 await create_timer(0.3).timeout
 check(game.ui.find_children("*","Button",true,false).any(func(button):return button.text=="Market"),"Recruitment returns between cups")
 print("Shop/carousel: %d checks, %d failures" % [checks, failures])
 game.sound.stop_all(); game.queue_free(); await process_frame
 quit(1 if failures else 0)
