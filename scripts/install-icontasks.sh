#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-icontasks.sh — Icon Tasks (C++ Plasma applet fork)
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

dir="$SRC_DIR/plasma/applets/org.kde.windowsmodern.icontasks"
[ -d "$dir" ] || { warn "Icon Tasks source not found — skipping."; exit 0; }

info "Installing Icon Tasks (C++)..."

if [ -x "$dir/dev.sh" ]; then
    rc=0; ( cd "$dir" && bash dev.sh ) || rc=$?
    if [ "$rc" != 0 ]; then
        if [ "$rc" = 3 ]; then
            err "Icon Tasks compilé et installé, mais plasmashell n'a pas redémarré (code $rc) : voir le journal ci-dessus."
        else
            err "Icon Tasks : échec de dev.sh (code $rc) — compilation, droits (pkexec/sudo) ou garde-fou : voir le journal ci-dessus."
            warn "Dépendances de compilation par distribution : README (section System Tray)."
        fi
        exit 1
    fi
else
    err "dev.sh not found in $dir"
    exit 1
fi
