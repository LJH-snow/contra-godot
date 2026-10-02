#!/usr/bin/env python3
"""魂斗罗像素素材生成器 — 生成全部 PNG 素材到 assets/sprites/"""
import os, math
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sprites")
os.makedirs(OUT, exist_ok=True)

# ---------------- 调色板 ----------------
OUTL = (14, 14, 26)
SKIN = (240, 176, 120); SKIN2 = (198, 130, 86)
BAND = (216, 40, 32); HAIR = (70, 44, 26)
PANTS = (56, 92, 216); PANTS2 = (34, 60, 158)
BOOT = (140, 90, 40); BOOT2 = (104, 64, 28)
GUN = (58, 58, 72); GUN2 = (108, 108, 126)
WHITE = (250, 250, 250); GRAY = (170, 170, 182)
OLIVE = (100, 124, 56); OLIVE2 = (68, 88, 40); CAPD = (56, 74, 30)
TEAL = (70, 150, 156); TEAL2 = (46, 108, 112)
TGRAY = (150, 150, 162); TGRAY2 = (92, 92, 106)
RED = (210, 46, 40); GOLD = (250, 186, 48)
BYEL = (255, 218, 96); BORANGE = (255, 140, 46); BRED = (248, 70, 46)
EPINK = (255, 168, 184); LCYAN = (110, 244, 255)
GRASS = (74, 164, 66); GRASS2 = (44, 118, 44)
DIRT = (130, 90, 54); DIRT2 = (100, 66, 38)
WOOD = (172, 122, 66); WOOD2 = (132, 90, 46)
WATER = (44, 92, 204); WATER2 = (76, 136, 234)
METAL = (118, 118, 134); METAL2 = (86, 86, 100)

F35 = {  # 3x5 微型字体
 'M': ["101","111","111","111","101"], 'S': ["111","100","111","001","111"],
 'L': ["100","100","100","100","111"], 'F': ["111","100","111","100","100"],
 'R': ["111","100","110","101","101"], 'B': ["111","101","111","101","111"],
 'E': ["111","100","110","100","111"], '1': ["010","110","010","010","111"],
}
F57 = {  # 5x7 像素字体(标题用)
 'A': ["01110","10001","10001","11111","10001","10001","10001"],
 'B': ["11110","10001","10001","11110","10001","10001","11110"],
 'C': ["01110","10001","10000","10000","10000","10001","01110"],
 'N': ["10001","11001","10101","10011","10001","10001","10001"],
 'T': ["11111","00100","00100","00100","00100","00100","00100"],
 'O': ["01110","10001","10001","10001","10001","10001","01110"],
 'R': ["11110","10001","10001","11110","10100","10010","10001"],
 ' ': ["00000","00000","00000","00000","00000","00000","00000"],
 '!': ["00100","00100","00100","00100","00100","00000","00100"],
}

# ---------------- 基础绘制 ----------------
class Cell:
    """在 sheet 的某个格子内作画, 坐标相对格子左上角"""
    def __init__(self, sheet, ox, oy, w, h):
        self.s, self.ox, self.oy, self.w, self.h = sheet, ox, oy, w, h
        self.d = ImageDraw.Draw(sheet)
    def px(self, x, y, c):
        x += self.ox; y += self.oy
        if 0 <= x < self.s.width and 0 <= y < self.s.height:
            self.d.point((x, y), c)
    def rect(self, x, y, w, h, c):
        for j in range(int(y), int(y + h)):
            for i in range(int(x), int(x + w)):
                self.px(i, j, c)
    def line(self, x0, y0, x1, y1, c, t=1):
        x0, y0, x1, y1 = int(x0), int(y0), int(x1), int(y1)
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1; sy = 1 if y0 < y1 else -1
        err = dx + dy
        while True:
            self.px(x0, y0, c)
            if t == 2:
                self.px(x0 + 1, y0, c); self.px(x0, y0 + 1, c)
            if x0 == x1 and y0 == y1: break
            e2 = 2 * err
            if e2 >= dy: err += dy; x0 += sx
            if e2 <= dx: err += dx; y0 += sy
    def disc(self, cx, cy, r, c):
        for j in range(int(cy - r) - 1, int(cy + r) + 2):
            for i in range(int(cx - r) - 1, int(cx + r) + 2):
                if (i - cx) ** 2 + (j - cy) ** 2 <= r * r + r * 0.6:
                    self.px(i, j, c)
    def outline(self, near=(14, 14, 26)):
        """给格子内非透明像素自动描边"""
        ox, oy = self.ox, self.oy
        tofill = []
        for y in range(oy, oy + self.h):
            for x in range(ox, ox + self.w):
                if self.s.getpixel((x, y))[3] == 0:
                    for nx, ny in ((x+1,y),(x-1,y),(x,y+1),(x,y-1)):
                        if ox <= nx < ox + self.w and oy <= ny < oy + self.h:
                            if self.s.getpixel((nx, ny))[3] > 0:
                                tofill.append((x, y)); break
        for p in tofill:
            self.d.point(p, near)

