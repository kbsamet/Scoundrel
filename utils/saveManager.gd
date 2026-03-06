extends Resource
class_name SaveManager

static func save_score(score: int) -> void:
	var config := ConfigFile.new()
	config.set_value("data", "high_score", score)
	config.save("user://save.cfg")

static func load_score() -> int:
	var config := ConfigFile.new()
	if config.load("user://save.cfg") == OK:
		return config.get_value("data", "high_score", 0)
	return 0

static func save_tutorial_seen() -> void:
	var config := ConfigFile.new()
	config.load("user://save.cfg")
	config.set_value("data", "tutorial_seen", true)
	config.save("user://save.cfg")

static func has_seen_tutorial() -> bool:
	var config := ConfigFile.new()
	if config.load("user://save.cfg") == OK:
		return config.get_value("data", "tutorial_seen", false)
	return false
