"""Contact sheet of every v0.77 item icon (base beside Legendary), to check the item art.

Usage (from the repo root):  python3 godot/tools/item_art_sheet.py [out.png]
Reads godot/data/item-art-manifest.json. Missing icons show as a red "missing" tile; also prints
the missing files and any icon that isn't 320x320 RGBA with a transparent corner.
"""
import json, os, sys
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
rows = json.load(open(os.path.join(ROOT, "godot/data/item-art-manifest.json")))
TILE, PAD = 96, 8
pairs = []
for r in rows:
    if r["id"].startswith("leg_"):
        continue
    leg = next((x for x in rows if x["id"] == "leg_" + r["id"]), None)
    pairs.append((r, leg))
cols = 6
lines = (len(pairs) + cols - 1) // cols
sheet = Image.new("RGBA", (cols * (TILE * 2 + PAD * 3), lines * (TILE + 28 + PAD)), (24, 20, 34, 255))
draw = ImageDraw.Draw(sheet)
missing, bad = [], []

def tile(entry, x, y):
    path = os.path.join(ROOT, entry["file"])
    if not os.path.exists(path):
        missing.append(entry["file"])
        draw.rectangle((x, y, x + TILE, y + TILE), outline=(255, 80, 80), width=2)
        draw.text((x + 18, y + 40), "missing", fill=(255, 120, 120))
        return
    im = Image.open(path)
    if im.size != (320, 320) or im.mode != "RGBA" or im.getpixel((2, 2))[3] > 10:
        bad.append("%s (%sx%s %s)" % (entry["file"], im.size[0], im.size[1], im.mode))
    sheet.alpha_composite(im.convert("RGBA").resize((TILE, TILE)), (x, y))

for i, (base, leg) in enumerate(pairs):
    x = (i % cols) * (TILE * 2 + PAD * 3) + PAD
    y = (i // cols) * (TILE + 28 + PAD) + PAD
    tile(base, x, y)
    if leg:
        tile(leg, x + TILE + PAD, y)
    draw.text((x, y + TILE + 6), base["id"], fill=(230, 220, 200))

out = sys.argv[1] if len(sys.argv) > 1 else "item-art-sheet.png"
sheet.save(out)
print("sheet:", out)
print("missing (%d):" % len(missing), *missing, sep="\n  ")
print("wrong format (%d):" % len(bad), *bad, sep="\n  ")
