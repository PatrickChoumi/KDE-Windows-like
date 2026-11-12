# Méthode de travail (Claude ↔ Patrick) — KDE Windows-like

> **À l'attention d'une autre IA (ou d'un humain) qui reprend ce travail : lis ce fichier en entier avant de toucher au dépôt, puis `docs/PLAN-WINDOWS11-PIXEL-PERFECT.md`.** C'est la méthode exacte suivie jusqu'ici ; respecte-la.
>
> Ce document doit être mis à jour dès que la méthode change (nouvel outil, nouvelle règle, nouvelle contrainte). Chaque changement : modifier la section concernée et la ligne « Dernière mise à jour ». Une copie est aussi tenue dans le projet claude.ai « Kde Windows like » (`claude/methode-de-travail.md`) : garder les deux identiques.
> Dernière mise à jour : 2026-11-12 (version 13).

## 1. Cadre et contraintes de l'utilisateur
- Objectif : copie la plus fidèle possible de Windows 11 sur Ubuntu 26.04 + KDE Plasma 6.6.6, sans casser le bureau. Plan détaillé : `docs/PLAN-WINDOWS11-PIXEL-PERFECT.md`. Liste complète des fonctionnalités attendues, avec état : `docs/FONCTIONNALITES-WIN11.md` (références Windows 11 : `docs/reference-win11/`). Mettre à jour les états de cette liste après chaque correctif validé.
- Consommer le moins de tokens possible : réponses courtes, pas de recap des étapes, une action à la fois quand il le demande.
- Ne jamais lancer de commande destructive, ne rien supprimer sans sauvegarde, ne pas mettre à jour toute la distribution, ne pas réinstaller Ubuntu, préserver données, favoris et configurations.
- Ne jamais croire qu'un script a réussi parce qu'il affiche « Done » : vérifier le résultat réel (journal, présence du fichier, `dpkg -V`, capture).
- Focus actuel : travailler **sur GitHub** (l'utilisateur ne veut plus de commandes à exécuter chez lui, sauf nécessité).
- Offre Claude gratuite : pas de contrôle de l'ordinateur, pas de navigateur piloté, pas de tâches planifiées.
- L'utilisateur écrit en français : répondre en français.

## 2. Où est le travail
- Dépôt : `PatrickChoumi/KDE-Windows-like` (fork de Jeysef/KDE-Windows-Modern, GPL-3.0).
- `main` = stable (contient 3 correctifs : Kirigami.Badge x2, filterByVirtualDesktop).
- `dev` = travail en cours (correctifs, CI, scripts). On fusionne dans `main` après validation visuelle.
- Branches `ci-shots-native` et `ci-shots-fork` = captures et journaux du dernier run (écrasées à chaque run).

## 3. Boucle de travail (un correctif à la fois)
1. Lire l'état réel (code, journaux CI, captures) avant de conclure. Ne pas supposer.
2. Un correctif = un commit, message `fix(...)`/`ci(...)`/`feat(...)`/`docs(...)`, avec les lignes d'attribution de l'outil utilisé. Pour Claude :
   `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>` et `Claude-Session: <url de session>`.
3. Pousser sur `dev`, laisser la CI tourner, lire le résultat, corriger.
4. Dire clairement ce qui est vérifié, ce qui est supposé, et ce qui n'a pas été testé.
5. Si une conclusion précédente se révèle fausse, le dire immédiatement avec la preuve (déjà arrivé : « pas d'icontasks natif » était faux ; « l'icône générique = icontasks » était faux : c'était le bouton Démarrer, sans thème d'icônes actif).
6. Quand la cause n'est pas évidente : instrumenter la CI (trace par étape, test isolé) plutôt que deviner.
7. **Mesurer avant de corriger un écart visuel** : analyser les pixels de la capture (PIL) pour obtenir hauteur de barre, taille des éléments, position de l'indicateur, puis comparer aux valeurs Windows 11 du plan.
8. Après chaque correctif validé : envoyer les captures à l'utilisateur (recadrées, zoom si utile), mettre à jour ce fichier (§5 leçons, §6 état) et la copie du projet, puis proposer la prochaine étape du plan.
9. Fin de réponse : court. Ce qui est fait et vérifié, ce qui reste non testé, une prochaine étape.

## 4. Outils et accès
- Clonage et push : `gh`/`git` via le proxy ; le dépôt est ajouté à la session avec droit d'écriture. Avant de pousser : `git fetch origin dev`.
- Les artefacts GitHub Actions ne sont pas téléchargeables depuis le bac à sable (accès refusé) → la CI publie captures et journaux sur les branches `ci-shots-<variante>`, lues par `git clone --depth 1 -b ci-shots-<variante>`. Vérifier `RUN.txt` (id du run) pour être sûr de lire le bon run.
- CI (`.github/workflows/`) :
  - `build.yml` (`build-and-check`) : garde-fou API (chaînes interdites `Kirigami.Badge`, `filterByCurrentVirtualDesktop`), compilation de l'Icon Tasks sur `ubuntu:26.04`, `qmllint`, syntaxe des scripts.
  - `screenshots.yml` : matrice `native`/`fork`, session X11 virtuelle (Xvfb + `kwin_x11` en `KWIN_COMPOSE=N` + plasmashell), captures `01-defaut`, `02-theme-windows`, `03-lookandfeel-dark`, `04-fenetres-ouvertes` (Konsole + Dolphin ouverts : seule capture qui montre la barre de tâches), `05-apres-redemarrage-plasmashell`, `06-test-icones` (Kirigami.Icon via `qmltestrunner`, `ci/icon-test.qml`). Journaux de diagnostic : `icon-diag.txt`, `icon-trace.txt`, `svgtoqml.log`. Un run dure 4–15 min.
  - **Déclenchement** : `screenshots.yml` ne démarre au push que si `ci/**` ou son propre fichier change. Après un changement ailleurs (QML, `scripts/`…), lancer : `gh workflow run screenshots.yml --repo PatrickChoumi/KDE-Windows-like --ref dev`. Attendre ensuite les deux workflows (`build-and-check` et `screenshots`) sur le même commit, et ne pas boucler plus de ~9 min par commande (limite 10 min) : reprendre l'attente dans une commande suivante.
  - La CI tourne en **root** : les paquets d'icônes vont dans `/usr/share/icons`, pas `~/.local`.
- Vérifier une capture : recadrer la barre (`convert x.png -crop 700x80+610+1000`) avant de la lire pour économiser les tokens ; zoom `-scale 800%` pour juger les pixels. Mesures par pixel avec Python/PIL.
- Pas de KDE dans le bac à sable : tester les scripts avec des commandes simulées (stubs `kreadconfig6`/`kwriteconfig6` dans un `PATH` temporaire) et les QML par la CI.

## 5. Leçons techniques acquises (à respecter)
- Un plugin ne doit jamais prendre l'identifiant d'un plugin ou d'un dossier natif sans vérifier le propriétaire : `dpkg -S`, et `dpkg -V` sur **tous** les paquets liés (`plasma-desktop`, `plasma-desktop-data`, `plasma-workspace`). `dev.sh` contient maintenant ce garde-fou.
- `/usr/share/plasma/plasmoids/org.kde.plasma.icontasks` appartient à `plasma-desktop-data` ; le fork ne doit rien y supprimer. Le fork a son propre identifiant `org.kde.windowsmodern.icontasks` (commit `effb308`).
- Ne pas mettre d'`Id` dans le `metadata.json` d'un plugin C++ : Plasma le signale et l'ignore (retiré).
- Le fork est reconnaissable : `iconsOnly: true` figé dans `main.qml` → barre en icônes seules ; le natif `taskmanager` affiche du texte.
- `addWidget()` renvoie un objet même si l'applet est absente : les replis du layout ne fonctionnent pas ; on remplace à l'installation (`resolve_layout_applets` dans `install-lib.sh`, paire `windowsmodern.icontasks=plasma.taskmanager`).
- `install-lib.sh` est en `set -euo pipefail` : ne pas écrire `ls glob… | grep -q .` pour tester une présence (faux négatif si un glob ne correspond à rien). Utiliser une boucle `[ -e ]`.
- La CI avait `kwin_x11` mort au démarrage (`KWIN_COMPOSE=Q` non supporté) : aucun gestionnaire de fenêtres, aucune tâche visible. Toujours vérifier `ps.txt` / `kwin.log` avant de juger une capture.
- **Thème d'icônes** : `plasma-apply-lookandfeel -a … --resetLayout` **efface `[Icons] Theme` de `kdeglobals`** (mesuré en CI). Sans thème actif, `start-here` n'existe pas dans Breeze → icône générique sur le bouton Démarrer. Corrigé : `ensure_icon_theme` dans `scripts/install-lib.sh`, appelée par `apply_lookandfeel` (ne touche à rien si le pack est absent ou si le thème est déjà bon) ; la CI appelle la même fonction. Le cas « utilisateur avait choisi un autre thème » est écrasé volontairement juste après l'application du thème Windows Modern.
- Le fichier `start-here.svg` du pack est valide (rendu rsvg et Qt direct OK) ; `kcmicons` n'est pas lu par KIconTheme (seul `kdeglobals` compte).
- **Barre de tâches (rendu)** : le thème Plasma `widgets/tasks.svg` (9 tranches, préfixes `north-*` pour un panneau en bas) donnait des boutons carrés pleine hauteur avec un liseré de 3 px **en haut**. Une pastille centrée est impossible dans un cadre 9 tranches : fond et indicateur sont donc dessinés en QML dans `Task.qml` (`win11Button`, `win11Indicator`), le cadre SVG étant gardé invisible (`opacity: 0`) pour ses marges. Valeurs : bouton inset 4 px haut/bas et 2 px côtés, rayon 4 ; pastille 16x3 (active, couleur d'accent) / 6x3 (ouverte, texte à 60 %), 3 px au-dessus du bas, animation de largeur 150 ms. Pas de pastille pour un lanceur sans fenêtre.
- **Icônes de la barre** : `Kirigami.Icon` remplissait tout le conteneur (~32 px de boîte, 28 px visibles). Fixée à 24 px centrée dans `Task.qml` (hors popup de groupe). Le pack d'icônes a une marge interne : une boîte de 24 px donne ~20 px de contenu visible (même valeur que le bouton Démarrer) ; ne pas confondre les deux mesures. Largeur de bouton déjà conforme : 44 px avec 4 px d'écart (tâche de 48 px moins 2 px de marge de chaque côté).
- **« Afficher le bureau »** : l'applet du fork (`org.kde.windowsmodern.showdesktop`, 6 px) était déjà conforme à Win11 : invisible au repos, trait vertical de 1 px sur 50 % de la hauteur au survol. Vérifié par captures `07-bureau-repos` / `07-bureau-survol` (souris placée avec `xdotool`, installé par la CI). Défaut corrigé : le trait était centré sur toute la zone cliquable (qui s'étend jusqu'au bord de l'écran) et tombait sur le dernier chiffre de l'horloge (x=1912) ; il est ancré à 2 px du bord droit (x=1917, 4 px après l'horloge). Le job `native` utilise aussi cet applet (seuls icontasks/systray/… sont remplacés).
- `kquitapp6` n'existe pas dans le conteneur CI : le « redémarrage » de plasmashell passe par `pkill`.
- L'erreur `kf.package: Could not find required file "mainscript" … org.kde.plasma.icontasks/` apparaît aussi sans le fork (panneau par défaut de Plasma dans le conteneur) : elle n'est pas causée par le fork.
- Plasma 6.6 : `filterByVirtualDesktop` (plus `filterByCurrentVirtualDesktop`), pas de `Kirigami.Badge`.
- `kwin_wayland` en conteneur : capability refusée ; la CI utilise X11 (Xvfb) pour pouvoir capturer.
- `install.sh all` et `--resetLayout` réécrivent le panneau : à éviter sur la machine réelle, acceptables dans la CI jetable.
- KWin ignore `wmctrl -b add,demands_attention` (état vide sur `_NET_WM_STATE`) : pour tester l'état « attention » en CI, un script KWin (`loadScript` via dbus, `w.demandsAttention = true`) fonctionne (run 43178371494).
- **Boutons Recherche / Vue des tâches** : un seul applet QML `org.kde.windowsmodern.shortcutbutton` (clé `General/action` = `search`|`taskview`), tuile 48 px, icône 24 px (SVG masqués dans `contents/icons/`). Recherche = `qdbus6 org.kde.krunner /App org.kde.krunner.App.display`, Vue des tâches = `qdbus6 org.kde.kglobalaccel /component/kwin … invokeShortcut Overview`, lancés via `P5Support.DataSource` (moteur `executable`). Le clic ne se teste pas en CI (le journal montre `kglobalaccel`, portail, PipeWire et udisks absents : bruit d'environnement, pas dû à l'applet) : à vérifier sur la machine réelle. Sans applet installée, `resolve_layout_applets` retire ses lignes du layout.
- **`applet_available` en root** : `kpackagetool6` installe dans `~/.local/share/plasma/plasmoids` même en root (CI), alors que `APPLETS_DIR` vaut `/usr/share/plasma/plasmoids` en root. Le test ne regardait pas `~/.local` : le menu du fork était jugé absent et le layout retombait sur Kickoff (capture 09 du run 43188663895). Corrigé (`fafd1f5`). Toujours vérifier dans `icon-diag.txt` (`plugin=`) quel applet est réellement chargé.
- **Favoris du menu Démarrer en CI** : « Entry is not valid » tant que le cache des services n'existe pas. Il faut `XDG_MENU_PREFIX=plasma-` puis `kbuildsycoca6 --noincremental` **avant** de (re)lancer plasmashell (`applications.menu` seul est introuvable en conteneur ; seul `plasma-applications.menu` existe). Fait dans `ci/screenshot.sh` (étape 05).
- **Menu Démarrer Win11** : `BottomBar.qml` = champ de recherche seul (placé en haut), `FooterBar.qml` = avatar + nom + alimentation, `PinnedTile.qml` = tuile icône 32 px + libellé ; `PinnedPage.qml` = `GridView` 6 colonnes. Les délégués utilisent `root`, `sharedContextMenu` et `kicker` par portée dynamique (comme `ListItemDelegate`).
- `qt6-declarative-dev-tools` ne fournit pas `qml` (runtime) mais `qmltestrunner` : utilisable pour tester du QML dans la CI.

## 6. État et prochaine étape
- Validé par capture CI du 2026-11-12 (run 43174550056, commit `0aef4f1`) : fork sous identifiant propre, barre 48 px en icônes seules, bouton Démarrer avec le logo Windows 11, boutons arrondis 44 px / écart 4 px, icônes 24 px, pastille d'activité en bas 16x3 / 6x3, état « attention » (fond orange + pastille orange 16x3, run 43178371494, commit `62cca84`), « Afficher le bureau » (trait au survol, bord droit), `build-and-check` vert (qmllint compris).
- Limites connues : rendu CI sans composition (barre ni translucide ni flottante) ; non testé sur la machine réelle ; l'indicateur n'est dessiné que pour une barre horizontale (`!vertical`) ; l'état « progression » n'a plus de rendu propre (cadre SVG invisible) ; couleurs de survol/actif (6 % / 9 % / 12 % du texte) non comparées à une référence Windows 11 (Phase 0 : références non capturées).
- Compromis accepté : avec un identifiant propre, le menu Démarrer ne propose plus « Ajouter au gestionnaire de tâches » (libkicker ne reconnaît pas le fork).
- Côté utilisateur : 3 commits locaux non poussés (metadata Id, exit code icontasks, résumé d'échecs `install.sh`) ; le commit « metadata Id » est contraire au retrait de l'`Id` (conflit probable au pull).
- Validé aussi (run 43186295862, commit `c237b85`) : boutons Recherche et Vue des tâches entre Démarrer et les applications, `build-and-check` vert.
- Horloge : date `M/d/yyyy` validée (run 43187508732, commit `9c688b3`, via `dateFormat=custom` dans les layouts) ; l'heure suit la locale (24 h dans la CI).
- Menu Démarrer au format Win11 validé en CI (run 43193526420, commit `e2ebf91`) : recherche en haut, grille « Épinglé » 6 colonnes, pied avatar + alimentation. Reste : section « Recommandés », vue « Toutes les applications » en grille, menu d'alimentation, liseré d'accent, rayon/ombre.
- (historique) Menu Démarrer du fork chargé et ouvert en CI (capture `09-menu-demarrer`, run 43189631314) : centré, mais disposition type Win10 (recherche en bas, colonne Places, pas de Recommandés).
- Ensuite : Phase 2 (menu Démarrer : capture « menu ouvert » en CI d'abord). Translucidité Mica / marges flottantes : impossible à valider en CI sans composition.

## 7. Quand modifier ce document
Mettre à jour dès que : une contrainte de l'utilisateur change, un outil/accès apparaît ou disparaît, la structure des branches ou de la CI change, ou une leçon technique est invalidée. Indiquer la date et incrémenter la version en tête.
