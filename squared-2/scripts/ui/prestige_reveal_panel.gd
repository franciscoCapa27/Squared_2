extends PanelContainer
class_name PrestigeRevealPanel

const SquareButtonScene = preload("res://scenes/squares/SquareButton.tscn")

@onready var trait_label: Label = %TraitLabel
@onready var square_container: Control = %SquareContainer
@onready var title_label: Label = %TitleLabel

var display_square_button: SquareButton = null


func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	_apply_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _apply_theme() -> void:
	add_theme_stylebox_override("panel", ThemeSystem.make_card_style())
	if trait_label:
		ThemeTextHelper.apply_body_label(trait_label)
	if title_label:
		ThemeTextHelper.apply_body_label(title_label)


func _on_theme_changed() -> void:
	_apply_theme()


func setup_data(trait_family: String, trait_rarity: String, square_title: String, target_square_id: String) -> void:
	trait_label.text = "%s - %s" % [trait_family, trait_rarity]
	title_label.text = square_title

	_clear_square()

	var btn := SquareButtonScene.instantiate() as SquareButton
	btn.setup(target_square_id)
	btn.disabled = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.custom_minimum_size = Vector2(64, 64)
	btn.size = Vector2(64, 64)
	square_container.add_child(btn)
	display_square_button = btn


func _clear_square() -> void:
	if display_square_button and is_instance_valid(display_square_button):
		display_square_button.queue_free()
	display_square_button = null
	for child in square_container.get_children():
		child.queue_free()
