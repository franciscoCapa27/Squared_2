extends PanelContainer
class_name PassivePanel

signal passive_generator_upgraded(generator_id: String)

@onready var passive_generator_list: VBoxContainer = %PassiveGeneratorList
@onready var passive_title: Label = %PassiveTitle
@onready var passive_margin: MarginContainer = %PassiveMargin
@onready var passive_v_box: VBoxContainer = %PassiveVBox


var passive_generator_card_scene: PackedScene = preload("res://scenes/ui/PassiveGeneratorCard.tscn")
var passive_generator_cards: Dictionary = {}


func _ready() -> void:
	PassiveSystem.passive_state_changed.connect(_on_passive_state_changed)
	
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	_apply_theme()
	refresh()
	


func refresh() -> void:
	var unlocked_generators: Array[PassiveGeneratorInstance] = PassiveSystem.get_unlocked_generator_instances()

	if unlocked_generators.is_empty():
		if passive_generator_cards.is_empty() and passive_generator_list.get_child_count() > 0:
			return

		_rebuild_passive_generator_list()
		return

	if unlocked_generators.size() != passive_generator_cards.size():
		_rebuild_passive_generator_list()
		return

	for generator_instance: PassiveGeneratorInstance in unlocked_generators:
		var card: PassiveGeneratorCard = passive_generator_cards.get(generator_instance.get_id()) as PassiveGeneratorCard

		if card == null:
			_rebuild_passive_generator_list()
			return

		card.refresh()


func _rebuild_passive_generator_list() -> void:
	for child: Node in passive_generator_list.get_children():
		child.queue_free()

	passive_generator_cards.clear()

	var unlocked_generators: Array[PassiveGeneratorInstance] = PassiveSystem.get_unlocked_generator_instances()

	if unlocked_generators.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No passive systems unlocked.\n\nBuy Traits and spend Vertices to awaken automation."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		passive_generator_list.add_child(empty_label)
		return
	PassiveSystem.refresh_visible_generator_discoveries()
	for generator_instance: PassiveGeneratorInstance in unlocked_generators:
		if not PassiveSystem.should_show_generator(generator_instance.definition.id):
			continue
		var card: PassiveGeneratorCard = passive_generator_card_scene.instantiate() as PassiveGeneratorCard
		passive_generator_list.add_child(card)

		card.setup(generator_instance.get_id())
		card.upgrade_requested.connect(_on_passive_generator_upgrade_requested)

		passive_generator_cards[generator_instance.get_id()] = card


func _on_passive_generator_upgrade_requested(generator_id: String) -> void:
	var upgraded: bool = PassiveSystem.upgrade_generator(generator_id)

	if not upgraded:
		refresh()
		return

	refresh()
	passive_generator_upgraded.emit(generator_id)


func _on_passive_state_changed() -> void:
	refresh()

func _apply_theme() -> void:
	add_theme_stylebox_override("panel", ThemeSystem.make_panel_style())

	ThemeLayoutHelper.apply_margin(passive_margin, "inner_margin")
	ThemeLayoutHelper.apply_box_separation(passive_v_box, "card_gap")

	ThemeTextHelper.apply_panel_title(passive_title)

	passive_title.clip_text = true
	passive_title.autowrap_mode = TextServer.AUTOWRAP_OFF


func _on_theme_changed() -> void:
	_apply_theme()
