# Conseil d'expédition

Une expédition Noche Live est conçue par un Conseil de spécialistes. Le
Directeur d'expédition n'est plus un prompt géant qui produit recherche,
théologie, quiz, art et trailer. Il orchestre des propriétaires capables de
se contredire et conserve leurs décisions dans un dossier partagé.

## Règle fondatrice

> Ne cherche jamais comment rendre un chapitre amusant. Cherche d'abord
> pourquoi des êtres humains ont conservé ce texte pendant des millénaires.
> Construis ensuite l'expédition autour de cette raison.

Les références sont la promesse de couverture. L'ordre des packs sert une
progression humaine et peut donc différer de l'ordre des chapitres.

## Le Conseil

| Agent | Responsabilité | Autorité |
| --- | --- | --- |
| expedition-director | Brief, Structure Gate, délégation, contradiction, arbitrage | Pose PUBLISH READY, jamais PUBLISHED |
| expedition-historian | Auteurs possibles, datations, monde, lieux, pratiques | Veto absolu sur la vérité historique |
| expedition-exegete | Texte, poésie, mots, liens, réceptions chrétiennes/LDS | Veto absolu sur la fidélité au texte |
| expedition-showrunner | Trois angles et architecture éditoriale interne | Ne possède aucun fait ni parole publique |
| expedition-spiritual-experience-director | Expérience spirituelle et contenu formatif des quiz | Veto sur tout pack exact mais sans expérience ou pertinence pour l'âme |
| expedition-incarnate-writer | Titres, packs, hooks, scripts et explications dicibles | Oublie le jargon du dossier, conserve ses claim IDs |
| expedition-game-designer | 2–7 packs, rythme, répétition, progression, récompenses | Met en jeu les questions formatives sans décider seul ce qui mérite d'être appris |
| expedition-art-director | Key art, map, Light/Dark, briefs des packs | Ne représente pas l'incertain comme fait |
| expedition-film-director | Brief exploitable Kling/Veo plan par plan | Ne monte pas et ne change pas les claims |
| expedition-social-video-editor | Cut 9:16, captions, ruptures, silence, son | Coupe les plans, pas la vérité |
| reel-editor-retention | Simulation du swipe seconde par seconde | Veto absolu sur la publication sociale |
| human-voice-reviewer | Lecture à voix haute et test vocal WhatsApp | Veto absolu sur la voix publique |
| expedition-fact-checker | Contrôle final de chaque transformation | Veto absolu sur la Truth Gate |

Les configurations vivent dans .cursor/agents.

## Artefact partagé

Copier config/expeditions/_showrunner_template.yml vers
config/expeditions/<id>.yml. Le dossier reste runtime_mode: detached tant
qu'une intégration produit n'a pas été séparément autorisée.

Chaque agent possède une zone :

~~~text
brief, council                  → Directeur
facts.historical               → Historien
facts.exegetical               → Exégète
concepts, editorial_structure   → Showrunner, usage interne
experience_design               → Directeur d'expérience spirituelle
formation_quizzes               → Directeur d'expérience spirituelle
public_story                    → Auteur incarné
packs                           → Game Designer
visual_language                 → Directeur artistique
trailer.directing               → Réalisateur
trailer.edit                    → Social Video Editor
review.truth_gate               → Fact Checker
review.structure_gate           → Directeur, avec Historien + Exégète
review.experience_gate          → Directeur d'expérience spirituelle
review.attention_gate           → Reviewer Rétention
review.human_voice_gate         → Human Voice Reviewer
~~~

Une correction de claim crée une nouvelle révision ou un lien supersedes.
Elle n'écrase pas silencieusement ce que d'autres agents ont déjà utilisé.

## Séquence réelle

~~~text
DIRECTEUR
  ↓ brief figé
HISTORIEN + EXÉGÈTE
  ↓ dossier source parallèle
DIRECTEUR — STRUCTURE GATE
  ↓ arc réel ? OUI / PARTIELLEMENT / NON
  ↓ « NON » est une réponse valide
SHOWRUNNER
  ↓ exactement 3 formes éditoriales compatibles
