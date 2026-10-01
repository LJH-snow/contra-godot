#!/usr/bin/env python3
"""魂斗罗音效/音乐生成器 — 纯 Python 合成 8-bit 风格 WAV (44100Hz 16bit mono)"""
import os, struct, wave, math, random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "audio")
os.makedirs(OUT, exist_ok=True)
SR = 44100
random.seed(42)

# ---------------- 合成器 ----------------
def write_wav(name, samples):
    samples = [max(-1.0, min(1.0, s)) for s in samples]
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32000)) for s in samples))
    print(f"  {name:22s} {len(samples)/SR:.2f}s")

def square(f, duty=0.5):
    return 1.0 if (f % 1.0) < duty else -1.0
def tri(f):
    p = f % 1.0
    return 4 * abs(p - 0.5) - 1
def saw(f):
    return 2 * (f % 1.0) - 1
def noise():
    return random.uniform(-1, 1)

def env_ad(n, a, d):
    """attack(0~1) + 指数衰减 环境"""
    e = []
    na = max(1, int(a * SR)); nd = max(1, int(d * SR))
    for i in range(na): e.append(i / na)
    k = math.exp(-5.0 / nd)
    v = 1.0
    for i in range(n): e.append(v); v *= k
    return e[:n]

def tone(freq, dur, vol=0.5, wavef=square, duty=0.5, a=0.005, decay=None, glide=0.0):
    n = int(dur * SR); out = []
    ph = 0.0
    df = glide / n if n else 0
    for i in range(n):
        f = freq + df * i
        ph += f / SR
        if wavef == square: s = square(ph, duty)
        elif wavef == tri: s = tri(ph)
        elif wavef == saw: s = saw(ph)
        else: s = noise()
        out.append(s * vol)
    e = env_ad(n, a, decay if decay else dur)
    return [o * ee for o, ee in zip(out, e)]

def noise_burst(dur, vol=0.5, lp=0.3, a=0.002):
    """低通噪声(用衰减式滑动平均近似)"""
    n = int(dur * SR); out = []; prev = 0.0
    for i in range(n):
        prev = prev * lp + noise() * (1 - lp)
        out.append(prev * vol)
    e = env_ad(n, a, dur)
    return [o * ee for o, ee in zip(out, e)]

def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, s in enumerate(t): out[i] += s
    return out

def seq(notes, vol=0.5, wavef=square, duty=0.5):
    """notes: [(midi或0=休止, 时长秒), ...]"""
    out = []
    for m, d in notes:
        if m == 0: out += [0.0] * int(d * SR)
        else:
            f = 440.0 * 2 ** ((m - 69) / 12)
            out += tone(f, d, vol, wavef, duty, a=0.004, decay=d * 0.9)
    return out

