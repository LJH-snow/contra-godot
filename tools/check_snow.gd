extends Node
## 第三关(雪原)专项验收: Boot.level=3

var game: Node2D
var fails: Array[String] = []
var step := 0
var _wait := 0
var _frames := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Boot.has_meta("snow_advanced"):
		var adv: Array = Boot.get_meta("snow_advanced")
		print("PASS: 关卡推进到巢穴(Boot.level=%d)" % adv[0])
		print("PASS: 周目不变(loop=%d)" % adv[1])
		print("=== 雪原关验收结束(含跨重启断言) ===")
		Boot.remove_meta("snow_advanced")
		Boot.level = 1
		Boot.loop_count = 1
		get_tree().quit(0 if adv[0] == 4 and adv[1] == 1 else 1)
		return
	print("=== 雪原关验收开始 ===")
	Boot.level = 3
	Boot.difficulty = 1
	var gs: PackedScene = load("res://scenes/main.tscn")
	game = gs.instantiate()
	add_child(game)

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
				game._intro_t = 0.0
				check(not game.L_VERTICAL, "雪原为横向卷轴")
				check(game.L_PLATFORMS.size() >= 14, "雪原浮台已构建(%d个)" % game.L_PLATFORMS.size())
				check(game.L_GROUNDS.size() == 6, "雪原地段 6 段")
				_next(1, 20)
		1:
			if _due():
				var bg := game.get_node("Background/Sky/SkySprite")
				check(bg.texture.resource_path.ends_with("bg_snow_sky.png"), "雪原夜空背景已换装")
				var far := game.get_node("Background/FarLayer/FarSprite")
				check(far.texture.resource_path.ends_with("bg_snow_far.png"), "雪山远景已换装")
				var snow := game.get_node_or_null("SnowLayer/SnowParticles")
				check(snow != null and snow.emitting, "飘雪粒子运行中")
				var near := game.get_node_or_null("Background/NearLayer")
				check(near == null or not near.visible, "丛林近景已隐藏")

				_next(2, 30)
		2:
			if _due():
				var stream = Boot._music_player.stream
				check(stream != null and stream == Boot._music["music_snow"], "雪原专属 BGM")
				# 雪地贴图抽查: 找一个 ground 顶层的雪贴图
				var found := false
				for t in game.world_node.get_children():
					if t is Sprite2D and t.texture == game.TEX_TILES["snow"] and t.position.y == game.L_GROUND_Y:
						found = true
						break
				check(found, "地表铺雪贴图")
				# Boss 狂暴测试
				if game.boss_core != null and is_instance_valid(game.boss_core):
					game.player.position = Vector2(3200, 170)   # 触发 Boss
				_next(3, 40)
		3:
			if _due():
				check(game.boss_active, "雪原 Boss 战触发")
				if is_instance_valid(game.boss_core):
					game.boss_core.set_open(true)
					game.boss_core.damage(game.boss_core.max_hp / 2 + 2, Vector2.RIGHT)   # 打入狂暴
				_next(4, 10)
		4:
			if _due():
				check(is_instance_valid(game.boss_core) and game.boss_core.enraged, "半血狂暴触发")
				check(absf(game.boss_core.fire_interval() - game.boss_core.fire_int * 0.5) < 0.001,
					"狂暴射速翻倍")
				# 击破完成
				_next(5, 2)
		5:
			if _due():
				if game.level_done:
					check(true, "雪原 Boss 被击破")
					_next(6, 250)
				elif not is_instance_valid(game.boss_core):
					_wait = 2
				elif _frames > 900:
					check(false, "Boss 击破超时")
					_next(6, 0)
				else:
					_frames += 1
					game.boss_core.set_open(true)
					var b := Bullet.new()
					b.setup(game.boss_core.position + Vector2(-30, -14), Vector2.RIGHT, GameData.W.NORMAL)
					game.bullets_node.add_child(b)
					_wait = 2
		6:
			if _due():
				# 关卡推进: 3 完成 → 回 1 + 周目+1 (reload 重启本场景, 见 _exit_tree)
				_wait = 200

func _exit_tree() -> void:
	if game != null and is_instance_valid(game) and game.level_done:
		Boot.set_meta("snow_advanced", [Boot.level, Boot.loop_count])