def new_sheet(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))

def save(img, name):
    img.save(os.path.join(OUT, name))
    print(f"  {name:22s} {img.width}x{img.height}")

# ---------------- 玩家 (比尔·雷泽, 朝右) ----------------
# 布局 6列x6行, 32x32: 行0=站立瞄准(横/斜上/竖上) 行1=跑动瞄准水平(6)
# 行2=跑动瞄准斜上(6) 行3=空中翻滚(4) 行4=[卧倒,死亡飞出,死亡倒地]
P1_PAL = {"band": BAND, "pants": PANTS, "pants2": PANTS2, "boot": BOOT, "boot2": BOOT2}
P2_PAL = {"band": (56, 120, 236), "pants": (208, 64, 52), "pants2": (156, 40, 34),
          "boot": (120, 76, 150), "boot2": (88, 52, 112)}

def draw_torso(c, bob=0, lean=0, pal=P1_PAL):
    """躯干+头, 根部在脚底 y=30"""
    y = bob
    c.rect(12, 10 + y, 8, 3, HAIR)                       # 头发
    c.rect(11, 12 + y, 10, 3, pal["band"])               # 头带
    c.px(10, 13 + y, pal["band"]); c.px(9, 12 + y, pal["band"]); c.px(8, 11 + y, pal["band"])  # 带尾
    c.rect(12, 15 + y, 9, 4, SKIN)                       # 脸
    c.px(19, 16 + y, OUTL)                               # 眼
    c.rect(12 + lean, 19 + y, 9 - lean, 2, SKIN)         # 脖子/上胸
    c.rect(12 + lean, 21 + y, 9 - lean, 5, SKIN)         # 胸肌
    c.rect(12 + lean, 25 + y, 9 - lean, 3, SKIN2)        # 腹部阴影
    c.line(16, 20 + y, 16, 27 + y, OUTL)                 # 中线
def draw_legs_stand(c, bob=0, pal=P1_PAL):
    y = bob
    c.rect(12, 28 + y, 4, 2, pal["pants"]); c.rect(17, 28 + y, 4, 2, pal["pants"])
    c.rect(11, 28 + y, 5, 2, pal["pants2"]); c.rect(17, 28 + y, 5, 2, pal["pants"])
    c.rect(11, 30, 5, 2, pal["boot"]); c.rect(17, 30, 6, 2, pal["boot"])
    c.rect(11, 31, 5, 1, pal["boot2"]); c.rect(17, 31, 6, 1, pal["boot2"])
def draw_rifle(c, x, y, angle, bob=0):
    """在肩部(x,y)按 angle(弧度, 0=右, -pi/2=上)画枪+手臂"""
    dx, dy = math.cos(angle), math.sin(angle)
    ex, ey = x + dx * 11, y + dy * 11          # 枪口
    c.line(x, y, ex, ey, GUN, 2)               # 枪管
    c.px(ex, ey, GUN2)
    mx, my = x + dx * 4, y + dy * 4
    c.line(x, y + 1, mx, my + 1, BOOT)         # 木质枪托
    c.disc(x + dx * 6, y + dy * 6 + 1, 1.6, SKIN)   # 前手
    c.disc(x + 1, y + 1, 2, SKIN)                    # 后手
