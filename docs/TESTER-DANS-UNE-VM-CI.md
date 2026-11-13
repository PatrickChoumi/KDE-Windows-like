# Tester un script système dans une VM GitHub Actions (avec captures)

> Méthode suivie pour la feature 5.1 (coins arrondis). Objectif : ne jamais lancer sur la machine de Patrick un script qui touche apt, KWin ou `~/.config` avant de l'avoir exécuté **pour de vrai** dans une VM jetable, avec preuves (journaux + captures).

## Principe
1. Un workflow dédié (`.github/workflows/<feature>-shots.yml`) tourne dans un conteneur `ubuntu:26.04` sur `ubuntu-latest` : mêmes versions de paquets qu'en vrai (Plasma 6.6.x), VM détruite à la fin.
2. Il installe une session Plasma virtuelle (Xvfb + `kwin_x11`, `plasmashell`, `konsole`), le thème du dépôt, puis lance **le vrai script** (`RC_YES=1 bash scripts/install-X.sh install`, puis `status`, puis `undo`), sans stub.
3. Avant / après install / après retour arrière : un état (`etat.txt`), une capture plein écran et des recadrages x8, publiés sur une branche `ci-shots-<feature>` (lisible sans télécharger d'artefact : `git clone --depth 1 -b ci-shots-<feature> …`).
4. Un déclencheur `paths:` limite le workflow aux fichiers concernés ; `workflow_dispatch` permet de le relancer à la main.
5. Lire les résultats **réels** : un job vert ne prouve rien si l'étape finit par `|| true`. Regarder `install.log`, `status-*.txt`, `kwinrc-*.txt`, `etat.txt` et les pixels.

Fichiers de la feature 5.1 : `scripts/install-roundcorners.sh`, `ci/roundcorners-shots.sh`, `.github/workflows/roundcorners-shots.yml` (X11) ; essai Wayland : `ci/roundcorners-wayland.sh`, `.github/workflows/roundcorners-wayland.yml` (lancement manuel).

## Ce que ça valide (et ce que ça ne valide pas)
- Validé en VM (run 43284005954 puis 43290304941) : ajout du PPA, simulation `apt -s`, installation d'un seul paquet, contrôles `dpkg`, écriture/relecture dans `kwinrc`, `undo` complet (paquet retiré, `kwinrc` identique à l'original), `status` fidèle.
- **Non validé : le rendu des coins.** Dans la VM, `kwin_x11` est en 6.6.4 alors que le plugin est compilé pour 6.6.6 (IID `org.kde.kwin.EffectPluginFactory6.6.6`) : KWin refuse l'effet, `loadEffect` répond `false`, les coins restent carrés après installation. Le script le détecte et l'affiche (« activé dans kwinrc mais NON chargé par KWin »).
- Piste Wayland (`kwin-wayland` est en 6.6.6, même version que le plugin) : `kwin_wayland --virtual` n'a pas pu démarrer dans le conteneur (5 essais, voir ci-dessous). Rendu à vérifier sur la vraie machine, **en session Wayland** (en session X11, même refus qu'en VM).

## Pièges rencontrés (à ne pas refaire)
- `cmd | grep -q` sous `set -o pipefail` : `grep -q` ferme le tube, la commande amont renvoie 141 et le test échoue à tort. Capturer la sortie dans une variable puis `grep <<<"$var"`.
- Un stub oublié (`add-apt-repository`) laisse le vrai programme s'exécuter : lister toutes les commandes appelées avant un test avec stubs.
- La décoration Aurorae n'est appliquée qu'après un `reconfigure` de KWin : attendre `_NET_FRAME_EXTENTS = 4, 4, 32, 4` avant la capture « avant », sinon on compare à la décoration Breeze.
- `kwin-x11` et `kwin-wayland` ne sont pas à la même version sur Ubuntu 26.04 (6.6.4 / 6.6.6) : vérifier `dpkg -l 'kwin*'` avant d'interpréter un échec de plugin.
- `kwin_wayland` porte `cap_sys_nice` : exécution refusée dans le conteneur (« Operation not permitted »). Contournement : `cp` du binaire (sans attributs étendus) sous un autre nom.
- Après ce contournement : « Could not load the Qt platform plugin wayland-org.kde.kwin.qpa » ; `/dev/dri` n'existe pas dans le conteneur, `EGL_PLATFORM=surfaceless` n'a pas suffi. Non résolu.
- Le bac à sable de Claude ne peut pas lire les journaux de job (blob.core.windows.net bloqué) : publier les fichiers utiles sur une branche `ci-*`.
- Dans une étape `bash -e`, un `grep` sans résultat arrête tout : ajouter `|| true`.
- Plusieurs sessions peuvent pousser sur `dev` en même temps : `git fetch` et lire `git log origin/dev` avant de pousser, ne pas empiler un diagnostic déjà fait.

## Recette pour une nouvelle feature
1. Écrire le script avec sauvegarde, simulation, contrôles, activation relue, `undo`, `status`.
2. Copier `roundcorners-shots.yml` et `ci/roundcorners-shots.sh`, adapter les paquets, l'état et le recadrage.
3. Pousser sur `dev`, attendre le run, cloner la branche `ci-shots-<feature>`, lire `etat.txt` et regarder les images.
4. Corriger tant que les journaux montrent un écart ; ne mettre « ✅ » dans `docs/FONCTIONNALITES-WIN11.md` que si une capture ou une mesure le prouve.
