# M159 — Continuité de lecture et quiz du chapitre

Reviewed: 2026-08-31
Slice: fin de lecture → prolongement jouable, sans rupture du Cercle
Tests: `bundle exec rails test test/services/scriptures/quiz_recommendation_test.rb test/controllers/scripture_circle_posts_controller_test.rb test/controllers/scripture_reader_three_controller_test.rb test/i18n/locale_files_test.rb test/system/scripture_reader_circle_visual_test.rb` — 35 runs, 672 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — surface de lecture soutenue, hors Hub
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr présents, YAML et parité validés

## Feeling

Le joueur doit sentir que sa lecture reste intacte quand il prend la parole, puis qu’une invitation calme lui permet de transformer ce qu’il vient de lire en une petite victoire de compréhension.

## 1 — Game experience

Boucle : lire → publier sans perdre sa place → voir sa parole dans le fil → atteindre la fin du chapitre → découvrir un quiz réellement relié au chapitre → jouer, reprendre, rejouer ou repérer son déblocage. Le catalogue éditorial existant reste la seule source des questions ; aucune promesse de contenu n’est faite sans correspondance exacte de chapitre.

## 2 — UI design

Verbe en deux secondes : « Jouer au quiz » ou « Voir sur la carte ». Les états `current`, `available`, `open`, `finished` et `locked` ont chacun une action honnête. La carte tient dans la mesure de lecture, le bouton fait au moins 44 px, les messages personnels suivent l’échelle typographique du lecteur et restent en graisse 400. Réduction de mouvement et couleurs forcées sont couvertes.

## 3 — Art direction

Une carte ivoire à double filet discret, médaillon-question et signature or prolonge le refuge de lecture sans devenir une bannière promotionnelle. Le titre reste en encre ; l’or guide l’action et ne remplace pas la hiérarchie. L’exception papier/verre est justifiée par la lecture soutenue et reste cohérente avec la Celestial Light de la liseuse.

## Theme engine

N/A — aucun changement du Hub `/` ni de son moteur d’atmosphère.

## Four seats

N/A live night. Street : une personne, dans la liseuse, sait quel chapitre elle vient de terminer, quel quiz y répond et si elle peut le jouer maintenant. Le Cercle reste visible sous la lecture.

## Tension

Tension douce de fin de chapitre : la compréhension peut maintenant être éprouvée. L’état verrouillé préserve l’envie sans contourner la progression ; l’état jouable donne une sortie immédiate vers l’action.

## Finale

N/A — ce slice ne modifie pas une finale live. Il renforce l’envie de poursuivre le parcours Street.

## Languages

Copy lue en es, pt-BR, en et fr. Les quatre variantes distinguent naturellement jouer, reprendre, rejouer et voir le déblocage. Test de parité vert.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 8 |
| Feedback | 9 |
| Progression | 9 |
| Social | 8 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- La publication ne transforme plus un retour dans le fil en ouverture forcée du détail mobile.
- La position exacte survit au cycle Turbo et la confirmation reste visible dans le contexte courant.
- La carte quiz est éditorialement vérifiable : Alma 32 trouve trois questions du pack « Symboles du Livre de Mormon ».
- Les états verrouillé et jouable conduisent vers des destinations réelles sans court-circuiter la progression.

## What feels weak

- Les chapitres sans question exacte n’affichent volontairement aucune carte ; la couverture dépend donc du catalogue éditorial.

## Required before approval

- None.

## Evidence

- Rendu inspecté à 390×844, 768×1024 et 1440×900 : aucun débordement horizontal ; CTA 48 px sur mobile et 44 px sur tablette/desktop.
- Console navigateur : 0 erreur, 0 avertissement aux trois largeurs.
- Test système : position conservée, graisse 400, facteur typographique 1,15 vérifiés après publication réelle.

## Night director

Oui. La proposition arrive après une action significative — finir un chapitre — et donne envie d’éprouver ce qu’on vient de recevoir, sans casser le calme de la lecture.
