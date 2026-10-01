# 魂斗罗 CONTRA (Godot 4.7)

**简体中文** | [English](README_EN.md)

用 Godot 4.7 复刻的经典横版卷轴射击游戏。全部像素美术与 8-bit 音频均由
`tools/` 下的 Python 脚本程序化生成，无外部素材依赖。

## 运行

用 Godot 4.7+ 打开本目录（Steam 版 Godot 直接「添加新游戏」选择此文件夹），
或命令行：

```bash
# Steam 版示例路径
"$HOME/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" --path .
```

## 操作（双手布局：左手移动，右手攻击）

| 按键 | 动作 |
|------|------|
| A D（左手） | 左右移动 |
| W / S（左手） | 瞄准上方 / 卧倒（按住 S） |
| J（右手） | 射击（八方向：W/A/S 配合指向） |
| K 或 空格（右手） | 跳跃（长按跳更高，满跳可从地面直接跳上两层浮台） |
| W/S（标题画面） | 选择 单人/双人 模式 |
| Enter 或 J | 开始游戏 |
| M | 静音 |

备选方案：方向键移动 + Z 跳跃 + X 射击（经典 FC 布局，两套同时有效）。

**双人模式**：标题画面选 `2 PLAYERS`。P1 红头带（WASD+J/K），P2 蓝头带
（方向键+Z/X 或数字键盘旁的 `,`/`.` 未启用——当前 P2 与 P1 共用键位布局，
建议一人键盘一人手柄）。各自独立生命/武器，镜头跟随领先者，落后者被
屏幕左缘推回，全员阵亡才算 Game Over。

**科乐美秘技**：标题画面输入 `上上下下左右左右BA` → 初始 30 条命。

## 玩法（对应原作机制）

- **八方向射击**：站立横射、斜上、竖直向上；奔跑中可朝斜上开火；卧倒贴地射击
- **一触即死**：碰到敌人或敌方子弹即死亡，尸体向后飞出，死亡后武器清空
- **武器系统**（击落红色飞行胶囊掉落鹰徽箱）：
  - `M` 机枪：按住连发
  - `S` 散弹枪：一次 5 发扇形
  - `L` 雷射枪：穿透，按住单发
  - `F` 火球枪：螺旋弹道
  - `R` 速射：射速提升，可叠加
  - `B` 护盾：12 秒无敌，触碰秒杀敌人
  - `★` 金鹰：瞬间清空全屏敌人
- **关卡**：丛林地形 + 浮台 + 会逐段爆炸的吊桥 + 缺口水面（坠落即死）
- **关底 Boss**：基地墙内的红色核心，闸门周期开合，开门时输出窗口，血条 30+，
  击破后连环爆炸 → 任务完成 → 难度提升进入下一周目（枪速/弹速递增）
- **镜头规则**：只前进不后退（经典规则）

## 项目结构

```
project.godot          工程配置 (320x240 像素视口, 3x 窗口)
scenes/                main.tscn(关卡) / title.tscn(标题)
scripts/
  boot.gd              自动加载: 输入注册 / 音频池 / 全局状态
  game_data.gd         常量: 碰撞层 / 武器表 / 关卡几何
  game.gd              主场景: 地形构建 / 敌人生成 / 镜头 / Boss 战
  player.gd            玩家: 移动跳跃射击 / 姿态动画 / 受击复活
  enemy*.gd            跑兵 / 狙击手 / 炮塔 / 飞行胶囊
  boss_core.gd         Boss 核心 (开合闸门 / 三向弹幕)
  boss_wall.gd         Boss 墙体 + 金属闸门
  bridge.gd            逐段爆炸吊桥
  item_box.gd          武器道具箱
  bullet.gd / ebullet.gd / fx.gd   子弹与特效
  hud.gd / title.gd    HUD 与标题
assets/
  sprites/             程序化生成的 PNG 精灵
  audio/               程序化合成的 8-bit WAV (音效16 + 音乐2)
  text/                预渲染中文文案 (PingFang)
tools/
  gen_sprites.py       像素美术生成器 (Pillow)
  gen_audio.py         音频合成器 (纯正弦/方波/噪声合成)
  gen_text.py          中文文案渲染
  test_runner.gd       无头自动化测试 (16 项玩法断言)
  screenshot_tour.gd   截图巡游
```

## 测试

```bash
GODOT="--path后缀" # Steam 版 Godot 可执行文件
"$GODOT" --headless res://tools/test_main.tscn   # 16 项断言, 0 失败退出码 0
```

覆盖: 地形构建 / 射击击杀 / 武器拾取 / 护盾秒杀 / 受击死亡扣命 /
自动复活与保护 / 吊桥爆炸 / Boss 触发与闸门 / 击破过关。
