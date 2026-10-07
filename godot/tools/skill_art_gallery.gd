extends SceneTree
func _initialize() -> void:
 call_deferred("build")
func build() -> void:
 var window=get_root();window.size=Vector2i(1280,720)
 var base=ColorRect.new();base.color=Color("10131d");base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);window.add_child(base)
 var entries=[]
 var dir=DirAccess.open("res://art-progress")
 for file in dir.get_files():
  if file.ends_with(".json"):entries.append(JSON.parse_string(FileAccess.get_file_as_string("res://art-progress/"+file)))
 entries.sort_custom(func(a,b):return a.id.naturalnocasecmp_to(b.id)<0)
 var champions=[]
 for entry in entries:
  var sp=entry.id.split(":")[0]
  if not champions.has(sp):champions.append(sp)
 var pages=champions.size()
 for page in range(pages):
  var grid=GridContainer.new();grid.columns=6;grid.position=Vector2(15,15);grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",10);window.add_child(grid)
  for entry in entries.filter(func(e):return e.id.split(":")[0]==champions[page]):
   var col=VBoxContainer.new();col.custom_minimum_size=Vector2(196,210);grid.add_child(col)
   var image=TextureRect.new();image.texture=load("res://assets/abilities/"+entry.file);image.custom_minimum_size=Vector2(196,180);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;col.add_child(image)
   var parts=entry.id.split(":")
   var label=Label.new();label.text=SkillScaling.audited(parts[0],parts[1]).name+"\n"+entry.id;label.add_theme_font_size_override("font_size",12);col.add_child(label)
  await process_frame;await process_frame
  await RenderingServer.frame_post_draw
  window.get_texture().get_image().save_png("res://../../skill-art-%s.png"%champions[page])
  grid.queue_free();await process_frame
 print("Rendered ",entries.size()," icons across ",pages," gallery pages")
 quit()
