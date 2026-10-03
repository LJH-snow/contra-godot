extends Node2D
## 通关结局: 直升机撤离演出 + THE END 字幕 → 回标题(周目+1)
## 中文文案用预渲染 PNG (运行时字体无中文字形), 直升机程序化绘制

const ENDING1 := preload("res://assets/text/ending1.png")
const ENDING_FALCON := preload("res://assets/text/ending_falcon.png")
const ENDING_EVAC := preload("res://assets/text/ending_evac.png")

var _t := 0.0
var _heli_x := -140.0
var _rotor := 0.0
var _phase := 0                     # 0=飞入 1=悬停 2=撤离 3=THE END
var _done_label: Label
var _stats: Label
var _heli_node: Node2D
var _falcon: TextureRect
var _evac: TextureRect
var _skipped := false

func _ready() -> void:
	print("[结局] 场景已加载")
	Boot.loop_count += 1                # 通关进入下一周目
	# 巢穴关验收: 结局加载即证明通关分流生效 (测试节点已被正常释放)
	if Boot.has_meta("lair_check"):
		Boot.remove_meta("lair_check")
		print("PASS: 通关结局场景已加载")
		print("PASS: 周目+1(loop=%d)" % Boot.loop_count)
		print("=== 巢穴关验收结束 ===")
		Boot.level = 1
		Boot.loop_count = 1
		get_tree().quit(0)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	Boot.play_music("music_gameover", -14.0)   # 低回氛围
	# 绘制顺序: 同一画布内按树序 — 天空最底, 其后山/直升机/文字依次叠加
	var sky := ColorRect.new()
	sky.color = Color(0.05, 0.04, 0.1)
	sky.size = Vector2(320, 240)         # Node2D 下 anchors 不可靠, 用显式尺寸
	add_child(sky)
	# 远山剪影
	var hills := Polygon2D.new()
	hills.polygon = PackedVector2Array([
		Vector2(0, 200), Vector2(60, 176), Vector2(120, 196), Vector2(190, 168),
		Vector2(260, 192), Vector2(320, 178), Vector2(320, 240), Vector2(0, 240)])
	hills.color = Color(0.1, 0.09, 0.16)
	add_child(hills)
	# 直升机: 独立子节点绘制 (父节点自身绘制永远在子节点之下, 会被天空盖住)
	_heli_node = Node2D.new()
	_heli_node.draw.connect(_draw_heli.bind(_heli_node))
	add_child(_heli_node)
	# 标语 (预渲染 PNG, nearest 过滤保证像素清晰)
	_mkrect(ENDING1, 70.0)
	_falcon = _mkrect(ENDING_FALCON, 104.0)
	_evac = _mkrect(ENDING_EVAC, 126.0)
	# THE END (阶段 3 显示)
	_done_label = Label.new()
	_done_label.text = "THE  END"
	_done_label.position = Vector2(0, 90)
	_done_label.size = Vector2(320, 40)
	_done_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_done_label.add_theme_font_size_override("font_size", 24)
	_done_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_done_label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.05))
	_done_label.add_theme_constant_override("outline_size", 5)
	_done_label.visible = false
	add_child(_done_label)
	_stats = Label.new()
	_stats.position = Vector2(0, 130)
	_stats.size = Vector2(320, 16)
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats.add_theme_font_size_override("font_size", 8)
	_stats.add_theme_color_override("font_color", Color(0.85, 0.87, 0.95))
	add_child(_stats)
	var hint := Label.new()
	hint.text = "PRESS ENTER"
	hint.position = Vector2(0, 216)
	hint.size = Vector2(320, 14)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(0.7, 0.74, 0.85))
	add_child(hint)

func _mkrect(tex: Texture2D, center_y: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.position = Vector2(roundf(160.0 - tex.get_width() / 2.0),
		roundf(center_y - tex.get_height() / 2.0))
	add_child(t)
	return t

## 程序化直升机 (position 为机身中心), 由 _heli_node 的 draw 信号驱动
## 绘制调用必须落在正在绘制的节点上, 因此所有 draw_* 通过参数 on 转发
func _draw_heli(on: CanvasItem) -> void:
	if _phase >= 3:
		return
	var x := _heli_x
	var y := 150.0                      # 撤离走廊: 标语下方, 远山上方
	var body_col := Color(0.32, 0.38, 0.52)
	var dark := Color(0.2, 0.24, 0.36)
	# 尾梁
	on.draw_line(Vector2(x - 20, y - 2), Vector2(x - 44, y - 6), dark, 4.0)
	on.draw_polygon(
		PackedVector2Array([Vector2(x - 50, y - 10), Vector2(x - 40, y - 9),
			Vector2(x - 44, y - 2), Vector2(x - 52, y - 3)]),
		PackedColorArray([dark, dark, dark, dark]))
	# 机身
	drawEllipse(on, x, y, 20, 9, body_col)
	drawEllipse(on, x + 6, y - 2, 9, 6, Color(0.5, 0.62, 0.8))
	# 起落橇
	on.draw_line(Vector2(x - 14, y + 12), Vector2(x + 16, y + 12), dark, 2.0)
	on.draw_line(Vector2(x - 10, y + 8), Vector2(x - 10, y + 12), dark, 2.0)
	on.draw_line(Vector2(x + 12, y + 8), Vector2(x + 12, y + 12), dark, 2.0)
	# 旋翼 (旋转)
	_rotor += 0.5
	var rx := cos(_rotor) * 34.0
	on.draw_line(Vector2(x - rx, y - 11), Vector2(x + rx, y - 11), Color(0.75, 0.78, 0.88), 2.0)
	on.draw_line(Vector2(x, y - 11), Vector2(x, y - 15), dark, 2.0)

func drawEllipse(on: CanvasItem, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(24):
		var a := TAU * i / 24.0
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	on.draw_colored_polygon(pts, col)

func _process(delta: float) -> void:
	_t += delta
	match _phase:
		0:
			_heli_x += 90.0 * delta
			if _heli_x >= 160.0:
				_heli_x = 160.0
				_phase = 1
		1:
			_heli_x = 160.0 + sin(_t * 2.0) * 3.0
			if _t > 5.0:
				_phase = 2
				Boot.play_sfx("sfx_start")
		2:
			_heli_x += 130.0 * delta
			if _heli_x > 460.0:
				_phase = 3
				_done_label.visible = true
				_falcon.visible = false            # THE END 阶段收起撤离字幕
				_evac.visible = false
				_stats.text = "SCORE %07d    LOOP %d    CAREER KILLS %d" % [
					Boot.score, Boot.loop_count, Boot.lifetime_kills]
				Boot.play_music("music_title", -8.0)
	_heli_node.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ENTER or event.physical_keycode == KEY_J \
				or event.physical_keycode == KEY_ESCAPE:
			_finish()
	elif event is InputEventMouseButton and event.pressed:
		_finish()

func _finish() -> void:
	if _skipped:
		return
	_skipped = true
	get_tree().change_scene_to_file("res://scenes/title.tscn")
