#!/usr/bin/env python3
"""预渲染游戏内文案为 PNG (金色像素字+深色描边), 输出到 assets/text/"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "text")
os.makedirs(OUT, exist_ok=True)

FONT_CANDIDATES = [
    ("/System/Library/Fonts/PingFang.ttc", 0),
    ("/System/Library/Fonts/Hiragino Sans GB.ttc", 0),
    ("/System/Library/Fonts/Supplemental/Songti.ttc", 0),
]

def load_font(size):
    for path, idx in FONT_CANDIDATES:
        try:
            return ImageFont.truetype(path, size, index=idx)
        except Exception:
            continue
    raise RuntimeError("无可用中文字体")

MESSAGES = {
    # key: (文本, 字号, 颜色)
    "mission1":  ("MISSION 1  丛林", 18, (255, 224, 120)),
    "mission2":  ("MISSION 2  瀑布", 18, (255, 224, 120)),
    "mission3":  ("MISSION 3  雪原", 18, (200, 230, 255)),
    "mission4":  ("FINAL  巢穴", 18, (255, 130, 170)),
    "ending1":   ("MISSION ACCOMPLISHED", 20, (140, 255, 170)),
    "ending2":   ("THE  END", 26, (255, 224, 120)),
    "enrage":    ("核心暴走!", 18, (255, 90, 70)),
    "warning":   ("警  告 !", 20, (255, 90, 70)),
    "core_open": ("核心暴露!", 18, (255, 200, 90)),
    "clear":     ("任务完成!", 20, (140, 255, 150)),
    "gameover":  ("GAME OVER", 20, (255, 90, 70)),
    "eagle":     ("金鹰闪击!", 18, (255, 224, 120)),
    "oneup":     ("1UP !", 18, (130, 255, 140)),
    "swim":      ("按 K 跃出水面", 10, (170, 220, 255)),
    "title_hint":("P1 WASD移动  J射击 K跳跃   S卧倒  M静音", 9, (200, 214, 255)),
    "title_hint_2p":("P1 WASD移动  J射击 K跳跃\nP2 方向键移动  X射击 Z跳跃", 9, (200, 214, 255)),
    "title_cheat":("秘技发动!  初始生命 30", 12, (255, 224, 120)),
    "title_start":("PRESS ENTER", 20, (255, 255, 255)),
}

def render(key, text, size, color):
    font = load_font(size)
    pad = 8
    # 先量尺寸
    tmp = Image.new("RGBA", (10, 10))
    d = ImageDraw.Draw(tmp)
    box = d.multiline_textbbox((0, 0), text, font=font, spacing=1, align="center")
    w = int(box[2] - box[0] + pad * 2)
    h = int(box[3] - box[1] + pad * 2)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ox, oy = pad - box[0], pad - box[1]
    for gx in (-2, -1, 0, 1, 2):          # 8向描边
        for gy in (-2, -1, 0, 1, 2):
            if gx or gy:
                d.multiline_text((ox + gx, oy + gy), text, font=font, spacing=1,
                                 align="center", fill=(24, 16, 20, 255))
    d.multiline_text((ox, oy), text, font=font, spacing=1, align="center", fill=color + (255,))
    img.save(os.path.join(OUT, key + ".png"))
    print(f"  {key:14s} {w}x{h}")

if __name__ == "__main__":
    print("生成文案 →", OUT)
    for k, v in MESSAGES.items():
        render(k, *v)
    print("完成")
