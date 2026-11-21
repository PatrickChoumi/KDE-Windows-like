#!/bin/bash
# ───────────────────────────────────────────────────────────────────
#  install-dolphin.sh — Dolphin : barre de commandes facon Explorateur Win11
#  Usage : ./install.sh dolphin           installe (sauvegarde l'existant)
#          bash scripts/install-dolphin.sh --undo   restaure l'etat precedent
#  Aucun paquet touche ; un seul fichier utilisateur + 2 cles dolphinrc.
# ───────────────────────────────────────────────────────────────────
source "$(dirname "$0")/install-lib.sh"

src="$SRC_DIR/config/dolphin/dolphinui.rc"
dstdir="${XDG_DATA_HOME:-$HOME/.local/share}/kxmlgui5/dolphin"
dst="$dstdir/dolphinui.rc"
bak="$dstdir/dolphinui.rc.windowsmodern-backup"
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/dolphinrc"
cfgbak="$cfg.windowsmodern-backup"
smrc="${XDG_CONFIG_HOME:-$HOME/.config}/kservicemenurc"
smbak="$smrc.windowsmodern-backup"

if [ "${1:-}" = "--undo" ]; then
    if [ -e "$bak" ]; then mv -f "$bak" "$dst"; info "dolphinui.rc precedent restaure."
    elif [ -e "$dst" ] && grep -q 'name="renamefile"' "$dst"; then rm -f "$dst"; info "dolphinui.rc du fork supprime (defaut Dolphin)."
    else warn "Rien a annuler pour dolphinui.rc."; fi
    if [ -e "$cfgbak" ]; then mv -f "$cfgbak" "$cfg"; info "dolphinrc restaure."; fi
    if [ -e "$smbak" ]; then mv -f "$smbak" "$smrc"; info "kservicemenurc restaure."
    elif command -v kwriteconfig6 >/dev/null 2>&1; then kwriteconfig6 --file kservicemenurc --group Show --key setfoldericonitemaction --delete; fi
    exit 0
fi

[ -e "$src" ] || { warn "config/dolphin/dolphinui.rc introuvable — ignore."; exit 0; }
if pgrep -x dolphin >/dev/null 2>&1; then
    warn "Dolphin est ouvert : ferme-le puis relance (le fichier est lu au demarrage)."
fi

ensure_dir "$dstdir"
if [ -e "$dst" ] && ! cmp -s "$src" "$dst" && [ ! -e "$bak" ]; then
    cp -a "$dst" "$bak"; info "Sauvegarde : $bak"
fi
[ -e "$cfg" ] && [ ! -e "$cfgbak" ] && cp -a "$cfg" "$cfgbak"
[ -e "$smrc" ] && [ ! -e "$smbak" ] && cp -a "$smrc" "$smbak"
cp -f "$src" "$dst"

if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file dolphinrc --group MainWindow --group "Toolbar mainToolBar" --key ToolButtonStyle IconOnly
    kwriteconfig6 --file dolphinrc --group MainWindow --group "Toolbar mainToolBar" --key IconSize 16
    # Barre d'etat pleine largeur (« N elements » comme l'Explorateur), au lieu de la pastille « Small » de KDE.
    kwriteconfig6 --file dolphinrc --group General --key ShowStatusBar FullWidth
    # Menu contextuel : retire la rangee « couleur de dossier » propre a KDE (absente de l'Explorateur Win11).
    kwriteconfig6 --file kservicemenurc --group Show --key setfoldericonitemaction false
else
    warn "kwriteconfig6 absent : icones seules non forcees (clic droit sur la barre > Afficher le texte)."
fi

# Verification du resultat reel (pas du message « Done »)
if cmp -s "$src" "$dst" && grep -q 'name="renamefile"' "$dst"; then
    info "Dolphin : barre de commandes installee ($dst)."
else
    err "Verification echouee : $dst ne correspond pas a la source."; exit 1
fi
