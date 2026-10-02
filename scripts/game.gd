extends Node2D
## 游戏主场景: 关卡构建 / 敌人生成 / 镜头 / Boss 战 / HUD 信号

const TILE := 16
const TEX_TILES := {
	"grass": preload("res://assets/sprites/tile_grass.png"),
	"dirt": preload("res://assets/sprites/tile_dirt.png"),
	"platform": preload("res://assets/sprites/tile_platform.png"),
	"water1": preload("res://assets/sprites/tile_water1.png"),
	"water2": preload("res://assets/sprites/tile_water2.png"),
	"snow": preload("res://assets/sprites/tile_snow.png"),
	"rock": preload("res://assets/sprites/tile_rock.png"),
	"icewater1": preload("res://assets/sprites/tile_icewater1.png"),
	"icewater2": preload("res://assets/sprites/tile_icewater2.png"),
	"cave": preload("res://assets/sprites/tile_cave.png"),
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
var cam_y := 0.0

# 关卡配置 (由 GameData.level_config 提供)
var cfg := {}
var L_VERTICAL := false
var L_W := 3488
var L_H := 240.0
var L_GROUNDS: Array = []
var L_PLATFORMS: Array = []
var L_GROUND_Y := 200
var L_FALL_LINE := 252.0
var L_BOSS_TRIGGER := 3088.0
var L_NAME := "MISSION 1  丛林"
var L_MSG_KEY := "mission1"

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
	Boot.setup_input(Boot.player_count)        # 按人数分配键位
	_apply_level()
	world_node = $World
	enemies_node = $Enemies
	bullets_node = $Bullets
	items_node = $Items
	_build_background()
	_build_terrain()
	_build_statics()
	_spawn_players()
	var track := "music_stage"
	if cfg["bg"] == "snow":
		track = "music_snow"
	Boot.play_music(track)
	for p in players:
		hud.call("set_weapon", p.pnum, p.weapon)
	hud.call("flash_message", L_MSG_KEY, 2.0)

## 关卡配置应用
func _apply_level() -> void:
	cfg = GameData.level_config(Boot.level)
	L_VERTICAL = cfg["vertical"]
	L_W = cfg["w"]
	L_H = float(cfg["h"])
	L_GROUNDS = cfg["grounds"]
	L_PLATFORMS = cfg["platforms"]
	L_GROUND_Y = cfg["ground_y"]
	L_FALL_LINE = cfg["fall_line"]
	L_BOSS_TRIGGER = cfg["boss_trigger"]
	L_NAME = cfg["name"]
	L_MSG_KEY = cfg["key"]
	if L_VERTICAL:
		cam_y = L_H - 240.0              # 纵向关相机从底部开始
		cam_x = 0.0

# ---------------- 玩家 ----------------
func _spawn_players() -> void:
	if L_VERTICAL:
		_spawn_player(Vector2(60, 1560 - 8), 1)
		if Boot.player_count >= 2:
			_spawn_player(Vector2(240, 1560 - 8), 2)
	else:
		_spawn_player(Vector2(40, L_GROUND_Y), 1)
		if Boot.player_count >= 2:
			_spawn_player(Vector2(70, L_GROUND_Y), 2)

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
	if L_VERTICAL:
		_build_terrain_vertical()
		return
	# 实心地段: 顶层草/雪 + 泥土/冻土到屏底; 缺口处画水面/冰水
	var theme: String = cfg["bg"]
	var top_key := "grass"
	var fill_key := "dirt"
	var w1 := "water1"
	var w2 := "water2"
	if theme == "snow":
		top_key = "snow"; fill_key = "rock"; w1 = "icewater1"; w2 = "icewater2"
	elif theme == "cave":
		top_key = "cave"; fill_key = "cave"; w1 = "water1"; w2 = "water2"
	for seg in L_GROUNDS:
		for x in range(seg.x, seg.y, TILE):
			_tile(TEX_TILES[top_key], x, L_GROUND_Y)
			for y in range(L_GROUND_Y + TILE, 240, TILE):
				_tile(TEX_TILES[fill_key], x, y)
	for i in range(L_GROUNDS.size() - 1):
		var a: int = L_GROUNDS[i].y
		var b: int = L_GROUNDS[i + 1].x
		for x in range(a, b, TILE):
			for y in range(L_GROUND_Y, 240, TILE):
				_tile(TEX_TILES[w1 if (x / TILE + y / TILE) % 2 == 0 else w2], x, y)
	# 静态碰撞体 (每段一个大矩形)
	for seg in L_GROUNDS:
		var body := StaticBody2D.new()
		body.collision_layer = GameData.L_WORLD
		var cs := CollisionShape2D.new()
		var sh := RectangleShape2D.new()
		var w: int = seg.y - seg.x
		sh.size = Vector2(w, 240 - L_GROUND_Y)
		cs.shape = sh
		cs.position = Vector2(seg.x + w / 2.0, L_GROUND_Y + sh.size.y / 2.0)
		body.add_child(cs)
		world_node.add_child(body)
	# 浮台(单向碰撞: 可从下方穿过跳上)
	for p in L_PLATFORMS:
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

## 纵向瀑布关: 底部水面 + 瀑布水柱装饰 + 之字浮台
func _build_terrain_vertical() -> void:
	# 底部水面 (坠落死区)
	for x in range(0, L_W, TILE):
		for y in range(int(L_H) - 96, int(L_H), TILE):
			_tile(TEX_TILES["water1" if (x / TILE + y / TILE) % 2 == 0 else "water2"], x, y)
	# 中央瀑布水柱 (装饰)
	for x in range(144, 176, TILE):
		for y in range(0, int(L_H) - 96, TILE):
			_tile(TEX_TILES["water1" if (x / TILE + y / TILE) % 2 == 0 else "water2"], x, y)
	for p in L_PLATFORMS:
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

## 关卡背景: 瀑布崖壁 / 雪原夜空 + 飘雪
func _build_background() -> void:
	var bg_root: ParallaxBackground = $Background
	if cfg["bg"] == "snow":
		bg_root.get_node("Sky/SkySprite").texture = preload("res://assets/sprites/bg_snow_sky.png")
		bg_root.get_node("FarLayer/FarSprite").texture = preload("res://assets/sprites/bg_snow_far.png")
		bg_root.get_node("NearLayer").visible = false
		_build_snow_particles()
		return
	if cfg["bg"] == "cave":
		bg_root.get_node("Sky/SkySprite").texture = preload("res://assets/sprites/bg_cave_sky.png")
		bg_root.get_node("FarLayer/FarSprite").texture = preload("res://assets/sprites/bg_cave.png")
		bg_root.get_node("NearLayer").visible = false
		return
	if not L_VERTICAL:
		return
	# 隐藏丛林层, 换瀑布崖壁 (纹理纵向重复)
	bg_root.get_node("Sky/SkySprite").texture = preload("res://assets/sprites/bg_falls_sky.png")
	bg_root.get_node("FarLayer").motion_scale = Vector2(0.0, 1.0)
	bg_root.get_node("FarLayer/FarSprite").texture = preload("res://assets/sprites/bg_waterfall.png")
	bg_root.get_node("FarLayer/FarSprite").region_enabled = true
	bg_root.get_node("FarLayer/FarSprite").region_rect = Rect2(0, 0, 320, L_H)
	bg_root.get_node("FarLayer/FarSprite").texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	bg_root.get_node("FarLayer/FarSprite").position = Vector2(160, L_H / 2.0)
	bg_root.get_node("FarLayer/FarSprite").centered = true
	bg_root.get_node("NearLayer").visible = false

## 飘雪粒子 (CanvasLayer 屏幕空间, 不随世界滚动)
func _build_snow_particles() -> void:
	var layer := CanvasLayer.new()
	layer.name = "SnowLayer"
	layer.layer = 5
	add_child(layer)
	var snow := CPUParticles2D.new()
	snow.name = "SnowParticles"
	snow.emitting = true
	snow.amount = 70
	snow.lifetime = 6.0
	snow.preprocess = 6.0
	snow.position = Vector2(160, -12)
	snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	snow.emission_rect_extents = Vector2(210, 6)
	snow.direction = Vector2(-0.22, 1.0)
	snow.spread = 8
	snow.gravity = Vector2(5, 12)
	snow.initial_velocity_min = 26.0
	snow.initial_velocity_max = 52.0
	snow.scale_amount_min = 0.6
	snow.scale_amount_max = 1.4
	snow.color = Color(1, 1, 1, 0.85)
	layer.add_child(snow)

func _tile(tex: Texture2D, x_px: int, y_px: int) -> void:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = Vector2(x_px, y_px)
	world_node.add_child(s)

# ---------------- 静态物体 ----------------
func _build_statics() -> void:
	# 吊桥 (仅丛林关)
	if cfg["bridge"].x >= 0:
		bridge = BRIDGE_SCENE.new()
		bridge.build(float(cfg["bridge"].x), float(L_GROUND_Y),
			(float(cfg["bridge"].y) - float(cfg["bridge"].x)) / GameData.BRIDGE_SEG)
		world_node.add_child(bridge)
	# 狙击手
	for s in cfg["snipers"]:
		var sn := EnemySniper.new()
		sn.position = Vector2(s.x, s.y)
		enemies_node.add_child(sn)
		_hook_score(sn)
	# 异形卵 (巢穴关)
	if cfg.has("pods"):
		for pv in cfg["pods"]:
			var pod: AlienPod = preload("res://scripts/alien_pod.gd").new()
			pod.position = Vector2(pv.x, pv.y)
			enemies_node.add_child(pod)
			_hook_score(pod)
	# 炮塔
	for t in cfg["turrets"]:
		var tu := EnemyTurret.new()
		tu.position = Vector2(t.x, t.y)
		enemies_node.add_child(tu)
		_hook_score(tu)
	# Boss
	if L_VERTICAL:
		# 瀑布顶要塞: 裸核心 (闸门由核心开合表现)
		_make_core(cfg["boss_pos"] + Vector2(48, 100), 30)   # 核心落进屏内, 站顶台直射可及
	else:
		boss_wall = StaticBody2D.new()
		boss_wall.set_script(preload("res://scripts/boss_wall.gd"))
		boss_wall.position = cfg["boss_pos"]
		world_node.add_child(boss_wall)
		boss_wall.build_shapes()
		# 核心嵌在墙底左角, 与站立平射弹道同高 (官方设计: Boss 弱点在平射带内)
		_make_core(Vector2(cfg["boss_pos"].x + 14, L_GROUND_Y - 18),
			int(cfg.get("boss_hp", 30)))
		if cfg.has("boss_tint"):
			boss_core.modulate = cfg["boss_tint"]   # 心脏配色
		boss_wall.attach_core(boss_core)

func _make_core(pos: Vector2, hp: int) -> BossCore:
	boss_core = BossCore.new()
	boss_core.position = pos
	boss_core.boss_destroyed.connect(_on_boss_core_destroyed)
	enemies_node.add_child(boss_core)
	# 入树后再设血量 (BossCore._ready 会按周目重置)
	boss_core.max_hp = hp
	boss_core.hp = hp
	_hook_score(boss_core)
	boss_core.set_open(false)
	return boss_core

func _on_boss_core_destroyed() -> void:
	var pos := boss_wall.position + Vector2(48, 24) if boss_wall != null else boss_core.position
	on_boss_destroyed(pos)

# ---------------- 玩家 ----------------
func player_in_bounds() -> bool:
	return not alive_players().is_empty()

# ---------------- 通用查询 ----------------
func has_floor(x: float, _y: float) -> bool:
	for seg in L_GROUNDS:
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
	for p in L_PLATFORMS:
		if x >= p.x and x <= p.x + p.z and y_near <= p.y + 8.0:
			best = minf(best, p.y)
	if best == INF and has_floor(x, y_near) and y_near <= L_GROUND_Y + 8.0:
		best = L_GROUND_Y
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

	# 相机: 横向跟随最靠前者只进不退; 纵向棘轮只上不下
	# (intro 期间相机照常跟随, 避免开场玩家先走、相机后追的"衔接不上")
	var alive := alive_players()
	if L_VERTICAL:
		var top_y := INF
		for p in alive:
			top_y = minf(top_y, p.position.y)
		var ty := clampf(top_y - 150.0, 0.0, L_H - 240.0)
		cam_y = minf(cam_y, ty)          # 只上不下棘轮 (爬得越高视野越上移)
		position = Vector2(0, -cam_y)
	else:
		var target := 0.0
		if not alive.is_empty():
			var lead_x := -INF
			for p in alive:
				lead_x = maxf(lead_x, p.position.x)
			target = clampf(lead_x - 120.0, 0.0, L_W - 320.0)
		cam_x = maxf(cam_x, target)
		position = Vector2(-cam_x, 0)

	# 开场 intro: 只暂停刷怪与 Boss 触发, 相机不冻结
	if _intro_t > 0.0:
		_intro_t -= delta
		return

	# 敌人波次 (难度影响刷新间隔)
	_spawn_t -= delta
	if _spawn_t <= 0.0 and not boss_active:
		_spawn_t = maxf(1.5, 2.7 - Boot.loop_count * 0.15) * GameData.diff_spawn()
		_spawn_wave()
	# 胶囊
	_capsule_t -= delta
	if _capsule_t <= 0.0 and not boss_active:
		_capsule_t = 11.0 + randf() * 5.0
		var cap := EnemyCapsule.new()
		enemies_node.add_child(cap)
		_hook_score(cap)

	# Boss 触发: 横向到达警戒线 / 纵向爬到要塞高度
	if not boss_active and not alive.is_empty():
		for p in alive:
			if (not L_VERTICAL and p.position.x >= boss_trigger_x) \
					or (L_VERTICAL and p.position.y <= boss_trigger_x):
				_start_boss()
				break

func _spawn_wave() -> void:
	if L_VERTICAL:
		_spawn_wave_vertical()
		return
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
		if not has_floor(sx, L_GROUND_Y):
			sx = cam_x + 340.0
		e.position = Vector2(sx, L_GROUND_Y - 40.0)
		enemies_node.add_child(e)
		_hook_score(e)

## 纵向关: 从视野上缘的平台刷出, 走落攻击
func _spawn_wave_vertical() -> void:
	var count := 1 + (randi() % 2)
	var cands: Array[Vector3i] = []
	for p in L_PLATFORMS:
		if p.y < cam_y + 40.0 and p.y > cam_y - 200.0 and p.y > 100.0:
			cands.append(p)
	if cands.is_empty():
		return
	for i in range(count):
		var plat: Vector3i = cands[randi() % cands.size()]
		var e := EnemyRunner.new()
		e.position = Vector2(plat.x + randf_range(8, plat.z - 8), plat.y - 20.0)
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
	# 不对称开合: 开门 3.6s 足够输出, 关门 2.2s 稍作喘息
	_gate_timer.wait_time = 3.6 if _gate_open else 2.2
	if _gate_open:
		if boss_wall != null:
			boss_wall.open_gate()
		hud.call("flash_message", "core_open", 1.0)
	else:
		if boss_wall != null:
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
	Boot.submit_score(Boot.score)
	Boot.stop_music()
	Boot.play_sfx("sfx_clear")
	hud.call("flash_message", "clear", 3.0)
	# 关卡推进: 1→2→3→4→结局→循环回1并提升周目
	var t := get_tree().create_timer(3.2)
	t.timeout.connect(func():
		if Boot.level >= 4:
			Boot.start_lives = 3
			get_tree().change_scene_to_file("res://scenes/ending.tscn")
			return
		Boot.level += 1
		get_tree().reload_current_scene())

func _game_over() -> void:
	Boot.submit_score(Boot.score)
	hud.call("flash_message", "gameover", 4.0)
	var t := get_tree().create_timer(3.5)
	t.timeout.connect(func():
		Boot.loop_count = 1
		get_tree().change_scene_to_file("res://scenes/title.tscn"))

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
