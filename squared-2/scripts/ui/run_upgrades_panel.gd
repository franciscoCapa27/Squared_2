extends PanelContainer
class_name RunUpgradesPanel

@onready var run_upgrade_list: VBoxContainer = %RunUpgradeList

var run_upgrade_card_scene: PackedScene = preload("res://scenes/ui/RunUpgradeCard.tscn")
var run_upgrade_cards: Dictionary = {}


func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	_apply_theme()
	
	EventBus.squares_changed.connect(_on_squares_changed)
	EventBus.prestige_changed.connect(_on_prestige_changed)
	EventBus.grid_changed.connect(_on_grid_changed)

	AchievementSystem.achievements_changed.connect(_on_achievements_changed)
	PassiveSystem.passive_state_changed.connect(_on_passive_state_changed)
	RunUpgradeSystem.run_upgrades_changed.connect(_on_run_upgrades_changed)

	refresh()

func _apply_theme() -> void:
	add_theme_stylebox_override("panel", ThemeSystem.make_panel_style())


func _on_theme_changed() -> void:
	_apply_theme()

func refresh() -> void:
	_rebuild_if_needed()

	for upgrade_id: String in run_upgrade_cards.keys():
		var card: RunUpgradeCard = run_upgrade_cards.get(upgrade_id) as RunUpgradeCard

		if card == null:
			continue

		card.refresh()


func _rebuild_if_needed() -> void:
	var visible_upgrades: Array[RunUpgradeDefinition] = _get_visible_upgrades()

	if visible_upgrades.size() != run_upgrade_cards.size():
		_rebuild_list()


func _rebuild_list() -> void:
	for child: Node in run_upgrade_list.get_children():
		child.queue_free()

	run_upgrade_cards.clear()

	var visible_upgrades: Array[RunUpgradeDefinition] = _get_visible_upgrades()

	for upgrade: RunUpgradeDefinition in visible_upgrades:
		var card: RunUpgradeCard = run_upgrade_card_scene.instantiate() as RunUpgradeCard
		run_upgrade_list.add_child(card)

		card.setup(upgrade)
		card.buy_requested.connect(_on_buy_requested)

		run_upgrade_cards[upgrade.id] = card


func _get_visible_upgrades() -> Array[RunUpgradeDefinition]:
	var visible_upgrades: Array[RunUpgradeDefinition] = []

	for upgrade: RunUpgradeDefinition in RunUpgradeDatabase.get_all_upgrades():
		if not upgrade.is_visible_by_default:
			continue

		if upgrade.hidden_until_unlocked and not RunUpgradeSystem.is_run_upgrade_unlocked(upgrade.id):
			continue

		visible_upgrades.append(upgrade)

	return visible_upgrades


func _on_buy_requested(upgrade_id: String) -> void:
	var bought: bool = RunUpgradeSystem.buy_run_upgrade(upgrade_id)

	if not bought:
		return

	refresh()


func _on_squares_changed(_value: float) -> void:
	refresh()


func _on_prestige_changed(_value: int) -> void:
	refresh()


func _on_grid_changed() -> void:
	refresh()


func _on_achievements_changed() -> void:
	refresh()


func _on_passive_state_changed() -> void:
	refresh()


func _on_run_upgrades_changed() -> void:
	refresh()
