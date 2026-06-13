extends Node
class_name FeaturePanelVisibility

@export var target: Control
@export var fade_duration_seconds: float = 0.55
@export var start_hidden: bool = true

@export_group("Motion")
@export var use_slide: bool = true
@export var slide_offset: Vector2 = Vector2(0.0, 12.0)
@export var use_scale: bool = true
@export var hidden_scale: Vector2 = Vector2(0.985, 0.985)

var is_feature_visible: bool = false
var tween: Tween
var visible_position: Vector2
var visible_scale: Vector2 = Vector2.ONE
var has_cached_transform: bool = false


func _ready() -> void:
	if target == null:
		target = get_parent() as Control

	if target == null:
		push_error("FeaturePanelVisibility needs a Control target or Control parent.")
		return

	_cache_visible_transform()

	if start_hidden:
		set_feature_visible(false, false)
	else:
		set_feature_visible(true, false)


func set_feature_visible(should_be_visible: bool, animated: bool = true) -> void:
	if target == null:
		return

	if not has_cached_transform:
		_cache_visible_transform()

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


func _cache_visible_transform() -> void:
	if target == null:
		return

	visible_position = target.position
	visible_scale = target.scale
	has_cached_transform = true


func _apply_visibility_immediately(should_be_visible: bool) -> void:
	target.visible = should_be_visible
	target.modulate.a = 1.0 if should_be_visible else 0.0
	target.mouse_filter = Control.MOUSE_FILTER_STOP if should_be_visible else Control.MOUSE_FILTER_IGNORE

	if should_be_visible:
		target.position = visible_position
		target.scale = visible_scale
	else:
		target.position = visible_position + slide_offset if use_slide else visible_position
		target.scale = hidden_scale if use_scale else visible_scale


func _fade_in() -> void:
	target.visible = true
	target.modulate.a = 0.0
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if use_slide:
		target.position = visible_position + slide_offset

	if use_scale:
		target.scale = hidden_scale

	tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(target, "modulate:a", 1.0, fade_duration_seconds)

	if use_slide:
		tween.tween_property(target, "position", visible_position, fade_duration_seconds)

	if use_scale:
		tween.tween_property(target, "scale", visible_scale, fade_duration_seconds)

	tween.finished.connect(_on_fade_in_finished)


func _fade_out() -> void:
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE

	tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(target, "modulate:a", 0.0, fade_duration_seconds)

	if use_slide:
		tween.tween_property(target, "position", visible_position + slide_offset, fade_duration_seconds)

	if use_scale:
		tween.tween_property(target, "scale", hidden_scale, fade_duration_seconds)

	tween.finished.connect(_on_fade_out_finished)


func _on_fade_in_finished() -> void:
	if target == null:
		return

	target.mouse_filter = Control.MOUSE_FILTER_STOP
	target.modulate.a = 1.0
	target.position = visible_position
	target.scale = visible_scale


func _on_fade_out_finished() -> void:
	if target == null:
		return

	target.visible = false
	target.modulate.a = 0.0
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.position = visible_position + slide_offset if use_slide else visible_position
	target.scale = hidden_scale if use_scale else visible_scale