def gen_player(pal=P1_PAL, name="player.png"):
    S = new_sheet(32 * 6, 32 * 6)
    def cell(col, row):
        return Cell(S, col * 32, row * 32, 32, 32)
    # 行0: 站立三方向
    for i, ang in enumerate([0.0, -math.pi / 4, -math.pi / 2]):
        c = cell(i, 0)
        draw_torso(c, lean=1 if i else 0, pal=pal)
        draw_legs_stand(c, pal=pal)
        draw_rifle(c, 17, 22 + (1 if i == 0 else 0), ang)
        c.outline()
    # 行1/2: 跑动循环 6 帧 (水平/斜上)
    for f in range(6):
        for row, ang in ((1, 0.0), (2, -math.pi / 4)):
            c = cell(f, row)
            bob = 1 if f % 2 == 0 else 0
            ph = f / 6.0 * 2 * math.pi
            draw_torso(c, bob=bob, pal=pal)
            hipx, hipy = 16.5, 28 + bob
            for side in (1, -1):                # 两条腿相位差半圈
                p = ph + (0 if side > 0 else math.pi)
                fx = hipx + math.cos(p) * 8.5
                fy = hipy + 1 - abs(math.sin(p)) * 2.2 + (math.sin(p) > 0) * 1.2
                kx = hipx + math.cos(p) * 4.5 + side
                ky = hipy - 1 + abs(math.sin(p)) * 1.5
                c.line(hipx, hipy, kx, ky, pal["pants"] if side > 0 else pal["pants2"], 2)
                c.line(kx, ky, fx, fy, pal["pants"] if side > 0 else pal["pants2"], 2)
                c.rect(fx - 2, fy, 5 if side > 0 else 4, 2, pal["boot"] if side > 0 else pal["boot2"])
            draw_rifle(c, 17, 22 + bob, ang)
            c.outline()
    # 行3: 空中翻滚团身(4帧旋转)
    ball = new_sheet(20, 20)
    b = Cell(ball, 0, 0, 20, 20)
    b.disc(10, 10, 7.2, SKIN)                   # 团起身躯
    b.disc(10, 8, 4, pal["band"])               # 头带在上
    b.rect(3, 9, 4, 5, pal["pants"])            # 蜷起的腿
    b.rect(14, 10, 4, 3, pal["boot"])           # 靴子
    b.rect(14, 6, 5, 3, SKIN2)                  # 手臂抱膝
    b.outline()
    for f in range(4):
        rot = ball.rotate(f * 90, resample=Image.NEAREST)
        S.alpha_composite(rot, (f * 32 + 6, 32 * 3 + 6))
    # 行4: 卧倒 / 死亡飞出 / 死亡倒地
    c = cell(0, 4)                              # 卧倒射击
    c.rect(4, 24, 24, 3, pal["pants"])
    c.rect(2, 24, 6, 3, pal["boot"])
    c.rect(14, 23, 9, 4, SKIN)
    c.rect(22, 21, 5, 3, SKIN)
    c.rect(24, 22, 4, 2, pal["band"])
    c.line(4, 25, 30, 25, GUN, 2)
    c.px(30, 25, GUN2); c.px(31, 24, BYEL)
    c.outline()
    c = cell(1, 4)                              # 死亡飞出(仰面四肢张开)
    c.disc(14, 16, 4, SKIN); c.rect(11, 12, 7, 2, pal["band"])
    c.line(11, 18, 5, 22, SKIN, 2); c.line(18, 18, 25, 21, SKIN, 2)
    c.line(12, 20, 8, 28, pal["pants"], 2); c.line(17, 20, 22, 27, pal["pants"], 2)
    c.rect(6, 28, 3, 2, pal["boot"]); c.rect(22, 27, 3, 2, pal["boot"])
    c.outline()
    c = cell(2, 4)                              # 死亡倒地
    c.rect(6, 28, 20, 3, SKIN)
    c.rect(24, 27, 4, 3, SKIN); c.rect(25, 25, 3, 2, pal["band"])
    c.line(4, 29, 10, 29, pal["boot"], 2)
    c.outline()
    save(S, name)

# ---------------- 敌人 ----------------
# enemies.png 6列x3行 32x32: 行0=跑兵(4) 行1=狙击手(横/斜上/竖上) 行2=飞行胶囊(2)
def draw_soldier_torso(c, uniform, u2, capcol, bob=0):
    y = bob
    c.rect(12, 9 + y, 9, 3, capcol)             # 帽檐
    c.rect(12, 6 + y, 8, 3, capcol)             # 帽顶
    c.rect(12, 12 + y, 9, 4, SKIN)              # 脸
    c.px(12, 14 + y, OUTL)                      # 眼(朝右)
    c.rect(12, 16 + y, 9, 7, uniform)           # 军装
    c.rect(12, 20 + y, 9, 3, u2)                # 腰带
