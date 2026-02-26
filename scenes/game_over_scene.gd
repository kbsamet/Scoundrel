extends Control
class_name GameOverScene

@onready var label: Label = $TextureRect/Label

func _on_button_pressed() -> void:
	Game.reset()
	visible = false
	get_tree().reload_current_scene()

func set_game_won() -> void:
	label.text = "You Win"
	label.label_settings.font_color = Color.DARK_GREEN
