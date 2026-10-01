extends Node2D
## 游戏主场景: 关卡构建 / 敌人生成 / 镜头 / Boss 战 / HUD 信号

const TILE := 16
const TEX_TILES := {
	"grass": preload("res://assets/sprites/tile_grass.png"),
	"dirt": preload("res://assets/sprites/tile_dirt.png"),
	"platform": preload("res://assets/sprites/tile_platform.png"),
	"water1": preload("res://assets/sprites/tile_water1.png"),
	"water2": preload("res://assets/sprites/tile_water2.png"),
}
const PLAYER_SCENE := preload("res://scripts/player.gd")
const BRIDGE_SCENE := preload("res://scripts/bridge.gd")

# 节点
var player: Player
var world_node: Node2D
var enemies_node: Node2D
var bullets_node: Node2D
var items_node: Node2D
var boss_wall: StaticBody2D
var boss_core: BossCore
var bridge: Bridge
var cam_x := 0.0

# 状态
var score := 0
var boss_active := false
var boss_trigger_x := GameData.BOSS_TRIGGER
var level_done := false
var _spawn_t := 1.2
var _capsule_t := 9.0
var _items_dropped := 0
var _w := [GameData.W.M, GameData.W.S, GameData.W.L, GameData.W.F, GameData.W.R, GameData.W.B]
var _wig := [0, 1, 2, 3, 4, 5]
var _wig_i := 0
var _respawn_t := 0.0
var _end_t := 0.0
var _intro_t := 2.0

# HUD 引用(由 main.tscn 提供)
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	add_to_group("game")
	world_node = $World
	enemies_node = $Enemies
	bullets_node = $Bullets
	items_node = $Items
	_build_terrain()
	_build_statics()
	_spawn_player(Vector2(40, GameData.GROUND_Y))
	Boot.play_music("music_stage")
	hud.call("set_weapon", player.weapon)
	hud.call("flash_message", "mission1", 2.0)

# ---------------- 地形 ----------------
func _build_terrain() -> void:
	# 实心地段(像素区间): 顶层草 + 泥土到屏底; 缺口处画水面
	for seg in GameData.GROUNDS:
		for x in range(seg.x, seg.y, TILE):
			_tile(TEX_TILES["grass"], x, GameData.GROUND_Y)
			for y in range(GameData.GROUND_Y + TILE, 240, TILE):
				_tile(TEX_TILES["dirt"], x, y)
	for i in range(GameData.GROUNDS.size() - 1):
		var a: int = GameData.GROUNDS[i].y
		var b: int = GameData.GROUNDS[i + 1].x
		for x in range(a, b, TILE):
			for y in range(GameData.GROUND_Y, 240, TILE):
				_tile(TEX_TILES["water1" if (x / TILE + y / TILE) % 2 == 0 else "water2"], x, y)
	# 静态碰撞体 (每段一个大矩形)
	for seg in GameData.GROUNDS:
		var body := StaticBody2D.new()
		body.collision_layer = GameData.L_WORLD
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		var w := seg.y - seg.x
		sh.size = Vector2(w, 240 - GameData.GROUND_Y)
		cs.shape = sh
		cs.position = Vector2(seg.x + w / 2.0, GameData.GROUND_Y + sh.size.y / 2.0)
		body.add_child(cs)
		world_node.add_child(body)
	# 浮台(单向碰撞: 可从下方穿过跳上)
	for p in GameData.PLATFORMS:
		var body2 := StaticBody2D.new()
		body2.collision_layer = GameData.L_PLATFORM
		var cs2 := CollisionShape2D.new()
		var sh2 := RectangleShape2D.new()
		sh2.size = Vector2(p.z, 6)
		cs2.shape = sh2
		cs2.position = Vector2(p.x + p.z / 2.0, p.y + 3)
		cs2.one_way_collision = true
		body2.add_child(cs2)
		for i in range(int(p.z) / TILE):
			var s := Sprite2D.new()
			s.texture = TEX_TILES["platform"]
			s.centered = false
			s.position = Vector2(p.x + i * TILE, p.y)
			body2.add_child(s)
		world_node.add_child(body2)

func _tile(tex: Texture2D, x_px: int, y_px: int) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = Vector2(x_px, y_px)
	world_node.add_child(s)

