#!/bin/bash
# Feature 5.1 : session KWin X11 AVEC composition OpenGL logicielle (llvmpipe), puis exécution du VRAI
# scripts/install-roundcorners.sh (install, status, undo) avec captures avant / après / après retour arrière.
# Usage : ci/roundcorners-shots.sh <dossier_sortie>   (à lancer sous dbus-run-session, HOME=/root, en root)
set -u
OUT="${1:-shots}"; mkdir -p "$OUT"
export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p $XDG_RUNTIME_DIR; chmod 700 $XDG_RUNTIME_DIR
export DISPLAY=:99 QT_QPA_PLATFORM=xcb XDG_SESSION_TYPE=x11 XDG_CURRENT_DESKTOP=KDE KDE_FULL_SESSION=true
export LC_ALL=C.UTF-8 LIBGL_ALWAYS_SOFTWARE=1 QT_QUICK_BACKEND=software
export KWIN_COMPOSE="${RC_COMPOSE:-O2}"
shot() { import -window root "$OUT/$1.png" > "$OUT/import-$1.log" 2>&1; ls -l "$OUT/$1.png" 2>&1; }
kw() { dbus-send --session --print-reply --dest=org.kde.KWin "$@" 2>&1; }
state() {
  {
    echo "== $1"
    kw /Compositor org.freedesktop.DBus.Properties.Get string:org.kde.kwin.Compositing string:active | tr '\n' ' '; echo
    kw /Compositor org.freedesktop.DBus.Properties.Get string:org.kde.kwin.Compositing string:compositingType | tr '\n' ' '; echo
    kw /Effects org.freedesktop.DBus.Properties.Get string:org.kde.kwin.Effects string:loadedEffects | tr -s ' \n' ' ' | grep -o 'shapecorners' || echo "(effet shapecorners non chargé)"
    echo "kwinrc: $(kreadconfig6 --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled)"
  } >> "$OUT/etat.txt"
}
cropwin() {  # $1 = nom ; recadre les 4 coins du cadre de la fenêtre Konsole (zoom x8), d'après _NET_FRAME_EXTENTS
  local id x y w h l r t b ext fx fy fw fh
  id=$(xdotool search --onlyvisible --class konsole 2>/dev/null | head -1)
  [ -n "$id" ] || { echo "pas de fenêtre konsole" >> "$OUT/etat.txt"; return; }
  eval "$(xdotool getwindowgeometry --shell "$id")"; x=$X; y=$Y; w=$WIDTH; h=$HEIGHT
  ext=$(xprop -id "$id" _NET_FRAME_EXTENTS | sed 's/.*= //; s/,//g'); read -r l r t b <<<"$ext"
  echo "$1 : client ${w}x${h}+${x}+${y} extents l=$l r=$r t=$t b=$b" >> "$OUT/etat.txt"
  fx=$((x-l)); fy=$((y-t)); fw=$((w+l+r)); fh=$((h+t+b))
  convert "$OUT/$1.png" -crop 40x40+$((fx-4))+$((fy-4)) +repage -scale 800% "$OUT/$1-coin-haut-gauche.png"
  convert "$OUT/$1.png" -crop 40x40+$((fx+fw-36))+$((fy-4)) +repage -scale 800% "$OUT/$1-coin-haut-droit.png"
  convert "$OUT/$1.png" -crop 40x40+$((fx-4))+$((fy+fh-36)) +repage -scale 800% "$OUT/$1-coin-bas-gauche.png"
  convert "$OUT/$1.png" -crop 40x40+$((fx+fw-36))+$((fy+fh-36)) +repage -scale 800% "$OUT/$1-coin-bas-droit.png"
}
waitdeco() {  # attend que la décoration Aurorae (barre 32 px) soit appliquée à Konsole
  local id i
  for i in $(seq 1 20); do
    id=$(xdotool search --onlyvisible --class konsole 2>/dev/null | head -1)
    [ -n "$id" ] && xprop -id "$id" _NET_FRAME_EXTENTS 2>/dev/null | grep -q '= 4, 4, 32, 4' && { echo "décoration prête après ${i}x2 s" >> "$OUT/etat.txt"; return; }
    sleep 2
  done
  echo "décoration Aurorae NON confirmée (extents attendus 4,4,32,4)" >> "$OUT/etat.txt"
}

