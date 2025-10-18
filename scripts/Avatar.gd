extends Node2D
signal clicked_me

var data := { "name":"", "icon":"", "color": Color.WHITE, "attack":"melee", "alive": true, "team":"A" }

@onready var icon_label: Label = $Icon
@onready var ring: ColorRect = $Ring
@onready var active_rect: ColorRect = $Active
@onready var hit_area: Area2D = $HitArea

var _hover := false
var _idle_tween: SceneTreeTween

func setup(d: Dictionary, team: String) -> void:
	data = d.duplicate(true)
	data["team"] = team
	icon_label.text = "%s" % d.get("icon", "?")
	modulate = d.get("color", Color.WHITE)
	_set_alive(d.get("alive", true))
	if hit_area:
		hit_area.mouse_entered.connect(_on_mouse_enter)
		hit_area.mouse_exited.connect(_on_mouse_exit)
		hit_area.input_event.connect(_on_hit_input)
	_start_idle()

func _set_alive(al: bool) -> void:
	data["alive"] = al
	visible = true
	icon_label.self_modulate = Color.WHITE if al else Color(1,1,1,0.3)
	ring.color = Color(0.2,1.0,0.3,0.5) if al else Color(0.3,0.3,0.3,0.3)

func mark_dead() -> void:
	_set_alive(false)
	_stop_idle()

func mark_alive() -> void:
	_set_alive(true)
	_start_idle()

func set_active(on: bool) -> void:
	if active_rect:
		active_rect.visible = on
	ring.color = Color(1.0, 0.9, 0.2, 0.55) if on and data.get("alive", true) else (Color(0.2,1.0,0.3,0.5) if data.get("alive", true) else Color(0.3,0.3,0.3,0.3))

func is_alive() -> bool:
	return bool(data.get("alive", true))

func get_team() -> String:
	return String(data.get("team", "A"))

func get_display_name() -> String:
	return String(data.get("name", ""))

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked_me", self)

func _on_hit_input(_vp, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked_me", self)

func _on_mouse_enter():
	_hover = true
	_apply_hover()

func _on_mouse_exit():
	_hover = false
	_apply_hover()

func _apply_hover():
	var target := 1.08 if _hover and data.get("alive", true) else 1.0
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(target, target), 0.08)

func _start_idle():
	_stop_idle()
	if not data.get("alive", true):
		return
	_idle_tween = create_tween()
	_idle_tween.set_loops()
	_idle_tween.tween_property(self, "position:y", position.y + 3.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "position:y", position.y - 3.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_idle():
	if is_instance_valid(_idle_tween):
		_idle_tween.kill()
