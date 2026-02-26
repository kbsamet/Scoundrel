extends Control
@onready var room_scene: RoomScene = $RoomScene
@onready var held_card: Panel = $HeldCard
const CardSceneScene := preload("res://scenes/CardScene.tscn")
@onready var health_panel: Panel = $HealthPanel
@onready var health_label: Label = $HealthPanel/HealthLabel
@onready var health_rect: ColorRect = $HealthPanel/HealthRect
@onready var game_over_scene: GameOverScene = $GameOverScene

@onready var deck: TextureRect = $Deck
@onready var flee_button: Button = $FleeButton
@onready var discard_pile: Panel = $DiscardPile
@onready var fist_select: Panel = $FistSelect

const attack_button_scene = preload("res://scenes/AttackButtonScene.tscn")
var selected_card := -1

func _ready() -> void:
	Game.reset()
	room_scene.discard_pile = discard_pile
	room_scene.deck_position = deck.global_position
	await get_tree().create_timer(1.0).timeout
	for i in range(4):
		var card := Game.draw_card()
		animate_draw_to_slot(i, card)



func card_clicked(id : int) -> void:
	if selected_card == id:
		selected_card = -1
		remove_attack_button(id)
		return
	elif selected_card != -1:
		remove_attack_button(selected_card)
	if room_scene.card_slots[id].get_child_count() == 0:
		return

	set_attack_button(id)
	selected_card = id


func make_card_move(id : int, secondary_attack : bool = false) -> void:
	
	if selected_card != -1:
		remove_attack_button(selected_card)
		selected_card = -1
	var id_card : Card = room_scene.get_card(id)
	if id_card.type == Card.card_type.WEAPON:
		await discard_held_card()
		var card := await room_scene.remove_card(id,false)
		var card_scene : CardScene = CardSceneScene.instantiate()
		held_card.add_child(card_scene)
		card_scene.global_position = room_scene.card_slots[id].global_position
		card_scene.setup(card,-1)
		animate_move_to_held(card_scene,Vector2.ZERO)

	elif id_card.type == Card.card_type.POTION:
		var card := await room_scene.remove_card(id)
		Game.heal(card.rank)
		update_health()
	else:
		if room_scene.get_card(id).rank > Game.held_weapon_max_dmg and !secondary_attack:
			return
		var card := await room_scene.get_card(id)
		
		var card_scene : CardScene = CardSceneScene.instantiate()
		if held_card.get_child_count() == 0 or secondary_attack:
			Game.take_damage(card.rank)
			await room_scene.remove_card(id)
		else:
			var weapon : CardScene = held_card.get_child(0) 
			var dmg : int = max(0,card.rank - weapon.card.rank)
			Game.take_damage(dmg)
			Game.held_weapon_max_dmg = card.rank
			Game.held_weapon_monster_amt += 1

			await room_scene.remove_card(id,false)
			held_card.get_child(0).add_child(card_scene)
			card_scene.global_position = room_scene.card_slots[id].global_position
			card_scene.setup(card,-1)
			animate_move_to_held(card_scene,Vector2(25 * Game.held_weapon_monster_amt,25*Game.held_weapon_monster_amt))
		
		update_health()
	
	
	Game.flee_available = false
	flee_button.disabled = true
	if room_scene.get_card_count() == 1:
		var won := fill_room()
		if won:
			game_over_scene.visible = true
			game_over_scene.set_game_won()
	
func remove_attack_button(id:int) -> void:
	if room_scene.card_slots[id].get_child_count() == 0:
		return
	var card_scene : CardScene = room_scene.card_slots[id].get_child(0)
	var tween := create_tween()
	tween.tween_property(card_scene,"scale",Vector2(1,1),0.1) \
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	for child in card_scene.get_children():
		card_scene.remove_child(child)

