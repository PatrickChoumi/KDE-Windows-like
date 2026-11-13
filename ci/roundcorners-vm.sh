#!/bin/bash
# Feature 5.1, variante Wayland : kwin_wayland --virtual (VM réelle ubuntu-latest = Ubuntu 26.04 ; kwin-wayland est en 6.6.6, comme le plugin ; kwin-x11 reste en 6.6.4
# sur Ubuntu 26.04 et refuse l'effet). Composition OpenGL logicielle. Exécute le VRAI scripts/install-roundcorners.sh.
# Usage : ci/roundcorners-wayland.sh <dossier_sortie>   (sous dbus-run-session, HOME=/root, root)
set -u
OUT="${1:-shots}"; mkdir -p "$OUT"
export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p $XDG_RUNTIME_DIR; chmod 700 $XDG_RUNTIME_DIR
export XDG_CURRENT_DESKTOP=KDE KDE_FULL_SESSION=true XDG_SESSION_TYPE=wayland
export LC_ALL=C.UTF-8 LIBGL_ALWAYS_SOFTWARE=1 QT_QUICK_BACKEND=software
unset DISPLAY
kw() { dbus-send --session --print-reply --dest=org.kde.KWin "$@" 2>&1; }
getcap /usr/bin/kwin_wayland > "$OUT/getcap.txt" 2>&1
KW=/usr/bin/kwin_wayland   # VM réelle : pas de conteneur, cap_sys_nice autorisée
"$KW" --help > "$OUT/kwin-wayland-help.txt" 2>&1
QPA=$(find /usr/lib -name 'libwayland-org.kde.kwin.qpa.so' 2>/dev/null | head -1)
{ echo "QPA=$QPA"; ldd "$QPA" 2>&1 | grep -iE "not found|=> not" || echo "ldd QPA : aucune bibliothèque manquante"; ldd "$KW" 2>&1 | grep -i "not found" || echo "ldd kwin : OK"; dpkg -l | awk '/qt6-wayland|waylandcompositor|libqt6wayland|kwin-wayland/{print $2, $3}'; } > "$OUT/qpa-diag.txt" 2>&1
ls -l /dev/dri > "$OUT/dri.txt" 2>&1; env | grep -E "^(QT_|WAYLAND|XDG_|EGL|LIBGL|DISPLAY)" > "$OUT/env.txt"
launch_kwin() {  # $1 = étiquette, le reste = variables d'environnement ; réussit seulement si la composition est OpenGL (gl2)
  local tag="$1"; shift
  env "$@" QT_LOGGING_RULES="kwin_*=true;kwin.*=true;qt.qpa.*=true;qt.core.plugin.loader=false;qt.core.plugin.factoryloader=false" "$KW" --virtual --width 1920 --height 1080 --socket wayland-0 --no-lockscreen > "$OUT/kwin-$tag.log" 2>&1 &
  KWPID=$!
  for i in $(seq 1 25); do [ -S "$XDG_RUNTIME_DIR/wayland-0" ] && break; kill -0 $KWPID 2>/dev/null || return 1; sleep 1; done
  [ -S "$XDG_RUNTIME_DIR/wayland-0" ] || return 1
  for i in $(seq 1 10); do
    ct=$(kw /Compositor org.freedesktop.DBus.Properties.Get string:org.kde.kwin.Compositing string:compositingType | tr -s ' \n' ' ')
    echo "$tag compositingType: $ct" >> "$OUT/kwin-essai.txt"
    case "$ct" in *gl2*|*gles*) return 0;; esac; sleep 1
  done
  return 1
}
ls -l /dev/dri /dev/kvm > "$OUT/dri.txt" 2>&1
: > "$OUT/kwin-essai.txt"
ok=0
for spec in "A KWIN_COMPOSE=O2 LIBGL_ALWAYS_SOFTWARE=1" \
            "B KWIN_COMPOSE=O2 LIBGL_ALWAYS_SOFTWARE=1 EGL_PLATFORM=surfaceless MESA_LOADER_DRIVER_OVERRIDE=llvmpipe" \
            "C KWIN_COMPOSE=O2 EGL_PLATFORM=gbm" \
            "D LIBGL_ALWAYS_SOFTWARE=1"; do
  set -- $spec
  launch_kwin "$@" && { echo "kwin_wayland : essai $1 retenu" >> "$OUT/kwin-essai.txt"; ok=1; break; }
  echo "kwin_wayland : essai $1 sans OpenGL, on arrête et on passe au suivant" >> "$OUT/kwin-essai.txt"
  kill $KWPID 2>/dev/null; sleep 2; rm -f "$XDG_RUNTIME_DIR"/wayland-0*
