#!/usr/bin/env python3
"""產生 examples/full 用的合成示意圖（非真實實驗數據，純為展示排版）。

依賴：Pillow（PIL）。執行：python3 make_figures.py
輸出：architecture.png / loss_curve.png / accuracy_curve.png
所有圖皆為小尺寸 PNG，避免 repo 肥大。
"""
import math
from PIL import Image, ImageDraw, ImageFont

W, H = 600, 380
BG = (255, 255, 255)
FG = (40, 40, 40)
ACCENT = (60, 90, 170)


def font(size):
    for path in (
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    ):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def centered(d, box, text, f, fill=FG):
    x0, y0, x1, y1 = box
    l, t, r, b = d.textbbox((0, 0), text, font=f)
    d.text(((x0 + x1 - (r - l)) / 2, (y0 + y1 - (b - t)) / 2 - t), text, font=f, fill=fill)


def architecture():
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    f = font(18)
    boxes = [("Input\n影像", 30), ("Backbone\n特徵抽取", 190), ("Head\n分類頭", 350), ("Output\n預測", 480)]
    y0, y1, bw = 150, 230, 100
    for i, (label, x) in enumerate(boxes):
        d.rectangle([x, y0, x + bw, y1], outline=ACCENT, width=3)
        lines = label.split("\n")
        for j, ln in enumerate(lines):
            centered(d, (x, y0 + 8 + j * 26, x + bw, y0 + 34 + j * 26), ln, f)
        if i < len(boxes) - 1:
            ax0 = x + bw
            ax1 = boxes[i + 1][1]
            ym = (y0 + y1) / 2
            d.line([ax0, ym, ax1, ym], fill=FG, width=2)
            d.polygon([(ax1, ym), (ax1 - 10, ym - 5), (ax1 - 10, ym + 5)], fill=FG)
    centered(d, (0, 40, W, 80), "模型整體架構（示意）", font(22))
    img.save("architecture.png", optimize=True)


def curve(fname, title, fn, ylabel):
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)
    f = font(16)
    ox, oy, pw, ph = 70, 300, 480, 220
    d.line([ox, oy, ox + pw, oy], fill=FG, width=2)
    d.line([ox, oy, ox, oy - ph], fill=FG, width=2)
    pts = []
    n = 60
    for i in range(n + 1):
        t = i / n
        v = fn(t)
        pts.append((ox + t * pw, oy - v * ph))
    d.line(pts, fill=ACCENT, width=3)
    centered(d, (0, 20, W, 55), title, font(22))
    d.text((ox - 30, oy - ph - 10), ylabel, font=f, fill=FG)
    d.text((ox + pw - 60, oy + 8), "Epoch", font=f, fill=FG)
    img.save(fname, optimize=True)


if __name__ == "__main__":
    architecture()
    curve("loss_curve.png", "訓練損失曲線（示意）", lambda t: 0.9 * math.exp(-3 * t) + 0.05, "Loss")
    curve("accuracy_curve.png", "驗證正確率曲線（示意）", lambda t: 0.95 * (1 - math.exp(-3.2 * t)), "Acc")
    print("done: architecture.png, loss_curve.png, accuracy_curve.png")
