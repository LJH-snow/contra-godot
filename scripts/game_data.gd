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

# 难度循环加成 + 难度选择 (0=EASY 1=NORMAL 2=HARD)
static func fire_scale(loop: int) -> float:
	return (1.0 + (loop - 1) * 0.12) * diff_fire()

static func speed_scale(loop: int) -> float:
	return (1.0 + (loop - 1) * 0.08) * diff_speed()

static func diff_index() -> int:
	return Boot.difficulty if Boot != null else 1

static func diff_fire() -> float:
	return [0.7, 0.85, 1.2][clampi(diff_index(), 0, 2)]

static func diff_speed() -> float:
	return [0.8, 0.9, 1.1][clampi(diff_index(), 0, 2)]

static func diff_spawn() -> float:
	return [1.45, 1.15, 0.85][clampi(diff_index(), 0, 2)]   # 刷新间隔倍率(越难越快)

static func diff_lives() -> int:
	return [6, 4, 3][clampi(diff_index(), 0, 2)]

# ---------------- 关卡配置 ----------------
## 异形巢穴: 洞穴横向, 卵巢孵化小兵, 终点心脏 Boss
static func _level_lair() -> Dictionary:
	var pods: Array[Vector2i] = [
		Vector2i(560, 184), Vector2i(900, 184), Vector2i(1240, 116),
		Vector2i(1700, 184), Vector2i(2050, 116), Vector2i(2450, 184),
		Vector2i(2800, 116), Vector2i(3100, 184),
	]
	var snip: Array[Vector2i] = [
		Vector2i(760, 200), Vector2i(1450, 200), Vector2i(1980, 200),
		Vector2i(2620, 200), Vector2i(3050, 200),
	]
	var turb: Array[Vector2i] = [
		Vector2i(1100, 200), Vector2i(2200, 200), Vector2i(3200, 200),
	]
	var blos: Array[Vector2i] = [
		Vector2i(1490, 200), Vector2i(2320, 200), Vector2i(2800, 116),
	]
	return {
		"name": "FINAL  巢穴",
		"key": "mission4",
		"vertical": false,
		"w": 3488, "h": 240,
		"grounds": [
			Vector2i(0, 756), Vector2i(820, 1496), Vector2i(1560, 2336),
			Vector2i(2400, 3488),
		],
		"bridge": Vector2i(-1, -1),
		"platforms": [
			Vector3i(340, 144, 64), Vector3i(470, 116, 48),
			Vector3i(1160, 144, 64), Vector3i(1290, 116, 48),
			Vector3i(1950, 144, 64), Vector3i(2080, 116, 48),
			Vector3i(2600, 144, 64),
		],
		"snipers": snip,
		"turrets": turb,
		"pods": pods,
		"blossoms": blos,
		"boss_pos": Vector2(3392, 24),
		"boss_trigger": 3088.0,
		"boss_hp": 60,
		"boss_tint": Color(1.0, 0.45, 0.6),
		"ground_y": 200, "fall_line": 252.0,
		"bg": "cave",
	}
## 雪原: 更密的浮台与缺口, 夜色 + 飘雪
static func _level_snow() -> Dictionary:
	var plats: Array[Vector3i] = [
		Vector3i(320, 144, 64), Vector3i(448, 116, 48),
		Vector3i(700, 144, 64), Vector3i(830, 116, 64), Vector3i(960, 144, 48),
		Vector3i(1230, 144, 80), Vector3i(1400, 116, 48),
		Vector3i(1760, 116, 64), Vector3i(1880, 144, 64), Vector3i(2000, 116, 48),
		Vector3i(2300, 144, 64), Vector3i(2430, 116, 64), Vector3i(2560, 144, 48),
		Vector3i(2700, 116, 80),
	]
	var snip: Array[Vector2i] = [
		Vector2i(350, 200), Vector2i(860, 200), Vector2i(1250, 200),
		Vector2i(1430, 116), Vector2i(1850, 200), Vector2i(2020, 116),
		Vector2i(2330, 200), Vector2i(2450, 116), Vector2i(2730, 200),
		Vector2i(3050, 200),
	]
	var turb: Array[Vector2i] = [
		Vector2i(1050, 200), Vector2i(1650, 200), Vector2i(2150, 200),
		Vector2i(2600, 200), Vector2i(3120, 200), Vector2i(3260, 200),
	]
	# 开花弹兵: 雪原关特色, 不可击毙只能躲
	var blos: Array[Vector2i] = [
		Vector2i(640, 200), Vector2i(1180, 200), Vector2i(1700, 200),
		Vector2i(2250, 200), Vector2i(2900, 200), Vector2i(3180, 200),
	]
	return {
		"name": "MISSION 3  雪原",
		"key": "mission3",
		"vertical": false,
		"w": 3488, "h": 240,
		"grounds": [
			Vector2i(0, 512), Vector2i(576, 1168), Vector2i(1232, 1776),
			Vector2i(1840, 2320), Vector2i(2384, 3040), Vector2i(3104, 3488),
		],
		"bridge": Vector2i(-1, -1),
		"platforms": plats,
		"snipers": snip,
		"turrets": turb,
		"blossoms": blos,
		"boss_pos": Vector2(3392, 24),
		"boss_trigger": 3088.0,
		"ground_y": 200, "fall_line": 252.0,
		"bg": "snow",
	}
