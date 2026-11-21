#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  Windows Modern Icon Tasks — dev cycle
#
#  The ONLY command to build and install this C++ applet.
#  Do NOT copy directories to ~/.local/share/plasma/plasmoids/
#  or /usr/share/plasma/plasmoids/ — that causes the dark rectangle.
#
#  Usage:  ./dev.sh
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SRC_DIR/build"
APP_ID="org.kde.windowsmodern.icontasks"
LAYOUT_FILE="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"

BOLD="\033[1m"; GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; RESET="\033[0m"
info()  { echo -e "${GREEN}==>${RESET} ${BOLD}$*${RESET}"; }
warn()  { echo -e "${YELLOW}==>${RESET} $*"; }
err()   { echo -e "${RED}==>${RESET} $*"; }

# ── Detect install paths ───────────────────────────────────────────
detect_paths() {
    if command -v pkg-config &>/dev/null; then
        QT_PLUGIN_DIR=$(pkg-config --variable=plugindir Qt6Core 2>/dev/null || true)
    fi
    if [ -z "${QT_PLUGIN_DIR:-}" ]; then
        if [ -d /usr/lib64/qt6/plugins ]; then
            QT_PLUGIN_DIR=/usr/lib64/qt6/plugins
        elif [ -d /usr/lib/qt6/plugins ]; then
            QT_PLUGIN_DIR=/usr/lib/qt6/plugins
        else
            QT_PLUGIN_DIR=/usr/lib64/qt6/plugins
        fi
    fi
    PLUGIN_DST="$QT_PLUGIN_DIR/plasma/applets"
    KPACKAGE_DIR="/usr/share/plasma/plasmoids/${APP_ID}"
}

# ── Build ─────────────────────────────────────────────────────────
info "Building..."
cmake -S "$SRC_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release > /dev/null
cmake --build "$BUILD_DIR" --parallel "$(nproc)" 2>&1 | tail -3

# ── Stop plasmashell ──────────────────────────────────────────────
info "Stopping plasmashell..."
# plasmashell peut tourner sous son service systemd (session normale) ou lancé à la main (banc de test, session minimale) :
# on le redémarre de la même façon qu'on l'a arrêté.
UNIT_ACTIVE=0; systemctl --user is-active --quiet plasma-plasmashell.service 2>/dev/null && UNIT_ACTIVE=1
MANUAL_SHELL=0; [ "$UNIT_ACTIVE" = 0 ] && pgrep -x plasmashell >/dev/null 2>&1 && MANUAL_SHELL=1
if [ "$MANUAL_SHELL" = 1 ]; then pkill -x plasmashell 2>/dev/null || true; else systemctl --user stop plasma-plasmashell.service 2>/dev/null || true; fi
sleep 1

# ── Garde-fou : l'identifiant ne doit jamais être celui d'un paquet natif ──
# (collision = Plasma lit les métadonnées du paquet et ignore notre .so)
# Indépendant de la distribution : dpkg, rpm ou pacman selon /etc/os-release (scripts/distro-lib.sh).
DISTRO_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/scripts/distro-lib.sh"
[ -r "$DISTRO_LIB" ] || { err "scripts/distro-lib.sh introuvable : garde-fou impossible, abandon (rien n'a été modifié)."; exit 1; }
source "$DISTRO_LIB"
detect_paths   # définit PLUGIN_DST (le garde-fou le contrôle aussi)
GUARD_UNKNOWN=0
for p in "/usr/share/plasma/plasmoids/${APP_ID}" "${PLUGIN_DST}/${APP_ID}.so" \
         "/usr/lib/x86_64-linux-gnu/qt6/plugins/plasma/applets/${APP_ID}.so" "/usr/lib64/qt6/plugins/plasma/applets/${APP_ID}.so" \
         "/usr/lib/qt6/plugins/plasma/applets/${APP_ID}.so"; do
    [ -e "$p" ] || continue
    rc=0; owner="$(pkg_owner "$p")" || rc=$?
    if [ "$rc" = 0 ]; then
        err "L'identifiant ${APP_ID} appartient déjà à un paquet : $owner"
        err "Abandon : aucun fichier système n'a été modifié."
        exit 1
    elif [ "$rc" = 2 ]; then
        GUARD_UNKNOWN=1
    fi
done
[ "$GUARD_UNKNOWN" = 0 ] || warn "Distribution « $(distro_family) » : propriétaire des fichiers non vérifiable (aucun gestionnaire de paquets reconnu). Garde-fou NON appliqué."

# ── Fix layout if corrupted ───────────────────────────────────────
if grep -q "plugin=metadata" "$LAYOUT_FILE" 2>/dev/null; then
    info "Fixing corrupted plugin=metadata in layout..."
    sed -i "/\[Containments\]\[.*\]\[Applets\]/,/\[/s/^plugin=metadata$/plugin=${APP_ID}/" "$LAYOUT_FILE"
fi

# ── Install .so only (no KPackage) ───────────────────────────────
info "Installing..."
PLUGIN_SRC="$BUILD_DIR/lib/plasma/applets/${APP_ID}.so"
detect_paths

# Elevation : root direct, sinon pkexec (PC reel avec session graphique), sinon sudo (CI, serveur).
if [ "$(id -u)" = 0 ]; then ASROOT=()
elif command -v pkexec >/dev/null 2>&1; then ASROOT=(pkexec)
elif command -v sudo >/dev/null 2>&1; then ASROOT=(sudo)
else echo "ERREUR : ni pkexec ni sudo disponibles." >&2; exit 1; fi
"${ASROOT[@]}" bash -s <<INSTALLEOF
set -e
mkdir -p "$PLUGIN_DST"
cp "$PLUGIN_SRC" "$PLUGIN_DST/"
# NB: on n'installe que le .so du fork (identifiant propre) et on ne supprime rien dans /usr/share :
# /usr/share/plasma/plasmoids/org.kde.plasma.icontasks appartient à plasma-desktop-data (applet native).
echo "Installed."
INSTALLEOF

# Also prune local copies (stale .so in ~/.local/lib* takes precedence over /usr)
rm -rf "$HOME/.local/share/plasma/plasmoids/${APP_ID}" 2>/dev/null || true
rm -f "$HOME/.local/lib64/qt6/plugins/plasma/applets/${APP_ID}.so" 2>/dev/null || true
rm -f "$HOME/.local/lib/qt6/plugins/plasma/applets/${APP_ID}.so" 2>/dev/null || true

info "Installed."

# ── Start plasmashell ────────────────────────────────────────────
# In batch mode (WM_BATCH=1) the parent 'all' driver restarts Plasma
# Shell once at the very end — skipping the start here avoids a storm
# of restarts when systray + icontasks install back-to-back.
if [ "${WM_BATCH:-0}" = "1" ]; then
    info "Installed (batch mode — Plasma Shell will restart at end of 'all')."
    exit 0
fi

info "Restarting plasmashell..."
if [ "$MANUAL_SHELL" = 1 ]; then
    setsid -f plasmashell >/dev/null 2>&1 || true
    sleep 3
    pgrep -x plasmashell >/dev/null 2>&1 || { err "Le .so est installé, mais plasmashell ne redémarre pas (lancement direct)."; exit 3; }
elif ! systemctl --user start plasma-plasmashell.service; then
    err "Le .so est installé, mais plasmashell ne redémarre pas (plantage au démarrage)."
    journalctl --user -u plasma-plasmashell.service -n 40 --no-pager 2>/dev/null | cut -c1-220 || true
    exit 3
fi
sleep 3

info "Done. If the taskbar is blank, check System Settings → Add Widgets."
