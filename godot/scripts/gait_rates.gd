class_name GaitRates
## Ground speed (world units / s) at which each creature's walk loop keeps its feet planted at
## animation speed 1.0. Measured from the walk clips by tools/gait_probe.gd (flyers / naga: move speed).
const PLANT := {
	"arachne": 1.839,
	"basilisk": 1.684,
	"cerberus": 2.031,
	"chimera": 1.973,
	"cyclops": 1.905,
	"direwolf": 2.813,
	"gargoyle": 2.683,
	"golem": 1.797,
	"griffin": 2.138,
	"harpy": 4.176,
	"hydra": 1.443,
	"jackalope": 2.499,
	"kirin": 2.170,
	"kitsune": 2.082,
	"manticore": 2.301,
	"minotaur": 2.328,
	"naga": 3.236,
	"nekomata": 1.816,
	"nemean": 2.182,
	"owlbear": 2.166,
	"pegasus": 2.629,
	"phoenix": 3.445,
	"salamander": 1.524,
	"sphinx": 1.976,
	"thunderbird": 3.863,
	"treant": 1.819,
	"troll": 2.022,
	"unicorn": 2.333,
	"wendigo": 2.336,
	"wyvern": 1.761,
	"yeti": 1.873,
	"zaratan": 1.287,
}

static func walk_rate(sp: String, ground_speed: float) -> float:
	return clampf(ground_speed / PLANT.get(sp, 2.0), 0.35, 2.6)