## level 1: 丛林(横向) / level 2: 瀑布(纵向) / level 3: 雪原(横向, 夜战)
static func level_config(n: int) -> Dictionary:
	if n >= 4:
		return _level_lair()
	if n >= 3:
		return _level_snow()
	if n <= 1:
		return {
			"name": "MISSION 1  丛林",
			"key": "mission1",
			"vertical": false,
			"w": 3488, "h": 240,
			"grounds": [
				Vector2i(0, 592), Vector2i(656, 1216), Vector2i(1280, 1504),
				Vector2i(1664, 2208), Vector2i(2272, 2976), Vector2i(3040, 3488),
			],
			"bridge": Vector2i(1504, 1664),
			"platforms": [
				Vector3i(368, 144, 64), Vector3i(480, 116, 48),
				Vector3i(720, 144, 64), Vector3i(832, 116, 64), Vector3i(944, 144, 48),
				Vector3i(1320, 144, 80),
				Vector3i(1740, 116, 64), Vector3i(1856, 144, 64), Vector3i(1968, 116, 48),
				Vector3i(2400, 144, 64), Vector3i(2512, 116, 64), Vector3i(2624, 144, 48),
				Vector3i(2760, 116, 80), Vector3i(2960, 144, 48),
			],
			"snipers": [
				Vector2i(420, 200), Vector2i(1096, 200), Vector2i(1370, 200),
				Vector2i(2064, 200), Vector2i(2544, 116), Vector2i(2700, 144),
				Vector2i(2920, 200), Vector2i(3120, 200),
			],
			"blossoms": [
				Vector2i(1490, 200), Vector2i(2320, 200), Vector2i(2800, 116),
			],
			"turrets": [
				Vector2i(928, 200), Vector2i(2080, 200), Vector2i(2384, 200),
				Vector2i(3088, 200), Vector2i(3232, 200),
			],
			"boss_pos": Vector2(3392, 24),          # 墙体位置 (核心内嵌)
			"boss_trigger": 3088.0,
			"ground_y": 200, "fall_line": 252.0,
			"bg": "jungle",
		}
	# 纵向瀑布: 宽 320 固定, 高 1728, 自下而上攀爬
	var plats: Array[Vector3i] = []
	var snip: Array[Vector2i] = []
	var turb: Array[Vector2i] = []
	# 之字浮台: 每 ~118px 一层, 左右交错 (y 从底部 1560 到顶部 120)
	var y := 1560
	var side := 0
	while y > 140:
		var x := 36 if side == 0 else 208
		plats.append(Vector3i(x, y, 76))
		if y % 240 < 120:                        # 部分层加侧翼小台
			plats.append(Vector3i(140 if side == 0 else 20, y - 56, 48))
		if y < 1500 and y % 360 < 120:
			snip.append(Vector2i(x + 30, y - 16))  # 平台上的狙击手
		y -= 118
		side = 1 - side
	# 顶部要塞平台 + 双炮塔
	plats.append(Vector3i(88, 120, 144))
	turb.append(Vector2i(60, 120))
	turb.append(Vector2i(248, 120))
	return {
		"name": "MISSION 2  瀑布",
		"key": "mission2",
		"vertical": true,
		"w": 320, "h": 1728,
		"grounds": [],                            # 无实地: 纯浮台攀爬
		"bridge": Vector2i(-1, -1),
		"platforms": plats,
		"snipers": snip,
		"turrets": turb,
		"boss_pos": Vector2(96, -80),             # 核心: 顶部要塞上方
		"boss_trigger": 240.0,                    # 玩家爬到 y<=240 触发
		"ground_y": 1660,                         # 底部水面(坠落死线)
		"fall_line": 1690.0,
		"bg": "waterfall",
	}
