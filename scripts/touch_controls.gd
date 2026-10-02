extends Control
## 移动端虚拟控制(自治节点, 由 Boot 挂载): 触屏时显示
## 左侧十字键 + 右侧跳/射按钮 + 右上 START, 直接驱动 p1_* 输入动作
## 纯 _draw 绘制, 零素材依赖

var _zones := {}                     # name -> Rect2 (画布坐标 320x240)
var _touch_owner := {}               # 触点index -> 按钮名
var _pressed := {}                   # 按钮名 -> bool (用于高亮)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_zones = {
		"left": Rect2(14, 168, 52, 52),
		"right": Rect2(78, 168, 52, 52),
		"up": Rect2(46, 140, 52, 52),
		"down": Rect2(46, 196, 52, 52),
		"jump": Rect2(238, 176, 52, 52),
		"fire": Rect2(262, 128, 56, 56),
		"start": Rect2(276, 4, 42, 20),
		"menu": Rect2(4, 4, 42, 20),
	}
	for k in _zones:
		_pressed[k] = false

func _draw() -> void:
	var col := Color(1, 1, 1, 0.22)
	var hot := Color(1.0, 0.85, 0.3, 0.5)
	var font := ThemeDB.fallback_font
	for k in _zones:
		var rect: Rect2 = _zones[k]
		var c: Color = hot if _pressed[k] else col
		if k == "start" or k == "menu":
			draw_rect(rect, Color(0.1, 0.1, 0.16, 0.45))
			draw_rect(rect, c, false, 2.0)
			draw_string(font, rect.position + Vector2(4, 14),
				"START" if k == "start" else "MENU",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.75))
			continue
		var center := rect.get_center()
		var radius := rect.size.x / 2.0
		draw_circle(center, radius, Color(0.1, 0.1, 0.16, 0.4))
		draw_circle(center, radius - 2.0, c)
		if k == "jump" or k == "fire":
			draw_string(font, center + Vector2(-radius * 0.6, 3), "JUMP" if k == "jump" else "FIRE",
				HORIZONTAL_ALIGNMENT_CENTER, radius * 1.2, 8, Color(1, 1, 1, 0.8))
		else:
			_draw_arrow(center, k)

func _draw_arrow(center: Vector2, dir: String) -> void:
	var s := 9.0
	var pts: PackedVector2Array
	match dir:
		"left": pts = PackedVector2Array([center + Vector2(s, -s), center + Vector2(-s * 0.7, 0), center + Vector2(s, s)])
		"right": pts = PackedVector2Array([center + Vector2(-s, -s), center + Vector2(s * 0.7, 0), center + Vector2(-s, s)])
		"up": pts = PackedVector2Array([center + Vector2(-s, s), center + Vector2(0, -s * 0.7), center + Vector2(s, s)])
		"down": pts = PackedVector2Array([center + Vector2(-s, -s), center + Vector2(0, s * 0.7), center + Vector2(s, -s)])
	draw_colored_polygon(pts, Color(1, 1, 1, 0.55))

func _hit(pos: Vector2) -> String:
	for k in _zones:
		if (_zones[k] as Rect2).has_point(pos):
			return k
	return ""

func _set_btn(name: String, on: bool) -> void:
	match name:
		"start":
			_synth_key(KEY_ENTER, on)        # 标题画面需要真实键盘事件
		"menu":
			_synth_key(KEY_P, on)            # 暂停菜单同样事件驱动
		_:
			var action := "p1_" + name
			if on:
				Input.action_press(action)
			else:
				Input.action_release(action)
	if _pressed.has(name) and _pressed[name] != on:
		_pressed[name] = on
		queue_redraw()

## 合成真实按键事件 (供事件驱动的界面: 标题/暂停菜单)
func _synth_key(code: Key, on: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.pressed = on
	Input.parse_input_event(ev)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			var name := _hit(t.position)
			if name != "":
				_touch_owner[t.index] = name
				_set_btn(name, true)
		else:
			var name: String = _touch_owner.get(t.index, "")
			if name != "":
				_set_btn(name, false)
				_touch_owner.erase(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		var old: String = _touch_owner.get(d.index, "")
		if old == "":
			return
		var now := _hit(d.position)
		if now != old:
			_set_btn(old, false)
			_touch_owner.erase(d.index)
			if now != "":
				_touch_owner[d.index] = now
				_set_btn(now, true)
