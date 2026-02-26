extends Node

var health := 20
var deck : Array[Card] = []
var flee_available := true
var held_weapon_max_dmg := INF
var held_weapon_monster_amt := 0
var fist_selected := true

func reset() -> void:
	health = 20
	deck = []
	flee_available = true
	fist_selected = true
	held_weapon_max_dmg = INF
	held_weapon_monster_amt = 0
	for i in range(2,15):
		for k in range(0,4):
			if (k == 1 or k == 3) and i > 10:
				continue
			deck.append(Card.create(i,Card.card_suit.values()[k]))
	deck.shuffle()
		
func draw_card() -> Card:
	if deck.size() == 0:
		print("Deck empty")
		return null
	var card : Card = deck[0]
	var card_copy := Card.from(card)
	deck.erase(card)
	return card_copy

func heal(amt: int) -> void:
	health = min(20,health + amt)

func take_damage(amt : int) -> void:
	health -= amt
