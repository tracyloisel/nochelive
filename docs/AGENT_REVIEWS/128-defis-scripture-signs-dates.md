# M128 — Défis parle enfin lecture, couronnes et échéances

Reviewed: 2026-08-29  
Slice: `/desafios` + `/desafio/:token` — signes bibliques, dates et contrôles de mission  
Tests: 8 contrôleur / 97 assertions + 4 visuels / 68 assertions, 0 échec  
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)  
Experience: `.agents/skills/noche-night/SKILL.md`  
UI: `.agents/skills/noche-ui/SKILL.md`  
Art: `.agents/skills/noche-art/SKILL.md`  
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en et fr alignés

## Feeling

Comprendre en un regard que le défi est une course de lecture biblique, pas un combat
générique : les couronnes ont de la valeur, les livres se répondent, les invitations
circulent comme des parchemins et deux compagnons avancent avec leurs bâtons.

## 1 — Game experience

La boucle reste courte : voir la valeur → reconnaître le prochain pack → lire
l’échéance → accepter ou jouer. Les dates exactes retirent l’ambiguïté des invitations
sans supprimer la tension relative. Le CTA principal conserve une cible de 46 px mais
cesse de prendre toute la carte.

Les contrôles ne flottent plus au-dessus du contenu sur la page d’invitation. Ils
arrivent après la règle du défi, dans le flux, puis laissent le dock intact.

## 2 — UI design

Les quatre PNG détaillés sont remplacés par des SVG à silhouette courte :

- couronne : total et score ;
- livre contre livre : défi actif ;
- parchemin contre parchemin : invitation ;
- bâton de berger contre bâton de berger : choix du rival ;
- livre ouvert simple : prochain pack.

Le bouton de mission n’est plus une pilule générique. Il devient un contrôle compact
à angle doux avec un module flèche distinct. Les actions d’invitation mesurent 46 px,
restent au-dessus du plancher tactile de 44 px et ne s’étirent plus artificiellement.

Les invitations entrantes affichent leur échéance exacte et le temps restant. Les
invitations envoyées affichent leur date d’envoi. La page détail répète l’échéance.

États inspectés : défi vide, invitation entrante, invitation envoyée, page invitation
visiteur, page invitation joueur, français et mouvement normal. Pressed et focus
restent fournis par le kit `.btn`; aucune permission ou notification ne change.

## 3 — Art direction

Univers : Campus des Écritures, Celestial Light naturel. Le décor de lecteurs reste le
monde. L’or est réservé aux couronnes, au métal du CTA et aux petits repères. Les signes
navy ne sont plus des mini-illustrations émaillées ; ils lisent comme un alphabet du
Campus jusque dans le HUD.

Aucun VFX nouveau n’est nécessaire : le gain vient de la sémantique et de la netteté,
pas d’une animation supplémentaire.

## Theme engine

N/A — `/desafios` n’est pas le Hub `/`.

## Four seats

N/A — boucle Street asynchrone.

| Seat | Verbe maintenant |
|---|---|
| Moi | Jouer le livre mis en avant |
| Mon rival | Avancer dans son propre livre |
| Invitation | Répondre avant l’échéance affichée |
| Autour de moi | Choisir un compagnon/rival dans la communauté |

## Tension

La tension reste honnête : couronnes, cible, progression du pack, présence du rival et
échéance réelle. Aucun sablier décoratif ni fausse urgence n’est ajouté.

## Finale

Inchangée : dernière question à 25 points et cérémonie existante.

## Languages

Les clés `duel_campus.dates.expires` et `duel_campus.dates.sent` existent dans les
quatre langues. Le total est nommé par la monnaie du jeu : coronas / crowns /
couronnes / coroas. Les dates utilisent le format local existant.

noche-i18n: PASS — formulations courtes et naturelles en es, pt-BR, fr et en.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 9.0 |
| Clarté | 9.8 |
| Impact visuel | 9.3 |
| Feedback | 9.0 |
| Progression | 9.5 |
| Social | 9.5 |
| Immersion | 9.7 |
| Accessibilité | 9.5 |
| Cohérence NocheLive | 9.8 |
| Envie de continuer | 9.4 |

## Verdict

PASS WITH NOTES — implémentation locale, non déployée.

## What works

- chaque petit signe possède maintenant un sens biblique distinct ;
- les couronnes identifient immédiatement la valeur du jeu ;
- dates exactes et temps restant coexistent sans ambiguïté ;
- les CTA ont une anatomie de mission compacte et une cible tactile conforme ;
- le décor Campus reste présent et les cartes ne reprennent plus toute la scène ;
- le serveur local sert la même feuille de style que les tests et le navigateur.

## What feels weak

- un contrôle sur téléphone physique et en plein soleil reste souhaitable ;
- aucun retour sonore ou haptique n’est ajouté à cet écran de sélection.

## Required before production approval

- Contrôle final sur iPhone et Android physiques.

## Evidence

- captures inspectées : 390×844, 768×1024, 1440×900, français 390 et invitation 390 ;
- CTA principal, accepter et détail : 46 px ; cibles secondaires : au moins 44 px ;
- ancienne iconographie raster absente du DOM et supprimée du projet ;
- serveur `127.0.0.1:3091` redémarré sur la feuille générée courante ;
- aucune nouvelle permission, fréquence de message ou destination externe ;
- direction éditoriale explicitement demandée : dates, couronnes et signes de lecture.
- parité i18n : 200 clés dans chacune des quatre langues, 0 manquante, 0 extra ;
- `zeitwerk:check` : vert.

## Night director

Oui. Le Campus raconte désormais un duel de lecteurs avant même que je lise le mot
« défi », et la date me dit clairement si je dois répondre maintenant.
