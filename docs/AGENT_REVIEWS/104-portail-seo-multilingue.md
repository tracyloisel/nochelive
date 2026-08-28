# 104 — Portail SEO multilingue

Reviewed: 2026-08-28
Slice: une porte publique vers l’aventure, distincte du produit personnalisé
Tests: ciblés `bin/rails test` — 36 runs, 547 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr présents et validés

## Feeling

Curiosité puis envie d’entrer : une personne qui arrive depuis Google doit comprendre que la Bible n’est pas présentée comme une fiche scolaire, mais comme une aventure à vivre avec d’autres.

## 1 — Game experience

Boucle : intention de recherche → réponse éditoriale claire → aperçu de l’expérience → choix d’un autre contenu ou entrée dans le jeu. Les pages évitent le cul-de-sac grâce à trois liens contextuels et un CTA principal unique.

## 2 — UI design

Le verbe principal est visible en moins de deux secondes. Le portail est mobile-first, les liens ont des libellés explicites et le changement de langue est constitué de vrais liens crawlables. Les écrans applicatifs restent séparés et noindex.

## 3 — Art direction

Celestial Dark, lumière or et typographie éditoriale. La composition va d’un grand seuil narratif vers trois chapitres, puis trois prochaines portes. Elle appartient à Noche Live sans imiter le hub personnalisé.

## Theme engine

N/A — le hub `/` n’est pas dupliqué ni modifié par le portail public.

## Four seats

N/A — acquisition publique. La destination du CTA retrouve le hub normal et ses sièges existants.

## Tension

La tension est éditoriale : promesse → preuve → prochain choix. Les pages évitent le quiz silencieux en parlant de la salle, des équipes, du présentateur et du passage biblique derrière chaque question.

## Finale

N/A.

## Languages

PASS. Espagnol source naturel ; français chaleureux avec tutoiement individuel ; portugais brésilien avec *ala*, *equipe* et *celular* ; anglais familial sans vocabulaire de concours télévisé. Les 28 combinaisons page/langue sont rendues par test.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 8 |
| Feedback | 8 |
| Progression | 8 |
| Social | 9 |
| Immersion | 8 |
| Accessibilité | 8 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS WITH NOTES

## What works

- Frontière nette entre acquisition indexable et produit personnalisé noindex.
- Trois clusters avec une longue traîne chacun, en quatre langues et avec maillage réciproque.
- Passage biblique relié à la source, au contexte et au jeu.

## What feels weak

- Les impressions et positions dépendent encore de la soumission externe dans Search Console après déploiement.
- La soumission et les données de performance réelles restent des opérations externes après déploiement.

## Required before approval

- None côté code. Soumettre le sitemap et vérifier les pages prioritaires après déploiement.

## Night director

Oui : chaque page promet une action collective concrète et offre immédiatement une autre porte ou l’entrée dans le jeu.
