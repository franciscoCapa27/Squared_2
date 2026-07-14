extends PanelContainer
class_name RunUpgradesPanel

@onready var run_upgrade_list: VBoxContainer = %RunUpgradeList
@onready var run_upgrades_margin: MarginContainer = %RunUpgradesMargin
@onready var run_upgrades_v_box: VBoxContainer = %RunUpgradesVBox

var run_upgrade_card_scene: PackedScene = preload("res://scenes/ui/RunUpgradeCard.tscn")
var run_upgrade_cards: Dictionary = {}
var visible_upgrade_ids: Array[String] = []
var refresh_is_queued: bool = false


func _ready() -> void:
	visible_upgrade_ids = []

	ThemeSystem.theme_changed.connect(_on_theme_changed)
	_apply_theme()

	EventBus.squares_changed.connect(_on_squares_changed)
	EventBus.trait_purchase_changed.connect(_on_trait_purchase_changed)
	EventBus.grid_changed.connect(_on_grid_changed)

	AchievementSystem.achievements_changed.connect(_on_achievements_changed)
	PassiveSystem.passive_state_changed.connect(_on_passive_state_changed)
	RunUpgradeSystem.run_upgrades_changed.connect(_on_run_upgrades_changed)

	refresh()


func _apply_theme() -> void:
	add_theme_stylebox_override("panel", ThemeSystem.make_panel_style())

	ThemeLayoutHelper.apply_margin(run_upgrades_margin, "inner_margin")
	ThemeLayoutHelper.apply_box_separation(run_upgrades_v_box, "card_gap")


func _on_theme_changed() -> void:
	_apply_theme()
	_queue_refresh()


func refresh() -> void:
	refresh_is_queued = false

	_rebuild_if_needed()

	for upgrade_id: String in run_upgrade_cards.keys():
		var card: RunUpgradeCard = run_upgrade_cards.get(upgrade_id) as RunUpgradeCard

		if card == null:
			continue

		card.refresh()


func _queue_refresh() -> void:
	if refresh_is_queued:
		return

	refresh_is_queued = true
	call_deferred("refresh")


func _rebuild_if_needed() -> void:
	var new_visible_upgrade_ids: Array[String] = _get_visible_upgrade_ids()

	if _arrays_are_equal(visible_upgrade_ids, new_visible_upgrade_ids):
		return

	_rebuild_list(new_visible_upgrade_ids)


func _rebuild_list(new_visible_upgrade_ids: Array[String]) -> void:
	for child: Node in run_upgrade_list.get_children():
		child.queue_free()

	run_upgrade_cards.clear()
	visible_upgrade_ids = new_visible_upgrade_ids

	for upgrade_id: String in visible_upgrade_ids:
		var upgrade: RunUpgradeDefinition = RunUpgradeDatabase.get_upgrade(upgrade_id)

		if upgrade == null:
			continue

		var card: RunUpgradeCard = run_upgrade_card_scene.instantiate() as RunUpgradeCard
		run_upgrade_list.add_child(card)

		card.setup(upgrade)
		card.buy_requested.connect(_on_buy_requested)

		run_upgrade_cards[upgrade.id] = card


func _get_visible_upgrade_ids() -> Array[String]:
	var result: Array[String] = []

	RunUpgradeSystem.refresh_visible_run_upgrade_discoveries()

	for upgrade: RunUpgradeDefinition in RunUpgradeDatabase.get_all_upgrades():
		if upgrade == null:
			continue

		if not RunUpgradeSystem.should_show_run_upgrade(upgrade.id):
			continue

		result.append(upgrade.id)

	return result


func _arrays_are_equal(left: Variant, right: Variant) -> bool:
	if not left is Array:
		return false

	if not right is Array:
		return false

	var left_array: Array = left as Array
	var right_array: Array = right as Array

	if left_array.size() != right_array.size():
		return false

	for index: int in left_array.size():
		if str(left_array[index]) != str(right_array[index]):
			return false

	return true


func _on_buy_requested(upgrade_id: String) -> void:
	var bought: bool = RunUpgradeSystem.buy_run_upgrade(upgrade_id)

	if not bought:
		return

	_queue_refresh()


func _on_squares_changed(_value: float) -> void:
	_queue_refresh()


func _on_trait_purchase_changed(_value: int) -> void:
	_queue_refresh()


func _on_grid_changed() -> void:
	_queue_refresh()


func _on_achievements_changed() -> void:
	_queue_refresh()


func _on_passive_state_changed() -> void:
	_queue_refresh()


func _on_run_upgrades_changed() -> void:
	_queue_refresh()
