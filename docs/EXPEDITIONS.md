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
| expedition-director | Brief, Structure Gate, délégation, contradiction, arbitrage et readiness de l'édito Bibliothèque | Pose PUBLISH READY, jamais SCHEDULED/PUBLISHED |
| expedition-historian | Auteurs possibles, datations, monde, lieux, pratiques | Veto absolu sur la vérité historique |
| expedition-exegete | Texte, poésie, mots, liens, réceptions chrétiennes/LDS | Veto absolu sur la fidélité au texte |
| expedition-showrunner | Trois angles, architecture interne et plan des sept jours de Bibliothèque | Ne possède aucun fait ni parole publique |
| expedition-spiritual-experience-director | Expérience spirituelle, architecture de connaissance et d'enquête des quiz, spécification sémantique et expérience de chaque jour | Veto sur tout pack ou édito exact mais sans expérience, progression de découverte ou pertinence pour l'âme |
| expedition-human-dramaturge | Situations humaines, désirs, relations, gestes, silences et sous-texte avant tout brief d'illustration | Veto absolu sur les métaphores littérales et les images jolies mais émotionnellement génériques |
| expedition-incarnate-writer | Titres, packs, hooks, scripts, éditos en quatre langues et copie finale jouée des quiz | Formule prompts, choix, corrections courtes et CTA lecteur ; oublie le jargon du dossier et conserve ses claim IDs |
| expedition-game-designer | 2–7 packs, ordre, rythme, répétition, progression, récompenses | Met en jeu les questions formatives sans décider seul ce qui mérite d'être appris ni réécrire leur copie finale |
| expedition-art-director | Key art, map, Light/Dark, briefs des packs et sept artworks Bibliothèque responsives | Ne représente pas l'incertain comme fait ; possède le Library Art Gate |
| expedition-film-director | Brief exploitable Kling/Veo plan par plan | Ne monte pas et ne change pas les claims |
| expedition-social-video-editor | Cut 9:16, captions, ruptures, silence, son | Coupe les plans, pas la vérité |
| reel-editor-retention | Simulation du swipe seconde par seconde | Veto absolu sur la publication sociale |
| human-voice-reviewer | Lecture à voix haute et test vocal WhatsApp, dont les quiz et les quatre locales Bibliothèque | Veto absolu sur la voix publique, révision par révision |
| expedition-fact-checker | Contrôle final de chaque transformation, date et représentation, dont la copie jouée des quiz | Veto absolu sur les Truth Gates, sur la même révision que la Human Voice Gate |

Les configurations vivent dans `.codex/agents`.

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
library_editorial.plan             → Showrunner
library_editorial.days[].experience → Directeur d'expérience spirituelle
library_editorial.days[].human_scene → Dramaturge humain
library_editorial.days[].copy        → Auteur incarné
library_editorial.days[].artwork     → Directeur artistique
library_editorial.workflow           → Directeur
experience_design               → Directeur d'expérience spirituelle
human_dramaturgy                → Dramaturge humain
formation_quizzes               → Directeur d'expérience spirituelle, pour le contrat sémantique
formation_quizzes.items[].semantic_handoff → Directeur d'expérience spirituelle
formation_quizzes.items[].formation_goal   → Directeur d'expérience spirituelle
formation_quizzes.items[].soul_relevance   → Directeur d'expérience spirituelle
formation_quizzes.items[].scenario         → Directeur d'expérience spirituelle
formation_quizzes.items[].choices[].diagnosis → Directeur d'expérience spirituelle
formation_quizzes.items[].correct_choice   → Directeur d'expérience spirituelle
formation_quizzes.items[].prompt           → Auteur incarné
formation_quizzes.items[].choices[].text   → Auteur incarné
formation_quizzes.items[].correction       → Auteur incarné
formation_quizzes.items[].reader_cta_label → Auteur incarné
formation_quizzes.copy_revision            → Auteur incarné
formation_quizzes.items[].copy_handoff     → Auteur incarné
formation_quizzes.items[].writer_self_check → Auteur incarné
public_story                    → Auteur incarné
packs                           → Game Designer
packs.items[].formation_question_ids → Game Designer
packs.items[].repetition_schedule    → Game Designer
visual_language                 → Directeur artistique
trailer.directing               → Réalisateur
trailer.edit                    → Social Video Editor
review.truth_gate               → Fact Checker
review.structure_gate           → Directeur, avec Historien + Exégète
review.experience_gate          → Directeur d'expérience spirituelle
review.human_dramaturgy_gate    → Dramaturge humain
review.attention_gate           → Reviewer Rétention
review.human_voice_gate         → Human Voice Reviewer
review.library_editorial.art_gate         → Directeur artistique
review.library_editorial.experience_gate  → Directeur d'expérience spirituelle
review.library_editorial.human_dramaturgy_gate → Dramaturge humain
review.library_editorial.truth_gate       → Fact Checker
review.library_editorial.human_voice_gate → Human Voice Reviewer
~~~

