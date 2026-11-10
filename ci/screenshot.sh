#!/bin/bash
# Session Plasma virtuelle X11 (Xvfb + kwin_x11) + captures ImageMagick. Usage : ci/screenshot.sh <dossier_sortie>
set -u
OUT="${1:-shots}"; mkdir -p "$OUT"
export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p $XDG_RUNTIME_DIR; chmod 700 $XDG_RUNTIME_DIR
export DISPLAY=:99 QT_QPA_PLATFORM=xcb XDG_SESSION_TYPE=x11 XDG_CURRENT_DESKTOP=KDE KDE_FULL_SESSION=true
export LC_ALL=C.UTF-8 LIBGL_ALWAYS_SOFTWARE=1 QT_QUICK_BACKEND=software KWIN_COMPOSE=Q

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
ps aux | grep -E "Xvfb|kwin|plasmashell|kactivity" | grep -v grep | cut -c1-120 > "$OUT/ps.txt"
