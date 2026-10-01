class_name BossCore extends Enemy
## 关底 Boss 核心: 藏在基地墙内, 周期张门开火, 血量高

signal boss_destroyed

const SHEET := preload("res://assets/sprites/boss_core.png")

var open := false
var fire_int := 1.5
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
	make_body_shape(22, 22, -14)
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
			_t = fire_int * (0.9 + randf() * 0.25)
			_burst = 3
			_burst_t = 0.05

func _fire(pl: Node2D) -> void:
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		return
	var d := (pl.global_position + Vector2(0, -12) - (global_position + Vector2(0, -14))).normalized()
	for off in [-0.16, 0.0, 0.16]:
		var eb := EBullet.new()
		g.enemies_node.add_child(eb)
		eb.setup(global_position + Vector2(0, -14) + d * 12.0, d.rotated(off),
			150.0 * GameData.fire_scale(Boot.loop_count))
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
	if hp <= 0:
		kill()

func kill() -> void:
	died.emit(score_val)
	boss_destroyed.emit()                      # 爆炸与过关由 game 的信号连接处理, 只走一条路径
	queue_free()
