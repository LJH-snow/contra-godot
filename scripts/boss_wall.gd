extends StaticBody2D
## Boss 墙体: 静态障碍。核心开闭由 BossCore 自身阻挡子弹(关门时伤害无效),
## 墙体四块碰撞始终保留, 中门区域留空露出核心。

const TEX := preload("res://assets/sprites/boss_wall.png")

var _sprite: Sprite2D
var _core: BossCore
var _shutter: Polygon2D

func _ready() -> void:
	collision_layer = GameData.L_WORLD
	_sprite = Sprite2D.new()
	_sprite.texture = TEX
	_sprite.centered = false
	add_child(_sprite)
	# 中门金属闸门(关门时遮住核心; z_index 抬到敌人之上)
	_shutter = Polygon2D.new()
	_shutter.polygon = PackedVector2Array([
		Vector2(16, 112), Vector2(74, 112), Vector2(74, 180), Vector2(16, 180)])
	_shutter.color = Color(0.42, 0.42, 0.5)
	_shutter.z_index = 20
	add_child(_shutter)
	for i in range(3):                          # 闸门铆钉条
		var bar := Polygon2D.new()
		bar.polygon = PackedVector2Array([
			Vector2(26, 128 + i * 18), Vector2(70, 128 + i * 18),
			Vector2(70, 131 + i * 18), Vector2(26, 131 + i * 18)])
		bar.color = Color(0.3, 0.3, 0.37)
		_shutter.add_child(bar)

func attach_core(c: BossCore) -> void:
	_core = c

func open_gate() -> void:
	if _shutter != null:
		_shutter.visible = false
	if _core != null:
		_core.set_open(true)

func close_gate() -> void:
	if _shutter != null:
		_shutter.visible = true
	if _core != null:
		_core.set_open(false)

func build_shapes() -> void:
	# 96 宽 x 200 高: 上下横梁 + 左右两柱, 中门 40 宽区域为开口
	# 左柱拆成上下两段, 中间 y(局部)108..162 留作射击窗口:
	# 子弹可穿过窗口命中门内核心, 玩家身体仍被下横梁挡住
	for meta in [[Vector2(48, 24), Vector2(96, 48)],
			[Vector2(48, 178), Vector2(96, 44)],
			[Vector2(14, 89), Vector2(28, 38)],
			[Vector2(14, 170), Vector2(28, 16)],
			[Vector2(82, 100), Vector2(28, 108)]]:
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = meta[1]
		cs.shape = sh
		cs.position = meta[0]
		add_child(cs)
