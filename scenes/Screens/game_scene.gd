extends Control
class_name GameScene

@onready var room_scene: RoomScene = $MarginContainer/VBoxContainer/RoomScene
@onready var held_card: Panel = $MarginContainer/VBoxContainer/HBoxContainer3/HeldCard
const CardSceneScene := preload("res://scenes/Components/CardScene.tscn")
@onready var health_panel: Panel = $MarginContainer/VBoxContainer/HealthPanel
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthPanel/HealthLabel
@onready var health_rect: ColorRect = $MarginContainer/VBoxContainer/HealthPanel/HealthRect
@onready var ghost_rect: ColorRect = $MarginContainer/VBoxContainer/HealthPanel/GhostRect

@onready var game_over_scene: GameOverScene = $GameOverScene

@onready var disabled_panel: Panel = $MarginContainer/VBoxContainer/HBoxContainer3/FleeButton/DisabledPanel
@onready var texture_container: Control = $MarginContainer/VBoxContainer/HealthPanel/TextureContainer
@onready var flee_outer_panel: Panel = $MarginContainer/VBoxContainer/HBoxContainer3/FleeButton/FleeOuterPanel

@onready var flee_tooltip: Tooltip = $MarginContainer/VBoxContainer/HBoxContainer3/FleeButton/FleeTooltip
@onready var deck_tooltip: Tooltip = $MarginContainer/VBoxContainer/HBoxContainer2/Deck/DeckTooltip

@onready var run_player: AudioStreamPlayer = $runPlayer

@onready var settings_button: TextureButton = $MarginContainer/VBoxContainer/HBoxContainer/SettingsButton
@onready var settings_screen: SettingsScreen = $SettingsScreen
@onready var tranistion_shader: ColorRect = $TranistionShader

@onready var deck: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer2/Deck
@onready var flee_button: Button = $MarginContainer/VBoxContainer/HBoxContainer3/FleeButton
@onready var discard_pile: Panel = $MarginContainer/VBoxContainer/HBoxContainer3/DiscardPile


@onready var punch_player: AudioStreamPlayer = $PunchPlayer
@onready var slash_player: AudioStreamPlayer = $SlashPlayer
@onready var equip_player: AudioStreamPlayer = $equipPlayer
@onready var drink_player: AudioStreamPlayer = $DrinkPlayer
@onready var tranistion: ColorRect = $Tranistion


const attack_button_scene = preload("res://scenes/Components/AttackButtonScene.tscn")
var selected_card := -1
var game_loaded := false
func _ready() -> void:
	await get_tree().process_frame
	settings_screen.close.connect(func() -> void: settings_screen.visible = false)
	room_scene.discard_pile = discard_pile
	room_scene.deck_position = deck.global_position
	settings_button.pivot_offset = settings_button.size/2
	flee_button.pivot_offset = flee_button.size/2
	if game_loaded:
		var tween := create_tween()
		tranistion.modulate.a = 1
		tween.tween_property(tranistion,"modulate:a",0,1.5) \
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_IN)
		settings_screen.visible = false
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
		await SaveManager.load_run(self)
		update_health()
		set_flee_disabled(!Game.flee_available)
		await get_tree().create_timer(0.5).timeout
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
		return
	Game.reset()
	set_flee_disabled(false)
	set_flee_button_panels()
	if !SaveManager.has_seen_tutorial():
		TutorialManager.start(self)
		TutorialManager.step_completed.connect(_on_tutorial_step)
		set_flee_disabled(true)
	await get_tree().create_timer(1.0).timeout
	for i in range(4):
		var card := Game.draw_card()
		await animate_draw_to_slot(i, card)
	if TutorialManager.is_active():
		_on_tutorial_step()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, \
		NOTIFICATION_APPLICATION_PAUSED, \
		NOTIFICATION_WM_CLOSE_REQUEST:
			print("saving")
			SaveManager.save_run(self)

