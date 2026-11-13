#!/bin/bash
# Feature 5.1 dans l'ENVIRONNEMENT COMPLET (comme screenshots.yml) : bureau Windows 11 avec fond d'écran et barre des tâches
# (look-and-feel + layout du dépôt, Icon Tasks du fork), mais avec composition OpenGL logicielle (KWIN_COMPOSE=O2), nécessaire
# aux coins arrondis. Exécute le VRAI scripts/install-roundcorners.sh (install, status, undo).
# Étape 3 = TEST DE RENDU UNIQUEMENT (VM jetable) : copie du .so dont l'IID 6.6.6 est réécrit en 6.6.4 (même longueur), car
# kwin-x11 reste en 6.6.4 sur Ubuntu 26.04 et refuse sinon le plugin compilé pour 6.6.6. Jamais utilisé par les scripts utilisateur.
# Usage : ci/roundcorners-desktop.sh <dossier_sortie>   (sous dbus-run-session, HOME=/root, root)
set -u
OUT="${1:-shots}"; mkdir -p "$OUT"
export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p $XDG_RUNTIME_DIR; chmod 700 $XDG_RUNTIME_DIR
export DISPLAY=:99 QT_QPA_PLATFORM=xcb XDG_SESSION_TYPE=x11 XDG_CURRENT_DESKTOP=KDE KDE_FULL_SESSION=true
export LC_ALL=C.UTF-8 LIBGL_ALWAYS_SOFTWARE=1 QT_QUICK_BACKEND=software KWIN_COMPOSE="${RC_COMPOSE:-O2}"
SOPKG=/usr/lib/x86_64-linux-gnu/qt6/plugins/kwin/effects/plugins/kwin4_effect_shapecorners.so
X11DIR=/usr/lib/x86_64-linux-gnu/qt6/plugins/kwin-x11/effects/plugins
shot() { import -window root "$OUT/$1.png" > "$OUT/import-$1.log" 2>&1; ls -l "$OUT/$1.png" 2>&1; }
kw() { dbus-send --session --print-reply --dest=org.kde.KWin "$@" 2>&1; }
px() { convert "$OUT/$1.png" -format "%[pixel:p{$2,$3}]" info: 2>/dev/null; }
state() {
  { echo "== $1"
    echo "composition : $(kw /Compositor org.freedesktop.DBus.Properties.Get string:org.kde.kwin.Compositing string:compositingType | tr -s ' \n' ' ')"
    if kw /Effects org.freedesktop.DBus.Properties.Get string:org.kde.kwin.Effects string:loadedEffects | grep -q kwin4_effect_shapecorners; then echo "effet shapecorners : CHARGÉ par KWin"; else echo "effet shapecorners : non chargé"; fi
    echo "kwinrc : $(kreadconfig6 --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled)"
  } >> "$OUT/etat.txt"
}
analyse() {  # $1 = capture ; mesure les pixels des 4 coins du cadre de Konsole, recadre x8 (avec 40 px de contexte)
  local id x y w h l r t b fx fy fw fh
  id=$(xdotool search --onlyvisible --class konsole 2>/dev/null | head -1)
  [ -n "$id" ] || { echo "$1 : pas de fenêtre Konsole" >> "$OUT/etat.txt"; return; }
  eval "$(xdotool getwindowgeometry --shell "$id")"; x=$X; y=$Y; w=$WIDTH; h=$HEIGHT
  read -r l r t b <<<"$(xprop -id "$id" _NET_FRAME_EXTENTS | sed 's/.*= //; s/,//g')"
  fx=$((x-l)); fy=$((y-t)); fw=$((w+l+r)); fh=$((h+t+b))
  { echo "$1 : cadre ${fw}x${fh}+${fx}+${fy} (extents $l,$r,$t,$b)"
    echo "  pixel (0,0) coin exact haut-gauche = $(px $1 $fx $fy) ; (1,1) = $(px $1 $((fx+1)) $((fy+1))) ; (4,4) = $(px $1 $((fx+4)) $((fy+4)))"
    echo "  pixel coin exact haut-droit = $(px $1 $((fx+fw-1)) $fy) ; bas-gauche = $(px $1 $fx $((fy+fh-1))) ; bas-droit = $(px $1 $((fx+fw-1)) $((fy+fh-1)))"
  } >> "$OUT/etat.txt"
  convert "$OUT/$1.png" -crop 40x40+$((fx-4))+$((fy-4)) +repage -scale 800% "$OUT/$1-coin-haut-gauche.png"
  convert "$OUT/$1.png" -crop 40x40+$((fx+fw-36))+$((fy-4)) +repage -scale 800% "$OUT/$1-coin-haut-droit.png"
  convert "$OUT/$1.png" -crop 40x40+$((fx-4))+$((fy+fh-36)) +repage -scale 800% "$OUT/$1-coin-bas-gauche.png"
  convert "$OUT/$1.png" -crop 40x40+$((fx+fw-36))+$((fy+fh-36)) +repage -scale 800% "$OUT/$1-coin-bas-droit.png"
}
waitdeco() {  # attend la décoration Aurorae (barre 32 px) sur Konsole ; relance reconfigure à chaque tour
  local id i
  for i in $(seq 1 25); do
    id=$(xdotool search --onlyvisible --class konsole 2>/dev/null | head -1)
    [ -n "$id" ] && xprop -id "$id" _NET_FRAME_EXTENTS 2>/dev/null | grep -q '= 4, 4, 32, 4' && { echo "décoration Aurorae prête (tour $i)" >> "$OUT/etat.txt"; return; }
    kw /KWin org.kde.KWin.reconfigure >/dev/null; sleep 2
  done
  echo "décoration Aurorae NON confirmée" >> "$OUT/etat.txt"
}

