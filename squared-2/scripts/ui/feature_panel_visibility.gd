extends Node
class_name FeaturePanelVisibility

@export var target: Control
@export var fade_duration_seconds: float = 0.85
@export var start_hidden: bool = true

# Kept for inspector compatibility, but intentionally unused for layout-managed UI.
# Do not animate position/scale directly on Controls inside Containers.
@export_group("Deprecated Motion")
@export var use_slide: bool = false
@export var slide_offset: Vector2 = Vector2.ZERO
@export var use_scale: bool = false
@export var hidden_scale: Vector2 = Vector2.ONE

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

	# Let parent containers place the control before the fade starts.
	await get_tree().process_frame

	if target == null or not is_feature_visible:
		return

	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "modulate:a", 1.0, fade_duration_seconds)
	tween.finished.connect(_on_fade_in_finished)


func _fade_out() -> void:
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE

	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(target, "modulate:a", 0.0, fade_duration_seconds)
	tween.finished.connect(_on_fade_out_finished)


func _on_fade_in_finished() -> void:
	if target == null:
		return

	target.visible = true
	target.modulate.a = 1.0
	target.mouse_filter = Control.MOUSE_FILTER_STOP
	_highlight_newly_visible()


func _on_fade_out_finished() -> void:
	if target == null:
		return

	target.visible = false
	target.modulate.a = 0.0
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _highlight_newly_visible() -> void:
	if target == null:
		return
	var ht := create_tween()
	ht.set_trans(Tween.TRANS_SINE)
	ht.tween_property(target, "modulate", Color(1.0, 0.85, 0.3, 1.0), 0.15)
	ht.tween_property(target, "modulate", Color.WHITE, 0.15)
