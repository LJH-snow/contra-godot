extends Node2D
## 标题画面: 三行选项(玩家数/关卡/难度) / 科乐美秘技(上上下下左右左右BA → 30条命)
## 兼容契约: _mode(1|2) / TwoPlayerHint 节点 / 模式行点击热区 (qa_title 依赖)

const LOGO := preload("res://assets/sprites/title_logo.png")
const HINT := preload("res://assets/text/title_hint.png")
const HINT_2P := preload("res://assets/text/title_hint_2p.png")
const CHEAT := preload("res://assets/text/title_cheat.png")
const START := preload("res://assets/text/title_start.png")
const KONAMI := [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A]

const DIFF_NAMES := ["EASY", "NORMAL", "HARD"]
const ROW_Y := [118, 134, 150, 166]        # 1P / 2P / STAGE / LEVEL

var _kidx := 0
var _activated := false
var _mode := 1                       # 1=单人 2=双人 (契约变量)
var _stage := 1                      # 起始关卡 1..3
var _diff := 1                       # 0=EASY 1=NORMAL 2=HARD
var _row := 0                        # 光标行 0..3
var _blink_t := 0.0
var _prompt: TextureRect
var _cheat_rect: TextureRect
var _logo_spr: Sprite2D
var _hint_single: TextureRect
var _hint_two: TextureRect
var _labels: Array[Label] = []
var _arrow: Label
var _hi: Label
var _scroll := 0.0

func _ready() -> void:
	Boot.loop_count = 1
	Boot.player_count = 1
	Boot.play_music("music_title", -6.0)
	# 后台预载游戏主场景: 玩家按开始时资源已在缓存, 消除进游戏首帧的卡顿
	ResourceLoader.load_threaded_request("res://scenes/main.tscn")
	var bg := Sprite2D.new()
	bg.texture = preload("res://assets/sprites/bg_sky.png")
	bg.centered = false
	add_child(bg)
	var far := Sprite2D.new()
	far.texture = preload("res://assets/sprites/bg_far.png")
	far.centered = false
	far.position = Vector2(0, 100)
	add_child(far)
	var near := Sprite2D.new()
	near.texture = preload("res://assets/sprites/bg_near.png")
	near.centered = false
	near.position = Vector2(0, 160)
	add_child(near)
	_logo_spr = Sprite2D.new()
	_logo_spr.texture = LOGO
	_logo_spr.position = Vector2(160, 68)
	add_child(_logo_spr)
	_prompt = _mkrect(START, Vector2(160, 188))
	_cheat_rect = _mkrect(CHEAT, Vector2(160, 188))
	_cheat_rect.visible = false
	# 选项行: 1P / 2P / STAGE / LEVEL
	var defaults := ["1  PLAYER", "2  PLAYERS", "", ""]
	for i in range(4):
		var l := Label.new()
		l.text = defaults[i]
		l.position = Vector2(110, ROW_Y[i])
		l.size = Vector2(120, 14)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 10)
		l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
		l.add_theme_constant_override("outline_size", 3)
		add_child(l)
		_labels.append(l)
	_arrow = Label.new()
	_arrow.text = ">"
	_arrow.position = Vector2(96, ROW_Y[0])
	_arrow.add_theme_font_size_override("font_size", 10)
	_arrow.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	_arrow.add_theme_constant_override("outline_size", 3)
	add_child(_arrow)
	_hint_single = _mkrect(HINT, Vector2(160, 222))
	_hint_two = _mkrect(HINT_2P, Vector2(160, 220))
	_hint_two.name = "TwoPlayerHint"
	_hi = Label.new()
	_hi.text = "HI-SCORE %07d" % Boot.high_score
	_hi.position = Vector2(90, 4)
	_hi.size = Vector2(140, 12)
	_hi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hi.add_theme_font_size_override("font_size", 8)
	_hi.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_hi.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	_hi.add_theme_constant_override("outline_size", 3)
	add_child(_hi)
	_refresh()