# ---- session (même séquence que ci/screenshot.sh, avec composition) ----
Xvfb :99 -screen 0 1920x1080x24 +extension GLX +render -noreset > "$OUT/xvfb.log" 2>&1 &
sleep 3
kwin_x11 > "$OUT/kwin.log" 2>&1 &
sleep 4
for d in /usr/libexec/kactivitymanagerd /usr/bin/kactivitymanagerd /usr/lib/x86_64-linux-gnu/libexec/kactivitymanagerd; do
  [ -x "$d" ] && { "$d" > "$OUT/kactivities.log" 2>&1 & break; }
done
sleep 3
plasmashell > "$OUT/plasmashell.log" 2>&1 &
sleep 25
plasma-apply-colorscheme WindowsModernDark >> "$OUT/apply.log" 2>&1
plasma-apply-desktoptheme Windows-modern-dark >> "$OUT/apply.log" 2>&1
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum-dark
kwriteconfig6 --file kdeglobals --group Icons --key Theme windows-modern
sleep 8
WP=$(find /root/.local/share/wallpapers/Windows-modern -type f \( -name '*.jpg' -o -name '*.png' \) 2>/dev/null | head -1)
[ -n "$WP" ] && plasma-apply-wallpaperimage "$WP" >> "$OUT/apply.log" 2>&1
plasma-apply-lookandfeel -a org.kde.windowsmodern.dark --resetLayout >> "$OUT/apply.log" 2>&1; echo "lookandfeel exit=$?" >> "$OUT/apply.log"
( source scripts/install-lib.sh; ensure_icon_theme windows-modern; ensure_window_decoration dark ) >> "$OUT/apply.log" 2>&1
sleep 15
export XDG_MENU_PREFIX=plasma-
kbuildsycoca6 --noincremental > "$OUT/sycoca.log" 2>&1
kquitapp6 plasmashell >> "$OUT/apply.log" 2>&1; sleep 3; pkill -x plasmashell 2>/dev/null; sleep 2
plasmashell > "$OUT/plasmashell-restart.log" 2>&1 &
sleep 20
konsole -e bash > "$OUT/konsole.log" 2>&1 &
dolphin > "$OUT/dolphin.log" 2>&1 &
sleep 10
waitdeco
cp /root/.config/kwinrc "$OUT/kwinrc-avant.txt" 2>/dev/null || true
{ echo "kwin-x11=$(dpkg-query -W -f='${Version}' kwin-x11 2>/dev/null) kwin-wayland=$(dpkg-query -W -f='${Version}' kwin-wayland 2>/dev/null) libkwin6=$(dpkg-query -W -f='${Version}' libkwin6 2>/dev/null)"; } >> "$OUT/etat.txt"

