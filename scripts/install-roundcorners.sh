#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-roundcorners.sh — effet KWin « KDE Rounded Corners » (feature 5.1)
#
#  Usage : scripts/install-roundcorners.sh [install|undo|status]   (défaut : install)
#
#  - install : sauvegarde kwinrc, ajoute le PPA matinlotfali/kde-rounded-corners
#              (après confirmation), SIMULE l'installation (refuse si un paquet
#              serait retiré), installe UN seul paquet, vérifie le résultat réel
#              (dpkg -V, propriétaire des fichiers, présence du .so), active
#              l'effet puis recharge KWin. Si une vérification échoue : retour
#              arrière automatique de l'activation.
#  - undo    : désactive l'effet, restaure kwinrc d'avant, désinstalle le paquet.
#  - status  : affiche l'état sans rien modifier.
#
#  Ne touche ni au panneau, ni à plasmashell, ni aux autres paquets.
#  Variables de test : RC_YES=1 (sans confirmation), RC_BACKUP_ROOT, RC_KWINRC.
# ───────────────────────────────────────────────────────────────────
set -euo pipefail

PKG="kwin-effect-roundcorners"
PPA="ppa:matinlotfali/kde-rounded-corners"
EFFECT_ID="kwin4_effect_shapecorners"
SO_REL="kwin/effects/plugins/${EFFECT_ID}.so"
KWINRC="${RC_KWINRC:-$HOME/.config/kwinrc}"
BACKUP_ROOT="${RC_BACKUP_ROOT:-$HOME}"
STATE_FILE="$BACKUP_ROOT/.roundcorners-last-backup"

info() { echo "==> $*"; }
warn() { echo "==> $*" >&2; }
die()  { echo "ERREUR : $*" >&2; exit 1; }

SUDO=""; [ "$(id -u)" -eq 0 ] || SUDO="sudo"

confirm() {
    [ "${RC_YES:-0}" = "1" ] && return 0
    [ -t 0 ] || die "confirmation impossible hors terminal (relancer avec RC_YES=1 pour l'accepter d'avance)"
    read -r -p "$1 [o/N] " a; [[ "$a" =~ ^[oOyY]$ ]]
}

is_installed() { dpkg -s "$PKG" 2>/dev/null | grep -q '^Status: install ok installed'; }

plugin_file() {
    # Chemin réel du .so, d'après le contenu du paquet (pas de chemin supposé).
    dpkg -L "$PKG" 2>/dev/null | grep -E "/${SO_REL//./\\.}\$" | head -1 || true
}

effect_enabled() {
    [ "$(kreadconfig6 --file kwinrc --group Plugins --key "${EFFECT_ID}Enabled" 2>/dev/null || true)" = "true" ]
}

reload_kwin() {
    if command -v qdbus6 >/dev/null 2>&1 && qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1; then
        info "KWin rechargé."
    elif command -v dbus-send >/dev/null 2>&1 && dbus-send --session --print-reply --dest=org.kde.KWin /KWin org.kde.KWin.reconfigure >/dev/null 2>&1; then
        info "KWin rechargé (dbus-send)."
    else
        warn "KWin non joignable (session absente ?) : l'effet sera pris en compte à la prochaine session."
    fi
}

set_effect() {   # $1 = true|false
    kwriteconfig6 --file kwinrc --group Plugins --key "${EFFECT_ID}Enabled" "$1"
}

do_status() {
    if is_installed; then
        echo "paquet      : installé ($(dpkg-query -W -f='${Version}' "$PKG"))"
        local so; so="$(plugin_file)"; echo "fichier .so : ${so:-ABSENT}"
        [ -n "$so" ] && [ -e "$so" ] || echo "  (le .so annoncé par le paquet n'existe pas sur le disque)"
    else
        echo "paquet      : non installé"
    fi
    if effect_enabled; then echo "effet       : activé dans kwinrc"; else echo "effet       : non activé dans kwinrc"; fi
    [ -f "$STATE_FILE" ] && echo "sauvegarde  : $(cat "$STATE_FILE")" || echo "sauvegarde  : aucune"
}

