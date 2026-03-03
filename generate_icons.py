#!/usr/bin/env python3
"""Generate all TalerID app icons: main icon, Android notification, iOS CallKit."""

import os
import json
import math
from PIL import Image, ImageDraw, ImageFilter
import numpy as np

PROJECT = os.path.dirname(os.path.abspath(__file__))
ANDROID_RES = os.path.join(PROJECT, 'android', 'app', 'src', 'main', 'res')
IOS_ASSETS = os.path.join(PROJECT, 'ios', 'Runner', 'Assets.xcassets')

# --- Brand Colors ---
NAVY = (10, 22, 40)
NAVY_LIGHTER = (20, 40, 65)
TEAL_LIGHT = (20, 184, 166)
TEAL_MID = (16, 166, 150)
TEAL_DARK = (13, 148, 136)
TEAL_BRIGHT = (40, 210, 190)
GOLD = (251, 191, 36)
WHITE = (255, 255, 255)

RENDER_SIZE = 4096
OUTPUT_SIZE = 1024


def make_shield_points(cx, cy, half_w, half_h):
    """Generate shield polygon points (flat top, pointed bottom)."""
    top_y = cy - half_h
    mid_y = cy + int(half_h * 0.3)
    bot_y = cy + half_h

    points = []
    corner_r = int(half_w * 0.18)

    # Top edge (left to right)
    points.append((cx - half_w + corner_r, top_y))
    points.append((cx + half_w - corner_r, top_y))

    # Top-right corner
    for angle in range(0, 91, 5):
        rad = math.radians(angle)
        px = cx + half_w - corner_r + int(corner_r * math.sin(rad))
        py = top_y + corner_r - int(corner_r * math.cos(rad))
        points.append((px, py))

    # Right side down to mid, then to bottom point
    points.append((cx + half_w, mid_y))
    points.append((cx, bot_y))
    points.append((cx - half_w, mid_y))

    # Top-left corner
    for angle in range(90, -1, -5):
        rad = math.radians(angle)
        px = cx - half_w + corner_r - int(corner_r * math.sin(rad))
        py = top_y + corner_r - int(corner_r * math.cos(rad))
        points.append((px, py))

    return points


def draw_smooth_arc(draw, center, radius, start_deg, end_deg, color, width):
    """Draw a smooth arc using line segments for better anti-aliasing."""
    points = []
    steps = max(60, int(abs(end_deg - start_deg) * 2))
    for i in range(steps + 1):
        t = i / steps
        angle = math.radians(start_deg + (end_deg - start_deg) * t)
        x = center[0] + radius * math.cos(angle)
        y = center[1] + radius * math.sin(angle)
        points.append((x, y))

    if len(points) >= 2:
        draw.line(points, fill=color, width=width, joint='curve')


