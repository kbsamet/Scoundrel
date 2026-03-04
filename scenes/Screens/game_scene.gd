extends Control
@onready var room_scene: RoomScene = $RoomScene
@onready var held_card: Panel = $HeldCard
const CardSceneScene := preload("res://scenes/Components/CardScene.tscn")
@onready var health_panel: Panel = $HealthPanel
@onready var health_label: Label = $HealthPanel/HealthLabel
@onready var health_rect: ColorRect = $HealthPanel/HealthRect
@onready var game_over_scene: GameOverScene = $GameOverScene
@onready var ghost_rect: ColorRect = $HealthPanel/GhostRect
@onready var texture_container: Control = $HealthPanel/TextureContainer

@onready var deck: TextureRect = $Deck
@onready var flee_button: TextureButton = $FleeButton
@onready var discard_pile: Panel = $DiscardPile

@onready var punch_player: AudioStreamPlayer = $PunchPlayer
@onready var slash_player: AudioStreamPlayer = $SlashPlayer
@onready var equip_player: AudioStreamPlayer = $equipPlayer
@onready var drink_player: AudioStreamPlayer = $DrinkPlayer

const attack_button_scene = preload("res://scenes/Components/AttackButtonScene.tscn")
var selected_card := -1

func _ready() -> void:
	Game.reset()
	room_scene.discard_pile = discard_pile
	room_scene.deck_position = deck.global_position
	await get_tree().create_timer(1.0).timeout
	for i in range(4):
		var card := Game.draw_card()
		await animate_draw_to_slot(i, card)


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
		equip_player.play()
		var card := await room_scene.remove_card(id,false)
		var card_scene : CardScene = CardSceneScene.instantiate()	
		held_card.add_child(card_scene)
		card_scene.global_position = room_scene.card_slots[id].global_position
		card_scene.setup(card,-1)
		animate_move_to_held(card_scene,Vector2.ZERO)

	elif id_card.type == Card.card_type.POTION:
		drink_player.play()
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
			punch_player.play()

			await room_scene.remove_card(id)
		else:
			var weapon : CardScene = held_card.get_child(0) 
			var dmg : int = max(0,card.rank - weapon.card.rank)
			Game.take_damage(dmg)
			Game.held_weapon_max_dmg = card.rank
			Game.held_weapon_monster_amt += 1
			slash_player.play()
			await room_scene.remove_card(id,false)
			held_card.get_child(0).add_child(card_scene)
			card_scene.global_position = room_scene.card_slots[id].global_position
			card_scene.setup(card,-1)
			animate_move_to_held(card_scene,Vector2(25 * Game.held_weapon_monster_amt,25*Game.held_weapon_monster_amt))
		
		update_health()
	
	
	Game.flee_available = false
	flee_button.disabled = true
	if room_scene.get_card_count() == 1:
		fill_room()
		if Game.deck.size() == 0:
			deck.visible = false
			for i in range(4):
				if room_scene.get_card(i) != null:
					await room_scene.remove_card(i)
			
			game_over_scene.visible = true
			game_over_scene.set_data(true,Game.calculate_score(true))
	
func remove_attack_button(id:int) -> void:
	if room_scene.card_slots[id].get_child_count() == 0:
		return
	var card_scene : CardScene = room_scene.card_slots[id].get_child(0)
	var tween := create_tween()
	tween.tween_property(card_scene,"scale",Vector2(1,1),0.1) \
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	Game.set_state(Game.GameState.ANIMATING)
	tween.tween_callback(func() ->void : Game.set_state(Game.GameState.PLAYING))
	
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
		Game.set_state(Game.GameState.ANIMATING)
		tween.tween_callback(func() ->void : Game.set_state(Game.GameState.PLAYING))
		
		
		for child in card_scene.get_children():
			card_scene.remove_child(child)
		var attack_button : AttackButtonScene = attack_button_scene.instantiate()
		card_scene.add_child(attack_button)
		attack_button.clicked.connect(func(first : bool) -> void: make_card_move(id,!first))
		attack_button.pressed.connect(func(diff: int) -> void: update_health(Game.health + diff) if diff != -1 else update_health())
		var held_card : Card = null if held_card.get_child_count() == 0 else held_card.get_child(0).card
		attack_button.set_data(card,held_card)
		attack_button.position = Vector2(0,280)

func fill_room() -> bool:
	var card_drawn := false
	for i in range(4):
		if room_scene.get_card(i) == null:
			var card := Game.draw_card()
			if card != null:
				await animate_draw_to_slot(i, card)
				card_drawn = true
				
	
	var remaining_deck_ratio : float = float(Game.deck.size()) / float(Game.MAX_DECK_COUNT)
	remaining_deck_ratio = 1.0 - remaining_deck_ratio
	for i in range(floor(remaining_deck_ratio * deck.get_child_count())):
		deck.get_child(-i - 1).visible = false
	Game.flee_available = true
	flee_button.disabled = false
	

	return !card_drawn