# ---------------- 静态物体 ----------------
func _build_statics() -> void:
	# 吊桥 (1504→1664 共 160px = 10 段)
	bridge = BRIDGE_SCENE.new()
	bridge.build(float(GameData.BRIDGE.x), float(GameData.GROUND_Y),
		(GameData.BRIDGE.y - GameData.BRIDGE.x) / GameData.BRIDGE_SEG)
	world_node.add_child(bridge)
	# 狙击手
	for s in GameData.SNIPERS:
		var sn := EnemySniper.new()
		sn.position = Vector2(s.x, s.y)
		enemies_node.add_child(sn)
		_hook_score(sn)
	# 炮塔
	for t in GameData.TURRETS:
		var tu := EnemyTurret.new()
		tu.position = Vector2(t.x, t.y)
		enemies_node.add_child(tu)
		_hook_score(tu)
	# Boss 墙
	boss_wall = StaticBody2D.new()
	boss_wall.set_script(preload("res://scripts/boss_wall.gd"))
	boss_wall.position = Vector2(GameData.BOSS_X, GameData.GROUND_Y - 176)
	world_node.add_child(boss_wall)
	boss_wall.build_shapes()
	boss_core = BossCore.new()
	boss_core.position = Vector2(GameData.BOSS_X + 48 - 14, GameData.GROUND_Y - 42)
	boss_core.boss_destroyed.connect(_on_boss_core_destroyed)
	enemies_node.add_child(boss_core)
	_hook_score(boss_core)
	boss_wall.attach_core(boss_core)
	boss_core.set_open(false)

func _on_boss_core_destroyed() -> void:
	on_boss_destroyed(boss_wall.position + Vector2(48, 24))

# ---------------- 玩家 ----------------
func _spawn_player(at: Vector2) -> void:
	player = PLAYER_SCENE.new()
	player.position = at
	add_child(player)
	player.add_to_group("player")
	player.died.connect(_on_player_died)
	player.weapon_changed.connect(_on_weapon_changed)
	player.invuln_t = 2.0

func _on_player_died() -> void:
	if player.lives <= 0:
		_game_over()
	else:
		_respawn_t = 1.6

func _on_weapon_changed(w: int) -> void:
	hud.call("set_weapon", w)

func player_in_bounds() -> bool:
	return player != null and not player.dead and player.position.x > cam_x - 10.0

func _respawn_player() -> void:
	var x := cam_x + 30.0
	# 找安全的地面
	var fy := floor_y_at(x, GameData.GROUND_Y)
	if fy == INF:
		x = cam_x + 60.0
		fy = floor_y_at(x, GameData.GROUND_Y)
	if fy == INF:
		fy = GameData.GROUND_Y
	player.respawn(Vector2(x, fy))
	# 敌人清场保护
	for e in get_tree().get_nodes_in_group("enemies"):
		if absf(e.position.x - x) < 100.0 and e is EnemyRunner:
			e.queue_free()

# ---------------- 通用查询 ----------------
func has_floor(x: float, _y: float) -> bool:
	for seg in GameData.GROUNDS:
		if x >= seg.x and x < seg.y:
			return true
	if bridge != null:
		var lx: float = x - bridge.position.x
		var i := int(lx / Bridge.SEG_W)
		if i >= 0 and i < bridge.segs.size():
			var b := bridge.segs[i]
			if b != null:
				for cs in b.get_children():
					if cs is CollisionShape2D and not cs.disabled:
						return true
	return false

func floor_y_at(x: float, y_near: float) -> float:
	# 返回 x 处、y_near 上方或附近的地面顶 y; 无则 INF
	if has_floor(x, y_near) and y_near <= GameData.GROUND_Y + 8.0:
		return GameData.GROUND_Y
	return INF

# ---------------- 帧循环 ----------------
func _physics_process(delta: float) -> void:
	# 复活倒计时用物理步长, 保证计时精确
	if not level_done and player != null and player.dead and player.lives > 0:
		_respawn_t -= delta
		if _respawn_t <= 0.0:
			_respawn_player()

