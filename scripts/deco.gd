extends Node2D
## 丛林装饰层: 棕榈/灌木/草丛 (Fierce Soldier scenery, CC-BY 4.0, 见 CREDITS.md)
## 场景树中位于 World 之后 Enemies 之前: 盖住地形, 不遮挡任何战斗单位
## 所有坐标已核对 GameData.GROUNDS 实地段, 避开水面缺口/吊桥/Boss区

const PALM1 := preload("res://assets/sprites/deco_palm1.png")
const PALM2 := preload("res://assets/sprites/deco_palm2.png")
const BUSH := preload("res://assets/sprites/deco_bush.png")
const GRASS := preload("res://assets/sprites/deco_grass.png")

const PALMS1 := [140, 860, 1450, 1900, 2600, 3150]
const PALMS2 := [360, 1100, 2450, 3050]
const BUSHES := [240, 500, 700, 1000, 1350, 1800, 2320, 2700, 3100]
const GRASSES := [90, 330, 830, 1060, 1310, 1700, 2050, 2300, 2500, 2850, 3020, 3300]

func _ready() -> void:
	for x in PALMS1:
		_put(PALM1, x)
	for x in PALMS2:
		_put(PALM2, x)
	for x in BUSHES:
		_put(BUSH, x)
	for x in GRASSES:
		_put(GRASS, x)

func _put(tex: Texture2D, x: float) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = Vector2(x - tex.get_width() / 2.0, GameData.GROUND_Y - tex.get_height())
	add_child(s)
