extends PanelContainer
class_name PassiveGeneratorCard

signal upgrade_requested(generator_id: String)

@onready var title_label: Label = %TitleLabel
@onready var level_label: Label = %LevelLabel
@onready var icon_label: PolygonIcon = %IconLabel
@onready var status_label: RichTextLabel = %StatusLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var upgrade_button: Button = %UpgradeButton
@onready var detail_help: ContextualHelp = %DetailHelp

var generator_id: String = ""
var upgrade_request_pending: bool = false

func _ready() -> void:
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)

	_apply_theme()

func _apply_theme() -> void:
	add_theme_stylebox_override("panel", ThemeSystem.make_card_style())

	ThemeTextHelper.apply_card_title(title_label)
	ThemeTextHelper.apply_detail_rich_text(status_label)
	ThemeTextHelper.apply_detail_label(level_label)
	icon_label.set_icon_color(ThemeSystem.get_color("text_primary"))
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
		level_label.text = "-"
		status_label.text = "No generator data found."
		progress_bar.visible = false
		upgrade_button.visible = false
		detail_help.visible = false
		return

	title_label.text = generator_instance.get_display_name()

	if not generator_instance.is_unlocked:
		status_label.text = "Locked"
		level_label.text = "0/%s" % generator_instance.get_max_level()
		progress_bar.visible = false
		upgrade_button.visible = false
		detail_help.visible = false
		return

	detail_help.visible = true
	detail_help.help_title = generator_instance.get_display_name()
	detail_help.help_detail = _get_detail_help(generator_instance)
	detail_help.tooltip_text = "%s\n%s" % [
		detail_help.help_title,
		detail_help.help_detail
	]
	level_label.text = "%s/%s" % [generator_instance.level, generator_instance.get_max_level()]
	icon_label.set_icon_kind("passive")
	icon_label.set_icon_color(ThemeSystem.get_color("text_primary"))

	var is_active: bool = generator_instance.is_active()
	var last_payout: String = "Last payout: -"
	if generator_instance.last_target_square_id != "":
		last_payout = "Last payout: [b]+%s[/b] Squares" % NumberFormatter.amount(generator_instance.last_payout)
	status_label.text = "%s\n%s" % [
		_get_compact_description(generator_instance),
		last_payout,
	]

	upgrade_button.visible = true
	upgrade_button.disabled = upgrade_request_pending or not PassiveSystem.can_upgrade_generator(generator_id)

	if generator_instance.level >= generator_instance.get_max_level():
		upgrade_button.text = "Max Level"
	else:
		upgrade_button.text = "Buy %s - %s" % [
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


func _get_compact_description(generator_instance: PassiveGeneratorInstance) -> String:
	if not generator_instance.is_active():
		return "Inactive"

	return "Clicks %s." % _get_targeting_text(generator_instance)


func _get_effect_summary(generator_instance: PassiveGeneratorInstance) -> String:
	return "Clicks %s every [b]%s[/b] at [b]%s[/b] strength." % [
		_get_targeting_text(generator_instance),
		NumberFormatter.seconds(generator_instance.get_current_interval_seconds()),
		NumberFormatter.percent(generator_instance.get_current_extraction_rate())
	]


func _get_detail_help(generator_instance: PassiveGeneratorInstance) -> String:
	var next_level_detail: String = "Next level: max level reached."
	if generator_instance.level < generator_instance.get_max_level():
		var next_level_instance: PassiveGeneratorInstance = PassiveGeneratorInstance.new(
			generator_instance.definition
		)
		next_level_instance.level = generator_instance.level + 1
		next_level_detail = "Next level: %s interval; %s extraction." % [
			NumberFormatter.seconds(next_level_instance.get_current_interval_seconds()),
			NumberFormatter.percent(next_level_instance.get_current_extraction_rate())
		]

	var last_pulse_detail: String = "None yet."
	if generator_instance.last_target_square_id != "":
		last_pulse_detail = "+%s Squares from %s." % [
			NumberFormatter.amount(generator_instance.last_payout),
			generator_instance.last_target_square_id
		]

	return (
		"Current effect: %s\n" % _get_effect_summary(generator_instance)
		+ "Interval: %s\n" % NumberFormatter.seconds(generator_instance.get_current_interval_seconds())
		+ "Extraction: %s\n" % NumberFormatter.percent(generator_instance.get_current_extraction_rate())
		+ "Targeting: %s\n" % _get_targeting_text(generator_instance)
		+ "%s\n\n" % next_level_detail
		+ "Last pulse: %s\n" % last_pulse_detail
		+ "Pulses: %s\n" % NumberFormatter.integer_amount(generator_instance.lifetime_pulses)
		+ "Squares generated: %s\n\n" % NumberFormatter.amount(generator_instance.lifetime_squares_generated)
		+ "Levels reset on a new game."
	)

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