func animate_draw_to_slot(slot: int, card: Card) -> void:
	var card_scene: CardScene = CardSceneScene.instantiate()
	
	var target_slot: Panel = room_scene.card_slots[slot]
	var target_pos := target_slot.global_position
	
	target_slot.add_child(card_scene)
	
	card_scene.setup(card, slot)
	card_scene.card_audio_player.play()
	
	card_scene.global_position = deck.global_position
	card_scene.size = card_scene.custom_minimum_size
	
	
	var tween := create_tween()
	tween.tween_property(card_scene, "global_position", target_pos, 0.3)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	Game.set_state(Game.GameState.ANIMATING)
	await tween.finished
	card_scene.position = Vector2.ZERO
	card_scene.clicked.connect(card_clicked)
	Game.set_state(Game.GameState.PLAYING)

	
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
	Game.set_state(Game.GameState.ANIMATING)
	tween.tween_callback(func() ->void : Game.set_state(Game.GameState.PLAYING))
	
func discard_held_card() -> void:
	if held_card.get_child_count() == 0:
		return
	
	var weapon_scene: CardScene = held_card.get_child(0)
	var monsters: Array = weapon_scene.get_children()
	monsters = monsters.filter(func(child : Node) -> bool: return child is CardScene)
	# First tween all monsters on top of the weapon card
	if monsters.size() != 0:
		var gather_tween := create_tween()
		gather_tween.set_parallel(true)
		for monster : CardScene in monsters:
			gather_tween.tween_property(monster, "position", Vector2.ZERO, 0.3)\
				.set_trans(Tween.TRANS_CUBIC)\
				.set_ease(Tween.EASE_OUT)
			Game.set_state(Game.GameState.ANIMATING)
			gather_tween.tween_callback(func() ->void : Game.set_state(Game.GameState.PLAYING))
		
		await gather_tween.finished
	
	held_card.remove_child(weapon_scene)
	discard_pile.add_child(weapon_scene)
	weapon_scene.global_position = held_card.global_position
	weapon_scene.size = weapon_scene.custom_minimum_size
	
	var discard_tween := create_tween()
	discard_tween.tween_property(weapon_scene, "global_position", discard_pile.global_position, 0.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	Game.set_state(Game.GameState.ANIMATING)
	weapon_scene.card_audio_player.play()
	await discard_tween.finished
	Game.set_state(Game.GameState.PLAYING)
	
	Game.held_weapon_max_dmg = INF
	Game.held_weapon_monster_amt = 0

func update_health(preview_health: int = -1) -> void:

	health_label.text = str(Game.health) + "/ 20"

	var panel_width  : float = health_panel.size.x
	var real_size    : float = (float(Game.health)   / 20.0) * panel_width - 8.0
	
	if preview_health == -1:

		var tween := create_tween().set_parallel()

		
		tween.tween_property(texture_container, "size",
				Vector2(real_size, health_rect.size.y), 0.2) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
		
		tween.tween_property(health_rect, "size",
				Vector2(real_size, health_rect.size.y), 0.2) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
			
		tween.tween_property(ghost_rect, "size",
			Vector2(0.0, ghost_rect.size.y), 0.2) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(ghost_rect, "position",
			Vector2(real_size + 4, 4), 0.2) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
		
			

		Game.set_state(Game.GameState.ANIMATING)
		tween.tween_callback(func() -> void: 
			Game.set_state(Game.GameState.PLAYING)
		)
	else:
		if preview_health < Game.health:
			ghost_rect.color = Color("5e1115")
		else:
			ghost_rect.color = Color("ed4c54")
			
		health_rect.size = Vector2(real_size, health_rect.size.y)
		texture_container.size = Vector2(real_size, texture_container.size.y)

		var ghost_size : float = (float(preview_health) / 20.0) * panel_width - 8
		ghost_size = min(max(ghost_size, 0.0),panel_width - 4)

		var bar_height : float = ghost_rect.size.y  

		ghost_rect.position.x = real_size
		ghost_rect.size = Vector2(0,bar_height)

		var tween := create_tween().set_parallel()
		tween.tween_property(ghost_rect, "size",
				Vector2(abs(real_size - ghost_size), bar_height), 0.2) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)
		if preview_health < Game.health:
			tween.tween_property(ghost_rect, "position",
					Vector2(ghost_size + 4, 4), 0.2) \
				.set_trans(Tween.TRANS_CUBIC) \
				.set_ease(Tween.EASE_OUT)
		elif preview_health > Game.health:
			tween.tween_property( texture_container , "size",
					Vector2(ghost_size,texture_container.size.y), 0.2) \
				.set_trans(Tween.TRANS_CUBIC) \
				.set_ease(Tween.EASE_OUT)

		Game.set_state(Game.GameState.ANIMATING)
		tween.tween_callback(func() -> void: Game.set_state(Game.GameState.PLAYING))
	if preview_health == -1 and Game.health <= 0:
		game_over_scene.visible = true
		game_over_scene.set_data(false, Game.calculate_score(false))

func _on_flee_button_pressed() -> void:
	if Game.game_state == Game.GameState.ANIMATING:
		return
	if Game.flee_available:
		if selected_card != -1:
			remove_attack_button(selected_card)
			selected_card = -1
		for i in range(4):
			await room_scene.move_card_to_back_of_deck(i)
	
		for i in range(4):
			var card := Game.draw_card()
			if card != null:
				await animate_draw_to_slot(i, card)
		
		Game.flee_available = false
		flee_button.disabled = true
		


func _on_gui_input(event: InputEvent) -> void:
	if Game.game_state == Game.GameState.ANIMATING:
		return
	if event is InputEventScreenTouch:
		if event.is_released():
			if selected_card != -1:
				remove_attack_button(selected_card)
				selected_card = -1
