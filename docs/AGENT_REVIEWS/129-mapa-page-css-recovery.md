# M129 — Carte Aventure : parcours restauré et CSS par page

Reviewed: 2026-08-29
Slice: ouvrir la carte, comprendre le prochain pack et lire le chemin de progression
Tests: `bundle exec rails test test/controllers/street_hub_controller_test.rb` — 28 runs, 633 assertions, 0 failures; `bundle exec rails test test/performance/architecture_contract_test.rb test/integration/ui_chrome_test.rb` — 26 runs, 25 938 assertions, 0 failures; `bundle exec rails assets:precompile` — PASS
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — `/mapa` est la surface Aventure, pas le hub `/`
Copy: N/A — aucun texte ni aucune clé de traduction modifiés

## Feeling

Émerveillement et accomplissement : le joueur retrouve un chemin céleste lisible, voit ce qu’il a déjà conquis et sait immédiatement où continuer.

## 1 — Game experience

Boucle : arrivée sur le chemin → mission courante mise en avant → lecture des packs terminés et verrouillés → choix d’une catégorie ou du prochain pack → feedback immédiat → envie d’atteindre le prochain coffre. Le CTA `Continuer l’aventure` reste le verbe dominant et les verrous expliquent maintenant leur condition au tap comme au clavier.

Les filtres de catégorie, l’ouverture des paliers futurs et le feedback de verrou ont été exercés dans le navigateur. L’écran mort en HTML brut est supprimé.

## 2 — UI design

Le CSS de la page vit désormais dans `app/assets/stylesheets/pages/street_map.css`, chargé uniquement par `/mapa`. Le HUD et le dock partagés restent dans `surfaces/hub.css`; les règles de carte ont été retirées de `surfaces/study.css` et du bloc générique du hub.

États couverts : current, finished, locked, unlocking, denied/explaining, catégorie active/muted, palier collapsed/open, pressed/focus-visible et reduced-motion. Les cibles tactiles mesurées font au moins 44 × 44 px. Aucun débordement horizontal n’est observable à 390 × 844, 768 × 1024 ou 1440 × 900.

## 3 — Art direction

Le chemin doré redevient le décor narratif, avec une mission en verre ivoire, des médaillons métalliques et des paliers colorés. Celestial Light vient de l’artwork fixe de la carte, pas d’un toggle. L’or reste réservé au CTA, aux médaillons, au chemin et aux récompenses; les titres restent en encre.

## Theme engine

N/A. La carte possède un artwork Celestial Light dédié. Le hub `/` et son moteur Light/Dark ne sont pas modifiés.

## Four seats

Street — qui : identité, rang et ressources dans le HUD; où : pack courant et palier dans la carte; quoi maintenant : `Continuer l’aventure`; autour de moi : progression totale, récompenses et accès au classement.

## Tension

Le pack courant pulse, les packs suivants restent visibles mais verrouillés, et un coffre ponctue chaque dizaine. Le prochain désir est concret sans transformer la carte en formulaire administratif.

## Finale

N/A. Cette tranche ne change ni une ronde Live ni sa finale.

## Languages

N/A. Aucun libellé n’a changé; les traductions existantes restent utilisées.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 10 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- La mission courante et son CTA sont compris avant de lire tout le chemin.
- Les nœuds terminés, courants et verrouillés racontent la progression sans dashboard.
- La feuille par page élimine le couplage accidentel avec l’univers Étude.
- Tap et clavier produisent le même feedback sur un verrou.

## What feels weak

- La carte utilise volontairement un seul artwork Celestial Light; une future carte Dark demanderait un artwork et des tokens narratifs dédiés, pas un toggle.

## Required before approval

- None.

## Evidence

- Captures navigateur inspectées à 390 × 844, 768 × 1024 et 1440 × 900.
- Console navigateur : 0 erreur, 0 avertissement.
- Filtres, paliers repliables, feedback verrouillé au tap et au clavier exercés.
- Aucun flux de permission ou message éditorial sur cette page.

## Night director

Oui : la destination suivante est évidente, le chemin montre ce qui reste à conquérir et le prochain coffre donne une raison de continuer.
