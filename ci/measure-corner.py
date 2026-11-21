#!/usr/bin/env python3
"""Mesure le rayon d'un coin de fenetre (haut-gauche) sur une capture a fond clair uni.
Usage : measure-corner.py capture.png x y rayon_attendu [tolerance_px]
(x, y) = coin haut-gauche du cadre de la fenetre. Sortie : une ligne 'RADIUS ...' ; code 0 si OK, 1 sinon.
Methode : pour chaque ligne du coin, decalage horizontal du premier pixel different du fond ;
on ajuste le rayon R d'un arc circulaire (moindres carres) et on compare a la cible (Windows 11 : 8 px)."""
import sys, math
from PIL import Image
png, x0, y0, want = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), float(sys.argv[4])
tol = float(sys.argv[5]) if len(sys.argv) > 5 else 1.0
im = Image.open(png).convert('RGB')
bg = im.getpixel((max(x0 - 8, 0), max(y0 - 8, 0)))
def diff(p): return sum(abs(a - b) for a, b in zip(p, bg))
prof = []
for j in range(0, 24):
    off = None
    for i in range(0, 30):
        if diff(im.getpixel((x0 - 2 + i, y0 + j))) > 60:
            off = i - 2; break
    prof.append(off)
# rayon apparent = premiere ligne ou le bord est atteint (decalage <= 0)
edge_row = next((j for j, o in enumerate(prof) if o is not None and o <= 0), None)
def model(R, j): return R - math.sqrt(max(R * R - (R - j - 0.5) ** 2, 0)) if j < R else 0.0
best = None
for R10 in range(20, 300):
    R = R10 / 10
    pts = [(j, o) for j, o in enumerate(prof) if o is not None]
    if not pts: break
    err = math.sqrt(sum((model(R, j) - max(o, 0)) ** 2 for j, o in pts) / len(pts))
    if best is None or err < best[1]: best = (R, err)
if best is None:
    print(f"RADIUS KO : aucun bord detecte (fond {bg})"); sys.exit(1)
R, err = best
ok = abs(R - want) <= tol and err <= 1.5
print(f"RADIUS {'OK' if ok else 'KO'} : mesure={R:.1f}px (ajustement rms={err:.2f}) cible={want:g}px±{tol:g} ligne_bord={edge_row} profil={prof[:14]}")
sys.exit(0 if ok else 1)
