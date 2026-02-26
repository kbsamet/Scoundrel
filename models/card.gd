
class_name Card

enum card_type {WEAPON,POTION,ENEMY}
enum card_suit {CLUBS,HEARTS,SPADES,DIAMONDS}


@export var rank : int
@export var suit : card_suit
@export var type : card_type

static func create(rank : int, suit : card_suit) -> Card:
	var card : Card = Card.new()
	card.rank = rank
	card.suit = suit
	if suit == card_suit.HEARTS:
		card.type = card_type.POTION
	elif suit == card_suit.DIAMONDS:
		card.type = card_type.WEAPON
	else:
		card.type = card_type.ENEMY
	return card

static func from(card: Card) -> Card:
	return Card.create(card.rank,card.suit)
