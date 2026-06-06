extends Resource
class_name VisualProfile

@export var base_color: Color = Color(0.8, 0.8, 1.0, 1.0)
@export var accent_color: Color = Color(1.0, 1.0, 1.0, 1.0)

@export_range(0, 10) var glow_level: int = 0
@export_range(0, 10) var edge_complexity: int = 0
@export_range(0, 10) var gloss_level: int = 0
@export_range(0, 10) var distortion_level: int = 0

@export var dominant_tag: String = ""
@export var secondary_tag: String = ""

@export var pulse_style: String = "none"
@export var particle_style: String = "none"
@export var pattern_style: String = "none"

func duplicate_profile() -> VisualProfile:
	var profile := VisualProfile.new()
	profile.base_color = base_color
	profile.accent_color = accent_color
	profile.glow_level = glow_level
	profile.edge_complexity = edge_complexity
	profile.gloss_level = gloss_level
	profile.distortion_level = distortion_level
	profile.dominant_tag = dominant_tag
	profile.secondary_tag = secondary_tag
	profile.pulse_style = pulse_style
	profile.particle_style = particle_style
	profile.pattern_style = pattern_style
	return profile
