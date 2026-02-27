extends Panel
class_name AttackOptionScene

@onready var skull: TextureRect = $Skull
@onready var disable_rect: ColorRect = $DisableRect
@onready var amount: Label = $Amount
@onready var first: TextureRect = $HBoxContainer/First

signal clicked

enum panel_state { DISABLED, RED, NORMAL, HOVER }
var last_state: panel_state = panel_state.NORMAL

func set_state(state: panel_state) -> void:
	if global_position.x + size.x + 200 >= get_viewport().get_visible_rect().size.x:
		skull.position = Vector2(-74,2)
	if state != panel_state.HOVER:
		last_state = state
	match state:
		panel_state.DISABLED:
			disable_rect.visible = true
			var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
			style.border_color = Color("8f8f8f")
			style.bg_color = Color("1f1f1f")
			add_theme_stylebox_override("panel", style)
		panel_state.RED:
			skull.visible = true
			var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
			style.border_color = Color("e42833")
			style.bg_color = Color("1f1f1f")
			add_theme_stylebox_override("panel", style)
		panel_state.NORMAL:
			var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
			style.bg_color = Color("1f1f1f")
			add_theme_stylebox_override("panel", style)
		panel_state.HOVER:
			var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
			style.bg_color = Color("3d3d3d")
			add_theme_stylebox_override("panel", style)

func _on_gui_input(event: InputEvent) -> void:
	if last_state == panel_state.DISABLED:
		return
	if event is InputEventScreenTouch:
		if event.is_pressed():
			set_state(panel_state.HOVER)
		if event.is_released():
			set_state(last_state)
			if get_global_rect().has_point(get_global_mouse_position()):
				clicked.emit()
