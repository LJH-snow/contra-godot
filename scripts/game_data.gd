class_name GameData
## 全局常量: 物理层 / 武器 / 关卡布局 / 帧索引

# 物理碰撞层 (位掩码值)
const L_WORLD := 1        # 实实地形
const L_PLATFORM := 2     # 单向浮台
const L_PLAYER := 4
const L_ENEMY := 8
const L_PBULLET := 16
const L_EBULLET := 32
const L_ITEM := 64

# 武器编号 (胶囊字母)
enum W { NORMAL, M, S, L, F, R, B, EAGLE }

const WEAPON_LABEL := {
	W.NORMAL: "R", W.M: "M", W.S: "S", W.L: "L", W.F: "F", W.R: "R+", W.B: "B", W.EAGLE: "★",
}
const WEAPON_NAME := {
	W.NORMAL: "步枪", W.M: "机枪", W.S: "散弹枪", W.L: "雷射枪",
	W.F: "火球枪", W.R: "速射", W.B: "护盾", W.EAGLE: "金鹰",
}

# 分值
const SCORE_RUNNER := 100
const SCORE_SNIPER := 300
const SCORE_TURRET := 500
const SCORE_CAPSULE := 500
const SCORE_BOSS := 5000

# 关卡几何 (视口 320x240, 地面顶 y=200, 图块 16px)
const LEVEL_W := 3488
const GROUND_Y := 200
const FALL_LINE := 252.0

# 实心地段 [起点x, 终点x]
static var GROUNDS: Array[Vector2i] = [
	Vector2i(0, 560), Vector2i(656, 1184), Vector2i(1280, 1504),
	Vector2i(1664, 2176), Vector2i(2288, 2976), Vector2i(2976, 3488),
]
# 吊桥 (会随玩家通过逐段爆炸)
static var BRIDGE := Vector2i(1504, 1664)
const BRIDGE_SEG := 16

# 浮台 (左端x, 顶面y, 宽) — 两层: 144 与 116, 满跳(≈88px)均可从地面直接登顶
static var PLATFORMS: Array[Vector3i] = [
	Vector3i(368, 144, 64), Vector3i(480, 116, 48),
	Vector3i(720, 144, 64), Vector3i(832, 116, 64), Vector3i(944, 144, 48),
	Vector3i(1320, 144, 80),
	Vector3i(1740, 116, 64), Vector3i(1856, 144, 64), Vector3i(1968, 116, 48),
	Vector3i(2400, 144, 64), Vector3i(2512, 116, 64), Vector3i(2624, 144, 48),
	Vector3i(2760, 116, 80), Vector3i(2960, 144, 48),
]

# 固定狙击手 (x, 脚底y)
static var SNIPERS: Array[Vector2i] = [
	Vector2i(420, 200), Vector2i(1096, 200), Vector2i(1370, 200),
	Vector2i(2064, 200), Vector2i(2544, 116), Vector2i(2700, 144),
	Vector2i(2920, 200), Vector2i(3120, 200),
]
# 固定炮塔 (x, 所在地面y)
static var TURRETS: Array[Vector2i] = [
	Vector2i(928, 200), Vector2i(2080, 200), Vector2i(2384, 200),
	Vector2i(3088, 200), Vector2i(3232, 200),
]

# Boss
const BOSS_X := 3392
const BOSS_TRIGGER := 3088

# 难度循环加成
static func fire_scale(loop: int) -> float:
	return 1.0 + (loop - 1) * 0.12

static func speed_scale(loop: int) -> float:
	return 1.0 + (loop - 1) * 0.08
