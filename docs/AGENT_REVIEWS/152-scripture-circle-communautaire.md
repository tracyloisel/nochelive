# M152 — Le Cercle de ta rama

Reviewed: 2026-08-30
Slice: le Cercle communautaire de la paroisse, depuis le Hub et la liseuse jusqu’aux échanges sûrs autour d’un chapitre
Tests: `PARALLEL_WORKERS=1 bundle exec rails test` (modèles, services, contrôleurs, locales du Cercle et de la liseuse) — 60 runs, 553 assertions, 0 failures; services Cercle — 8 runs, 66 assertions, 0 failures; contrôleur Cercle — 6 runs, 29 assertions, 0 failures; QA visuelle système — 1 run, 271 assertions, 0 failures; `rails media:build_responsive` — 458 assets, 4 410 variants
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — le Hub conserve son atmosphère ; il expose seulement une porte lecture vers le Cercle.
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr validés en YAML et parité de locale

## Feeling

Appartenance calme et courage d’aider : « cette question de ma paroisse attend peut-être ma sagesse ; je peux l’ouvrir sans interrompre ma lecture. »

## 1 — Game experience

La boucle est volontaire et de proximité : `lire → remarquer une question ou un échange → ouvrir le Cercle → aider ou réfléchir → revenir au chapitre`. Le flux ne fabrique ni classement ni récompense artificielle. Les cartes donnent un prochain geste clair (« Ouvrir et répondre » / « Ouvrir l’échange »), puis le lien profond garde le lecteur sur la conversation demandée, même lorsqu’elle n’est plus parmi les plus récentes.

L’aide sert une vraie intention : questions racines sans réponse visible d’un autre membre, jamais les propres questions ; aperçu limité à trois mais compteur exact. Les conversations, l’activité récente, les lectures et mes échanges se limitent à la paroisse courante, à une référence connue et à une branche publiable/rendable ; une réponse sous une branche masquée ne remonte donc ni dans un compteur ni dans une liste.

## 2 — UI design

Le verbe en deux secondes est « Aider ». La page garde une seule navigation par onglets avec Turbo, un état vide honnête, une rail de lecture et aucune composition de message au niveau de l’index. Chaque carte entière est un lien lecteur ; les cibles tactiles font au moins 44 px. Les états chargement, vide, sélection, lecture seule, appui, focus, reduced motion et forced colors sont couverts sans effacer le contexte de chapitre.

La matrice réelle 320 × 568, 390 × 844, 768 × 1024, 1024 × 768, 1440 × 900, 1536 × 1024 et 1920 × 1080 a été capturée en Celestial Light et Dark ; pas de débordement horizontal, de texte tronqué ni de flèche décorative trompeuse sur mobile. Les onglets affichent maintenant leurs totaux réels, y compris le total exact du chapitre sélectionné ; leur libellé accessible annonce aussi le nombre d’échanges.

## 3 — Art direction

Le Cercle prolonge le geste de lecture : ivoire, encre et or réservé au geste important. Deux paysages originaux sans personne ni texte — olivier et vallée à l’aube, puis pendant bleu nuit — sont livrés comme masters responsive AVIF/WebP/JPEG. La version sombre est issue du backdrop approuvé et non d’un toggle ; des scrims locaux protègent la lecture sans recouvrir entièrement les décors. Les vignettes de chapitre ne s’affichent que lorsqu’un artwork approuvé est réellement mappé ; sans mapping, une carte typographique lisible prend sa place. Le Hub ne duplique ni fil ni événement : il ne propose qu’une porte de lecture sûre.

## Theme engine (hub `/` only)

N/A — aucune atmosphère du Hub n’est modifiée. La surface Cercle résout son mode depuis `Hubs::Backdrop` et les screenshots de QA forcent uniquement deux backdrops de catalogue approuvés, dans l’environnement de test.

## Four seats

N/A — boucle Street asynchrone, hors soirée Live. La paroisse a un verb social précis : répondre dans le Cercle de sa communauté, sans diffusion ni spectacle imposé.

## Tension

Tension douce : une question sans réponse d’un autre membre appelle une aide concrète ; après réponse, elle quitte l’état d’urgence et laisse apparaître l’échange suivant. Le fil conserve un rythme communautaire sans transformer la foi ou les réponses en score.

## Finale

N/A — ce slice ne modifie aucune manche ni couronne Live. Sa résolution est le retour net à la Parole après un échange choisi.

## Languages

PASS — les clés Cercle et liseuse sont présentes et non vides en espagnol, portugais brésilien, français et anglais. Les rôles anonymes emploient une formulation générique locale, sans pseudo ni avatar.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 8.5 |
| Feedback | 8.5 |
| Progression | 8 |
| Social | 9 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 8.5 |

## Verdict

PASS WITH NOTES

## What works

- Une seule conversation racine identifie un échange : les réponses profondes restent récupérables par lien direct sans contourner l’accès de paroisse.
- L’anonymat est un choix métier explicite : seulement la question racine peut être anonyme envers la paroisse ; l’identité reste disponible à la modération et aux limites anti-abus.
- Les écritures/événements du Hub et la validation Socializer ne sont jamais confondus avec le Cercle de la Parole.
- Light et Dark sont testés sur sept formats, avec focus, mouvement réduit et contrastes forcés.
- Les compteurs de `Tout`, `À aider`, `Récentes`, `Mes échanges` et du chapitre actif proviennent des scopes de conversation réels, pas des aperçus limités à trois cartes.
- Les deux artworks du Cercle sont servis par le manifeste responsive, avec des dérivés portrait et paysage immuables.

## What feels weak

- La boucle choisit le recueillement plutôt qu’un rituel de célébration : aucun badge, streak ou feedback sonore n’est ajouté, ce qui est juste ici mais moins spectaculaire qu’une surface Live.

## Required before approval

- Aucun prérequis de code pour ce slice. Toute future promotion éditoriale sur le Hub devra demander son propre flux d’approbation ; elle ne peut pas réutiliser automatiquement un post du Cercle.

## Evidence

- Lien direct inspecté : `/escrituras/ot/ps/52?circle=1&circle_post=2` conserve `circle_post` et focalise la conversation dans la liseuse.
- Migration : racines de conversation, visibilité sémantique d’auteur, garde anti-cycle, contraintes de paroisse/thread et backfill des anciens anonymes non admissibles.
- Captures système : `tmp/street-shots/scripture-circle/circle-{light,dark}-{320x568,390x844,768x1024,1024x768,1440x900,1536x1024,1920x1080}.png`.
- Masters ImageGen : `media/masters/media/hub/rama/circle-scripture-celestial-{light,dark}-v1.png`; dérivés : `public/media/generated/scripture_circle/backdrop/{light,dark}/`.

## Night director

Oui : je comprends immédiatement où une personne de ma paroisse attend une aide, je peux ouvrir l’échange sans me perdre dans le flux, puis revenir naturellement au chapitre. Cela crée de l’appartenance sans voler la scène à la Parole.
