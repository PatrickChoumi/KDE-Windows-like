# Verification automatique des fonctionnalites

PASS = mesure conforme sur la capture ; FAIL = mesure non conforme ; NON-TESTABLE = capture/mesure absente.

| # | Controle | Resultat | Mesure |
|---|---|---|---|
| 1.1 | barre 48 px pleine largeur | PASS | hauteur=48px (cible 48), pleine largeur=True |
| 1.3 | logo Windows 11 du bouton Demarrer | FAIL | 44 px bleu du logo dans la zone du bouton Demarrer (>= 80 attendus) |
| 1.12 | Demarrer + Recherche + Vue des taches + applis, groupe centre | FAIL | 1 icones/boutons au centre (>= 5), centre du groupe x=964 (ecran 960) |
| 2.3 | horloge sur deux lignes | PASS | lignes de texte non vides : heure=11, date=8 |
| 2.4 | cloche puis pastille de nombre | FAIL | cloche=68 px clairs (>=25), pastille=0 px accent (>=60) |
| 2.6 | panneau Parametres rapides flottant a 12 px | PASS | marge droite=11px, au-dessus de la barre=12px (cible 12 +-1) |
| 2.8 | panneau Notifications flottant a 12 px | PASS | marge droite=11px, au-dessus de la barre=12px (cible 12 +-1) |
| 3.1 | menu Demarrer centre, a 12 px de la barre | FAIL | largeur=1px, centre x=960 (960), ecart a la barre=62px (12 +-1) |
| 3.2 | liseré d'accent du champ de recherche | FAIL | 133 px de liseré accent sous le champ de recherche (>= 400) |
| 5.1 | coins arrondis de 8 px (banc 2) | NON-TESTABLE | dossier du banc 2 non fourni |
| 6.7 | barre d'etat Dolphin pleine largeur avec nombre d'elements | PASS | ShowStatusBar=FullWidth=True ; texte « N dossiers » a gauche : 161 px clairs (>= 30) |

Lignes ✅ du document : 24 ; avec controle automatique : 6 ; SANS controle : 18 ; controle en echec : 4.

## ✅ annoncees mais controle en ECHEC
- 1.3 Bouton Démarrer avec le logo Windows 11
- 1.12 Icônes « Recherche » et « Vue des tâches » à côté du Démarrer (réf. [1
- 2.4 Bouton de notifications à droite de l'horloge, avec pastille de nombre
- 3.2 Champ de recherche en haut (« Search for apps, settings, and documents

## ✅ annoncees SANS controle automatique (a prouver ou a retrograder)
- 1.4 Icônes en icônes seules, 24 px, boutons 44 px, écart 4 px
- 1.5 Fond de bouton arrondi (rayon 4 px) au survol et pour la fenêtre activ
- 1.6 Pastille d'activité en bas : 16×3 px accent (active), 6×3 px grise (ou
- 1.14 Fond de barre translucide type Mica/acrylique, sombre ou clair selon l
- 1.16 État « attention » (icône qui clignote / pastille orange)
- 2.1 Chevron `^` « icônes cachées » avec popup
- 2.5 « Afficher le bureau » : trait fin au bord droit, visible au survol
- 2.7 Tuiles actives en accent plein, inactives en gris translucide, rayon 4
- 3.3 Section Épinglé : grille 6 colonnes × 3 lignes, icône 32 px + libellé 
- 3.5 Pied de menu : avatar + nom d'utilisateur à gauche, bouton alimentatio
- 3.6 Vue « Toutes les applications » (réf. [08]) : liste alphabétique avec 
- 3.10 Animation d'ouverture (glissement vers le haut + fondu, ~200 ms)
- 4.1 Panneau de recherche : champ en haut, colonne « Suggérés » (applicatio
- 4.2 « Recherches rapides » (tuiles de paramètres) et « Applications princi
- 5.2 Barre de titre 32 px, titre aligné à gauche avec icône 16 px
- 5.3 Boutons réduire / agrandir / fermer : 46×32 px, glyphes fins, fond de 
- 11.3 Fond d'écran « bloom » Windows 11 (clair et sombre)
- 12.5 Installation et retour arrière sans casser le bureau (`install.sh`, `u