func _on_tutorial_step() -> void:
	match TutorialManager.current_step:
		TutorialManager.Step.POTION:
			room_scene.card_slots[1].get_child(0).show_tutorial_tip("Hearts are healing potions.\nTap to restore health")
		TutorialManager.Step.MONSTER_BARE:
			room_scene.card_slots[0].get_child(0).show_tutorial_tip("Clubs and Spades are monsters.\nTap and attack with your fists.")
		TutorialManager.Step.ROOM_CLEAR:
			room_scene.card_slots[2].get_child(0).show_tutorial_tip("Move on to the next room\nwhen there is only 1 card left.\nTap and attack to move on.")
		TutorialManager.Step.WEAPON_EQUIP:
			room_scene.card_slots[0].get_child(0).show_tutorial_tip("Diamonds are weapons.\nThey reduce monster damage.\nTap and equip.")
		TutorialManager.Step.MONSTER_WEAPON:
			room_scene.card_slots[1].get_child(0).show_tutorial_tip("Use your weapon to kill this monster.\nTap and select weapon.")
		TutorialManager.Step.WEAPON_DEGRADED:
			held_card.get_child(0).show_tutorial_tip("Weapons can't hit monsters\n stronger than its last kill.")
			room_scene.card_slots[2].get_child(0).show_tutorial_tip("You can still use your fists to kill it.\nTap and select fists.")
		TutorialManager.Step.FLEE:
			flee_tooltip.show_tip("Too dangerous? Flee the room.\nYou can't flee two rooms in a row.")
			set_flee_disabled(false)
		TutorialManager.Step.DONE:
			deck_tooltip.show_tip("Defeat all the cards in the deck to win.\nGood luck.")
			

func card_clicked(id : int) -> void:
	if TutorialManager.is_active() and id != TutorialManager.current_step % 3:
		return
	if selected_card == id:
		selected_card = -1
		await remove_attack_button(id)
		return
	elif selected_card != -1:
		await remove_attack_button(selected_card)
	if room_scene.card_slots[id].get_child_count() == 0:
		return
	
	set_attack_button(id)
	selected_card = id


func make_card_move(id : int, secondary_attack : bool = false) -> void:
	if TutorialManager.is_active() || TutorialManager.current_step == TutorialManager.Step.DONE:
		for i in range(4):
			if room_scene.card_slots[i].get_child_count() == 0:
				continue
			room_scene.card_slots[i].get_child(0).hide_tutorial_tip()
			if held_card.get_child_count() != 0:
				held_card.get_child(0).hide_tutorial_tip()
		deck_tooltip.hide_tip()
	if selected_card != -1:
		await remove_attack_button(selected_card)
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
		Game.potion_used = true
		if Game.difficulty == "Veteran" or Game.difficulty == "Condemned":
			Game.heal(0 if Game.potion_used else card.rank)
		else:
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
	set_flee_disabled(true)
	if room_scene.get_card_count() == 1:
		fill_room()
		if Game.deck.size() == 0:
			deck.modulate.a = 0
			for i in range(4):
				if room_scene.get_card(i) != null:
					await room_scene.remove_card(i)
			SaveManager.clear_run()
			game_over_scene.visible = true
			game_over_scene.set_data(true,Game.calculate_score(true))
	if TutorialManager.is_active():
		TutorialManager.advance(TutorialManager.current_step + 1)

func remove_attack_button(id:int) -> void:
	if room_scene.card_slots[id].get_child_count() == 0:
		return
	var card_scene : CardScene = room_scene.card_slots[id].get_child(0)
	var tween := create_tween().set_parallel()
	tween.tween_method(
			func(v: float) -> void: card_scene.material.set_shader_parameter("glow_strength", v),
			0.3,
			0.0,
			0.1
		)
	tween.tween_property(card_scene,"scale",Vector2(1,1),0.1) \
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	Game.set_state(Game.GameState.ANIMATING)
	await tween.finished
	Game.set_state(Game.GameState.PLAYING)
	
	for child in card_scene.get_children():
		if child is Tooltip:
			continue
		card_scene.remove_child(child)