do_install() {
    command -v kwriteconfig6 >/dev/null || die "kwriteconfig6 introuvable (Plasma 6 requis)"
    command -v apt-get >/dev/null || die "apt-get introuvable"

    # 1. Sauvegarde (avant toute modification)
    local bdir; bdir="$BACKUP_ROOT/backup-kde-roundcorners-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$bdir"
    if [ -f "$KWINRC" ]; then cp -a "$KWINRC" "$bdir/kwinrc"; else echo "(absent)" > "$bdir/kwinrc.absent"; fi
    echo "$bdir" > "$STATE_FILE"
    info "Sauvegarde : $bdir"

    # 2. Dépôt PPA (modifie les sources apt : confirmation explicite)
    if ! grep -rqs "matinlotfali/kde-rounded-corners" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
        confirm "Ajouter le PPA $PPA aux sources apt ?" || die "PPA refusé, rien n'a été modifié (sauvegarde : $bdir)"
        $SUDO add-apt-repository -y "$PPA"
    fi
    $SUDO apt-get update

    # 3. Disponibilité + simulation : aucun retrait de paquet toléré
    apt-cache policy "$PKG" | grep -q 'Candidate: [^(]' || die "$PKG sans candidat pour cette version d'Ubuntu"
    local sim; sim="$(apt-get install -s "$PKG")"
    echo "$sim" | grep -E '^(Inst|Remv|Conf) ' || true
    if echo "$sim" | grep -q '^Remv '; then die "la simulation retirerait des paquets : abandon"; fi
    confirm "Installer $PKG (et seulement lui) ?" || die "installation refusée (sauvegarde : $bdir)"

    # 4. Installation d'un seul paquet, sans recommandations
    $SUDO apt-get install -y --no-install-recommends "$PKG"

    # 5. Contrôle du résultat réel
    local so; so="$(plugin_file)"
    [ -n "$so" ] && [ -e "$so" ] || die "installé, mais le .so $SO_REL est introuvable (rien n'est activé)"
    local f o
    while read -r f; do
        [ -f "$f" ] || continue
        o="$(dpkg -S "$f" 2>/dev/null | cut -d: -f1 | sort -u | tr '\n' ' ')"
        [ "$o" = "$PKG " ] || die "$f appartient à : $o (rien n'est activé)"
    done < <(dpkg -L "$PKG")
    if dpkg -V "$PKG" | grep -v '/usr/share/locale/'; then die "dpkg -V signale des écarts (rien n'est activé)"; fi
    info "Contrôles de paquet OK."

    # 6. Activation + rechargement ; retour arrière si l'écriture n'est pas relue
    set_effect true
    if ! effect_enabled; then
        [ -f "$bdir/kwinrc" ] && cp -a "$bdir/kwinrc" "$KWINRC"
        die "l'activation n'a pas été relue dans kwinrc : kwinrc restauré"
    fi
    reload_kwin
    info "Effet $EFFECT_ID activé. Vérifier visuellement : coins arrondis sur une fenêtre ouverte."
    info "Retour arrière : scripts/install-roundcorners.sh undo"
}

do_undo() {
    command -v kwriteconfig6 >/dev/null || die "kwriteconfig6 introuvable"
    # Désactivation d'abord (KWin ne doit plus référencer l'effet avant la suppression du .so)
    set_effect false
    reload_kwin
    if [ -f "$STATE_FILE" ] && [ -f "$(cat "$STATE_FILE")/kwinrc" ]; then
        info "Restauration de kwinrc depuis $(cat "$STATE_FILE")"
        cp -a "$(cat "$STATE_FILE")/kwinrc" "$KWINRC"
        reload_kwin
    else
        warn "Aucune sauvegarde de kwinrc trouvée : seule l'activation a été retirée."
    fi
    if is_installed; then
        confirm "Désinstaller $PKG ?" || { info "Paquet conservé (effet désactivé)."; return 0; }
        $SUDO apt-get remove -y "$PKG"
        is_installed && die "$PKG est toujours installé"
    fi
    info "Retour arrière terminé (le PPA reste dans les sources apt : ppa-purge ou add-apt-repository -r $PPA pour l'enlever)."
}

case "${1:-install}" in
    install) do_install ;;
    undo)    do_undo ;;
    status)  do_status ;;
    *) die "usage : $0 [install|undo|status]" ;;
esac