Le chemin le plus précis prévaut sur le propriétaire de sa section parente.
Ainsi, le Directeur d'expérience garde la vérité testée et le sens de chaque
distracteur, tandis que l'Auteur incarné possède les mots effectivement lus
par le joueur. L'ordre d'apparition et la répétition vivent dans `packs`, chez
le Game Designer ; l'ordre physique des entrées de `formation_quizzes.items`
n'est pas une séquence de jeu.

Une correction de claim crée une nouvelle révision ou un lien supersedes.
Elle n'écrase pas silencieusement ce que d'autres agents ont déjà utilisé.

## L'édito hebdomadaire de la Bibliothèque

Chaque run hebdomadaire du Conseil livre désormais un artefact indépendant
`library_editorial`. Il doit contenir exactement sept entrées datées :

- six `discovery`, reliées aux six unités éditoriales de la semaine et, si une
  expédition existe déjà, à ses packs valides ;
- une `contemplation`, qui conclut sans fabriquer une septième leçon ;
- pour chaque jour, une référence, des claim IDs, une expérience, une copie et
  un artwork ;
- toute la copie, les alt texts et les disclosures dans `fr`, `es`, `en` et
  `pt-BR`.

Ce n'est pas « sept images pour un jour ». Il existe un seul édito par date.
Chaque édito possède trois compositions responsives du même monde — portrait,
tablet et landscape — afin de ne pas sacrifier le sujet ou la zone de texte par
un crop automatique.

La responsabilité circule ainsi :

~~~text
SHOWRUNNER
  ↓ plan de 7 dates : 6 découvertes + 1 contemplation
DIRECTEUR D'EXPÉRIENCE SPIRITUELLE
  ↓ vérité à habiter, tension, question, trace du lendemain
DRAMATURGE HUMAIN
  ↓ situation vécue, désir, relation, émotion contradictoire, geste et silence
AUTEUR INCARNÉ
  ↓ copie native fr / es / en / pt-BR
DIRECTEUR ARTISTIQUE
  ↓ 1 monde par jour, 3 compositions responsives
FACT CHECKER + HUMAN VOICE REVIEWER
  ↓ Truth et voix sur la même révision
DIRECTEUR
  ↓ PUBLISH READY, puis arrêt
HUMAIN
  ↓ autorisation explicite de SCHEDULED
~~~

### Où vivent les éditos

Il y a quatre couches volontairement séparées :

1. `config/expeditions/<id>.yml` décrit la source créative : plan des sept
   jours, responsabilités, claims, expériences, scènes humaines, copy, briefs
   d'art et gates.
   Son contrat est documenté par
   `config/expeditions/_showrunner_template.yml` et les agents de
   `.codex/agents`.
2. `config/study/library_daily_editorials/YYYY-MM-DD-<corpus>.yml` est la
   livraison hebdomadaire exécutable : programme, unité d'étude, dates,
   fuseau, payload relu, digest de copy, digest des trois masters par jour,
   gates et autorisation éventuelle. On peut y
   préparer la semaine suivante aussi tôt que nécessaire.
3. `media/masters/media/study/library/daily/` contient les fichiers maîtres. Leur nom suit
   `<reference-biblique>-<slug-editorial>-<portrait|tablet|landscape>-v<revision>.png`,
   par exemple `ps137-suspended-harps-landscape-v1.png`. La référence biblique
   au début du nom est obligatoire. `config/media/responsive.yml` les expose
   avec le rôle `library_daily_hero`.
4. Après publication autorisée, les sept entrées sont copiées dans la version
   immuable du quiz de l'unité d'étude. La base est le stockage runtime ; elle
   ne décide pas quel jour est visible.

Le contrat runtime est porté par `Studies::DailyEditorialSchedule`. Il valide
le fichier hebdomadaire, six découvertes suivies d'une contemplation, les sept
dates, le fuseau, les cinq Library Gates sur la même révision que le dossier,
le digest éditorial, les trois fichiers maîtres distincts et leur SHA-256,
leur unicité globale sur les 21 renditions, et la concordance des deux digests
avec le dossier du Conseil, ainsi que l'autorisation. `Studies::PublishScheduledDailyEditorials`
n'importe que les fichiers explicitement `scheduled`. La présence d'un YAML,
d'un artwork ou même d'un payload `publish_ready` n'est jamais une permission
de publier. Un brouillon peut être incomplet et est ignoré ; un fichier qui se
déclare `publish_ready` doit au contraire passer tout le contrat, sinon le job
échoue bruyamment.

