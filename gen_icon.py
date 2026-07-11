#!/usr/bin/env python3
"""Generate elegant water drop app icon"""

from PIL import Image, ImageDraw
import math
import os

SIZES = {
    "icon_16x16.png": 16,
    "icon_16x16@2x.png": 32,
    "icon_32x32.png": 32,
    "icon_32x32@2x.png": 64,
    "icon_128x128.png": 128,
    "icon_128x128@2x.png": 256,
    "icon_256x256.png": 256,
    "icon_256x256@2x.png": 512,
    "icon_512x512.png": 512,
    "icon_512x512@2x.png": 1024,
}


def draw_water_drop(draw, cx, cy, r):
    """Draw an elegant water drop shape"""
    # Water drop is like a teardrop: pointed top, rounded bottom
    # We'll draw it as a bezier-like shape using arcs and lines

    # The main body: a circle at the bottom plus a triangle at the top
    top_point = (cx, cy - r * 0.85)
    bottom = cy + r * 0.5

    # Draw gradient from top to bottom
    steps = 100
    for i in range(steps):
        t = i / steps
        y = top_point[1] + (bottom - top_point[1]) * t

        # Width at this height: narrow at top, wide at middle, slightly narrow at bottom
        # Normalized height from 0 to 1
        h_norm = t
        width_factor = math.sin(h_norm * math.pi) * 0.95
        if h_norm < 0.1:
            width_factor = h_norm / 0.1 * 0.3  # Sharp point at top
        elif h_norm > 0.85:
            width_factor *= (1 - (h_norm - 0.85) / 0.15 * 0.15)  # Slightly narrow at bottom

        half_w = r * width_factor * 0.9

        # Color gradient: warm blue to soft teal
        # Top: slightly warmer, bottom: cooler
        r_val = int(80 + t * 30)
        g_val = int(160 + t * 40)
        b_val = int(220 - t * 30)
        a_val = max(1, int(255 * (1 - t * 0.05)))

        color = (r_val, g_val, b_val, a_val)
        draw.line([(cx - half_w, y), (cx + half_w, y)], fill=color, width=1)

    # Draw a subtle highlight (shine)
    highlight_cx = cx - r * 0.25
    highlight_cy = cy + r * 0.1
    highlight_r = r * 0.25

    for i in range(10):
        t = i / 10
        hr = highlight_r * (1 - t * 0.3)
        alpha = int(80 * (1 - t))
        if alpha <= 0:
            continue
        draw.ellipse(
            [
                highlight_cx - hr,
                highlight_cy - hr,
                highlight_cx + hr,
                highlight_cy + hr,
            ],
            fill=(255, 255, 255, alpha),
        )

    # Add a small sparkle
    sparkle_x = cx + r * 0.3
    sparkle_y = cy - r * 0.3
    sparkle_r = r * 0.06
    draw.ellipse(
        [
            sparkle_x - sparkle_r,
            sparkle_y - sparkle_r,
            sparkle_x + sparkle_r,
            sparkle_y + sparkle_r,
        ],
        fill=(255, 255, 255, 180),
    )


def main():
    iconset_dir = "/Applications/water/WaterReminder.iconset"
    os.makedirs(iconset_dir, exist_ok=True)

    for filename, size in SIZES.items():
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img, "RGBA")

        # Draw rounded rect background (soft, warm)
        padding = size // 8
        r = (size - 2 * padding) // 2
        cx, cy = size // 2, size // 2

        # Soft background glow
        glow_r = r * 1.2
        for i in range(20):
            t = i / 20
            gr = glow_r * (1 - t * 0.1)
            alpha = int(15 * (1 - t))
            if alpha <= 0:
                continue
            draw.ellipse(
                [cx - gr, cy - gr + r * 0.1, cx + gr, cy + gr + r * 0.1],
                fill=(150, 200, 255, alpha),
            )

        draw_water_drop(draw, cx, cy, r)

        img.save(os.path.join(iconset_dir, filename))
        print(f"  {filename}: {size}x{size}")

    # Convert to .icns
    icns_path = "/Applications/water/WaterReminder.app/Contents/Resources/WaterReminder.icns"
    os.system(f"iconutil -c icns {iconset_dir} -o {icns_path}")
    print(f"\nicns created: {icns_path}")

    # Also generate a high-res PNG for preview
    preview = Image.open(os.path.join(iconset_dir, "icon_512x512@2x.png"))
    preview.save("/Applications/water/icon_preview.png")
    print("Preview saved: icon_preview.png")


if __name__ == "__main__":
    main()
