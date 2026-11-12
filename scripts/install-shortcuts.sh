#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-shortcuts.sh — boutons Recherche / Vue des tâches (QML pur)
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

src="$SRC_DIR/plasma/applets/org.kde.windowsmodern.shortcutbutton"
[ -d "$src" ] || { warn "Shortcut button not found — skipping."; exit 0; }

info "Installing Search / Task View button applet..."
ensure_dir "$APPLETS_DIR"
rm -rf "$APPLETS_DIR/org.kde.windowsmodern.shortcutbutton"
cp -r "$src" "$APPLETS_DIR/"
[ -f "$APPLETS_DIR/org.kde.windowsmodern.shortcutbutton/metadata.json" ] || { err "Copy failed"; exit 1; }
info "Search / Task View button installed."

if is_batch; then
    exit 0
fi

command -v kbuildsycoca6 &>/dev/null && kbuildsycoca6 2>/dev/null || true
if pgrep -x plasmashell >/dev/null 2>&1; then
    restart_plasmashell
else
    warn "Plasma Shell not running — button will load on next session."
fi
