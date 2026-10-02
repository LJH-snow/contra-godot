class_name EnemyGrenadier extends EnemyRunner
## 手雷兵: 缓慢逼近, 定点抛物线手雷 (官方基地关敌兵之一)

var _lob_t := 1.1

func _ready() -> void:
	super()
	add_to_group("grenadier")
	score_val = 300
	run_speed *= 0.5
	_fire_t = 99999.0                            # 不用步枪, 只扔雷
	_sprite.self_modulate = Color(1.0, 0.87, 0.55)   # 土黄标识

func _physics_process(delta: float) -> void:
	_lob_t -= delta
	if _lob_t <= 0.0 and is_on_floor():
		var g := get_tree().get_first_node_in_group("game")
		var pl: Node2D = g.nearest_player(global_position) if g != null else null
		if pl != null and absf(pl.global_position.x - global_position.x) < 280.0:
			_lob_t = 2.2 + randf() * 0.9
			_lob(g, pl)
		else:
			_lob_t = 0.6
	super(delta)

func _shoot() -> void:
	pass                                         # 覆盖跑兵的停步射击

func _lob(g: Node, pl: Node2D) -> void:
	var dx: float = pl.global_position.x - global_position.x
	var tof := clampf(absf(dx) / 140.0, 0.5, 1.4)   # 飞行时间
	# 抛物线: 选取初速使落点恰为目标 (g=620)
	var eb := EBullet.new()
	eb.setup_grenade(global_position + Vector2(0, -20),
		Vector2(dx / tof, -0.5 * 620.0 * tof))
	g.enemies_node.add_child(eb)
	Boot.play_sfx("sfx_clang", -7.0)
