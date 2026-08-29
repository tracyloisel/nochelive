# M132 — Le duel rend son verdict et change de monde

Reviewed: 2026-08-29
Slice: fin de quiz Street — verdict du duel, couronnes, coffre et classement de cérémonie
Tests: tranche ciblée verte après le polish final
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr présents et parité validée

## Feeling

Comprendre le verdict en deux secondes, voir ce que le score change contre Amina,
puis ressentir soit la fierté d'être acclamé, soit l'envie immédiate de repartir.

## 1 — Game experience

La boucle devient : fin du quiz → couronnes gagnées → verdict nommé → comparaison
Moi/Amina → écart expliqué → coffre qui pose réellement le bonus → classement du pack
→ action suivante. La victoire ouvre une célébration collective en pleine lumière.
La défaite devient une promesse de revanche sous l'orage, avec un chemin doré qui
continue au-delà du résultat.

Le libellé administratif « 1 défi mis à jour » disparaît du cas singulier. Le joueur
ne doit plus décoder `76 · 91` : chaque total a un propriétaire, l'unité « couronnes »
et un vainqueur visuellement désigné. Le titre ne réagit plus par un « Incroyable »
indifférent au jeu : il annonce l'issue et sa conséquence.

## 2 — UI design

Verbe à deux secondes : **gagner / prendre sa revanche**.

- titre final explicite : « Tu bats Amina ! » ou « Amina garde l'avantage » ;
- sous-titre relié au total : « 105 couronnes : tu prends l'avantage » ou écart à combler ;
- sans duel, verdict fondé sur les bonnes réponses : sans-faute, maîtrise, parcours
  solide ou pack à reprendre ;
- face-à-face `Moi / contre / Amina`, avec `couronnes` sous chaque valeur ;
- gagnant cerclé d'or ;
- CTA contextuel : « Voir le duel » ou « Prendre ma revanche » ;
- Light pour la victoire, Dark pour la revanche, issus de l'illustration et non d'un
  interrupteur utilisateur ;
- égalité et attente gardent un monde neutre et leurs propres actions ;
- plusieurs impacts gardent le titre collectif et nomment le verdict sur chaque carte.
- couronne SVG redessinée comme emblème à cinq pointes, bande gravée et joyau ;
- coffre agrandi, auréolé, sonore et rejouable : il déclenche le bonus, les couronnes
  en particules et le comptage final au lieu de rester décoratif ;
- classement pleine largeur avec vrais avatars, rangs, couronnes, entrée séquencée,
  reflet et traitement spécial du leader.

## 3 — Art direction

Deux illustrations verticales 941×1672 ont été créées dans le même monde arboré que
la cérémonie existante :

- victoire : héros contemporain au centre, amis sur les passerelles qui applaudissent,
  lumière dorée, feuilles en suspension et chemin ouvert ;
- revanche : héros déterminé face au chemin, amis en soutien, pluie nocturne, éclair
  puissant et lueur dorée au loin.

La composition réserve le centre au résultat HTML et place les signes émotionnels
sur les bords, au-dessus et sous la carte. Aucun texte ni faux composant UI n'est
intégré aux images.

### Prompts finaux de production

Référence de monde et de style :
`media/masters/media/social/campus-ceremony-friends-v1.png`.

**Victoire**

> Create a premium vertical AAA mobile-game background illustration for Noche Live,
> matching the attached luminous forest campus world and its cinematic painterly
> realism. A contemporary young adult hero stands centered on a broad golden wooden
> path, joyfully acknowledged by a diverse group of real friends on both side
> balconies and around the path; they applaud, cheer and lean toward the hero with
> warm belonging, never like a posed stock photo. Celestial Light: radiant sunbeams
> through huge trees, ivory and signature gold, floating leaves, subtle magical
> particles, triumphant but intimate. Keep a generous calm central corridor and
> readable upper/lower zones for HTML score overlays; place expressive faces mainly
> toward the sides. Full-bleed 9:16 composition, deep layered perspective, no border,
> no typography, no logo, no numbers, no UI, no trophy, no religious iconography.

**Revanche**

