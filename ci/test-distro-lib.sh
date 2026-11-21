#!/bin/bash
# Test de scripts/distro-lib.sh : détection de famille + propriétaire de fichier, avec de faux dpkg/rpm/pacman.
# Aucun paquet réel nécessaire. Sortie : une ligne par cas ; code 1 au premier écart.
set -uo pipefail
cd "$(dirname "$0")/.."
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fail=0
ok()  { echo "OK   $*"; }
ko()  { echo "KO   $*"; fail=1; }
mkdir -p "$T/bin" "$T/min"
for x in sed head tr awk grep cat; do ln -s "$(command -v $x)" "$T/min/$x"; done
# faux outils : « possède » uniquement /usr/share/x/owned
cat > "$T/bin/dpkg"   <<'S'
#!/bin/sh
[ "$1" = "-S" ] && [ "$2" = "/usr/share/x/owned" ] && { echo "plasma-desktop-data: $2"; exit 0; }; exit 1
S
cat > "$T/bin/rpm"    <<'S'
#!/bin/sh
[ "$1" = "-qf" ] && [ "$2" = "/usr/share/x/owned" ] && { echo "plasma-desktop-6.6.6-1.fc44.x86_64"; exit 0; }; exit 1
S
cat > "$T/bin/pacman" <<'S'
#!/bin/sh
[ "$1" = "-Qo" ] && [ "$2" = "/usr/share/x/owned" ] && { echo "/usr/share/x/owned is owned by plasma-desktop 6.6.6-1"; exit 0; }; exit 1
S
chmod +x "$T/bin/"*
mkrel() { printf 'ID=%s\nID_LIKE="%s"\n' "$1" "$2" > "$T/os-$1"; echo "$T/os-$1"; }
check() { # id like famille_attendue outil_present(0/1)
    local rel fam; rel="$(mkrel "$1" "$2")"
    ( export DISTRO_OS_RELEASE="$rel" PATH="$T/bin:/usr/bin:/bin"; source scripts/distro-lib.sh
      fam="$(distro_family)"; [ "$fam" = "$3" ] || { echo "famille=$fam"; exit 10; }
      rc=0; pkg_owner /usr/share/x/owned >/dev/null || rc=$?; [ "$rc" = "$4" ] || { echo "owned rc=$rc"; exit 11; }
      rc=0; pkg_owner /usr/share/x/autre >/dev/null || rc=$?; [ "$rc" = "$5" ] || { echo "autre rc=$rc"; exit 12; } ) \
      && ok "$1 -> $3 (possede=$4, non possede=$5)" || ko "$1 -> $3"
}
check ubuntu    debian                    debian  0 1
check linuxmint "ubuntu debian"           debian  0 1
check fedora    ""                        fedora  0 1
check nobara    "rhel fedora"             fedora  0 1
check arch      ""                        arch    0 1
check cachyos   arch                      arch    0 1
check opensuse-tumbleweed "opensuse suse" suse    0 1
# distribution inconnue : impossible de conclure => code 2 (jamais « sûr »)
( export DISTRO_OS_RELEASE="$(mkrel exoticos "")" PATH="$T/bin:/usr/bin:/bin"; source scripts/distro-lib.sh
  [ "$(distro_family)" = unknown ] || exit 10
  rc=0; pkg_owner /usr/share/x/owned >/dev/null || rc=$?; [ "$rc" = 2 ] ) && ok "distribution inconnue -> code 2" || ko "distribution inconnue"
# famille connue mais outil absent => code 2
( export DISTRO_OS_RELEASE="$(mkrel fedora "")" PATH="$T/min"; source scripts/distro-lib.sh
  [ "$(distro_family)" = fedora ] || exit 10
  rc=0; pkg_owner /usr/share/x/owned >/dev/null || rc=$?; [ "$rc" = 2 ] ) && ok "fedora sans rpm -> code 2" || ko "fedora sans rpm"
# Coins arrondis hors famille Debian : message explicite, code 0, AUCUN appel à apt/sudo (faux apt-get qui échoue s'il est appelé)
printf '#!/bin/sh\necho APPEL-INTERDIT >> "%s/appel.txt"; exit 1\n' "$T" > "$T/bin/apt-get"; cp "$T/bin/apt-get" "$T/bin/sudo"; chmod +x "$T/bin/apt-get" "$T/bin/sudo"
for fam in fedora arch; do
    out="$(DISTRO_OS_RELEASE="$(mkrel $fam "")" PATH="$T/bin:/usr/bin:/bin" HOME="$T" RC_YES=1 bash scripts/install-roundcorners.sh install 2>&1)"; rc=$?
    if [ "$rc" = 0 ] && grep -q "NON installés" <<<"$out" && [ ! -e "$T/appel.txt" ]; then ok "coins arrondis sur $fam : refus explicite, rien modifié"; else ko "coins arrondis sur $fam (rc=$rc)"; fi
done
exit $fail