done
[ "$ok" = 1 ] || { echo "AUCUN essai OpenGL : repli QPainter (essai D) dans le dernier journal" >> "$OUT/kwin-essai.txt"; launch_kwin E LIBGL_ALWAYS_SOFTWARE=1 || true; }
cat "$OUT/kwin-essai.txt"
ln -sf "$(ls "$OUT"/kwin-?.log | tail -1)" "$OUT/kwin.log" 2>/dev/null || true
ls -l "$XDG_RUNTIME_DIR" > "$OUT/runtime-dir.txt" 2>&1
export WAYLAND_DISPLAY=wayland-0 QT_QPA_PLATFORM=wayland

shot() {  # spectacle (interface ScreenShot2 de KWin) ; repli : rien
  spectacle -b -n -f -o "$OUT/$1.png" > "$OUT/spectacle-$1.log" 2>&1; ls -l "$OUT/$1.png" 2>&1 | tee -a "$OUT/spectacle-$1.log"
}
geom() {  # géométrie du cadre de la fenêtre Konsole, via un script KWin (print -> kwin.log)
  cat > "$OUT/geom.js" <<'JS'
for (const w of workspace.windowList()) {
  if (w.caption.indexOf("Konsole") >= 0 || w.resourceClass.indexOf("konsole") >= 0)
    print("GEOM " + w.frameGeometry.x + " " + w.frameGeometry.y + " " + w.frameGeometry.width + " " + w.frameGeometry.height + " | client " + w.clientGeometry.x + " " + w.clientGeometry.y + " " + w.clientGeometry.width + " " + w.clientGeometry.height);
}
JS
  local sid; sid=$(kw /Scripting org.kde.kwin.Scripting.loadScript string:"$OUT/geom.js" string:ci-geom$RANDOM | awk '/int32/{print $2}')
  kw /Scripting/Script$sid org.kde.kwin.Script.run >/dev/null; sleep 2
  grep -a "GEOM" "$OUT/kwin.log" | tail -1 | sed 's/.*GEOM //'
}
px() { convert "$OUT/$1.png" -format "%[pixel:p{$2,$3}]" info: 2>/dev/null; }
analyse() {  # $1 = nom de capture ; mesure les pixels du coin haut-gauche et haut-droit du cadre, recadre x8
  local g fx fy fw fh
  g=$(geom); echo "$1 geom: $g" >> "$OUT/etat.txt"
  read -r fx fy fw fh _ <<<"$g"; [ -n "${fw:-}" ] || { echo "$1 : fenêtre Konsole introuvable" >> "$OUT/etat.txt"; return; }
  {
    echo "$1 pixels (cadre ${fw}x${fh}+${fx}+${fy}) :"
    echo "  coin exact haut-gauche (0,0)  = $(px $1 $fx $fy)"
    echo "  (1,1)                         = $(px $1 $((fx+1)) $((fy+1)))"
    echo "  (3,3)                         = $(px $1 $((fx+3)) $((fy+3)))"
    echo "  (8,8) intérieur               = $(px $1 $((fx+8)) $((fy+8)))"
    echo "  coin exact haut-droit         = $(px $1 $((fx+fw-1)) $fy)"
    echo "  coin exact bas-gauche         = $(px $1 $fx $((fy+fh-1)))"
    echo "  coin exact bas-droit          = $(px $1 $((fx+fw-1)) $((fy+fh-1)))"
  } >> "$OUT/etat.txt"
  convert "$OUT/$1.png" -crop 40x40+$((fx-4))+$((fy-4)) +repage -scale 800% "$OUT/$1-coin-haut-gauche.png"
  convert "$OUT/$1.png" -crop 40x40+$((fx+fw-36))+$((fy-4)) +repage -scale 800% "$OUT/$1-coin-haut-droit.png"
  convert "$OUT/$1.png" -crop 40x40+$((fx-4))+$((fy+fh-36)) +repage -scale 800% "$OUT/$1-coin-bas-gauche.png"
  convert "$OUT/$1.png" -crop 40x40+$((fx+fw-36))+$((fy+fh-36)) +repage -scale 800% "$OUT/$1-coin-bas-droit.png"
}
state() {
  { echo "== $1"
    kw /Compositor org.freedesktop.DBus.Properties.Get string:org.kde.kwin.Compositing string:compositingType | tr -s ' \n' ' '; echo
    kw /Effects org.freedesktop.DBus.Properties.Get string:org.kde.kwin.Effects string:loadedEffects | grep -o 'kwin4_effect_shapecorners' | head -1 || true
    kw /Effects org.kde.kwin.Effects.isEffectLoaded string:kwin4_effect_shapecorners | tr -s ' \n' ' '; echo
    echo "kwinrc: $(kreadconfig6 --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled)"
  } >> "$OUT/etat.txt"
}

