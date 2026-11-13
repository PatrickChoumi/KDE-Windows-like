# Fonctionnalités requises pour un Windows 11 « pixel perfect » sur KDE Plasma

Source : les 24 captures de référence fournies par Patrick (`docs/reference-win11/NN.jpeg`, numérotées par ordre alphabétique de nom de fichier ; la n°15 était un doublon exact de la n°14 et n'a pas été copiée). Les mesures et états ci-dessous viennent de ces captures et des captures CI du fork.

**Légende d'état** — ✅ vérifié par capture CI · 🟡 existe dans le dépôt mais non vérifié (ou partiel) · ⬜ à faire · ❌ impossible ou hors périmètre sur KDE.
Les références `[nn]` renvoient aux captures. Les phases `P0…P9` renvoient à `docs/PLAN-WINDOWS11-PIXEL-PERFECT.md`.

---

## 1. Barre des tâches (réf. [14] [23] [24] [05] [06] [09])
| # | Fonctionnalité | État |
|---|---|---|
| 1.1 | Barre pleine largeur, 48 px de haut, en bas | ✅ |
| 1.2 | Groupe Démarrer + applications centré (espaceurs gauche/droite) | 🟡 layout présent, centrage non vu en CI |
| 1.3 | Bouton Démarrer avec le logo Windows 11 | ✅ |
| 1.4 | Icônes en icônes seules, 24 px, boutons 44 px, écart 4 px | ✅ |
| 1.5 | Fond de bouton arrondi (rayon 4 px) au survol et pour la fenêtre active | ✅ (opacités à comparer) |
| 1.6 | Pastille d'activité en bas : 16×3 px accent (active), 6×3 px grise (ouverte) | ✅ |
| 1.7 | Animation de la pastille (largeur) et du fond au survol | 🟡 largeur 150 ms, fond 100 ms |
| 1.8 | Lanceurs épinglés (clic droit « Épingler à la barre »), glisser-déposer pour réordonner | 🟡 hérité du gestionnaire de tâches |
| 1.9 | Aperçu miniature de la fenêtre au survol (vignette + titre + bouton fermer) | 🟡 tooltip natif, non stylé |
| 1.10 | Menu contextuel d'une icône (liste de tâches récentes, épingler, fermer la fenêtre) | 🟡 natif |
| 1.11 | Clic du milieu = nouvelle instance ; survol + molette = changer de fenêtre | 🟡 natif |
| 1.12 | Icônes « Recherche » et « Vue des tâches » à côté du Démarrer (réf. [14] [09] [24]) | ✅ rendu vu en CI (run 43186295862, pas de 48 px) ; clic non testé en CI (pas de kglobalaccel/KRunner) ; « Widgets » et « Discussion » : ⬜ |
| 1.13 | Champ de recherche intégré à la barre (variante [04] [20] [22]) | ❌ |
| 1.14 | Fond de barre translucide type Mica/acrylique, sombre ou clair selon le thème | ⬜ (non vérifiable en CI : pas de composition) |
| 1.15 | Barre non flottante, bord à bord, ombre/liseré supérieur d'1 px | 🟡 |
| 1.16 | État « attention » (icône qui clignote / pastille orange) | ✅ fond orange + pastille orange 16x3 (CI 43178371494) |
| 1.17 | Indicateur de progression (téléchargement/copie) sous l'icône | ⬜ |
| 1.18 | Badges de notification sur les icônes | 🟡 `TaskBadgeOverlay.qml` |
| 1.19 | Barre sur écrans multiples (applications par écran) | 🟡 |
| 1.20 | Masquage automatique de la barre | 🟡 natif |

## 2. Zone de notification, horloge, centre rapide (réf. [14] [23] [05] [22])
| # | Fonctionnalité | État |
|---|---|---|
| 2.1 | Chevron `^` « icônes cachées » avec popup | ✅ chevron vu ; popup 🟡 |
| 2.2 | Icônes de la zone : cloud, langue (« ENG »), puis bloc **Réseau + Son + Batterie** regroupé en un seul bouton | 🟡 System Tray natif ; regroupement ⬜ |
| 2.3 | Horloge sur 2 lignes : heure (ex. `10:42 AM`) et date (ex. `1/30/2022`), alignée à droite | ✅ deux lignes, date `11/12/2026` (CI 43187508732) ; heure en 24 h dans la CI (locale C) : le 12 h `AM/PM` dépend de la locale, non forcé |
| 2.4 | Bouton de notifications à droite de l'horloge, avec pastille de nombre (réf. [23]) | ⬜ |
| 2.5 | « Afficher le bureau » : trait fin au bord droit, visible au survol | ✅ |
| 2.6 | **Centre rapide** (réf. [23]) : tuiles Wi-Fi (avec chevron), Bluetooth, Cellulaire, Mode avion, Assistant de concentration, Accessibilité ; curseurs luminosité et volume (avec flèche de sélection de sortie) ; batterie en %, bouton crayon « Modifier » et engrenage « Paramètres » | ⬜ (popups natifs à restyler, P3) |
| 2.7 | Tuiles actives en accent plein, inactives en gris translucide, rayon 4 px | ⬜ |
| 2.8 | **Centre de notifications + calendrier** (réf. [05] [22]) : liste de toasts regroupés par application, bouton « Effacer tout », boutons d'action (« Sauvegarder maintenant / Ignorer »), calendrier du mois avec jour actuel en pastille accent, bandeau « Focus » avec minuteur 30 min | ⬜ (P3) |
| 2.9 | Toasts de notification en bas à droite, coins arrondis | ⬜ (P8) |
| 2.10 | Info-bulles des icônes de la zone (volume, réseau, batterie) | 🟡 |

## 3. Menu Démarrer (réf. [09] [13] [24] [08])
| # | Fonctionnalité | État |
|---|---|---|
| 3.1 | Fenêtre flottante centrée au-dessus de la barre, rayon 8 px, ombre, fond translucide (clair et sombre) | 🟡 centré, 640×720 px, fond sombre (CI 43193526420) ; rayon 8 px / ombre / translucidité non mesurés (pas de composition en CI) |
| 3.2 | Champ de recherche en haut (« Search for apps, settings, and documents ») avec liseré d'accent en bas quand actif | ✅ en haut, rayon 4 px, liseré d'accent 2 px au focus (CI 43217058274) |
| 3.3 | Section **Épinglé** : grille 6 colonnes × 3 lignes, icône 32 px + libellé sous l'icône, bouton « Toutes les applications > » | ✅ 6 colonnes (pas 96 px), icône 32 px + libellé, « All apps » ; 3 lignes et glisser-déposer non testés |
| 3.4 | Section **Recommandés** : 2 colonnes × 3, icône + nom + sous-titre ; bouton « More > » | 🟡 section, grille 2×3 et texte d'état vide en place, liée aux applications récentes (CI 43198228291, commit `6fadc00`) ; contenu non vu en CI (aucun récent), fichiers récents (ligne « Files ») non branchés |
| 3.5 | Pied de menu : avatar + nom d'utilisateur à gauche, bouton alimentation à droite | ✅ avatar + nom, bouton alimentation icône seule (avatar vide en CI : pas d'image de compte) |
| 3.6 | Vue « Toutes les applications » (réf. [08]) : liste alphabétique avec en-têtes de lettre, grille de l'alphabet au clic sur une lettre, saut vers la section, bouton « Retour » | ✅ en-têtes, grille (lettres sans application grisées), saut, Back (CI 43203472481 et 43204388588, commits `f0fdb3a`, `38e1ed9`) ; défilement réel du saut non vu (la liste de la CI tient à l'écran) |
| 3.7 | Menu d'alimentation : Suspendre / Arrêter / Redémarrer avec icônes fines (réf. [07]) | 🟡 ordre Win11, lignes 36 px, icônes 16 px, coins 8 px (CI 43202074169, commit `ca96b8f`) ; Lock / Log out gardés sous un séparateur ; actions grisées en CI (pas de logind), non testées ; pas d'ombre ni d'animation |
| 3.8 | Épingler / désépingler, réorganiser par glisser-déposer, dossiers d'épinglés | ⬜ |
| 3.9 | Recherche immédiate en tapant dès l'ouverture ; touche Windows (Meta) ouvre/ferme | 🟡 |
| 3.10 | Animation d'ouverture (glissement vers le haut + fondu, ~200 ms) | ✅ trace CI (run 43380171516, commit `dc4ccfc`) : glissement 32 px → 0 et opacité 0 → 1 en 197 ms ; image à 106 ms différente de l'état final (21 635 px), images suivantes identiques |
| 3.11 | Fermeture au clic extérieur et à `Échap` | 🟡 |
| 3.12 | Clic droit sur le bouton Démarrer : menu « Power User » (Win+X) | 🟡 15 entrées au clic droit (CI 43214957855) ; menu Qt natif avec entrées Plasma en plus, sans séparateurs ni sous-menu ; clics non testés |

