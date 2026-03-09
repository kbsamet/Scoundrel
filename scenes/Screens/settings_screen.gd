extends ColorRect
class_name SettingsScreen

@onready var sfx_slider:   HSlider = $Panel/MarginContainer/VBoxContainer/HBoxContainer2/SFXSlider
@onready var sfx_level:    Label   = $Panel/MarginContainer/VBoxContainer/HBoxContainer2/SFXLevel
@onready var normal_btn: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer3/NormalSpeedButton
@onready var fast_btn: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer3/FastSpeedButton
@onready var reset_save: Button = $"Panel/MarginContainer/VBoxContainer/HBoxContainer4/Reset Save"
@onready var abandon_run: Button = $"Panel/MarginContainer/VBoxContainer/HBoxContainer4/Abandon Run"

var main_menu_scene : PackedScene = load("res://scenes/Screens/MainMenuScreen.tscn")

var reset_save_armed := false
var abandon_run_armed := false
signal close

var _settings: Dictionary = {}

func _ready() -> void:
	_settings = SaveManager.load_settings()
	print("settings: " + str(_settings))
	_apply_to_ui()
	if get_parent() is not GameScene:
		abandon_run.visible = false
	
func _apply_to_ui() -> void:
	sfx_slider.value = _settings["sfx_volume"]
	sfx_level.text   = str(_settings["sfx_volume"])
	_apply_sfx_volume(_settings["sfx_volume"])
	var speed_btns := [normal_btn, fast_btn]
	_set_speed_active(speed_btns[_settings["anim_speed"]])

func _on_sfx_slider_value_changed(value: float) -> void:
	_settings["sfx_volume"] = int(value)
	sfx_level.text = str(int(value))
	_apply_sfx_volume(int(value))
	SaveManager.save_settings(_settings)

func _apply_sfx_volume(value: int) -> void:
	if value == 0:

		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)

		var db := linear_to_db(value / 100.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func _set_speed_active(active: Button) -> void:
	for btn: Button in [normal_btn, fast_btn]:
		var is_active := btn == active

		var target_bg     := Color("#3a2a10") if is_active else Color("#1a1614")
		var target_border := Color("#8a6830") if is_active else Color("#2e2520")
		var target_text   := Color("#c9a878") if is_active else Color("#3a2e26")

		# Get existing style or build a fresh one
		var style: StyleBoxFlat
		if btn.has_theme_stylebox_override("normal"):
			style = btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		else:
			style = StyleBoxFlat.new()
			style.border_width_top    = 1
			style.border_width_bottom = 1
			style.border_width_left   = 1
			style.border_width_right  = 1
			style.corner_radius_top_left     = 2
			style.corner_radius_top_right    = 2
			style.corner_radius_bottom_left  = 2
			style.corner_radius_bottom_right = 2

		for state : String in ["normal", "focus", "hover", "pressed"]:
			btn.add_theme_stylebox_override(state, style)

		var tween := create_tween().set_parallel()

		tween.tween_method(
			func(c: Color) -> void: style.bg_color = c,
			style.bg_color, target_bg, 0.2
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		tween.tween_method(
			func(c: Color) -> void: style.border_color = c,
			style.border_color, target_border, 0.2
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

		for font_override : String in ["font_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color", "font_hover_color"]:
			var current := btn.get_theme_color(font_override) \
			if btn.has_theme_color_override(font_override) \
			else Color("#3a2e26")
			tween.tween_method(
				func(c: Color) -> void: btn.add_theme_color_override(font_override, c),
				current, target_text, 0.2
				).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_normal_speed_button_pressed() -> void:
	_settings["anim_speed"] = 0
	_set_speed_active(normal_btn)
	Game.fast_mode = false
	SaveManager.save_settings(_settings)



func _on_fast_speed_button_pressed() -> void:
	_settings["anim_speed"] = 1
	_set_speed_active(fast_btn)
	Game.fast_mode = true
	SaveManager.save_settings(_settings)


func _on_reset_save_pressed() -> void:
	if !reset_save_armed:
		reset_save.text = "Tap to Confirm"
		reset_save_armed = true
		await get_tree().create_timer(2).timeout
		reset_save.text = "Reset Save"
		reset_save_armed = false
	else:
		reset_save_armed = false
		reset_save.text = "Reset Save"
		SaveManager.reset()
		_settings = SaveManager.load_settings()
		_apply_to_ui()


func _on_abandon_run_pressed() -> void:
	if !abandon_run_armed:
		abandon_run.text = "Tap to Confirm"
		abandon_run_armed = true
		await get_tree().create_timer(2).timeout
		abandon_run.text = "Abandon Run"
		abandon_run_armed = false
	else:
		abandon_run_armed = false
		abandon_run.text = "Abandon Run"
		SaveManager.clear_run()
		TutorialManager.active = false
		close.emit()
		get_tree().change_scene_to_packed(main_menu_scene)


func _on_close_button_pressed() -> void:
	close.emit()
