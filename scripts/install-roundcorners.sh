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

# Le PPA publie deux paquets : kwin-effect-roundcorners (KWin Wayland) et kwin-effect-roundcorners-x11 (KWin X11, autre dossier de plugins).
# Choix : RC_PKG (forcé) > paquet déjà installé > session X11 (XDG_SESSION_TYPE=x11) > Wayland (défaut).
PKG_WAYLAND="kwin-effect-roundcorners"; PKG_X11="kwin-effect-roundcorners-x11"
pkg_installed() { local o; o="$(dpkg -s "$1" 2>/dev/null || true)"; grep -q '^Status: install ok installed' <<<"$o"; }
if [ -n "${RC_PKG:-}" ]; then PKG="$RC_PKG"
elif pkg_installed "$PKG_X11"; then PKG="$PKG_X11"
elif pkg_installed "$PKG_WAYLAND"; then PKG="$PKG_WAYLAND"
elif [ "${XDG_SESSION_TYPE:-}" = "x11" ]; then PKG="$PKG_X11"
else PKG="$PKG_WAYLAND"; fi
PPA="ppa:matinlotfali/kde-rounded-corners"
EFFECT_ID="kwin4_effect_shapecorners"
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

# Pas de « cmd | grep -q » : sous pipefail, grep -q ferme le tube et la commande amont renvoie 141 (SIGPIPE).
is_installed() { local o; o="$(dpkg -s "$PKG" 2>/dev/null || true)"; grep -q '^Status: install ok installed' <<<"$o"; }

plugin_file() {
    # Chemin réel du .so, d'après le contenu du paquet (pas de chemin supposé).
    dpkg -L "$PKG" 2>/dev/null | grep -E "/${EFFECT_ID}[^/]*\.so\$" | head -1 || true
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

# Version exigee par le plugin (IID compile dans le .so) : KWin refuse l'effet si elle differe de celle de son binaire.
plugin_kwin_version() {  # $1 = chemin du .so
    grep -a -o -E 'EffectPluginFactory[0-9]+\.[0-9]+\.[0-9]+' "$1" 2>/dev/null | head -1 | sed 's/EffectPluginFactory//' || true
}

check_kwin_versions() {  # avertit si un binaire KWin installe n'a pas la version du plugin
    local so="$1" want pkg have bad=0
    want="$(plugin_kwin_version "$so")"
    [ -n "$want" ] || { warn "version exigee par le plugin illisible : controle de compatibilite ignore."; return 0; }
    for pkg in kwin-wayland kwin-x11; do
        have="$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || true)"
        [ -n "$have" ] || continue
        have="${have#*:}"; have="${have%%-*}"
        if [ "$have" != "$want" ]; then
            warn "$pkg est en $have mais le plugin est compile pour $want : KWin refusera l'effet pour ce binaire ($pkg)."
            bad=1
        fi
    done
    [ "$bad" = 0 ] && info "Versions KWin / plugin concordantes ($want)."
    return 0
}

effect_loaded() {  # vrai si KWin liste l'effet comme charge
    local out=""
    if command -v qdbus6 >/dev/null 2>&1; then
        out="$(qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadedEffects 2>/dev/null || true)"
    fi
    if [ -z "$out" ] && command -v dbus-send >/dev/null 2>&1; then
        out="$(dbus-send --session --print-reply --dest=org.kde.KWin /Effects org.freedesktop.DBus.Properties.Get string:org.kde.kwin.Effects string:loadedEffects 2>/dev/null || true)"
    fi
    grep -q "$EFFECT_ID" <<<"$out"
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

    # Idempotence : paquet déjà installé (relance, ou installé à la main) -> pas de PPA ni d'apt, on passe aux contrôles.
    if is_installed; then
        info "$PKG est déjà installé : étapes PPA / apt ignorées."
    else
        # 2. Dépôt PPA (modifie les sources apt : confirmation explicite)
        if ! grep -rqs "matinlotfali/kde-rounded-corners" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
            command -v add-apt-repository >/dev/null || die "add-apt-repository introuvable : installer d'abord le paquet software-properties-common (sudo apt install software-properties-common). Rien n'a été modifié (sauvegarde : $bdir)"
            confirm "Ajouter le PPA $PPA aux sources apt ?" || die "PPA refusé, rien n'a été modifié (sauvegarde : $bdir)"
            $SUDO add-apt-repository -y "$PPA"
        fi
        $SUDO apt-get update

        # 3. Disponibilité + simulation : aucun retrait de paquet toléré
        local pol; pol="$(apt-cache policy "$PKG" 2>&1 || true)"
        grep -q 'Candidate: [^(]' <<<"$pol" || die "$PKG sans candidat pour cette version d'Ubuntu"
        local sim; sim="$(apt-get install -s "$PKG")"
        echo "$sim" | grep -E '^(Inst|Remv|Conf) ' || true
        if grep -q '^Remv ' <<<"$sim"; then die "la simulation retirerait des paquets : abandon"; fi
        confirm "Installer $PKG (et seulement lui) ?" || die "installation refusée (sauvegarde : $bdir)"

        # 4. Installation d'un seul paquet, sans recommandations
        $SUDO apt-get install -y --no-install-recommends "$PKG"

    fi

    # 5. Contrôle du résultat réel
    local so; so="$(plugin_file)"
    [ -n "$so" ] && [ -e "$so" ] || die "installé, mais le .so ${EFFECT_ID}.so est introuvable (rien n'est activé)"
    local f o
    while read -r f; do
        [ -f "$f" ] || continue
        o="$(dpkg -S "$f" 2>/dev/null | cut -d: -f1 | sort -u | tr '\n' ' ')"
        [ "$o" = "$PKG " ] || die "$f appartient à : $o (rien n'est activé)"
    done < <(dpkg -L "$PKG")
    local vout; vout="$(dpkg -V "$PKG" 2>&1 || true)"; vout="$(grep -v '/usr/share/locale/' <<<"$vout" || true)"
    [ -z "$vout" ] || { echo "$vout"; die "dpkg -V signale des écarts (rien n'est activé)"; }
    info "Contrôles de paquet OK."
    check_kwin_versions "$so"

    # 6. Activation + rechargement ; retour arrière si l'écriture n'est pas relue
    set_effect true
    if ! effect_enabled; then
        [ -f "$bdir/kwinrc" ] && cp -a "$bdir/kwinrc" "$KWINRC"
        die "l'activation n'a pas été relue dans kwinrc : kwinrc restauré"
    fi
    reload_kwin
    sleep 2
    if effect_loaded; then
        info "Effet $EFFECT_ID activé ET chargé par KWin. Vérifier visuellement : coins arrondis sur une fenêtre ouverte."
    else
        warn "Effet $EFFECT_ID activé dans kwinrc mais NON chargé par KWin (version incompatible ou KWin à relancer)."
        warn "Ferme la session puis reconnecte-toi, puis relance : scripts/install-roundcorners.sh status"
    fi
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
