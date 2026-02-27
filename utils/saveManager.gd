extends Resource
class_name SaveManager

static func save_score(score : int) -> void:
	var config := ConfigFile.new()
	config.set_value("data", "high_score", score)
	config.save("user://save.cfg")
	

static func load_score() -> int:
	var config := ConfigFile.new()
	var high_score := 0
	if config.load("user://save.cfg") == OK:
		high_score = config.get_value("data", "high_score", 0)  
	return high_score
