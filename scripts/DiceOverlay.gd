extends Window
signal roll_finished(success: bool, rolled: int)

var picks := []
var buttons := []

@onready var grid: GridContainer = $VBox/Grid
@onready var result_label: Label = $VBox/Result
@onready var roll_btn: Button = $VBox/Roll

func _ready() -> void:
	_build_grid()
	roll_btn.disabled = true
	roll_btn.pressed.connect(_on_roll2)

func _build_grid():
	# Clear previous number buttons safely (replace broken queue_free_children)
	for c in grid.get_children():
		c.queue_free()
	buttons.clear()
	picks.clear()
	for i in range(1,7):
		var b := Button.new()
		b.text = str(i)
		b.toggle_mode = true
		b.toggled.connect(func(on): _on_toggle(i, on))
		grid.add_child(b)
		buttons.append(b)

func _on_toggle(num: int, on: bool) -> void:
	if on:
		if picks.size() >= 3:
			# prevent more than 3
			for b in buttons:
				if int(b.text) not in picks:
					b.button_pressed = false
			return
		picks.append(num)
	else:
		picks.erase(num)
	roll_btn.disabled = picks.size() != 3
	result_label.text = "Selected: %s" % (",".join(picks.map(func(x): return str(x))))

func open_and_get_result():
	_build_grid()
	result_label.text = "Pick three numbers."
	roll_btn.disabled = true
	popup_centered()

func _on_roll2():
    # 3-second animated roll preview
    var spinner := ["◐","◓","◑","◒"]
    for i in range(15): # 15 * 0.2s = 3.0s
        var preview := randi_range(1,6)
        result_label.text = "Rolling %s  %d" % [spinner[i % spinner.size()], preview]
        await get_tree().create_timer(0.2).timeout
    var rolled := randi_range(1,6)
    var ok := rolled in picks
    result_label.text = "Rolled %d - %s" % [rolled, ("SUCCESS" if ok else "FAIL")]
    await get_tree().create_timer(0.5).timeout
    hide()
    emit_signal("roll_finished", ok, rolled)
