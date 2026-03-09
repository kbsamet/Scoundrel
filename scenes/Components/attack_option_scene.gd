extends Panel
class_name AttackOptionScene

@onready var disable_rect: Panel = $DisableRect
@onready var amount: Label = $HBoxContainer/Amount
@onready var first: TextureRect = $HBoxContainer/First
@onready var health_diff_panel: Panel = $ColorRect
@onready var skull: TextureRect = $ColorRect/Skull
@onready var second: TextureRect = $HBoxContainer/Second

@onready var health_bar: ColorRect = $ColorRect/HealthBar
@onready var new_health: ColorRect = $ColorRect/NewHealth

signal clicked
signal pressed
signal pressed_disabled

enum panel_state { DISABLED, RED, NORMAL, HOVER, DISABLEDRED }
var last_state: panel_state = panel_state.NORMAL
var health_change : int = 0

func set_state(state: panel_state) -> void:
	if state != panel_state.HOVER:
		last_state = state
	match state:
		panel_state.DISABLED:
			disable_rect.visible = true
			var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
			style.border_color = Color("8f8f8f")
			style.bg_color = Color("1f1f1f")
			add_theme_stylebox_override("panel", style)
		panel_state.DISABLEDRED:
			disable_rect.visible = true
			amount.visible = false
			second.texture = skull.texture
			var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
			style.border_color = Color("e42833")
			style.bg_color = Color("4a0d10")
			add_theme_stylebox_override("panel", style)
		panel_state.RED:
			amount.visible = false
			second.texture = skull.texture
			var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
			style.border_color = Color("e42833")
			style.bg_color = Color("4a0d10")
			add_theme_stylebox_override("panel", style)
		panel_state.NORMAL:
			var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
			style.bg_color = Color("1f1f1f")
			add_theme_stylebox_override("panel", style)
		panel_state.HOVER:
			var style: StyleBoxFlat = get_theme_stylebox("panel").duplicate()
			style.bg_color = Color("3d3d3d")
			add_theme_stylebox_override("panel", style)
	

func set_health_rects(health_change : int) -> void:
	self.health_change = health_change
	return
	var max_health_width : int = health_diff_panel.size.x - 5
	
	health_bar.size = Vector2((float(Game.health) / 20.0) * max_health_width ,health_bar.size.y)
	if health_change > 0:
		new_health.color = Color("ff1c2b")
		new_health.position = health_bar.position + Vector2(health_bar.size.x,0)
		var health_diff : float = float(min(20,Game.health + health_change) - Game.health)
		new_health.size =  Vector2((health_diff / 20.0) * max_health_width ,health_bar.size.y)
	else:
		new_health.color = Color("1f1f1fcc")

		var width := (float(min(Game.health,-health_change)) / 20.0) * max_health_width
		
		new_health.size =  Vector2(width ,health_bar.size.y)
		new_health.position = health_bar.position + Vector2((health_bar.size.x - width) + 12,0)
		
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.is_pressed():
			if last_state == panel_state.DISABLED || last_state == panel_state.DISABLEDRED:
				pressed_disabled.emit()
				var tween := create_tween()
				tween.tween_property(self,"modulate",Color(2.2, 0.11, 0.11, 1.0),0.3)
				tween.tween_property(self,"modulate",Color("ffffff"),0.3)
				return
			pressed.emit(health_change)
			set_state(panel_state.HOVER)
		if event.is_released():
			if last_state == panel_state.DISABLED || last_state == panel_state.DISABLEDRED:
				return
			set_state(last_state)
			if get_global_rect().has_point(get_global_mouse_position()):
				clicked.emit()
			else:
				pressed.emit(-1)
