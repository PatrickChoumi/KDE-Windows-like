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
mkdir -p "$HOME/.config"
# Base « sans effet » : le paquet des coins arrondis (installé à la main par le workflow) est activé par défaut -> on le désactive AVANT KWin.
kwriteconfig6 --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled false
RULES="kwin_*=true;kwin.*=true;qt.qpa.*=true;qt.core.plugin.loader=false;qt.core.plugin.factoryloader=false"
env KWIN_WAYLAND_NO_PERMISSION_CHECKS=1 LIBGL_ALWAYS_SOFTWARE=1 KWIN_COMPOSE=O2 LIBSEAT_BACKEND=noop KWIN_DRM_DEVICES="$DRMDEV" QT_LOGGING_RULES="$RULES" "$KW" --socket wayland-0 --no-lockscreen > "$OUT/kwin.log" 2>&1 &
for i in $(seq 1 25); do [ -S "$XDG_RUNTIME_DIR/wayland-0" ] && break; sleep 1; done
export WAYLAND_DISPLAY=wayland-0 QT_QPA_PLATFORM=wayland
for i in $(seq 1 10); do ct=$(kw /Compositor org.freedesktop.DBus.Properties.Get string:org.kde.kwin.Compositing string:compositingType | tr -s ' \n' ' '); case "$ct" in *gl2*) break;; esac; sleep 1; done
echo "compositingType: ${ct##* variant }" > "$OUT/etat.txt"
echo "utilisateur: $(id -un) uid=$(id -u) HOME=$HOME" >> "$OUT/etat.txt"

shot() { ${GRAB_SUDO:-} python3 ci/drm-grab.py "$DRMDEV" "$OUT/$1.png" >> "$OUT/grab.log" 2>&1; ls -l "$OUT/$1.png" 2>&1 | tail -1; }
for d in /usr/libexec/kactivitymanagerd /usr/bin/kactivitymanagerd /usr/lib/x86_64-linux-gnu/libexec/kactivitymanagerd; do
  [ -x "$d" ] && { "$d" > "$OUT/kactivities.log" 2>&1 & echo "kactivitymanagerd: $d" >> "$OUT/etat.txt"; break; }
done
sleep 3
plasmashell > "$OUT/plasmashell.log" 2>&1 &
sleep 25
plasma-apply-colorscheme WindowsModernDark >> "$OUT/apply.log" 2>&1
plasma-apply-desktoptheme Windows-modern-dark >> "$OUT/apply.log" 2>&1
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum-dark
WP=$(find "$HOME/.local/share/wallpapers/Windows-modern" /usr/share/wallpapers/Windows-modern -type f \( -name '*.jpg' -o -name '*.png' \) 2>/dev/null | head -1)
echo "fond d'ecran trouve : ${WP:-AUCUN}" >> "$OUT/etat.txt"
[ -n "$WP" ] && plasma-apply-wallpaperimage "$WP" >> "$OUT/apply.log" 2>&1
plasma-apply-lookandfeel -a org.kde.windowsmodern.dark --resetLayout >> "$OUT/apply.log" 2>&1; echo "lookandfeel exit=$?" >> "$OUT/apply.log"
( source scripts/install-lib.sh; ensure_icon_theme windows-modern; ensure_window_decoration dark; ensure_kwin_blur ) >> "$OUT/apply.log" 2>&1
kw /KWin org.kde.KWin.reconfigure >/dev/null
sleep 20
shot 01-bureau

# Test de translucidité : fond d'écran blanc uni -> si la barre est translucide, ses pixels s'éclaircissent par rapport à 01-bureau.
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'for (var d of desktops()) { d.wallpaperPlugin = "org.kde.color"; d.currentConfigGroup = ["Wallpaper","org.kde.color","General"]; d.writeConfig("Color", "255,255,255"); }' >> "$OUT/apply.log" 2>&1
sleep 15
shot 01b-fond-blanc

konsole -e bash > "$OUT/konsole.log" 2>&1 &
# Dolphin comme sur le banc 1 (barre de commandes Win11, dossiers de test) pour comparer a [Z29] [Z30] avec les coins arrondis
for d in Documents Downloads Music Pictures Videos; do mkdir -p "$HOME/$d"; done
mkdir -p ~/.local/share/kxmlgui5/dolphin && cp config/dolphin/dolphinui.rc ~/.local/share/kxmlgui5/dolphin/dolphinui.rc
kwriteconfig6 --file dolphinrc --group MainWindow --group "Toolbar mainToolBar" --key ToolButtonStyle IconOnly
kwriteconfig6 --file dolphinrc --group MainWindow --group "Toolbar mainToolBar" --key IconSize 16
dolphin > "$OUT/dolphin.log" 2>&1 &
sleep 15
shot 02-fenetres-ouvertes

