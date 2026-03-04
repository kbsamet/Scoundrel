extends Control
class_name RoomScene

@onready var card_slots : Array[Panel] = [$HBoxContainer/Card1,$HBoxContainer/Card2,$HBoxContainer/Card3,$HBoxContainer/Card4]
const CardSceneScene := preload("res://scenes/Components/CardScene.tscn")
var discard_pile : Panel
var deck_position : Vector2

func add_card(slot : int, card: Card) -> CardScene:
	assert(slot >= 0,"slot has to be above -1")
	assert(slot < 4,"slot has to be below 4")
	if card_slots[slot].get_child_count() != 0:
		print("Attempting to place card at a filled spot !")
		return
	var card_scene : CardScene = CardSceneScene.instantiate()
	card_slots[slot].add_child(card_scene)
	card_scene.position = Vector2(0,0)
	card_scene.setup(card,slot)
	return card_scene

func remove_card(slot: int, animated : bool = true) -> Card:
	assert(slot >= 0, "slot has to be above -1")
	assert(slot < 4, "slot has to be below 4")

	if card_slots[slot].get_child_count() == 0:
		print("Attempting to remove card at an empty spot!")
		return null

	var card_scene: CardScene = card_slots[slot].get_child(0)
	var card := Card.from(card_scene.card)
	if !animated:
		card_slots[slot].remove_child(card_scene)
		card_scene.queue_free()
		return card
	
	card_slots[slot].remove_child(card_scene)
	discard_pile.add_child(card_scene)
	card_scene.global_position = card_slots[slot].global_position
	card_scene.size = card_scene.custom_minimum_size
	
	var tween := create_tween()
	tween.tween_property(card_scene, "global_position", discard_pile.global_position, 0.4)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN_OUT)
		
	Game.set_state(Game.GameState.ANIMATING)
	await tween.finished
	Game.set_state(Game.GameState.PLAYING)
	for n in discard_pile.get_children():
		if n == card_scene:
			continue
		discard_pile.remove_child(n)
	
	card_scene.global_position = discard_pile.global_position

	return card

func move_card_to_back_of_deck(slot:int) -> Card:
	assert(slot >= 0, "slot has to be above -1")
	assert(slot < 4, "slot has to be below 4")

	if card_slots[slot].get_child_count() == 0:
		print("Attempting to remove card at an empty spot!")
		return null

	var card_scene: CardScene = card_slots[slot].get_child(0)
	var card := Card.from(card_scene.card)
	Game.deck.append(card)
		
	var tween := create_tween()
	tween.tween_property(card_scene, "global_position", deck_position, 0.4)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN_OUT)
		
	Game.set_state(Game.GameState.ANIMATING)
	await tween.finished
	Game.set_state(Game.GameState.PLAYING)
	
	card_slots[slot].remove_child(card_scene)
	card_scene.queue_free()

	return card

func get_card(slot : int) -> Card:
	assert(slot >= 0,"slot has to be above -1")
	assert(slot < 4,"slot has to be below 4")
	if card_slots[slot].get_child_count() == 0:
		return null
	var card_scene : CardScene = card_slots[slot].get_child(0)
	return card_scene.card

func get_card_count() -> int:
	var count := 0
	for i in range(4):
		if card_slots[i].get_child_count() > 0:
			count += 1
	return count
