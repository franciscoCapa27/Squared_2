extends Resource
class_name UIThemeDefinition

@export var id: String = "void_dark"
@export var display_name: String = "Void Dark"

@export_group("Base Colors")
@export var background: Color = Color("#060914")
@export var background_subtle: Color = Color("#0A1020")

@export_group("Surfaces")
@export var surface: Color = Color("#0D1426CC")
@export var surface_soft: Color = Color("#10182FCC")
@export var surface_strong: Color = Color("#151F3BDD")

@export_group("Borders")
@export var border: Color = Color("#29365799")
@export var border_soft: Color = Color("#1D294666")
@export var border_strong: Color = Color("#6E7CFFAA")

@export_group("Text")
@export var text_primary: Color = Color("#EEF2FF")
@export var text_secondary: Color = Color("#B8C0D9")
@export var text_muted: Color = Color("#78839F")

@export_group("Accents")
@export var accent_primary: Color = Color("#8B7CFF")
@export var accent_secondary: Color = Color("#67D7FF")
@export var success: Color = Color("#64F29A")
@export var warning: Color = Color("#FFB84D")
@export var danger: Color = Color("#FF6B7A")

@export_group("Shape")
@export_range(0, 64, 1) var panel_corner_radius: int = 18
@export_range(0, 64, 1) var card_corner_radius: int = 14
@export_range(0, 64, 1) var button_corner_radius: int = 12

@export_range(0, 8, 1) var panel_border_width: int = 1
@export_range(0, 8, 1) var card_border_width: int = 1
@export_range(0, 8, 1) var button_border_width: int = 1

@export_group("Opacity")
@export_range(0.0, 1.0, 0.01) var disabled_opacity: float = 0.45
@export_range(0.0, 1.0, 0.01) var hover_brightness: float = 1.15
@export_range(0.0, 1.0, 0.01) var pressed_brightness: float = 0.85

@export_group("Spacing")
@export_range(0, 64, 1) var screen_margin: int = 24
@export_range(0, 64, 1) var panel_gap: int = 16
@export_range(0, 64, 1) var section_gap: int = 18
@export_range(0, 64, 1) var card_gap: int = 10
@export_range(0, 64, 1) var inner_margin: int = 16
@export_range(0, 64, 1) var grid_gap: int = 14
@export_range(0, 128, 1) var trait_purchase_gap: int = 32

@export_group("Typography")
@export_range(8, 40, 1) var font_size_resource: int = 16
@export_range(8, 40, 1) var font_size_page_title: int = 18
@export_range(8, 40, 1) var font_size_panel_title: int = 15
@export_range(8, 40, 1) var font_size_card_title: int = 14
@export_range(8, 40, 1) var font_size_body: int = 13
@export_range(8, 40, 1) var font_size_detail: int = 12
@export_range(8, 40, 1) var font_size_button: int = 13
@export_range(8, 40, 1) var font_size_tiny: int = 10

@export_range(0.7, 1.2, 0.01) var compact_text_scale: float = 0.88
