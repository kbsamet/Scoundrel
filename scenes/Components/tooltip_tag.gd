extends Panel
class_name Tooltip

@onready var label: Label = $Label
@export var custom_y : int = -1


func _ready() -> void:
	modulate.a = 0.0

func show_tip(text: String) -> void:
	label.text = text
	await get_tree().process_frame
	_reposition()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func hide_tip() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _reposition() -> void:
	custom_minimum_size = label.get_minimum_size() + Vector2(20,20)
	var card_width  : float = get_parent().size.x
	var y := (-custom_minimum_size.y - 20.0)
	if custom_y != -1:
		y = custom_y
	position = Vector2(
		(card_width / 2.0) - (size.x / 2.0),
		y
	)
	global_position = Vector2(max(50,global_position.x),global_position.y)
func _draw() -> void:
	var parent_center_global : Vector2 = get_parent().global_position + Vector2(get_parent().size.x / 2.0, 0)
	var stem_x := parent_center_global.x - global_position.x
	var stem_y := size.y

	# Outer triangle (border color)
	var outer := PackedVector2Array([
		Vector2(stem_x - 20, stem_y),
		Vector2(stem_x + 20, stem_y),
		Vector2(stem_x,      stem_y + 18)
	])
	draw_colored_polygon(outer, Color("#2a2420"))

	# Inner triangle (background color)
	var inner := PackedVector2Array([
		Vector2(stem_x - 19, stem_y),
		Vector2(stem_x + 19, stem_y),
		Vector2(stem_x,      stem_y + 16)
	])
	draw_colored_polygon(inner, Color("#241f1d"))

	# Cover the bottom border
	draw_line(
		Vector2(stem_x - 20, stem_y),
		Vector2(stem_x + 20, stem_y),
		Color("#241f1d"),
		1.5
	)
