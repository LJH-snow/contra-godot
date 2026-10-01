extends CanvasLayer
## HUD: 生命图标 / 武器字母 / 分数 / Boss 血条 / 中央提示(预渲染文案)

const LIFE_TEX := preload("res://assets/sprites/life.png")
const MSG := {
	"mission1": preload("res://assets/text/mission1.png"),
	"warning": preload("res://assets/text/warning.png"),
	"core_open": preload("res://assets/text/core_open.png"),
	"clear": preload("res://assets/text/clear.png"),
	"gameover": preload("res://assets/text/gameover.png"),
	"eagle": preload("res://assets/text/eagle.png"),
}
const WEAPON_LABEL := {0: "R", 1: "M", 2: "S", 3: "L", 4: "F", 5: "R+", 6: "B", 7: "★"}

var _lives_box: HBoxContainer
var _weapon: Label
var _score: Label
var _msg: TextureRect
var _boss_bar: ProgressBar
var _boss_title: Label
var _msg_t := 0.0

func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_score = Label.new()
	_score.text = "0000000"
	_score.position = Vector2(8, 4)
	_score.add_theme_font_size_override("font_size", 8)
	_score.add_theme_color_override("font_color", Color.WHITE)
	_score.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	_score.add_theme_constant_override("outline_size", 3)
	root.add_child(_score)

	_weapon = Label.new()
	_weapon.text = "R"
	_weapon.position = Vector2(296, 4)
	_weapon.add_theme_font_size_override("font_size", 8)
	_weapon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_weapon.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
	_weapon.add_theme_constant_override("outline_size", 3)
	root.add_child(_weapon)

	_lives_box = HBoxContainer.new()
	_lives_box.position = Vector2(8, 220)
	_lives_box.add_theme_constant_override("separation", 1)
	root.add_child(_lives_box)

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
	_msg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_msg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_msg.visible = false
	root.add_child(_msg)

func set_weapon(w: int) -> void:
	_weapon.text = str(WEAPON_LABEL.get(w, "R"))

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

func set_boss_hp(f: float) -> void:
	_boss_bar.value = clampf(f, 0.0, 1.0)

func _process(delta: float) -> void:
	if _msg_t > 0.0:
		_msg_t -= delta
		if _msg_t <= 0.0:
			_msg.visible = false
	var p := get_tree().get_first_node_in_group("player")
	if p != null:
		var n: int = maxf(0, p.lives)
		while _lives_box.get_child_count() > n:
			var c := _lives_box.get_child(_lives_box.get_child_count() - 1)
			_lives_box.remove_child(c)
			c.queue_free()
		while _lives_box.get_child_count() < n:
			var t := TextureRect.new()
			t.texture = LIFE_TEX
			t.stretch_mode = TextureRect.STRETCH_KEEP
			_lives_box.add_child(t)
	if p != null and not p.dead:
		_score.text = "%07d" % Boot.score
