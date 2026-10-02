class_name Player extends CharacterBody2D
## 玩家: 八方向射击 / 跳跃翻滚 / 卧倒 / 一触即死 / 武器系统

signal died
signal weapon_changed(w: int)

const SHEET_P1 := preload("res://assets/sprites/player.png")
const SHEET_P2 := preload("res://assets/sprites/player2.png")
const INVINCIBLE_TIME := 2.0
const SHIELD_TIME := 12.0

# 姿态
enum P { RUN_AIM, RUN_UP, TUMBLE, PRONE, DEAD_FLY, DEAD_GROUND }

var pnum := 1
var respawn_t := 0.0
var weapon := GameData.W.NORMAL
var rapid := false
var lives := 3
var facing := 1
var prone := false
var on_ground := false
var dead := false
var ctrl := true

# 无敌: B道具护盾 / 复活保护
var shield_t := 0.0
var invuln_t := 0.0

# 射击
var _fire_cd := 0.0
var _fire_hold := false
var _laser_block := false

# 动画
var _anim_t := 0.0
var _tumble_a := 0.0
var _muzzle_t := 0.0

var _sprite: Sprite2D
var _muzzle: Sprite2D
var _ring: Sprite2D
var _hurtbox: Area2D

func _ready() -> void:
	add_to_group("player")
	collision_layer = GameData.L_PLAYER
	collision_mask = GameData.L_WORLD | GameData.L_PLATFORM
	_sprite = Sprite2D.new()
	_sprite.texture = SHEET_P1 if pnum == 1 else SHEET_P2
	_sprite.hframes = 6
	_sprite.vframes = 6
	add_child(_sprite)
	_muzzle = Sprite2D.new()
	_muzzle.texture = preload("res://assets/sprites/fx.png")
	_muzzle.hframes = 6
	_muzzle.vframes = 3
	_muzzle.frame = 6
	_muzzle.visible = false
	add_child(_muzzle)
	_ring = Sprite2D.new()                     # B 护盾光环
	_ring.texture = preload("res://assets/sprites/items.png")
	_ring.hframes = 8
	_ring.frame = 7
	_ring.scale = Vector2(1.6, 1.6)
	_ring.visible = false
	add_child(_ring)
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(12, 26)
	cs.shape = sh
	cs.position = Vector2(0, -13)
	add_child(cs)
	# 受击判定: 敌方子弹 / 敌人身体接触 (每帧轮询, 出生重叠也能命中)
	_hurtbox = Area2D.new()
	_hurtbox.collision_layer = 0
	_hurtbox.collision_mask = GameData.L_EBULLET | GameData.L_ENEMY
	var hcs := CollisionShape2D.new()
	var hsh := RectangleShape2D.new()
	hsh.size = Vector2(10, 24)
	hcs.shape = hsh
	hcs.position = Vector2(0, -13)
	_hurtbox.add_child(hcs)
	add_child(_hurtbox)
	lives = Boot.start_lives
	weapon_changed.emit(weapon)


# ---------------- 输入 (按玩家编号区分键位) ----------------
func _act(name: String) -> String:
	return ("p1_" if pnum == 1 else "p2_") + name

func _axis_x() -> float:
	return Input.get_axis(_act("left"), _act("right"))

