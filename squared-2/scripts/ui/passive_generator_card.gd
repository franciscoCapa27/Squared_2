extends PanelContainer
class_name PassiveGeneratorCard

signal upgrade_requested(generator_id: String)

@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var upgrade_button: Button = %UpgradeButton

var generator_id: String = ""
var upgrade_request_pending: bool = false

func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)

	_apply_theme()

func _apply_theme() -> void:
	add_theme_stylebox_override("panel", ThemeSystem.make_card_style())

	ThemeTextHelper.apply_primary_label(title_label)
	ThemeTextHelper.apply_body_label(status_label)
	ThemeButtonHelper.apply_button_theme(upgrade_button)


func _on_theme_changed() -> void:
	_apply_theme()
func setup(p_generator_id: String) -> void:
	generator_id = p_generator_id
	refresh()

func refresh() -> void:
	var generator_instance: PassiveGeneratorInstance = PassiveSystem.get_generator_instance(generator_id)

	if generator_instance == null:
		title_label.text = "Unknown Generator"
		status_label.text = "No generator data found."
		progress_bar.visible = false
		upgrade_button.visible = false
		return

	title_label.text = generator_instance.get_display_name()

	if not generator_instance.is_unlocked:
		status_label.text = "Locked"
		progress_bar.visible = false
		upgrade_button.visible = false
		return

	var is_active: bool = generator_instance.is_active()
	var activity_state: String = "Active" if is_active else "Inactive"
	var effect_prefix: String = "" if is_active else "When active: "
	status_label.text = "Level %s / %s · %s\n%s%s" % [
		generator_instance.level,
		generator_instance.get_max_level(),
		activity_state,
		effect_prefix,
		_get_effect_summary(generator_instance)
	]

	upgrade_button.visible = true
	upgrade_button.disabled = upgrade_request_pending or not PassiveSystem.can_upgrade_generator(generator_id)

	if generator_instance.level >= generator_instance.get_max_level():
		upgrade_button.text = "Max Level"
	else:
		upgrade_button.text = "Buy Level %s — %s Squares" % [
			generator_instance.level + 1,
			NumberFormatter.cost(float(generator_instance.get_next_level_cost()))
		]

	upgrade_button.tooltip_text = "Squares: %s / Cost: %s" % [
		NumberFormatter.amount(GameState.squares),
		NumberFormatter.cost(float(generator_instance.get_next_level_cost()))
	]

	if not is_active:
		progress_bar.value = 0.0
		progress_bar.visible = false
		return

	progress_bar.visible = true
	progress_bar.value = generator_instance.get_progress_ratio()


func _get_effect_summary(generator_instance: PassiveGeneratorInstance) -> String:
	return "Lightly clicks %s every %s at %s strength." % [
		_get_targeting_text(generator_instance),
		NumberFormatter.seconds(generator_instance.get_current_interval_seconds()),
		NumberFormatter.percent(generator_instance.get_current_extraction_rate())
	]

func _get_targeting_text(generator_instance: PassiveGeneratorInstance) -> String:
	if generator_instance == null or generator_instance.definition == null:
		return "Unknown"

	match generator_instance.definition.targeting_mode:
		PassiveGeneratorDefinition.TargetingMode.RANDOM_SQUARE:
			return "one random square"
		PassiveGeneratorDefinition.TargetingMode.HIGHEST_PAYOUT:
			return "the highest-payout square"
		PassiveGeneratorDefinition.TargetingMode.LOWEST_RESPAWN:
			return "the square with the shortest respawn"
		PassiveGeneratorDefinition.TargetingMode.SELECTED_SQUARE:
			return "the selected square"
		_:
			return "one square"

func _on_upgrade_button_pressed() -> void:
	if generator_id == "" or upgrade_request_pending:
		return

	upgrade_request_pending = true
	upgrade_button.disabled = true
	upgrade_requested.emit(generator_id)
	call_deferred("_finish_upgrade_request")


func _finish_upgrade_request() -> void:
	if not is_instance_valid(self):
		return

	upgrade_request_pending = false
	refresh()
