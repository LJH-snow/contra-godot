# QA 审查报告（并行窗口产出）

> 审查基线：git `1a167dd`（20:57 左右的 scripts 版本）。
> 本报告**只读产出**，未修改 `scripts/` 任何文件——另一窗口正在活跃开发（game.gd 21:05 仍在变），行号可能略有漂移，补丁按内容定位即可。

---

## P0 — 建议尽快修

### 1. 分数永远是 0000000
- **现象**：HUD 读取 `Boot.score`（hud.gd:124），但全项目没有任何地方对 `Boot.score` 做累加；敌人基类的 `signal died(score)`（enemy.gd:4）在 kill 时发出，**没有任何接收方**。炮塔/胶囊/Boss 的 kill() 也一样。
- **补丁**（enemy.gd `_init`，一行覆盖所有子类，含未来新增敌人）：
  ```gdscript
  func _init() -> void:
      collision_layer = GameData.L_ENEMY
      collision_mask = GameData.L_WORLD | GameData.L_PLATFORM
      died.connect(func(s: int): Boot.score += s)   # ← 新增
  ```
- **注意**：标题画面开始新游戏时建议顺带 `Boot.score = 0`（title.gd `_start()`），否则 30 命秘技重开后带着旧分。

### 2. 散弹枪（S）实际只打 1 发
- **现象**：`player.shoot_spread(g)`（player.gd:229，一次 5 发）写好了但**从未被调用**；`_try_shoot` 对所有武器统一生成单颗 Bullet。
- **补丁**（player.gd `_try_shoot`，替换发射段）：
  ```gdscript
  _fire_cd = fire_interval()
  if weapon == GameData.W.L:
      _laser_block = true
  if weapon == GameData.W.S:          # ← 散弹走 5 发
      shoot_spread(g)
  else:
      var b := Bullet.new()
      b.setup(pos, d, weapon)
      g.bullets_node.add_child(b)
  ```
  枪口焰与音效代码保持在其后即可（`shoot_sfx()` 对 S 已返回 `sfx_spread`）。

## P1 — 影响体验

### 3. 复活一次后就站不上浮台了
- **现象**：`respawn()`（player.gd:293）把 `collision_mask` 设回 `L_WORLD`，丢了 `L_PLATFORM`；初始 `_ready` 是两者。第一次复活后玩家会穿过所有浮台。
- **补丁**：`collision_mask = GameData.L_WORLD | GameData.L_PLATFORM`

### 4. Boss 爆炸整段跑两遍
- **现象**：`BossCore.kill()` 既 `boss_destroyed.emit()`（game.gd 已连接 → 调 `on_boss_destroyed`），又**直接**调 `g.on_boss_destroyed(position)`（boss_core.gd kill 末尾）。结果：连环爆炸×2、大爆炸音效×2、两个 1.8s 定时器（`_mission_complete` 有 `level_done` 保护所以不会二周目×2，但定时器泄漏）。
- **补丁**（二选一，推荐前者）：删除 `boss_core.gd` `kill()` 里的直接调用 `g.on_boss_destroyed(position)` 三行，只留信号。

## P2 — 边角情况 / 维护性

### 5. 复活点可能悬在水面正上方 → 连死循环
- `_respawn_player()`（game.gd:164-173）先试 `cam_x+30` 再试 `+60`，都无地面时 fallback `fy = GROUND_Y` 直接把玩家放在坑上方 → 落水即死，若相机附近都是坑会连续扣命。
- 建议：扫描偏移序列 `[30, 60, 90, -30, -60]`，全部无地面才放弃；或往回找最近已通过的安全段。

### 6. 道具箱无视浮台
- `floor_y_at` 只查 GROUNDS 与吊桥，道具箱会穿浮台落到地面。像素魂斗罗原作道具会停在平台上。若要修：`floor_y_at` 里遍历 `GameData.PLATFORMS` 取 `p.y`（要求 x 在台面范围内且 y_near 从上方接近）。

### 7. 武器字母表双份易漂移
- `hud.gd` 的 `WEAPON_LABEL` 与 `GameData.WEAPON_LABEL` 内容相同。HUD 里 `set_weapon` 建议改为引用 `GameData.WEAPON_LABEL`，单一事实来源。

### 8. 玩家子弹穿透 Boss 墙（视觉违和）
- `Bullet` mask 只有 `L_ENEMY`，Boss 墙是 `L_WORLD`：关门时子弹直接穿墙飞过去（核心只是响 clang）。建议 Bullet 对 `L_WORLD` 也注册碰撞→消失（已核对：地形/吊桥碰撞体都在 y≥200，常规射击枪口 y≈178~195，不会误挡；仅卧倒 y≈195 贴地射时注意墙根碰撞从 200 起，仍安全）。

## P3 — 小瑕疵（可不修）

- Boss 门 Toggle Timer 在 `level_done` 后仍空转到场景重载（有早退保护，仅节点泄漏）。
- `_spawn_wave()` 反侧出兵在 `cam_x-20`，大部分立即被 `cam_x-100` 剔除逻辑回收，浪费生成。
- hud.gd:121 `maxf(0, p.lives)` 返回 float 赋给 int 变量（编辑器会有警告）。
- player.gd `_animate()` 里 `row` 计算了三次，前两次是死代码。
- gen_sprites.py / gen_audio.py 使用非密码学随机数（Mimosa low 级提示，工具脚本无风险）。

---

## 已核对无问题的部分
出生保护与无敌闪烁、落水/落坑判定、吊桥逐段爆炸与碰撞禁用、Konami 秘技输入状态机、音频池轮转与 WAV 循环点、敌人出屏/落水剔除、Boss 血条与闸门开闭节奏、`_mission_complete` 防重入。

## 验证方式（供另一窗口跑回归）
```bash
# 无头自动化测试（通过 exit 0）：
"/Users/Admin/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" \
  --headless --path . res://tools/test_main.tscn

# 截图巡检（产出 tools/shots/*.png）：
... Godot --path . res://tools/shot_main.tscn
```
