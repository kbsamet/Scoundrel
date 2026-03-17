extends Control
@onready var v_box_container: VBoxContainer = $MarginContainer/VBoxContainer
const OPTION_SCENE = preload("res://scenes/Components/DifficultyOptionScene.tscn")
const MAIN_MENU_SCENE = preload("res://scenes/Screens/MainMenuScreen.tscn")
const GAME_SCENE = preload("res://scenes/Screens/GameScene.tscn")
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var control: Control = $MarginContainer/VBoxContainer/Control3

const DIFFICULTY_DATA := {
	"Squire": {
		"tier": "Beginner",
		"pips": 1,
		"accent": Color("#6ab85a"),
		"accent_dim": Color("#162810"),
		"border": Color("#3a5a28"),
		"tags": [
			["Start with 20 HP",        DifficultyTag.TagLevel.NORMAL],
			["No Potion Limit",         DifficultyTag.TagLevel.EASY],
			["Easier Deck",             DifficultyTag.TagLevel.EASY],
		]
	},
	"Rogue": {
		"tier": "Standard",
		"pips": 2,
		"accent": Color("#c9a060"),
		"accent_dim": Color("#2a1e08"),
		"border": Color("#4a3818"),
		"tags": [
			["Start with 20 HP",  DifficultyTag.TagLevel.NORMAL],
			["No Potion Limit",   DifficultyTag.TagLevel.EASY],
			["Standard deck",     DifficultyTag.TagLevel.NORMAL],
		]
	},
	"Scoundrel": {
		"tier": "Veteran",
		"pips": 3,
		"accent": Color("#e0a040"),
		"accent_dim": Color("#2a1a06"),
		"border": Color("#5a3c14"),
		"tags": [
			["Start with 20 HP",   DifficultyTag.TagLevel.NORMAL],
			["One Potion Per Room", DifficultyTag.TagLevel.HARD],
			["Standard deck",      DifficultyTag.TagLevel.NORMAL],
		]
	},
	"Villain": {
		"tier": "Condemned",
		"pips": 4,
		"accent": Color("#c43030"),
		"accent_dim": Color("#200808"),
		"border": Color("#5a1818"),
		"tags": [
			["Start with 20 HP",   DifficultyTag.TagLevel.NORMAL],
			["One Potion Per Room",     DifficultyTag.TagLevel.HARD],
			["Harder Deck",             DifficultyTag.TagLevel.HARD],
		]
	},
}

func _ready() -> void:
	for level : String in DIFFICULTY_DATA.keys():
		var option : DifficultyOption = OPTION_SCENE.instantiate()
		option.data = DIFFICULTY_DATA[level]
		option.clicked.connect(func() -> void : start_game(option.data["tier"]))
		v_box_container.add_child(option)
	v_box_container.move_child(back_button,-1)
	v_box_container.move_child(control,-2)

func start_game(difficulty: String) -> void:
	Game.difficulty = difficulty
	get_tree().change_scene_to_packed(GAME_SCENE)
	
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_packed(MAIN_MENU_SCENE)
