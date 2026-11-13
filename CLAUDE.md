# Instructions pour les agents IA (Claude, Codex, Copilot, etc.)

Avant toute modification de ce dépôt, lis dans cet ordre :

1. `docs/METHODE-DE-TRAVAIL.md` : la méthode exacte (contraintes de l'utilisateur, boucle de travail, outils, CI, leçons techniques, état actuel). **À respecter.**
2. `docs/PLAN-WINDOWS11-PIXEL-PERFECT.md` : le plan par phases pour approcher Windows 11 sur KDE Plasma 6.6.

3. `docs/FONCTIONNALITES-WIN11.md` : liste de toutes les fonctionnalités à reproduire, avec leur état (références visuelles dans `docs/reference-win11/`).

Points essentiels (détails dans la méthode) :
- Répondre en français, de façon courte ; un correctif = un commit, une chose à la fois.
- Travailler et pousser sur la branche `main` (il n'y a plus de `dev` : seulement `main` + `ci-out`), jamais de commande destructive, ne rien supprimer dans `/usr/share`.
- Valider par la CI (`build-and-check` + captures `ci-out/fork` / `ci-out/native`), mesurer les pixels avant de corriger, ne jamais croire un « Done ».
- Après chaque correctif validé : mettre à jour `docs/METHODE-DE-TRAVAIL.md` (§5 leçons, §6 état).
