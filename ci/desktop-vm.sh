#!/bin/bash
# Bureau Plasma COMPLET sur la VM réelle (runner sans conteneur) : kwin_wayland 6.6.6 sur DRM, OpenGL (gl2), plasmashell, thème du dépôt.
# Permet de vérifier ce que le Xvfb sans composition ne montre pas : translucidité/flou, barre flottante, ombres, coins arrondis.
# Usage : ci/desktop-vm.sh <dossier_sortie>   (root, HOME=/root, sous dbus-run-session, depuis la racine du dépôt)
set -u
OUT="${1:-shots}"; mkdir -p "$OUT"
export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p $XDG_RUNTIME_DIR; chmod 700 $XDG_RUNTIME_DIR
export XDG_CURRENT_DESKTOP=KDE KDE_FULL_SESSION=true XDG_SESSION_TYPE=wayland
export LC_ALL=C.UTF-8 LIBGL_ALWAYS_SOFTWARE=1 QT_QUICK_BACKEND=software
unset DISPLAY
kw() { dbus-send --session --print-reply --dest=org.kde.KWin "$@" 2>&1; }
DRMDEV=$(ls /dev/dri/card* 2>/dev/null | head -1); { ls -l /dev/dri; echo "DRMDEV=$DRMDEV"; } > "$OUT/dri.txt" 2>&1
KW=/usr/bin/kwin_wayland
mkdir -p /root/.config
RULES="kwin_*=true;kwin.*=true;qt.qpa.*=true;qt.core.plugin.loader=false;qt.core.plugin.factoryloader=false"
env KWIN_WAYLAND_NO_PERMISSION_CHECKS=1 LIBGL_ALWAYS_SOFTWARE=1 KWIN_COMPOSE=O2 LIBSEAT_BACKEND=noop KWIN_DRM_DEVICES="$DRMDEV" QT_LOGGING_RULES="$RULES" "$KW" --socket wayland-0 --no-lockscreen > "$OUT/kwin.log" 2>&1 &
for i in $(seq 1 25); do [ -S "$XDG_RUNTIME_DIR/wayland-0" ] && break; sleep 1; done
export WAYLAND_DISPLAY=wayland-0 QT_QPA_PLATFORM=wayland
for i in $(seq 1 10); do ct=$(kw /Compositor org.freedesktop.DBus.Properties.Get string:org.kde.kwin.Compositing string:compositingType | tr -s ' \n' ' '); case "$ct" in *gl2*) break;; esac; sleep 1; done
echo "compositingType: ${ct##* variant }" > "$OUT/etat.txt"

shot() { python3 ci/drm-grab.py "$DRMDEV" "$OUT/$1.png" >> "$OUT/grab.log" 2>&1; ls -l "$OUT/$1.png" 2>&1 | tail -1; }
for d in /usr/libexec/kactivitymanagerd /usr/bin/kactivitymanagerd /usr/lib/x86_64-linux-gnu/libexec/kactivitymanagerd; do
  [ -x "$d" ] && { "$d" > "$OUT/kactivities.log" 2>&1 & echo "kactivitymanagerd: $d" >> "$OUT/etat.txt"; break; }
done
sleep 3
plasmashell > "$OUT/plasmashell.log" 2>&1 &
sleep 25
plasma-apply-colorscheme WindowsModernDark >> "$OUT/apply.log" 2>&1
plasma-apply-desktoptheme Windows-modern-dark >> "$OUT/apply.log" 2>&1
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum-dark
WP=$(find /root/.local/share/wallpapers/Windows-modern -type f \( -name '*.jpg' -o -name '*.png' \) 2>/dev/null | head -1)
[ -n "$WP" ] && plasma-apply-wallpaperimage "$WP" >> "$OUT/apply.log" 2>&1
plasma-apply-lookandfeel -a org.kde.windowsmodern.dark --resetLayout >> "$OUT/apply.log" 2>&1; echo "lookandfeel exit=$?" >> "$OUT/apply.log"
( source scripts/install-lib.sh; ensure_icon_theme windows-modern; ensure_window_decoration dark ) >> "$OUT/apply.log" 2>&1
kw /KWin org.kde.KWin.reconfigure >/dev/null
sleep 20
shot 01-bureau

konsole -e bash > "$OUT/konsole.log" 2>&1 &
dolphin > "$OUT/dolphin.log" 2>&1 &
sleep 15
shot 02-fenetres-ouvertes

# --- Mesures : effets chargés, état du panneau ---
{
  echo "== effets (blur, shapecorners, translucency, ...)"
  for e in blur contrast kwin4_effect_shapecorners slidingpopups fade; do echo "$e : $(kw /Effects org.kde.kwin.Effects.isEffectLoaded string:$e | tr -s ' \n' ' ' | sed 's/.*boolean/boolean/')"; done
  echo "== panneau (script Plasma)"
  qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'var out=""; for (var p of panels()) { out += "panel id="+p.id+" location="+p.location+" height="+p.height+" floating="+p.floating+" opacity="+p.opacity+" alignment="+p.alignment+" lengthMode="+p.lengthMode+" hiding="+p.hiding+"\n"; } print(out)' 2>&1 | head -10
} >> "$OUT/etat.txt"
# Translucidité : la barre est translucide si sa couleur de fond suit le fond d'écran en dessous (pixels éloignés différents) — échantillons dans la barre, hors icônes.
W=$(identify -format %w "$OUT/01-bureau.png" 2>/dev/null); H=$(identify -format %h "$OUT/01-bureau.png" 2>/dev/null)
{ echo "== écran ${W}x${H}"; for x in 20 120 220 $((W-220)) $((W-120)) $((W-20)); do echo "barre x=$x y=$((H-6)) : $(convert "$OUT/01-bureau.png" -format "%[pixel:p{$x,$((H-6))}]" info:)"; done; } >> "$OUT/etat.txt"
convert "$OUT/01-bureau.png" -gravity south -crop "${W}x80+0+0" +repage "$OUT/01-barre-recadree.png" 2>/dev/null
ps aux | grep -E "kwin|plasmashell|konsole|dolphin" | grep -v grep | cut -c1-140 > "$OUT/ps.txt"
