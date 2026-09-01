# M173 — La Rama comme histoire collective

Reviewed: 2026-09-01
Slice: transformer la fiche fonctionnelle d’une unité locale en récit vivant de sa communauté
Tests: 27 runs, 723 assertions, 0 failure ; 42 tests JavaScript, 0 failure
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — la page conserve le HUD et le dock partagés sans les modifier
Copy: `.agents/skills/noche-i18n/SKILL.md` — 50 clés terminales à parité en es, pt-BR, en et fr

## Feeling

La page doit faire sentir : « voici ce que nous vivons ensemble cette semaine ».
L’appartenance précède l’information pratique ; la curiosité biblique, l’attente
de la prochaine soirée, la conversation et la compétition amicale donnent
ensuite envie de revenir.

## 1 — Game experience

La boucle est linéaire : reconnaître sa communauté → entrer dans son étude →
anticiper sa prochaine rencontre → lire ou rejoindre sa conversation → voir qui
avance → préparer une visite. Une section porte une seule idée. La progression
réelle de l’expédition et le classement créent une tension légère sans inventer
de métrique. Les zéros sociaux, le countdown inactif et le nombre attendu de
participants ont disparu.

Le Cercle a trois états honnêtes : deux conversations réelles pour un membre,
une invitation calme lorsque le Cercle actif est vide, et aucune donnée privée
dans le HTML invité. Le mode `read_only` ouvre les échanges sans inviter à
répondre.

## 2 — UI design

Le verbe se lit en deux secondes dans chaque chapitre : venir, étudier, se
retrouver, parler, jouer, visiter. La page renonce aux cartes de dashboard au
profit de six scènes pleine largeur. Le HUD et le dock restent les composants
partagés exacts ; aucune règle locale ne les redessine.

Les trois actions du hero et de la visite ont des cibles confortables. La
typographie fonctionnelle de la page a un plancher de `0.94rem`, qui continue de
respecter les réglages d’agrandissement globaux. Les citations du Cercle ont une
cible minimale de 44 × 44 px. À 390 px, la dernière action du hero garde 36 px
avant le dock et aucune action finale n’est occultée.

## 3 — Art direction

Benidorm possède un artwork humain et local, livré en cadrages portrait et
paysage. Les scènes alternent nuit biblique, lumière de rassemblement et accueil
à la chapelle. Les gradients protègent la lecture sans transformer les scènes en
cartes opaques. L’or reste une signature et un guide d’action, tandis que les
portraits du classement font apparaître les personnes avant leurs scores.

## Motion et performance

Les révélations sont locales, one-shot et limitées aux contenus qui peuvent
bouger. Dans la ligue, seuls les cinq portraits sont staggerés ; noms et scores
restent stables. Le dernier chapitre ferme l’observer et place la page en
`ready`. Turbo, absence de Web Animations et `prefers-reduced-motion` aboutissent
tous au même état lisible.

Le hero charge en priorité un AVIF adapté au viewport ; les chapitres suivants
sont différés. Portrait et paysage existent en AVIF, WebP et JPEG avec `srcset`.
La passe navigateur ne relève aucune image cassée, aucune erreur console et
aucun débordement horizontal.

## Trois états humains

| État | Ce que la page raconte |
|---|---|
| Membre, Cercle actif | Nos questions, mon rang et l’écart réel avec la personne devant moi |
| Membre, Cercle vide | Le Cercle est calme, mais la lecture de la semaine reste le prochain geste |
| Invité | Une communauté, son étude, sa prochaine soirée, ses joueurs et une invitation à venir — jamais ses échanges privés |

## SEO public

Chaque unité reçoit un slug public persistant, unique et indépendant de son
adresse. Les collisions de ville sont qualifiées avec le nom de l’unité, de la
chapelle ou son code. Les quatre URLs canoniques utilisent le nom localisé de la
confession, avec `hreflang`, sitemap, métadonnées indexables et données
structurées `Church`. `/ramas/:code` demeure la route applicative compatible ;
la route localisée est la version canonique destinée aux moteurs.

## Languages

Les quatre voix ont été relues comme des textes natifs. Les couples d’unité sont
distincts : Rama/Barrio, Branche/Paroisse, Branch/Ward et Ramo/Ala. Les pluriels,
interpolations, états actifs et lecture seule ont la même structure dans les
quatre locales.

## Scores (/10)

Toute dimension est supérieure ou égale à 8.

| Dimension | /10 |
|---|---:|
| Fun | 8.7 |
| Clarté | 9.6 |
| Impact visuel | 9.7 |
| Feedback | 8.9 |
| Progression | 9.2 |
| Social | 9.5 |
| Immersion | 9.6 |
| Accessibilité | 9.5 |
| Cohérence NocheLive | 9.7 |
| Envie de continuer | 9.3 |

## Verdict

PASS.

## What works

- La page raconte « nous » sans inventer une seule feature ni un faux signal.
- Les six scènes gardent une hiérarchie nette aux trois formats.
- Le Cercle apporte de vraies voix humaines tout en restant strictement privé.
- Le confort de lecture progresse sensiblement sans alourdir la composition.
- Le HUD et le dock restent identiques aux autres pages NocheLive.

## What feels weak

- Les unités autres que Benidorm utilisent encore l’artwork de chapelle générique ;
  la structure est prête à recevoir leur propre monde visuel plus tard.
- La force sociale dépend naturellement de conversations et de scores récents ;
  les états vides restent donc volontairement calmes.

## Required before approval

- None.

## Evidence

- Contrôleur, projection Circle, slug SEO et modèle Ward : 24 runs,
  165 assertions, 0 failure.
- Matrice système `RAMA_SCREENSHOTS=1` : 3 runs, 558 assertions,
  0 failure, 0 error, 0 skip.
- Neuf captures : membre avec conversations, membre avec Cercle vide et invité,
  chacune en 390 × 844, 768 × 1024 et 1440 × 900.
- Runtime JavaScript complet : 42 tests, 0 failure ; contrôleur Rama ciblé :
  5 tests, 0 failure.
- RuboCop ciblé : 10 fichiers, 0 offense ; `git diff --check` propre.
- Navigateur réel : largeur de scroll égale au viewport aux trois formats,
  texte utile minimal à 15.04 px sur mobile/tablette, page motion `ready`,
  0 warning/error console et 0 image cassée.

## Night director

Oui. La prochaine action n’est plus cachée dans une fiche : chaque scène donne
une raison différente de revenir vers cette communauté — comprendre, se
retrouver, répondre ou rattraper quelqu’un.
