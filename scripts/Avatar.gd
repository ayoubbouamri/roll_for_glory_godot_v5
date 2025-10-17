extends Node2D
signal clicked_me

var data := { "name":"", "icon":"", "color": Color.WHITE, "attack":"melee", "alive": true, "team":"A" }

@onready var icon_label: Label = $Icon
@onready var ring: ColorRect = $Ring

func setup(d: Dictionary, team: String) -> void:
    data = d.duplicate(true)
	data["team"] = team
	icon_label.text = "%s" % d.get("icon","🙂")
	modulate = d.get("color", Color.WHITE)
	_set_alive(d.get("alive", true))

func _set_alive(al: bool) -> void:
    data["alive"] = al
    visible = true
    icon_label.self_modulate = Color.WHITE if al else Color(1,1,1,0.3)
    ring.color = Color(0.2,1.0,0.3,0.5) if al else Color(0.3,0.3,0.3,0.3)

func mark_dead() -> void:
	_set_alive(false)

func mark_alive() -> void:
    _set_alive(true)

func is_alive() -> bool:
	return bool(data.get("alive", true))

func get_team() -> String:
	return String(data.get("team", "A"))

func get_display_name() -> String:
	return String(data.get("name", ""))

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked_me", self)
