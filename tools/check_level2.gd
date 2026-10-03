extends Node
## 第二关(纵向瀑布)专项验收: Boot.level=2

var game: Node2D
var fails: Array[String] = []
var step := 0
var _wait := 0
var _cam_y0 := 0.0
var _boss_frames := 0
var _lives0 := 0

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
				var main_plats := []
				for p in game.L_PLATFORMS:
					if p.z == 76:
						main_plats.append(p)
				main_plats.sort_custom(func(a, b): return a.y > b.y)
				check(main_plats.size() >= 18, "主浮台数量足够(%d个)" % main_plats.size())
				var spacing_ok := true
				for i in range(1, main_plats.size()):
					if main_plats[i - 1].y - main_plats[i].y != 64:
						spacing_ok = false
				check(spacing_ok, "主浮台垂直间距 64px")
				check(game.get_tree().get_nodes_in_group("air_missile").is_empty(), "瀑布关无空袭导弹")
				# 起步可达: 出生台与上一层横向重叠, 无需横跨间隙
				var base_ok := false
				var overlap_ok := false
				var base_right := 0
				for p in game.L_PLATFORMS:
					if p.y == 1560 and p.z == 76:
						base_right = p.x + p.z
						if p.x <= 60 and p.x + p.z >= 60:
							base_ok = true
				for p in game.L_PLATFORMS:
					if p.y == 1496 and p.z == 76 and p.x < base_right:
						overlap_ok = true
				check(base_ok, "出生站位浮台存在")
				check(overlap_ok, "上一层浮台与出生台横向重叠 (起步满跳可达)")
				check(game.player != null and game.player.position.y > 1500.0, "玩家出生在底部")
				var bg := game.get_node("Background/FarLayer/FarSprite")
				check(bg.texture.resource_path.ends_with("bg_waterfall.png"), "瀑布崖壁背景已换装")
				check(game.bridge == null, "瀑布关无吊桥")
				_cam_y0 = game.cam_y
				game._intro_t = 0.0               # 跳过开场字幕, 立即激活相机
				game.player.invuln_t = 99.0       # 波次/滚石已恢复, 攀爬模拟免死
				_next(1, 10)
		1:
			if _due():
				check(not game.boss_active, "Boss 不在关卡开始时提前触发 (y≤3088 恒真回归)")
				game.player.position = Vector2(74, 1490)
				_next(2, 20)
		2:
			if _due():
				game.player.position = Vector2(150, 1360)
				_next(3, 20)
		3:
			if _due():
				game.player.position = Vector2(74, 1040)
				_next(4, 20)
		4:
			if _due():
				check(game.cam_y < _cam_y0 - 200.0, "纵向镜头跟随攀爬(cam_y %.0f→%.0f, 只上不下)" % [_cam_y0, game.cam_y])
				check(game.player.position.y > game.L_FALL_LINE - 900.0, "玩家存活于攀爬中")
				# 纵向复活: 死亡后应在相机视野内的浮台上重生
				_lives0 = game.player.lives
				game.player.die(false)
				_next(5, 130)
		5:
			if _due():
				check(not game.player.dead, "纵向关死亡后自动复活")
				check(game.player.lives == _lives0 - 1, "复活消耗一条命")
				check(game.player.position.y > game.cam_y and game.player.position.y < game.cam_y + 240.0,
					"纵向复活点在相机视野内 (y=%.0f, cam_y=%.0f)" % [game.player.position.y, game.cam_y])
				var on_plat := false
				for q in game.L_PLATFORMS:
					if game.player.position.x >= q.x and game.player.position.x <= q.x + q.z \
							and absf(game.player.position.y - float(q.y)) < 14.0:
						on_plat = true
				check(on_plat, "纵向复活点落在浮台上 (非水面)")
				# 快进到顶部要塞
				game.player.position = Vector2(160, 114)
				_next(6, 30)
		6:
			if _due():
				check(game.boss_active, "瀑布顶 Boss 战触发")
				check(game.boss_core != null and is_instance_valid(game.boss_core), "要塞核心存在")
				# 击破核心 (强制开门 + 连射)
				_next(7, 2)
		7:
			if _due():
				# 等待核心爆炸链结束 (level_done 由 on_boss_destroyed 延迟 1.8s 设置)
				if game.level_done:
					check(true, "瀑布 Boss 被击破")
					_next(8, 250)
				elif not is_instance_valid(game.boss_core):
					_wait = 2                          # 核心已炸, 等结算链
				elif _boss_frames > 900:
					check(false, "Boss 击破超时")
					_next(8, 0)
				else:
					_boss_frames += 1
					game.boss_core.set_open(true)
					var b := Bullet.new()
					b.setup(game.boss_core.position + Vector2(-30, -14), Vector2.RIGHT, GameData.W.NORMAL)
					game.bullets_node.add_child(b)
					_wait = 2
		8:
			if _due():
				# 关卡推进经由 reload 重启本场景完成 (见 _ready / _exit_tree)
				print("等待关卡推进重启...")
				_wait = 200