# ---------------- 主循环 ----------------
func _physics_process(delta: float) -> void:
	if dead:
		_physics_dead(delta)
		return
	shield_t = maxf(0.0, shield_t - delta)
	invuln_t = maxf(0.0, invuln_t - delta)
	_ring.visible = shield_t > 0.0
	if _ring.visible:
		_ring.rotation += delta * 6.0
		_ring.modulate.a = 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.02)
	if invuln_t > 0.0:
		_sprite.visible = int(Time.get_ticks_msec() * 0.02) % 2 == 0
	else:
		_sprite.visible = true

	var g := get_tree().get_first_node_in_group("game")

	# 重力
	velocity.y = minf(velocity.y + 860.0 * delta, 460.0)

	# 水平移动
	var ax := _axis_x()
	if not ctrl:
		ax = 0.0
	prone = on_ground and Input.is_action_pressed(_act("down")) and ctrl
	if prone:
		velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
	else:
		var top := 132.0
		velocity.x = move_toward(velocity.x, ax * top, 1900.0 * delta)
		if ax != 0.0:
			facing = 1 if ax > 0.0 else -1

	# 跳跃 (可变高度, 满跳约 88px: 可从地面直接跳上两层浮台)
	if ctrl and Input.is_action_just_pressed(_act("jump")) and on_ground:
		velocity.y = -390.0
		on_ground = false
		Boot.play_sfx("sfx_jump", -6.0)
	if velocity.y < 0.0 and not Input.is_action_pressed(_act("jump")):
		velocity.y += 950.0 * delta

	# 翻滚动画计时
	if not on_ground:
		_tumble_a += delta * 10.5

	# 射击
	if ctrl and Input.is_action_pressed(_act("shoot")):
		_try_shoot(g)
	else:
		_laser_block = false
	_fire_cd -= delta
	_muzzle_t -= delta
	if _muzzle_t <= 0.0:
		_muzzle.visible = false

	move_and_slide()
	_update_ground(g)
	_animate(delta)
	_poll_hurt()

	# 落水/落坑死亡 (坠落线由关卡配置提供)
	if g != null and position.y > g.L_FALL_LINE:
		die(true)
	elif g == null and position.y > GameData.FALL_LINE:
		die(true)

func _poll_hurt() -> void:
	for b in _hurtbox.get_overlapping_bodies():
		hurt(b)
	for a in _hurtbox.get_overlapping_areas():
		hurt(a)

func _update_ground(_g: Node) -> void:
	on_ground = is_on_floor()

# ---------------- 射击 ----------------
func aim_dir() -> Vector2:
	var up := Input.is_action_pressed(_act("up"))
	var down := Input.is_action_pressed(_act("down"))
	if on_ground and down and absf(velocity.x) < 5.0:
		return Vector2.ZERO                    # 卧倒单独处理
	if up and down:
		return Vector2.ZERO
	if up:
		var d := Vector2(facing, -1).normalized() if absf(velocity.x) > 5.0 or _axis_x() != 0.0 else Vector2(0, -1)
		return d
	if on_ground and down:
		return Vector2(facing, 0)
	return Vector2(facing, 0)

func muzzle_pos(d: Vector2) -> Vector2:
	if prone:
		return position + Vector2(facing * 15.0, -5.0)
	return position + Vector2(0, -15) + d * 12.0

func _try_shoot(g: Node) -> void:
	if _fire_cd > 0.0:
		return
	if g == null or position.x < g.cam_x - 10.0:   # 不在屏幕内不能开火
		return
	var d := aim_dir()
	var pos: Vector2
	if d == Vector2.ZERO:                      # 卧倒
		d = Vector2(facing, 0)
		pos = muzzle_pos(d)
	else:
		pos = muzzle_pos(d)
	# 雷射: 按住不重复
	if weapon == GameData.W.L and _laser_block:
		return
	_fire_cd = fire_interval()
	if weapon == GameData.W.L:
		_laser_block = true
	if weapon == GameData.W.S:                     # 散弹: 一次5发扇形
		shoot_spread(g)
	else:
		var b := Bullet.new()
		b.setup(pos, d, weapon)
		g.bullets_node.add_child(b)
	# 枪口焰
	_muzzle.position = (pos - position).rotated(-rotation)
	_muzzle.rotation = d.angle() + PI / 2.0
	_muzzle.visible = true
	_muzzle_t = 0.05
	Boot.play_sfx(shoot_sfx(), -4.0)

func fire_interval() -> float:
	var base := 0.24
	match weapon:
		GameData.W.M: base = 0.13
		GameData.W.S: base = 0.42
		GameData.W.L: base = 0.4
		GameData.W.F: base = 0.3
		_: base = 0.24
	if rapid:
		base *= 0.55
	return base

