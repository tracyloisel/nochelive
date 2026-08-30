# Liseuse 3.0 — entrée centrée sur la Parole

Reviewed: 2026-08-30
Slice: l'entrée de la liseuse, la porte des accompagnements et le retour au chapitre
Tests: `bundle exec rails test test/controllers/scripture_reader_three_controller_test.rb` — 11 runs, 118 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md`
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, fr et en relus ; aucune sélection éditoriale ou notification nouvelle

## Feeling

Recueillement d'abord, maîtrise ensuite, appartenance seulement sur invitation. Le lecteur doit sentir : « Le chapitre m'attend ; le reste est là si j'en ai besoin. »

## 1 — Game experience

La boucle calme devient : `ouvrir → accueillir → lire → choisir d'accompagner → revenir au texte`.

Le fil, les votes et le mouvement de ward ne sont plus un événement qui interrompt la lecture. La récompense est le retour immédiat à une colonne pleine et au bon focus après une consultation volontaire. Le lien direct vers un message reste une intention explicite et peut ouvrir le Cercle.

## 2 — UI design

Le premier verbe est `Lire`. À l'arrivée, le lecteur ne reçoit ni dock, ni rail, ni panneau droit, ni compteur social intrusif. Le seul signe d'appartenance est la présence de lecteurs distincts de la ward, petite et posée au-dessus du titre : nombre après le seuil de confidentialité, formulation non chiffrée en dessous. Deux icônes calmes restent disponibles : le signet ouvre `Mes repères`, les deux bulles ouvrent `Le cercle` ; chaque destination possède `Retour au chapitre`.

Quand le lecteur demande le Cercle, l'écriture devient immédiatement le premier geste : un seul titre, le retour au chapitre, puis le formulaire déjà ouvert. Le sous-titre cérémoniel, le double libellé et la carte à déplier ont été retirés ; le périmètre de la paroisse reste visible une seule fois dans le formulaire.

États vérifiés : lecture initiale, repères/cercle ouverts volontairement, lien direct vers le Cercle, retour et restitution du focus, mobile/tablette/desktop, absence de débordement. Les cibles principales font au moins 44 px et les titres recevant le focus utilisent l'anneau or, jamais le focus bleu du navigateur.

## 3 — Art direction

Celestial Light est justifié par le moment de lecture : papier ivoire, encre, cheveux d'or et illustration montagne monochrome. La surface du texte reste volontairement papier pour la lecture longue. Le panneau dense devient opaque à tablette afin que les versets ne transparaissent jamais derrière les messages ; il n'existe pas à l'entrée.

## Four seats

N/A — la liseuse n'est pas une surface Live.

## Languages

PASS — les nouvelles clés de navigation existent en espagnol, portugais brésilien, français et anglais, avec une formulation locale ; aucune phrase spirituelle nouvelle n'est générée ou sélectionnée.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 8 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 8 |

## Verdict

PASS

## Evidence

- rendu inspecté à `390 × 844`, `768 × 1024` et `1440 × 900` ;
- signet, Cercle, retour, focus et absence de débordement vérifiés dans un navigateur ;
- `git diff --check`, analyse syntaxique du contrôleur JavaScript et lecture YAML des quatre locales réussis ;
- une exécution élargie a rencontré un verrou PostgreSQL externe sur les fixtures hors périmètre ; le test contrôleur de la liseuse a ensuite réussi isolément.
