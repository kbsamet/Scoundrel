extends Control
class_name AttackButtonScene

@onready var first_amount: Label = $FirstOption/FirstAmount
@onready var h_box_container: HBoxContainer = $FirstOption/HBoxContainer
@onready var second_option: Panel = $SecondOption
@onready var second_amount: Label = $SecondOption/SecondAmount
@onready var first: TextureRect = $FirstOption/HBoxContainer/First
@onready var single_icon: TextureRect = $FirstOption/SingleIcon
@onready var first_option: Panel = $FirstOption

@onready var first_skull: TextureRect = $FirstOption/FirstSkull
@onready var second_skull: TextureRect = $SecondOption/SecondSkull
@onready var disable_rect: ColorRect = $FirstOption/DisableRect
@onready var second_disable_rect: ColorRect = $SecondOption/SecondDisableRect

signal clicked(first: bool)

enum panel_state {DISABLED,RED,NORMAL,HOVER}

var first_last_state : panel_state = panel_state.NORMAL
var second_last_state : panel_state = panel_state.NORMAL

func set_data(card: Card,held_card: Card) -> void:
	match card.type:
		Card.card_type.WEAPON:
			first_amount.visible = false
			h_box_container.visible = false
			single_icon.visible = true
		Card.card_type.POTION:
			first.texture = load("res://sprites/potion.png")
			first_amount.text = "+" + str(card.rank)
		Card.card_type.ENEMY:
			if held_card == null:
				first.texture = load("res://sprites/fist.png")
				first_amount.text = "-" + str(card.rank)
				if card.rank >= Game.health:
					set_panel(first_option,panel_state.RED,true)
			else:
				second_option.visible = true
				first.texture = load("res://sprites/sword.png")
				first_amount.text = "-" + str(max(0,card.rank - held_card.rank))
				second_amount.text = "-" + str(card.rank)
				if card.rank > Game.held_weapon_max_dmg:
					set_panel(first_option,panel_state.DISABLED,true)
				elif max(0,card.rank - held_card.rank) >= Game.health:
					set_panel(first_option,panel_state.RED,true)
				if card.rank >= Game.health:
					set_panel(second_option,panel_state.RED,false)

func _on_first_option_gui_input(event: InputEvent) -> void:
	if first_last_state == panel_state.DISABLED:
		return
	if event is InputEventScreenTouch:
		if event.is_pressed():
			set_panel(first_option,panel_state.HOVER,true)
		if event.is_released():
			set_panel(first_option,first_last_state,true)
			
			if first_option.get_rect().has_point(event.position):
				clicked.emit(true)


func _on_second_option_gui_input(event: InputEvent) -> void:
	if second_last_state == panel_state.DISABLED:
		return
	if event is InputEventScreenTouch:
		if event.is_pressed():
			set_panel(second_option,panel_state.HOVER,false)

		if event.is_released():
			set_panel(second_option,second_last_state,false)
			clicked.emit(false)

func set_panel(panel : Panel, state : panel_state,first: bool) -> void:
	if state != panel_state.HOVER:
		if first:
			first_last_state = state
		else:
			second_last_state = state
	match state:
		panel_state.DISABLED:
			disable_rect.visible = true
			var style : StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
			style.border_color = Color("8f8f8f")
			style.bg_color = Color("1f1f1f")
			panel.add_theme_stylebox_override("panel", style)
		panel_state.RED:
			if first:
				first_skull.visible = true 
			else:
				second_skull.visible = true 
			var style : StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
			style.border_color = Color("e42833")
			style.bg_color = Color("1f1f1f")
			panel.add_theme_stylebox_override("panel", style)
		panel_state.NORMAL:
			var style := panel.get_theme_stylebox("panel").duplicate()
			style.bg_color = Color("1f1f1f")
			panel.add_theme_stylebox_override("panel", style)
		panel_state.HOVER:
			var style := panel.get_theme_stylebox("panel").duplicate()
			style.bg_color = Color("3d3d3d")
			panel.add_theme_stylebox_override("panel", style)