CONSEIL
  ↓ critiques sans réécriture
DIRECTEUR
  ↓ arbitrage explicite
DIRECTEUR D'EXPÉRIENCE SPIRITUELLE
  ↓ expérience locale + questions qui forment un discernement
  ↳ REJECT retourne au Showrunner
AUTEUR INCARNÉ
  ↓ titre, hooks et récit humain, sans langage de dossier
GAME DESIGNER + DIRECTEUR ARTISTIQUE
  ↓ répétition jouable, packs et monde en parallèle
DIRECTEUR D'EXPÉRIENCE SPIRITUELLE
  ↓ « de quoi le joueur se souviendra-t-il demain ? »
FACT CHECKER
  ↓ OK / FAUX / TROP_CERTAIN / AMBIGU, sans réécriture de style
RÉALISATEUR
  ↓ plans
SOCIAL VIDEO EDITOR
  ↓ montage 9:16
FACT CHECKER
  ↓ contrôle du montage et de la VO
REVIEWER RÉTENTION
  ↓ structure du swipe
HUMAN VOICE REVIEWER
  ↓ lecture à voix haute : « est-ce que Tracy dirait ça ? »
DIRECTEUR
  ↓ arbitrage final, puis PUBLISH READY si les quatre gates passent
HUMAIN
  ↓ autorisation éventuelle de publier
~~~

Le Réalisateur applique avant montage un `CHARACTER GATE` : chaque scène
narrative contient une personne visible qui veut quelque chose, agit et
rencontre une résistance. `Anonyme` signifie non identifié, jamais absent ou
réduit à une silhouette décorative. Les objets bibliques soutiennent les
personnages ; ils ne portent pas seuls le film.

Le montage applique aussi un `NO-CONTEXT AUDIO TEST` : écran noir, une seule
oreillette, auditeur fatigué, aucune culture biblique présupposée. La VO doit
faire comprendre seule qui agit, ce qui lui arrive, pourquoi c'est étrange et
ce que le joueur fera. Un nom inconnu arrive après son contexte et devient une
question, jamais un raccourci de compréhension.

Ce n'est pas une chaîne aveugle. Chaque rejet ouvre une boucle ciblée vers le
propriétaire de la faiblesse.

## Structure Gate

Avant le Showrunner, le Directeur demande : « Ces lectures possèdent-elles
réellement un arc assez fort pour améliorer leur compréhension ? »

- `YES` : l'arc est permis, jamais obligatoire ;
- `PARTIAL` : clusters ou constellation avec quelques échos ;
- `NO` : anthologie, constellation, dossiers ou mini-expéditions.

L'absence d'arc est un résultat parfaitement valide. Le Showrunner demande
ensuite : « Quelle est la meilleure forme éditoriale pour faire vivre ces
lectures cette semaine ? » La réponse peut être `arc`, `constellation`,
`anthology`, `dossiers`, `clusters` ou `mini_expeditions`.

`editorial_structure` remplace tout arc obligatoire :

```yaml
editorial_structure:
  type: constellation
  confidence: high
  reason: "Les lectures ne forment pas un récit unique."
  navigation: free_choice
  units: []
  echoes: []
  forced_connections: []
```

Historien, Exégète et Fact Checker peuvent opposer un veto à une connexion qui
fabrique une même voix, un même événement, une causalité ou un ordre historique
non soutenu.

## Objections et vetos

Une objection contient :

- l'agent qui l'ouvre ;
- la gate concernée ;
- le chemin et la révision visés ;
- les claim IDs ;
- la raison observable ;
- la réparation exigée ;
- le propriétaire chargé de la correction ;
- l'état open, repaired, verified ou waived.

Seul un avis ADVISORY peut être écarté avec une justification du Directeur.
Les vetos de vérité de l'Historien, de l'Exégète et du Fact Checker sont
absolus. Les vetos sociaux du Reviewer Rétention et du Human Voice Reviewer le
sont également, indépendamment. Aucun score moyen ne peut les compenser.

Exemple :

