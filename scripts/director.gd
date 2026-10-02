extends Node2D
## 玩法导演: 负责非 game.gd 体系的额外敌人/事件生成 (mini-boss 等)
## 自包含设计: 只读 game 状态 (group "game"), 不侵入 game.gd, 主线重构无冲突
## 场景重载时本节点随场景重建, 每周目状态自动复位

var _gatling_done := false
var _tank_done := false
var _strike_cd := 4.0

func _physics_process(delta: float) -> void:
	var g := get_tree().get_first_node_in_group("game")
	if g == null or g.level_done:
		return
	var alive: Array = g.alive_players()
	if alive.size() == 0:
		return
	var lead: Player = alive[0]
	for p in alive:
		if p.position.x > lead.position.x:
			lead = p
	# 桥头加特林机枪堡: 玩家接近吊桥且 Boss 战未开始时出现一次
	if not _gatling_done and not g.boss_active and lead.position.x > 1380.0:
		_spawn_gatling(lead)
	# 碾压坦克: 炮塔区之后的长平地段出现一次
	if not _tank_done and not g.boss_active and lead.position.x > 2380.0:
		_spawn_tank(lead)
	# 空袭导弹: 吊桥后到 Boss 区前周期来袭
	if not g.boss_active and lead.position.x > 1700.0 and lead.position.x < GameData.BOSS_TRIGGER - 100.0:
		_strike_cd -= delta
		if _strike_cd <= 0.0:
			_spawn_air_strike(lead)
			_strike_cd = randf_range(12.0, 16.0)

func _spawn_gatling(lead: Player) -> void:
	_gatling_done = true
	var e := EnemyGatling.new()
	e.position = Vector2(minf(lead.position.x + 180.0, GameData.LEVEL_W - 400.0), 96.0)
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		return
	g.enemies_node.add_child(e)
	e.died.connect(func(s: int): Boot.score += s)

func _spawn_tank(lead: Player) -> void:
	_tank_done = true
	var e := EnemyTank.new()
	e.position = Vector2(minf(lead.position.x + 300.0, 3140.0), GameData.GROUND_Y - 60.0)
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		return
	g.enemies_node.add_child(e)
	e.died.connect(func(s: int): Boot.score += s)

func _spawn_air_strike(lead: Player) -> void:
	var g := get_tree().get_first_node_in_group("game")
	if g == null:
		return
	for offset in [-96.0, 96.0]:
		var e := EnemyMissile.new()
		e.setup(Vector2(lead.position.x + offset, -18.0), lead.position)
		g.enemies_node.add_child(e)
		e.died.connect(func(s: int): Boot.score += s)