## 4. Recherche (réf. [12])
| # | Fonctionnalité | État |
|---|---|---|
| 4.1 | Panneau de recherche : champ en haut, colonne « Suggérés » (applications/paramètres récents) à gauche | ⬜ |
| 4.2 | « Recherches rapides » (tuiles de paramètres) et « Applications principales » (grille de tuiles) à droite | ⬜ |
| 4.3 | Résultats groupés (applications, documents, paramètres, web) avec aperçu à droite | ⬜ (peut s'appuyer sur KRunner/Baloo) |
| 4.4 | Raccourci Win+S | ⬜ |

## 5. Fenêtres (réf. [06] [16] [17] [18] [21])
| # | Fonctionnalité | État |
|---|---|---|
| 5.1 | Coins arrondis 8 px sur les 4 angles, liseré 1 px, ombre douce | 🟡 effet KDE Rounded Corners 0.11.0 (PPA `ppa:matinlotfali/kde-rounded-corners`) : installable sur ubuntu:26.04, fichiers sans conflit, liens OK contre KWin 6.6.6 (run 43245109790, commit `b3e94e5`). Rendu non vérifiable en CI (pas de composition) ; `scripts/install-roundcorners.sh [install|undo|status]` écrit (sauvegarde, simulation, contrôles, activation `kwin4_effect_shapecorners`, retour arrière), exécuté pour de vrai en VM CI (install/status/undo OK, `kwinrc` restauré) ; effet refusé par `kwin-x11` 6.6.4 (plugin 6.6.6) donc coins carrés en X11 ; un chargement forcé de l'effet fait planter `kwin_x11` 6.6.4 (run 43366267322) ; rendu à vérifier en session Wayland sur la vraie machine (docs/TESTER-DANS-UNE-VM-CI.md) |
| 5.2 | Barre de titre 32 px, titre aligné à gauche avec icône 16 px | ✅ 32 px, titre à gauche, icône (CI 43228942810) ; nécessite le paquet `kwin-style-aurorae` |
| 5.3 | Boutons réduire / agrandir / fermer : 46×32 px, glyphes fins, fond de survol, fermeture en rouge `#C42B1C` | ✅ vérifié par capture CI (run 43232159100, commit `843ac40`) : 46×32 px, glyphes fins, survol de fermeture `#C42B1C` mesuré sur 46×32 px |
| 5.4 | Fenêtre inactive : titre et glyphes atténués | 🟡 |
| 5.5 | Mica sur la barre de titre (teinte du fond d'écran) | ❌ (approximation par couleur unie) |
| 5.6 | **Snap Layouts** au survol du bouton agrandir (réf. [16]) | ❌ |
| 5.7 | Snap par glisser vers le bord/coin et `Meta`+flèches (moitiés, quarts) | 🟡 tiling KWin, zones Win11 à régler |
| 5.8 | **Vue des tâches** avec bureaux virtuels en bas, bouton « + Nouveau bureau » (réf. [20]) | ⬜ (effet Présentation des fenêtres + sélecteur de bureaux restylés) |
| 5.9 | Alt+Tab : rangée de vignettes arrondies avec titre (aperçu centré) | ⬜ |
| 5.10 | Animations : ouverture (échelle + fondu), réduction vers l'icône de la barre, agrandissement | ⬜ |
| 5.11 | Bordure d'accent facultative sur la fenêtre active | ⬜ |

## 6. Explorateur de fichiers — Dolphin (réf. [06] [18] [21])
| # | Fonctionnalité | État |
|---|---|---|
| 6.1 | Onglets arrondis dans la barre de titre, bouton « + » | ⬜ |
| 6.2 | Barre de commandes à icônes fines : Nouveau ▾, couper, copier, coller, renommer, partager, supprimer, Trier ▾, Afficher ▾, filtre, `…` | ⬜ |
| 6.3 | Barre d'adresse : précédent / suivant / parent / actualiser, fil d'Ariane avec chevrons, champ « Rechercher … » | 🟡 |
| 6.4 | Volet gauche : Accueil, Galerie, OneDrive-like, Épinglés avec punaise, Ce PC, Réseau ; chevrons d'expansion ; sélection par pastille à gauche | ⬜ |
| 6.5 | Volet principal : sections repliables (« Dossiers », « Périphériques et lecteurs »), grandes icônes de dossiers colorées | ⬜ |
| 6.6 | Lecteurs avec barre d'utilisation (accent bleu, rouge si > 90 %) et « X Go libres sur Y Go » | ⬜ |
| 6.7 | Barre d'état : « N éléments » à gauche, boutons liste/grandes icônes à droite | ⬜ |
| 6.8 | Volet de détails/aperçu à droite (réf. [21]) | 🟡 |
| 6.9 | Icônes de dossiers et types de fichiers de style Fluent (pack d'icônes complet) | 🟡 pack partiel |

## 7. Menus contextuels et boîtes de dialogue (réf. [03] [17])
| # | Fonctionnalité | État |
|---|---|---|
| 7.1 | Menu contextuel du bureau : Afficher ▸, Trier par ▸, Actualiser, Nouveau ▸, Paramètres d'affichage, Personnaliser — icônes fines à gauche, séparateurs, rayon 8 px, ombre, fond acrylique | ⬜ (P5 Kvantum + thème Plasma) |
| 7.2 | Hauteur d'entrée ~ 32–36 px, chevrons de sous-menu, raccourcis clavier alignés à droite | ⬜ |
| 7.3 | Boîtes « Enregistrer sous / Ouvrir » avec la même mise en page que l'Explorateur | ⬜ |
| 7.4 | Boîtes de message : boutons arrondis 4 px, bouton principal en accent | ⬜ (P5) |
| 7.5 | Menus des applications (Konsole, Dolphin) au même style | ⬜ |

## 8. Paramètres système (réf. [02] [10] [11])
| # | Fonctionnalité | État |
|---|---|---|
| 8.1 | Navigation à gauche : Accueil, Système, Bluetooth et appareils, Réseau, Personnalisation, Applications, Comptes, Heure et langue, Jeux, Accessibilité, Confidentialité, Windows Update ; élément actif avec barre d'accent verticale | ⬜ (page d'accueil des Paramètres Plasma à épurer, P8) |
| 8.2 | Champ « Rechercher un paramètre » en haut | 🟡 |
| 8.3 | Pages en cartes arrondies (titre + sous-titre gris + chevron à droite), fond Mica clair | ⬜ |
| 8.4 | Cartes d'en-tête : avatar, nom de la machine, état réseau, état des mises à jour (réf. [11]) | ⬜ |
| 8.5 | Interrupteurs (toggle) Fluent : pastille ronde, piste accent, libellé « Activé/Désactivé » | ⬜ (Kvantum) |
| 8.6 | Liste déroulante, curseurs, cases à cocher, boutons radio au style Fluent | ⬜ (P5) |
| 8.7 | Page Personnalisation : thèmes (vignettes), couleurs d'accent, mode clair/sombre | 🟡 schémas de couleurs fournis |

## 9. Écrans de verrouillage et de connexion (réf. [01] [19] [07])
| # | Fonctionnalité | État |
|---|---|---|
| 9.1 | Écran de verrouillage : fond d'écran « bloom » bleu, horloge très grande (`9:00`) et date en dessous, centrées en haut | 🟡 lock screen du fork, non vérifié |
| 9.2 | Icônes réseau/accessibilité en bas à droite | ⬜ |
| 9.3 | Écran de connexion : fond flouté, avatar rond, nom en gras, champ mot de passe avec bouton flèche → | ⬜ (thème SDDM, P7) |
| 9.4 | Boutons bas d'écran : accessibilité, réseau, alimentation avec menu Suspendre/Arrêter/Redémarrer (réf. [07]) | ⬜ |
| 9.5 | Raccourci Meta+L ; transition verrouillage → connexion (glissement) | 🟡 |
| 9.6 | Écran de démarrage (logo + cercle de chargement) | ⬜ (Plymouth, optionnel) |

## 10. Widgets et panneaux latéraux (réf. [04])
| # | Fonctionnalité | État |
|---|---|---|
| 10.1 | Panneau Widgets (météo, actualités, bourse, sport) ouvert par Win+W ou survol du bouton météo | ❌ |
| 10.2 | Bouton météo à gauche de la barre (« 18°C Nuageux ») (réf. [06] [20]) | ⬜ (applet météo simple possible) |

## 11. Apparence globale
| # | Fonctionnalité | État |
|---|---|---|
| 11.1 | Thèmes clair et sombre complets, bascule cohérente (Plasma, couleurs, Aurorae, Kvantum, curseur, icônes, GTK) | 🟡 |
| 11.2 | Couleurs d'accent : sombre `#4CC2FF`, clair `#0067C0` ; couleur d'accent modifiable | 🟡 |
| 11.3 | Fond d'écran « bloom » Windows 11 (clair et sombre) | ✅ fond présent dans le dépôt |
| 11.4 | Police : Segoe UI Variable (propriétaire) → Inter en remplacement ; réglages fontconfig | ❌ pour Segoe ; 🟡 Inter |
| 11.5 | Rayons : fenêtres 8 px, contrôles 4 px ; focus ring accent 2 px | ⬜ |
| 11.6 | Curseur de souris Windows 11 | 🟡 curseurs fournis |
| 11.7 | Applications GTK (Chrome, Nautilus, libadwaita) au même style | ⬜ (P5) |
| 11.8 | Sons système Windows 11 | ❌ (propriétaires) |
| 11.9 | Effet de flou/acrylique derrière les panneaux (menus, barre, centre rapide) | ⬜ (flou KWin ; Mica dynamique impossible) |
| 11.10 | Icônes d'applications de style Fluent (Edge, Store, Courrier, Photos, Calculatrice, Paramètres, etc.) | 🟡 pack partiel |

## 12. Comportements système
| # | Fonctionnalité | État |
|---|---|---|
| 12.1 | Raccourcis : Meta (Démarrer), Meta+D (bureau), Meta+E (Explorateur), Meta+L (verrouiller), Meta+S (recherche), Meta+A (centre rapide), Meta+N (notifications), Meta+Tab (vue des tâches), Meta+flèches (snap), Meta+I (Paramètres) | ⬜ |
| 12.2 | Bureaux virtuels (création, noms, fonds différents) | 🟡 natif |
| 12.3 | Mode Ne pas déranger / Assistant de concentration | 🟡 natif |
| 12.4 | Éclairage nocturne | 🟡 natif |
| 12.5 | Installation et retour arrière sans casser le bureau (`install.sh`, `uninstall.sh`, sauvegardes) | ✅ garde-fous, ❌ jamais testé sur la machine réelle |

---

## Ce qui est hors d'atteinte sur KDE (cible réaliste ≈ 90 %)
Snap Layouts au survol de « agrandir » · panneau Widgets · champ de recherche intégré à la barre · ClearType · vrai Mica (fond dynamique) · Segoe UI Variable et sons Microsoft (propriétaires).

## Ordre de travail conseillé (du plus visible au moins visible)
1. Barre des tâches : état « attention », icônes Recherche / Vue des tâches, translucidité.
2. Menu Démarrer (validation puis alignement complet).
3. Zone de notification : regroupement réseau/son/batterie, centre rapide, centre de notifications + calendrier.
4. Fenêtres : coins arrondis, boutons de titre, Alt+Tab, Vue des tâches.
5. Kvantum (widgets), menus contextuels, boîtes de dialogue, Paramètres.
6. Dolphin façon Explorateur.
7. Verrouillage, connexion (SDDM).
8. Finitions : curseur, sons non propriétaires, GTK, fontconfig.
