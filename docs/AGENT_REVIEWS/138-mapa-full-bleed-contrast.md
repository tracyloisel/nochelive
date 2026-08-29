# M138 — Carte Aventure plein écran et contraste céleste

Reviewed: 2026-08-29
Slice: retrouver une carte de progression qui ressemble à un monde, pas à une colonne illustrée
Tests: `bundle exec rails test test/controllers/street_hub_controller_test.rb` — 30 runs, 604 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — `/mapa` est la surface Aventure
Copy: N/A — aucun texte ni aucune traduction modifiés

## Feeling

Émerveillement et envie d’avancer : le joueur doit sentir que sa progression traverse un royaume céleste immense, avec une destination lumineuse et un chemin encore à conquérir.

## 1 — Game experience

La boucle reste mission actuelle → lecture du chemin → prochain pack ou filtre → progression visible → prochain désir. Le décor plein écran renforce l’anticipation sans déplacer le CTA `Continuer l’aventure` ni modifier les règles de déverrouillage.

## 2 — UI design

La peinture occupe maintenant tout le viewport tandis que le HUD, la mission, les filtres, les nœuds et le footer restent dans une colonne de lecture de 50 rem. Le portrait est sélectionné sur téléphone et le panorama à partir de 45 rem. Les libellés de palier reçoivent un halo-verre local pour rester lisibles sur les rochers sombres sans voile global.

États inchangés et préservés : current, finished, locked, unlocking, denied/explaining, catégorie active/muted, palier collapsed/open, pressed, focus-visible et reduced-motion.

## 3 — Art direction

Celestial Light, sans toggle : ivoire et or restent la signature, mais des ombres sapphire/lavande, des rochers et des nuages plus denses remplacent la surexposition beige. Deux artworks responsives originaux composent le même royaume et gardent le décor jusqu’aux bords. L’or reste métal, chemin, médaillon et CTA; les titres restent en encre.

## Theme engine

N/A. Le hub `/` et son moteur de thèmes ne sont pas modifiés.

## Four seats

Street — qui : identité et rang dans le HUD; où : palier et pack courant; quoi maintenant : `Continuer l’aventure`; autour de moi : progression, récompenses et classement.

## Tension

Le chemin monte vers le sanctuaire, le pack courant reste le point de tension et les verrous matérialisent la prochaine conquête. Le nouveau contraste rend la distance restante plus lisible.

## Finale

N/A. Cette tranche ne modifie pas une ronde Live.

## Languages

N/A. Aucun libellé n’a changé.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 10 |
| Feedback | 9 |
| Progression | 10 |
| Social | 8 |
| Immersion | 10 |
| Accessibilité | 9 |
| Cohérence NocheLive | 10 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- L’illustration remplit réellement le téléphone, la tablette et le bureau sans étirer la colonne de jeu.
- Les nœuds verts, bleus et verrouillés se détachent des ombres froides.
- Le halo local des paliers protège le texte sans blanchir la peinture.
- Le portrait et le panorama conservent la même destination et la même lumière.

## What feels weak

- L’artwork est fixe pendant le scroll; une future version pourrait ajouter une parallaxe très légère, désactivée avec `prefers-reduced-motion`.

## Required before approval

- None.

## Evidence

- Rendus inspectés à 390 × 844, 768 × 1024 et 1440 × 900.
- Aucun débordement horizontal aux trois formats.
- Variante portrait active à 390 px; variante panorama active à 768 et 1440 px.
- Filtre de catégorie exercé; sélection et atténuation des nœuds vérifiées.
- Console : 0 erreur, 0 avertissement.
- Aucun flux de permission ni message éditorial dans cette tranche.

## Night director

Oui : la carte donne maintenant l’impression d’une ascension réelle et la destination suivante reste immédiatement compréhensible.