def make_main_icon():
    """Generate the primary 1024x1024 app icon."""
    S = RENDER_SIZE
    cx, cy = S // 2, S // 2

    img = Image.new('RGBA', (S, S), (*NAVY, 255))

    y_coords, x_coords = np.mgrid[0:S, 0:S]

    # --- Layer 1: Radial background gradient ---
    bg_arr = np.zeros((S, S, 4), dtype=np.uint8)
    dist = np.sqrt((x_coords - cx) ** 2 + (y_coords - (cy - S * 0.03)) ** 2)
    max_dist = S * 0.55
    t = np.clip(1.0 - dist / max_dist, 0, 1) ** 1.2
    bg_arr[:, :, 0] = (NAVY_LIGHTER[0] * t).astype(np.uint8)
    bg_arr[:, :, 1] = (NAVY_LIGHTER[1] * t).astype(np.uint8)
    bg_arr[:, :, 2] = (NAVY_LIGHTER[2] * t).astype(np.uint8)
    bg_arr[:, :, 3] = (50 * t).astype(np.uint8)
    img = Image.alpha_composite(img, Image.fromarray(bg_arr, 'RGBA'))

    # --- Layer 2: Strong ambient teal glow ---
    glow_arr = np.zeros((S, S, 4), dtype=np.uint8)
    glow_cy = cy - int(S * 0.01)
    dist_glow = np.sqrt((x_coords - cx) ** 2 + (y_coords - glow_cy) ** 2)
    glow_radius = S * 0.42
    t_glow = np.clip(1.0 - dist_glow / glow_radius, 0, 1) ** 1.8
    glow_arr[:, :, 0] = (TEAL_LIGHT[0] * t_glow).astype(np.uint8)
    glow_arr[:, :, 1] = (TEAL_LIGHT[1] * t_glow).astype(np.uint8)
    glow_arr[:, :, 2] = (TEAL_LIGHT[2] * t_glow).astype(np.uint8)
    glow_arr[:, :, 3] = (55 * t_glow).astype(np.uint8)
    img = Image.alpha_composite(img, Image.fromarray(glow_arr, 'RGBA'))

    # --- Layer 3: Shield filled with gradient ---
    shield_hw = int(S * 0.26)
    shield_hh = int(S * 0.29)
    shield_pts = make_shield_points(cx, cy, shield_hw, shield_hh)

    shield_mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(shield_mask).polygon(shield_pts, fill=255)
    mask_arr = np.array(shield_mask).astype(np.float64) / 255.0

    # Gradient: teal top → darker teal bottom
    shield_layer = np.zeros((S, S, 4), dtype=np.uint8)
    y_norm = np.linspace(0, 1, S).reshape(-1, 1)
    shield_layer[:, :, 0] = np.broadcast_to(
        (TEAL_LIGHT[0] + (TEAL_DARK[0] - TEAL_LIGHT[0]) * y_norm).astype(np.uint8), (S, S))
    shield_layer[:, :, 1] = np.broadcast_to(
        (TEAL_LIGHT[1] + (TEAL_DARK[1] - TEAL_LIGHT[1]) * y_norm).astype(np.uint8), (S, S))
    shield_layer[:, :, 2] = np.broadcast_to(
        (TEAL_LIGHT[2] + (TEAL_DARK[2] - TEAL_LIGHT[2]) * y_norm).astype(np.uint8), (S, S))
    shield_layer[:, :, 3] = (mask_arr * 255).astype(np.uint8)
    img = Image.alpha_composite(img, Image.fromarray(shield_layer, 'RGBA'))

    # --- Layer 4: Inner dark cutout (thinner border - only 6% inset) ---
    inner_hw = int(shield_hw * 0.92)
    inner_hh = int(shield_hh * 0.92)
    inner_pts = make_shield_points(cx, cy, inner_hw, inner_hh)

    inner_mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(inner_mask).polygon(inner_pts, fill=255)
    inner_mask_arr = np.array(inner_mask).astype(np.float64) / 255.0

    # Dark fill with slight teal tint for depth
    inner_arr = np.zeros((S, S, 4), dtype=np.uint8)
    inner_arr[:, :, 0] = 12
    inner_arr[:, :, 1] = 26
    inner_arr[:, :, 2] = 46
    inner_arr[:, :, 3] = (inner_mask_arr * 240).astype(np.uint8)
    img = Image.alpha_composite(img, Image.fromarray(inner_arr, 'RGBA'))

    # --- Layer 5: Fingerprint pattern (clean, horizontal elliptical arcs) ---
    fp_layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    fp_draw = ImageDraw.Draw(fp_layer)

    fp_cx = cx
    fp_cy = cy + int(S * 0.01)
    stroke = max(4, int(S * 0.006))

    # Draw elliptical arcs (wider than tall = fingerprint look, not WiFi circles)
    # Each "ridge" is a section of an ellipse
    # Ridges stack vertically, center ones are tighter

    def draw_elliptical_arc(draw, center, rx, ry, start_deg, end_deg, color, width):
        """Draw an elliptical arc using line segments."""
        points = []
        steps = max(80, int(abs(end_deg - start_deg) * 2))
        for i in range(steps + 1):
            t = i / steps
            angle = math.radians(start_deg + (end_deg - start_deg) * t)
            x = center[0] + rx * math.cos(angle)
            y = center[1] + ry * math.sin(angle)
            points.append((x, y))
        if len(points) >= 2:
            draw.line(points, fill=color, width=width, joint='curve')

    # Fingerprint ridges - horizontal ellipses stacked vertically
    # Going outward from center, each one wider and taller
    ridges = [
        # (y_offset, rx, ry, start_deg, end_deg, alpha)
        # Innermost - tiny tight loop at center
        (-int(S * 0.020), int(S * 0.045), int(S * 0.018), 180, 360, 230),
        (int(S * 0.020), int(S * 0.045), int(S * 0.018), 0, 180, 230),
        # Second ring
        (-int(S * 0.045), int(S * 0.075), int(S * 0.025), 190, 350, 210),
        (int(S * 0.045), int(S * 0.075), int(S * 0.025), 10, 170, 210),
        # Third ring
        (-int(S * 0.075), int(S * 0.110), int(S * 0.032), 195, 345, 190),
        (int(S * 0.075), int(S * 0.110), int(S * 0.032), 15, 165, 190),
        # Fourth ring - wider
        (-int(S * 0.108), int(S * 0.148), int(S * 0.038), 198, 342, 170),
        (int(S * 0.108), int(S * 0.148), int(S * 0.038), 18, 162, 170),
        # Outermost
        (-int(S * 0.143), int(S * 0.180), int(S * 0.042), 200, 340, 140),
        (int(S * 0.143), int(S * 0.180), int(S * 0.042), 20, 160, 140),
    ]

    for y_off, rx, ry, start, end, alpha in ridges:
        draw_elliptical_arc(
            fp_draw, (fp_cx, fp_cy + y_off), rx, ry,
            start, end, (*TEAL_BRIGHT, alpha), stroke
        )

    # Clip fingerprint to inner shield area
    fp_clip_mask = Image.new('L', (S, S), 0)
    # Use slightly smaller area than inner shield for padding
    clip_hw = int(inner_hw * 0.90)
    clip_hh = int(inner_hh * 0.90)
    clip_pts = make_shield_points(cx, cy, clip_hw, clip_hh)
    ImageDraw.Draw(fp_clip_mask).polygon(clip_pts, fill=255)

    # Apply feathered clip
    fp_clip_mask = fp_clip_mask.filter(ImageFilter.GaussianBlur(radius=int(S * 0.005)))
    fp_layer.putalpha(
        Image.fromarray(
            np.minimum(np.array(fp_layer.split()[3]), np.array(fp_clip_mask)),
            'L'
        )
    )

    img = Image.alpha_composite(img, fp_layer)

    # --- Layer 6: Gold accent dot at center ---
    # Gold glow
    dot_glow_arr = np.zeros((S, S, 4), dtype=np.uint8)
    dot_dist = np.sqrt((x_coords - fp_cx) ** 2 + (y_coords - fp_cy) ** 2)
    glow_r = int(S * 0.05)
    dot_t = np.clip(1.0 - dot_dist / glow_r, 0, 1) ** 2
    dot_glow_arr[:, :, 0] = (GOLD[0] * dot_t).astype(np.uint8)
    dot_glow_arr[:, :, 1] = (GOLD[1] * dot_t).astype(np.uint8)
    dot_glow_arr[:, :, 2] = (GOLD[2] * dot_t).astype(np.uint8)
    dot_glow_arr[:, :, 3] = (100 * dot_t).astype(np.uint8)
    img = Image.alpha_composite(img, Image.fromarray(dot_glow_arr, 'RGBA'))

    # Solid gold dot
    dot_layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    dot_r = int(S * 0.022)
    ImageDraw.Draw(dot_layer).ellipse(
        (fp_cx - dot_r, fp_cy - dot_r, fp_cx + dot_r, fp_cy + dot_r),
        fill=(*GOLD, 255)
    )
    img = Image.alpha_composite(img, dot_layer)

    # --- Layer 7: Shield edge glow (soft) ---
    edge_layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(edge_layer).polygon(shield_pts, outline=(*TEAL_LIGHT, 140),
                                       width=max(3, int(S * 0.003)))
    edge_glow = edge_layer.filter(ImageFilter.GaussianBlur(radius=int(S * 0.012)))
    img = Image.alpha_composite(img, edge_glow)

    # Crisp thin edge line
    edge_sharp = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(edge_sharp).polygon(shield_pts, outline=(*TEAL_LIGHT, 100),
                                       width=max(2, int(S * 0.0015)))
    img = Image.alpha_composite(img, edge_sharp)

    # --- Layer 8: Subtle top highlight on shield border ---
    highlight = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    hl_draw = ImageDraw.Draw(highlight)
    # Draw just the top portion of the shield for a specular highlight
    top_y = cy - shield_hh
    hl_draw.line(
        [(cx - shield_hw + int(shield_hw * 0.18), top_y),
         (cx + shield_hw - int(shield_hw * 0.18), top_y)],
        fill=(*WHITE, 60), width=max(2, int(S * 0.003))
    )
    highlight = highlight.filter(ImageFilter.GaussianBlur(radius=int(S * 0.004)))
    img = Image.alpha_composite(img, highlight)

    # --- Downscale ---
    img = img.convert('RGB')
    img = img.resize((OUTPUT_SIZE, OUTPUT_SIZE), Image.LANCZOS)

    output_path = os.path.join(PROJECT, 'app_icon_1024.png')
    img.save(output_path, 'PNG')
    print(f'  Saved: {output_path} ({OUTPUT_SIZE}x{OUTPUT_SIZE})')
    return img


