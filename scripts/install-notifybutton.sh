#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-notifybutton.sh — bouton du centre de notifications (QML pur)
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

src="$SRC_DIR/plasma/applets/org.kde.windowsmodern.notifybutton"
[ -d "$src" ] || { warn "Notification button not found — skipping."; exit 0; }

info "Installing notification centre button applet..."
ensure_dir "$APPLETS_DIR"
rm -rf "$APPLETS_DIR/org.kde.windowsmodern.notifybutton"
cp -r "$src" "$APPLETS_DIR/"
[ -f "$APPLETS_DIR/org.kde.windowsmodern.notifybutton/metadata.json" ] || { err "Copy failed"; exit 1; }
info "Notification centre button installed."

if is_batch; then
    exit 0
fi

command -v kbuildsycoca6 &>/dev/null && kbuildsycoca6 2>/dev/null || true
if pgrep -x plasmashell >/dev/null 2>&1; then
    restart_plasmashell
else
    warn "Plasma Shell not running — button will load on next session."
fi
