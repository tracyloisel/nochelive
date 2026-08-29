# M130 — Défis laisse respirer le Campus avant les lecteurs

Reviewed: 2026-08-29
Slice: `/desafios` + tuile Campus du Hub — recadrage narratif du master lecteurs
Tests: 8 contrôleur / 97 assertions + 2 visuels / 47 assertions + 1 matrice visuelle / 40 assertions, 0 échec
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: N/A — aucune copie déplacée

## Feeling

Entrer d'abord dans un Campus lumineux, puis rencontrer les lecteurs. Le monde doit
respirer entre le HUD et les visages au lieu de transformer l'illustration en rangée
de portraits collée au chrome.

## 1 — Game experience

La boucle ne change pas : lire l'enjeu, reconnaître le prochain pack, répondre au
rival. Le nouveau cadre améliore l'anticipation sans ajouter de clic : le décor ouvre
la scène, puis le regard descend naturellement vers le groupe et la mission.

Le fond reste utile au jeu. Les cinq lecteurs, leurs livres et leur interaction sont
conservés ; la course demeure sociale plutôt que décorative.

## 2 — UI design

Le master portrait 941×1672 imposait un zoom violent dans le bandeau desktop. Il est
remplacé par un master paysage 1672×941 et douze dérivés AVIF/WebP/JPEG aux largeurs
390, 768, 1440 et 1672 px.

Le point focal vertical final est 30 %. Il garde les personnages lisibles sur les
écrans desktop peu hauts tout en laissant une grande zone de décor sous le HUD. Le
mobile conserve un recadrage central cohérent. Le test visuel attend désormais le
chargement effectif de la variante responsive après chaque changement de viewport.

États inspectés : 390×844, 768×1024, 1440×900 et session française réelle 1280×720.
Aucun débordement horizontal ni erreur console sévère.

## 3 — Art direction

ImageGen a recomposé le master en panorama Celestial Light. Le haut est maintenant
une canopée lumineuse avec ciel, lanternes, passerelles et pavillons du Campus. Les
cinq lecteurs occupent la moitié basse, avec les mêmes couleurs de vêtements, livres
ouverts et relation chaleureuse.

Le décor raconte le lieu avant le contenu. La lumière dorée, les ombres vert-bleu et
le bois sculpté prolongent la signature Noche Live sans ajouter de texte, symbole,
arme, logo ou interface dans l'image.

## Theme engine

N/A — `/desafios` n'est pas le Hub `/`. La tuile du Hub réutilise néanmoins le même
master pour préserver la continuité spatiale.

## Four seats

N/A — boucle Street asynchrone.

| Seat | Verbe maintenant |
|---|---|
| Moi | Repérer la mission puis jouer le pack |
| Mon rival | Lire et avancer dans son pack |
| Invitation | Répondre avant l'échéance |
| Autour de moi | Reconnaître un Campus vivant de lecteurs |

## Tension

Les couronnes, le score cible, la progression et l'échéance restent les moteurs de
tension. Le panorama ajoute de l'anticipation et de l'appartenance sans inventer une
urgence visuelle.

## Finale

Inchangée : dernière question à 25 points et cérémonie existante.

## Languages

N/A — aucune chaîne ni clé i18n modifiée.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 9.0 |
| Clarté | 9.7 |
| Impact visuel | 9.8 |
| Feedback | 9.0 |
| Progression | 9.5 |
| Social | 9.7 |
| Immersion | 9.9 |
| Accessibilité | 9.5 |
| Cohérence NocheLive | 9.9 |
| Envie de continuer | 9.5 |

## Verdict

PASS WITH NOTES — implémentation locale, non déployée.

## What works

- le HUD survole maintenant du décor, jamais une rangée de fronts ;
- les premiers visages restent largement sous le chrome aux trois viewports ;
- les cinq lecteurs et leurs livres restent lisibles dans la composition ;
- la version desktop n'extrapole plus un master portrait ;
- le même monde continue dans la tuile Campus du Hub ;
- le serveur local sert bien `campus-scriptures-master-v2` en AVIF.

## What feels weak

- le texte et le scrim couvrent volontairement une partie des corps en desktop ;
- un contrôle sur téléphone physique très étroit reste souhaitable.

## Required before production approval

- Contrôle final sur iPhone et Android physiques.

## Evidence

- master ImageGen : `media/masters/media/social/campus-scriptures-master-v2.png`,
  1672×941, conservé à côté de `v1` ;
- dérivés responsive : 12 fichiers AVIF/WebP/JPEG, 390 à 1672 px ;
- captures inspectées : 390×844, 768×1024, 1440×900 et français 1280×720 ;
- page réelle : source `...master-v2/...-1672.avif`, `object-position: 50% 30%` ;
- console : 0 erreur sévère ; aucune permission ou destination externe modifiée ;
- direction artistique explicitement demandée : ajouter de la scène avant les visages.

## Night director

Oui. Le monde apparaît maintenant avant les joueurs, puis les livres ramènent le
regard vers la mission : je comprends où je suis et pourquoi je continue.
