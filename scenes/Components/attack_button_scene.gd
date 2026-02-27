extends Control
class_name AttackButtonScene

@onready var first_option: AttackOptionScene = $VBoxContainer/FirstOption
@onready var second_option: AttackOptionScene = $VBoxContainer/SecondOption
@onready var h_box_container: HBoxContainer = $VBoxContainer/FirstOption/HBoxContainer
@onready var single_icon: TextureRect = $VBoxContainer/FirstOption/SingleIcon

signal clicked(first: bool)

func _ready() -> void:
	first_option.clicked.connect(_on_first_clicked)
	second_option.clicked.connect(_on_second_clicked)

func _on_first_clicked() -> void:
	clicked.emit(true)

func _on_second_clicked() -> void:
	clicked.emit(false)

func set_data(card: Card, held_card: Card) -> void:
	match card.type:
		Card.card_type.WEAPON:
			first_option.amount.visible = false
			h_box_container.visible = false
			single_icon.visible = true
		Card.card_type.POTION:
			first_option.first.texture = load("res://sprites/potion.png")
			first_option.amount.text = "+" + str(card.rank)
		Card.card_type.ENEMY:
			if held_card == null:
				first_option.first.texture = load("res://sprites/fist.png")
				first_option.amount.text = "-" + str(card.rank)
				if card.rank >= Game.health:
					first_option.set_state(AttackOptionScene.panel_state.RED)
			else:
				second_option.visible = true
				first_option.first.texture = load("res://sprites/sword.png")
				second_option.first.texture = load("res://sprites/fist.png")
				first_option.amount.text = "-" + str(max(0, card.rank - held_card.rank))
				second_option.amount.text = "-" + str(card.rank)
				second_option
				if card.rank > Game.held_weapon_max_dmg:
					first_option.set_state(AttackOptionScene.panel_state.DISABLED)
				elif max(0, card.rank - held_card.rank) >= Game.health:
					first_option.set_state(AttackOptionScene.panel_state.RED)
				if card.rank >= Game.health:
					second_option.set_state(AttackOptionScene.panel_state.RED)
