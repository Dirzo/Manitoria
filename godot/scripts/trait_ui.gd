class_name TraitUI
extends RefCounted
## Temperament and scaling readouts. The species' perfect role and ideal temperaments are gold;
## a champion whose own temperament is one of its ideals shows that in gold too.
const IDEAL := Color("ffd36e")

static func line(game: Node, parent: Node, hero: Dictionary, compact := false) -> void:
	var t = Traits.trait_of(hero); var data = Traits.TRAITS[t]; var ideal = Traits.is_ideal(hero)
	var box = VBoxContainer.new(); box.add_theme_constant_override("separation", 1); parent.add_child(box)
	var head = game.label(box, ("★ " if ideal else "") + t.to_upper() + ("  ·  IDEAL" if ideal else ""), 13, IDEAL if ideal else Color("c9d6dc"), false)
	head.tooltip_text = Traits.describe(hero)
	if not compact:
		game.label(box, "%s  /  %s" % [data.up, data.down], 12, Color("9fb0b8"), true)
	var s = Traits.score(hero)
	var curve = game.label(box, "%s scaler %d/10  ·  %s" % [Traits.scaling_type(s), int(round(s)), Traits.info(hero.sp).calling], 12, IDEAL, true)
	curve.tooltip_text = "Scaling: early scalers are strongest in the first cups and fade; late scalers start weaker and grow. At level %d this champion fights at %d%% of par." % [int(hero.level), roundi(Traits.curve(hero) * 100)]
	if not compact:
		game.label(box, "Ideal temperaments: " + " · ".join(Traits.info(hero.sp).ideal), 12, IDEAL, true)

static func species_line(game: Node, parent: Node, sp: String) -> void:
	var info = Traits.info(sp)
	game.label(parent, "%s  ·  %s" % [Traits.scaling_text(sp), info.calling], 13, IDEAL, true)
	game.label(parent, "Ideal: " + " · ".join(info.ideal), 12, IDEAL, true)
