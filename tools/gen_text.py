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
    "warning":   ("警  告 !", 20, (255, 90, 70)),
    "core_open": ("核心暴露!", 18, (255, 200, 90)),
    "clear":     ("任务完成!", 20, (140, 255, 150)),
    "gameover":  ("GAME OVER", 20, (255, 90, 70)),
    "eagle":     ("金鹰闪击!", 18, (255, 224, 120)),
    "title_hint":("方向键移动  Z跳  X射击  下卧倒  M静音", 11, (200, 214, 255)),
    "title_cheat":("秘技发动!  初始生命 30", 13, (255, 224, 120)),
    "title_start":("PRESS ENTER", 20, (255, 255, 255)),
}

def render(key, text, size, color):
    font = load_font(size)
    pad = 8
    # 先量尺寸
    tmp = Image.new("RGBA", (10, 10))
    d = ImageDraw.Draw(tmp)
    box = d.textbbox((0, 0), text, font=font)
    w, h = box[2] - box[0] + pad * 2, box[3] - box[1] + pad * 2
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ox, oy = pad - box[0], pad - box[1]
    for gx in (-2, -1, 0, 1, 2):          # 8向描边
        for gy in (-2, -1, 0, 1, 2):
            if gx or gy:
                d.text((ox + gx, oy + gy), text, font=font, fill=(24, 16, 20, 255))
    d.text((ox, oy), text, font=font, fill=color + (255,))
    img.save(os.path.join(OUT, key + ".png"))
    print(f"  {key:14s} {w}x{h}")

if __name__ == "__main__":
    print("生成文案 →", OUT)
    for k, v in MESSAGES.items():
        render(k, *v)
    print("完成")
