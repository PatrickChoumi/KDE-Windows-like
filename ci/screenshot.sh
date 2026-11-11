#!/bin/bash
# Session Plasma virtuelle X11 (Xvfb + kwin_x11) + captures ImageMagick. Usage : ci/screenshot.sh <dossier_sortie>
set -u
OUT="${1:-shots}"; mkdir -p "$OUT"
export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p $XDG_RUNTIME_DIR; chmod 700 $XDG_RUNTIME_DIR
export DISPLAY=:99 QT_QPA_PLATFORM=xcb XDG_SESSION_TYPE=x11 XDG_CURRENT_DESKTOP=KDE KDE_FULL_SESSION=true
export LC_ALL=C.UTF-8 LIBGL_ALWAYS_SOFTWARE=1 QT_QUICK_BACKEND=software KWIN_COMPOSE=N

Xvfb :99 -screen 0 1920x1080x24 +extension GLX +render -noreset > "$OUT/xvfb.log" 2>&1 &
sleep 3
kwin_x11 > "$OUT/kwin.log" 2>&1 &
sleep 4
for d in /usr/libexec/kactivitymanagerd /usr/bin/kactivitymanagerd /usr/lib/x86_64-linux-gnu/libexec/kactivitymanagerd; do
  [ -x "$d" ] && { "$d" > "$OUT/kactivities.log" 2>&1 & echo "kactivitymanagerd: $d" > "$OUT/info.txt"; break; }
done
sleep 3
plasmashell > "$OUT/plasmashell.log" 2>&1 &
sleep 25
shot() { import -window root "$OUT/$1.png" > "$OUT/import-$1.log" 2>&1; ls -l "$OUT/$1.png" 2>&1; }
shot 01-defaut

# --- thème Windows Modern (sans reset du layout) ---
plasma-apply-colorscheme WindowsModernDark    >> "$OUT/apply.log" 2>&1
plasma-apply-desktoptheme Windows-modern-dark >> "$OUT/apply.log" 2>&1
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum-dark
kwriteconfig6 --file kdeglobals --group Icons --key Theme windows-modern
sleep 10
shot 02-theme-windows
# --- look-and-feel complet du dépôt (layout inclus ; session jetable, le reset est sans risque) ---
WP=$(find /root/.local/share/wallpapers/Windows-modern -type f \( -name '*.jpg' -o -name '*.png' \) 2>/dev/null | head -1)
[ -n "$WP" ] && plasma-apply-wallpaperimage "$WP" >> "$OUT/apply.log" 2>&1
plasma-apply-lookandfeel -a org.kde.windowsmodern.dark --resetLayout >> "$OUT/apply.log" 2>&1
sleep 15
shot 03-lookandfeel-dark
# --- fenêtres ouvertes : la barre en icônes seules n'est visible que s'il y a des tâches ---
konsole -e bash > "$OUT/konsole.log" 2>&1 &
dolphin > "$OUT/dolphin.log" 2>&1 &
sleep 15
shot 04-fenetres-ouvertes
# --- test : plasmashell relancé après le changement de thème d'icônes (cache d'icônes périmé ?) ---
kquitapp6 plasmashell >> "$OUT/apply.log" 2>&1; sleep 3; pkill -x plasmashell 2>/dev/null; sleep 2
plasmashell > "$OUT/plasmashell-restart.log" 2>&1 &
sleep 20
shot 05-apres-redemarrage-plasmashell
# --- test direct de résolution d'icônes via Kirigami.Icon ---
QMLBIN=$(command -v qml6 || command -v qml || find /usr/lib /usr/bin -maxdepth 4 \( -name qml -o -name qml6 -o -name qml-qt6 \) -type f 2>/dev/null | head -1)
dpkg -L qt6-declarative-dev-tools 2>/dev/null | grep -i "bin/" > "$OUT/qml-files.txt"
echo "qml: $QMLBIN" > "$OUT/icon-qml.log"
if [ -n "$QMLBIN" ]; then
  "$QMLBIN" ci/icon-test.qml >> "$OUT/icon-qml.log" 2>&1 &
  sleep 8
  shot 06-test-icones
  pkill -f icon-test.qml 2>/dev/null
fi
# --- diagnostic de l'icône du bouton Démarrer ---
{
  echo "== theme (kcmicons / kdeglobals)"; kreadconfig6 --file kcmicons --group Icons --key Theme; kreadconfig6 --file kdeglobals --group Icons --key Theme
  echo "== fichiers"; ls -l /usr/share/icons/windows-modern/places/start-here*.svg /usr/share/icons/windows-modern/apps/start-here*.svg 2>&1
  echo "== index.theme (Inherits)"; grep -n "^Inherits\|^Directories" /usr/share/icons/windows-modern/index.theme | cut -c1-200
  echo "== themes breeze presents"; ls -d /usr/share/icons/breeze* 2>&1
  echo "== cache et resolution"; ls -l /usr/share/icons/windows-modern/icon-theme.cache 2>&1; ls /usr/share/icons/windows-modern/places | head -3; python3 -c "import os;print(os.path.getsize('/usr/share/icons/windows-modern/places/start-here.svg'))" 2>&1
  echo "== appletsrc : icon/kickoff"; grep -n "kickoff\|^icon=\|icon=" /root/.config/plasma-org.kde.plasma.desktop-appletsrc 2>&1 | head -20
  echo "== plasmashell : icon"; grep -in "icon" "$OUT/plasmashell.log" | head -10
} > "$OUT/icon-diag.txt" 2>&1
ps aux | grep -E "Xvfb|kwin|plasmashell|kactivity" | grep -v grep | cut -c1-120 > "$OUT/ps.txt"
# trigger
