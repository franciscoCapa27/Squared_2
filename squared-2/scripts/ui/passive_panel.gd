extends PanelContainer
class_name PassivePanel

signal passive_generator_upgraded(generator_id: String)

@onready var passive_generator_list: VBoxContainer = %PassiveGeneratorList

var passive_generator_card_scene: PackedScene = preload("res://scenes/ui/PassiveGeneratorCard.tscn")
var passive_generator_cards: Dictionary = {}


func _ready() -> void:
	PassiveSystem.passive_state_changed.connect(_on_passive_state_changed)
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
		empty_label.text = "No passive systems unlocked.\n\nPrestige and spend Vertices to awaken automation."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		passive_generator_list.add_child(empty_label)
		return

	for generator_instance: PassiveGeneratorInstance in unlocked_generators:
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
