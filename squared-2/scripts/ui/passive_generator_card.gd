extends PanelContainer
class_name PassiveGeneratorCard

signal upgrade_requested(generator_id: String)

@onready var title_label: Label = %TitleLabel
@onready var status_label: RichTextLabel = %StatusLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var upgrade_button: Button = %UpgradeButton

var generator_id: String = ""

func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	
	_apply_theme()
	
func _apply_theme() -> void:
	add_theme_stylebox_override("panel", ThemeSystem.make_card_style())

	ThemeTextHelper.apply_primary_label(title_label)
	ThemeTextHelper.apply_detail_rich_text(status_label)
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
		status_label.text = "Locked."
		progress_bar.visible = false
		upgrade_button.visible = false
		return

	upgrade_button.visible = true
	upgrade_button.disabled = not PassiveSystem.can_upgrade_generator(generator_id)

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

	if not generator_instance.is_active():
		progress_bar.visible = false
		status_label.text = (
			"Unlocked, inactive this run.\n\n"
			+ "Level: 0 / %s\n" % generator_instance.get_max_level()
			+ "Buy Level 1 to start passive generation.\n\n"
			+ "Level 1:\n"
			+ "- Interval: %s\n" % NumberFormatter.seconds(generator_instance.definition.base_interval_seconds)
			+ "- Extraction: %s\n\n" % NumberFormatter.percent(generator_instance.definition.base_extraction_rate)
			+ "Run levels persist after buying a Trait."
		)
		return

	progress_bar.visible = true
	progress_bar.value = generator_instance.get_progress_ratio()

	var last_pulse_text: String = "None"

	if generator_instance.last_target_square_id != "":
		last_pulse_text = "+%s Squares from %s" % [
			NumberFormatter.amount(generator_instance.last_payout),
			generator_instance.last_target_square_id
		]

	var next_level_text: String = "Max level reached"

	if generator_instance.level < generator_instance.get_max_level():
		next_level_text = "Next Level Cost: %s Squares" % NumberFormatter.cost(float(generator_instance.get_next_level_cost()))
	
	status_label.text = (
		"Level: %s / %s\n\n" % [
			generator_instance.level,
			generator_instance.get_max_level()
		]
		+ "- Interval: %s\n" % NumberFormatter.seconds(generator_instance.definition.base_interval_seconds)
		+ "- Extraction: %s\n\n" % NumberFormatter.percent(generator_instance.definition.base_extraction_rate)
		+ "Targeting: %s\n\n" % _get_targeting_text(generator_instance)
		+ "Last Pulse: %s\n" % last_pulse_text
		+ "Lifetime Pulses This Run: %s\n" % NumberFormatter.integer_amount(generator_instance.lifetime_pulses)
		+ "Squares This Run: %s\n\n" % NumberFormatter.amount(generator_instance.lifetime_squares_generated)
		+ next_level_text
	)

func _get_targeting_text(generator_instance: PassiveGeneratorInstance) -> String:
	if generator_instance == null or generator_instance.definition == null:
		return "Unknown"

	match generator_instance.definition.targeting_mode:
		PassiveGeneratorDefinition.TargetingMode.RANDOM_SQUARE:
			return "Random square"
		PassiveGeneratorDefinition.TargetingMode.HIGHEST_PAYOUT:
			return "Highest payout"
		PassiveGeneratorDefinition.TargetingMode.LOWEST_RESPAWN:
			return "Lowest respawn"
		PassiveGeneratorDefinition.TargetingMode.SELECTED_SQUARE:
			return "Selected square"
		_:
			return "Unknown"

func _on_upgrade_button_pressed() -> void:
	if generator_id == "":
		return

	upgrade_requested.emit(generator_id)