def gen_enemies():
    S = new_sheet(32 * 6, 32 * 3)
    def cell(col, row):
        return Cell(S, col * 32, row * 32, 32, 32)
    for f in range(4):                          # 行0 跑兵(朝右, 运行时翻转)
        c = cell(f, 0)
        ph = f / 4.0 * 2 * math.pi
        bob = 1 if f % 2 == 0 else 0
        draw_soldier_torso(c, OLIVE, OLIVE2, CAPD, bob)
        hipx, hipy = 16.5, 23 + bob
        for side in (1, -1):
            p = ph + (0 if side > 0 else math.pi)
            fx = hipx + math.cos(p) * 7.5
            fy = hipy + 2 - abs(math.sin(p)) * 2 + (math.sin(p) > 0) * 1.5
            c.line(hipx, hipy, fx, fy, OLIVE if side > 0 else OLIVE2, 2)
            c.rect(fx - 2, fy, 4, 2, BOOT)
        c.line(17, 18 + bob, 26, 20 + bob, GUN, 2)   # 端枪
        c.disc(18, 19 + bob, 1.6, SKIN)
        c.outline()
    for i, ang in enumerate([0.0, -math.pi / 4, -math.pi / 2]):   # 行1 狙击手
        c = cell(i, 1)
        draw_soldier_torso(c, TEAL, TEAL2, TEAL2)
        c.rect(12, 23, 4, 2, TEAL); c.rect(17, 23, 4, 2, TEAL2)
        c.rect(11, 25, 5, 2, BOOT); c.rect(17, 25, 6, 2, BOOT)
        dx, dy = math.cos(ang), math.sin(ang)
        c.line(17, 20, 17 + dx * 11, 20 + dy * 11, GUN, 2)
        c.disc(18, 21, 1.6, SKIN)
        c.outline()
    for f in range(2):                          # 行2 飞行胶囊(红色橄榄型)
        c = cell(f, 2)
        c.disc(16, 16, 7, RED)
        c.disc(13, 14, 3, (250, 120, 100))
        c.rect(8, 15, 16, 2, (150, 24, 20))
        c.rect(10, 21, 12, 2, GRAY)              # 下鳍
        c.rect(13, 6, 6, 3, GRAY)                # 上鳍
        if f:                                    # 尾焰
            c.line(8, 16, 3, 14, BORANGE, 2); c.px(4, 18, BYEL)
        else:
            c.line(8, 17, 3, 19, BORANGE, 2); c.px(4, 14, BYEL)
        c.outline()
    save(S, "enemies.png")

# 炮塔 turret.png 9列 16x16: [0]=底座 之后8个旋转炮管(0..315度)
def gen_turret():
    S = new_sheet(16 * 9, 16)
    c = Cell(S, 0, 0, 16, 16)
    c.disc(8, 8, 6.5, TGRAY2)
    c.disc(8, 8, 5, TGRAY)
    c.disc(8, 8, 2.5, OUTL)
    c.outline()
    for i in range(8):
        c = Cell(S, 16 * (i + 1), 0, 16, 16)
        ang = i * math.pi / 4
        c.line(8, 8, 8 + math.cos(ang) * 6.5, 8 + math.sin(ang) * 6.5, GUN, 2)
        c.px(8 + math.cos(ang) * 7, 8 + math.sin(ang) * 7, GUN2)
        c.outline()
    save(S, "turret.png")

# ---------------- 道具箱 items.png 8列 24x16: M S L F R B 金鹰 光环 ----------------
def gen_items():
    S = new_sheet(24 * 8, 16)
    letters = ["M", "S", "L", "F", "R", "B"]
    for i, ch in enumerate(letters):
        c = Cell(S, 24 * i, 0, 24, 16)
        c.rect(3, 2, 18, 12, RED)
        c.rect(3, 2, 18, 2, (250, 110, 96))
        c.rect(3, 12, 18, 2, (150, 20, 16))
        g = F35[ch]
        for yy in range(5):
            for xx in range(3):
                if g[yy][xx] == "1":
                    c.rect(3 + 9 + xx * 2 - 3, 3 + yy * 2, 2, 2, WHITE)
        c.outline()
    c = Cell(S, 24 * 6, 0, 24, 16)              # 金鹰
    c.rect(4, 8, 16, 3, GOLD)
    c.disc(7, 7, 2.5, GOLD); c.disc(7, 7, 1, OUTL)
    c.line(9, 6, 15, 2, GOLD, 2); c.line(12, 8, 20, 8, (220, 150, 30), 2)
    c.rect(4, 11, 16, 2, (220, 150, 30))
    c.outline()
    c = Cell(S, 24 * 7, 0, 24, 16)              # 无敌光环
    c.disc(12, 8, 6.5, (120, 200, 255))
    c.disc(12, 8, 4.2, (200, 240, 255))
    c.outline()
    save(S, "items.png")

# ---------------- 子弹 ----------------
def gen_bullets():
    S = new_sheet(8 * 6, 8)
    def cell(i):
        return Cell(S, 8 * i, 0, 8, 8)
    c = cell(0); c.disc(4, 4, 1.8, BYEL); c.px(3, 4, WHITE); c.line(0, 4, 2, 4, BORANGE)
    c = cell(1); c.disc(4, 4, 2.2, BORANGE); c.disc(3, 3, 0.9, WHITE)
    c = cell(2); c.disc(4, 4, 2.8, BRED); c.disc(3, 3, 1.2, (255, 170, 90))
    c = cell(3); c.disc(4, 4, 2.4, EPINK); c.disc(3, 3, 1, WHITE)
    c = cell(4); c.disc(4, 4, 3, BORANGE); c.disc(4, 4, 1.6, BYEL); c.px(2, 2, BRED); c.px(6, 6, BRED)
    c = cell(5); c.disc(4, 4, 1.6, LCYAN); c.px(4, 4, WHITE)
    save(S, "bullets.png")
    S2 = new_sheet(28, 6)                       # 雷射(横向)
    c = Cell(S2, 0, 0, 28, 6)
    c.rect(0, 2, 28, 2, LCYAN); c.rect(2, 1, 22, 4, (56, 180, 220))
    c.rect(0, 0, 6, 6, LCYAN); c.rect(4, 2, 3, 2, WHITE)
    save(S2, "laser.png")