# ---- 1. avant ----
state "1-avant"; shot 01-avant; analyse 01-avant

# ---- 2. le VRAI script (install) ----
RC_YES=1 bash scripts/install-roundcorners.sh install > "$OUT/install.log" 2>&1; echo "install exit=$?" >> "$OUT/install.log"
sleep 8
bash scripts/install-roundcorners.sh status > "$OUT/status-apres-install.txt" 2>&1
state "2-apres-install"; shot 02-apres-install; analyse 02-apres-install
cp /root/.config/kwinrc "$OUT/kwinrc-apres.txt" 2>/dev/null || true

# ---- 3. TEST DE RENDU (CI seulement) : IID réécrit pour kwin-x11 ----
WANT=$(grep -a -o -E 'EffectPluginFactory[0-9]+\.[0-9]+\.[0-9]+' "$SOPKG" | head -1 | sed 's/EffectPluginFactory//')
HAVE=$(dpkg-query -W -f='${Version}' kwin-x11); HAVE=${HAVE#*:}; HAVE=${HAVE%%-*}
echo "IID du plugin=$WANT ; kwin-x11=$HAVE" >> "$OUT/etat.txt"
if [ -n "$WANT" ] && [ "$WANT" != "$HAVE" ] && [ ${#WANT} = ${#HAVE} ]; then
  mkdir -p "$X11DIR"
  LC_ALL=C sed -b "s/EffectPluginFactory$WANT/EffectPluginFactory$HAVE/g" "$SOPKG" > "$X11DIR/kwin4_effect_shapecorners.so"
  chmod 755 "$X11DIR/kwin4_effect_shapecorners.so"
  echo "copie IID-patchée : $(grep -a -o -E 'EffectPluginFactory[0-9.]+' "$X11DIR/kwin4_effect_shapecorners.so" | head -1) -> $X11DIR" >> "$OUT/etat.txt"
fi
kw /KWin org.kde.KWin.reconfigure >/dev/null; sleep 3
kw /Effects org.kde.kwin.Effects.loadEffect string:kwin4_effect_shapecorners >> "$OUT/etat.txt" 2>&1
sleep 5
state "3-rendu-iid-patche"; shot 03-rendu-iid-patche; analyse 03-rendu-iid-patche
kw /Effects org.freedesktop.DBus.Properties.Get string:org.kde.kwin.Effects string:loadedEffects > "$OUT/loaded-effects.txt" 2>&1
# fenêtre déplacée pour forcer un nouveau rendu (l'effet s'applique aux fenêtres au moment de leur peinture)
xdotool search --onlyvisible --class konsole | head -1 | xargs -I{} xdotool windowmove {} 560 330; sleep 3
shot 03b-apres-deplacement; analyse 03b-apres-deplacement

# ---- 4. undo ----
rm -f "$X11DIR/kwin4_effect_shapecorners.so"
RC_YES=1 bash scripts/install-roundcorners.sh undo > "$OUT/undo.log" 2>&1; echo "undo exit=$?" >> "$OUT/undo.log"
sleep 8
bash scripts/install-roundcorners.sh status > "$OUT/status-apres-undo.txt" 2>&1
state "4-apres-undo"; shot 04-apres-undo; analyse 04-apres-undo
cp /root/.config/kwinrc "$OUT/kwinrc-apres-undo.txt" 2>/dev/null || true
diff "$OUT/kwinrc-avant.txt" "$OUT/kwinrc-apres-undo.txt" > "$OUT/kwinrc-diff-avant-undo.txt" 2>&1 && echo "kwinrc identique avant/après undo" >> "$OUT/etat.txt" || echo "kwinrc DIFFÉRENT avant/après undo (voir kwinrc-diff-avant-undo.txt)" >> "$OUT/etat.txt"
ps aux | grep -E "Xvfb|kwin|plasmashell" | grep -v grep | cut -c1-120 > "$OUT/ps.txt"
