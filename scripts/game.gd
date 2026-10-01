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
var players: Array[Player] = []
var player: Player                       # 兼容引用 = P1
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
var _end_t := 0.0
var _intro_t := 2.0
var _gate_timer: Timer

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
	_spawn_players()
	Boot.play_music("music_stage")
	for p in players:
		hud.call("set_weapon", p.pnum, p.weapon)
	hud.call("flash_message", "mission1", 2.0)

# ---------------- 玩家 ----------------
func _spawn_players() -> void:
	_spawn_player(Vector2(40, GameData.GROUND_Y), 1)
	if Boot.player_count >= 2:
		_spawn_player(Vector2(70, GameData.GROUND_Y), 2)

func _spawn_player(at: Vector2, num: int) -> void:
	var p: Player = PLAYER_SCENE.new()
	p.pnum = num
	p.position = at
	add_child(p)
	p.add_to_group("player")
	p.died.connect(_on_player_died.bind(p))
	p.weapon_changed.connect(func(w: int): hud.call("set_weapon", num, w))
	p.lives = Boot.start_lives
	p.invuln_t = 2.0
	players.append(p)
	if num == 1:
		player = p

func nearest_player(pos: Vector2) -> Player:
	# 最近的存活玩家 (都死光时返回 null)
	var best: Player = null
	var best_d := INF
	for p in players:
		if p.dead:
			continue
		var d: float = p.position.distance_squared_to(pos)
		if d < best_d:
			best_d = d
			best = p
	return best

func alive_players() -> Array[Player]:
	var out: Array[Player] = []
	for p in players:
		if not p.dead:
			out.append(p)
	return out

func _on_player_died(p: Player) -> void:
	if p.lives > 0:
		p.respawn_t = 1.6
	elif alive_players().is_empty():
		_game_over()

func _respawn_player(p: Player) -> void:
	var base := cam_x + 30.0
	if players.size() > 1:
		# 避开还活着的同伴
		for other in players:
			if not other.dead and absf(other.position.x - base) < 24.0:
				base += 26.0
	# 从近到远找有落点的复活位, 避免悬在水面正上方连死
	var x := base
	var fy := INF
	for off in [0.0, 30.0, 60.0, 90.0, -30.0, -60.0]:
		x = base + off
		fy = floor_y_at(x, GameData.GROUND_Y)
		if fy != INF:
			break
	if fy == INF:
		x = base + 120.0
		fy = GameData.GROUND_Y
	p.respawn(Vector2(x, fy))
	# 复活点附近清场保护
	for e in get_tree().get_nodes_in_group("enemies"):
		if absf(e.position.x - x) < 100.0 and e is EnemyRunner:
			e.queue_free()

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
func player_in_bounds() -> bool:
	return not alive_players().is_empty()

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
	# 返回 x 处、y_near 上方或附近的落点 y (浮台优先, 其次实地); 无则 INF
	var best := INF
	for p in GameData.PLATFORMS:
		if x >= p.x and x <= p.x + p.z and y_near <= p.y + 8.0:
			best = minf(best, p.y)
	if best == INF and has_floor(x, y_near) and y_near <= GameData.GROUND_Y + 8.0:
		best = GameData.GROUND_Y
	return best

# ---------------- 帧循环 ----------------
func _physics_process(delta: float) -> void:
	# 复活倒计时用物理步长, 保证计时精确
	if level_done:
		return
	for p in players:
		if p.dead and p.lives > 0:
			p.respawn_t -= delta
			if p.respawn_t <= 0.0:
				_respawn_player(p)
		# 落后者不得超出屏幕左缘 (经典规则: 被镜头甩出即被推回)
		if not p.dead and p.position.x < cam_x + 6.0:
			p.position.x = cam_x + 6.0

func _process(delta: float) -> void:
	if level_done:
		_end_t += delta
		return
	if _intro_t > 0.0:
		_intro_t -= delta
		return

	# 相机: 跟随最靠前的存活玩家, 只前进不后退(经典规则)
	var target := 0.0
	var alive := alive_players()
	if not alive.is_empty():
		var lead_x := -INF
		for p in alive:
			lead_x = maxf(lead_x, p.position.x)
		target = clampf(lead_x - 120.0, 0.0, GameData.LEVEL_W - 320.0)
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

	# Boss 触发: 任一存活玩家到达警戒线
	if not boss_active and not alive.is_empty():
		for p in alive:
			if p.position.x >= boss_trigger_x:
				_start_boss()
				break

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
	_gate_timer = timer
	_toggle_gate()

var _gate_open := false
func _toggle_gate() -> void:
	if level_done:
		if _gate_timer != null:
			_gate_timer.stop()
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
