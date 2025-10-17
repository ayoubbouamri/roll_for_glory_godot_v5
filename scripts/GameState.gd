extends Node
# Global state carried between scenes

const TEAM_SIZE_MIN := 3
const TEAM_SIZE_MAX := 10
const STARTING_HEARTS := 2

var team_a_size: int = 5
var team_b_size: int = 5

# Each roster entry: {name: String, icon: String, color: Color, attack: "melee"|"ranged", alive: bool}
var roster_a: Array = []
var roster_b: Array = []

# Hearts are shared per team (used by Revive)
var hearts_a: int = STARTING_HEARTS
var hearts_b: int = STARTING_HEARTS

# Character pool (emoji + style). This mirrors the technical sheet concept.
var CHARACTER_POOL := [
    {"icon":"@","name":"Rogue","color": Color(0.23,0.62,0.95), "attack":"melee"},
    {"icon":"^","name":"Archer","color": Color(0.16,0.80,0.44), "attack":"ranged"},
    {"icon":"&","name":"Knight","color": Color(0.90,0.20,0.31), "attack":"melee"},
    {"icon":"*","name":"Mage","color": Color(0.57,0.44,0.84), "attack":"ranged"},
    {"icon":"+","name":"Sorcerer","color": Color(0.98,0.78,0.18), "attack":"ranged"},
    {"icon":"#","name":"Fighter","color": Color(0.95,0.63,0.13), "attack":"melee"},
    {"icon":"~","name":"Ranger","color": Color(0.17,0.63,0.55), "attack":"ranged"}
]

var SAMPLE_NAMES := ["Aiden","Bella","Cairo","Dina","Eli","Faye","Gio","Hana","Ivan","Jade","Kian","Lia","Moe","Nia","Omar","Pia","Quin","Ria","Sam","Tia"]

func _ready() -> void:
	pass

func ensure_rosters() -> void:
	# If empty, auto-generate simple rosters using pool
	if roster_a.is_empty():
		roster_a = []
		for i in range(team_a_size):
			var c: Dictionary = CHARACTER_POOL[i % CHARACTER_POOL.size()]
			roster_a.append({
				"name": "%s %d" % [SAMPLE_NAMES[i % SAMPLE_NAMES.size()], i + 1],
				"icon": c["icon"], "color": c["color"], "attack": c["attack"], "alive": true
			})
	if roster_b.is_empty():
		roster_b = []
		for i in range(team_b_size):
			var c: Dictionary = CHARACTER_POOL[(i + 2) % CHARACTER_POOL.size()]
			roster_b.append({
				"name": "%s %d" % [SAMPLE_NAMES[(i + 7) % SAMPLE_NAMES.size()], i + 1],
				"icon": c["icon"], "color": c["color"], "attack": c["attack"], "alive": true
			})

func reset_hearts() -> void:
	hearts_a = STARTING_HEARTS
	hearts_b = STARTING_HEARTS

func deep_clone(val):
	# Basic deep copy for Arrays/Dictionaries
	if typeof(val) == TYPE_ARRAY:
		var out := []
		for v in val: out.append(deep_clone(v))
		return out
	elif typeof(val) == TYPE_DICTIONARY:
		var d := {}
		for k in val.keys(): d[k] = deep_clone(val[k])
		return d
	else:
		return val

func build_launch_payload() -> Dictionary:
	ensure_rosters()
	var payload := {
		"team_a_size": team_a_size,
		"team_b_size": team_b_size,
		"roster_a": deep_clone(roster_a),
		"roster_b": deep_clone(roster_b),
		"hearts_a": hearts_a,
		"hearts_b": hearts_b
	}
	return payload

func reset_all() -> void:
	roster_a.clear()
	roster_b.clear()
	reset_hearts()
