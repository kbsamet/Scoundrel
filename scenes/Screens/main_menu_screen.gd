extends Control

@onready var continue_run_button: Button = $MarginContainer/VBoxContainer/ContinueRunButton
@onready var new_run_button: Button = $MarginContainer/VBoxContainer/NewRunButton
@onready var settings_button: Button = $MarginContainer/VBoxContainer/SettingsButton
@onready var settings_screen: SettingsScreen = $SettingsScreen
@onready var replay_tutorial_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/ReplayTutorialButton

var gameScene : PackedScene = load("res://scenes/Screens/DifficultySelectScreen.tscn")
var gamePlayScene : PackedScene = load("res://scenes/Screens/GameScene.tscn")

func _ready() -> void:
	if SaveManager.has_active_run():
		continue_run_button.disabled = false
	settings_screen.close.connect(func() -> void: settings_screen.visible = false)
	if SaveManager.has_seen_tutorial():
		replay_tutorial_button.visible = true
		

func _on_continue_run_button_pressed() -> void:
	print("loading run")
	var scene := gamePlayScene.instantiate()
	scene.game_loaded = true
	var old_scene := get_tree().current_scene
	get_tree().root.add_child(scene)
	await get_tree().process_frame  # _ready fires here, @onready resolves
	scene.game_loaded = true        # set AFTER ready so @onready are valid
	get_tree().current_scene = scene
	old_scene.queue_free()


func _on_new_run_button_pressed() -> void:
	get_tree().change_scene_to_packed(gameScene)


func _on_settings_button_pressed() -> void:
	settings_screen.visible = true


func _on_continue_run_button_focus_entered() -> void:
	if continue_run_button.disabled:
		continue_run_button.release_focus()


func _on_new_run_button_button_up() -> void:
	new_run_button.release_focus()


func _on_continue_run_button_button_up() -> void:
	continue_run_button.release_focus()


func _on_replay_tutorial_button_pressed() -> void:
	SaveManager.reset_tutorial()
	Game.difficulty = "Beginner"
	get_tree().change_scene_to_packed(gamePlayScene)
