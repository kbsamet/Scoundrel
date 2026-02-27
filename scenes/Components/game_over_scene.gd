extends Control
class_name GameOverScene

@onready var label: Label = $Label
@onready var score_label: Label = $ScoreLabel

func set_data(won : bool, score : int) -> void:
	if won:
		label.text = "You Win"
		label.label_settings.font_color = Color.DARK_GREEN
	else:
		label.text = "Game Over"
		label.label_settings.font_color = Color("ff2929")
	
	if score > Game.high_score:
		SaveManager.save_score(score)
		score_label.text = "New high score! : " + str(score)
	else:
		score_label.text = "Your Score was: "+ str(score) +"\nHigh score : " + str(Game.high_score)
func _on_button_pressed() -> void:
	Game.reset()
	visible = false
	get_tree().reload_current_scene()