~~~text
« David écrit le Psaume 102 après la mort d'Absalom. »
→ VETO Historien : auteur et scène non établis.
→ Retour au Showrunner.
→ « Une voix anonyme voit ses jours partir en fumée. »
→ Nouvelle révision, puis nouvelle vérification.
~~~

Même protocole pour une question :

~~~text
« Qui a écrit le Psaume 102 ? David / Salomon / Moïse »
→ VETO : réponse non défendable.
→ Retour au Game Designer.
~~~

## Les quatre portes

### Experience Gate

Le Directeur d'expérience spirituelle travaille unité par unité et refuse tout angle ou pack pour lequel il
comprend l'enseignement mais ne sait pas ce que le joueur vivra. Il exige : une
image ou un son avant l'explication, une tension à habiter, une question née
chez le joueur, un symbole laissé ouvert, un acte mémorable et une trace pour
le lendemain.

Il ne fabrique jamais de cohérence globale. Deux packs peuvent avoir des
tonalités et des mondes opposés. Cohérence éditoriale ne signifie pas narration
continue.

Le premier PASS ouvre le travail de l'Auteur, du Game Designer et de la DA.
Leurs livrables repassent ensuite ce gate. Il ne prescrit jamais l'émotion, ne
note pas la foi et ne transforme pas le traumatisme en mécanique de rétention.

Pour les quiz, le Directeur d'expérience spirituelle possède
`formation_quizzes` : objectif formatif, pertinence pour l'âme, scénario,
choix, erreur de lecture visée, correction, invitation libre et variante de
répétition. Le Game Designer possède le rythme, l'ordre, la difficulté, les
récompenses et la maîtrise espacée.

Il planifie aussi neuf lentilles d'apprentissage : récit du texte, personnages,
monde historique, lecture du texte, principes de l'Évangile, plan de Dieu,
espérance éternelle, réception canonique et discernement de vie. Une lentille
n'est pas obligatoire dans chaque pack. À l'échelle de la semaine, elle doit
être marquée `covered`, `planned`, `not_supported` ou `pending_claims`. L'histoire et la
vie des personnages ont leur place lorsqu'elles rendent une action, une
promesse, un principe ou le plan de Dieu plus intelligibles ; elles ne sont pas
réduites à des pièges de mémoire.

Le `FORMATION RELEVANCE TEST` rejette toute question dont la bonne réponse est
seulement un nombre, un nom, une date ou une structure oubliable. Un détail
comme `22 strophes × 8 vers` peut renforcer une révélation ; il ne devient pas
un objectif d'apprentissage si le discernement véritable est qu'une vie très
ordonnée a encore besoin d'être cherchée par Dieu.

Le modèle « code de la route » est : situation → choix → correction immédiate
→ même discernement dans un autre contexte → maîtrise visible. Le jeu note la
compréhension du texte et son transfert, jamais foi, sainteté, émotion,
confession, prière, repentance ou salut.

### Mobile Copy Gate

La copie est écrite pour la feuille Street réelle sur l'écran court de
référence `390 × 667`, avec quatre réponses possibles :

- question autonome : 72 graphèmes maximum et 3 lignes ;
- chaque réponse : 32 graphèmes maximum et 2 lignes ;
- correction immédiate : 120 graphèmes maximum ;
- quatre réponses maximum.

Espaces et ponctuation comptent. Chaque traduction est mesurée et rendue
séparément. Un dépassement donne `REJECT_COPY_OVERFLOW`; le système réécrit le
texte au lieu de réduire la police, tronquer, ajouter une ellipse ou faire
défiler la liste des réponses. Le scénario peut guider l'auteur en interne,
mais la question affichée doit contenir seule tout ce qui est nécessaire pour
choisir.

Contrôle automatique d'un dossier :

```bash
ruby script/validate_expedition_quiz_copy.rb config/expeditions/mon-dossier.yml
```

### Truth Gate

Elle exige simultanément :

- historique PASS ;
- exégèse PASS ;
- canon/fact checking PASS ;
- couverture complète des lectures ;
- aucun veto de vérité ouvert.

Il n'existe pas de note moyenne.

### Attention Gate

