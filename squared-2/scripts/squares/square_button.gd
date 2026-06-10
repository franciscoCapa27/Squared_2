extends Button
class_name SquareButton

signal square_clicked(square_id: String)

var square_id: String = ""
var is_respawning: bool = false
var respawn_timer: SceneTreeTimer = null
var normal_modulate: Color = Color.WHITE

func setup(id: String, display_text: String = "■") -> void:
	square_id = id
	text = display_text
	tooltip_text = "Square %s" % square_id
	_apply_square_visuals()
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

func refresh_visuals() -> void:
	_apply_square_visuals()
	if not is_respawning:
		_reset_visual_state()

func _apply_square_visuals() -> void:
	var square_data: SquareData = GameState.get_square(square_id)

	if square_data == null:
		normal_modulate = Color.WHITE
		return

	normal_modulate = square_data.visual_profile.base_color

func _start_respawn(respawn_time: float) -> void:
	is_respawning = true
	disabled = true
	modulate = Color(normal_modulate.r, normal_modulate.g, normal_modulate.b, 0.25)
	text = "·"

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
	modulate = normal_modulate

func set_square_data(p_square_data: SquareData) -> void:
	var square_data := GameState.get_square(square_id)
	square_data = p_square_data
	_apply_square_visuals()
