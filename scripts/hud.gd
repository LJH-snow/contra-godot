extends CanvasLayer
## HUD: 分数 / 武器字母 / 生命图标 / Boss 血条 / 中央提示(预渲染文案)
## 单人: 左上分数+右上武器; 双人: 1P 左侧 / 2P 右侧 各一套

const LIFE_TEX := preload("res://assets/sprites/life.png")
const LIFE2_TEX := preload("res://assets/sprites/life2.png")
const MSG := {
	"mission1": preload("res://assets/text/mission1.png"),
	"warning": preload("res://assets/text/warning.png"),
	"core_open": preload("res://assets/text/core_open.png"),
	"clear": preload("res://assets/text/clear.png"),
	"gameover": preload("res://assets/text/gameover.png"),
	"eagle": preload("res://assets/text/eagle.png"),
	"oneup": preload("res://assets/text/oneup.png"),
	"swim": preload("res://assets/text/swim.png"),
}
const WEAPON_LABEL := {0: "R", 1: "M", 2: "S", 3: "L", 4: "F", 5: "R+", 6: "B", 7: "★"}

var _two_p := false
var _score: Label
var _weapon: Label
var _score2: Label
var _weapon2: Label
var _lives_box: HBoxContainer
var _lives2_box: HBoxContainer
var _msg: TextureRect
var _boss_bar: ProgressBar
var _boss_title: Label
var _msg_t := 0.0

func _ready() -> void:
	layer = 10
	_two_p = Boot.player_count >= 2
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	if _two_p:
		_score = _mklabel(root, "1P", Vector2(8, 4), Color(0.6, 0.85, 1.0))
		_weapon = _mklabel(root, "R", Vector2(128, 4), Color(1.0, 0.85, 0.3))
		_score2 = _mklabel(root, "2P", Vector2(168, 4), Color(1.0, 0.7, 0.65))
		_weapon2 = _mklabel(root, "R", Vector2(296, 4), Color(1.0, 0.85, 0.3))
	else:
		_score = _mklabel(root, "0000000", Vector2(8, 4), Color.WHITE)
		_weapon = _mklabel(root, "R", Vector2(296, 4), Color(1.0, 0.85, 0.3))

	_lives_box = _mklives(root, Vector2(8, 220), LIFE_TEX)
	if _two_p:
		_lives2_box = _mklives(root, Vector2(280, 220), LIFE2_TEX)

	_boss_title = Label.new()
	_boss_title.text = "BOSS"
	_boss_title.position = Vector2(10, 28)
	_boss_title.add_theme_font_size_override("font_size", 8)
	_boss_title.add_theme_color_override("font_color", Color(1, 0.35, 0.3))
	_boss_title.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	_boss_title.add_theme_constant_override("outline_size", 3)
	_boss_title.visible = false
	root.add_child(_boss_title)

	_boss_bar = ProgressBar.new()
	_boss_bar.position = Vector2(42, 29)
	_boss_bar.size = Vector2(230, 7)
	_boss_bar.min_value = 0
	_boss_bar.max_value = 1.0
	_boss_bar.show_percentage = false
	_boss_bar.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.62, 0.13, 0.12)
	_boss_bar.add_theme_stylebox_override("fill", sb)
	var sbg := StyleBoxFlat.new()
	sbg.bg_color = Color(0.07, 0.07, 0.11, 0.85)
	sbg.border_color = Color(0.8, 0.8, 0.9)
	sbg.set_border_width_all(1)
	_boss_bar.add_theme_stylebox_override("background", sbg)
	root.add_child(_boss_bar)

	_msg = TextureRect.new()
	_msg.position = Vector2(0, 92)
	_msg.size = Vector2(320, 44)
	_msg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_msg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_msg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_msg.visible = false
	root.add_child(_msg)

func _mklabel(root: Control, txt: String, pos: Vector2, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.position = pos
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	l.add_theme_constant_override("outline_size", 3)
	root.add_child(l)
	return l

func _mklives(root: Control, pos: Vector2, tex: Texture2D) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.position = pos
	box.add_theme_constant_override("separation", 1)
	root.add_child(box)
	box.set_meta("tex", tex)
	return box

func set_weapon(pnum: int, w: int) -> void:
	var label := _weapon2 if pnum >= 2 else _weapon
	if label != null:
		label.text = str(WEAPON_LABEL.get(w, "R"))

func flash_message(key: String, dur: float) -> void:
	if MSG.has(key):
		_msg.texture = MSG[key]
		_msg.visible = true
		_msg_t = dur

func show_boss_bar(v: bool) -> void:
	_boss_bar.visible = v
	_boss_title.visible = v
	if v:
		_boss_bar.value = 1.0

## 纵向关: Boss 在屏幕上方, 血条移到底部避免遮挡攀爬路径
func set_boss_bar_bottom() -> void:
	_boss_bar.position = Vector2(42, 206)
	_boss_title.position = Vector2(10, 205)

func set_boss_hp(f: float) -> void:
	_boss_bar.value = clampf(f, 0.0, 1.0)

func _process(delta: float) -> void:
	if _msg_t > 0.0:
		_msg_t -= delta
		if _msg_t <= 0.0:
			_msg.visible = false
	var game := get_tree().get_first_node_in_group("game")
	if game == null:
		return
	var ps: Array = game.players
	if ps.is_empty():
		return
	# 分数 (共享计分)
	if _two_p:
		_score.text = "1P %07d" % Boot.score
		_score2.text = "2P"
	else:
		_score.text = "%07d" % Boot.score
	# 生命图标
	_sync_lives(_lives_box, ps[0])
	if _two_p and _lives2_box != null and ps.size() > 1:
		_sync_lives(_lives2_box, ps[1])

func _sync_lives(box: HBoxContainer, p: Node) -> void:
	var n := 0
	if p != null:
		n = maxi(0, p.lives)
	while box.get_child_count() > n:
		var c := box.get_child(box.get_child_count() - 1)
		box.remove_child(c)
		c.queue_free()
	while box.get_child_count() < n:
		var t := TextureRect.new()
		t.texture = box.get_meta("tex")
		t.stretch_mode = TextureRect.STRETCH_KEEP
		box.add_child(t)
