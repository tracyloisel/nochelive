# M127 — Défis devient une mission dans le Campus

Reviewed: 2026-08-29  
Slice: `/desafios` — monde Campus → rail de scores → mission suivante → course sociale  
Tests: 8 tests contrôleur / 80 assertions + 4 tests visuels / 50 assertions, 0 échec  
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)  
Experience: `.agents/skills/noche-night/SKILL.md`  
UI: `.agents/skills/noche-ui/SKILL.md`  
Art: `.agents/skills/noche-art/SKILL.md`  
Copy: N/A — aucun texte, choix de contenu ou comportement éditorial modifié

## Feeling

Entrer dans une course amicale qui se déroule réellement au Campus : les lecteurs
sont le monde, le score est le HUD et le prochain pack est la mission immédiate.

## 1 — Game experience

La boucle reste honnête et inchangée : voir le pack → comprendre les points → lire ce
que fait le rival → jouer → revenir au résultat. La passe supprime un écran mort
visuel : l’ancienne grande plaque ivoire répétait le titre comme une page web et
reléguait les lecteurs à une bannière. Le regard suit maintenant décor → Défis →
scores → prochain pack sans détour administratif.

La mission suivante chevauche légèrement la sortie du décor. Cette continuité donne
une prochaine envie sans inventer de compte à rebours, de récompense ou d’activité.

## 2 — UI design

Le titre et son résumé sont posés directement sur le décor avec un scrim local. Les
trois compteurs deviennent une seule raille navy vitrée, séparée par des filets et non
trois mini-cartes. À 390 px, le Campus conserve 352 px de hauteur et la mission entre
avant la fin du héros. Cette géométrie est désormais testée.

Le pack reste l’unique verbe or avec un CTA de 46 px. La recherche est devenue un
champ et un bouton intégrés dans une capsule de 44 px. Les rivaux sont des tickets
séparés, avec points, pack et état. Les informations textuelles restent complètes ;
les médaillons restent décoratifs.

États vérifiés : sans défi, rival live, français, mouvement réduit. Les états serveur
d’erreur et d’invitation ne changent pas. Aucune permission ni notification n’est
introduite.

## 3 — Art direction

Univers : Campus des Écritures, Celestial Light naturel. L’art n’est plus derrière
une feuille de papier : il porte le titre en crème et or, avec une profondeur locale
navy en bas. Les médaillons ImageGen, le métal or, l’émail navy et l’ivoire forment
une même famille.

La mission utilise une surface ivoire lumineuse avec une lueur interne très contenue.
Les sections sociales deviennent des feuilles vitrées plus fines et les tickets
introduisent du rythme sans refaire un dashboard. Aucun VFX nouveau : l’entrée
stagger existante suffit, et le mouvement réduit livre immédiatement l’état final.

## Theme engine

N/A — `/desafios` n’est pas le Hub `/`.

## Four seats

N/A — boucle Street asynchrone.

| Seat | Verbe maintenant |
|---|---|
| Moi | Jouer la mission pack mise en avant |
| Mon rival | Continuer son pack ; son activité live reste visible |
| Autour de moi | Comparer points et pack avant d’inviter |
| Prochaine envie | Revenir voir si la course a bougé |

## Tension

La tension vient des valeurs existantes : points, score cible, progression, présence
live et échéance réelle. La raille de scores les fait lire comme un HUD de course sans
fabriquer d’urgence.

## Finale

Inchangée : dernière question à 25 points, score et cérémonie existants intacts.

## Languages

N/A — aucun libellé n’a changé. Le parcours français a été rejoué jusqu’au quiz ;
`Rivaux de ta communauté` passe sur deux lignes sans clipping et le CTA reste à
46 px.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 9.0 |
| Clarté | 9.6 |
| Impact visuel | 9.6 |
| Feedback | 8.8 |
| Progression | 9.4 |
| Social | 9.4 |
| Immersion | 9.7 |
| Accessibilité | 9.2 |
| Cohérence NocheLive | 9.7 |
| Envie de continuer | 9.4 |

## Verdict

PASS WITH NOTES — implémentation locale, non déployée.

## What works

- les lecteurs redeviennent le monde plutôt qu’une bannière ;
- la hiérarchie tient en deux secondes : score, mission, rival ;
- le HUD unifié remplace trois petites cartes de dashboard ;
- la mission chevauche le décor sans masquer les visages ;
- recherche et tickets de rivaux ont un rythme plus tactile ;
- aucun overflow, aucune troncature bloquante, aucune erreur console `SEVERE`.

## What feels weak

- le téléphone physique et la luminosité extérieure restent à contrôler ;
- les formulations de M125 n’ont toujours pas de validation éditoriale explicite ;
- cette passe n’ajoute volontairement aucun son ou haptique à l’écran de sélection.

## Required before production approval

- Validation éditoriale des formulations proposées dans M125 ;
- contrôle sur iPhone et Android physiques, avec focus clavier et plein soleil.

## Evidence

- captures inspectées : 390×844, 768×1024, 1440×900, défi actif 390, français 390,
  mouvement réduit 390 ;
- héros mobile mesuré à au moins 350 px, fond du titre transparent, mission en
  chevauchement testée ;
- CTA principal 46 px, recherche 44 px ;
- console navigateur : 0 entrée `SEVERE` sur référence et rival live ;
- tests contrôleur : 8 / 80, verts ; tests visuels : 4 / 50, verts.

## Night director

Oui. Je n’entre plus sur une feuille de paramètres sociaux : j’arrive au Campus, je
vois mon score, puis une mission pack me donne immédiatement quelque chose à battre.
