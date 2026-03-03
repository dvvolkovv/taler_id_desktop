#!/usr/bin/env python3
"""Generate TID notification and CallKit icons from the main app icon."""

import os
import json
from PIL import Image, ImageDraw, ImageFont

PROJECT = os.path.dirname(os.path.abspath(__file__))
ANDROID_RES = os.path.join(PROJECT, 'android', 'app', 'src', 'main', 'res')
IOS_ASSETS = os.path.join(PROJECT, 'ios', 'Runner', 'Assets.xcassets')

WHITE = (255, 255, 255)

# Bold rounded font for "TID" text
FONT_PATH = '/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf'
FALLBACK_FONT = '/System/Library/Fonts/Supplemental/Arial Bold.ttf'


def get_font(size):
    """Load a bold rounded font, with fallback."""
    for path in [FONT_PATH, FALLBACK_FONT]:
        try:
            return ImageFont.truetype(path, size)
        except (OSError, IOError):
            continue
    return ImageFont.load_default()


def make_tid_silhouette(size):
    """Generate white 'TID' text on transparent background."""
    # Render at 4x for anti-aliasing
    render_s = size * 4
    img = Image.new('RGBA', (render_s, render_s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Find optimal font size to fill ~75% of the icon width
    font_size = int(render_s * 0.48)
    font = get_font(font_size)

    # Measure text and center it
    bbox = draw.textbbox((0, 0), 'TID', font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    x = (render_s - text_w) // 2 - bbox[0]
    y = (render_s - text_h) // 2 - bbox[1]

    draw.text((x, y), 'TID', fill=(*WHITE, 255), font=font)

    # Downscale with high-quality resampling
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
        icon = make_tid_silhouette(px)
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
        icon = make_tid_silhouette(px)
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

    print('1. Generating Android notification icons (TID silhouette)...')
    make_notification_icons()

    print('\n2. Generating iOS CallKit icons (TID silhouette)...')
    make_callkit_icons()

    print('\n=== Done! Run: dart run flutter_launcher_icons ===')