# ---------------- 特效 fx.png 6列x3行 48x48 ----------------
def gen_fx():
    S = new_sheet(48 * 6, 48 * 3)
    for f in range(6):                          # 行0 爆炸 6 帧
        c = Cell(S, 48 * f, 0, 48, 48)
        r = 4 + f * 3.4
        if f < 4:
            c.disc(24, 24, r, BYEL if f < 2 else BORANGE)
            c.disc(24, 24, r * 0.55, WHITE if f < 2 else BYEL)
            for a in range(8):
                ang = a * math.pi / 4 + f
                c.px(24 + math.cos(ang) * (r + 3), 24 + math.sin(ang) * (r + 3), BRED)
        else:
            c.disc(24, 24, r, (150, 60, 40))
            for a in range(10):
                ang = a * math.pi / 5 + f * 0.5
                c.px(24 + math.cos(ang) * (r - 2), 24 + math.sin(ang) * (r - 2), BORANGE)
    for f in range(2):                          # 行1 枪口焰 2 帧
        c = Cell(S, 48 * f, 48, 48, 48)
        r = 4 + f * 2
        c.disc(24, 24, r, BYEL); c.disc(24, 24, r * 0.5, WHITE)
        c.line(24 - r - 3, 24, 24 + r + 3, 24, BYEL); c.line(24, 24 - r - 3, 24, 24 + r + 3, BYEL)
    for f in range(3):                          # 行1 水花 3 帧
        c = Cell(S, 48 * (f + 2), 48, 48, 48)
        for i, h in enumerate([8, 14, 10][:(f + 1) * 1]):
            x = 14 + i * 8
            c.line(x, 40, x + (2 if f else 0), 40 - h - f * 4, (190, 220, 255), 2)
            c.px(x + 2, 36 - h - f * 4, WHITE)
    for f in range(3):                          # 行2 闪光 3 帧
        c = Cell(S, 48 * f, 96, 48, 48)
        c.disc(24, 24, 6 - f * 1.6, WHITE if f == 0 else LCYAN)
        c.line(18, 18, 30 - f * 3, 30 - f * 3, WHITE, 2)
    save(S, "fx.png")

# ---------------- Boss ----------------
def gen_boss():
    S = new_sheet(96, 200)                      # 基地墙体
    c = Cell(S, 0, 0, 96, 200)
    c.rect(0, 0, 96, 200, METAL)
    for y in range(0, 200, 20):                 # 面板缝+铆钉
        c.rect(0, y, 96, 2, METAL2)
        for x in range(0, 96, 24):
            c.px(x + 3, y + 5, (60, 60, 76)); c.px(x + 20, y + 5, (60, 60, 76))
    for x in range(0, 96, 32):
        c.rect(x, 0, 2, 200, METAL2)
    c.rect(0, 0, 96, 4, TGRAY2)                 # 顶部装甲
    c.rect(28, 118, 40, 56, (52, 52, 66))       # 核心大门框
    c.rect(31, 121, 34, 50, OUTL)               # 门内(关闭=黑)
    c.rect(0, 186, 96, 14, (64, 64, 78))        # 底座
    save(S, "boss_wall.png")
    S2 = new_sheet(28 * 2, 28)                  # 核心 2 帧
    for f in range(2):
        c = Cell(S2, 28 * f, 0, 28, 28)
        c.disc(14, 14, 10, (120, 20, 20))
        c.disc(14, 14, 8 - f, RED)
        c.disc(14 - f, 13, 4, (255, 140, 120))
        c.disc(11, 11, 1.6, WHITE)
        c.outline()
    save(S2, "boss_core.png")