func shoot_sfx() -> String:
	match weapon:
		GameData.W.M: return "sfx_shoot"
		GameData.W.S: return "sfx_spread"
		GameData.W.L: return "sfx_laser"
		GameData.W.F: return "sfx_fire"
		_: return "sfx_shoot"

# 散弹枪: 一次 5 发 (由 game 调用重载)
func shoot_spread(g: Node) -> void:
	var d := aim_dir()
	if d == Vector2.ZERO:
		d = Vector2(facing, 0)
	var base_a := d.angle()
	for off in [-0.42, -0.21, 0.0, 0.21, 0.42]:
		var b := Bullet.new()
		b.setup(muzzle_pos(d), Vector2.RIGHT.rotated(base_a + off), GameData.W.S)
		g.bullets_node.add_child(b)

# ---------------- 受击 / 死亡 ----------------
func hurt(_what: Node = null) -> void:
	if dead:
		return
	if shield_t > 0.0:
		if _what is Enemy and is_instance_valid(_what):
			(_what as Enemy).kill()
		elif _what is EBullet and is_instance_valid(_what):
			(_what as EBullet).queue_free()
		return
	if invuln_t > 0.0:
		return
	die(false)

func die(fell: bool) -> void:
	if dead:
		return
	dead = true
	shield_t = 0.0
	invuln_t = 0.0
	_ring.visible = false
	velocity = Vector2(facing * -55.0, -260.0)   # 经典向后飞出
	collision_layer = 0
	collision_mask = GameData.L_WORLD
	Boot.play_sfx("sfx_death")
	weapon = GameData.W.NORMAL                   # 死亡武器清空
	rapid = false
	weapon_changed.emit(weapon)
	lives -= 1
	died.emit()
	if fell:
		visible = false
		set_physics_process(false)

func _physics_dead(delta: float) -> void:
	velocity.y = minf(velocity.y + 900.0 * delta, 460.0)
	position += velocity * delta
	_sprite.visible = true
	_sprite.frame = 25                          # 死亡飞出姿态
	_sprite.flip_h = facing < 0
	if position.y > GameData.FALL_LINE + 40.0:
		set_physics_process(false)

func respawn(at: Vector2) -> void:
	dead = false
	visible = true
	set_physics_process(true)
	position = at
	velocity = Vector2.ZERO
	invuln_t = INVINCIBLE_TIME
	_sprite.visible = true
	on_ground = false
	ctrl = true
	collision_layer = GameData.L_PLAYER
	collision_mask = GameData.L_WORLD | GameData.L_PLATFORM
	_tumble_a = 0.0

# ---------------- 道具 ----------------
func pickup(w: int) -> void:
	match w:
		GameData.W.R:
			rapid = true
		GameData.W.B:
			shield_t = SHIELD_TIME
		GameData.W.EAGLE:
			var g := get_tree().get_first_node_in_group("game")
			if g != null:
				g.eagle_wipe()
		_:
			weapon = w
			rapid = false
	weapon_changed.emit(weapon)

# ---------------- 动画 ----------------
func _animate(_delta: float) -> void:
	_sprite.flip_h = facing < 0
	_sprite.offset = Vector2.ZERO
	if prone:
		_sprite.frame = 24
		_sprite.offset = Vector2(0, 5)
		return
	if not on_ground:
		_sprite.frame = 18 + (int(_tumble_a) % 4)   # 空中翻滚
		return
	# 站立瞄准方向: 水平0 斜上1 竖上2
	var up := Input.is_action_pressed(_act("up"))
	var ax := _axis_x()
	if up and ax == 0.0:
		_sprite.frame = 2
	elif up:
		_sprite.frame = 1
	elif absf(velocity.x) > 5.0:
		_anim_t += _delta
		# 跑动横射 行1 / 跑动斜上 行2 (仅按住上时)
		var row := 2 if up else 1
		_sprite.frame = row * 6 + int(_anim_t * 11.0) % 6
	else:
		_sprite.frame = 0
