extends Button
class_name ContextualHelp

const POPUP_MARGIN := 16.0
const POPUP_GAP := 8.0
const POPUP_MAX_WIDTH := 360.0
const POPUP_MAX_HEIGHT := 320.0

@export var help_title: String = "Help"
@export_multiline var help_detail: String = ""

static var _active_help: ContextualHelp
static var _active_layer: CanvasLayer

var _popup: PanelContainer
var _popup_centered: bool = false


func _ready() -> void:
	text = "i"
	focus_mode = Control.FOCUS_NONE
	set_process_input(true)
	tooltip_text = _get_explanation()
	pressed.connect(_on_pressed)
	ThemeSystem.theme_changed.connect(_on_theme_changed)
	_apply_theme()


func _exit_tree() -> void:
	if _active_help == self:
		_close_active()


func _on_pressed() -> void:
	if _active_help == self:
		_close_active()
		return

	_close_active()
	_open_popup()


func open_help() -> void:
	_on_pressed()


func open_centered_detail(popup_title: String, custom_content: Control) -> void:
	help_title = popup_title
	_close_active()
	_open_popup_with_content(custom_content, true)


func _open_popup() -> void:
	_open_popup_with_content(null, false)


func _open_popup_with_content(custom_content: Control, centered: bool) -> void:
	_active_help = self
	_popup_centered = centered
	_active_layer = CanvasLayer.new()
	_active_layer.layer = 100
	get_tree().root.add_child(_active_layer)

	var overlay: Control = Control.new()
	overlay.name = "ContextualHelpOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_overlay_gui_input)
	overlay.set_process_input(true)
	_active_layer.add_child(overlay)

	_popup = PanelContainer.new()
	_popup.name = "ContextualHelpPopup"
	_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup.gui_input.connect(_on_popup_gui_input)
	_active_popup_setup(overlay, custom_content)
	_apply_popup_theme()
	_position_popup.call_deferred()


func _active_popup_setup(overlay: Control, custom_content: Control = null) -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var available_width: float = maxf(0.0, viewport_size.x - POPUP_MARGIN * 2.0)
	var available_height: float = maxf(0.0, viewport_size.y - POPUP_MARGIN * 2.0)
	var popup_width: float = minf(
		POPUP_MAX_WIDTH,
		maxf(1.0, available_width)
	)
	var popup_height: float = minf(
		POPUP_MAX_HEIGHT,
		maxf(1.0, available_height)
	)
	_popup.custom_minimum_size = Vector2(popup_width, popup_height)
	_popup.size = _popup.custom_minimum_size
	overlay.add_child(_popup)

	var margin: MarginContainer = MarginContainer.new()
	ThemeLayoutHelper.apply_margin(margin, "inner_margin")
	_popup.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	ThemeLayoutHelper.apply_box_separation(content, "section_gap")
	margin.add_child(content)

	var title_label: Label = Label.new()
	title_label.text = help_title
	ThemeTextHelper.apply_panel_title(title_label)
	content.add_child(title_label)

	var detail_scroll: ScrollContainer = ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(detail_scroll)

	if custom_content != null:
		custom_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		custom_content.custom_minimum_size = Vector2(
			maxf(0.0, popup_width - ThemeSystem.get_spacing("inner_margin") * 2.0),
			0.0
		)
		detail_scroll.add_child(custom_content)
	else:
		var detail_label: Label = Label.new()
		detail_label.text = help_detail
		detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail_label.custom_minimum_size = Vector2(
			maxf(0.0, popup_width - ThemeSystem.get_spacing("inner_margin") * 2.0),
			0.0
		)
		ThemeTextHelper.apply_body_label(detail_label)
		detail_scroll.add_child(detail_label)


func _position_popup() -> void:
	if _popup == null or not is_instance_valid(_popup):
		return

	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var trigger_rect: Rect2 = get_global_rect()
	var popup_size: Vector2 = _popup.size
	var x: float = trigger_rect.position.x
	var y: float = trigger_rect.end.y + POPUP_GAP

	if _popup_centered:
		x = viewport_rect.position.x + (viewport_rect.size.x - popup_size.x) * 0.5
		y = viewport_rect.position.y + (viewport_rect.size.y - popup_size.y) * 0.5
		_popup.position = Vector2(floor(x), floor(y))
		return

	if y + popup_size.y > viewport_rect.end.y - POPUP_MARGIN:
		y = trigger_rect.position.y - popup_size.y - POPUP_GAP

	x = clampf(x, viewport_rect.position.x + POPUP_MARGIN, viewport_rect.end.x - popup_size.x - POPUP_MARGIN)
	y = clampf(y, viewport_rect.position.y + POPUP_MARGIN, viewport_rect.end.y - popup_size.y - POPUP_MARGIN)
	_popup.position = Vector2(floor(x), floor(y))


func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close_active()


func _on_popup_gui_input(_event: InputEvent) -> void:
	accept_event()


func _input(event: InputEvent) -> void:
	if _active_help != self:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close_active()


func _close_active() -> void:
	if _active_layer != null and is_instance_valid(_active_layer):
		_active_layer.queue_free()

	_active_layer = null
	_active_help = null
	_popup = null
	_popup_centered = false


func _get_explanation() -> String:
	if help_detail.is_empty():
		return help_title
	return "%s\n%s" % [help_title, help_detail]


func _apply_theme() -> void:
	ThemeButtonHelper.apply_button_theme(self)


func _apply_popup_theme() -> void:
	if _popup == null:
		return
	_popup.add_theme_stylebox_override("panel", ThemeSystem.make_elevated_panel_style())


func _on_theme_changed() -> void:
	_apply_theme()
	_apply_popup_theme()
