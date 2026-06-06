extends Button

signal square_clicked(square_id: String)

var square_id: String = ""

func setup(id: String, display_text: String = "□") -> void:
	square_id = id
	text = display_text
	tooltip_text = "Square %s" % square_id

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	square_clicked.emit(square_id)
