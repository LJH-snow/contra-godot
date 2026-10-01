# Fierce Soldier 素材包（魂斗罗风格替换候选）

来源: [Fierce Soldier sprites — OpenGameArt](https://opengameart.org/content/fierce-soldier-sprites)
作者: Vircon32 (Carra) · 授权: **CC-BY 4.0**（可自由商用/修改，**必须署名**——见根目录 `CREDITS.md`）

- `originals/` 原始 PNG（640×360 设计分辨率，RGBA 带透明通道）
- `hero_half.png` / `foe_half.png` / `scn_half.png`：**50% 缩小版**（BOX 滤镜，2x2 胖像素无损塌缩），
  尺寸匹配本项目 320×240 视口：主角帧 ≈ 23×30（现有碰撞盒 12×26，无需改物理）
- `compare.png`：与现有程序化素材的对比图

## 为什么选它
金发赤膊主角 + 绿军装敌兵 + 棕榈丛林 + 要塞墙 Boss —— 魂斗罗第一关的完整配方；
是本次调研中风格匹配度最高的免费授权素材（其余候选见文末）。

## 帧内容清单（接入时按此切图）

**主角 (originals/…main_character.png, 391×265)**：
- 行1: 站立/走射 ×6 + 卧倒射击 ×2
- 行2: 跑动横射 ×5 + 空中翻滚(团身) ×1
- 行3: 跑射变体 ×5 + 双子弹贴图(蓝/黄) + 胜利姿势 ×1
- ⚠️ jam 作品，帧间距不规则，需逐帧裁切（不能按均匀网格切）
- ⚠️ **没有朝上/斜上瞄准帧**（魂斗罗核心动作）——需要自制（可基于站立帧改）或保留现逻辑

**敌人&Boss (…enemies_and_bosses.png, 453×247)**：
- 绿色敌兵 ×2 帧 → 杂兵 Runner（NES 原作也是 2 帧跑步）
- 灰色炮座 + 炮管 → 炮塔 Turret
- 红色加特林圆盘 ×2 → 可做第二炮塔或狙击手
- 蓝色圆形核心 ×2 → **BossCore 替换**
- 红色/蓝色要塞墙 ×2 + 履带墙 → **Boss 墙替换**（尺寸≈130×150，需缩放到 96×200）
- 火箭 ×2 → 飞行胶囊替身或新敌

**场景&GUI (…scenery_and_gui.png, 318×170)**：
- 棕榈树 ×2、灌木、草丛 → 背景装饰层（提升丛林感的最大功臣）
- 金发头像框 → 生命图标 / HUD
- 白色导弹 ×4 → 子弹贴图备选

## 缺口（保留现有程序化素材或另补）
水/吊桥图块、道具箱、爆炸特效、标题 Logo、文案图。
爆炸与子弹可搭配 Master484 的免费包（同为 CC-BY）:
[bullet collection](https://opengameart.org/content/bullet-collection) ·
[explosion pack](https://opengameart.org/content/explosion-animations)

## 接入方式建议
1. 用 Pillow 脚本逐帧裁切 → 重排成 player.gd 现有的 6×6 网格（帧索引见 player.gd 头部注释），
   scripts/ 与 assets/ 一行不用改，零代码侵入。
2. 或保持不规则 sheet + 在 Godot 里用 `Region`/`AnimatedSprite2D`（改动大，不推荐）。
3. ⚠️ 主线窗口正在活跃开发 scripts/，接入请与其协调后再动 `player.gd` 的帧索引。

## 其他候选（本次调研核实过的免费素材）
| 素材 | 来源 | 授权 | 备注 |
|---|---|---|---|
| [Open Gunner Starter Kit](https://opengameart.org/content/open-gunner-starter-kit) | OGA | CC-BY 3.0 | 洛克人X/Turrican 科幻风，120+帧主角+敌人+图块+UI，缺子弹/爆炸 |
| [Reploit Pack 1](https://itch.io/game-assets/free/tag-run-and-gun) | itch.io | 见页面 | 16×16 洛克人X风，偏科幻 |
| [Generic RUN n' GUN pack](https://itch.io/game-assets/free/tag-run-and-gun) | itch.io | 见页面 | 通用跑打底材 |