dbus-send --session --dest=org.freedesktop.DBus / org.freedesktop.DBus.ListNames >/dev/null 2>&1
plasmashell > "$OUT/plasmashell.log" 2>&1 &
sleep 20
plasma-apply-colorscheme WindowsModernDark >> "$OUT/apply.log" 2>&1
plasma-apply-desktoptheme Windows-modern-dark >> "$OUT/apply.log" 2>&1
( source scripts/install-lib.sh; ensure_icon_theme windows-modern; ensure_window_decoration dark ) >> "$OUT/apply.log" 2>&1
kw /KWin org.kde.KWin.reconfigure >/dev/null
WP=$(find /root/.local/share/wallpapers/Windows-modern -type f \( -name '*.jpg' -o -name '*.png' \) 2>/dev/null | head -1)
[ -n "$WP" ] && plasma-apply-wallpaperimage "$WP" >> "$OUT/apply.log" 2>&1
sleep 5
konsole -e bash > "$OUT/konsole.log" 2>&1 &
sleep 12
kw /KWin org.kde.KWin.reconfigure >/dev/null; sleep 4
cp /root/.config/kwinrc "$OUT/kwinrc-avant.txt" 2>/dev/null || true

state "1-avant"; shot 01-avant; analyse 01-avant

RC_YES=1 bash scripts/install-roundcorners.sh install > "$OUT/install.log" 2>&1; echo "install exit=$?" >> "$OUT/install.log"
sleep 8
bash scripts/install-roundcorners.sh status > "$OUT/status-apres-install.txt" 2>&1
state "2-apres-install"; shot 02-apres-install; analyse 02-apres-install
cp /root/.config/kwinrc "$OUT/kwinrc-apres.txt" 2>/dev/null || true
kw /Effects org.freedesktop.DBus.Properties.Get string:org.kde.kwin.Effects string:loadedEffects > "$OUT/loaded-effects.txt" 2>&1

RC_YES=1 bash scripts/install-roundcorners.sh undo > "$OUT/undo.log" 2>&1; echo "undo exit=$?" >> "$OUT/undo.log"
sleep 8
bash scripts/install-roundcorners.sh status > "$OUT/status-apres-undo.txt" 2>&1
state "3-apres-undo"; shot 03-apres-undo; analyse 03-apres-undo
ps aux | grep -E "kwin|plasmashell|konsole" | grep -v grep | cut -c1-140 > "$OUT/ps.txt"
