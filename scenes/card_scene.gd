extends TextureRect
class_name CardScene

const CARD_TEXTURE := preload("res://sprites/cards.png")


var card : Card
var id: int
signal clicked(id:int)


func setup(card : Card,id: int) -> void:
	self.card = card
	self.id = id
	var atlas := AtlasTexture.new()
	atlas.atlas = CARD_TEXTURE
	var x_region := (card.rank - 1) % 13 
	atlas.region = get_card_region(x_region,card.suit)

	texture = atlas

func get_card_region(rank: int, suit: int) -> Rect2:
	var x := rank * 128
	var y := suit * 178
	return Rect2(x, y, 128, 178)
	
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.is_released():
			if get_rect().has_point(event.position):
				clicked.emit(id)
