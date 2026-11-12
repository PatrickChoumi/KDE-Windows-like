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
ic() { echo "$1: [$(kreadconfig6 --file kdeglobals --group Icons --key Theme)] kdeglobals=$(stat -c %s ${XDG_CONFIG_HOME:-$HOME/.config}/kdeglobals 2>&1)" >> "$OUT/icon-trace.txt"; }
shot() { import -window root "$OUT/$1.png" > "$OUT/import-$1.log" 2>&1; ls -l "$OUT/$1.png" 2>&1; }
shot 01-defaut
ic apres-01

# --- thème Windows Modern (sans reset du layout) ---
plasma-apply-colorscheme WindowsModernDark    >> "$OUT/apply.log" 2>&1
ic apres-colorscheme-ET-avant-desktoptheme-sera-mesure-ici
plasma-apply-desktoptheme Windows-modern-dark >> "$OUT/apply.log" 2>&1
ic apres-desktoptheme
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum-dark
kwriteconfig6 --file kdeglobals --group Icons --key Theme windows-modern
ic apres-kwriteconfig-icons
sleep 10
shot 02-theme-windows
ic apres-02
# --- look-and-feel complet du dépôt (layout inclus ; session jetable, le reset est sans risque) ---
WP=$(find /root/.local/share/wallpapers/Windows-modern -type f \( -name '*.jpg' -o -name '*.png' \) 2>/dev/null | head -1)
[ -n "$WP" ] && plasma-apply-wallpaperimage "$WP" >> "$OUT/apply.log" 2>&1
plasma-apply-lookandfeel -a org.kde.windowsmodern.dark --resetLayout >> "$OUT/apply.log" 2>&1; echo "lookandfeel exit=$?" >> "$OUT/apply.log"
ic apres-lookandfeel
# plasma-apply-lookandfeel --resetLayout vide [Icons] Theme (mesuré : 2795 -> 2745 octets) :
# on appelle la fonction des scripts utilisateur (scripts/install-lib.sh) pour la valider en conditions réelles.
( source scripts/install-lib.sh; ensure_icon_theme windows-modern ) >> "$OUT/apply.log" 2>&1
ic apres-remise-du-theme-icones
sleep 15
shot 03-lookandfeel-dark
# --- fenêtres ouvertes : la barre en icônes seules n'est visible que s'il y a des tâches ---
konsole -e bash > "$OUT/konsole.log" 2>&1 &
dolphin > "$OUT/dolphin.log" 2>&1 &
sleep 15
shot 04-fenetres-ouvertes
# --- test : plasmashell relancé après le changement de thème d'icônes (cache d'icônes périmé ?) ---
# Cache des services (.desktop) : sans lui, les favoris du menu Démarrer sont « Entry is not valid » (vu en CI).
# KDE cherche /etc/xdg/menus/${XDG_MENU_PREFIX}applications.menu : en conteneur sans préfixe, « applications.menu not found » et le cache reste vide.
ls /etc/xdg/menus > "$OUT/sycoca.log" 2>&1
export XDG_MENU_PREFIX=plasma-
kbuildsycoca6 --noincremental >> "$OUT/sycoca.log" 2>&1
kquitapp6 plasmashell >> "$OUT/apply.log" 2>&1; sleep 3; pkill -x plasmashell 2>/dev/null; sleep 2
plasmashell > "$OUT/plasmashell-restart.log" 2>&1 &
sleep 20
shot 05-apres-redemarrage-plasmashell
# --- test direct de résolution d'icônes via Kirigami.Icon (qmltestrunner) ---
QTR=/usr/lib/qt6/bin/qmltestrunner
for f in start-here start-here-kde; do echo "== svgtoqml $f"; /usr/lib/qt6/bin/svgtoqml /usr/share/icons/windows-modern/places/$f.svg "$OUT/$f.qml" 2>&1 | head -15; done > "$OUT/svgtoqml.log" 2>&1
if [ -x "$QTR" ]; then
  QT_QPA_PLATFORM=xcb "$QTR" -input ci/icon-test.qml > "$OUT/icon-qml.log" 2>&1 &
  sleep 9
  shot 06-test-icones
  pkill -f qmltestrunner 2>/dev/null
else
  echo "qmltestrunner absent" > "$OUT/icon-qml.log"
