extends CanvasLayer
## 暂停菜单(自治节点, 由 Boot 挂载): P/Esc 暂停游戏, 菜单操作不影响主场景
## 仅在关卡场景(含 "game" 组的节点)中生效, 标题画面自动忽略

var _items: Array[String] = ["resume", "restart", "title", "bgm", "sfx"]
var _sel := 0
var _root: Control
var _open := false

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var title := Label.new()
	title.text = "- PAUSED -"
	title.position = Vector2(0, 52)
	title.size = Vector2(320, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.05))
	title.add_theme_constant_override("outline_size", 4)
	_root.add_child(title)
	for i in range(_items.size()):
		var l := Label.new()
		l.name = _items[i]
		l.position = Vector2(0, 92 + i * 22)
		l.size = Vector2(320, 18)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 10)
		l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
		l.add_theme_constant_override("outline_size", 3)
		_root.add_child(l)
	var hint := Label.new()
	hint.text = "W/S SELECT   A/D ADJUST   ENTER OK   P BACK"
	hint.position = Vector2(0, 196)
	hint.size = Vector2(320, 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(0.7, 0.74, 0.85))
	_root.add_child(hint)

func _unhandled_input(event: InputEvent) -> void:
	var in_game := get_tree().get_first_node_in_group("game") != null
	if not in_game:
		return                              # 标题画面不响应
	if Input.is_action_pressed("mute"):
		return                              # M 键交给 Boot 静音
	if event is InputEventKey and event.pressed and not event.echo:
		if not _open:
			if event.is_action_pressed("pause"):
				_set_open(true)
			return
		# 菜单打开时的键盘操作
		if event.is_action_pressed("pause"):
			_set_open(false)
		elif event.is_action_pressed("p1_up") or event.is_action_pressed("p2_up"):
			_nav(-1)
		elif event.is_action_pressed("p1_down") or event.is_action_pressed("p2_down"):
			_nav(1)
		elif event.is_action_pressed("p1_left") or event.is_action_pressed("p2_left"):
			_adjust(-1)
		elif event.is_action_pressed("p1_right") or event.is_action_pressed("p2_right"):
			_adjust(1)
		elif event.is_action_pressed("p1_jump") or event.is_action_pressed("p2_jump") \
				or event.is_action_pressed("start"):
			_confirm()
	elif event is InputEventJoypadButton and event.pressed:
		# 手柄导航 (任意手柄): 十字键上下选择, A 确认, B/Start 关闭
		if not _open:
			if event.button_index == JOY_BUTTON_START:
				_set_open(true)
			return
		match event.button_index:
			JOY_BUTTON_DPAD_UP:
				_nav(-1)
			JOY_BUTTON_DPAD_DOWN:
				_nav(1)
			JOY_BUTTON_DPAD_LEFT:
				_adjust(-1)
			JOY_BUTTON_DPAD_RIGHT:
				_adjust(1)
			JOY_BUTTON_A:
				_confirm()
			JOY_BUTTON_B, JOY_BUTTON_START:
				_set_open(false)

func _nav(dir: int) -> void:
	_sel = (_sel + dir + _items.size()) % _items.size()
	_refresh()
	Boot.play_sfx("sfx_item", -16.0)

func _set_open(v: bool) -> void:
	_open = v
	_root.visible = v
	get_tree().paused = v
	if v:
		_sel = 0                             # 每次打开都回到 RESUME
	_refresh()
	if v:
		Boot.play_sfx("sfx_start", -6.0)

func _refresh() -> void:
	var labels := { "resume": "RESUME", "restart": "RESTART", "title": "BACK TO TITLE",
		"bgm": "BGM  < %d >" % roundi(Boot.music_vol * 100), "sfx": "SFX  < %d >" % roundi(Boot.sfx_vol * 100) }
	for i in range(_items.size()):
		var key: String = _items[i]
		var l := _root.get_node(key) as Label
		var txt: String = labels[key]
		l.text = ("> " + txt) if i == _sel else txt
		l.add_theme_color_override("font_color",
			Color(1.0, 0.85, 0.3) if i == _sel else Color(0.78, 0.8, 0.9))

## 音量行: 左右调节 (10% 步进), 其他行无操作
func _adjust(dir: int) -> void:
	var key: String = _items[_sel]
	if key == "bgm":
		Boot.set_music_vol(Boot.music_vol + dir * 0.1)
	elif key == "sfx":
		Boot.set_sfx_vol(Boot.sfx_vol + dir * 0.1)
	else:
		return
	_refresh()
	Boot.play_sfx("sfx_item", -14.0)

func _confirm() -> void:
	match _items[_sel]:
		"resume":
			_set_open(false)
		"restart":
			_set_open(false)
			Boot.score = 0
			Boot.loop_count = 1
			get_tree().reload_current_scene()
		"title":
			_set_open(false)
			Boot.score = 0
			Boot.loop_count = 1
			Boot.stop_music()
			get_tree().change_scene_to_file("res://scenes/title.tscn")
		"bgm", "sfx":
			pass                              # 音量行用左右键调节
