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


# ------------------------------------------------------------------------
# Family‑material visual identities (issue #68)
# ------------------------------------------------------------------------

const FAMILY_VISUAL_MAP := {
	"quick": {
		"base_color": Color(0.2, 0.6, 1.0, 1.0),       # bright electric blue
		"accent_color": Color(1.0, 1.0, 1.0, 1.0),
		"glow_base": 1,
		"edge_base": 1,
		"gloss_base": 0,
		"distortion_base": 0,
		"pulse_style": "sharp",
		"particle_style": "none",
		"pattern_style": "none",
	},
	"dense": {
		"base_color": Color(0.9, 0.4, 0.15, 1.0),       # warm heavy orange‑brown
		"accent_color": Color(0.95, 0.7, 0.3, 1.0),
		"glow_base": 0,
		"edge_base": 2,
		"gloss_base": 1,
		"distortion_base": 0,
		"pulse_style": "none",
		"particle_style": "none",
		"pattern_style": "none",
	},
	"glimmer": {
		"base_color": Color(1.0, 0.85, 0.4, 1.0),       # luminous gold
		"accent_color": Color(1.0, 1.0, 0.9, 1.0),
		"glow_base": 2,
		"edge_base": 0,
		"gloss_base": 2,
		"distortion_base": 0,
		"pulse_style": "none",
		"particle_style": "sparkle",
		"pattern_style": "none",
	},
	"patient": {
		"base_color": Color(0.5, 0.5, 1.0, 1.0),        # soft purple‑blue
		"accent_color": Color(0.8, 0.85, 1.0, 1.0),
		"glow_base": 1,
		"edge_base": 0,
		"gloss_base": 0,
		"distortion_base": 1,
		"pulse_style": "slow_pulse",
		"particle_style": "none",
		"pattern_style": "none",
	},
}


static func get_family_profile(family_id: String, stack_count: int, rarity: int) -> VisualProfile:
	var profile := VisualProfile.new()

	if family_id == "" or not FAMILY_VISUAL_MAP.has(family_id):
		# Neutral fallback for unknown / future families.
		profile.base_color = Color(0.85, 0.85, 1.0, 1.0)
		profile.accent_color = Color(1.0, 1.0, 1.0, 1.0)
		profile.glow_level = clampi(rarity, 0, 10)
		profile.edge_complexity = clampi(stack_count, 0, 10)
		profile.gloss_level = 0
		profile.distortion_level = 0
		profile.pulse_style = "none"
		profile.particle_style = "none"
		profile.pattern_style = "none"
		return profile

	var data: Dictionary = FAMILY_VISUAL_MAP[family_id]

	profile.base_color = data.get("base_color", Color.WHITE)
	profile.accent_color = data.get("accent_color", Color.WHITE)

	profile.glow_level = clampi(data.get("glow_base", 0) + rarity, 0, 10)
	profile.edge_complexity = clampi(data.get("edge_base", 0) + stack_count, 0, 10)
	profile.gloss_level = clampi(data.get("gloss_base", 0) + rarity, 0, 10)
	profile.distortion_level = clampi(data.get("distortion_base", 0) + rarity, 0, 10)

	profile.pulse_style = str(data.get("pulse_style", "none"))
	profile.particle_style = str(data.get("particle_style", "none"))
	profile.pattern_style = str(data.get("pattern_style", "none"))

	return profile
