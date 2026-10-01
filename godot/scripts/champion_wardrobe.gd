class_name ChampionWardrobe
extends RefCounted
static func build(desk: ManagementDesk) -> void:
 var game=desk.game;var c=game.campaign;var hero=GearUI.selected(game)
 var top=HBoxContainer.new();desk.body.add_child(top)
 var title=game.label(top,"YOUR CHAMPIONS",30);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 game.button(top,"Auto lineup",func():c.suggest_lineup();game.render(),false,c.state.roster.is_empty())
 game.button(top,"Formation",game.prepare_match,true,c.state.roster.size()<Campaign.MIN_SQUAD)
 game.button(top,"Recruit",func():desk.navigate("market"))
 if hero.is_empty():game.label(desk.body,"Recruit your first champion to begin.",25);return
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",14);desk.body.add_child(row)
 for h in c.lineup():champion(desk,row,h)
 for i in range(5-c.lineup().size()):
  var empty=FantasyFrame.new();empty.custom_minimum_size=Vector2(286,338);row.add_child(empty)
  var box=VBoxContainer.new();empty.add_child(box);game.label(box,"+",62,game.GOLD).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  game.button(box,"Recruit",func():desk.navigate("market"))
 var bench=c.state.roster.filter(func(h):return h.slot<0)
 if not bench.is_empty():
  var reserve=HBoxContainer.new();desk.body.add_child(reserve);game.label(reserve,"RESERVES",15,game.GOLD)
  for h in bench:
   var button=GearUI.hero_button(game,reserve,h,60,false)
   button.tooltip_text="Click to field or replace a starter. Drop gear here to equip."
   button.pressed.connect(func():desk.field_hero(h))
 var bag=FantasyFrame.new();desk.body.add_child(bag);var bag_box=VBoxContainer.new();bag.add_child(bag_box);bag_box.add_theme_constant_override("separation",6)
 GearUI.bag(game,bag_box,hero)
 var tools=HBoxContainer.new();desk.body.add_child(tools)
 game.label(tools,"Selected: "+hero.name,16,game.GOLD).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 game.button(tools,"Hero details",func():desk.profile(hero,true))
 game.button(tools,"Compare / stats",func():performance(desk))

static func champion(desk: ManagementDesk,parent: Node,h: Dictionary) -> void:
 var game=desk.game;var selected=h.id==game.selected_id
 var frame=FantasyFrame.new();frame.accent=game.GOLD if selected else SkillCombat.tint(h.sp);frame.custom_minimum_size=Vector2(286,360);parent.add_child(frame)
 frame.add_theme_stylebox_override("panel",game.style(Color(.09,.055,.16,.93),frame.accent,4,12,2))
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",6);frame.add_child(box)
 var name_label=game.label(box,h.name+" · "+str(h.level),24,game.GOLD if selected else game.WHITE);name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var preview_holder=GearToken.new();preview_holder.game=game;preview_holder.target_hero=h.id;preview_holder.custom_minimum_size=Vector2(258,172);box.add_child(preview_holder);preview_holder.name="Champion_"+h.id
 preview_holder.add_theme_stylebox_override("normal",StyleBoxEmpty.new());preview_holder.pressed.connect(func():game.selected_id=h.id;game.render())
 var preview=SplashArt.new();preview.sp=h.sp;preview_holder.add_child(preview);preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var role=game.label(box,HeroData.species[h.sp].n+"  ·  "+("★ " if Traits.is_ideal(h) else "")+Traits.trait_of(h),15,TraitUI.IDEAL if Traits.is_ideal(h) else game.MUTED);role.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;role.tooltip_text=Traits.describe(h)+"\n"+Traits.scaling_text(h.sp)+" · "+Traits.info(h.sp).calling
 var slots=HBoxContainer.new();slots.alignment=BoxContainer.ALIGNMENT_CENTER;slots.add_theme_constant_override("separation",12);box.add_child(slots)
 for key in GearUI.SLOT_KEYS:GearUI.slot(game,slots,h,key,62)
 var actions=HBoxContainer.new();actions.alignment=BoxContainer.ALIGNMENT_CENTER;box.add_child(actions)
 game.button(actions,"Tactics",func():game.show_tactics(h.id)).add_theme_font_size_override("font_size",14)
 game.button(actions,"Details",func():desk.profile(h,true)).add_theme_font_size_override("font_size",14)
 var bench=game.button(actions,"↓",func():game.campaign.bench(h.id);game.render());bench.tooltip_text="Move to reserves"

static func performance(desk: ManagementDesk) -> void:
 var dialog=desk.overlay("Champion statistics")
 var table=GridContainer.new();table.columns=6;table.add_theme_constant_override("h_separation",40);dialog.body.add_child(table)
 for title in ["HERO","LEVEL","POWER","KILLS","IMPACT / MATCH","COMPARE"]:desk.text(table,title,14,desk.GOLD)
 for h in desk.state.roster:
  desk.action(table,h.name,func():dialog.root.queue_free();desk.profile(h,true))
  desk.text(table,str(h.level));desk.text(table,str(HeroData.power(h)));desk.text(table,str(h.kills));desk.text(table,"%.1f"%(h.impact/maxf(1,h.bouts)))

  desk.action(table,"Selected" if h.id in desk.prefs.compare else "Select",func():
   if h.id in desk.prefs.compare:desk.prefs.compare.erase(h.id)
   else:
    if desk.prefs.compare.size()>=2:desk.prefs.compare.pop_front()
    desk.prefs.compare.append(h.id)
   dialog.root.queue_free();performance(desk))
 desk.action(dialog.body,"Compare selected",func():dialog.root.queue_free();desk.compare_heroes(),true,desk.prefs.compare.size()!=2)