> Create a premium vertical AAA mobile-game background illustration for Noche Live,
> in the same forest campus world and cinematic painterly realism as the attached
> reference. A contemporary young adult hero is seen from behind at the center of a
> rain-dark wooden path, steady and determined rather than defeated. Supportive
> friends watch from side balconies. Celestial Dark: a powerful white-blue lightning
> strike splits the stormy canopy, rain shines on the boards, deep navy shadows and
> warm lanterns frame the scene, while a narrow signature-gold path glows ahead as a
> clear promise of the next quiz and revenge. Preserve a calm central corridor for
> HTML score overlays and keep story details on the sides, above and below it.
> Full-bleed 9:16 composition, high contrast but readable, no border, no typography,
> no logo, no numbers, no UI, no trophy, no horror and no religious iconography.

## Theme engine

N/A — cette tranche n'est pas le Hub `/`. Elle respecte néanmoins les contrats
sémantiques Celestial Light/Dark de la cérémonie Street.

## Four seats

N/A — boucle Street asynchrone.

| Seat | Verbe maintenant |
|---|---|
| Moi | Lire le verdict puis célébrer ou relancer le duel |
| Amina | Être reconnue comme adversaire, gagnante ou perdante |
| Amis du Campus | Acclamer ou soutenir dans l'illustration |
| Autour de moi | Comprendre la rivalité sans décoder les chiffres |

## Tension

Le score du quiz monte vers le verdict social. La victoire libère la lumière et le
collectif ; la défaite garde l'intensité au lieu de tomber dans un écran mort, puis
pointe vers le prochain affrontement.

## Finale

Cette tranche est la finale du pack. Le duel ne modifie pas rétroactivement le score :
il transforme le résultat en conséquence sociale lisible et en prochaine envie.

## Languages

Copie relue dans **es**, **pt-BR**, **en** et **fr**. La parité complète des arbres i18n
est automatisée. La demande française et sa direction éditoriale sont approuvées dans
le fil ; les formulations traduites restent une proposition d'implémentation locale,
non déployée.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 9.5 |
| Clarté | 9.9 |
| Impact visuel | 9.6 |
| Feedback | 9.8 |
| Progression | 9.4 |
| Social | 9.7 |
| Immersion | 9.7 |
| Accessibilité | 9.2 |
| Cohérence NocheLive | 9.7 |
| Envie de continuer | 9.6 |

## Verdict

PASS WITH NOTES — implémentation locale, non déployée.

## What works

- verdict compris sans interpréter un séparateur numérique ;
- gagnant, écart, total et unité « couronnes » sont explicites dès le héros ;
- le CTA répond émotionnellement au résultat ;
- deux mondes réellement distincts nourrissent la fierté ou la revanche ;
- le coffre vit, délivre le bonus et répond au toucher par son, haptique et particules ;
- le classement occupe sa surface, montre les personnes et célèbre le leader ;
- aucun ancien `shout_key`, libellé générique, plinthe, étoile de cérémonie ou classe
  `points` de cette surface n'est conservé en parallèle ;
- hiérarchie lisible à 390×844, 768×1024 et 1440×900 ;
- aucun débordement horizontal ni erreur sévère en console ;
- données réalistes de QA : 10/10, 8 bonnes réponses, série 7, 00:57 ;
- tests ciblés, parité i18n et scénarios navigateur verts.

## What feels weak

- sur téléphone, la carte centrale masque volontairement une partie du héros ; les
  amis, la lumière, l'éclair et le chemin portent donc l'essentiel de la narration ;
- contrôle final sur appareils physiques encore souhaitable ;
- les traductions n'ont pas reçu de validation éditoriale externe séparée.

## Required before production approval

- Valider les quatre formulations traduites avec la responsable éditoriale ;
- faire un contrôle final sur iPhone et Android physiques.

## Evidence

- captures inspectées pour victoire et revanche aux trois viewports de référence ;
- contrôleurs Campus/cérémonie et services : 34 runs, 2635 assertions, 0 échec ;
- helper de verdict et parité i18n : 63 runs, 501 assertions, 0 échec ;
- dernier contrôle ciblé score/profil/SFX/i18n : 25 runs, 544 assertions, 0 échec ;
- cérémonie complète : 1 run, 87 assertions, 0 échec ;
- duel revanche : 1 run, 24 assertions, 0 échec ;
- duel victoire : 1 run, 22 assertions, 0 échec ;
- captures inspectées en Celestial Light et Dark à 390×844, 768×1024 et 1440×900 ;
- médias responsive générés : 437 assets, 4143 variantes.

## Night director

Oui. Si je gagne, le Campus me voit. Si je perds, la nuit ne me punit pas : elle me
montre l'éclair, le chemin et le bouton exact pour revenir battre Amina.
