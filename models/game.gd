extends Node
const MAX_DECK_COUNT = 44

var health := 20
var deck : Array[Card] = []
var flee_available := true
var held_weapon_max_dmg := INF
var held_weapon_monster_amt := 0
var high_score := SaveManager.load_score()
var game_state := GameState.ANIMATING
var fast_mode := false
var difficulty := "Beginner"
var potion_used := false

enum GameState {ANIMATING,PLAYING}

func _ready() -> void:
	match OS.get_locale_language():
		"en":
			TranslationServer.set_locale("en")
		"tr":
			TranslationServer.set_locale("tr")
		_:
			TranslationServer.set_locale("en")
			
	fast_mode = SaveManager.load_settings()["anim_speed"] == 1

func set_state(state : GameState) -> void:
	game_state = state

func reset() -> void:
	health = 20
	deck = []
	flee_available = true
	held_weapon_max_dmg = INF
	held_weapon_monster_amt = 0
	game_state = GameState.ANIMATING
	high_score = SaveManager.load_score()
	for i in range(2,15):
		for k in range(0,4):
			if difficulty != "Beginner":
				if (k == 1 or k == 3) and i > 10:
					continue
				if difficulty == "Condemned":
					if (k == 1 or k == 3) and i > 8:
						continue
			deck.append(Card.create(i,Card.card_suit.values()[k]))
	deck.shuffle()

func calculate_score(won: bool) -> int:
	var score := 208
	
	if won:
		return score + health
	for card in deck:
		if card.type == Card.card_type.ENEMY:
			score -= card.rank
	
	match difficulty:
		"Beginner":
			score = score * 0.5
		"Standard":
			score = score * 0.7
		"Veteran":
			score = score * 1
		"Condemned":
			score = score * 1.5
			
	return score

func draw_card() -> Card:
	if deck.size() == 0:
		print("Deck empty")
		return null
	if TutorialManager.is_active() and TutorialManager.scripted_deck.size() > 0:
		var card := TutorialManager.scripted_deck[0]
		TutorialManager.scripted_deck.erase(card)
		return card
	var card : Card = deck[0]
	var card_copy := Card.from(card)
	deck.erase(card)
	return card_copy

func heal(amt: int) -> void:
	health = min(20,health + amt)

func take_damage(amt : int) -> void:
	health -= amt

func load_from(game : Game) -> void:
	health = game.health
	deck = game.deck
	flee_available = game.flee_available
	held_weapon_max_dmg = game.held_weapon_max_dmg
	held_weapon_monster_amt = game.held_weapon_monster_amt
	fast_mode = SaveManager.load_settings()["anim_speed"] == 1
