extends Node
## 全局引导(自动加载): 输入注册 / 音频加载播放 / 跨场景数据

var start_lives := 3
var loop_count := 1
var score := 0
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
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		muted = not muted
		AudioServer.set_bus_mute(0, muted)

# ---------------- 音频 ----------------
func play_sfx(n: String, vol_db: float = 0.0) -> void:
	if not _sfx.has(n):
		return
	var p := _pool[_pool_i]
	_pool_i = (_pool_i + 1) % _pool.size()
	p.stream = _sfx[n]
	p.volume_db = vol_db
	p.play()

func play_music(n: String, vol_db: float = -9.0) -> void:
	if not _music.has(n):
		return
	if _music_player.stream == _music[n] and _music_player.playing:
		return
	_music_player.stream = _music[n]
	_music_player.volume_db = vol_db
	_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func _load_audio() -> void:
	var sfx_names := ["sfx_shoot", "sfx_spread", "sfx_laser", "sfx_fire", "sfx_jump",
		"sfx_explode", "sfx_explode_big", "sfx_item", "sfx_powerup", "sfx_death",
		"sfx_clang", "sfx_bosshit", "sfx_clear", "sfx_start", "sfx_konami", "sfx_eagle"]
	for n in sfx_names:
		var s := _load_wav("res://assets/audio/%s.wav" % n, false)
		if s != null:
			_sfx[n] = s
	for n in ["music_stage", "music_title"]:
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
	_add_keys("move_left", [KEY_LEFT, KEY_A])
	_add_keys("move_right", [KEY_RIGHT, KEY_D])
	_add_keys("move_up", [KEY_UP, KEY_W])
	_add_keys("move_down", [KEY_DOWN, KEY_S])
	_add_keys("jump", [KEY_Z, KEY_K, KEY_SPACE])
	_add_keys("shoot", [KEY_X, KEY_J])
	_add_keys("start", [KEY_ENTER, KEY_KP_ENTER])
	_add_keys("title", [KEY_ESCAPE])
	_add_keys("mute", [KEY_M])

func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