Le Reviewer joue le montage à 0–2, 2–5, 5–10, 10–20, 20–30 secondes et à la
fin. Stop power, curiosité, escalade, nouveauté, payoff et désir d'ouvrir
doivent tous obtenir au moins 8,5/10. Une seule fenêtre faible donne REJECT.

Le rejet repart :

- au Monteur si le rythme ou l'ordre échoue ;
- au Réalisateur si les plans ne portent pas l'intrigue ;
- au Showrunner si l'angle lui-même ne crée aucune question.

Cette gate juge la structure. Elle ne certifie jamais qu'un humain parlerait
ainsi.

### Human Voice Gate

Le Reviewer lit réellement la copie publique à voix haute. Il rejette toute
phrase qui exige de ralentir, contient deux abstractions, sonne dissertation,
n'évoque aucune image, explique l'image ou ne pourrait pas être envoyée en
vocal WhatsApp à un ami.

Sa sortie reste volontairement pauvre : chaque phrase est seulement `SAYABLE`
ou `UNSAYABLE`. Une ligne rejetée reçoit une seule raison : `écrit mais pas
parlé`, `abstraction`, `trop long`, `jargon`, `explication inutile`, `émotion
fabriquée` ou `transition IA`. Aucun commentaire littéraire n'est permis.

Les mots `mouvement`, `strate`, `protagonisme`, `réception`, `arc éditorial`,
`fonction dramatique`, `pertinence durable` et `pluralité des voix` sont
interdits dans la parole joueur. Un rejet retourne à l'Auteur incarné. Le Fact
Checker n'a pas le droit de proposer une reformulation.

### Publish Ready

Le Directeur pose publish_ready seulement si les quatre gates sont PASS, toutes
les objections bloquantes sont verified et les sorties accessibles sont
présentes.

Publish Ready n'autorise pas la publication. Rendu externe, voix, musique,
upload, notification, mutation produit et données joueur restent soumis au
brief et à l'autorisation humaine.

## Production éditoriale

- Chaque claim porte un propriétaire, une certitude ATTESTÉ, PROBABLE,
  TRADITION ou INCERTAIN, ses sources et ses limites.
- Toute question, réponse, légende, image ou VO pointe vers des claim IDs.
- La fidélité factuelle est sémantique, pas mot à mot. Une paraphrase parlée
  est permise ; seul un texte présenté comme citation directe exige le
  verbatim d'une traduction vérifiée.
- La fidélité n'impose aucune neutralité documentaire. La vidéo doit séduire :
  performance anonyme, météo, lumière, geste, espace symbolique, caméra, son,
  silence et montage peuvent dramatiser le texte. La mention « Illustration
  dramatisée » empêche seulement de confondre cette mise en scène avec une
  reconstitution historique certaine.
- Historien et Exégète sont garde-fous et mine d'or ; leur langage ne devient
  jamais automatiquement le langage du public.
- Le Showrunner trouve l'angle. L'Auteur incarné le raconte comme une personne,
  sans résumer le dossier.
- Les questions appartiennent à TEXTE, CONTEXTE, PERSONNAGES, LIEUX,
  ÉVÉNEMENTS ou MYSTÈRE et doivent apprendre quelque chose après l'erreur.
- Les illustrations inconnues restent anonymes et symboliques avec la mention
  Illustration dramatisée · route d'étude.
- Le trailer montre les intrigues et une preuve de jeu ; il ne commence ni par
  la liste des chapitres, ni par le logo.
- Toute phrase informative qui ne produit ni image mentale, ni tension, ni
  surprise, ni émotion doit justifier sa présence.
- Les passages sensibles offrent avertissement, voie calme et progression
  sans sanction.
- Sous-titres, transcript et version mouvement réduit sont obligatoires.

## Statuts honnêtes

- production_package : script, prompts et shot list uniquement ;
- animatic_preview : prévisualisation locale, pas film final ;
- rendered_draft : rendu réellement reçu, encore soumis aux gates ;
- publish_ready : gates franchies, publication non autorisée ;
- published : réservé à une action humaine ou explicitement autorisée.
