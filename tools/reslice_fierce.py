#!/usr/bin/env python3
"""Fierce Soldier (CC-BY 4.0, by Vircon32/Carra — OpenGameArt) → 魂斗罗复刻 sprite sheet 重切。

零代码侵入设计:
- player.png 336x336, 6x6 格, 每格 56x56 (hframes/vframes=6 与帧索引 行*6+列 不变)
- 精灵在格内居中, 脚底放在 距格中心 +15px (与旧 32px 表的视觉对齐一致)
- 敌人表 336x168 (6x3), 脚底 +16px, 同理零代码
合成帧: 竖直瞄准(擦枪竖置) / 空中翻滚(蹲姿 90° 旋转 x4) / 死亡(跑姿 90°)
"""
from PIL import Image
import os

SRC = os.path.join(os.path.dirname(__file__), "asset_pack_fierce")
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
CELL = 56          # 新单元格
HALF = CELL // 2   # 28
FEET = 15          # 脚底距格中心 (匹配旧 32px 表 bbox y5..31)

def C(path):
    return Image.open(os.path.join(SRC, path)).convert("RGBA")

hero = C("originals/fierce_soldier_sprites_-_main_character.png")
foes = C("originals/fierce_soldier_sprites_-_enemies_and_bosses.png")

def flip_r(img):
    """统一朝右: 原表朝左帧水平翻转 (像素级无损)"""
    return img.transpose(Image.FLIP_LEFT_RIGHT)