func set_attack_button(id : int) -> void:
	var card := room_scene.get_card(id)
	if card != null:
		var card_scene : CardScene = room_scene.card_slots[id].get_child(0)
		var tween := create_tween().set_parallel()
		tween.tween_method(
			func(v: float) -> void: card_scene.material.set_shader_parameter("glow_strength", v),
			0.0,
			0.3,
			0.2
		)
		tween.tween_property(card_scene,"scale",Vector2(1.2,1.2),0.1) \
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		Game.set_state(Game.GameState.ANIMATING)
		tween.tween_callback(func() ->void : Game.set_state(Game.GameState.PLAYING))
		
		
		for child in card_scene.get_children():
			if child is Tooltip:
				continue
			card_scene.remove_child(child)
		var attack_button : AttackButtonScene = attack_button_scene.instantiate()
		card_scene.add_child(attack_button)
		attack_button.clicked.connect(func(first : bool) -> void: make_card_move(id,!first))
		attack_button.pressed.connect(func(diff: int) -> void: update_health(Game.health + diff) if diff != -1 else update_health())
		attack_button.pressed_disabled.connect(disabled_attack_pressed)
		var held_card : Card = null if held_card.get_child_count() == 0 else held_card.get_child(0).card
		attack_button.set_data(card,held_card)
		
		attack_button.position = Vector2((card_scene.size.x / 2.0) - (attack_button.size.x / 2.0),280)

func disabled_attack_pressed() -> void:
	if held_card.get_child_count() == 0:
		return
	var child_list := held_card.get_child(0).get_children()
	child_list.reverse()
	for card in child_list:
		if card is CardScene:
			var tween := create_tween()
			card.material.set_shader_parameter("glow_width",0.8)
			tween.tween_method(
			func(v: float) -> void: card.material.set_shader_parameter("glow_strength", v),
				0.0,
				0.6,
				0.3
			).set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)
			tween.tween_method(
			func(v: float) -> void: card.material.set_shader_parameter("glow_strength", v),
				0.6,
				0,
				0.3
			).set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_IN)
			await tween.finished
			card.material.set_shader_parameter("glow_width",0.08)
			return
			
			
func fill_room() -> bool:
	Game.potion_used = false
	var card_drawn := false
	for i in range(4):
		if room_scene.get_card(i) == null:
			var card := Game.draw_card()
			if card != null:
				await animate_draw_to_slot(i, card)
				card_drawn = true
				
	SaveManager.save_run(self)
	
	var remaining_deck_ratio : float = float(Game.deck.size()) / float(Game.MAX_DECK_COUNT)
	remaining_deck_ratio = 1.0 - remaining_deck_ratio
	for i in range(floor(remaining_deck_ratio * deck.get_child_count())):
		deck.get_child(-i - 1).visible = false
	Game.flee_available = true
	set_flee_disabled(false)
	

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
	tween.tween_property(card_scene, "global_position", target_pos, 0.15 if Game.fast_mode else 0.3)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	Game.set_state(Game.GameState.ANIMATING)
	await tween.finished
	card_scene.position = Vector2.ZERO
	card_scene.clicked.connect(card_clicked)
	Game.set_state(Game.GameState.PLAYING)

	