Xvfb :99 -screen 0 1920x1080x24 +extension GLX +render -noreset > "$OUT/xvfb.log" 2>&1 &
sleep 3
kwin_x11 > "$OUT/kwin.log" 2>&1 &
sleep 5
plasmashell > "$OUT/plasmashell.log" 2>&1 &
sleep 20
plasma-apply-colorscheme WindowsModernDark >> "$OUT/apply.log" 2>&1
plasma-apply-desktoptheme Windows-modern-dark >> "$OUT/apply.log" 2>&1
( source scripts/install-lib.sh; ensure_icon_theme windows-modern; ensure_window_decoration dark ) >> "$OUT/apply.log" 2>&1
dbus-send --session --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1
sleep 5
WP=$(find /root/.local/share/wallpapers/Windows-modern -type f \( -name '*.jpg' -o -name '*.png' \) 2>/dev/null | head -1)
[ -n "$WP" ] && plasma-apply-wallpaperimage "$WP" >> "$OUT/apply.log" 2>&1
konsole -e bash > "$OUT/konsole.log" 2>&1 &
dolphin > "$OUT/dolphin.log" 2>&1 &
sleep 6
waitdeco
cp /root/.config/kwinrc "$OUT/kwinrc-avant.txt" 2>/dev/null || true

state "1-avant"; shot 01-avant; cropwin 01-avant

# --- le VRAI script, en root (pas de sudo), PPA déjà présent dans le conteneur ---
RC_YES=1 bash scripts/install-roundcorners.sh install > "$OUT/install.log" 2>&1; echo "install exit=$?" >> "$OUT/install.log"
sleep 8
bash scripts/install-roundcorners.sh status > "$OUT/status-apres-install.txt" 2>&1
state "2-apres-install"; shot 02-apres-install; cropwin 02-apres-install
cp /root/.config/kwinrc "$OUT/kwinrc-apres.txt" 2>/dev/null || true

# --- diagnostic : reconfigure a-t-il suffi ? sinon loadEffect, puis redemarrage de KWin ---
kw /Effects org.kde.kwin.Effects.loadEffect string:kwin4_effect_shapecorners >> "$OUT/etat.txt" 2>&1
sleep 4
state "2b-apres-loadEffect"; shot 02b-apres-loadEffect; cropwin 02b-apres-loadEffect
SO=$(dpkg -L kwin-effect-roundcorners | grep '\.so$' | head -1)
{ echo "SO=$SO"; ldd "$SO" 2>&1 | grep -i "not found" || echo "ldd: aucune lib manquante"; strings "$SO" | grep -i -m3 "shapecorners"; } > "$OUT/so-diag.txt" 2>&1
kw /Effects org.freedesktop.DBus.Properties.Get string:org.kde.kwin.Effects string:loadedEffects > "$OUT/loaded-effects.txt" 2>&1
kw /Effects org.kde.kwin.Effects.listOfEffects > "$OUT/list-effects.txt" 2>&1
QT_DEBUG_PLUGINS=1 QT_LOGGING_RULES="kwin_core*=true;kwin_effects*=true;kwin*.debug=true" kwin_x11 --replace > "$OUT/kwin-replace.log" 2>&1 &
sleep 10
state "2c-apres-kwin-replace"; shot 02c-apres-kwin-replace; cropwin 02c-apres-kwin-replace

RC_YES=1 bash scripts/install-roundcorners.sh undo > "$OUT/undo.log" 2>&1; echo "undo exit=$?" >> "$OUT/undo.log"
sleep 8
bash scripts/install-roundcorners.sh status > "$OUT/status-apres-undo.txt" 2>&1
state "3-apres-undo"; shot 03-apres-undo; cropwin 03-apres-undo
cp /root/.config/kwinrc "$OUT/kwinrc-apres-undo.txt" 2>/dev/null || true

ps aux | grep -E "Xvfb|kwin|plasmashell" | grep -v grep | cut -c1-120 > "$OUT/ps.txt"