# ---------------- 音效 ----------------
def sfx():
    write_wav("sfx_shoot.wav", tone(880, 0.07, 0.35, square, 0.35, glide=-500, decay=0.06))
    write_wav("sfx_spread.wav", mix(tone(620, 0.09, 0.3, square, 0.4, glide=-350, decay=0.08),
                                    noise_burst(0.05, 0.12, 0.5)))
    write_wav("sfx_laser.wav", tone(1500, 0.14, 0.35, saw, glide=-1300, decay=0.13))
    write_wav("sfx_fire.wav", mix(tone(300, 0.16, 0.25, tri, glide=140, decay=0.15),
                                  noise_burst(0.12, 0.2, 0.15)))
    write_wav("sfx_jump.wav", tone(170, 0.12, 0.3, square, 0.3, glide=260, decay=0.11))
    write_wav("sfx_explode.wav", mix(noise_burst(0.32, 0.55, 0.08), tone(90, 0.25, 0.4, tri, glide=-40, decay=0.24)))
    write_wav("sfx_explode_big.wav", mix(noise_burst(0.7, 0.6, 0.05), tone(65, 0.6, 0.5, tri, glide=-30, decay=0.55),
                                         tone(45, 0.7, 0.4, tri, decay=0.6)))
    write_wav("sfx_item.wav", mix(tone(1200, 0.12, 0.3, square, 0.3, decay=0.11),
                                  tone(1800, 0.06, 0.15, square, 0.2), noise_burst(0.08, 0.2, 0.4)))
    ar = seq([(72, 0.07), (76, 0.07), (79, 0.07), (84, 0.14)], vol=0.4)
    write_wav("sfx_powerup.wav", ar + tone(440 * 2 ** ((88 - 69) / 12), 0.18, 0.15, square, 0.25, decay=0.17))
    write_wav("sfx_death.wav", mix(seq([(69, 0.09), (65, 0.09), (62, 0.09), (57, 0.3)], vol=0.4),
                                   noise_burst(0.5, 0.3, 0.07)))
    write_wav("sfx_clang.wav", mix(tone(520, 0.07, 0.3, square, 0.2, decay=0.06),
                                   tone(507, 0.07, 0.25, square, 0.2, decay=0.06)))
    write_wav("sfx_bosshit.wav", mix(tone(260, 0.09, 0.35, square, 0.3, glide=-60, decay=0.08),
                                     noise_burst(0.06, 0.15, 0.3)))
    write_wav("sfx_clear.wav", seq([(69, 0.12), (72, 0.12), (76, 0.12), (81, 0.2), (79, 0.12), (81, 0.44)], vol=0.42)
              + [0.0] * int(0.2 * SR))
    write_wav("sfx_start.wav", seq([(60, 0.08), (67, 0.08), (72, 0.16)], vol=0.4))
    write_wav("sfx_konami.wav", seq([(76, 0.09), (81, 0.09), (88, 0.22)], vol=0.4))
    write_wav("sfx_eagle.wav", mix(seq([(81, 0.06), (84, 0.06), (88, 0.06), (93, 0.3)], vol=0.35),
                                   noise_burst(0.4, 0.2, 0.1)))

# ---------------- 音乐 ----------------
def midi(m): return 440.0 * 2 ** ((m - 69) / 12)

def drum_track(bars, bp, pattern_kick, pattern_snare, hat=True):
    """按小节生成鼓"""
    out = []
    for b in range(bars):
        for beat in range(4):
            if pattern_kick[beat % len(pattern_kick)]:
                out += tone(60, 0.1, 0.5, tri, glide=-25, decay=0.09)
                out[-int(0.1 * SR):] = out[-int(0.1 * SR):]
                pad = 0
            else:
                pad = 0
            # 对齐到拍长
            tgt = int((b * 4 + beat + 1) * bp * SR)
            while len(out) < tgt: out.append(0.0)
            if pattern_snare[beat % len(pattern_snare)]:
                sb = noise_burst(0.09, 0.3, 0.25)
                pos = int((b * 4 + beat) * bp * SR)
                for i, s in enumerate(sb):
                    if pos + i < len(out): out[pos + i] += s
            if hat:
                hb = noise_burst(0.03, 0.08, 0.7)
                for half in range(2):
                    pos = int((b * 4 + beat + half * 0.5) * bp * SR)
                    for i, s in enumerate(hb):
                        if pos + i < len(out): out[pos + i] += s
    return out

def place(dest, src, t):
    pos = int(t * SR)
    need = pos + len(src)
    if need > len(dest): dest += [0.0] * (need - len(dest))
    for i, s in enumerate(src): dest[pos + i] += s
    return dest

