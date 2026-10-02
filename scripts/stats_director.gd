extends CanvasLayer
## 结算导演(自治节点, 由 Boot 挂载): 过关时弹出本局统计浮层
## 只读 game 状态 + 惰性连接敌人 died 信号计击杀, 零侵入主场景

const SHOW_DELAY := 1.4            # 等爆炸演出结束再弹

var _kills := 0
var _time := 0.0
var _scene_id := 0
var _shown := false
var _anim_t := 0.0                  # 浮层展示秒数 (驱动逐行浮现/分数滚动)
var _root: Control
var _lines: Array[Label] = []

func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)
	var panel := ColorRect.new()
	panel.color = Color(0.03, 0.03, 0.08, 0.78)
	panel.position = Vector2(56, 62)
	panel.size = Vector2(208, 124)
	_root.add_child(panel)
	var border := ReferenceRect.new()
	border.position = panel.position
	border.size = panel.size
	border.border_color = Color(1.0, 0.85, 0.3, 0.9)
	border.editor_only = false
	_root.add_child(border)
	var head := Label.new()
	head.text = "MISSION COMPLETE"
	head.position = Vector2(56, 68)
	head.size = Vector2(208, 16)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 10)
	head.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_root.add_child(head)
	for i in range(5):
		var l := Label.new()
		l.position = Vector2(70, 90 + i * 16)
		l.size = Vector2(180, 14)
		l.add_theme_font_size_override("font_size", 8)
		l.add_theme_color_override("font_color", Color(0.9, 0.92, 1.0))
		_root.add_child(l)
		_lines.append(l)

func _process(delta: float) -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game == null:
		_root.visible = false
		_shown = false
		return
	# 场景重载(新周目/新开局) → 统计复位
	if game.get_instance_id() != _scene_id:
		_scene_id = game.get_instance_id()
		_kills = 0
		_time = 0.0
		_shown = false
		_root.visible = false
	if not game.level_done:
		if not get_tree().paused:
			_time += delta
		_hook_enemies(game)
		if _shown:                         # 非过关状态确保隐藏(重开等)
			_root.visible = false
			_shown = false
		return
	if _shown:
		_anim_t += delta                   # 驱动结算动画
		_refresh(game)
		return
	# 过关: 计一次任务 (生涯击杀已在每次击杀时实时累计, 此处随提交落盘)
	_shown = true
	_anim_t = 0.0
	Boot.missions_played += 1
	_root.visible = true
	_refresh(game)
	Boot.play_sfx("sfx_powerup", -4.0)

func _hook_enemies(game: Node) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy and not e.died.is_connected(_on_enemy_died):
			e.died.connect(_on_enemy_died)

func _on_enemy_died(_score: int) -> void:
	_kills += 1
	Boot.lifetime_kills += 1

func _refresh(game: Node) -> void:
	# 结算动画: 面板淡入 → 逐行浮现 → 分数滚动
	var t := _anim_t
	_root.modulate.a = clampf(t / 0.3, 0.0, 1.0)
	var roll := clampf((t - 0.5) / 0.9, 0.0, 1.0)          # 分数滚动 0.9s
	var shown_score := int(round(Boot.score * roll))
	var mm := int(_time) / 60
	var ss := int(_time) % 60
	var texts := [
		"SCORE   %07d" % shown_score,
		"BEST    %07d%s" % [Boot.high_score, "  NEW!" if Boot.score >= Boot.high_score else ""],
		"KILLS   %d      LOOP %d" % [_kills, Boot.loop_count],
		"TIME    %02d:%02d" % [mm, ss],
		"TOTAL   %d KILLS / %d RUNS" % [Boot.lifetime_kills, Boot.missions_played],
	]
	for i in range(_lines.size()):
		_lines[i].text = texts[i] if t > 0.4 + i * 0.22 else ""