### Comment la date est vérifiée

Chaque fichier déclare :

- `starts_on` et `ends_on`, avec exactement six jours d'écart ;
- un fuseau IANA explicite, par exemple `Europe/Madrid` ;
- `publication.activate_at`, exactement à minuit local de `starts_on` ;
- sept `scheduled_on` consécutifs, dans le même fuseau et dans le même ordre.

Le validateur rejette une date manquante, dupliquée, décalée, un mauvais
fuseau ou un `activate_at` qui n'est pas le minuit local attendu. Une semaine
future peut être importée en base plusieurs jours à l'avance. À l'écran, le
resolver convertit l'heure courante dans le fuseau de l'édito et ne sélectionne
que l'entrée dont `scheduled_on` est exactement cette date civile. Une entrée
future reste invisible même si elle est déjà `published`.
Le fuseau de l'édito prévaut également pour un membre dont la rama utilise un
autre fuseau : la couverture mondiale change selon l'horloge éditoriale
versionnée, jamais selon une identité locale accidentelle.

### Workflow et autorisation

~~~text
PREPARED
  contenu en cours, aucune promesse de publication
    ↓ cinq Library Gates sur une même révision
PUBLISH_READY
  le Conseil a terminé ; le fichier reste non autorisé
    ↓ décision humaine avec authorized_by + authorized_on + activate_at
SCHEDULED
  l'import automatique est permis
    ↓ copie immuable dans la version d'étude, possible avant la semaine
PUBLISHED
  stocké, mais pas encore forcément visible
    ↓ scheduled_on == date locale courante
ACTIVE
  un seul édito du jour est rendu
~~~

La production éditoriale est déclenchée avec la préparation de l'expédition,
pas au premier jour de sa semaine. Le Conseil peut donc préparer une ou
plusieurs semaines futures : chaque run reçoit les dates réelles et le fuseau,
termine les sept jours et leurs gates, puis livre `publish_ready`. Attendre la
date de début ne fait partie d'aucun contrat du Conseil.

Le rappel opérationnel « Préparer l’édito Bibliothèque » est programmé dans
Codex chaque lundi à 22 h. Il réveille le Conseil pour la semaine suivante ;
ce rappel ne publie rien, n'écrit aucune autorisation humaine et doit lui aussi
s'arrêter à `publish_ready`. La cadence du rappel vit dans Codex, tandis que le
contrat, les contenus et leurs dates restent versionnés ici.

Le Conseil doit toujours terminer son run hebdomadaire à `publish_ready` et
s'arrêter là. Il ne remplit jamais lui-même `authorized_by` ou `authorized_on`,
ne déduit jamais une autorisation du brief et ne transforme jamais
automatiquement `publish_ready` en `scheduled`. La programmation humaine et
l'activation par date sont deux garanties différentes.

Dans le fichier de livraison, `PREPARED` correspond à
`publication.state: draft`; `PUBLISH_READY` à
`publication.state: publish_ready`; et seule l'autorisation humaine permet
`publication.state: scheduled`. Le champ `activate_at` peut être préparé à
l'avance : il décrit la date prévue, il n'accorde aucune permission à lui
seul.

En production, `DailyEditorialPublicationCoordinatorJob` contrôle les fichiers
toutes les quinze minutes. Il ignore `draft` et `publish_ready`, puis importe
uniquement `scheduled`. Les commandes manuelles restent explicites :

```bash
bin/rails library_editorials:validate
bin/rails library_editorials:status
bin/rails library_editorials:preflight
bin/rails library_editorials:publish_scheduled
```

`validate`, `status` et `preflight` sont sans publication. `preflight` prouve,
avant l'autorisation humaine, que le programme, la semaine datée et sa quiz de
base publiée existent encore en base et que le périmètre des packs correspond.
`publish_scheduled` respecte la même autorisation et n'est pas un moyen de
contourner le workflow. Un `draft` incomplet est signalé comme tel sans faire
échouer la validation globale; dès qu'il se déclare `publish_ready`, toute
incohérence redevient bloquante.

Les cinq portes propres à l'édito sont indépendantes de celles du trailer ou
des packs :

- **Library Art Gate** : sept artworks, 21 compositions maîtres, noms avec
  références bibliques, manifeste, focus, alt texts et disclosures ;
- **Library Experience Gate** : six découvertes distinctes et une
  contemplation, chacune avec image, tension, question et trace ;