fi
# --- état « attention » : un script KWin met demandsAttention sur la fenêtre Konsole (inactive) ---
cat > "$OUT/attention.js" <<'JS'
for (const w of workspace.windowList()) {
    if (w.caption.indexOf("Konsole") >= 0) { w.demandsAttention = true; print("attention-script: " + w.caption + " -> " + w.demandsAttention); }
}
JS
SID=$(dbus-send --session --print-reply --dest=org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript string:"$OUT/attention.js" string:ci-attention 2>&1 | awk '/int32/{print $2}')
echo "script id=[$SID]" > "$OUT/attention.log"
dbus-send --session --print-reply --dest=org.kde.KWin /Scripting/Script$SID org.kde.kwin.Script.run >> "$OUT/attention.log" 2>&1
sleep 2
for id in $(wmctrl -l 2>/dev/null | awk '/Konsole/{print $1}'); do xprop -id $id _NET_WM_STATE >> "$OUT/attention.log" 2>&1; done
shot 08-attention
# --- survol du bord droit : le trait « Afficher le bureau » doit apparaître (invisible au repos) ---
if command -v xdotool >/dev/null; then
  xdotool mousemove 1200 500; sleep 1
  shot 07-bureau-repos
  xdotool mousemove 1917 1056; sleep 2
  shot 07-bureau-survol
  xdotool mousemove 1200 500
else
  echo "xdotool absent" > "$OUT/xdotool.log"
fi
# --- menu Démarrer ouvert (clic sur le bouton Démarrer, centré sur la barre) ---
if command -v xdotool >/dev/null; then
  L0=$(wc -l < "$OUT/plasmashell.log" 2>/dev/null || echo 0)
  xdotool mousemove 860 1056; sleep 1; xdotool click 1; sleep 4
  shot 09-menu-demarrer
  # vue « Toutes les applications » : clic sur le bouton « All apps » du menu ouvert
  xdotool mousemove 1198 403; sleep 1; xdotool click 1; sleep 3
  shot 10-toutes-applications
  { echo "== lignes plasmashell.log après le clic (depuis $L0)"; tail -n +$((L0+1)) "$OUT/plasmashell.log" 2>/dev/null | head -40; } > "$OUT/startmenu.log" 2>&1
  xdotool key Escape; sleep 1; xdotool mousemove 1200 500
fi
# --- diagnostic de l'icône du bouton Démarrer ---
{
  echo "== theme"; echo "kcmicons=[$(kreadconfig6 --file kcmicons --group Icons --key Theme)]"; echo "kdeglobals=[$(kreadconfig6 --file kdeglobals --group Icons --key Theme)]"
  echo "== env"; env | grep -E "^(HOME|XDG_[A-Z_]*|QT_QPA_PLATFORMTHEME|KDE_[A-Z_]*)=" 
  echo "== kdeglobals (sections Icons/General)"; grep -n -B1 -A3 "^\[Icons\]" "${XDG_CONFIG_HOME:-$HOME/.config}/kdeglobals" 2>&1 | head -12
  echo "== fichiers de config"; ls -l "${XDG_CONFIG_HOME:-$HOME/.config}"/kdeglobals "${XDG_CONFIG_HOME:-$HOME/.config}"/kcmicons 2>&1
  echo "== fichiers"; ls -l /usr/share/icons/windows-modern/places/start-here*.svg /usr/share/icons/windows-modern/apps/start-here*.svg 2>&1
  echo "== index.theme (Inherits)"; grep -n "^Inherits\|^Directories" /usr/share/icons/windows-modern/index.theme | cut -c1-200
  echo "== themes breeze presents"; ls -d /usr/share/icons/breeze* 2>&1
  echo "== cache et resolution"; ls -l /usr/share/icons/windows-modern/icon-theme.cache 2>&1; ls /usr/share/icons/windows-modern/places | head -3; python3 -c "import os;print(os.path.getsize('/usr/share/icons/windows-modern/places/start-here.svg'))" 2>&1
  echo "== appletsrc : icon/kickoff"; grep -n "kickoff\|^icon=\|icon=" /root/.config/plasma-org.kde.plasma.desktop-appletsrc 2>&1 | head -20
  echo "== plasmashell : icon"; grep -in "icon" "$OUT/plasmashell.log" | head -10
} > "$OUT/icon-diag.txt" 2>&1
ps aux | grep -E "Xvfb|kwin|plasmashell|kactivity" | grep -v grep | cut -c1-120 > "$OUT/ps.txt"
# trigger
