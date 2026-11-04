extends Control
class_name GameOverScene

## Emitted once the player has watched a rewarded ad and earned a revive.
signal revived

## How far New Run / Main Menu move down to make room for the Revive button.
const REVIVE_BUTTON_SHIFT := 132.0
@onready var transition: ColorRect = $Transition

@onready var label: Label = $Label
@onready var score_label: Label = $VBoxContainer/HBoxContainer/ScoreLabel
@onready var high_score_label: Label = $VBoxContainer/HBoxContainer2/HighScoreLabel
@onready var shader_rect: ColorRect = $ShaderRect
@onready var new_run_button: Button = $NewRunButton
@onready var main_menu_button: Button = $MainMenuButton
@onready var revive_button: Button = $ReviveButton
@onready var high_score_text: Label = $VBoxContainer/HBoxContainer2/HighScoreText
@onready var new_difficulty_label: Label = $VBoxContainer/NewDifficultyLabel

@onready var new_high_score_label: Label = $VBoxContainer/NewHighScoreLabel

var gameScene : PackedScene = load("res://scenes/Screens/DifficultySelectScreen.tscn")
var mainMenuScene : PackedScene = load("res://scenes/Screens/MainMenuScreen.tscn")

var _transition_tween : Tween
var _buttons_shifted := false


func set_data(won: bool, score: int, allow_revive: bool = false) -> void:
	_set_revive_available(
		not won and allow_revive and AdManager.is_supported() and Game.can_revive()
	)

	if won:
		label.text = "Victorious"
		label.label_settings.font_color = Color("c9a060")
		new_difficulty_label.label_settings.font_color = Color("c9a060")
		score_label.label_settings.font_color = Color("c9a060")
		high_score_label.label_settings.font_color = Color("c9a060")
		shader_rect.material.set_shader_parameter("tint", Color("c9a060"))
		
		var unlocked : = SaveManager.get_unlocked_difficulties()
		
		match Game.difficulty:
			"Standard":
				if "Veteran" not in unlocked:
					new_difficulty_label.visible = true
					SaveManager.unlock_difficulty("Veteran")
			"Veteran":
				if "Condemned" not in unlocked:
					new_difficulty_label.visible = true
					SaveManager.unlock_difficulty("Condemned")
	else:
		label.text = "Slain"
		label.label_settings.font_color = Color("c43030")
		score_label.label_settings.font_color = Color("c43030")
		high_score_label.label_settings.font_color = Color("c43030")
		shader_rect.material.set_shader_parameter("tint", Color("ba1c1c"))

	high_score_label.text = str(Game.high_score)
	score_label.text = str(score)

	if score >= Game.high_score:
		# A revived run can die again with a lower score; keep the best one saved.
		if score > SaveManager.load_score():
			SaveManager.save_score(score)
		high_score_text.text = "Previous High Score:"
		new_high_score_label.visible = true

	var accent := Color("c9a060") if won else Color("c43030")
	var accent_dim := Color("2e2010") if won else Color("2a0808")
	_style_buttons(accent, accent_dim)

	_transition_tween = create_tween()
	_transition_tween.tween_property(transition, "modulate:a", 0, 2)

## Hides the screen and puts it back in its initial state for the next death.
func close_for_revive() -> void:
	visible = false
	if _transition_tween:
		_transition_tween.kill()
	transition.modulate.a = 1
	new_high_score_label.visible = false
	high_score_text.text = "High Score:"
	_set_revive_available(false)

func _set_revive_available(available: bool) -> void:
	revive_button.visible = available
	revive_button.disabled = false
	_update_revive_text()
	if available == _buttons_shifted:
		return
	_buttons_shifted = available
	var shift := REVIVE_BUTTON_SHIFT if available else -REVIVE_BUTTON_SHIFT
	for btn : Button in [new_run_button, main_menu_button]:
		btn.offset_top += shift
		btn.offset_bottom += shift

func _update_revive_text() -> void:
	revive_button.text = tr("revive_button") % (Game.MAX_REVIVES - Game.revives_used)

func _set_buttons_disabled(is_disabled: bool) -> void:
	for btn : Button in [revive_button, new_run_button, main_menu_button]:
		btn.disabled = is_disabled

func _on_revive_button_pressed() -> void:
	if AdManager.is_busy():
		return
	_set_buttons_disabled(true)
	revive_button.text = tr("revive_loading")
	var result := await AdManager.show_rewarded_ad()
	_set_buttons_disabled(false)
	match result:
		AdManager.Result.REWARDED:
			revived.emit()
		AdManager.Result.FAILED:
			revive_button.text = tr("revive_unavailable")
		_:
			_update_revive_text()

func _style_buttons(accent: Color, accent_dim: Color) -> void:
	for btn : Button in [revive_button, new_run_button, main_menu_button]:
		var is_primary := btn != main_menu_button

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
		hover.bg_color = accent_dim.lightened(0.05) 

		var pressed := normal.duplicate() as StyleBoxFlat
		pressed.bg_color = accent_dim.lightened(0.05)

		for state : String in ["normal", "hover", "pressed", "focus", "disabled"]:
			btn.add_theme_stylebox_override(state,
				normal if state == "normal" else
				hover if state == "hover" else
				pressed if state == "pressed" else
				pressed if state == "focus" else
				normal)

		var font_color := accent if is_primary else Color("878787")
		for font_state : String in ["font_color", "font_hover_color", "font_pressed_color",
				"font_focus_color", "font_hover_pressed_color"]:
			btn.add_theme_color_override(font_state, font_color)
		btn.add_theme_color_override("font_disabled_color", font_color.darkened(0.4))

		for icon_state : String in ["icon_normal_color", "icon_hover_color", "icon_pressed_color",
				"icon_focus_color", "icon_hover_pressed_color"]:
			btn.add_theme_color_override(icon_state, font_color)
		btn.add_theme_color_override("icon_disabled_color", font_color.darkened(0.4))

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