# ---------------- 地形贴图 ----------------
def gen_tiles():
    import random
    random.seed(7)
    S = new_sheet(16, 16)                       # 草地顶
    c = Cell(S, 0, 0, 16, 16)
    c.rect(0, 0, 16, 16, DIRT)
    c.rect(0, 0, 16, 4, GRASS)
    c.rect(0, 4, 16, 1, GRASS2)
    for i in range(16):
        if random.random() < 0.5: c.px(i, 0, GRASS2)
        if random.random() < 0.3: c.px(i, -0 + random.randint(5, 8) if False else random.randint(5, 14), DIRT2)
    save(S, "tile_grass.png")
    S = new_sheet(16, 16)                       # 泥土
    c = Cell(S, 0, 0, 16, 16)
    c.rect(0, 0, 16, 16, DIRT)
    for _ in range(9):
        c.px(random.randint(0, 15), random.randint(0, 15), DIRT2)
    save(S, "tile_dirt.png")
    S = new_sheet(16, 16)                       # 木质平台
    c = Cell(S, 0, 0, 16, 16)
    c.rect(0, 0, 16, 8, WOOD)
    c.rect(0, 6, 16, 2, WOOD2)
    for x in range(0, 16, 8):
        c.rect(x, 0, 1, 8, WOOD2); c.px(x + 4, 3, (90, 60, 30))
    c.px(2, 1, (210, 160, 100)); c.px(10, 2, (210, 160, 100))
    save(S, "tile_platform.png")
    for name, bright in (("tile_water1.png", 0), ("tile_water2.png", 1)):
        S = new_sheet(16, 16)
        c = Cell(S, 0, 0, 16, 16)
        c.rect(0, 0, 16, 16, WATER)
        for x in range(16):                     # 波纹
            y = 2 + (2 if (x // 4 + bright) % 2 else 0)
            c.px(x, y, WATER2); c.px(x, y + 1, (120, 170, 250)) if (x + bright * 2) % 5 == 0 else None
        save(S, name)
    S = new_sheet(16, 16)                       # 吊桥
    c = Cell(S, 0, 0, 16, 16)
    c.rect(0, 4, 16, 6, WOOD)
    c.rect(0, 4, 16, 1, (210, 160, 100))
    c.rect(0, 9, 16, 1, WOOD2)
    c.rect(7, 4, 2, 6, WOOD2)
    c.line(0, 2, 7, 3, (90, 60, 30)); c.line(8, 3, 15, 2, (90, 60, 30))
    save(S, "tile_bridge.png")

# ---------------- 背景 ----------------
def gen_bg():
    S = Image.new("RGBA", (320, 240))           # 天空渐变
    d = ImageDraw.Draw(S)
    for y in range(240):
        t = y / 240
        if t < 0.55:
            k = t / 0.55
            col = (int(24 + k * 60), int(48 + k * 110), int(96 + k * 120))
        else:
            k = (t - 0.55) / 0.45
            col = (int(84 + k * 150), int(158 - k * 60), int(216 - k * 120))
        d.line((0, y, 320, y), fill=col)
    d.ellipse((250, 30, 292, 72), fill=(255, 236, 160))      # 太阳
    d.ellipse((258, 36, 286, 66), fill=(255, 248, 210))
    for cx, cy, w in ((40, 44, 60), (130, 26, 80), (240, 66, 50), (80, 90, 40)):  # 云
        for i in range(w // 8):
            d.ellipse((cx + i * 8 - w // 2, cy - 4, cx + i * 8 - w // 2 + 14, cy + 6),
                      fill=(240, 244, 255, 210))
    S.save(os.path.join(OUT, "bg_sky.png")); print("  bg_sky.png            320x240")
    import random
    random.seed(11)
    S = Image.new("RGBA", (320, 120))           # 远景丛林(可平铺)
    d = ImageDraw.Draw(S)
    for x in range(320):                        # 周期性山脊
        y = int(56 + 26 * math.sin(x * math.pi / 160 * 2) + 14 * math.sin(x * math.pi / 80 * 2 + 1.3))
        d.line((x, y, x, 120), fill=(30, 58, 52))
    for x in range(0, 320, 16):                 # 树冠团
        y = int(50 + 22 * math.sin(x * math.pi / 160 * 2) + 12 * math.sin(x * math.pi / 80 * 2 + 1.3))
        d.ellipse((x - 8, y - 10, x + 12, y + 12), fill=(24, 50, 44))
    S.save(os.path.join(OUT, "bg_far.png")); print("  bg_far.png            320x120")
    S = Image.new("RGBA", (320, 80))            # 近景树影(可平铺)
    d = ImageDraw.Draw(S)
    for x in range(-8, 328, 28):
        h = 34 + int(18 * math.sin(x * 0.21 + 2))
        d.polygon([(x, 80), (x + 10, 80 - h), (x + 20, 80)], fill=(16, 34, 30))
        d.ellipse((x + 2, 80 - h - 10, x + 20, 80 - h + 6), fill=(16, 34, 30))
    S.save(os.path.join(OUT, "bg_near.png")); print("  bg_near.png           320x80")

# ---------------- 瀑布关背景 ----------------
def gen_waterfall():
    import random
    random.seed(23)
    OUT2 = os.path.join(ROOT, "assets", "sprites")
    # 崖壁 (可纵向平铺 320x256): 深色岩壁 + 苔藓 + 横向岩层
    S = Image.new("RGBA", (320, 256))
    d = ImageDraw.Draw(S)
    d.rectangle((0, 0, 320, 256), fill=(38, 46, 44))
    for yy in range(0, 256, 24):                    # 岩层横缝
        d.line((0, yy, 320, yy), fill=(30, 37, 36))
        for xx in range(0, 320, 40):
            if random.random() < 0.5:
                d.line((xx, yy, xx + random.randint(6, 18), yy + random.randint(2, 6)),
                       fill=(48, 58, 52))
    for _ in range(60):                             # 苔藓斑
        xx, yy = random.randint(0, 312), random.randint(0, 250)
        d.ellipse((xx, yy, xx + random.randint(3, 9), yy + random.randint(2, 6)),
                  fill=(52, 92, 58))
    for _ in range(30):                             # 岩石高光
        xx, yy = random.randint(0, 310), random.randint(0, 250)
        d.line((xx, yy, xx + random.randint(4, 10), yy), fill=(70, 80, 74))
    S.save(os.path.join(OUT2, "bg_waterfall.png"))
    print("  bg_waterfall.png      320x256")
    # 瀑布关天空 (冷色调渐变 + 薄雾)
    S2 = Image.new("RGBA", (320, 240))
    d2 = ImageDraw.Draw(S2)
    for yy in range(240):
        t = yy / 240
        col = (int(30 + t * 40), int(44 + t * 66), int(70 + t * 80))
        d2.line((0, yy, 320, yy), fill=col)
    d2.ellipse((240, 24, 284, 68), fill=(210, 226, 235))
    d2.ellipse((250, 34, 276, 60), fill=(228, 240, 246))
    S2.save(os.path.join(OUT2, "bg_falls_sky.png"))
    print("  bg_falls_sky.png      320x240")

# ---------------- 雪地关贴图/背景 ----------------
def gen_snow():
    import random
    random.seed(31)
    OUT2 = os.path.join(ROOT, "assets", "sprites")
    SNOW = (232, 240, 248); SNOW2 = (196, 210, 226)
    ROCK = (88, 96, 118); ROCK2 = (66, 74, 94)
    # 雪地顶 (16x16): 白雪覆盖 + 蓝阴影
    S = Image.new("RGBA", (16, 16))
    c = Cell(S, 0, 0, 16, 16)
    c.rect(0, 0, 16, 16, ROCK)
    c.rect(0, 0, 16, 5, SNOW)
    c.rect(0, 5, 16, 1, SNOW2)
    for i in range(16):
        if random.random() < 0.4: c.px(i, 0, SNOW2)
        if random.random() < 0.3: c.px(i, random.randint(6, 14), ROCK2)
    S.save(os.path.join(OUT2, "tile_snow.png")); print("  tile_snow.png          16x16")
    # 冻土
    S = Image.new("RGBA", (16, 16))
    c = Cell(S, 0, 0, 16, 16)
    c.rect(0, 0, 16, 16, ROCK)
    for _ in range(9): c.px(random.randint(0, 15), random.randint(0, 15), ROCK2)
    S.save(os.path.join(OUT2, "tile_rock.png")); print("  tile_rock.png          16x16")
    # 冰水 (深蓝)
    for name, hi in (("tile_icewater1.png", 0), ("tile_icewater2.png", 1)):
        S = Image.new("RGBA", (16, 16))
        c = Cell(S, 0, 0, 16, 16)
        c.rect(0, 0, 16, 16, (30, 52, 110))
        for x in range(16):
            y = 2 + (2 if (x // 4 + hi) % 2 else 0)
            c.px(x, y, (70, 110, 180)); c.px(x, y + 1, (120, 160, 220)) if (x + hi * 2) % 5 == 0 else None
        S.save(os.path.join(OUT2, name))
    print("  tile_icewater1/2.png   16x16")
    # 雪原夜空 (极光带 + 星)
    S = Image.new("RGBA", (320, 240))
    d = ImageDraw.Draw(S)
    for yy in range(240):
        t = yy / 240
        d.line((0, yy, 320, yy), fill=(int(10 + t * 16), int(14 + t * 30), int(38 + t * 46)))
    for i in range(60):                        # 星
        xx, yy = random.randint(0, 318), random.randint(0, 150)
        b = random.randint(150, 255)
        d.point((xx, yy), fill=(b, b, min(255, b + 30)))
    for xx in range(320):                      # 极光带
        yy = int(52 + 16 * math.sin(xx * 0.02) + 8 * math.sin(xx * 0.05 + 1.7))
        for k in range(26):
            a = max(0, 90 - k * 4)
            d.point((xx, yy + k), fill=(60, 220, 150, a))
    d.ellipse((250, 170, 290, 210), fill=(220, 228, 240))   # 月亮
    d.ellipse((262, 176, 284, 202), fill=(10, 14, 38))
    S.save(os.path.join(OUT2, "bg_snow_sky.png")); print("  bg_snow_sky.png        320x240")
    # 雪山远景 (可横向平铺)
    S = Image.new("RGBA", (320, 120))
    d = ImageDraw.Draw(S)
    for x in range(320):
        y = int(58 + 24 * math.sin(x * math.pi / 160 * 2) + 12 * math.sin(x * math.pi / 80 * 2 + 2.2))
        d.line((x, y, x, 120), fill=(52, 62, 92))
        d.line((x, y, x, min(y + 8, 120)), fill=(190, 205, 230))
    S.save(os.path.join(OUT2, "bg_snow_far.png")); print("  bg_snow_far.png        320x120")

# ---------------- 标题 Logo ----------------
def gen_title():
    W, H = 300, 110
    S = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(S)
    text = "CONTRA"
    cw, ch, sc = 6, 8, 5
    tw = len(text) * (cw * sc)
    x0 = (W - tw) // 2
    for i, chn in enumerate(text):
        g = F57.get(chn)
        if not g: continue
        for yy in range(7):
            for xx in range(5):
                if g[yy][xx] == "1":
                    px, py = x0 + i * cw * sc + xx * sc, 14 + yy * sc
                    grad = (250 - int(yy * 22), 90 - yy * 4, 40 + yy * 4)
                    d.rectangle((px, py, px + sc - 1, py + sc - 1), fill=grad)
    for i, chn in enumerate(text):              # 银色高光+描边
        g = F57.get(chn)
        if not g: continue
        for yy in range(7):
            for xx in range(5):
                if g[yy][xx] == "1":
                    px, py = x0 + i * cw * sc + xx * sc, 14 + yy * sc
                    if yy == 0:
                        d.rectangle((px, py, px + sc - 1, py + 1), fill=(255, 220, 160))
    d.text((0, 0), "", fill=(0, 0, 0))
    cjk = None
    for p, idx in (("/System/Library/Fonts/PingFang.ttc", 2),
                   ("/System/Library/Fonts/PingFang.ttc", 0),
                   ("/System/Library/Fonts/Hiragino Sans GB.ttc", 0),
                   ("/System/Library/Fonts/Supplemental/Songti.ttc", 0)):
        try:
            cjk = ImageFont.truetype(p, 26, index=idx); break
        except Exception:
            continue
    if cjk:
        d.text((W // 2 - 40, 66), "魂斗罗", font=cjk, fill=(255, 210, 90))
    else:
        d.text((W // 2 - 30, 66), "- 1 9 8 7 -", fill=(255, 210, 90))
    S.save(os.path.join(OUT, "title_logo.png")); print("  title_logo.png        300x110")

# ---------------- 生命图标 / 预览图 ----------------
def gen_misc():
    for pname, pal in (("life.png", P1_PAL), ("life2.png", P2_PAL)):
        S = new_sheet(12, 12)
        c = Cell(S, 0, 0, 12, 12)
        c.rect(2, 1, 8, 3, pal["band"])
        c.rect(2, 4, 8, 4, SKIN); c.px(3, 6, OUTL)
        c.rect(2, 8, 8, 3, pal["pants"])
        c.outline()
        save(S, pname)

def gen_preview():
    """拼一张总览图供检查"""
    import glob
    files = sorted(glob.glob(os.path.join(OUT, "*.png")))
    cols = 5
    rows = (len(files) + cols - 1) // cols
    CW, CH = 220, 200
    S = Image.new("RGBA", (cols * CW, rows * CH), (40, 40, 52, 255))
    d = ImageDraw.Draw(S)
    for i, f in enumerate(files):
        x, y = (i % cols) * CW, (i // cols) * CH
        im = Image.open(f)
        im.thumbnail((CW - 16, CH - 40), Image.NEAREST)
        bg = Image.new("RGBA", im.size, (70, 70, 90, 255))
        bg.alpha_composite(im)
        S.alpha_composite(bg, (x + 8, y + 26))
        d.text((x + 8, y + 6), os.path.basename(f), fill=(255, 255, 150))
    S.save(os.path.join(ROOT, "tools", "preview.png"))
    print("  preview.png 已生成")

if __name__ == "__main__":
    print("生成像素素材 →", OUT)
    gen_player(P1_PAL, "player.png"); gen_player(P2_PAL, "player2.png")
    gen_enemies(); gen_turret(); gen_items()
    gen_bullets(); gen_fx(); gen_boss(); gen_tiles(); gen_bg()
    gen_title(); gen_misc(); gen_waterfall(); gen_snow(); gen_preview()
    print("完成")
