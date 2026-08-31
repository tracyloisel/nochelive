# M168 — Expédition des Psaumes, portes permanentes et Live H+3

Reviewed: 2026-08-31
Slice: de l’illustration Home aux six packs permanents, puis aux deux Noche Live de Benidorm
Tests: trois lots ciblés — 27/3763, 76/2873 et 48/296, 0 failure
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — chrome es, pt-BR, en, fr valide ; édition biblique publiée en français

## Feeling

Curiosité immédiate devant six histoires que le joueur ne s’attendait pas à
trouver dans les Psaumes, puis soulagement de ne pas perdre ses découvertes à la
fin de la semaine. La Rama Benidorm doit sentir qu’elle entre ensemble dans ces
portes, sans que l’expédition efface l’aventure permanente.

## 1 — Game experience

Les six unités sont des packs permanents de dix questions. L’expédition ne les
duplique pas : elle conserve leur ordre, leur présentation et leur progression.
La carte propose deux lectures distinctes, `Parcours complet` et `Expéditions`,
afin que la collection de la semaine ne soit jamais confondue avec le chemin
permanent.

La structure est une constellation, pas un faux arc. Chaque porte possède son
personnage, sa tension et son payoff. Les soirées de lundi et vendredi prennent
respectivement les trois premiers puis les trois derniers packs. Leur fermeture
automatique est configurée à H+3 : 20:00–23:00 dans le fuseau de Benidorm.

## 2 — UI design

Verbe en deux secondes : `Ouvrir l’expédition`, puis `Entrer` ou `Continuer`.
La Home vend l’aventure avec son illustration et ses six portes ; la
Bibliothèque garde la semaine comme porte de lecture ; la Rama montre la
progression collective et les deux rendez-vous ; `/mapa` sépare clairement la
route permanente de la constellation.

Les états locked, available, current et finished proviennent des mêmes runs que
les packs permanents. La page publique d’une soirée annonce sa durée réelle —
`3 quiz · 3 heures en direct` — et son compte à rebours suit l’échéance serveur.
QA réelle sans débordement à 390×844, 768×1024 et 1440×900.

## 3 — Art direction

L’illustration spectaculaire de la Home porte des personnages humains, une ville
et une lumière qui promet la découverte. Les 60 questions possèdent chacune une
illustration propre. Les six portes changent volontairement de température et de
rythme : silence froid des harpes, mystère royal, intimité de la maison, puis
respiration lumineuse. L’or reste une signature d’action, jamais un tapis.

## Theme engine

Une seule Home et un seul arbre de rendu. L’illustration d’expédition entre dans
la composition existante après le carrousel de Rama ; elle n’introduit ni thème
utilisateur ni variante de page. Les tokens du Hub assurent lisibilité et
continuité Celestial Dark depuis l’œuvre.

## Four seats

| Seat | Verb tonight |
|---|---|
| Host | Ouvre Watch, donne le code et voit la soirée se fermer automatiquement à 23:00 |
| Chapel (controller) | Rejoint une équipe et joue les trois packs depuis son téléphone |
| Remote | Entre avec le même code et joue avec la Rama, question par question |
| TV / Twitch | Affiche Watch, le classement, la progression et le résultat final |

## Tension

Chaque pack suit sa propre montée, des trois premières lectures rassurantes au
payoff de la dixième question. Sur la semaine, la tension vient du nombre de
portes encore fermées et du pourcentage collectif de la Rama, pas d’une
continuité narrative inventée. En Live, trois packs offrent assez de terrain
pour les retournements d’équipe jusqu’à la fermeture H+3.

## Finale

La sixième porte conduit à `Tout ce qui respire` et à sa cérémonie permanente.
La seconde Noche Live conserve le classement actif sur ses trois packs ; une
équipe en retard peut encore reprendre la tête dans le dernier pack avant que le
résultat ne soit figé à 23:00.

## Languages

Les nouveaux libellés système et la durée plurielle sont présents en espagnol,
portugais brésilien, anglais et français. Le titre, le sous-titre et la promesse
de l’expédition ont les quatre variantes. Le corps des 60 questions reste une
édition française explicite (`editorial_locale: fr`) pour cette publication
locale ; aucune traduction automatique n’est présentée comme validée.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 9 |
| Clarté | 9 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 10 |
| Social | 9 |
| Immersion | 9 |
| Accessibilité | 8 |
| Cohérence NocheLive | 10 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Un pack gagné pendant l’expédition reste gagné dans le catalogue permanent.
- La Home, la Bibliothèque, la Rama, la liseuse et `/mapa` convergent vers les
  mêmes six identifiants ; aucune copie de progression n’existe.
- Les deux sessions montrent leurs trois vrais titres et utilisent l’heure
  locale de Benidorm.
- H+3 est un paramètre métier validé, pas une heure de fin codée dans le script.

## What feels weak

- Les 60 questions ne disposent pas encore d’une édition humaine validée dans
  les trois autres langues.
- Trois heures restent un rendez-vous long ; Watch et la progression par pack
  doivent rendre les respirations visibles pendant l’usage réel.

## Required before approval

- None.

## Evidence

- Publication locale : StudyUnit 50, player 22, Rama Benidorm.
- Lundi : session CBR7X, 20:00–23:00, trois premiers packs.
- Vendredi : session NOEMI, 20:00–23:00, trois derniers packs.
- Contrôle navigateur : Home, Rama, `/mapa` et page publique Live.

## Night director

Oui. Je peux ouvrir n’importe quelle porte sans mémoriser une thèse artificielle,
et la seconde soirée reprend une vraie moitié de l’expédition. Le rendez-vous
H+3 laisse le temps aux trois packs sans casser la permanence de l’aventure.
