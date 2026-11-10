#!/bin/bash
# Session Plasma virtuelle (KWin Wayland sans écran) + captures. Usage : ci/screenshot.sh <dossier_sortie>
set -u
OUT="${1:-shots}"; mkdir -p "$OUT"
export XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p $XDG_RUNTIME_DIR; chmod 700 $XDG_RUNTIME_DIR
export KWIN_COMPOSE=Q QT_QPA_PLATFORM=wayland XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=KDE
export KDE_FULL_SESSION=true LC_ALL=C.UTF-8 WAYLAND_DISPLAY=wayland-ci

kwin_wayland --virtual --width 1920 --height 1080 --socket wayland-ci --no-lockscreen > "$OUT/kwin.log" 2>&1 &
sleep 8
plasmashell > "$OUT/plasmashell.log" 2>&1 &
sleep 25
shot() { spectacle -b -n -f -o "$OUT/$1.png" > "$OUT/spectacle-$1.log" 2>&1; sleep 2; ls -l "$OUT/$1.png" 2>&1; }
shot 01-defaut

# --- thème Windows Modern (composants sans reset du layout) ---
plasma-apply-colorscheme WindowsModernDark                  >> "$OUT/apply.log" 2>&1
plasma-apply-desktoptheme Windows-modern-dark               >> "$OUT/apply.log" 2>&1
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum-dark
kwriteconfig6 --file kdeglobals --group Icons --key Theme windows-modern
sleep 8
shot 02-theme-windows
ps aux | grep -E "kwin|plasmashell" | grep -v grep | cut -c1-120 > "$OUT/ps.txt"
