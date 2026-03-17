extends Panel
class_name DifficultyTag

enum TagLevel {EASY,NORMAL,HARD}

@onready var label: Label = $Label

func set_data(text: String, level: TagLevel) -> void:
	
	label.text = text
	await get_tree().process_frame

	var bg_color: Color
	var border_color: Color
	var font_color: Color

	match level:
		TagLevel.EASY:
			bg_color     = Color("#122010")
			border_color = Color("#3a5a28")
			font_color   = Color("#6ab85a")
		TagLevel.NORMAL:
			bg_color     = Color("#1a1608")
			border_color = Color("#4a3818")
			font_color   = Color("#c9a060")
		TagLevel.HARD:
			bg_color     = Color("#200808")
			border_color = Color("#5a1818")
			font_color   = Color("#c43030")
	var style := StyleBoxFlat.new()
	style.bg_color            = bg_color
	style.border_color        = border_color
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.corner_radius_top_left     = 1
	style.corner_radius_top_right    = 1
	style.corner_radius_bottom_left  = 1
	style.corner_radius_bottom_right = 1
	add_theme_stylebox_override("panel", style)

	for font_state: String in ["font_color", "font_hover_color", "font_pressed_color",
			"font_focus_color"]:
		label.add_theme_color_override(font_state, font_color)

	# Fit minimum size to label + margins
	var label_size := label.get_minimum_size()
	custom_minimum_size = label_size + Vector2(40, 8)
	visible = true
