extends Node
## 全局引导(自动加载): 输入注册 / 音频加载播放 / 跨场景数据 / 最高分存档

const SAVE_PATH := "user://highscore.cfg"

var start_lives := 3
var player_count := 1
var difficulty := 1                   # 0=EASY 1=NORMAL 2=HARD
var level := 1                        # 当前关卡 (1=丛林 2=瀑布)
var loop_count := 1
var score := 0
var high_score := 0
var lifetime_kills := 0
var missions_played := 0
var music_vol := 0.8
var sfx_vol := 0.8
var muted := false

var _sfx := {}
var _music := {}
var _music_player: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _pool_i := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_inputs()
	_load_audio()
	_load_high()
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	# 自治功能节点(暂停菜单/触屏控制/Boss音乐导演) — 与主场景零耦合
	var pm := preload("res://scripts/pause_menu.gd").new()
	pm.name = "PauseMenu"
	add_child(pm)
	var md := preload("res://scripts/music_director.gd").new()
	md.name = "MusicDirector"
	add_child(md)
	var sd := preload("res://scripts/stats_director.gd").new()
	sd.name = "StatsDirector"
	add_child(sd)
	var jd := preload("res://scripts/juice_director.gd").new()
	jd.name = "JuiceDirector"
	add_child(jd)
	var fx := preload("res://scripts/fx_director.gd").new()
	fx.name = "FxDirector"
	add_child(fx)
	if DisplayServer.is_touchscreen_available():
		var tc := preload("res://scripts/touch_controls.gd").new()
		tc.name = "TouchControls"
		add_child(tc)

# ---------------- 最高分 / 生涯统计 ----------------
func _load_high() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		high_score = int(cf.get_value("score", "high", 0))
		lifetime_kills = int(cf.get_value("stats", "lifetime_kills", 0))
		missions_played = int(cf.get_value("stats", "missions_played", 0))
		music_vol = float(cf.get_value("audio", "music", 0.8))
		sfx_vol = float(cf.get_value("audio", "sfx", 0.8))

## 提交分数, 破纪录返回 true 并落盘 (顺带持久化生涯统计)
func submit_score(s: int) -> bool:
	var broke := s > high_score
	if broke:
		high_score = s
	var cf := ConfigFile.new()
	cf.set_value("score", "high", high_score)
	cf.set_value("stats", "lifetime_kills", lifetime_kills)
	cf.set_value("stats", "missions_played", missions_played)
	cf.save(SAVE_PATH)
	return broke

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		muted = not muted
		AudioServer.set_bus_mute(0, muted)
	if event.is_action_pressed("fullscreen"):
		var is_full := DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if is_full else DisplayServer.WINDOW_MODE_FULLSCREEN)
	# 标题画面: 手柄 Start → 合成回车 (手柄也能开始游戏)
	if event.is_action_pressed("start"):
		var cur := get_tree().current_scene
		if cur != null and cur.name == "Title":
			var ev := InputEventKey.new()
			ev.physical_keycode = KEY_ENTER
			ev.pressed = true
			Input.parse_input_event(ev)

# ---------------- 音频 ----------------
func play_sfx(n: String, vol_db: float = 0.0) -> void:
	if not _sfx.has(n):
		return
	var p := _pool[_pool_i]
	_pool_i = (_pool_i + 1) % _pool.size()
	p.stream = _sfx[n]
	p.volume_db = vol_db + linear_to_db(maxf(sfx_vol, 0.05))
	# 连发音效随机微调音高, 消除"机枪单音"的单调感
	if n == "sfx_shoot" or n == "sfx_spread" or n == "sfx_clang":
		p.pitch_scale = randf_range(0.94, 1.06)
	else:
		p.pitch_scale = 1.0
	p.play()

func play_music(n: String, vol_db: float = -9.0) -> void:
	if not _music.has(n):
		return
	if _music_player.stream == _music[n] and _music_player.playing:
		return
	_music_player.stream = _music[n]
	_music_player.volume_db = vol_db + linear_to_db(maxf(music_vol, 0.05))
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

## 音量分轨 (0~1), 即时生效并入档
func set_music_vol(v: float) -> void:
	music_vol = clampf(v, 0.0, 1.0)
	if _music_player.playing:
		_music_player.volume_db = -9.0 + linear_to_db(maxf(music_vol, 0.05))
	_save_audio_pref()

func set_sfx_vol(v: float) -> void:
	sfx_vol = clampf(v, 0.0, 1.0)
	_save_audio_pref()

func _save_audio_pref() -> void:
	var cf := ConfigFile.new()
	cf.load(SAVE_PATH)
	cf.set_value("audio", "music", music_vol)
	cf.set_value("audio", "sfx", sfx_vol)
	cf.save(SAVE_PATH)

