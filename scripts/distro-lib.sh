#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  distro-lib.sh — détection de la distribution et requêtes de paquets
#  Source-able (aucun effet de bord). Familles : debian, fedora, arch, suse, unknown.
#  Pour les tests : DISTRO_OS_RELEASE=/chemin/os-release remplace /etc/os-release.
# ───────────────────────────────────────────────────────────────────

# Famille de la distribution, d'après ID puis ID_LIKE.
distro_family() {
    local f="${DISTRO_OS_RELEASE:-/etc/os-release}" id="" like="" w
    [ -r "$f" ] || { echo unknown; return 0; }
    id="$(sed -n 's/^ID=//p' "$f" | head -1 | tr -d '"' | tr 'A-Z' 'a-z')"
    like="$(sed -n 's/^ID_LIKE=//p' "$f" | head -1 | tr -d '"' | tr 'A-Z' 'a-z')"
    for w in $id $like; do
        case "$w" in
            debian|ubuntu|linuxmint|pop|neon|kali|raspbian) echo debian; return 0 ;;
            fedora|rhel|centos|rocky|almalinux|nobara)      echo fedora; return 0 ;;
            arch|manjaro|endeavouros|cachyos|garuda)        echo arch;   return 0 ;;
            suse|opensuse|opensuse-leap|opensuse-tumbleweed|sles) echo suse; return 0 ;;
        esac
    done
    echo unknown
}

# Gestionnaire de paquets disponible pour la famille (vide si l'outil est absent).
pkg_tool() {
    case "$(distro_family)" in
        debian) command -v dpkg   >/dev/null 2>&1 && echo dpkg ;;
        fedora|suse) command -v rpm >/dev/null 2>&1 && echo rpm ;;
        arch)   command -v pacman >/dev/null 2>&1 && echo pacman ;;
    esac
    return 0
}

# pkg_owner CHEMIN : affiche le paquet propriétaire du fichier.
#   code 0 = appartient à un paquet ; 1 = n'appartient à aucun paquet ; 2 = impossible à déterminer
#   (distribution inconnue ou outil absent : l'appelant doit alors prévenir, jamais conclure « sûr »).
pkg_owner() {
    local p="$1" out
    case "$(pkg_tool)" in
        dpkg)   out="$(dpkg -S "$p" 2>/dev/null)" && { echo "$out"; return 0; } || return 1 ;;
        rpm)    out="$(rpm -qf "$p" 2>/dev/null)" && { echo "$out"; return 0; } || return 1 ;;
        pacman) out="$(pacman -Qo "$p" 2>/dev/null)" && { echo "$out"; return 0; } || return 1 ;;
        *)      return 2 ;;
    esac
}

# pkg_version PAQUET : version installée (vide si absent ou outil inconnu).
pkg_version() {
    case "$(pkg_tool)" in
        dpkg)   dpkg-query -W -f='${Version}' "$1" 2>/dev/null ;;
        rpm)    rpm -q --qf '%{VERSION}-%{RELEASE}' "$1" 2>/dev/null | grep -v 'not installed' ;;
        pacman) pacman -Q "$1" 2>/dev/null | awk '{print $2}' ;;
    esac
    return 0
}

# pkg_installed PAQUET : code 0 si installé.
pkg_installed() { [ -n "$(pkg_version "$1")" ]; }

# plasma_version : « 6.6.6 » (vide si plasmashell est absent).
plasma_version() {
    command -v plasmashell >/dev/null 2>&1 || return 0
    plasmashell --version 2>/dev/null | sed -n 's/^plasmashell \([0-9][0-9.]*\).*/\1/p' | head -1
}
