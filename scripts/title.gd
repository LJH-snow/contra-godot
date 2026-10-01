extends Node2D
## 标题画面: Logo / 1P·2P 选择 / 科乐美秘技(上上下下左右左右BA → 30条命)

const LOGO := preload("res://assets/sprites/title_logo.png")
const HINT := preload("res://assets/text/title_hint.png")
const CHEAT := preload("res://assets/text/title_cheat.png")
const START := preload("res://assets/text/title_start.png")
const KONAMI := [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A]

var _kidx := 0
var _activated := false
var _mode := 1                       # 1=单人 2=双人
var _blink_t := 0.0
var _prompt: TextureRect
var _cheat_rect: TextureRect
var _logo_spr: Sprite2D
var _mode_labels: Array[Label] = []
var _arrow: Label
var _scroll := 0.0

func _ready() -> void:
	Boot.loop_count = 1
	Boot.player_count = 1
	Boot.play_music("music_title", -6.0)
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
	_prompt = _mkrect(START, Vector2(160, 176))
	_cheat_rect = _mkrect(CHEAT, Vector2(160, 176))
	_cheat_rect.visible = false
	# 模式选择
	for i in range(2):
		var l := Label.new()
		l.text = "1  PLAYER" if i == 0 else "2  PLAYERS"
		l.position = Vector2(110, 126 + i * 16)
		l.size = Vector2(120, 14)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 10)
		l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
		l.add_theme_constant_override("outline_size", 3)
		add_child(l)
		_mode_labels.append(l)
	_arrow = Label.new()
	_arrow.text = "▶"
	_arrow.position = Vector2(92, 126)
	_arrow.add_theme_font_size_override("font_size", 10)
	_arrow.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	_arrow.add_theme_constant_override("outline_size", 3)
	add_child(_arrow)
	var hint := _mkrect(HINT, Vector2(160, 216))
	_refresh_mode()

func _mkrect(tex: Texture2D, center: Vector2) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	t.position = center - Vector2(tex.get_width() / 2.0, tex.get_height() / 2.0)
	add_child(t)
	return t

func _refresh_mode() -> void:
	for i in range(2):
		var sel := (i + 1) == _mode
		_mode_labels[i].add_theme_color_override("font_color",
			Color(1.0, 0.85, 0.3) if sel else Color(0.62, 0.66, 0.78))
	_arrow.position.y = 126 + (_mode - 1) * 16

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: Key = event.physical_keycode
		_check_konami(key)
		if key == KEY_UP or key == KEY_W:
			if _mode != 1:
				_mode = 1
				Boot.play_sfx("sfx_item", -16.0)
				_refresh_mode()
		elif key == KEY_DOWN or key == KEY_S:
			if _mode != 2:
				_mode = 2
				Boot.play_sfx("sfx_item", -16.0)
				_refresh_mode()
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
	Boot.start_lives = 30 if _activated else 3
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _process(delta: float) -> void:
	_blink_t += delta
	_prompt.visible = not _activated and fmod(_blink_t, 1.0) < 0.65
	_scroll += delta
	_logo_spr.position.y = 68 + sin(_scroll * 1.6) * 3.0
