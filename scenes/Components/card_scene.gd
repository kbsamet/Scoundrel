extends TextureRect
class_name CardScene

const CARD_TEXTURE := preload("res://sprites/cards.png")


var card : Card
var id: int
signal clicked(id:int)
@onready var card_audio_player: AudioStreamPlayer = $CardAudioPlayer

func _ready() -> void:
	# Ensure the shader knows the size immediately
	update_shader_size()
	# Connect to the size_flags_changed or item_rect_changed 
	# if you expect the card to resize dynamically
	item_rect_changed.connect(update_shader_size)

func update_shader_size() -> void:
	if material is ShaderMaterial:
		# size is a built-in property of Control nodes (TextureRect)
		material.set_shader_parameter("rect_size", size - Vector2(15,15))


func setup(card : Card,id: int) -> void:
	self.card = card
	self.id = id
	var atlas := AtlasTexture.new()
	atlas.atlas = CARD_TEXTURE
	var x_region := (card.rank - 1) % 13 
	var region := get_card_region(x_region,card.suit)
	atlas.region = region

	texture = atlas
	
	if material is ShaderMaterial:
		var mat := material.duplicate() as ShaderMaterial
		
		# 1. Pass the Node's visual size
		mat.set_shader_parameter("rect_size", size if size.x > 0 else region.size)

		# 2. Convert pixel region to UV region (0.0 to 1.0)
		var tex_size := CARD_TEXTURE.get_size()
		var uv_pos := region.position / tex_size
		var uv_size := region.size / tex_size

		# Pass as a vec4(x, y, width, height)
		mat.set_shader_parameter("uv_rect", Color(uv_pos.x, uv_pos.y, uv_size.x, uv_size.y))
		material = mat
func get_card_region(rank: int, suit: int) -> Rect2:
	var x := rank * 128
	var y := suit * 178
	return Rect2(x, y, 128, 178)
	
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.is_released():
			if get_rect().has_point(event.position):
				clicked.emit(id)

func set_shadow_overlay(is_covered: bool) -> void:
	if material is ShaderMaterial:
		material.set_shader_parameter("has_card_above", is_covered)