func _mkrect(tex: Texture2D, center: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	t.position = center - Vector2(tex.get_width() / 2.0, tex.get_height() / 2.0)
	add_child(t)
	return t

func _refresh() -> void:
	_labels[0].text = "1  PLAYER"
	_labels[1].text = "2  PLAYERS"
	_labels[2].text = "STAGE  %d" % _stage
	_labels[3].text = "LEVEL  %s" % DIFF_NAMES[_diff]
	for i in range(4):
		var col := Color(0.62, 0.66, 0.78)
		if i < 2 and _mode == i + 1:
			col = Color(1.0, 0.85, 0.3)          # 当前模式: 金
		if i == _row:
			col = Color(1.0, 0.95, 0.6)          # 光标行: 亮金
		if i == 3 and i != _row:
			if _diff == 0:
				col = Color(0.5, 0.95, 0.6)      # EASY: 绿
			elif _diff == 2:
				col = Color(1.0, 0.5, 0.4)       # HARD: 红
		_labels[i].add_theme_color_override("font_color", col)
	_arrow.position.y = ROW_Y[_row]
	_hint_single.visible = _mode == 1
	_hint_two.visible = _mode == 2

func _set_row(r: int) -> void:
	var nr := clampi(r, 0, 3)
	if nr < 2:
		_mode = nr + 1
	if nr != _row or r != nr:
		Boot.play_sfx("sfx_item", -18.0)
	_row = nr
	_refresh()

func _cycle(dir: int) -> void:
	match _row:
		0, 1:
			_mode = 3 - _mode                   # 左右也能切模式
			_row = _mode - 1
		2:
			_stage = wrapi(_stage - 1 + dir, 1, 4)
		3:
			_diff = wrapi(_diff + dir, 0, 3)
	Boot.play_sfx("sfx_item", -16.0)
	_refresh()

func _mode_at(pos: Vector2) -> int:
	if Rect2(88, 120, 144, 22).has_point(pos):
		return 1
	if Rect2(88, 142, 144, 22).has_point(pos):
		return 2
	return 0

func is_start_hit(pos: Vector2) -> bool:
	return Rect2(76, 172, 168, 40).has_point(pos)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mode := _mode_at(event.position)
		if mode != 0:
			_set_row(mode - 1)
		elif Rect2(88, 156, 144, 16).has_point(event.position):
			_row = 2
			_cycle(1)
		elif Rect2(88, 172, 144, 16).has_point(event.position):
			_row = 3
			_cycle(1)
		elif is_start_hit(event.position):
			_start()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: Key = event.physical_keycode
		_check_konami(key)
		if key == KEY_UP or key == KEY_W:
			_set_row(_row - 1)
		elif key == KEY_DOWN or key == KEY_S:
			_set_row(_row + 1)
		elif key == KEY_A or key == KEY_LEFT:
			_cycle(-1)
		elif key == KEY_D or key == KEY_RIGHT:
			_cycle(1)
		elif key == KEY_ENTER or key == KEY_KP_ENTER or key == KEY_J:
			_start()

func _check_konami(key: Key) -> void:
	if _activated:
		return
	if key == KONAMI[_kidx]:
		_kidx += 1
		if _kidx >= KONAMI.size():
			_activated = true
			Boot.play_sfx("sfx_konami")
			_cheat_rect.visible = true
		else:
			Boot.play_sfx("sfx_item", -14.0)
	else:
		_kidx = 1 if key == KONAMI[0] else 0

func _start() -> void:
	Boot.play_sfx("sfx_start")
	Boot.player_count = _mode
	Boot.difficulty = _diff
	Boot.level = _stage
	Boot.start_lives = 30 if _activated else GameData.diff_lives()
	Boot.score = 0
	# 预载已完成则直接用缓存场景; 未完成 load 会阻塞到完成 (通常已就绪)
	if ResourceLoader.load_threaded_get_status("res://scenes/main.tscn") \
			== ResourceLoader.THREAD_LOAD_LOADED:
		get_tree().change_scene_to_packed(
			ResourceLoader.load_threaded_get("res://scenes/main.tscn"))
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _process(delta: float) -> void:
	_blink_t += delta
	_prompt.visible = not _activated and fmod(_blink_t, 1.0) < 0.65
	_scroll += delta
	_logo_spr.position.y = 68 + sin(_scroll * 1.6) * 3.0
