extends Node
class_name FeaturePanelVisibility

@export var target: Control
@export var fade_duration_seconds: float = 0.25
@export var start_hidden: bool = true

var is_feature_visible: bool = false
var tween: Tween


func _ready() -> void:
	if target == null:
		target = get_parent() as Control

	if target == null:
		push_error("FeaturePanelVisibility needs a Control target or Control parent.")
		return

	if start_hidden:
		set_feature_visible(false, false)
	else:
		set_feature_visible(true, false)


func set_feature_visible(should_be_visible: bool, animated: bool = true) -> void:
	if target == null:
		return

	if is_feature_visible == should_be_visible and target.visible == should_be_visible:
		return

	is_feature_visible = should_be_visible

	if tween != null:
		tween.kill()
		tween = null

	if not animated:
		_apply_visibility_immediately(should_be_visible)
		return

	if should_be_visible:
		_fade_in()
	else:
		_fade_out()


func _apply_visibility_immediately(should_be_visible: bool) -> void:
	target.visible = should_be_visible
	target.modulate.a = 1.0 if should_be_visible else 0.0
	target.mouse_filter = Control.MOUSE_FILTER_STOP if should_be_visible else Control.MOUSE_FILTER_IGNORE


func _fade_in() -> void:
	target.visible = true
	target.modulate.a = 0.0
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE

	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "modulate:a", 1.0, fade_duration_seconds)
	tween.finished.connect(_on_fade_in_finished)


func _fade_out() -> void:
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE

	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(target, "modulate:a", 0.0, fade_duration_seconds)
	tween.finished.connect(_on_fade_out_finished)


func _on_fade_in_finished() -> void:
	if target == null:
		return

	target.mouse_filter = Control.MOUSE_FILTER_STOP
	target.modulate.a = 1.0


func _on_fade_out_finished() -> void:
	if target == null:
		return

	target.visible = false
	target.modulate.a = 0.0
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
