extends StaticBody2D
## Boss 墙体: 静态障碍。核心开闭由 BossCore 自身阻挡子弹(关门时伤害无效),
## 墙体四块碰撞始终保留, 中门区域留空露出核心。

const TEX := preload("res://assets/sprites/boss_wall.png")

var _sprite: Sprite2D
var _core: BossCore
var _shutter: Polygon2D

func _ready() -> void:
	collision_layer = GameData.L_WORLD
	# 96x104 堡垒贴地: 自行定位 (覆盖 game.gd 预设的旧 200 高位置)
	position = Vector2(GameData.BOSS_X, GameData.GROUND_Y - 104)
	_sprite = Sprite2D.new()
	_sprite.texture = TEX
	_sprite.centered = false
	add_child(_sprite)
	# 中门金属闸门(关门时遮住核心; z_index 抬到敌人之上)
	# 核心贴图以节点为中心 (28x28), 位于墙底左角 覆盖 x0..28 / y72..100, 闸门须盖住它
	_shutter = Polygon2D.new()
	_shutter.polygon = PackedVector2Array([
		Vector2(-2, 70), Vector2(32, 70), Vector2(32, 102), Vector2(-2, 102)])
	_shutter.color = Color(0.42, 0.42, 0.5)
	_shutter.z_index = 20
	add_child(_shutter)
	for i in range(2):                          # 闸门铆钉条
		var bar := Polygon2D.new()
		bar.polygon = PackedVector2Array([
			Vector2(4, 78 + i * 12), Vector2(26, 78 + i * 12),
			Vector2(26, 81 + i * 12), Vector2(4, 81 + i * 12)])
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
	# 96 宽 x 104 高堡垒: 上横梁 + 右柱 + 右下横梁;
	# 左下角 x0..30 留弹道凹槽直通核心 (站立平射 y≈185 全局 = 局部 y≈89 可命中),
	# 玩家贸然走进凹槽会触到核心 (接触即死, 与官方一致)
	for meta in [[Vector2(48, 17), Vector2(96, 34)],
			[Vector2(76, 48), Vector2(40, 28)],
			[Vector2(63, 83), Vector2(66, 42)]]:
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		sh.size = meta[1]
		cs.shape = sh
		cs.position = meta[0]
		add_child(cs)
