extends Button

signal square_clicked(square_id: String)

var square_id: String = ""
var is_respawning: bool = false
var respawn_timer: SceneTreeTimer = null

func setup(id: String, display_text: String = "■") -> void:
	square_id = id
	text = display_text
	tooltip_text = "Square %s" % square_id
	_reset_visual_state()

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if is_respawning:
		return

	square_clicked.emit(square_id)

	var square_data := GameState.get_square(square_id)
	var respawn_time := 1.0

	if square_data != null:
		respawn_time = SquareCalculator.calculate_respawn_time(square_data)

	_start_respawn(respawn_time)

func _start_respawn(respawn_time: float) -> void:
	is_respawning = true
	disabled = true
	modulate = Color(1, 1, 1, 0.25)
	text = "."

	respawn_timer = get_tree().create_timer(respawn_time)
	await respawn_timer.timeout

	_finish_respawn()

func _finish_respawn() -> void:
	is_respawning = false
	disabled = false
	respawn_timer = null
	_reset_visual_state()

func _reset_visual_state() -> void:
	text = "■"
	modulate = Color(1, 1, 1, 1)
