extends Node
## 特效导演(自治节点, 由 Boot 挂载): 击杀分数飘字 + 屏幕闪光
## 击杀飘字: 惰性连接敌人 died 信号, 在击杀位置弹出 "+分数"
## 屏幕闪光: 玩家死亡红闪 / Boss警告白闪 / 击破过关金闪
## 全部只读轮询+信号, 零侵入主场景

var _flash: ColorRect
var _scene_id := 0
var _dead_state := {}
var _boss_was := false
var _done_was := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 18
	add_child(layer)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_flash)

func _process(delta: float) -> void:
	_process_combo(delta)
	var game := get_tree().get_first_node_in_group("game")
	if game == null:
		_dead_state.clear()
		return
	if game.get_instance_id() != _scene_id:
		_scene_id = game.get_instance_id()
		_dead_state.clear()
		_done_was = false
		_boss_was = false
	_hook_enemies(game)
	# 玩家死亡 → 红闪
	for p in get_tree().get_nodes_in_group("player"):
		var id: int = p.get_instance_id()
		if p.dead and not _dead_state.get(id, false):
			flash(Color(0.9, 0.1, 0.1, 0.32), 0.28)
		_dead_state[id] = p.dead
	# Boss 警告 → 白闪两下
	if game.boss_active and not _boss_was:
		flash(Color(1, 1, 1, 0.25), 0.12)
		var t := get_tree().create_timer(0.18)
		t.timeout.connect(func(): flash(Color(1, 1, 1, 0.25), 0.12))
	_boss_was = game.boss_active
	# 击破过关 → 金闪
	if game.level_done and not _done_was:
		flash(Color(1.0, 0.85, 0.3, 0.45), 0.5)
	_done_was = game.level_done

## 屏幕闪光 (颜色含 alpha 强度)
func flash(col: Color, dur: float) -> void:
	_flash.color = col
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(_flash, "color:a", 0.0, dur)

# ---------------- 击杀飘字 + 连击 ----------------
const COMBO_WINDOW := 3.0           # 连击保持窗口(秒)
const COMBO_BONUS := 25             # 每级连击奖励分

var _combo := 0
var _combo_t := 0.0
var _combo_label: Label

func _hook_enemies(game: Node) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy and not e.died.is_connected(_on_enemy_died):
			e.died.connect(_on_enemy_died.bind(e))

func _process_combo(delta: float) -> void:
	if _combo > 0:
		_combo_t -= delta
		if _combo_t <= 0.0:
			_combo = 0
			_refresh_combo()

func _on_enemy_died(score: int, e: Node2D) -> void:
	# 连击计数 + 奖励分
	_combo += 1
	_combo_t = COMBO_WINDOW
	var bonus := mini(_combo - 1, 8) * COMBO_BONUS
	if bonus > 0:
		Boot.score += bonus
	if _combo == 5 or _combo == 8 or _combo == 12:
		Boot.play_sfx("sfx_combo")            # 连击里程碑闪亮音
	_refresh_combo()
	var game := get_tree().get_first_node_in_group("game")
	if game == null or e == null or not is_instance_valid(e):
		return
	var popup := Node2D.new()
	popup.add_to_group("kill_popup")
	popup.position = e.position + Vector2(0, -26)
	popup.z_index = 40
	var l := Label.new()
	var big: bool = score >= GameData.SCORE_BOSS
	var txt := "+%d" % score
	if _combo >= 2:
		txt += "  x%d" % _combo
	l.text = txt
	l.add_theme_font_size_override("font_size", 12 if big else 8)
	l.add_theme_color_override("font_color",
		Color(1.0, 0.85, 0.3) if not big else Color(1.0, 0.5, 0.3))
	l.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.08))
	l.add_theme_constant_override("outline_size", 3)
	popup.add_child(l)
	game.add_child(popup)
	var tw := popup.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(popup, "position:y", popup.position.y - 22.0, 0.7)
	tw.tween_property(popup, "modulate:a", 0.0, 0.7).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(popup.queue_free)

## 顶部连击计数牌
func _refresh_combo() -> void:
	if _combo_label == null:
		_combo_label = Label.new()
		_combo_label.position = Vector2(0, 44)
		_combo_label.size = Vector2(320, 16)
		_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_combo_label.add_theme_font_size_override("font_size", 10)
		_combo_label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.08))
		_combo_label.add_theme_constant_override("outline_size", 3)
		var layer := CanvasLayer.new()
		layer.layer = 17
		add_child(layer)
		layer.add_child(_combo_label)
	if _combo >= 2:
		_combo_label.text = "%d COMBO!" % _combo
		_combo_label.add_theme_color_override("font_color",
			Color(1.0, 0.85, 0.3) if _combo < 5 else Color(1.0, 0.45, 0.3))
		_combo_label.visible = true
	else:
		_combo_label.visible = false
