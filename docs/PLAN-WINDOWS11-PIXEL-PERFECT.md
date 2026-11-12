# Plan : KDE Plasma 6.6.6 → Windows 11 (Ubuntu 26.04)

> L'avancement à jour est dans `docs/METHODE-DE-TRAVAIL.md` §6 (le bloc « État au 10/11/2026 » ci-dessous est l'état de départ, conservé tel quel).

Base : fork `PatrickChoumi/KDE-Windows-like` (dérivé de Jeysef/KDE-Windows-Modern).
Règle : un module à la fois, sauvegarde avant, vérification après, retour arrière prêt. Pas de `install.sh all`, pas de `--resetLayout`.

## État au 10/11/2026
- Plasma natif restauré (taskmanager + systemtray natifs), panneau flottant centré 46 px, police Inter, Aurorae Windows-modern, horloge M/d/yyyy.
- Fork : 3 correctifs poussés (Kirigami.Badge x2, filterByVirtualDesktop) ; 3 commits locaux NON poussés (metadata Id, exit code icontasks, résumé d'échecs install.sh).
- `install-icontasks-safe.sh` (build + bascule + annulation auto) à relancer avec les correctifs ; non validé tant qu'on n'a pas vu une barre en icônes seules.
- Restent : menu Démarrer perso, coins arrondis des 4 angles, indicateur d'activité, tray/flyouts, Kvantum, login.

## Limites assumées (impossibles sur KDE)
Flyout Snap Layouts au survol de « agrandir », panneau Widgets, barre de recherche intégrée à la barre, ClearType, vrai Mica (flou dynamique du fond d'écran), police Segoe UI Variable (propriétaire, non redistribuable). Cible réaliste : ~90 %.

## Phase 0 : référence et mesure (avant de toucher quoi que ce soit)
1. Pousser les 3 commits locaux. Tag `baseline-2026-11-10`.
2. Capturer des références Windows 11 (VM ou machine réelle) en 1920x1080, thème sombre et clair : bureau, barre, menu Démarrer, centre de notifications, calendrier, Explorateur, Paramètres, fenêtre normale/inactive, menu contextuel, boîte de dialogue.
3. Tableau de spécifications mesurées sur ces captures (à vérifier, valeurs typiques) : barre 48 px, icônes 24 px, rayon fenêtres 8 px, rayon contrôles 4 px, barre de titre 32 px, boutons de titre 46x32 px, accent sombre #4CC2FF / clair #0067C0, espacement icônes 4 px.
4. Script de comparaison : capture Plasma (`spectacle -b -n -o`) + comparaison ImageMagick (`compare -metric RMSE`) par zone recadrée. Seuil d'acceptation par zone.
Critère de sortie : référence + tableau de specs validés.

## Phase 1 : barre des tâches
1. Compiler/installer Icon Tasks corrigé (`install-icontasks-safe.sh`). Critère : aucune erreur au journal, icônes seules, lanceurs intacts.
2. Indicateur d'activité : pastille 16x3 px (actif) / 6x3 px (ouvert), accent. Fond survol/appui. Dans le QML icontasks + thème Plasma.
3. Hauteur 48 px, marges flottantes 8 px, translucidité type Mica (opacité + flou KWin), icône 24 px.
4. Bouton « Afficher le bureau » en bord fin, séparateur, ordre des applets.
Critère : comparaison zone barre sous le seuil.

## Phase 2 : menu Démarrer
1. `./install.sh startmenu`, basculer l'applet (Afficher les alternatives), journal propre.
2. Aligner sur Win11 : champ de recherche en haut, grille « Épinglé » 6 colonnes, « Recommandés », barre utilisateur/alimentation, rayon 8 px, ombre, animation d'ouverture.
3. Raccourci Meta, ouverture centrée au-dessus de la barre, fermeture au clic extérieur.

## Phase 3 : zone de notification, horloge, flyouts
1. Garder le System Tray natif ; styler via le thème Plasma (icônes monochromes, espacements).
2. Horloge 2 lignes, popup calendrier style Win11. Centre rapide (réseau, son, luminosité) : popups natifs restylés.
3. Systray C++ du fork : à n'envisager qu'après validation complète du reste (risque élevé, déjà source de panne).

## Phase 4 : fenêtres
1. Effet KWin de coins arrondis (4 angles + liseré) : vérifier la disponibilité sur Ubuntu 26.04 avant installation (paquet ou compilation).
2. Aurorae : titre 32 px, boutons 46x32 px, rouge #C42B1C au survol de fermeture, glyphes fins, titre aligné à gauche, ombres Win11, bordure 1 px.
3. Tiling : zones Win11 (Meta+flèches), animations rapides (fondu/échelle).

## Phase 5 : widgets Qt (Kvantum) et GTK
1. Kvantum : boutons rayon 4 px, hauteur 32 px, focus ring accent, cases/toggles Fluent, barres de défilement fines, menus rayon 8 px, onglets, champs.
2. Applications GTK (Chrome, Nautilus…) : thème GTK Fluent-like + `kde-gtk-config`, libadwaita via variables.
3. Palette : variables de `docs/STYLE.md` comme source unique ; vérifier sombre et clair.

## Phase 6 : typographie, icônes, curseur, sons
1. Police : Inter (par défaut) ; Segoe UI Variable seulement si tu l'obtiens légalement. Crénage/hinting `fontconfig` (slight, rgba=none).
2. Icônes : pack du fork, compléter les manquantes (dossiers, types MIME, apps courantes) ; échelles 16/24/32/48.
3. Curseur type Windows 11 et sons système (optionnel).

## Phase 7 : verrouillage et connexion
1. Lock screen (Meta+L) du fork, fond et horloge Win11.
2. Écran de connexion : thème SDDM (le login actuel est SDDM). Pas de PLM/greeter remplaçant sans test en session de secours (TTY).
3. Splash Plymouth/KDE (optionnel).

## Phase 8 : applications « de base »
- Dolphin : barre, fil d'Ariane, panneau gauche, icônes, densité type Explorateur.
- Konsole : profil façon Windows Terminal. Paramètres système : page d'accueil épurée. Notifications : toasts coins arrondis en bas à droite.

## Phase 9 : vérification et livraison
1. `verify-all.sh` + journal plasmashell/kwin sans erreur + redémarrage complet + session après 24 h.
2. Comparaison pixel par zone vs références ; liste des écarts restants.
3. Committer par module sur le fork, README à jour (tableau des correctifs Plasma 6.6.6, limites), tag de version.
4. Procédure de retour arrière documentée (sauvegardes `~/backup-kde-*`, `undo` de chaque script).

## Risques et garde-fous
- Un plugin ne doit jamais prendre l'identifiant d'un plugin natif sans contrôle `dpkg -S`.
- Tout script vérifie le résultat réel (journal, présence du fichier, `dpkg -V`), pas son message « Done ».
- Après une mise à jour Plasma d'Ubuntu : recompiler les applets C++ (API Qt/KF6 changeantes) ou revenir aux natifs.
- Aucune mise à jour globale de la distribution ; paquets installés un par un après simulation `-s`.
