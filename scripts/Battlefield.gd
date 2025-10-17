extends Node2D
const Avatar := preload("res://scenes/Avatar.tscn")

enum Phase { CHOOSE_ACTION, SELECT_TARGETS, RESOLVING, GAME_OVER }

@onready var kill_btn: Button = %KillBtn
@onready var double_btn: Button = %DoubleBtn
@onready var revive_btn: Button = %ReviveBtn
@onready var status_label: Label = $UI/Status
@onready var team_a_label: Label = %TeamALabel
@onready var team_b_label: Label = %TeamBLabel
@onready var hearts_a_label: Label = %HeartsA
@onready var hearts_b_label: Label = %HeartsB
@onready var turn_label: Label = %TurnLabel
@onready var dice: Window = $Dice

var team_a: Array[Node2D] = []
var team_b: Array[Node2D] = []
var current_team := "A" # "A" or "B"
var phase := Phase.CHOOSE_ACTION
var pending_action := ""
var pending_kill_targets := 0

func _ready() -> void:
	_spawn_teams()
	current_team = "A"
	_update_ui()
	_connect_buttons()


func _connect_buttons() -> void:
	# KILL
	kill_btn.pressed.connect(func():
		if phase != Phase.CHOOSE_ACTION:
			return
		pending_action = "KILL"
		pending_kill_targets = 1
		status_label.text = "Select 1 enemy to KILL."
		phase = Phase.SELECT_TARGETS
	)

	# DOUBLE-KILL
	double_btn.pressed.connect(func():
		if phase != Phase.CHOOSE_ACTION:
			return
		pending_action = "DOUBLE"
		dice.open_and_get_result()
		var sig = await dice.roll_finished
        var ok: bool = sig[0]
        var _rolled: int = sig[1]
		if ok:
			pending_kill_targets = 2
			status_label.text = "SUCCESS: Select up to 2 enemies to kill."
			phase = Phase.SELECT_TARGETS
		else:
			status_label.text = "FAILED: Acting hero dies!"
			_kill_acting_random()
			_end_turn()
	)

	# REVIVE
	revive_btn.pressed.connect(func():
		if phase != Phase.CHOOSE_ACTION:
			return
		if not _team_has_dead(current_team):
			status_label.text = "No fallen allies to revive."
			return
		if _team_hearts(current_team) <= 0:
			status_label.text = "No hearts left."
			return
		pending_action = "REVIVE"
		status_label.text = "Select 1 fallen ally to REVIVE (consumes a heart)."
		phase = Phase.SELECT_TARGETS
	)


func _spawn_teams() -> void:
	var payload := GameState.build_launch_payload()
	# Arrange positions
	var left := Rect2(Vector2(140, 160), Vector2(360, 400))
	var right := Rect2(Vector2(780, 160), Vector2(360, 400))
	for d in payload["roster_a"]:
		var a: Node2D = Avatar.instantiate()
		add_child(a)
		a.position = left.position + Vector2(randi() % int(left.size.x), randi() % int(left.size.y))
		a.call("setup", d, "A")
		a.connect("clicked_me", Callable(self, "_on_avatar_clicked2"))
		team_a.append(a)
	for d in payload["roster_b"]:
		var b: Node2D = Avatar.instantiate()
		add_child(b)
		b.position = right.position + Vector2(randi() % int(right.size.x), randi() % int(right.size.y))
		b.call("setup", d, "B")
		b.connect("clicked_me", Callable(self, "_on_avatar_clicked2"))
		team_b.append(b)

	_update_ui()

func _update_ui() -> void:
	team_a_label.text = "Team A (%d alive)" % _living_count("A")
	team_b_label.text = "Team B (%d alive)" % _living_count("B")
	turn_label.text = "Turn: Team %s" % current_team
	# Override hearts display with a robust builder (avoids broken glyphs)
	hearts_a_label.text = _hearts(GameState.hearts_a)
	hearts_b_label.text = _hearts(GameState.hearts_b)
	_update_buttons_state()
	_check_win()

func _update_buttons_state():
	var can_revive := _team_has_dead(current_team) and _team_hearts(current_team) > 0
	revive_btn.disabled = not can_revive
	kill_btn.disabled = false
	double_btn.disabled = false

func _on_avatar_clicked2(av):
	if phase != Phase.SELECT_TARGETS:
		return
	match pending_action:
		"KILL":
			if av.get_team() == current_team: return
			if not av.is_alive(): return
			status_label.text = "KILL: %s" % av.get_display_name()
			_play_kill(av)
			pending_kill_targets -= 1
			if pending_kill_targets <= 0:
				_end_turn()
		"DOUBLE":
			if av.get_team() == current_team: return
			if not av.is_alive(): return
			status_label.text = "DOUBLE-KILL: %s" % av.get_display_name()
			_play_kill(av)
			pending_kill_targets -= 1
			if pending_kill_targets <= 0:
				_end_turn()
		"REVIVE":
			if av.get_team() != current_team: return
			if av.is_alive(): return
			status_label.text = "REVIVE: %s" % av.get_display_name()
			_play_revive(av)
			_consume_heart(current_team)
			_end_turn()

func _kill_acting_random() -> void:
	# If failure on Double, random acting hero dies (closest to center for simplicity)
	var team := team_a if current_team == "A" else team_b
	var candidates := []
	for a in team:
		if a.is_alive():
			candidates.append(a)
	if candidates.is_empty():
		return
	var victim = candidates[randi()%candidates.size()]
	_play_kill(victim)

func _play_kill(av):
	av.call("mark_dead")
	_update_ui()

func _play_revive(av):
	av.call("mark_alive")
	_update_ui()

func _end_turn():
	phase = Phase.RESOLVING
	await get_tree().create_timer(0.4).timeout
	if _check_win(): return
	current_team = "B" if current_team == "A" else "A"
	phase = Phase.CHOOSE_ACTION
	pending_action = ""
	pending_kill_targets = 0
	status_label.text = "Choose an action."
	_update_ui()

func _check_win() -> bool:
	var a_alive := _living_count("A")
	var b_alive := _living_count("B")
	if a_alive <= 0 and b_alive <= 0:
		_game_over("Draw! Both teams fell.")
		return true
	if a_alive <= 0:
		_game_over("Team B wins!")
		return true
	if b_alive <= 0:
		_game_over("Team A wins!")
		return true
	return false

func _game_over(msg: String):
	phase = Phase.GAME_OVER
	status_label.text = msg + "  (Click here to Restart)"
	kill_btn.disabled = true
	double_btn.disabled = true
	revive_btn.disabled = true
	$UI/Status.mouse_filter = Control.MOUSE_FILTER_STOP
	$UI/Status.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			get_tree().change_scene_to_file("res://scenes/SetupMenu.tscn")
	)

func _living_count(team: String) -> int:
	var arr := team_a if team == "A" else team_b
	var n := 0
	for a in arr:
		if a.is_alive(): n += 1
	return n

func _team_has_dead(team: String) -> bool:
	var arr := team_a if team == "A" else team_b
	for a in arr:
		if not a.is_alive(): return true
	return false

func _team_hearts(team: String) -> int:
	return GameState.hearts_a if team == "A" else GameState.hearts_b

func _consume_heart(team: String) -> void:
	if team == "A":
		GameState.hearts_a = max(0, GameState.hearts_a - 1)
	else:
		GameState.hearts_b = max(0, GameState.hearts_b - 1)
	_update_ui()

func _hearts(n: int) -> String:
	var s := ""
	for _i in range(n):
		s += "\u2665" # '♥'
	return s
