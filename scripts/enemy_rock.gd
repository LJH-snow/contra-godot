class_name EnemyRock extends Enemy
## 瀑布滚石: 从上方坠落砸向攀爬的玩家, 可击碎; 击碎有概率掉 1UP (官方彩蛋)

const SHEET := preload("res://assets/sprites/tile_rock.png")

var fall_speed := 150.0
var gift_chance := 0.35                   # 击碎掉 1UP 概率

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("rock")
	hp = 1
	score_val = 100
	fall_speed = (135.0 + randf() * 45.0) * GameData.speed_scale(Boot.loop_count)
	make_sprite(SHEET, 0, 1, 1)
	make_body_shape(14, 14, 0)
	z_index = 4

func _physics_process(delta: float) -> void:
	position.y += fall_speed * delta
	_sprite.rotation += delta * 5.0
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		queue_free()
		return
	# 落到平台/实地即摔碎 (无分无礼)
	var fy: float = g.floor_y_at(position.x, position.y)
	if fy != INF and position.y >= fy - 6.0:
		_shatter(false)
		return
	if position.y > g.cam_y + 320.0:
		queue_free()

func kill() -> void:
	died.emit(score_val)
	_shatter(true)

func _shatter(by_shot: bool) -> void:
	Fx.make(get_parent(), position, "boom", 1.1)
	Boot.play_sfx("sfx_explode", -4.0)
	var g := get_tree().get_first_node_in_group("game")
	# 官方彩蛋: 打碎石头概率 +1 命
	if by_shot and g != null and randf() < gift_chance:
		for p in g.players:
			p.lives += 1
		g.hud.call("flash_message", "oneup", 1.2)
		Boot.play_sfx("sfx_powerup", -2.0)
	queue_free()
