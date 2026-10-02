extends Node
## 新增自治功能验收: 暂停菜单 / Boss音乐导演 / 触屏控制挂载 (全部通过 exit 0)

var game: Node2D
var fails: Array[String] = []
var step := 0
var _wait := 0
var _spawned_runner: EnemyRunner

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # 暂停期间验收脚本需继续运行
	print("=== 自治功能验收开始 ===")
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

func _next(n: int, wait: int) -> void:
	step = n
	_wait = wait

func _key(code: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventKey.new()
	up.physical_keycode = code
	up.pressed = false
	Input.parse_input_event(up)

func _physics_process(_d: float) -> void:
	match step:
		0:
			if _due():
				check(game.player != null, "游戏已运行")
				# 触屏控制: 桌面无触屏 → 不挂载(网页触屏设备自动挂载)
				var tc := _find_node("TouchControls")
				check(DisplayServer.is_touchscreen_available() == (tc != null),
					"触屏控制挂载策略正确(桌面=%s)" % str(tc == null))
				_next(1, 20)
		1:
			if _due():
				# 按下 P → 暂停
				_key(KEY_P)
				_next(2, 5)
		2:
			if _due():
				check(get_tree().paused, "P键暂停生效")
				# 再按 P → 恢复
				_key(KEY_P)
				_next(3, 5)
		3:
			if _due():
				check(not get_tree().paused, "再按P恢复游戏")
				# Boss音乐导演: 强制 boss_active
				game.boss_active = true
				_next(4, 8)
		4:
			if _due():
				var stream = Boot._music_player.stream
				check(stream != null and stream == Boot._music["music_boss"],
					"Boss战自动切换 BGM")
				game.boss_active = false
				_next(5, 8)
		5:
			if _due():
				var stream = Boot._music_player.stream
				check(stream != null and stream == Boot._music["music_stage"],
					"Boss结束自动切回关卡 BGM")
				# 暂停菜单: 打开 → 选到 SOUND 项 → 恢复
				_key(KEY_P)
				_next(6, 5)
		6:
			if _due():
				check(get_tree().paused, "菜单打开")
				# 下移到 BGM 行 (resume=0, restart=1, title=2, bgm=3): 按3次下
				_key(KEY_S)
				_next(7, 3)
		7:
			if _due():
				_key(KEY_S)
				_next(8, 3)
		8:
			if _due():
				_key(KEY_S)
				_next(9, 3)
		9:
			if _due():
				set_meta("vol0", Boot.music_vol)
				_key(KEY_D)                     # BGM 行: 右调 +10%
				_next(10, 3)
		10:
			if _due():
				var v1: float = Boot.music_vol
				check(absf(v1 - float(get_meta("vol0", 0.8)) - 0.1) < 0.001, "菜单内 BGM 音量可调(+10%)")
				_key(KEY_A)                     # 调回
				_next(11, 3)
		11:
			if _due():
				check(absf(Boot.music_vol - float(get_meta("vol0", 0.8))) < 0.001, "BGM 音量还原")
				_key(KEY_P)                     # 关闭菜单
				_next(12, 5)
		12:
			if _due():
				check(not get_tree().paused, "菜单关闭恢复游戏")
				# 测试环境确定性: 清场 + 冻结生成器 (隔绝另一窗口内容的随机击杀)
				for e in get_tree().get_nodes_in_group("enemies"):
					e.queue_free()
				game._spawn_t = 99999.0
				game._capsule_t = 99999.0
				# 结算导演: 手柄震动接口无手柄时静默不报错
				var jd := _find_node("JuiceDirector")
				check(jd != null, "手感导演已挂载")
				if jd != null:
					jd.vibrate_all(0.5, 0.5, 0.1)
				# 特效导演: 已挂载 + 屏幕闪光触发
				var fx := _find_node("FxDirector")
				check(fx != null, "特效导演已挂载")
				if fx != null:
					fx.flash(Color(1, 0, 0, 0.3), 0.1)
					check(fx._flash.color.a > 0.2, "死亡/击破屏幕闪光生效")
				# 音量分轨: 设置生效并还原
				var mv0: float = Boot.music_vol
				Boot.set_music_vol(0.5)
				check(absf(Boot.music_vol - 0.5) < 0.001, "BGM音量设置生效")
				Boot.set_music_vol(mv0)
				# 击杀飘字: 布置跑兵 → 等1帧让导演挂钩信号 → 击杀 → 弹出 +分数
				var e := EnemyRunner.new()
				e.position = Vector2(200, GameData.GROUND_Y - 30)
				e.died.connect(func(sv: int): Boot.score += sv)   # 模拟游戏计分钩子
				game.enemies_node.add_child(e)
				_spawned_runner = e
				_next(15, 3)
		15:
			if _due():
				# 慢动作 hit-stop: 触发 → time_scale 降低 → 真实时间到点自动恢复
				var jd2 := _find_node("JuiceDirector")
				jd2.hit_stop(0.35, 300)
				check(absf(Engine.time_scale - 0.35) < 0.001, "慢动作 hit-stop 触发")
				set_meta("slowmo_t0", Time.get_ticks_msec())
				_next(21, 30)
		21:
			if _due():
				check(Engine.time_scale == 1.0, "慢动作按真实时间自动恢复")
				# 手柄导航暂停菜单: 十字键下 → 选择第二项, B 关闭
				var pm := _find_node("PauseMenu")
				_key(KEY_P)
				_next(22, 5)
		22:
			if _due():
				var pm := _find_node("PauseMenu")
				var down := InputEventJoypadButton.new()
				down.button_index = JOY_BUTTON_DPAD_DOWN
				down.pressed = true
				Input.parse_input_event(down)
				_next(23, 3)
		23:
			if _due():
				var pm := _find_node("PauseMenu")
				check(pm._sel == 1, "手柄十字键导航菜单(选中=%d)" % pm._sel)
				var b := InputEventJoypadButton.new()
				b.button_index = JOY_BUTTON_B
				b.pressed = true
				Input.parse_input_event(b)
				_next(24, 5)
		24:
			if _due():
				var pm := _find_node("PauseMenu")
				check(not pm._open and not get_tree().paused, "手柄 B 键关闭菜单")
				# 击杀飘字: 布置跑兵 → 等1帧让导演挂钩信号 → 击杀 → 弹出 +分数
				var e := EnemyRunner.new()
				e.position = Vector2(200, GameData.GROUND_Y - 30)
				e.died.connect(func(sv: int): Boot.score += sv)   # 模拟游戏计分钩子
				game.enemies_node.add_child(e)
				_spawned_runner = e
				_next(25, 3)
		25:
			if _due():
				var runner: EnemyRunner = _spawned_runner
				if runner != null and is_instance_valid(runner):
					runner.damage(99, Vector2.RIGHT)
				_next(26, 8)
		26:
			if _due():
				var popups := get_tree().get_nodes_in_group("kill_popup")
				check(popups.size() > 0, "击杀分数飘字弹出(%d个)" % popups.size())
				check(Boot.lifetime_kills >= 1, "生涯击杀累计(%d)" % Boot.lifetime_kills)
				# 连击: 3秒内再杀一个 → x2 + 奖励分25
				var e2 := EnemyRunner.new()
				e2.position = Vector2(240, GameData.GROUND_Y - 30)
				e2.died.connect(func(sv: int): Boot.score += sv)
				game.enemies_node.add_child(e2)
				_spawned_runner = e2
				_next(27, 3)
		27:
			if _due():
				set_meta("score_before", Boot.score)
				var runner2: EnemyRunner = _spawned_runner
				if runner2 != null and is_instance_valid(runner2):
					runner2.damage(99, Vector2.RIGHT)
				_next(28, 8)
		28:
			if _due():
				var fx2 := _find_node("FxDirector")
				check(fx2._combo == 2, "连击计数 x2")
				var delta_score: int = Boot.score - int(get_meta("score_before", 0))
				check(delta_score == 100 + 25, "连击奖励分入账(基础100+奖励25=%d)" % delta_score)
				# 结算浮层: 强制 level_done → 延迟弹出统计
				game.level_done = true
				_next(13, 110)
		13:
			if _due():
				var sd := _find_node("StatsDirector")
				check(sd != null and sd._root.visible, "过关结算浮层自动弹出")
				var txt: String = sd._lines[0].text
				check(txt.begins_with("SCORE"), "统计内容已填充(%s)" % txt)
				game.level_done = false
				_next(14, 5)
		14:
			if _due():
				var sd := _find_node("StatsDirector")
				check(not sd._root.visible, "非过关状态结算浮层隐藏")
				# Game Over 音乐: 全员阵亡且无剩余生命
				game.player.dead = true
				game.player.lives = 0
				_next(29, 8)
		29:
			if _due():
				var stream = Boot._music_player.stream
				check(stream != null and stream == Boot._music["music_gameover"],
					"Game Over 自动切换哀乐")
				game.player.dead = false
				game.player.lives = Boot.start_lives
				_next(30, 8)
		30:
			if _due():
				var stream = Boot._music_player.stream
				check(stream != null and stream == Boot._music["music_stage"],
					"玩家恢复切回关卡 BGM")
				print("=== 自治功能验收结束: %d 失败 ===" % fails.size())
				for f in fails:
					print("  失败项: ", f)
				get_tree().paused = false
				get_tree().quit(1 if fails.size() > 0 else 0)

func _find_node(name: String) -> Node:
	for c in Boot.get_children():
		if c.name == name:
			return c
	return null
