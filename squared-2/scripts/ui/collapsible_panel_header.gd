extends Button
class_name CollapsiblePanelHeader

@export var content_path: NodePath

var _content: Control
var _title_text: String
var _expanded: bool = true


func _ready() -> void:
	_title_text = text
	_content = get_node_or_null(content_path) as Control
	if _content == null and not content_path.is_empty():
		push_warning("CollapsiblePanelHeader could not resolve content_path: %s" % content_path)
	pressed.connect(_toggle_expanded)
	ThemeButtonHelper.apply_button_theme(self)
	_update_visual_state()


func set_title(title_text: String) -> void:
	_title_text = title_text
	_update_visual_state()


func _toggle_expanded() -> void:
	_expanded = not _expanded
	_update_visual_state()


func _update_visual_state() -> void:
	text = "%s  %s" % ["▼" if _expanded else "▶", _title_text]
	if _content != null:
		_content.visible = _expanded
