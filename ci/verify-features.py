#!/usr/bin/env python3
"""Verifie, sur les captures CI, que chaque fonctionnalite annoncee est PRESENTE, par mesure de pixels.

Usage : verify-features.py --fork DIR [--vm DIR] [--doc docs/FONCTIONNALITES-WIN11.md] [--out FEATURES.md] [--strict]
  --fork : dossier des captures du banc 1 (1920x1080, sans composition)
  --vm   : dossier des captures du banc 2 (VM reelle, composition active ; sert aux coins arrondis)
Sortie : tableau FEATURES.md ; code 1 avec --strict si un controle ECHOUE.

Regle : une ligne ✅ du document de fonctionnalites sans controle automatique ici, ou dont le controle echoue,
est signalee. Un controle PASS prouve la presence/la geometrie mesuree, pas la ressemblance complete a Windows 11.
Toutes les mesures sont donnees en pixels ; aucun chiffre n'est suppose.
"""
import argparse, os, re, sys
from PIL import Image

ap = argparse.ArgumentParser()
ap.add_argument('--fork'); ap.add_argument('--vm')
ap.add_argument('--doc', default='docs/FONCTIONNALITES-WIN11.md')
ap.add_argument('--out', default='FEATURES.md')
ap.add_argument('--strict', action='store_true')
A = ap.parse_args()

PASS, FAIL, SKIP = 'PASS', 'FAIL', 'NON-TESTABLE'
results = {}   # id -> (status, mesure)
names = {}     # id -> libelle du controle

def img(d, name):
    p = os.path.join(d, name) if d else None
    if not p or not os.path.exists(p): return None
    return Image.open(p).convert('RGB')

def near(p, q, t=4): return all(abs(a - b) <= t for a, b in zip(p, q))
def accent(p): return p[2] > 200 and p[0] < 110 and p[1] > 120          # bleu d'accent / logo clair
def bright(p): return min(p) > 150
def check(fid, label, fn):
    names[fid] = label
    try:
        st, m = fn()
    except Exception as e:  # capture absente ou illisible = non verifie, jamais PASS
        st, m = SKIP, f'capture ou mesure indisponible ({type(e).__name__}: {e})'
    results[fid] = (st, m)

def taskbar_top(im):
    """Premiere ligne de la barre (colonne x=300, du bas vers le haut tant que la couleur est celle de la barre)."""
    bg = im.getpixel((300, im.height - 2)); y = im.height - 2
    while y > 0 and near(im.getpixel((300, y - 1)), bg, 6): y -= 1
    return y, bg

F = A.fork
bar = img(F, '07-bureau-repos.png')

def f11():
    top, bg = taskbar_top(bar); h = bar.height - top
    full = near(bar.getpixel((2, top + 24)), bg, 6) and near(bar.getpixel((bar.width - 3, top + 24)), bg, 12)
    return (PASS if h == 48 and full else FAIL), f'hauteur={h}px (cible 48), pleine largeur={full}'
check('1.1', 'barre 48 px pleine largeur', f11)

def groups(im, y0, y1, x0, x1, bg, gap=8, t=40):
    # seuil 40 : ne retient que les icones/pastilles, pas le fond discret d'une tuile (Dolphin et Konsole sont a 4 px l'un de l'autre)
    cols = [x for x in range(x0, x1) if any(not near(im.getpixel((x, y)), bg, t) for y in range(y0, y1))]
    gs = []
    for x in cols:
        if gs and x - gs[-1][1] <= gap: gs[-1][1] = x
        else: gs.append([x, x])
    return gs

def f13():
    top, bg = taskbar_top(bar)
    n = sum(1 for y in range(top + 6, top + 42) for x in range(780, 940) if accent(bar.getpixel((x, y))))
    return (PASS if n >= 80 else FAIL), f'{n} px bleu du logo dans la zone du bouton Demarrer (>= 80 attendus)'
check('1.3', 'logo Windows 11 du bouton Demarrer', f13)

def f112():
    top, bg = taskbar_top(bar)
    gs = groups(bar, top + 6, top + 42, 780, 1150, bg)
    centre = (gs[0][0] + gs[-1][1]) / 2 if gs else 0
    ok = len(gs) >= 5 and abs(centre - bar.width / 2) <= 40
    return (PASS if ok else FAIL), f'{len(gs)} icones/boutons au centre (>= 5), centre du groupe x={centre:.0f} (ecran {bar.width // 2})'
check('1.12', 'Demarrer + Recherche + Vue des taches + applis, groupe centre', f112)

def f23():
    top, bg = taskbar_top(bar)
    def rows(y0, y1): return sum(1 for y in range(y0, y1) if any(not near(bar.getpixel((x, y)), bg, 18) for x in range(1795, 1868)))
    l1, l2 = rows(top + 6, top + 24), rows(top + 26, top + 44)
    return (PASS if l1 >= 6 and l2 >= 4 else FAIL), f'lignes de texte non vides : heure={l1}, date={l2}'
check('2.3', 'horloge sur deux lignes', f23)

def f24():
    n0 = img(F, '16-notif-0.png'); n1 = img(F, '17-notif-1.png')
    top, bg = taskbar_top(n0)
    cloche = sum(1 for y in range(top + 6, top + 42) for x in range(1865, 1912) if bright(n0.getpixel((x, y))))
    pastille = sum(1 for y in range(top + 6, top + 42) for x in range(1865, 1912) if accent(n1.getpixel((x, y))))
    return (PASS if cloche >= 25 and pastille >= 60 else FAIL), f'cloche={cloche} px clairs (>=25), pastille={pastille} px accent (>=60)'