func _process(delta: float) -> void:
	if level_done:
		_end_t += delta
		return
	if _intro_t > 0.0:
		_intro_t -= delta
		return

	# 相机: 只前进不后退(经典规则), Boss区自然钳制到右端
	var target := 0.0
	if player != null:
		target = clampf(player.position.x - 120.0, 0.0, GameData.LEVEL_W - 320.0)
	cam_x = maxf(cam_x, target)
	position = Vector2(-cam_x, 0)

	# 敌人波次
	_spawn_t -= delta
	if _spawn_t <= 0.0 and not boss_active:
		_spawn_t = maxf(1.15, 2.1 - Boot.loop_count * 0.18)
		_spawn_wave()
	# 胶囊
	_capsule_t -= delta
	if _capsule_t <= 0.0 and not boss_active:
		_capsule_t = 11.0 + randf() * 5.0
		var cap := EnemyCapsule.new()
		enemies_node.add_child(cap)
		_hook_score(cap)

	# Boss 触发
	if not boss_active and player != null and not player.dead \
			and player.position.x >= boss_trigger_x:
		_start_boss()

func _spawn_wave() -> void:
	var count := 1 + (randi() % 2) + (1 if Boot.loop_count > 1 else 0)
	var side := 1 if randf() < 0.72 else -1       # 多数从右侧来
	for i in range(count):
		var e := EnemyRunner.new()
		var sx: float
		if side > 0:
			sx = cam_x + 340.0 + i * 22.0
		else:
			sx = cam_x - 20.0 - i * 22.0
		# 需要有地面
		if not has_floor(sx, GameData.GROUND_Y):
			sx = cam_x + 340.0
		e.position = Vector2(sx, GameData.GROUND_Y - 40.0)
		enemies_node.add_child(e)
		_hook_score(e)

func _hook_score(e: Enemy) -> void:
	e.died.connect(func(s: int): Boot.score += s)

# ---------------- Boss 战 ----------------
func _start_boss() -> void:
	boss_active = true
	hud.call("flash_message", "warning", 1.6)
	hud.call("show_boss_bar", true)
	Boot.play_sfx("sfx_eagle")
	# 周期开门射击
	var timer := Timer.new()
	timer.wait_time = 2.4
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_toggle_gate)
	_toggle_gate()

var _gate_open := false
func _toggle_gate() -> void:
	if level_done:
		return
	_gate_open = not _gate_open
	if _gate_open:
		boss_wall.open_gate()
		hud.call("flash_message", "core_open", 1.0)
	else:
		boss_wall.close_gate()

func boss_hp_changed(hp: int, maxhp: int) -> void:
	hud.call("set_boss_hp", float(hp) / maxhp)

func on_boss_destroyed(pos: Vector2) -> void:
	hud.call("show_boss_bar", false)
	Boot.play_sfx("sfx_explode_big")
	# 连环爆炸
	for i in range(8):
		var t := get_tree().create_timer(i * 0.18)
		t.timeout.connect(func():
			var p := pos + Vector2(randf_range(-40, 40), randf_range(-60, 30))
			Fx.make(self, p, "boom_big", 1.0 + i * 0.12)
			Boot.play_sfx("sfx_explode", -6.0))
	var t2 := get_tree().create_timer(1.8)
	t2.timeout.connect(_mission_complete)

func _mission_complete() -> void:
	if level_done:
		return
	level_done = true
	Boot.stop_music()
	Boot.play_sfx("sfx_clear")
	hud.call("flash_message", "clear", 3.0)
	# 循环下一轮(保留分数, 提升难度)
	var t := get_tree().create_timer(3.2)
	t.timeout.connect(func():
		Boot.loop_count += 1
		get_tree().reload_current_scene())

func _game_over() -> void:
	hud.call("flash_message", "gameover", 4.0)
	var t := get_tree().create_timer(3.5)
	t.timeout.connect(func():
		Boot.loop_count = 1
		get_tree().change_scene_to_file("res://scenes/main.tscn"))

# ---------------- 道具 ----------------
func spawn_item(pos: Vector2) -> void:
	var it := ItemBox.new()
	it.setup(pos, _w[_wig_i % _w.size()])
	_wig_i += 1
	items_node.add_child(it)
	it.vy = -60.0

func eagle_wipe() -> void:
	Boot.play_sfx("sfx_eagle")
	hud.call("flash_message", "eagle", 1.2)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy and not (e is BossCore):
			e.kill()
	# 清空敌弹
	for n in enemies_node.get_children():
		if n is EBullet:
			n.queue_free()