def music_stage():
    """原创作曲: A小调 进行曲风格 16小节 循环 (160bpm)"""
    bpm = 160; bp = 60.0 / bpm; ep = bp / 2
    total = 16 * 4 * bp
    out = [0.0] * int(total * SR)

    roots = [45, 45, 41, 41, 43, 43, 40, 40, 45, 45, 41, 41, 43, 43, 45, 45]  # A2 F2 G2 E2...
    # 贝斯: 每小节 8 个八分音符 根音+五度交替
    for bar, r in enumerate(roots):
        for e in range(8):
            n = r if e % 2 == 0 else r + 7
            if e % 4 == 3: n = r + 12
            s = tone(midi(n), ep * 0.92, 0.24, square, 0.5, a=0.003, decay=ep * 0.8)
            place(out, s, (bar * 4) * bp + e * ep)

    # 主旋律 (高音方波 25%占空比)
    mel = [
        # 第1-2小节: A小调琶音冲锋
        [(69,2),(72,1),(76,1),(81,2),(79,1),(76,1)],
        [(77,2),(76,1),(74,1),(76,2),(74,1),(71,1)],
        # 第3-4小节
        [(67,2),(71,1),(74,1),(79,2),(77,1),(74,1)],
        [(76,3),(74,1),(72,2),(69,2)],
        # 第5-6小节 上行
        [(69,1),(72,1),(76,1),(81,1),(84,2),(81,1),(76,1)],
        [(77,1),(81,1),(84,2),(81,1),(77,1),(76,1),(74,1)],
        # 第7-8小节
        [(74,2),(71,2),(67,2),(71,2)],
        [(64,2),(67,1),(71,1),(76,4)],
        # 第9-12小节 重复主题
        [(69,2),(72,1),(76,1),(81,2),(79,1),(76,1)],
        [(77,2),(76,1),(74,1),(76,2),(74,1),(71,1)],
        [(67,2),(71,1),(74,1),(79,2),(77,1),(74,1)],
        [(76,3),(74,1),(72,2),(69,2)],
        # 第13-16小节 高潮收尾
        [(81,2),(79,2),(76,2),(72,2)],
        [(74,2),(77,2),(81,2),(84,2)],
        [(83,2),(81,2),(79,2),(76,2)],
        [(77,1),(76,1),(74,1),(72,1),(69,4)],
    ]
    t = 0.0
    for bar in range(16):
        for (n, d) in mel[bar]:
            if n:
                s = tone(midi(n), ep * d * 0.95, 0.3, square, 0.25, a=0.004, decay=ep * d * 0.75)
                place(out, s, t)
            t += ep * d

    # 副旋律(低八度回声, 弱)
    t = 0.0
    for bar in range(16):
        for (n, d) in mel[bar]:
            if n and bar % 2 == 1:
                s = tone(midi(n - 12), ep * d * 0.9, 0.1, square, 0.5, a=0.004, decay=ep * d * 0.7)
                place(out, s, t)
            t += ep * d

    # 鼓
    for bar in range(16):
        for beat in range(4):
            tt = (bar * 4 + beat) * bp
            if beat % 2 == 0:
                place(out, tone(55, 0.12, 0.42, tri, glide=-20, decay=0.1), tt)
            else:
                place(out, noise_burst(0.08, 0.2, 0.3), tt)
            for half in range(2):
                place(out, noise_burst(0.025, 0.05, 0.75), tt + half * bp / 2)

    write_wav("music_stage.wav", out)

def music_title():
    """标题: 沉稳琶音循环 8小节 100bpm"""
    bpm = 100; bp = 60.0 / bpm; ep = bp / 2
    total = 8 * 4 * bp
    out = [0.0] * int(total * SR)
    chords = [[45,52,57,60],[41,48,53,57],[43,50,55,59],[40,47,52,55]] * 2   # Am F G E
    for bar, ch in enumerate(chords):
        for e in range(8):
            n = ch[e % 4] + (12 if e >= 4 else 0)
            place(out, tone(midi(n), ep * 0.9, 0.16, square, 0.5, a=0.004, decay=ep * 0.8),
                  (bar * 4) * bp + e * ep)
        place(out, tone(midi(ch[0] - 12), bp * 3.8, 0.25, tri, decay=bp * 3), (bar * 4) * bp)
        for beat in range(4):
            place(out, noise_burst(0.02, 0.035, 0.8), (bar * 4 + beat) * bp + bp / 2)
    write_wav("music_title.wav", out)

if __name__ == "__main__":
    print("生成音频 →", OUT)
    sfx(); music_stage(); music_title()
    print("完成")
