extends Node
## 标题菜单 QA: 鼠标选择双人、显示双人键位和开始区域

var title: Node2D
var fails: Array[String] = []

func _ready() -> void:
	var scene: PackedScene = load("res://scenes/title.tscn")
	title = scene.instantiate()
	get_tree().root.add_child.call_deferred(title)
	await get_tree().process_frame
	get_tree().current_scene = title
	await get_tree().process_frame
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(160, 144)
	Input.parse_input_event(click)
	await get_tree().process_frame
	_check(int(title.get("_mode")) == 2, "鼠标点击 2 PLAYERS 可切换模式")
	var hint := title.find_child("TwoPlayerHint", true, false)
	_check(hint != null and hint.visible, "双人模式显示 P1/P2 键位说明")
	var single_click := InputEventMouseButton.new()
	single_click.button_index = MOUSE_BUTTON_LEFT
	single_click.pressed = true
	single_click.position = Vector2(160, 130)
	Input.parse_input_event(single_click)
	await get_tree().process_frame
	_check(int(title.get("_mode")) == 1 and hint != null and not hint.visible,
		"鼠标切回单人后隐藏双人键位")
	var two_player_click := InputEventMouseButton.new()
	two_player_click.button_index = MOUSE_BUTTON_LEFT
	two_player_click.pressed = true
	two_player_click.position = Vector2(160, 144)
	Input.parse_input_event(two_player_click)
	await get_tree().process_frame
	var start_event := InputEventMouseButton.new()
	start_event.button_index = MOUSE_BUTTON_LEFT
	start_event.pressed = true
	start_event.position = Vector2(160, 194)
	Input.parse_input_event(start_event)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(Boot.player_count == 2, "鼠标点击开始后保留双人模式")
	_check(get_tree().current_scene != null and get_tree().current_scene.scene_file_path == "res://scenes/main.tscn",
		"鼠标点击开始后进入主游戏场景")
	print("=== 标题菜单验证结束: %d 失败 ===" % fails.size())
	for f in fails:
		print("  失败项: ", f)
	get_tree().quit(1 if not fails.is_empty() else 0)

func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS: ", name)
	else:
		fails.append(name)
		print("FAIL: ", name)
