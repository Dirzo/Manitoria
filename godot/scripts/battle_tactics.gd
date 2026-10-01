class_name BattleTactics
extends RefCounted

# Stable keys are saved per hero; labels and explanations belong to the UI.
const FIELDS = [
 ["posture", "Approach", ["balanced", "aggressive", "guard"], ["Balanced", "Aggressive", "Guard allies"], ["Fight at the natural distance for this kit.", "Close in and keep pressing the selected enemy.", "Prioritize enemies threatening your nearby ranged allies."]],
 ["target", "Target priority", ["natural", "weakest", "backline", "healers", "threat", "tanks"], ["Natural", "Wounded", "Back line", "Healers", "Highest threat", "Front line"], ["Use this creature's natural instincts and nearest threats.", "Favor low-health enemies within a practical pursuit distance.", "Favor ranged enemies; fall back to the nearest available foe.", "Favor enemies with healing abilities.", "Favor enemies with high attack damage per second.", "Favor tanks and bruisers to break their front line."]],
 ["teamwork", "Teamwork", ["independent", "assist"], ["Independent", "Focus together"], ["Choose targets independently.", "Favor the enemy already targeted by nearby allies."]],
 ["distance", "Fighting distance", ["natural", "close", "kite"], ["Natural", "Close pressure", "Keep distance"], ["Use the kit's normal fighting distance.", "Ranged heroes move closer before attacking.", "Ranged heroes retreat between attacks when enemies close in. Melee heroes use their normal reach."]],
 ["persistence", "Target persistence", ["adaptive", "committed"], ["Adaptive", "Committed"], ["Reassess priorities as the fight changes.", "Keep the current enemy until it dies, hides or moves too far away. Taunts still override orders."]],
 ["opening", "Opening move", ["advance", "hold", "flank", "lurk"], ["Advance", "Hold for 3 seconds", "Flank", "Lurk, then dive"], ["Advance directly from the chosen formation.", "Let enemies approach for three seconds; attack and cast if they enter reach.", "Approach around the outer edge for the first four seconds, until an enemy is in reach.", "Wait on the flank while the front lines clash (4 to 8 seconds), then dive the enemy back line and open with your signature."]],
 ["area", "Area abilities", ["any", "cluster"], ["Any target", "Wait for a cluster"], ["Use area abilities as soon as they are ready.", "Wait up to two seconds for at least two enemies in the area, then cast anyway."]],
 ["healing", "Heal priority", ["wounded", "front", "self"], ["Most wounded", "Frontliners first", "Self first"], ["Heal allies with the lowest health percentage first.", "Favor injured frontliners; still heal other injured allies.", "Favor yourself when injured; otherwise heal wounded allies."]],
 ["abilities", "Ability order", ["signature", "learned"], ["Signature first", "Learned abilities first"], ["When multiple abilities are ready, try the signature first.", "Try learned abilities before the signature. Each keeps its own cooldown."]]
]
const PRESETS = {
 "Natural": {},
 "Vanguard": {"posture": "guard", "target": "tanks", "persistence": "committed"},
 "Hunter": {"posture": "aggressive", "target": "backline", "opening": "flank", "persistence": "committed"},
 "Assassin": {"posture": "aggressive", "target": "backline", "opening": "lurk", "persistence": "committed", "abilities": "signature"},
 "Artillery": {"target": "weakest", "distance": "kite", "area": "cluster", "teamwork": "assist"},
 "Support": {"posture": "guard", "distance": "kite", "opening": "hold", "healing": "front"}
}

static func normalized(raw: Variant) -> Dictionary:
 var result = {}
 for field in FIELDS:
  var value = raw.get(field[0], field[2][0]) if raw is Dictionary else field[2][0]
  result[field[0]] = value if value in field[2] else field[2][0]
 return result

static func for_hero(hero: Dictionary) -> Dictionary:
 return normalized(hero.get("tactics", {}))

static func summary(hero: Dictionary) -> String:
 var t = for_hero(hero); var parts = []
 for field in FIELDS.slice(0, 2): parts.append(field[3][field[2].find(t[field[0]])])
 return " · ".join(parts)