func animate_move_to_held(card_scene: CardScene,offset : Vector2) -> void:
	if selected_card != -1:
		await remove_attack_button(selected_card)
		selected_card = -1
	
	add_child(card_scene)
	
	var start_pos := card_scene.global_position
	var target_pos := held_card.global_position + offset
	
	card_scene.global_position = start_pos
	card_scene.size = card_scene.custom_minimum_size
	
	var tween := create_tween()
	tween.tween_property(card_scene, "global_position", target_pos, 0.4 if Game.fast_mode else 0.8)\
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
			gather_tween.tween_property(monster, "position", Vector2.ZERO, 0.15 if Game.fast_mode else 0.3)\
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
	discard_tween.tween_property(weapon_scene, "global_position", discard_pile.global_position, 0.25 if Game.fast_mode else 0.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	Game.set_state(Game.GameState.ANIMATING)
	weapon_scene.card_audio_player.play()
	await discard_tween.finished
	Game.set_state(Game.GameState.PLAYING)
	
	Game.held_weapon_max_dmg = INF
	Game.held_weapon_monster_amt = 0

func update_health(preview_health: int = -1) -> void:

	health_label.text = str(Game.health) + " / 20"

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
			ghost_rect.color = Color("30090ba4")
		else:
			ghost_rect.color = Color("ff6b724d")
			
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
		SaveManager.clear_run()
		TutorialManager.active = false
		game_over_scene.visible = true
		game_over_scene.set_data(false, Game.calculate_score(false))
		



func _on_gui_input(event: InputEvent) -> void:
	if Game.game_state == Game.GameState.ANIMATING:
		return
	if event is InputEventScreenTouch:
		if event.is_released():
			if selected_card != -1:
				await remove_attack_button(selected_card)
				selected_card = -1


func _on_flee_button_button_down() -> void:
	var tween := create_tween()
	tween.tween_property(flee_button, "scale", Vector2(0.93, 0.93), 0.1)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_flee_button_button_up() -> void:
	var tween := create_tween()
	tween.tween_property(flee_button, "scale", Vector2(1.0, 1.0), 0.15)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if Game.game_state == Game.GameState.ANIMATING:
		return
	if Game.flee_available:
		set_flee_disabled(true)
		run_player.play()
		if selected_card != -1:
			await remove_attack_button(selected_card)
			selected_card = -1
		for i in range(4):
			await room_scene.move_card_to_back_of_deck(i)
	
		for i in range(4):
			var card := Game.draw_card()
			if card != null:
				await animate_draw_to_slot(i, card)
		
		Game.flee_available = false
		flee_tooltip.hide_tip()
		TutorialManager.advance(TutorialManager.current_step + 1)
		TutorialManager.active = false

func set_flee_button_panels() -> void:
	var normal := flee_button.get_theme_stylebox("normal").duplicate()

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#1a1a1a")

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#121111")

	var focus := StyleBoxEmpty.new()
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color("#333030")
	disabled.border_color = Color("#333030")

	flee_button.add_theme_stylebox_override("disabled", disabled)
	flee_button.add_theme_stylebox_override("hover", hover)
	flee_button.add_theme_stylebox_override("pressed", pressed)
	flee_button.add_theme_stylebox_override("focus", focus)

func set_flee_disabled(is_disabled: bool) -> void:
	flee_button.disabled = is_disabled

	var stylebox := disabled_panel.get_theme_stylebox("panel") as StyleBoxFlat
	var outer_stylebox := flee_outer_panel.get_theme_stylebox("panel") as StyleBoxFlat
	
	var tween := create_tween().set_parallel()
	tween.tween_method(
		func(c: Color) -> void: stylebox.bg_color = c,
		stylebox.bg_color,
		Color("#171413ca") if is_disabled else Color("#17141300"),
		0.2
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_method(
		func(c: Color) -> void: outer_stylebox.border_color = c,
		outer_stylebox.border_color,
		Color("#2a241f") if is_disabled else Color("#382e2a"),
		0.2
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	


func _on_settings_button_button_down() -> void:
	var tween := create_tween()
	tween.tween_property(settings_button, "scale", Vector2(0.8, 0.8), 0.1)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_settings_button_button_up() -> void:
	var tween := create_tween()
	tween.tween_property(settings_button, "scale", Vector2(1.0, 1.0), 0.15)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_settings_button_pressed() -> void:
	settings_screen.visible = true
	SaveManager.save_run(self)
