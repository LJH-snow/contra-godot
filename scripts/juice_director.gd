extends Node
## 手感导演(自治节点, 由 Boot 挂载): 手柄震动反馈 + 死亡慢动作
## 玩家死亡 → 中震 + 慢动作 / Boss警告 → 短促双震 / 击破过关 → 长震 + 慢动作
## 只读状态轮询, 零侵入主场景; 无手柄时震动静默

var _dead_state := {}                # 玩家实例id -> 上帧是否死亡
var _boss_was := false
var _done_was := false
var _slowmo_until_ms := 0

func _process(_delta: float) -> void:
	var game := get_tree().get_first_node_in_group("game")
	# 慢动作到时恢复 (按真实时间计时, 不受 time_scale 影响)
	if Engine.time_scale < 1.0:
		if game == null or get_tree().paused or Time.get_ticks_msec() >= _slowmo_until_ms:
			Engine.time_scale = 1.0
	if game == null:
		_dead_state.clear()
		return
	# 玩家死亡 → 震动 + 慢动作
	for p in get_tree().get_nodes_in_group("player"):
		if p.dead and p.invuln_t <= 0.0:    # 死亡(非复活闪烁)
			var id: int = p.get_instance_id()
			if not _dead_state.get(id, false):
				vibrate_all(0.75, 0.35, 0.4)
				hit_stop(0.35, 400)
			_dead_state[id] = true
		else:
			_dead_state[p.get_instance_id()] = false
	# Boss 警告 → 短促双震
	if game.boss_active and not _boss_was:
		vibrate_all(0.5, 0.5, 0.12)
		var t := get_tree().create_timer(0.2)
		t.timeout.connect(func(): vibrate_all(0.5, 0.5, 0.12))
	_boss_was = game.boss_active
	# 击破过关 → 长震 + 慢动作
	if game.level_done and not _done_was:
		vibrate_all(1.0, 1.0, 0.8)
		hit_stop(0.45, 650)
	_done_was = game.level_done

## 慢动作: time_scale 降速 scale 毫秒级时长(真实时间)后自动恢复
func hit_stop(scale: float, real_ms: int) -> void:
	Engine.time_scale = scale
	_slowmo_until_ms = Time.get_ticks_msec() + real_ms

func vibrate_all(strong: float, weak: float, dur: float) -> void:
	for dev in Input.get_connected_joypads():
		Input.start_joy_vibration(dev, strong, weak, dur)
