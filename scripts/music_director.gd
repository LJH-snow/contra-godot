extends Node
## Boss 音乐导演(自治节点, 由 Boot 挂载): 监听关卡 Boss 状态自动切换 BGM
## 零侵入: 只读 game.boss_active / level_done, 不修改主场景任何代码

var _boss_music_on := false
var _gameover_on := false

func _process(_delta: float) -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game == null:
		return
	# Game Over 检测: 全员阵亡且无剩余生命
	var players := get_tree().get_nodes_in_group("player")
	var all_out := players.size() > 0
	for p in players:
		if not p.dead or p.lives > 0:
			all_out = false
	if all_out and not game.level_done and not _gameover_on:
		_gameover_on = true
		_boss_music_on = false
		Boot.play_music("music_gameover", -5.0)
		return
	if _gameover_on:
		if not all_out:
			_gameover_on = false
			Boot.play_music("music_stage")   # 复活/重开 → 回关卡音乐
		return
	var boss_active: bool = game.boss_active
	var level_done: bool = game.level_done
	if boss_active and not level_done and not _boss_music_on:
		_boss_music_on = true
		Boot.play_music("music_boss", -7.0)
	elif not boss_active and _boss_music_on and not level_done:
		# 周目重开等场景恢复: 切回关卡音乐
		_boss_music_on = false
		Boot.play_music("music_stage")
