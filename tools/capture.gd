extends SceneTree
## Dev tool: renders a scene and saves a PNG.
## Headless (logic check only, no window): add --headless.
## godot --path . -s tools/capture.gd -- <scene_path> <out.png> [wait_seconds] [setup]
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path := args[0]
	var out := args[1]
	var wait := float(args[2]) if args.size() > 2 else 1.5
	var setup := args[3] if args.size() > 3 else ""
	await process_frame
	var scene: Node = load(scene_path).instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.1).timeout
	match setup:
		"settings":
			scene.get_node("SettingsScreen").visible = true
		"gameover_win":
			scene.get_node("GameOverScene").visible = true
			scene.get_node("GameOverScene").set_data(true, 228)
		"gameover_lose":
			scene.get_node("GameOverScene").visible = true
			scene.get_node("GameOverScene").set_data(false, 87, true)
	await create_timer(wait).timeout
	if setup == "select" or setup == "midgame":
		if setup == "midgame":
			_inject_weapon(scene)
			await create_timer(0.6).timeout
		for i in range(4):
			if scene.room_scene.get_card(i).type == Card.card_type.ENEMY:
				scene.card_clicked(i)
				break
		await create_timer(0.6).timeout
	if DisplayServer.get_name() != "headless":
		root.get_texture().get_image().save_png(out)
	else:
		print("headless run finished OK")
	quit()

func _inject_weapon(scene: Node) -> void:
	var weapon: CardScene = scene.CardSceneScene.instantiate()
	scene.held_card.add_child(weapon)
	weapon.setup(Card.create(8, Card.card_suit.DIAMONDS), -1)
	weapon.position = Vector2.ZERO
	for i in range(2):
		var m: CardScene = scene.CardSceneScene.instantiate()
		weapon.add_child(m)
		m.setup(Card.create(9 - i * 3, Card.card_suit.SPADES), -1)
		m.position = Vector2(25 * (i + 1), 25 * (i + 1))
	var game: Node = root.get_node("Game")
	game.held_weapon_max_dmg = 6
	game.held_weapon_monster_amt = 2
	game.health = 13
	scene.update_health()
