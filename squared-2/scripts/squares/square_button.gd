extends Button
class_name SquareButton

signal square_clicked(square_id: String)

var square_id: String = ""
var is_respawning: bool = false
var respawn_timer: SceneTreeTimer = null
var normal_modulate: Color = Color.WHITE
var trait_purchase_reveal_label: RichTextLabel = null
var trait_purchase_reveal_tween: Tween = null
var trait_purchase_reveal_layer: CanvasLayer = null

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

	var square_data: SquareData = GameState.get_square(square_id)
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


func play_trait_purchase_reveal(
	trait_family_display: String,
	trait_rarity_display: String,
	previous_square_title: String,
	new_square_title: String
) -> void:
	_show_trait_purchase_reveal_text(
		trait_family_display,
		trait_rarity_display,
		previous_square_title,
		new_square_title
	)

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


func _show_trait_purchase_reveal_text(
	trait_family_display: String,
	trait_rarity_display: String,
	previous_square_title: String,
	new_square_title: String
) -> void:
	if trait_purchase_reveal_tween and trait_purchase_reveal_tween.is_valid():
		trait_purchase_reveal_tween.kill()
	if trait_purchase_reveal_label and is_instance_valid(trait_purchase_reveal_label):
		trait_purchase_reveal_label.queue_free()
	if trait_purchase_reveal_layer and is_instance_valid(trait_purchase_reveal_layer):
		trait_purchase_reveal_layer.queue_free()

	var reveal_label := RichTextLabel.new()
	reveal_label.bbcode_enabled = true
	reveal_label.fit_content = false
	reveal_label.scroll_active = false
	reveal_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_label.anchor_right = 1.0
	reveal_label.anchor_bottom = 1.0
	reveal_label.offset_left = 5.0
	reveal_label.offset_top = 5.0
	reveal_label.offset_right = -5.0
	reveal_label.offset_bottom = -5.0
	reveal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reveal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reveal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ThemeTextHelper.apply_body_rich_text(reveal_label)
	reveal_label.add_theme_font_size_override("normal_font_size", 11)
	reveal_label.text = _build_trait_purchase_reveal_text(
		trait_family_display,
		trait_rarity_display,
		previous_square_title,
		new_square_title
	)
	reveal_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	trait_purchase_reveal_layer = CanvasLayer.new()
	trait_purchase_reveal_layer.layer = 50
	get_tree().root.add_child(trait_purchase_reveal_layer)
	trait_purchase_reveal_layer.add_child(reveal_label)
	reveal_label.position = get_global_rect().position
	reveal_label.size = get_global_rect().size
	trait_purchase_reveal_label = reveal_label

	trait_purchase_reveal_tween = create_tween()
	trait_purchase_reveal_tween.tween_property(reveal_label, "modulate:a", 1.0, 0.2)
	trait_purchase_reveal_tween.tween_interval(2.0)
	trait_purchase_reveal_tween.tween_property(reveal_label, "modulate:a", 0.0, 0.6)
	trait_purchase_reveal_tween.tween_callback(func():
		if is_instance_valid(reveal_label):
			reveal_label.queue_free()
		if trait_purchase_reveal_layer and is_instance_valid(trait_purchase_reveal_layer):
			trait_purchase_reveal_layer.queue_free()
		if trait_purchase_reveal_layer == null or not is_instance_valid(trait_purchase_reveal_layer):
			trait_purchase_reveal_layer = null
		if trait_purchase_reveal_label == reveal_label:
			trait_purchase_reveal_label = null
	)


func _build_trait_purchase_reveal_text(
	trait_family_display: String,
	trait_rarity_display: String,
	_previous_square_title: String,
	_new_square_title: String
) -> String:
	var rarity: String = trait_rarity_display.to_lower()
	var rarity_color: String = ThemeTextHelper.get_rarity_color_hex(rarity)
	var family_color: String = ThemeTextHelper.get_trait_family_color_hex(trait_family_display)

	return "[center][color=%s][font_size=10]%s[/font_size][/color]\n[color=%s][font_size=12]%s[/font_size][/color][/center]" % [
		rarity_color,
		rarity,
		family_color,
		trait_family_display
	]
