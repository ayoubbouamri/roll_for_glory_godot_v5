extends Control

@onready var spin_a: SpinBox = %SpinA
@onready var spin_b: SpinBox = %SpinB
@onready var play_btn: Button = %Play

func _ready() -> void:
	spin_a.value = GameState.team_a_size
	spin_b.value = GameState.team_b_size
	%Randomize.pressed.connect(_on_randomize)
	play_btn.pressed.connect(_on_play)

func _on_randomize() -> void:
	# Clear rosters so GameState.ensure_rosters() regenerates
	GameState.roster_a.clear()
	GameState.roster_b.clear()

func _on_play() -> void:
	GameState.team_a_size = int(spin_a.value)
	GameState.team_b_size = int(spin_b.value)
	GameState.reset_hearts()
	GameState.build_launch_payload()
	get_tree().change_scene_to_file("res://scenes/Battlefield.tscn")
