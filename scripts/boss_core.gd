class_name BossCore extends Enemy
## 关底 Boss 核心: 藏在基地墙内, 周期张门开火, 血量高

signal boss_destroyed

const SHEET := preload("res://assets/sprites/boss_core.png")

var open := false
var fire_int := 1.8
var volley := 3                       # 每轮弹数 (瀑布关调低)
var enraged := false                  # 半血以下狂暴: 射速翻倍+五连弹幕
var _t := 2.0
var _burst := 0
var _burst_t := 0.0
var max_hp := 30

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	hp = 30 + (Boot.loop_count - 1) * 10
	max_hp = hp
	score_val = GameData.SCORE_BOSS
	make_sprite(SHEET, 0, 2, 1)
	make_body_shape(24, 24, 0)          # 与站立平射弹道(y≈185)同高
	_t = 2.2

func set_open(o: bool) -> void:
	open = o

func _physics_process(delta: float) -> void:
	_sprite.frame = 0 if not open else (1 - int(Time.get_ticks_msec() * 0.008) % 2)
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		return
	var pl: Node2D = g.nearest_player(global_position)
	if pl == null:
		return
	if _burst > 0:
		_burst_t -= delta
		if _burst_t <= 0.0:
			_burst -= 1
			_burst_t = 0.24
			_fire(pl)
		elif open:
			_t -= delta
			if _t <= 0.0:
				_t = fire_interval() * (0.9 + randf() * 0.25)
				_burst = volley if not enraged else (5 if volley >= 3 else 3)
				_burst_t = 0.05


## 半血以下狂暴: 射速提升, 弹幕加宽; 小弹量 Boss 保持可躲
func fire_interval() -> float:
	return fire_int * ((0.7 if volley <= 2 else 0.5) if enraged else 1.0)

func _fire(pl: Node2D) -> void:
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		return
	var d := (pl.global_position + Vector2(0, -12) - (global_position + Vector2(0, -14))).normalized()
	var offs: Array = [-0.28, -0.14, 0.0, 0.14, 0.28] if enraged \
			else ([-0.18, 0.18] if volley <= 2 else [-0.16, 0.0, 0.16])
	for off in offs:
		var eb := EBullet.new()
		g.enemies_node.add_child(eb)
		eb.setup(global_position + Vector2(0, -14) + d * 12.0, d.rotated(off),
			130.0 * GameData.fire_scale(Boot.loop_count))
	Boot.play_sfx("sfx_clang", -2.0)

func damage(amt: int, dir: Vector2) -> void:
	if not open:
		Boot.play_sfx("sfx_clang", -6.0)       # 关门时子弹被弹开
		return
	hp -= amt
	_flash = 0.06
	Boot.play_sfx("sfx_bosshit", -4.0)
	var g := get_tree().get_first_node_in_group("game")
	if g != null:
		g.boss_hp_changed(hp, max_hp)
	if not enraged and hp <= max_hp / 2 and hp > 0:
		enraged = true
		_flash = 0.3
		if g != null:
			g.hud.call("flash_message", "enrage", 1.2)
		Boot.play_sfx("sfx_eagle", -4.0)
	if hp <= 0:
		kill()

func kill() -> void:
	died.emit(score_val)
	boss_destroyed.emit()                      # 爆炸与过关由 game 的信号连接处理, 只走一条路径
	queue_free()
