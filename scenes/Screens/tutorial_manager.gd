extends Control
class_name Tutorial

signal step_completed

enum Step {
	MONSTER_BARE,
	POTION,
	ROOM_CLEAR,
	WEAPON_EQUIP,
	MONSTER_WEAPON,
	WEAPON_DEGRADED,
	FLEE,
	DONE
}

var active := false
var current_step := Step.MONSTER_BARE
var scripted_deck : Array[Card] = []

func start(game_scene : Control) -> void:
	active = true
	current_step = Step.MONSTER_BARE
	_build_scripted_deck()
	SaveManager.save_tutorial_seen()

func is_active() -> bool:
	return active and current_step != Step.DONE

func advance(to: Step) -> void:
	current_step = to
	step_completed.emit()

func _build_scripted_deck() -> void:
	scripted_deck = [
		Card.create(5,  Card.card_suit.SPADES),
		Card.create(5,  Card.card_suit.HEARTS),
		Card.create(3,  Card.card_suit.CLUBS),
		Card.create(4,  Card.card_suit.SPADES),
		Card.create(5,  Card.card_suit.DIAMONDS),
		Card.create(6,  Card.card_suit.CLUBS),
		Card.create(7,  Card.card_suit.SPADES),
		Card.create(14,  Card.card_suit.CLUBS),
		Card.create(13, Card.card_suit.SPADES),
		Card.create(9,  Card.card_suit.HEARTS),
		Card.create(8,  Card.card_suit.DIAMONDS),
	]