def place(sheet, art, col, row, bottom_offset, scale=1.0):
    """居中放入单元格: bottom_offset = 脚底/底边距格中心的像素"""
    a = art
    if scale != 1.0:
        a = a.resize((max(1, round(a.width * scale)), max(1, round(a.height * scale))), Image.BOX)
    cx = col * CELL + HALF
    by = row * CELL + HALF + bottom_offset
    sheet.paste(a, (cx - a.width // 2, by - a.height), a)

def crop_box(img, box):
    return img.crop(box)

# ---- 主角源帧 (半尺寸坐标) ----
H = hero.resize((hero.width // 2, hero.height // 2), Image.BOX)
run_l = [crop_box(H, b) for b in [(2, 43, 31, 85), (64, 43, 93, 85)]]        # 朝左跑
run_r = [crop_box(H, b) for b in [(33, 44, 62, 85), (95, 44, 124, 85),
                                  (2, 87, 31, 130), (33, 88, 62, 130),
                                  (64, 87, 93, 130), (95, 88, 124, 130)]]    # 朝右跑(带焰)
run_r2 = [crop_box(H, b) for b in [(2, 87, 31, 130), (33, 88, 62, 130),
                                   (64, 87, 93, 130), (95, 88, 124, 130)]]
stand_l = crop_box(H, (2, 2, 31, 41))
stand_r = crop_box(H, (164, 2, 193, 45))
crouch = crop_box(H, (96, 9, 126, 41))
prone = flip_r(crop_box(H, (135, 47, 177, 68)))   # 头朝右 = 朝右卧倒

run_cycle = [flip_r(f) for f in run_l] + run_r      # 6 帧跑步循环

# ---- 竖直瞄准合成: 擦掉水平枪, 旋转 90° 竖到肩上 ----
def rifle_band(img):
    """找最长暗色横条 (枪身) 的行带"""
    w, h = img.size
    px = img.load()
    best, best_row = 0, None
    for y in range(h):
        run = cur = 0
        for x in range(w):
            r, g, b, a = px[x, y]
            dark = a > 0 and max(r, g, b) < 110
            cur = cur + 1 if dark else 0
            if cur > run:
                run = cur
                best_row = y if run > best else best_row
        best = max(best, run)
    return (best, best_row) if best >= 8 else None

def synth_up(img):
    """竖直瞄准: 枪身旋转竖置"""
    band = rifle_band(img)
    if band is None:
        return img
    length, y = band
    w, h = img.size
    px = img.load()
    xs = [x for x in range(w) if px[x, y][3] > 0 and max(px[x, y][:3]) < 110]
    x0, x1 = min(xs), max(xs) + 1
    gun = img.crop((x0, y, x1, y + 1)).resize((x1 - x0, 3), Image.NEAREST)
    gun = gun.transpose(Image.ROTATE_90)                    # 枪口朝上
    out = img.copy()
    opx = out.load()
    for yy in range(h):                                     # 擦掉原枪身
        for xx in range(w):
            r, g, b, a = px[xx, yy]
            if a > 0 and max(r, g, b) < 110 and abs(yy - y) <= 1 and x0 - 1 <= xx <= x1:
                opx[xx, yy] = (0, 0, 0, 0)
    hx = (x0 + x1) // 2
    out.paste(gun, (hx - 1, max(0, y - gun.height - 2)), gun)
    return out

# ---- 生成 P1 表 ----
def build_player():
    s = Image.new("RGBA", (CELL * 6, CELL * 6), (0, 0, 0, 0))
    place(s, flip_r(stand_l), 0, 0, FEET)                          # 0 待机
    place(s, synth_up(run_cycle[0]), 1, 0, FEET)                   # 1 跑动斜上
    place(s, synth_up(flip_r(stand_l)), 2, 0, FEET)                # 2 站立竖直瞄准
    for i, f in enumerate(run_cycle):                              # 6..11 跑步
        place(s, f, i, 1, FEET)
    for i, f in enumerate(run_cycle):                              # 12..17 跑动斜上
        place(s, synth_up(f), i, 2, FEET)
    for i in range(4):                                             # 18..21 翻滚
        place(s, crouch.rotate(-90 * i), i, 3, 0)
    place(s, prone, 0, 4, FEET + 5)                                # 24 卧倒 (+5 = 代码 prone offset)
    place(s, run_r[1].rotate(-90, expand=True), 1, 4, 0)           # 25 死亡飞出
    place(s, crouch, 2, 4, FEET)                                   # 26 蹲姿(备用)
    return s

# ---- P2: 红↔蓝, 绿裤→红裤 (匹配现 P1/P2 换色约定) ----
def swap_p2(img):
    out = img.copy()
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if r > 140 and g < 100 and b < 100:                    # 红头带→蓝
                px[x, y] = (56, 110, 226, a)
            elif g > 100 and r < 110 and b < 110:                  # 绿裤→红
                px[x, y] = (196, 62, 50, a)
    return out

# ---- 敌人表 336x168 (6x3, 56 格) ----
def build_enemies():
    s = Image.new("RGBA", (CELL * 6, CELL * 3), (0, 0, 0, 0))
    F = foes.resize((foes.width // 2, foes.height // 2), Image.BOX)
    sol_a = flip_r(crop_box(F, (3, 2, 32, 45)))     # 朝右站立
    sol_b = crop_box(F, (34, 2, 63, 45))            # 朝右开火
    for i in range(4):                              # 0..3 跑兵 2 帧循环
        place(s, sol_a if i % 2 == 0 else sol_b, i, 0, 16)
    place(s, sol_a, 6 % 6, 1, 16)                   # 6 狙击手·水平
    place(s, sol_b, 7 % 6, 1, 16)                   # 7 狙击手·斜上(暂用开火帧)
    place(s, sol_b, 8 % 6, 1, 16)                   # 8 狙击手·竖直(暂用开火帧)
    rk1 = crop_box(F, (114, 7, 147, 21))
    rk2 = crop_box(F, (114, 22, 149, 36))
    place(s, rk1, 0, 2, 0, scale=0.88)              # 12 胶囊·火箭 A
    place(s, rk2, 1, 2, 0, scale=0.88)              # 13 胶囊·火箭 B
    return s

# ---- 加特林 mini-boss 贴图 (2 帧旋转) ----
def build_gatling():
    F = foes.resize((foes.width // 2, foes.height // 2), Image.BOX)
    g1 = crop_box(F, (135, 41, 159, 65))
    g2 = crop_box(F, (161, 41, 185, 65))
    tex = Image.new("RGBA", (48, 24), (0, 0, 0, 0))
    tex.paste(g1, (0, 0), g1)
    tex.paste(g2, (24, 0), g2)
    tex.save(os.path.join(OUT, "enemy_gatling.png"))

def build_all():
    p1 = build_player()
    p1.save(os.path.join(OUT, "player.png"))
    swap_p2(p1).save(os.path.join(OUT, "player2.png"))
    build_enemies().save(os.path.join(OUT, "enemies.png"))
    build_boss()
    build_deco()
    build_fx()
    build_life()
    build_gatling()
    print("已生成 player/player2/enemies/boss_wall/boss_core/deco/fx/life/gatling")

# ---- 丛林装饰 (棕榈/灌木/草丛, 独立 PNG) ----
def build_deco():
    S = C("originals/fierce_soldier_sprites_-_scenery_and_gui.png")
    S = S.resize((S.width // 2, S.height // 2), Image.BOX)
    for name, box in [("deco_palm1", (2, 2, 59, 83)),
                      ("deco_palm2", (62, 2, 113, 57)),
                      ("deco_bush", (116, 2, 157, 33)),
                      ("deco_grass", (68, 63, 110, 83))]:
        crop_box(S, box).save(os.path.join(OUT, f"{name}.png"))

# ---- 爆炸帧替换 fx.png 第一行 (Frogatto explosion3, 见 CREDITS.md) ----
def key_out(img, tol=14):
    """源帧背景不透明: 按角落色抠底"""
    px = img.load()
    bg = px[0, 0][:3]
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if abs(r - bg[0]) < tol and abs(g - bg[1]) < tol and abs(b - bg[2]) < tol:
                px[x, y] = (0, 0, 0, 0)
    return img

def build_fx():
    exp = Image.open(os.path.join(os.path.dirname(__file__),
                      "asset_pack_fierce/originals/explosion3.png")).convert("RGBA")
    # 小版动画: 两行各 5 帧, 每帧约 62x56
    frames = []
    for r, y0 in [(0, 188), (1, 246)]:
        for c in range(5):
            frames.append(key_out(exp.crop((c * 62, y0, (c + 1) * 62, y0 + 56))))
    pick = [frames[i] for i in (0, 2, 3, 4, 5, 7)]         # 闪光→膨胀→火球→大→环→散
    fx = Image.open(os.path.join(OUT, "fx.png")).convert("RGBA")
    for i, f in enumerate(pick):
        cell = Image.new("RGBA", (48, 48), (0, 0, 0, 0))
        fit = f.resize((46, round(56 * 46 / 62)), Image.BOX)   # 适配 48 格
        cell.paste(fit, (1, (48 - fit.height) // 2), fit)
        fx.paste(cell, ((i % 6) * 48, (i // 6) * 48))          # 覆盖第 0 行 boom
    fx.save(os.path.join(OUT, "fx.png"))

# ---- HUD 生命图标: 主角头像 (从新 player 表裁头部, 自带透明底) ----
def build_life():
    p1 = Image.open(os.path.join(OUT, "player.png")).convert("RGBA")
    head = crop_box(p1, (16, 0, 40, 20)).resize((12, 12), Image.BOX)
    head.save(os.path.join(OUT, "life.png"))

# ---- Boss 堡垒 + 核心 (phase 2) ----
def build_boss():
    F = foes.resize((foes.width // 2, foes.height // 2), Image.BOX)
    fort = crop_box(F, (3, 51, 67, 120))                       # 红色要塞 64x69
    wall = fort.resize((96, 104), Image.BOX)                   # 等比 ≈ 96x104
    wall.save(os.path.join(OUT, "boss_wall.png"))
    core = crop_box(F, (153, 7, 183, 38)).resize((26, 27), Image.BOX)
    tex = Image.new("RGBA", (56, 28), (0, 0, 0, 0))
    tex.paste(core, (1, 0), core)                              # 帧0 = 关闭
    glow = core.copy()
    gp = glow.load()
    for y in range(6, 21):                                     # 帧1 = 核心发光
        for x in range(6, 20):
            r, g, b, a = gp[x, y]
            if a > 0:
                gp[x, y] = (min(255, r + 120), max(0, g - 60), max(0, b - 60), a)
    tex.paste(glow, (29, 0), glow)                             # 帧1
    tex.save(os.path.join(OUT, "boss_core.png"))

if __name__ == "__main__":
    build_all()
