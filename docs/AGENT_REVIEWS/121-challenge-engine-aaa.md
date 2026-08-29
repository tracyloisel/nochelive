# M121 — Le défi devient une rivalité vivante

> **Superseded pour l'architecture multi-duels.** Cette revue décrit le premier
> correctif mono-duel. La cible produit et technique à implémenter est désormais
> [STREET_MULTI_DUEL_ENGINE_PLAN.md](../STREET_MULTI_DUEL_ENGINE_PLAN.md) : N rivalités
> actives, scores bruts comparables entre packs et fan-out d'un run vers plusieurs
> duels. La rotation forcée de pack documentée plus bas ne doit pas être conservée.

Reviewed: 2026-08-28
Slice: envoi → reçu → vu → accepté → face-à-face → verdict → revanche sur un nouveau pack
Tests: domaine défi — 110 runs, 666 assertions ; navigateur — 3 runs, 17 assertions ; Service Worker — 6 tests ; 0 failure, 0 error sur le périmètre
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md` — même markup et tokens sémantiques, aucun toggle
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en et fr lus, parsés et à parité

## Feeling

Faire monter une rivalité claire et personnelle. Le challenger doit sentir que son
gant a atteint l'autre joueur ; le destinataire doit comprendre en deux secondes
qui l'appelle et quel score l'attend ; tous deux doivent reconnaître la revanche
avant même de lire la question. Le verdict doit provoquer soit la fierté, soit
l'envie immédiate de reprendre la couronne.

## 1 — Game experience

La boucle possède désormais des battements observables : le défi part, le signal
est reçu, la fiche est vue, l'adversaire accepte et le duel passe en jeu. Le
challenger suit ces états en direct. Pendant la partie, un ruban nomme explicitement
« défi » ou « revanche » et l'adversaire. À la fin, le verdict précède les coffres,
statistiques et classements : issue, écart, visages et scores sont le premier enjeu
social visible.

La revanche conserve sa filiation mais sélectionne le prochain pack de la rotation,
en privilégiant un pack encore inédit dans cette rivalité. Elle ne peut jamais
réutiliser silencieusement un duel ordinaire déjà ouvert ni relancer immédiatement
le pack qui vient d'être terminé lorsque le catalogue en contient plusieurs.

## 2 — UI design

Le verbe prioritaire est « ouvrir le face-à-face ». Le signal entrant occupe la zone
sûre sous le HUD, avec un z-index supérieur au dock et un bouton de fermeture de
44 px. La chronologie envoyé/reçu/vu/accepté remplace l'attente aveugle. Le ruban en
jeu reste compact, non interactif et lisible sans masquer la question. Le verdict
forme un héros autonome avec état victoire, défaite ou égalité, gagnant encadré et
CTA doré annonçant le nom du prochain pack.

États couverts : envoyé, reçu, vu, accepté, en jeu, terminé, victoire, défaite,
égalité, défi, revanche, signal fermé et fallback Push. Les erreurs réseau d'accusé
ne bloquent jamais l'accès au défi.

## 3 — Art direction

Le système appartient à la cour céleste : médaillon du défi, verre teinté par la
scène, liseré or, ruban marine et verdict de tournoi. La lumière se concentre sur
le signal puis sur le gagnant. Les animations sont courtes et désactivées avec la
préférence de mouvement réduit. Les sons réemploient les cues nommés `duel_send`,
`reveal` et `stake_gain` au lieu d'ajouter un bruit générique.

## Theme engine

Le Hub et le jeu gardent une seule structure. Les surfaces utilisent les tokens
`surface`, `text`, `gold`, `fire` et `navy` de la scène Celestial Light ou Dark ;
aucune préférence de thème, aucun fork d'ERB et aucun style basé sur un décor
particulier n'ont été ajoutés.

## Four seats

N/A — boucle Street asynchrone.

| Seat | Verb tonight |
|---|---|
| Challenger | Envoyer, suivre la réception et lire le verdict |
| Adversaire | Ouvrir, accepter et jouer le même pack du face-à-face |
| Autour de moi | Voir la rivalité dans le Hub sans écran d'administration |
| Prochain désir | Relancer immédiatement sur un nouveau pack |

## Tension

La tension monte par preuve : envoyé → reçu → vu → accepté → score à battre →
verdict. Sans le ruban et les accusés, ce serait un quiz silencieux ; avec eux, chaque
étape rappelle qu'une personne précise est de l'autre côté.

## Finale

Le dernier écran du pack traite le duel comme le vrai enjeu de la manche. Le verdict
est rendu juste après le héros de cérémonie, avant le médaillon, le coffre, les
statistiques et les deux classements. Une défaite garde une sortie active : la
revanche nomme immédiatement son prochain terrain.

## Languages

Les nouveaux états, résultats, signaux, rubans et CTA ont été lus en es, pt-BR, en
et fr. Les quatre YAML se chargent sans erreur ; le français utilise les espaces
insécables fines avant `!` et `:`.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 9 |
| Clarté | 9.5 |
| Impact visuel | 9 |
| Feedback | 9.5 |
| Progression | 9 |
| Social | 9.5 |
| Immersion | 9 |
| Accessibilité | 8.5 |
| Cohérence NocheLive | 9.5 |
| Envie de continuer | 9.5 |

## Verdict

PASS WITH NOTES

## What works

- accusés monotones et signés, propagés du Service Worker au duel ;
- fallback Push différé seulement si le signal temps réel n'a pas été reçu ;
- signal mobile mesuré au-dessus du dock, CTA et fermeture accessibles ;
- filiation de revanche persistée et rotation garantie hors du pack précédent ;
- identité défi/revanche maintenue pendant le jeu et jusqu'au verdict ;
- résultat social remonté avant les récompenses individuelles.

## What feels weak

- un navigateur peut confirmer « reçu », mais pas garantir que la notification
  native a été humainement remarquée ; seul « vu » signifie que la fiche a été ouverte ;
- les tests simulent le Push et les dimensions mobiles, sans remplacer deux appareils
  physiques avec leurs politiques iOS/Android réelles.

## Required before approval

- Effectuer un duel réel entre deux téléphones installés : écran verrouillé, app au
  premier plan puis arrière-plan, et confirmer reçu/vu/accepté dans les trois cas.

## Evidence

Captures vérifiées à 390×844 : `challenge-signal-phone.png`,
`rematch-ask-phone.png` et `duel-result-phone.png`. Le test du signal mesure
explicitement sa limite basse contre le haut du dock et compare leurs z-index.

La suite Rails globale exécute 1 027 runs et 15 408 assertions. Son unique échec,
`Audience::SnapshotTest#test_never_exposes_the_answer_while_delayed_reveal_is_pending`,
est hors périmètre, n'a aucun fichier modifié par cette slice et se reproduit isolément.

## Night director

Oui. Le premier duel donne envie de connaître la réponse de l'autre ; le verdict
donne envie de reprendre la couronne ; la revanche change de terrain au lieu de
faire répéter la même soirée.
