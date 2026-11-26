extends Control

@onready var continue_run_button: Button = $MarginContainer/VBoxContainer/ContinueRunButton
@onready var new_run_button: Button = $MarginContainer/VBoxContainer/NewRunButton
@onready var settings_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/SettingsButton
@onready var settings_screen: SettingsScreen = $SettingsScreen
@onready var replay_tutorial_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/ReplayTutorialButton
@onready var card_fan: Control = $MarginContainer/VBoxContainer/Control2/CardFan
@onready var best_label: Label = $MarginContainer/VBoxContainer/BestLabel

const CARD_TEXTURE := preload("res://sprites/cards.png")
const FAN_CARD_SIZE := Vector2(230, 320)
## [rank, suit] for the decorative hand: a monster of each black suit, a weapon, a potion.
const FAN_CARDS := [
	[11, Card.card_suit.CLUBS],
	[7, Card.card_suit.HEARTS],
	[10, Card.card_suit.DIAMONDS],
	[14, Card.card_suit.SPADES],
]

var gameScene : PackedScene = load("res://scenes/Screens/DifficultySelectScreen.tscn")
# TODO: replace with Popplin's real App Store link
const POPPLIN_APP_STORE_URL := "https://apps.apple.com/app/apple-store/id6773328628?pt=125892042&ct=scoundrel&mt=8"

var gamePlayScene : PackedScene = load("res://scenes/Screens/GameScene.tscn")

func _ready() -> void:
	if SaveManager.has_active_run():
		continue_run_button.disabled = false
	settings_screen.close.connect(func() -> void: settings_screen.visible = false)
	if SaveManager.has_seen_tutorial():
		replay_tutorial_button.visible = true
	var best := SaveManager.load_score()
	if best > 0:
		best_label.text = tr("hud_best") + " " + str(best)
		best_label.visible = true
	_build_card_fan()
	card_fan.resized.connect(_layout_card_fan)

func _build_card_fan() -> void:
	for i in range(FAN_CARDS.size()):
		var data : Array = FAN_CARDS[i]
		var atlas := AtlasTexture.new()
		atlas.atlas = CARD_TEXTURE
		atlas.region = Rect2(((data[0] - 1) % 13) * 128, data[1] * 178, 128, 178)
		var card := TextureRect.new()
		card.texture = atlas
		card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card.stretch_mode = TextureRect.STRETCH_SCALE
		card.size = FAN_CARD_SIZE
		card.pivot_offset = Vector2(FAN_CARD_SIZE.x / 2.0, FAN_CARD_SIZE.y * 1.6)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.modulate = Color(0.92, 0.86, 0.8)
		card_fan.add_child(card)
	_layout_card_fan()
	# Gentle idle sway so the menu doesn't feel static.
	var tween := create_tween().set_loops()
	tween.tween_property(card_fan, "position:y", -14.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card_fan, "position:y", 0.0, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _layout_card_fan() -> void:
	var count := card_fan.get_child_count()
	var center := card_fan.size / 2.0
	# Shrink the hand if the band between title and buttons is short.
	var fit : float = clamp((card_fan.size.y - 40.0) / (FAN_CARD_SIZE.y * 1.15), 0.4, 1.0)
	for i in range(count):
		var card := card_fan.get_child(i) as TextureRect
		var t := (float(i) - (count - 1) / 2.0)
		card.scale = Vector2(fit, fit)
		card.rotation_degrees = t * 11.0
		card.position = center - FAN_CARD_SIZE / 2.0 + Vector2(t * 120.0 * fit, abs(t) * 18.0 * fit)
		

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


func _on_popplin_banner_pressed() -> void:
	OS.shell_open(POPPLIN_APP_STORE_URL)
