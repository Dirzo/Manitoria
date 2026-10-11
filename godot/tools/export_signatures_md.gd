extends SceneTree
## Prints the champion list (signature, mana, builds, evolutions) as markdown from Signatures.DATA.
func _init() -> void:
	HeroData.load_data()
	var groups = [["Frontline", ["minotaur","golem","troll","wendigo","cerberus","nemean","yeti","zaratan","owlbear","hydra"]],
		["Flank", ["direwolf","manticore","griffin","kitsune","gargoyle","nekomata","jackalope","chimera"]],
		["Back line", ["wyvern","harpy","phoenix","kirin","basilisk","treant","naga","unicorn","cyclops","thunderbird","sphinx","pegasus","arachne","salamander"]]]
	for g in groups:
		var out = "### %s\n\n" % g[0]
		for sp in g[1]:
			var d = Signatures.of(sp)
			var text = Signatures.fill(str(d.text), {}, {}).replace("true damage", "**true damage**")
			out += "**%s — %s** · %s · Mana %d/%d · Builds: %s\n%s" % [HeroData.species[sp].n, d.name, HeroData.species[sp].role, d.mana[0], d.mana[1], d.builds, text]
			if d.has("passive"): out += " *Passive:* " + str(d.passive)
			out += "\n\n"
			for e in d.evos: out += "- *%s* (%s): %s\n" % [e.name, e.tag, Signatures.fill(str(e.text), {}, {})]
			out += "\n"
		print("@@GROUP@@"); print(out.strip_edges())
	quit()
