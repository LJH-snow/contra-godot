extends Node
## 复现网页版冻结: 标题 → Enter → 检查游戏状态

var step := 0
var _wait := 0
var title: Node
var game: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("=== 冻结复现开始 ===")
	var ts: PackedScene = load("res://scenes/title.tscn")
	title = ts.instantiate()
	get_tree().root.add_child.call_deferred(title)
	_set_current.call_deferred()      # 入树完成后再设 current_scene

func _set_current() -> void:
	if title != null and title.get_parent() == get_tree().root:
		get_tree().current_scene = title

func _due() -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	return true

func _next(n: int, w: int) -> void:
	step = n
	_wait = w

func _key(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.pressed = true
	Input.parse_input_event(ev)

func _physics_process(_d: float) -> void:
	match step:
		0:
			if _due():
				_next(1, 10)                  # 等标题延迟入树
		1:
			if _due():
				_key(KEY_ENTER)               # 标题 → 开始游戏
				_next(2, 10)
		2:
			if _due():
				# 标题的 change_scene 生效了吗?
				var cur := get_tree().current_scene
				var nm: String = cur.name if cur != null else "null"
				print("当前场景: ", nm, " paused=", get_tree().paused)
				if cur != null and cur.name == "Title":
					_key(KEY_ENTER)           # 再按一次
					_wait = 10
					return
				game = get_tree().get_first_node_in_group("game")
				check(game != null, "进入游戏场景")
				_next(3, 60)
		3:
			if _due():
				var p: Player = game.player
				var dead_s: String = str(p.dead) if p else "-"
				var vis_s: String = str(p.visible) if p else "-"
				var pos_s: Vector2 = p.position if p else Vector2.ZERO
				var lives_s: int = p.lives if p else -1
				print("玩家: 存在=", p != null, " dead=", dead_s, " visible=", vis_s,
					" pos=", pos_s, " lives=", lives_s, " paused=", get_tree().paused)
				check(p != null and not p.dead and p.visible, "玩家存在且可见")
				check(not get_tree().paused, "游戏未被暂停")
				var hud: CanvasLayer = game.get_node("HUD")
				var msg: TextureRect = hud._msg
				print("HUD消息: visible=", msg.visible, " texture=", msg.texture != null)
				_next(4, 130)
		4:
			if _due():
				var hud: CanvasLayer = game.get_node("HUD")
				var msg: TextureRect = hud._msg
				print("130帧后(应已过2秒): 消息visible=", msg.visible)
				check(not msg.visible, "MISSION消息正常隐藏")
				var p: Player = game.player
				var pos_s: Vector2 = p.position if p else Vector2.ZERO
				print("玩家仍在: pos=", pos_s)
				print("=== 复现结束 ===")
				get_tree().quit(0)

func check(cond: bool, name: String) -> void:
	print(("PASS: " if cond else "FAIL: ") + name)