# --- Coins arrondis (5.1) sur le bureau COMPLET : mesure Konsole avant / après install-roundcorners.sh ---
geom() {  # cadre de la fenêtre Konsole via un script KWin (print -> kwin.log)
  cat > "$OUT/geom.js" <<'JS'
for (const w of workspace.windowList()) {
  if (w.caption.indexOf("Konsole") >= 0 || w.resourceClass.indexOf("konsole") >= 0)
    print("GEOM " + w.frameGeometry.x + " " + w.frameGeometry.y + " " + w.frameGeometry.width + " " + w.frameGeometry.height);
}
JS
  local sid; sid=$(kw /Scripting org.kde.kwin.Scripting.loadScript string:"$OUT/geom.js" string:ci-geom$RANDOM | awk '/int32/{print $2}')
  kw /Scripting/Script$sid org.kde.kwin.Script.run >/dev/null; sleep 2
  grep -a "GEOM" "$OUT/kwin.log" | tail -1 | sed 's/.*GEOM //'
}
px() { convert "$OUT/$1.png" -format "%[pixel:p{$2,$3}]" info: 2>/dev/null; }
analyse() {  # $1 = capture ; écrit les pixels des 4 coins exacts et recadre x8
  local g fx fy fw fh
  g=$(geom); read -r fx fy fw fh _ <<<"$g"
  [ -n "${fw:-}" ] || { echo "$1 : fenêtre Konsole introuvable" >> "$OUT/etat.txt"; return 1; }
  { echo "== coins $1 (cadre ${fw}x${fh}+${fx}+${fy})"
    echo "haut-gauche=$(px $1 $fx $fy) haut-droit=$(px $1 $((fx+fw-1)) $fy) bas-gauche=$(px $1 $fx $((fy+fh-1))) bas-droit=$(px $1 $((fx+fw-1)) $((fy+fh-1)))"
  } >> "$OUT/etat.txt"
  convert "$OUT/$1.png" -crop 40x40+$((fx-4))+$((fy-4)) +repage -scale 800% "$OUT/$1-coin-haut-gauche.png"
  convert "$OUT/$1.png" -crop 40x40+$((fx+fw-36))+$((fy+fh-36)) +repage -scale 800% "$OUT/$1-coin-bas-droit.png"
  CORNERS="$(px $1 $fx $fy)|$(px $1 $((fx+fw-1)) $fy)|$(px $1 $fx $((fy+fh-1)))|$(px $1 $((fx+fw-1)) $((fy+fh-1)))"
}
analyse 02-fenetres-ouvertes; AVANT="$CORNERS"
{ echo "== effet avant install : $(kw /Effects org.kde.kwin.Effects.isEffectLoaded string:kwin4_effect_shapecorners | tr -s ' \n' ' ' | sed 's/.*boolean/boolean/')"; } >> "$OUT/etat.txt"
RC_YES=1 bash scripts/install-roundcorners.sh install > "$OUT/install-roundcorners.log" 2>&1; echo "install exit=$?" >> "$OUT/install-roundcorners.log"
sleep 8
bash scripts/install-roundcorners.sh status > "$OUT/status-roundcorners.txt" 2>&1
shot 03-coins-apres; analyse 03-coins-apres; APRES="$CORNERS"
CHARGE=$(kw /Effects org.kde.kwin.Effects.isEffectLoaded string:kwin4_effect_shapecorners | tr -s ' \n' ' ' | sed 's/.*boolean/boolean/')
# Même bureau avec le fond d'écran Windows 11 (rendu final)
[ -n "$WP" ] || echo "ATTENTION : fond Windows 11 introuvable, capture 04 sur fond blanc" >> "$OUT/etat.txt"
[ -n "$WP" ] && qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "for (var d of desktops()) { d.wallpaperPlugin = 'org.kde.image'; d.currentConfigGroup = ['Wallpaper','org.kde.image','General']; d.writeConfig('Image', 'file://$WP'); }" >> "$OUT/apply.log" 2>&1
sleep 12
shot 04-coins-bureau-complet
# Dolphin au premier plan (rendu final : coins arrondis, fond Win11)
cat > "$OUT/raise.js" <<'JS'
for (const w of workspace.windowList()) { if (w.resourceClass.indexOf("dolphin") >= 0) workspace.activeWindow = w; }
JS
RSID=$(kw /Scripting org.kde.kwin.Scripting.loadScript string:"$OUT/raise.js" string:ci-raise$RANDOM | awk '/int32/{print $2}')
kw /Scripting/Script$RSID org.kde.kwin.Script.run >/dev/null; sleep 3
shot 05-dolphin-avant-plan
{ echo "== verdict coins"; echo "avant=$AVANT"; echo "apres=$APRES"; echo "effet charge=$CHARGE"
  if [ "$AVANT" != "$APRES" ] && echo "$CHARGE" | grep -q true; then echo "VERDICT coins: OK"; else echo "VERDICT coins: KO"; fi; } >> "$OUT/etat.txt"

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
{ echo "== barre sur fond blanc (01b) vs fond sombre (01)"; for x in 20 220 $((W-220)); do echo "x=$x sombre=$(convert "$OUT/01-bureau.png" -format "%[pixel:p{$x,$((H-6))}]" info:) blanc=$(convert "$OUT/01b-fond-blanc.png" -format "%[pixel:p{$x,$((H-6))}]" info:)"; done; } >> "$OUT/etat.txt"
convert "$OUT/01-bureau.png" -gravity south -crop "${W}x80+0+0" +repage "$OUT/01-barre-recadree.png" 2>/dev/null
ps aux | grep -E "kwin|plasmashell|konsole|dolphin" | grep -v grep | cut -c1-140 > "$OUT/ps.txt"
