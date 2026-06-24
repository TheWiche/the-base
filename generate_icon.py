"""
Bonanza Base — App Icon Generator v2
Clean composition:
  - Solid amber background with rounded corners
  - White palm tree silhouette (trunk + 6 fronds)
  - Two stacked gold coins at the trunk base (referencing 'base' / fondo)
  - Proportions designed for small-screen legibility
"""

import math
from PIL import Image, ImageDraw, ImageFilter

SIZE    = 1024
HALF    = SIZE // 2
RADIUS  = 210  # corner radius

# Colors
AMBER       = (185, 100, 20)    # background amber
AMBER_DARK  = (150, 75, 10)     # shadow / depth
CREAM       = (255, 248, 235)   # palm tree fill
CREAM_DARK  = (230, 215, 190)   # trunk texture lines
GOLD        = (255, 205, 60)    # coin fill
GOLD_DARK   = (200, 155, 20)    # coin shadow / rim
GOLD_TEXT   = (160, 110, 10)    # coin symbol


# ── Helpers ───────────────────────────────────────────────────────────────────

def leaf_points(ox, oy, length, half_w, angle_deg, n=24):
    """Pointed oval leaf rotated to angle_deg (degrees from east/right)."""
    a = math.radians(angle_deg)
    ca, sa = math.cos(a), math.sin(a)
    pts = []
    for side in (1, -1):
        rng = range(n) if side == 1 else range(n - 1, -1, -1)
        for i in rng:
            t = i / (n - 1)
            # Along-leaf position (0 = base, 1 = tip)
            lx = t * length
            # Across-leaf: sine envelope, slightly tapered toward tip
            ly = side * math.sin(math.pi * t) * half_w * (1 - 0.25 * t)
            # Rotate
            rx = lx * ca - ly * sa
            ry = lx * sa + ly * ca
            pts.append((int(ox + rx), int(oy + ry)))
    return pts


def trunk_polygon(bx, by, tx, ty, bw, tw):
    """Tapered 4-sided trunk polygon. b=base, t=top, w=half-width."""
    # Perpendicular offset direction
    dx, dy = tx - bx, ty - by
    length = math.hypot(dx, dy)
    nx, ny = -dy / length, dx / length  # normal (perpendicular)
    return [
        (int(bx - nx * bw), int(by - ny * bw)),
        (int(bx + nx * bw), int(by + ny * bw)),
        (int(tx + nx * tw), int(ty + ny * tw)),
        (int(tx - nx * tw), int(ty - ny * tw)),
    ]


# ── Icon composition ──────────────────────────────────────────────────────────

def build_icon():
    # --- Canvas (RGBA for anti-aliasing trick) ---
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(canvas)

    # ── Background rounded square ────────────────────────────────────────────
    d.rounded_rectangle([0, 0, SIZE - 1, SIZE - 1], radius=RADIUS, fill=AMBER + (255,))

    # Subtle inner highlight at top (very light, unobtrusive)
    hl = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hl)
    hd.rounded_rectangle([0, 0, SIZE - 1, SIZE // 3],
                          radius=RADIUS, fill=(255, 200, 100, 35))
    canvas.alpha_composite(hl)

    d = ImageDraw.Draw(canvas)   # refresh draw reference

    # ── Palm tree positioning ────────────────────────────────────────────────
    # Crown center (slightly left of center for natural lean)
    cx, cy   = HALF - 20, 310
    # Trunk base
    bx, by   = HALF + 10, 740

    # ── Fronds (6 main leaves) ───────────────────────────────────────────────
    fronds = [
        # angle, length, half_width
        (  5,  310, 46),   # far right, slight droop
        ( 38,  285, 42),   # upper right
        ( 72,  265, 40),   # near vertical right
        (100,  255, 40),   # near vertical left
        (138,  270, 42),   # upper left
        (170,  295, 44),   # far left
        (-28,  265, 38),   # drooping right
        (-160, 255, 38),   # drooping left
    ]

    for angle, length, hw in fronds:
        pts = leaf_points(cx, cy, length, hw, angle)
        # Subtle shadow under each frond
        shadow_pts = [(x + 6, y + 8) for x, y in pts]
        d.polygon(shadow_pts, fill=AMBER_DARK + (120,))
        d.polygon(pts, fill=CREAM + (255,))

    # ── Trunk ────────────────────────────────────────────────────────────────
    trunk = trunk_polygon(bx, by, cx, cy, bw=36, tw=18)
    # Trunk shadow
    shadow_trunk = [(x + 7, y + 7) for x, y in trunk]
    d.polygon(shadow_trunk, fill=AMBER_DARK + (140,))
    d.polygon(trunk, fill=CREAM + (255,))

    # Trunk texture (subtle horizontal bands)
    for step in range(7):
        t = (step + 0.5) / 7           # 0..1 along trunk
        # Interpolate position
        lx = int(bx * (1 - t) + cx * t)
        ly = int(by * (1 - t) + cy * t)
        # Interpolate half-width
        hw = 36 * (1 - t) + 18 * t
        # Perpendicular to trunk
        dx, dy = cx - bx, cy - by
        ln = math.hypot(dx, dy)
        nx, ny = -dy / ln, dx / ln
        x0 = int(lx - nx * (hw - 5))
        y0 = int(ly - ny * (hw - 5))
        x1 = int(lx + nx * (hw - 5))
        y1 = int(ly + ny * (hw - 5))
        d.line([(x0, y0), (x1, y1)], fill=CREAM_DARK + (200,), width=4)

    # ── Coins (stacked, at trunk base) ───────────────────────────────────────
    # Two coins: back coin slightly right and lower, front coin centered
    coins = [
        (bx + 54, by + 38, 68),   # back-right
        (bx - 54, by + 38, 68),   # back-left
        (bx,      by + 22, 72),   # front center
    ]

    for (coin_x, coin_y, cr) in coins:
        # Shadow
        d.ellipse([coin_x - cr, coin_y - cr // 3 + 14,
                   coin_x + cr, coin_y + cr // 3 + 14],
                  fill=GOLD_DARK + (160,))
        # Coin body (ellipse for 3D feel)
        d.ellipse([coin_x - cr, coin_y - cr // 3,
                   coin_x + cr, coin_y + cr // 3],
                  fill=GOLD + (255,))
        # Rim
        d.ellipse([coin_x - cr + 7, coin_y - cr // 3 + 5,
                   coin_x + cr - 7, coin_y + cr // 3 - 5],
                  outline=GOLD_DARK + (220,), width=4)

    # $ symbol on front coin
    fx, fy, _ = coins[2]
    # Draw a simple $ sign using lines
    sign_size = 34
    sx, sy = fx - sign_size // 3, fy - sign_size // 2
    d.text((sx, sy), "$", fill=GOLD_TEXT + (230,))

    # ── Convert to flat RGB and save ─────────────────────────────────────────
    bg = Image.new("RGB", (SIZE, SIZE), (255, 255, 255))
    bg.paste(canvas, mask=canvas.split()[3])

    out = r"C:\Users\cotes\Documents\Bonanza\assets\icon\app_icon.png"
    import os; os.makedirs(os.path.dirname(out), exist_ok=True)
    bg.save(out, "PNG", optimize=True)
    print(f"Icon saved: {out}")


build_icon()