func _load_audio() -> void:
	var sfx_names := ["sfx_shoot", "sfx_spread", "sfx_laser", "sfx_fire", "sfx_jump",
		"sfx_explode", "sfx_explode_big", "sfx_item", "sfx_powerup", "sfx_death",
		"sfx_clang", "sfx_bosshit", "sfx_clear", "sfx_start", "sfx_konami", "sfx_eagle",
		"sfx_combo"]
	for n in sfx_names:
		var s := _load_wav("res://assets/audio/%s.wav" % n, false)
		if s != null:
			_sfx[n] = s
	for n in ["music_stage", "music_title", "music_boss", "music_gameover", "music_snow"]:
		var s := _load_wav("res://assets/audio/%s.wav" % n, true)
		if s != null:
			_music[n] = s

func _load_wav(path: String, loop: bool) -> AudioStreamWAV:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		push_warning("音频缺失: " + path)
		return null
	var s := AudioStreamWAV.load_from_buffer(bytes)
	if s == null:
		push_warning("音频解析失败: " + path)
		return null
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = s.data.size() / 2
	return s

# ---------------- 输入 ----------------
func _register_inputs() -> void:
	# 动作名注册(事件绑定在 setup_input 中按人数分配)
	for p in ["p1_", "p2_"]:
		for a in ["left", "right", "up", "down", "jump", "shoot"]:
			var n: String = p + a
			if not InputMap.has_action(n):
				InputMap.add_action(n)
	_add_keys("start", [KEY_ENTER, KEY_KP_ENTER])
	_add_keys("title", [KEY_ESCAPE])
	_add_keys("pause", [KEY_P, KEY_ESCAPE])
	_add_keys("fullscreen", [KEY_F11, KEY_F])
	_add_keys("mute", [KEY_M])
	setup_input(1)

## 按人数分配键位: 单人 P1 兼容两套; 双人 P1=WASD+JK+手柄0, P2=方向键+ZX+手柄1
func setup_input(count: int) -> void:
	_rebind("p1_left", [KEY_A] + ([KEY_LEFT] if count < 2 else []))
	_rebind("p1_right", [KEY_D] + ([KEY_RIGHT] if count < 2 else []))
	_rebind("p1_up", [KEY_W] + ([KEY_UP] if count < 2 else []))
	_rebind("p1_down", [KEY_S] + ([KEY_DOWN] if count < 2 else []))
	_rebind("p1_jump", ([KEY_Z, KEY_SPACE] if count < 2 else []) + [KEY_K])
	_rebind("p1_shoot", ([KEY_X] if count < 2 else []) + [KEY_J])
	if count >= 2:
		_rebind("p2_left", [KEY_LEFT])
		_rebind("p2_right", [KEY_RIGHT])
		_rebind("p2_up", [KEY_UP])
		_rebind("p2_down", [KEY_DOWN])
		_rebind("p2_jump", [KEY_Z])
		_rebind("p2_shoot", [KEY_X])
	# 手柄: P1 = 0号手柄, P2 = 1号手柄 (摇杆/十字键移动, A跳, X射, RB连射)
	_bind_pad(0, "p1", count)
	if count >= 2:
		_bind_pad(1, "p2", count)
	# 开始键: Enter / 任意手柄 Start
	InputMap.action_erase_events("start")
	_add_keys("start", [KEY_ENTER, KEY_KP_ENTER])
	for dev in (2 if count >= 2 else 1):
		var ev := InputEventJoypadButton.new()
		ev.device = dev
		ev.button_index = JOY_BUTTON_START
		InputMap.action_add_event("start", ev)

func _bind_pad(device: int, prefix: String, count: int) -> void:
	# 左摇杆 (X/Y轴) + 十字键
	for dir in [["left", -1.0, JOY_BUTTON_DPAD_LEFT], ["right", 1.0, JOY_BUTTON_DPAD_RIGHT],
			["up", -1.0, JOY_BUTTON_DPAD_UP], ["down", 1.0, JOY_BUTTON_DPAD_DOWN]]:
		var axis := JOY_AXIS_LEFT_X if dir[0] == "left" or dir[0] == "right" else JOY_AXIS_LEFT_Y
		var mv := InputEventJoypadMotion.new()
		mv.device = device
		mv.axis = axis
		mv.axis_value = dir[1]
		InputMap.action_add_event(prefix + "_" + dir[0], mv)
		var bt := InputEventJoypadButton.new()
		bt.device = device
		bt.button_index = dir[2]
		InputMap.action_add_event(prefix + "_" + dir[0], bt)
	# A(0)=跳, X(2)=射击, RB(10)=射击
	for map in [["jump", JOY_BUTTON_A], ["shoot", JOY_BUTTON_X], ["shoot", JOY_BUTTON_RIGHT_SHOULDER]]:
		var bt := InputEventJoypadButton.new()
		bt.device = device
		bt.button_index = map[1]
		InputMap.action_add_event(prefix + "_" + map[0], bt)

func _rebind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
		InputMap.action_set_deadzone(action, 0.4)
	InputMap.action_erase_events(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
