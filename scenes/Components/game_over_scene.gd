extends Control
class_name GameOverScene
@onready var transition: ColorRect = $Transition

@onready var label: Label = $Label
@onready var score_label: Label = $VBoxContainer/HBoxContainer/ScoreLabel
@onready var high_score_label: Label = $VBoxContainer/HBoxContainer2/HighScoreLabel
@onready var shader_rect: ColorRect = $ShaderRect
@onready var new_run_button: Button = $NewRunButton
@onready var main_menu_button: Button = $MainMenuButton

@onready var new_high_score_label: Label = $VBoxContainer/NewHighScoreLabel

var gameScene : PackedScene = load("res://scenes/Screens/GameScene.tscn")
var mainMenuScene : PackedScene = load("res://scenes/Screens/MainMenuScreen.tscn")


func set_data(won: bool, score: int) -> void:
	if won:
		label.text = "Victorious"
		label.label_settings.font_color = Color("c9a060")
		score_label.label_settings.font_color = Color("c9a060")
		high_score_label.label_settings.font_color = Color("c9a060")
		shader_rect.material.set_shader_parameter("tint", Color("c9a060"))
	else:
		label.text = "Slain"
		label.label_settings.font_color = Color("c43030")
		score_label.label_settings.font_color = Color("c43030")
		high_score_label.label_settings.font_color = Color("c43030")
		shader_rect.material.set_shader_parameter("tint", Color("ba1c1c"))

	high_score_label.text = str(Game.high_score)
	score_label.text = str(score)

	if score >= Game.high_score:
		SaveManager.save_score(score)
		new_high_score_label.visible = true

	var accent := Color("c9a060") if won else Color("c43030")
	var accent_dim := Color("2e2010") if won else Color("2a0808")
	_style_buttons(accent, accent_dim)

	var tween := create_tween()
	tween.tween_property(transition, "modulate:a", 0, 2)

func _style_buttons(accent: Color, accent_dim: Color) -> void:
	for btn : Button in [new_run_button, main_menu_button]:
		var is_primary := btn == new_run_button

		var normal := StyleBoxFlat.new()
		normal.bg_color = accent_dim 
		normal.border_color = accent 
		normal.border_width_top = 1
		normal.border_width_bottom = 1
		normal.border_width_left = 1
		normal.border_width_right = 1
		normal.corner_radius_top_left = 2
		normal.corner_radius_top_right = 2
		normal.corner_radius_bottom_left = 2
		normal.corner_radius_bottom_right = 2

		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = accent_dim.lightened(0.05) if is_primary else Color("0e0c04")

		var pressed := normal.duplicate() as StyleBoxFlat
		pressed.bg_color = accent_dim.darkened(0.1) if is_primary else Color("111008")

		for state : String in ["normal", "hover", "pressed", "focus"]:
			btn.add_theme_stylebox_override(state,
				normal if state == "normal" else
				hover if state == "hover" else
				pressed if state == "pressed" else
				normal)

		var font_color := accent if is_primary else Color("878787")
		for font_state : String in ["font_color", "font_hover_color", "font_pressed_color",
				"font_focus_color", "font_hover_pressed_color"]:
			btn.add_theme_color_override(font_state, font_color)

func set_tutorial_done() -> void:
	label.text = "Tutorial Completed"
	label.label_settings.font_color = Color.DARK_GREEN
	score_label.text = "Click restart to start the real run."
	
func _on_button_pressed() -> void:
	Game.reset()
	get_tree().change_scene_to_packed(gameScene)


func _on_button_2_pressed() -> void:
	Game.reset()
	get_tree().change_scene_to_packed(mainMenuScene)
