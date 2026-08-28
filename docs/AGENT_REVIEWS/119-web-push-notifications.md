# M119 — Web Push, le prochain rendez-vous choisi

Reviewed: 2026-08-28
Slice: valeur vécue → consentement précis → notification → ressource exacte
Tests: 998 runs, 15 175 assertions, 0 failure, 0 error, 93,93 % de couverture ; 5 tests Service Worker verts
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — le moteur du Hub ne change pas
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en et fr à parité

## Feeling

Se sentir attendu par une personne ou accompagné par une parole, jamais suivi
par une campagne. Le retour doit sembler être la suite naturelle d'un duel ou
d'un chemin d'étude déjà choisi.

## 1 — Game experience

Le Push prolonge deux boucles existantes : réponse sociale d'un rival et lumière
biblique régulière. Il reste absent de l'onboarding et du Live. L'invitation
arrive après la valeur, une catégorie à la fois ; l'appui ramène au duel ou au
passage exact. Le rappel unique conserve l'anticipation sans fabriquer d'urgence.

## 2 — UI design

La ficha sépare clairement état technique de l'appareil et choix de la personne.
Les CTA nomment la ficha, le contenu, la fréquence et l'appareil. Les états
inconnu, autorisé, refusé, non supporté, iOS à installer, expiré, actif, retiré,
réattribué et en erreur existent. Les actions impossibles disparaissent ; le
bouton fixe du profil s'efface pendant la lecture des réglages.

## 3 — Art direction

L'épilogue Light est un sceau ivoire et or posé dans la cour des défis. L'épilogue
Dark reprend le bleu nocturne de l'étude, sa lumière dorée et son type crème.
L'or reste l'unique action contextuelle. Les cartes conservent l'artwork visible
et ne ressemblent ni à un dashboard SaaS ni à un dialogue système.

## Theme engine

N/A. Celestial Light/Dark est hérité de la surface et de son artwork, jamais
choisi par un toggle.

## Street seats

| Contexte | Verbe |
|---|---|
| Joueur actif | Continuer à jouer ; Turbo reste prioritaire |
| Rival absent | Appuyer et entrer directement dans l'arène |
| Lecteur | Ouvrir le passage exact puis poursuivre son chemin |
| Appareil familial | Confirmer la ficha avant toute réattribution |

## Tension

Le nom du rival et l'attente de sa réponse portent la tension. Le rendez-vous
biblique porte une attente douce, sans badge anxiogène ni série punitive.

## Finale

N/A pour la finale Live. Le résultat de duel constitue sa propre petite finale
et revient directement à l'arène résolue.

## Languages

Les clés sont parallèles et rendues en es, pt-BR, en et fr. Les notifications
gardent la langue enregistrée par appareil ; les destinations bibliques sont
générées dans cette même langue.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.5 |
| Clarté | 9.5 |
| Impact visuel | 9 |
| Feedback | 9 |
| Progression | 8.5 |
| Social | 9 |
| Immersion | 9 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9.5 |
| Envie de continuer | 9 |

## Verdict

PASS WITH NOTES

## What works

- permission après un geste explicite, jamais pendant l'onboarding ;
- consentement granulaire, retrait et appareil partagé traités sans ambiguïté ;
- deep link défensif vers la ressource exacte, app ouverte ou fermée ;
- deux familles visuelles réellement lisibles, y compris reduced-motion ;
- résilience PostgreSQL/Solid Queue, déduplication et rétention alignées avec la politique de confidentialité.

## What feels weak

- les écrans et flux simulés ne remplacent pas Safari iOS installé ni Chrome Android réel ;
- le pilote et l'alerte Render sur retard de file nécessitent le déploiement autorisé ;
- le catalogue biblique initial est volontairement petit.
- `bin/ci` valide tests, couverture et seeds mais reste globalement rouge sur 35 offenses RuboCop et un avertissement Brakeman faible préexistants, hors de cette slice ; les 67 fichiers Ruby touchés ici sont propres.

## Required before approval

- Aucun veto logiciel. Exécuter la recette physique et le pilote progressif avant
  l'ouverture générale du feature flag.

## Evidence

Captures 390×844 Light/Dark et iOS, contrôles 430×932, 768×1024 et 1440×900,
parité de copie, tests de permission simulée, appareil partagé, DST, déduplication,
révocation, nettoyage, CSRF et ouverture directe.

## Night director

Oui : l'appui n'ouvre pas une boîte de réception générique. Il remet immédiatement
le joueur devant la personne ou la parole qui lui avait donné envie de revenir.
