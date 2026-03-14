extends Panel
class_name DifficultyOption

@onready var level: Label = $MarginContainer/VBoxContainer/Level
@onready var pips : Array = [$MarginContainer/VBoxContainer/HBoxContainer/Pip,$MarginContainer/VBoxContainer/HBoxContainer/Pip1,$MarginContainer/VBoxContainer/HBoxContainer/Pip2,$MarginContainer/VBoxContainer/HBoxContainer/Pip3]
@onready var grid_container: GridContainer = $MarginContainer/VBoxContainer/GridContainer
@onready var locked_rect: ColorRect = $LockedRect

const TAG_SCENE = preload("res://scenes/Components/DifficultyTag.tscn")

var data : Dictionary
var locked := false
signal clicked
func _ready() -> void:
	set_data(data)

func set_data(data: Dictionary) -> void:

	# Level label
	level.text = data["tier"]
	var unlocked_difficulties : Array = SaveManager.get_unlocked_difficulties()
	
	if data["tier"] not in unlocked_difficulties:
		locked = true
		locked_rect.visible = true
		
	var label := level.label_settings.duplicate()
	label.font_color = data["accent"].darkened(0.3)
	level.label_settings = label
	for i in range(pips.size()):
		var pip := pips[i] as Panel
		var style := StyleBoxFlat.new()
		style.bg_color = data["accent"] if i < data["pips"] else Color("#2a2418")
		style.corner_radius_top_left     = 99
		style.corner_radius_top_right    = 99
		style.corner_radius_bottom_left  = 99
		style.corner_radius_bottom_right = 99
		pip.add_theme_stylebox_override("panel", style)

	# Panel style
	var style := StyleBoxFlat.new()
	style.bg_color            = data["accent_dim"]
	style.border_color        = data["border"]
	style.border_width_top    = 4
	style.border_width_bottom = 4
	style.border_width_left   = 4
	style.border_width_right  = 4
	style.corner_radius_top_left     = 2
	style.corner_radius_top_right    = 2
	style.corner_radius_bottom_left  = 2
	style.corner_radius_bottom_right = 2
	
	add_theme_stylebox_override("panel", style)

	level.add_theme_color_override("font_color", data["accent"])

	for tag_data : Array in data["tags"]:
		var tag := TAG_SCENE.instantiate() as DifficultyTag
		grid_container.add_child(tag)
		tag.set_data(tag_data[0], tag_data[1])
		grid_container.reset_size()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.is_pressed():
			var style : StyleBoxFlat = get_theme_stylebox("panel").duplicate()
			style.bg_color = style.bg_color.lightened(0.02)
			style.border_color = style.border_color.lightened(0.05)
			
			add_theme_stylebox_override("panel",style)
		if event.is_released():
			var style : StyleBoxFlat = get_theme_stylebox("panel").duplicate()
			style.bg_color = data["accent_dim"]
			style.border_color        = data["border"]
			add_theme_stylebox_override("panel",style)
			if get_global_rect().has_point(get_global_mouse_position()):
				clicked.emit()
