# 148 — Fiche joueur Celestial Glass

Reviewed: 2026-08-30
Slice: consulter sa fiche, corriger une donnée canonique et repartir vers son histoire
Tests: 33 runs / 297 assertions fonctionnelles, 18 / 25 194 architecture, 5 / 294 système visuel — 0 failure
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en et fr relus et validés

## Feeling

Le joueur doit ressentir de la fierté, de l’appartenance et du contrôle : « c’est bien moi, voici ma communauté et tout ce que j’ai déjà vécu ». La fiche ne doit jamais ressembler à l’administration d’un compte SaaS.

## 1 — Game experience

Revue `noche-night` effectuée en premier.

La boucle est courte et honnête : reconnaissance immédiate par l’avatar, le nom, le rang, les couronnes et la série ; choix entre corriger une donnée ou rouvrir un parcours ; action focalisée ; feedback de validation ; retour à la fiche ou à la destination Aventure, Parole ou Défis. Le prochain désir vient des historiques visibles et de la progression réelle, sans niveau ni récompense inventés.

La motion soutient cette boucle sans la transformer en cérémonie : entrée complète en moins de 650 ms, signature lumineuse unique, aucun mouvement ambiant infini, aucun son et aucune vibration pour ces actions calmes. L’historique apparaît par sessions et non question par question afin de préserver le rythme des longues listes.

Le changement de paroisse conserve la personne et sa progression, puis revient à la fiche. Parole ouvre l’historique existant : aucun second historique concurrent n’a été créé.

## 2 — UI design

Revue `noche-ui` effectuée en second.

Le test des deux secondes répond à : qui — avatar et nom ; où — paroisse ; où j’en suis — couronnes, rang, série et résumés ; que faire — lignes canoniques et destinations. La lecture reste l’état par défaut. Chaque édition est un panneau contextuel avec valeur préremplie, autofocus, compteur, loading, succès, erreur locale, annulation et restauration du focus.

L’entrée suit titre, héros puis quatre groupes avec un stagger borné à 55 ms. Les plaques réagissent en 160 ms, l’éditeur s’ouvre en 180/320 ms et se ferme en 200 ms avant la navigation. `Escape`, la croix, Annuler et le clic sur le voile partagent la même sortie. La poignée factice a été retirée puisqu’aucun geste de déplacement n’est proposé.

Les surfaces utiles seulement reçoivent le verre ivoire. Les listes partagent un même panneau avec séparateurs fins ; elles ne deviennent pas une mosaïque de cartes. Le bouton principal est un verre doré translucide et les actions secondaires restent neutres. Les cibles mesurées font au moins 44 × 44 px, le dock disparaît sous l’éditeur et les actions restent visibles à 390 × 844.

Les états testés couvrent profil réaliste, minimal, noms maximaux, paroisse longue/partielle, quatre langues, loading, erreur 422, reduced motion, reduced transparency et fallback CSS sans `backdrop-filter`.

## 3 — Art direction

Revue `noche-art` effectuée en troisième.

Celestial Light est dicté par le décor de rassemblement lumineux. La composition garde l’architecture sacrée visible, fait du héros joueur le premier monument, puis descend vers identité, communauté et parcours. L’or reste une signature de métal, de liseré et d’action principale ; les titres demeurent en encre.

L’orbite, l’étoile et le reflet du héros ne jouent qu’une fois. Le verre reste un matériau statique : aucun `backdrop-filter` n’est interpolé. La feuille d’édition est suffisamment dense pour rester lisible dès sa première frame, sans perdre son caractère transparent.

Sept médaillons propres à la feature ont été générés et inspectés. Le premier essai de paroisse a été refusé parce qu’il comportait une croix ; la version livrée représente une église moderne sans symbole confessionnel. Le voile, la densité du verre, les noms extrêmes, l’erreur doublée et la cible de fermeture subpixel ont tous été repris puis recapturés.

## Theme engine

N/A : `/ficha` est explicitement une surface Celestial Light déterminée par son artwork. Aucun sélecteur de thème utilisateur et aucun markup parallèle n’ont été ajoutés. Les matériaux reposent néanmoins sur les familles sémantiques et possèdent un fallback opaque lisible.

## Four seats

N/A — surface Street personnelle.

| Question Street | Réponse immédiate |
|---|---|
| Qui ? | Avatar, nom, rang réel |
| Où ? | Paroisse associée |
| Quoi maintenant ? | Corriger une donnée ou ouvrir un parcours |
| Autour de moi ? | Rang paroissial, défis et appartenance |

## Tension

Pas de tension de manche sur une fiche. La progression réelle et les destinations créent une invitation calme à reprendre l’aventure ; aucun compte à rebours ou artificiel de récompense n’est ajouté.

## Finale

N/A.

## Languages

Les libellés de la feature ont été relus en espagnol, portugais brésilien, anglais et français. Les quatre rendus ont été exercés dans Chrome avec contrôle d’overflow. Le changement de langue écrit la personne, les sièges Live liés et le cookie de préférence.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8.6 |
| Clarté | 9.6 |
| Impact visuel | 9.4 |
| Feedback | 9.5 |
| Progression | 9.2 |
| Social | 8.8 |
| Immersion | 9.4 |
| Accessibilité | 9.7 |
| Cohérence NocheLive | 9.6 |
| Envie de continuer | 9.0 |

## Verdict

PASS

## What works

- La fiche fait reconnaître le joueur avant de lui demander quoi que ce soit.
- Le verre conserve le monde visible tout en restant lisible sur mobile et desktop.
- L’édition Prénom est focalisée, réversible, accessible et sans bouton « web 2004 ».
- La motion donne une continuité matérielle au profil, avec succès sur la ligne d’origine et erreur strictement locale.
- Parole et les autres parcours conduisent aux systèmes existants avec des métriques réelles.
- Les sept médaillons donnent une identité de jeu cohérente sans transformer chaque ligne en carte.

## What feels weak

- Le profil reste par nature un moment calme ; son « fun » vient de la fierté et des portes vers le jeu, pas d’une mécanique autonome.
- Les actions self-service d’export, d’effacement et de révocation distante restent volontairement hors MVP faute de preuve d’identité renforcée.

## Required before approval

- None.

## Evidence

- Viewports inspectés : 390 × 844, 768 × 1024, 1440 × 900.
- Captures : `tmp/street-shots/profile-dashboard/`.
- Console : aucun WARNING ni SEVERE sur les vues normales profil/éditeur ; l’unique entrée réseau 422 du scénario d’erreur est attendue et vérifiée, sans exception JavaScript.
- Interaction : consultation, six éditeurs, save/cancel/Escape, fermeture animée, restauration du focus, compteur, succès local, erreur conservée, loading, Parole, retour de paroisse, langue, profil minimal et textes extrêmes.
- Motion : noms d’animations calculés dans Chrome pour héros, groupes, médaillons, voile, feuille et historique ; aucune animation appliquée aux réponses individuelles.
- Accessibilité : dialogue modal nommé, erreur reliée par `aria-describedby`, live region, focus, reduced motion/transparency y compris transition de document, spinner statique en réduction de mouvement, fallback sans blur, cibles tactiles mesurées.

## Night director

Oui, j’ai envie de repartir jouer : la fiche transforme la progression passée en portes visibles vers Aventure, Parole et Défis, tout en renforçant l’appartenance à la paroisse.
