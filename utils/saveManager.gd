extends Resource
class_name SaveManager
const SAVE_PATH = "user://save.cfg"
const UNLOCK_PATH = "user://unlocks.cfg"
const SETTINGS_PATH = "user://save.cfg"

const TUTORIAL_PATH = "user://tutorial.cfg"

static func save_score(score: int) -> void:
	var config := ConfigFile.new()
	config.set_value("data", "high_score", score)
	config.save("user://save.cfg")

static func load_score() -> int:
	var config := ConfigFile.new()
	if config.load("user://save.cfg") == OK:
		return config.get_value("data", "high_score", 0)
	return 0
	

static func unlock_difficulty(difficulty: String) -> void:
	var config := ConfigFile.new()
	config.load(UNLOCK_PATH)
	var unlocked: Array = config.get_value("unlocks", "difficulties", ["Beginner", "Standard"])
	if difficulty not in unlocked:
		unlocked.append(difficulty)
	config.set_value("unlocks", "difficulties", unlocked)
	config.save(UNLOCK_PATH)

static func get_unlocked_difficulties() -> Array:
	var config := ConfigFile.new()
	config.load(UNLOCK_PATH)
	return config.get_value("unlocks", "difficulties", ["Beginner", "Standard"])

static func save_tutorial_seen() -> void:
	var config := ConfigFile.new()
	config.set_value("tutorial", "tutorial_seen", true)
	config.save(TUTORIAL_PATH)

static func has_seen_tutorial() -> bool:
	var config := ConfigFile.new()
	if config.load(TUTORIAL_PATH) == OK:
		return config.get_value("tutorial", "tutorial_seen", false)
	return false

static func reset_tutorial() -> void:
	var config := ConfigFile.new()
	config.set_value("tutorial", "tutorial_seen", false)
	config.save(TUTORIAL_PATH)


static func _load_config(path : String) -> ConfigFile:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)  
	return config

static func save_settings(settings: Dictionary) -> void:
	var config := _load_config(SETTINGS_PATH)
	for key : String in settings:
		config.set_value("settings", key, settings[key])
		config.save(SETTINGS_PATH)

static func reset() -> void:
	var config := ConfigFile.new()
	config.save(SETTINGS_PATH)
	
static func load_settings() -> Dictionary:
	var config := _load_config(SETTINGS_PATH)
	return {
		"sfx_volume":       config.get_value("settings", "sfx_volume",       85),
		"anim_speed":       config.get_value("settings", "anim_speed",        0) 
	}
static func save_run(game_scene: GameScene) -> void:
	print("starting save")
	var config := _load_config(SAVE_PATH)
	config.set_value("run", "active", true)
	config.set_value("run", "health",                    Game.health)
	config.set_value("run", "flee_available",            Game.flee_available)
	config.set_value("run", "held_weapon_max_dmg",       Game.held_weapon_max_dmg)
	config.set_value("run", "held_weapon_monster_amt",   Game.held_weapon_monster_amt)
	config.set_value("run", "difficulty",                Game.difficulty)
	config.set_value("run", "potion_used",               Game.potion_used)
	print("saved run info")
	var held_card_data : Array = []
	var held_card := game_scene.held_card
	if held_card == null:
		return
	if held_card.get_child_count() != 0:
		var held_card_weapon : Card = held_card.get_child(0).card
		held_card_data.append([held_card_weapon.rank,held_card_weapon.suit])
		for child in held_card.get_child(0).get_children():
			if child is CardScene:
				held_card_data.append([child.card.rank,child.card.suit])
	config.set_value("run", "held_card_data", held_card_data)
	print("saved held card")
	var discard_pile : Array = []
	if game_scene.discard_pile.get_child_count() != 0:
		var discard_card : Card = game_scene.discard_pile.get_child(0).card
		discard_pile = [discard_card.rank,discard_card.suit]
	config.set_value("run", "discard_data", discard_pile)
	
	var room_data : Array = []
	for i in range(4):
		var card := game_scene.room_scene.get_card(i)
		if card != null:
			room_data.append([card.rank,card.suit,i])
	config.set_value("run", "room_data", room_data)
	var deck_data : Array = []
	for card in Game.deck:
		deck_data.append([card.rank, card.suit])
	print("saved room info")
	config.set_value("run", "deck", deck_data)
	config.save(SAVE_PATH)
	print("finished save")

static func load_run(game_scene: GameScene) -> bool:
	var config := _load_config(SAVE_PATH)
	if not config.get_value("run", "active", false):
		return false

	# ── Game singleton ─────────────────────────────
	Game.health                  = config.get_value("run", "health",                  20)
	Game.flee_available          = config.get_value("run", "flee_available",          true)
	Game.held_weapon_max_dmg     = config.get_value("run", "held_weapon_max_dmg",     INF)
	Game.held_weapon_monster_amt = config.get_value("run", "held_weapon_monster_amt", 0)
	Game.held_weapon_monster_amt = config.get_value("run", "difficulty", "Standard")
	Game.held_weapon_monster_amt = config.get_value("run", "potion_used", false)

	# ── Deck ───────────────────────────────────────
	var deck_data : Array = config.get_value("run", "deck", [])
	Game.deck.clear()
	for pair : Array in deck_data:
		Game.deck.append(Card.create(pair[0], pair[1]))

	# ── Room cards ─────────────────────────────────
	var room_data : Array = config.get_value("run", "room_data", [])
	for i in range(room_data.size()):
		var card := Card.create(room_data[i][0], room_data[i][1])
		game_scene.animate_draw_to_slot(room_data[i][2], card)

	# ── Held weapon + stacked monsters ─────────────
	var held_card_data : Array = config.get_value("run", "held_card_data", [])
	if held_card_data.size() > 0:
		# First entry is the weapon
		var weapon_card := Card.create(held_card_data[0][0], held_card_data[0][1])
		var weapon_scene : CardScene = game_scene.CardSceneScene.instantiate()
		game_scene.held_card.add_child(weapon_scene)
		weapon_scene.setup(weapon_card, -1)
		weapon_scene.position = Vector2.ZERO

		# Remaining entries are monsters stacked on the weapon
		for i in range(1, held_card_data.size()):
			var monster_card := Card.create(held_card_data[i][0], held_card_data[i][1])
			var monster_scene : CardScene = game_scene.CardSceneScene.instantiate()
			weapon_scene.add_child(monster_scene)
			monster_scene.setup(monster_card, -1)
			monster_scene.position = Vector2(
				25 * i,
				25 * i
			)

	# ── Discard pile ───────────────────────────────
	var discard_data : Array = config.get_value("run", "discard_data", [])
	if discard_data.size() == 2:
		var discard_card := Card.create(discard_data[0], discard_data[1])
		var discard_scene : CardScene = game_scene.CardSceneScene.instantiate()
		game_scene.discard_pile.add_child(discard_scene)
		discard_scene.setup(discard_card, -1)
		discard_scene.position = Vector2.ZERO

	return true
static func has_active_run() -> bool:
	return _load_config(SAVE_PATH).get_value("run", "active", false)

static func clear_run() -> void:
	var config := _load_config(SAVE_PATH)
	config.set_value("run","active",false)
	config.save(SAVE_PATH)