- **Library Human Dramaturgy Gate** : sept scènes vécues et 21 masters lisibles
  par les comportements humains sans titre, sans métaphore littérale ni cliché
  de banque d'images ;
- **Library Truth Gate** : dates, références, claims, traductions, images et
  digest contrôlés sur la révision exacte ;
- **Library Human Voice Gate** : les cinq champs publics des sept jours sont
  réellement lus dans chacune des quatre langues.

Une modification de date, texte, traduction, claim, image, alt text ou
disclosure invalide les gates concernés et produit un nouveau digest avant de
retrouver `publish_ready`.

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
  ↓ expérience locale + enquête de connaissance + spécification sémantique
  ↳ REJECT retourne au Showrunner
DRAMATURGE HUMAIN
  ↓ scène vécue; rejette la métaphore littérale et l'émotion générique
  ↳ REJECT retourne à sa propre scène avant tout brief Art
AUTEUR INCARNÉ
  ↓ titre, hooks et récit humain, sans langage de dossier
GAME DESIGNER + DIRECTEUR ARTISTIQUE (après PASS dramaturgique)
  ↓ ordre, rythme, répétition jouable, packs et monde en parallèle
AUTEUR INCARNÉ
  ↓ prompts, choix, corrections courtes et CTA lecteur dans l'ordre réellement joué
HUMAN VOICE REVIEWER
  ↓ voix du quiz sur la copy_revision finale
FACT CHECKER
  ↓ vérité du quiz sur cette même copy_revision
SHOWRUNNER + EXPÉRIENCE + DRAMATURGE + AUTEUR + ART
  ↓ 7 éditos Bibliothèque datés, 4 locales, 21 compositions maîtres
DIRECTEUR D'EXPÉRIENCE SPIRITUELLE
  ↓ « de quoi le joueur se souviendra-t-il demain ? »
DRAMATURGE HUMAIN
  ↓ « que comprend-on des gestes et relations sans connaître le texte ? »
FACT CHECKER
  ↓ expédition + éditos : OK / FAUX / TROP_CERTAIN / AMBIGU
HUMAN VOICE REVIEWER
  ↓ copie Bibliothèque réellement lue dans les quatre langues
DIRECTEUR
  ↓ édito Bibliothèque PUBLISH READY, jamais auto-programmé
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
  ↓ arbitrage final, puis PUBLISH READY si les cinq gates passent
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
absolus. Le veto dramaturgique sur les concepts visuels l'est aussi. Les vetos
sociaux du Reviewer Rétention et du Human Voice Reviewer le sont également,
indépendamment. Aucun score moyen ne peut les compenser.

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
→ Retour au Directeur d'expérience pour réparer la spécification sémantique.

« Le texte permet-il de nommer ce roi avec certitude ? »
→ UNSAYABLE : connaissance défendable, formulation d'examen.
→ Retour à l'Auteur incarné : « Sait-on qui est ce roi ? »
→ Nouvelle copy_revision ; Human Voice Gate et Truth Gate redeviennent pending.
~~~

## Les cinq portes

### Experience Gate

Le Directeur d'expérience spirituelle travaille unité par unité et refuse tout angle ou pack pour lequel il
comprend l'enseignement mais ne sait pas ce que le joueur vivra. Il exige : une
image ou un son avant l'explication, une tension à habiter, une question née
chez le joueur, un symbole laissé ouvert, un acte mémorable et une trace pour
le lendemain.

Il ne fabrique jamais de cohérence globale. Deux packs peuvent avoir des
tonalités et des mondes opposés. Cohérence éditoriale ne signifie pas narration
continue.

Le premier PASS ouvre le travail de l'Auteur, du Game Designer et du Dramaturge
humain. La DA attend également le Human Dramaturgy Gate. Leurs livrables
repassent ensuite l'Experience Gate. Il ne prescrit jamais l'émotion, ne note
pas la foi et ne transforme pas le traumatisme en mécanique de rétention.

Pour les quiz, le Directeur d'expérience spirituelle possède l'enquête de
connaissance et la spécification sémantique de `formation_quizzes` : objectif
formatif, pertinence pour l'âme, étape de l'enquête, vérité à révéler, sens de
la bonne réponse, intention de chaque distracteur, erreur de lecture visée,
invitation libre et curiosité à laisser ouverte. Il ne possède pas la phrase
finale affichée.

Le Game Designer possède l'ordre réellement joué, le rythme, la difficulté,
les récompenses et la maîtrise espacée. Il déplace les IDs de questions et
planifie leurs reprises ; il ne réécrit ni leur vérité ni leur voix.

