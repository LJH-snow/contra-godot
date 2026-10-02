extends Node
## 第二关(纵向瀑布)专项验收: Boot.level=2

var game: Node2D
var fails: Array[String] = []
var step := 0
var _wait := 0
var _cam_y0 := 0.0
var _boss_frames := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("=== 瀑布关验收开始 ===")
	# 关卡推进通过 reload 重启本场景 — 第二次启动时验证推进结果
	if Boot.has_meta("lvl2_advanced"):
		var adv: Array = Boot.get_meta("lvl2_advanced")
		print("PASS: 关卡推进到雪原(Boot.level=%d)" % adv[0])
		print("PASS: 周目不变(loop=%d)" % adv[1])
		print("=== 瀑布关验收结束(含跨重启断言) ===")
		Boot.remove_meta("lvl2_advanced")
		Boot.level = 1
		Boot.loop_count = 1
		get_tree().quit(0 if adv[0] == 3 and adv[1] == 1 else 1)
		return
	Boot.level = 2
	Boot.difficulty = 1
	var gs: PackedScene = load("res://scenes/main.tscn")
	game = gs.instantiate()
	add_child(game)

func _exit_tree() -> void:
	if game != null and is_instance_valid(game) and game.level_done:
		Boot.set_meta("lvl2_advanced", [Boot.level, Boot.loop_count])

func check(cond: bool, name: String) -> void:
	if cond:
		print("PASS: ", name)
	else:
		fails.append(name)
		print("FAIL: ", name)

func _due() -> bool:
	if _wait > 0:
		_wait -= 1
		return false
	return true

func _next(n: int, w: int) -> void:
	step = n
	_wait = w

func _physics_process(_d: float) -> void:
	match step:
		0:
			if _due():
				check(game.L_VERTICAL, "纵向关配置生效")
				check(game.L_PLATFORMS.size() >= 18, "瀑布浮台已构建(%d个)" % game.L_PLATFORMS.size())
				check(game.L_H == 1728.0, "关卡高度 1728")
				check(game.player != null and game.player.position.y > 1500.0, "玩家出生在底部")
				var bg := game.get_node("Background/FarLayer/FarSprite")
				check(bg.texture.resource_path.ends_with("bg_waterfall.png"), "瀑布崖壁背景已换装")
				check(game.bridge == null, "瀑布关无吊桥")
				_cam_y0 = game.cam_y
				game._intro_t = 0.0               # 跳过开场字幕, 立即激活相机
				_next(1, 10)
		1:
			if _due():
				game.player.position = Vector2(74, 1438)
				_next(2, 20)
		2:
			if _due():
				game.player.position = Vector2(246, 1320)
				_next(3, 20)
		3:
			if _due():
				game.player.position = Vector2(74, 1082)
				_next(4, 20)
		4:
			if _due():
				check(game.cam_y < _cam_y0 - 200.0, "纵向镜头跟随攀爬(cam_y %.0f→%.0f, 只上不下)" % [_cam_y0, game.cam_y])
				check(game.player.position.y > game.L_FALL_LINE - 900.0, "玩家存活于攀爬中")
				# 快进到顶部要塞
				game.player.position = Vector2(160, 114)
				_next(5, 30)
		5:
			if _due():
				check(game.boss_active, "瀑布顶 Boss 战触发")
				check(game.boss_core != null and is_instance_valid(game.boss_core), "要塞核心存在")
				# 击破核心 (强制开门 + 连射)
				_next(6, 2)
		6:
			if _due():
				# 等待核心爆炸链结束 (level_done 由 on_boss_destroyed 延迟 1.8s 设置)
				if game.level_done:
					check(true, "瀑布 Boss 被击破")
					_next(7, 250)
				elif not is_instance_valid(game.boss_core):
					_wait = 2                          # 核心已炸, 等结算链
				elif _boss_frames > 900:
					check(false, "Boss 击破超时")
					_next(7, 0)
				else:
					_boss_frames += 1
					game.boss_core.set_open(true)
					var b := Bullet.new()
					b.setup(game.boss_core.position + Vector2(-30, -14), Vector2.RIGHT, GameData.W.NORMAL)
					game.bullets_node.add_child(b)
					_wait = 2
		7:
			if _due():
				# 关卡推进经由 reload 重启本场景完成 (见 _ready / _exit_tree)
				print("等待关卡推进重启...")
				_wait = 200