func set_attack_button(id : int) -> void:
	var card := room_scene.get_card(id)
	if card != null:
		var card_scene : CardScene = room_scene.card_slots[id].get_child(0)
		var tween := create_tween()
		tween.tween_property(card_scene,"scale",Vector2(1.2,1.2),0.1) \
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		for child in card_scene.get_children():
			card_scene.remove_child(child)
		var attack_button : AttackButtonScene = attack_button_scene.instantiate()
		card_scene.add_child(attack_button)
		attack_button.clicked.connect(func(first : bool) -> void: make_card_move(id,!first))
		var held_card : Card = null if held_card.get_child_count() == 0 else held_card.get_child(0).card
		attack_button.set_data(card,held_card)
		attack_button.position = Vector2(-card_scene.size.x/4,280)

func fill_room() -> bool:
	var card_drawn := false
	for i in range(4):
		if room_scene.get_card(i) == null:
			var card := Game.draw_card()
			if card != null:
				animate_draw_to_slot(i, card)
				card_drawn = true
	
	Game.flee_available = true
	flee_button.disabled = false
	

	return !card_drawn

func animate_draw_to_slot(slot: int, card: Card) -> void:
	var card_scene: CardScene = CardSceneScene.instantiate()
	
	var target_slot: Panel = room_scene.card_slots[slot]
	var target_pos := target_slot.global_position
	
	target_slot.add_child(card_scene)
	
	card_scene.setup(card, slot)
	
	card_scene.global_position = deck.global_position
	card_scene.size = card_scene.custom_minimum_size
	
	
	var tween := create_tween()
	tween.tween_property(card_scene, "global_position", target_pos, 0.3)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	tween.finished.connect(func() -> void:
		card_scene.position = Vector2.ZERO
		card_scene.clicked.connect(card_clicked)
	)
	
func animate_move_to_held(card_scene: CardScene,offset : Vector2) -> void:
	if selected_card != -1:
		remove_attack_button(selected_card)
		selected_card = -1
	add_child(card_scene)
	
	var start_pos := card_scene.global_position
	var target_pos := held_card.global_position + offset
	
	card_scene.global_position = start_pos
	card_scene.size = card_scene.custom_minimum_size
	
	var tween := create_tween()
	tween.tween_property(card_scene, "global_position", target_pos, 0.8)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
func discard_held_card() -> void:
	if held_card.get_child_count() == 0:
		return
	
	var weapon_scene: CardScene = held_card.get_child(0)
	var monsters: Array = weapon_scene.get_children()
	
	# First tween all monsters on top of the weapon card
	if monsters.size() != 0:
		var gather_tween := create_tween()
		gather_tween.set_parallel(true)
		for monster : CardScene in monsters:
			gather_tween.tween_property(monster, "position", Vector2.ZERO, 0.3)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_OUT)
		
		await gather_tween.finished
	
	held_card.remove_child(weapon_scene)
	discard_pile.add_child(weapon_scene)
	weapon_scene.global_position = held_card.global_position
	weapon_scene.size = weapon_scene.custom_minimum_size
	
	var discard_tween := create_tween()
	discard_tween.tween_property(weapon_scene, "global_position", discard_pile.global_position, 0.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	await discard_tween.finished
	
	Game.held_weapon_max_dmg = INF
	Game.held_weapon_monster_amt = 0
	
func update_health() -> void:
	health_label.text = str(Game.health) + "/ 20"
	var new_size :=( ( float(Game.health) / 20.0 ) * health_panel.size.x ) - 5.0
	var tween := create_tween()
	tween.tween_property(health_rect, "size", Vector2(new_size,health_rect.size.y), 0.3)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	if Game.health <= 0:
		game_over_scene.visible = true
		return
func _on_flee_button_pressed() -> void:
	if Game.flee_available:
		if selected_card != -1:
			remove_attack_button(selected_card)
			selected_card = -1
		for i in range(4):
			await room_scene.move_card_to_back_of_deck(i)
	
		for i in range(4):
			var card := Game.draw_card()
			if card != null:
				animate_draw_to_slot(i, card)
		
		Game.flee_available = false
		flee_button.disabled = true
		


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.is_released():
			if selected_card != -1:
				remove_attack_button(selected_card)
				selected_card = -1