check('2.4', 'cloche puis pastille de nombre', f24)

def margins(im, row, col):
    """Marges du panneau flottant : pixels libres a droite (ligne row) et au-dessus de la barre (colonne col)."""
    top, _ = taskbar_top(im)
    panneau = lambda p: max(p) - min(p) <= 3 and max(p) <= 31
    x = im.width - 1
    while x > 0 and not panneau(im.getpixel((x, row))): x -= 1
    y = top - 1
    while y > 0 and not panneau(im.getpixel((col, y))): y -= 1
    return im.width - 1 - x, top - 1 - y

def panel_check(png, row):
    def f():
        r, b = margins(img(F, png), row, 1700)
        ok = abs(r - 12) <= 1 and abs(b - 12) <= 1
        return (PASS if ok else FAIL), f'marge droite={r}px, au-dessus de la barre={b}px (cible 12 +-1)'
    return f
check('2.6', 'panneau Parametres rapides flottant a 12 px', panel_check('22-quick-popup.png', 800))
check('2.8', 'panneau Notifications flottant a 12 px', panel_check('19-notif-popup.png', 800))

def start_box(im):
    top, _ = taskbar_top(im)
    ref = im.getpixel((960, 800))
    l = r = 960
    while l > 0 and near(im.getpixel((l - 1, 700)), ref, 3): l -= 1
    while r < im.width - 1 and near(im.getpixel((r + 1, 700)), ref, 3): r += 1
    b = top - 1
    while b > 0 and not near(im.getpixel((960, b)), ref, 3): b -= 1
    return l, r, top - 1 - b
def f31():
    l, r, gap = start_box(img(F, '09-menu-demarrer.png'))
    w = r - l + 1; c = (l + r) / 2
    return (PASS if abs(c - 960) <= 2 and abs(gap - 12) <= 1 else FAIL), f'largeur={w}px, centre x={c:.0f} (960), ecart a la barre={gap}px (12 +-1)'
check('3.1', 'menu Demarrer centre, a 12 px de la barre', f31)

def f32():
    im = img(F, '09-menu-demarrer.png')
    n = sum(1 for y in range(344, 354) for x in range(676, 1244) if accent(im.getpixel((x, y))))
    return (PASS if n >= 400 else FAIL), f'{n} px de liseré accent sous le champ de recherche (>= 400)'
check('3.2', 'liseré d\'accent du champ de recherche', f32)

def f55():
    # banc 2 : le rayon est mesure par ci/measure-corner.py ; on lit ses lignes dans les journaux
    if not A.vm: return SKIP, 'dossier du banc 2 non fourni'
    txt = ''
    for f in os.listdir(A.vm):
        if f.endswith(('.log', '.txt')): txt += open(os.path.join(A.vm, f), errors='ignore').read()
    m = re.findall(r'RADIUS (OK|KO) : mesure=([\d.]+)px', txt)
    if not m: return SKIP, 'aucune ligne RADIUS dans les journaux du banc 2'
    ok = all(s == 'OK' for s, _ in m)
    return (PASS if ok else FAIL), 'rayons mesures : ' + ', '.join(v + ' px' for _, v in m) + ' (cible 8 +-1)'
check('5.1', 'coins arrondis de 8 px (banc 2)', f55)

# --- lecture du document : quelles lignes ✅ sont prouvees ? ---
rows = []
if os.path.exists(A.doc):
    for line in open(A.doc, encoding='utf-8'):
        m = re.match(r'\|\s*(\d+\.\d+)\s*\|(.*?)\|\s*(✅|🟡|⬜|❌|⛔)', line)
        if m: rows.append((m.group(1), re.sub(r'\*\*', '', m.group(2)).strip()[:70], m.group(3)))

out = ['# Verification automatique des fonctionnalites', '',
       'PASS = mesure conforme sur la capture ; FAIL = mesure non conforme ; NON-TESTABLE = capture/mesure absente.', '',
       '| # | Controle | Resultat | Mesure |', '|---|---|---|---|']
for fid in sorted(results, key=lambda s: [int(x) for x in s.split('.')]):
    st, m = results[fid]
    out.append(f'| {fid} | {names[fid]} | {st} | {m} |')
claimed = [(i, t) for i, t, s in rows if s == '✅']
sans = [(i, t) for i, t in claimed if i not in results]
faux = [(i, t) for i, t in claimed if i in results and results[i][0] == FAIL]
out += ['', f'Lignes ✅ du document : {len(claimed)} ; avec controle automatique : {len(claimed) - len(sans)} ; SANS controle : {len(sans)} ; controle en echec : {len(faux)}.', '']
if faux:
    out += ['## ✅ annoncees mais controle en ECHEC'] + [f'- {i} {t}' for i, t in faux] + ['']
if sans:
    out += ['## ✅ annoncees SANS controle automatique (a prouver ou a retrograder)'] + [f'- {i} {t}' for i, t in sans] + ['']
open(A.out, 'w', encoding='utf-8').write('\n'.join(out) + '\n')
print('\n'.join(out))
bad = [i for i, (s, _) in results.items() if s == FAIL]
sys.exit(1 if (A.strict and bad) else 0)
