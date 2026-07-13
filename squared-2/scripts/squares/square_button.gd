extends Button
class_name SquareButton

signal square_clicked(square_id: String)

var square_id: String = ""
var is_respawning: bool = false
var respawn_timer: SceneTreeTimer = null
var normal_modulate: Color = Color.WHITE

## A tween dedicated to the quick press/compression animation on manual click.
var press_tween: Tween

func setup(id: String) -> void:
	square_id = id
	_apply_square_visuals()
	_reset_visual_state()

func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	pressed.connect(_on_pressed)

	_apply_theme()

func _apply_theme() -> void:
	add_theme_stylebox_override("normal", ThemeSystem.make_card_style())
	add_theme_stylebox_override("hover", ThemeSystem.make_selected_card_style())
	add_theme_stylebox_override("pressed", ThemeSystem.make_selected_card_style())
	add_theme_stylebox_override("disabled", ThemeSystem.make_card_style())

	add_theme_color_override("font_color", ThemeSystem.get_color("text_secondary"))
	add_theme_color_override("font_hover_color", ThemeSystem.get_color("text_primary"))
	add_theme_color_override("font_pressed_color", ThemeSystem.get_color("text_primary"))
	add_theme_color_override("font_disabled_color", ThemeSystem.get_color("text_muted"))


func _on_theme_changed() -> void:
	_apply_theme()

func _on_pressed() -> void:
	if is_respawning:
		return

	square_clicked.emit(square_id)

	var square_data := GameState.get_square(square_id)
	var respawn_time := 1.0

	if square_data != null:
		respawn_time = SquareCalculator.calculate_respawn_time(square_data)

	_play_press_animation()
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

func _play_press_animation() -> void:
	# Kill any previous animation that is still running so the scale state is clean.
	if press_tween and press_tween.is_valid():
		press_tween.kill()
	scale = Vector2.ONE

	press_tween = create_tween().set_parallel(false)
	# Squash slightly
	press_tween.tween_property(self, "scale", Vector2(0.92, 0.92), 0.05).set_ease(Tween.EASE_IN)
	# Spring back
	press_tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_OUT)


func _start_respawn(respawn_time: float) -> void:
	is_respawning = true
	disabled = true
	modulate = Color(normal_modulate.r, normal_modulate.g, normal_modulate.b, 0.25)

	respawn_timer = get_tree().create_timer(respawn_time)
	await respawn_timer.timeout

	_finish_respawn()

func _finish_respawn() -> void:
	is_respawning = false
	disabled = false
	respawn_timer = null
	_reset_visual_state()

func _reset_visual_state() -> void:
	modulate = normal_modulate

func set_square_data(p_square_data: SquareData) -> void:
	var square_data := GameState.get_square(square_id)
	square_data = p_square_data
	_apply_square_visuals()
	
func apply_responsive_visual_size(_square_size: float) -> void:
	# Body is textless; no visual scaling needed beyond layout.
	pass


func play_prestige_reveal() -> void:
	if is_respawning:
		return

	# Quick scale pulse and slight brighten
	if press_tween and press_tween.is_valid():
		press_tween.kill()
	scale = Vector2.ONE

	var tw := create_tween().set_parallel(false)
	tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_IN)

	var old_mod := modulate
	tw.parallel().tween_property(self, "modulate", old_mod * 1.3, 0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate", old_mod, 0.3).set_ease(Tween.EASE_IN)