L'Auteur incarné reçoit le handoff sémantique et l'ordre de jeu, puis possède
la formulation finale des champs plats consommés par le runtime : `prompt`,
`choices[].text`, `correction` courte et `reader_cta_label`. La correction
révèle assez pour rendre la réponse intelligible, mais renvoie à la liseuse
pour le développement. La frontière produit est absolue :

> **Le quiz provoque la curiosité. La Bibliothèque la satisfait.**

Avant tout handoff de revue, l'Auteur passe trois tests obligatoires :

1. **Question humaine** — est-ce qu'un humain poserait réellement la question
   comme ça ?
2. **Choix en moins de deux secondes** — les réponses se comprennent-elles
   toutes sans relire ni décoder du jargon ?
3. **Curiosité ouverte** — la révélation donne-t-elle envie de découvrir
   quelque chose de plus ?

Un seul `false` renvoie la copie à l'Auteur. Une fois les trois tests passés,
le Human Voice Reviewer contrôle la voix, puis le Fact Checker contrôle la
vérité sur exactement la même `formation_quizzes.copy_revision`. Toute
réécriture de `prompt`, `choices[].text`, `correction` ou `reader_cta_label`,
même minime, incrémente cette révision globale et invalide les deux contrôles.
Aucun PASS de voix ou de vérité d'une révision antérieure ne peut être reporté.

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

### Human Dramaturgy Gate

Le Dramaturge humain transpose la vérité textuelle en situation vécue avant
tout brief visuel. Il exige une relation ou une présence humaine concrète, un
désir encore inassouvi, une émotion contradictoire et un geste, regard, silence
ou écart qui rende le sous-texte compréhensible sans titre.

Il rejette la métaphore littérale — route pour « chemin », porte pour
« entrer », sommet pour « s'élever », rayon providentiel pour « bénédiction » —
ainsi que la première scène générique qu'offrirait une banque d'images. Le
brief passe une première fois; les pixels finaux repassent le même gate. Une
image peut être belle, exacte et techniquement parfaite tout en échouant ici.

Le casting reste beau, charismatique et désirable : présence magnétique,
visages expressifs, style soigné, corps vivants et lumière flatteuse. Cette
désirabilité ne devient ni sexualisation gratuite, ni perfection plastique, ni
casting publicitaire interchangeable; la vulnérabilité précise du personnage
reste visible.

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

Pour la copie du quiz, le Fact Checker contrôle le prompt, chaque choix, la
correction courte et le CTA lecteur de la `copy_revision` ciblée. Son PASS
n'est valide que si la Human Voice Gate porte sur cette même révision.

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

Pour le quiz, il lit également le prompt, chaque choix, la correction courte
et le CTA lecteur. Il ne PASS que la `copy_revision` également ciblée par le
Fact Checker.

Sa sortie reste volontairement pauvre : chaque phrase est seulement `SAYABLE`
ou `UNSAYABLE`. Une ligne rejetée reçoit une seule raison : `écrit mais pas
parlé`, `abstraction`, `trop long`, `jargon`, `explication inutile`, `émotion
fabriquée`, `transition IA`, `question d'exégète`, `choix illisible en deux
secondes`, `réponse administrative` ou `curiosité refermée`. Aucun commentaire
littéraire n'est permis.

Les mots `mouvement`, `strate`, `protagonisme`, `réception`, `arc éditorial`,
`fonction dramatique`, `pertinence durable` et `pluralité des voix` sont
interdits dans la parole joueur. Un rejet retourne à l'Auteur incarné. Le Fact
Checker n'a pas le droit de proposer une reformulation.

Après cette réécriture, Human Voice Gate et Truth Gate repassent toutes deux à
`pending`, y compris lorsque le changement semble seulement stylistique : une
phrase plus naturelle peut aussi déplacer un degré de certitude.

### Publish Ready

Le Directeur pose publish_ready seulement si les cinq gates sont PASS, toutes
les objections bloquantes sont verified et les sorties accessibles sont
présentes.

Pour l'édito Bibliothèque, il existe cinq gates séparées — Art, Experience,
Human Dramaturgy, Truth et Human Voice — et un `publish_ready` propre. Le run
hebdomadaire doit les réparer jusqu'au PASS et livrer l'édito `publish_ready`;
il ne peut jamais s'auto-autoriser à devenir `scheduled`.

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
- scheduled : autorisation humaine enregistrée, import permis ;
- published : payload immuable stocké, possiblement avant sa semaine ;
- active : réservé à l'édito dont la date correspond exactement à aujourd'hui
  dans son fuseau déclaré.