def make_silhouette(size):
    """Generate a white-on-transparent silhouette icon."""
    render_s = size * 4
    cx, cy = render_s // 2, render_s // 2

    img = Image.new('RGBA', (render_s, render_s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Filled shield (solid white)
    shield_hw = int(render_s * 0.34)
    shield_hh = int(render_s * 0.38)
    shield_pts = make_shield_points(cx, cy, shield_hw, shield_hh)
    draw.polygon(shield_pts, fill=(*WHITE, 255))

    # Cut out inner area (dark, leaving thin white border)
    inner_hw = int(shield_hw * 0.82)
    inner_hh = int(shield_hh * 0.82)
    inner_pts = make_shield_points(cx, cy, inner_hw, inner_hh)
    draw.polygon(inner_pts, fill=(0, 0, 0, 0))

    # Fingerprint elliptical arcs inside (simplified for small sizes)
    fp_cy = cy + int(render_s * 0.01)
    lw = max(2, render_s // 24)

    def draw_elliptical_arc_s(drw, center, rx, ry, start_deg, end_deg, color, width):
        points = []
        steps = max(40, int(abs(end_deg - start_deg)))
        for i in range(steps + 1):
            t = i / steps
            angle = math.radians(start_deg + (end_deg - start_deg) * t)
            x = center[0] + rx * math.cos(angle)
            y = center[1] + ry * math.sin(angle)
            points.append((x, y))
        if len(points) >= 2:
            drw.line(points, fill=color, width=width, joint='curve')

    # Simplified ridges for small icon
    small_ridges = [
        (-int(render_s * 0.03), int(render_s * 0.06), int(render_s * 0.022), 185, 355),
        (int(render_s * 0.03), int(render_s * 0.06), int(render_s * 0.022), 5, 175),
        (-int(render_s * 0.08), int(render_s * 0.11), int(render_s * 0.035), 195, 345),
        (int(render_s * 0.08), int(render_s * 0.11), int(render_s * 0.035), 15, 165),
        (-int(render_s * 0.13), int(render_s * 0.16), int(render_s * 0.042), 200, 340),
        (int(render_s * 0.13), int(render_s * 0.16), int(render_s * 0.042), 20, 160),
    ]
    for y_off, rx, ry, start, end in small_ridges:
        draw_elliptical_arc_s(draw, (cx, fp_cy + y_off), rx, ry,
                              start, end, (*WHITE, 255), lw)

    # Central dot
    dot_r = max(2, render_s // 20)
    draw.ellipse((cx - dot_r, fp_cy - dot_r, cx + dot_r, fp_cy + dot_r),
                 fill=(*WHITE, 255))

    img = img.resize((size, size), Image.LANCZOS)
    return img


def make_notification_icons():
    """Generate Android notification icons for all densities."""
    densities = {
        'mdpi': 24, 'hdpi': 36, 'xhdpi': 48,
        'xxhdpi': 72, 'xxxhdpi': 96,
    }
    for density, px in densities.items():
        folder = os.path.join(ANDROID_RES, f'drawable-{density}')
        os.makedirs(folder, exist_ok=True)
        icon = make_silhouette(px)
        path = os.path.join(folder, 'ic_notification.png')
        icon.save(path, 'PNG')
        print(f'  Saved: {path} ({px}x{px})')


def make_callkit_icons():
    """Generate iOS CallKit icon set."""
    imageset_dir = os.path.join(IOS_ASSETS, 'CallKitLogo.imageset')
    os.makedirs(imageset_dir, exist_ok=True)

    scales = {
        'CallKitLogo.png': 40,
        'CallKitLogo@2x.png': 80,
        'CallKitLogo@3x.png': 120,
    }
    for filename, px in scales.items():
        icon = make_silhouette(px)
        path = os.path.join(imageset_dir, filename)
        icon.save(path, 'PNG')
        print(f'  Saved: {path} ({px}x{px})')

    contents = {
        "images": [
            {"idiom": "universal", "filename": "CallKitLogo.png", "scale": "1x"},
            {"idiom": "universal", "filename": "CallKitLogo@2x.png", "scale": "2x"},
            {"idiom": "universal", "filename": "CallKitLogo@3x.png", "scale": "3x"},
        ],
        "info": {"version": 1, "author": "xcode"},
        "properties": {"template-rendering-intent": "template"}
    }
    contents_path = os.path.join(imageset_dir, 'Contents.json')
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    print(f'  Saved: {contents_path}')


if __name__ == '__main__':
    print('=== TalerID Icon Generator ===\n')

    print('1. Generating main app icon (1024x1024)...')
    make_main_icon()

    print('\n2. Generating Android notification icons...')
    make_notification_icons()

    print('\n3. Generating iOS CallKit icons...')
    make_callkit_icons()

    print('\n=== Done! ===')
