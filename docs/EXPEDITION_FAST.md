# Conseil d'expédition FAST

Le Conseil d'expédition FAST est le workflow canonique de création d'une
expédition Noche Live. Il est destiné à remplacer entièrement l'ancien Conseil
d'expédition, pas à préparer une entrée pour celui-ci.

Lorsqu'un programme couvre plusieurs chapitres ou passages, un Responsable du
travail missionnaire ouvre le Conseil et soumet un à trois parcours à l'humain avant
toute écriture de quiz. Le noyau éditorial commence ensuite par cinq relais
strictement séquentiels. Trois relais visuels séparent le choix de la scène de
sa production :

1. `expedition-fast-responsable-missionnaire`
2. `expedition-fast-influenceur`
3. `expedition-fast-mystique`
4. `expedition-fast-nouveau-baptise`
5. `expedition-fast-quiz`
6. `expedition-fast-voix`
7. `expedition-fast-directeur-mise-en-scene`
8. `expedition-fast-directeur-artistique-producteur`
9. `expedition-fast-critique-deux-secondes`
10. `expedition-fast-localisateur-voix`

Cette séquence est le début du Conseil FAST, pas sa limite définitive. Les rôles
de recherche, de vérité et de validation seront ajoutés directement à cette
même chaîne et au même YAML. Il n'existe aucune promotion vers l'ancien Conseil
d'expédition.

## Contrat d'exécution — obligatoire

- Le Responsable missionnaire est propriétaire du démarrage d'un programme
  multi-source et de sa porte de sélection humaine. Après approbation, il lance
  l'Influenceur, qui demeure propriétaire de l'assemblage du noyau éditorial.
- Chaque agent appelle uniquement le relais suivant, lui transmet le texte
  original, la référence, la langue et toutes les réponses déjà produites, puis
  **attend sa réponse complète**.
- Aucun agent ne termine avec une simple annonce telle que « transmis à l'étape
  suivante ». Il ne termine qu'après le retour complet de son successeur.
- Chaque agent joint le résultat de son successeur sans le résumer ni supprimer
  de questions. L'Influenceur rend donc les cinq sections assemblées.
- Si un relais ne peut pas être lancé ou attendu, l'agent rend `FAST BLOQUÉ`,
  nomme l'étape manquante et n'affirme jamais que le Conseil est terminé.
- Une expédition de plusieurs packs possède un manifeste canonique dans
  `config/expeditions/<id>-fast.yml`. Ce manifeste contient le corpus, le choix
  missionnaire, l'ordre des packs et le chemin de leurs fichiers ; il ne contient
  jamais les productions internes des agents de pack.
- Chaque pack possède son propre YAML dans
  `config/expeditions/<id>-fast/packs/<pack-id>.yml`. Tous les agents d'un pack
  écrivent dans ce seul fichier, chacun dans sa zone. Une réponse de chat seule
  n'est jamais un résultat FAST terminé.
- Les productions des agents sont une mémoire append-only : un agent ne résume,
  ne réécrit et ne supprime jamais la production d'un agent précédent.

## Contrat de source

L'entrée minimale est : la référence du passage, son texte ou une source
consultable, et la langue de sortie. Chaque agent distingue explicitement :

- ce que dit le texte ;
- l'interprétation ou la réception religieuse mobilisée ;
- l'application proposée pour la vie.

Une citation n'est jamais inventée. Une application n'est jamais présentée
comme une phrase littérale du passage. Les promesses ne deviennent ni un
diagnostic sur autrui, ni une garantie automatique de santé, de richesse ou de
protection.

## Manifeste d'expédition et YAML de pack

Avant l'étape 1, le Responsable missionnaire copie la structure de
`config/expeditions/_fast_expedition_template.yml` vers
`config/expeditions/<id>-fast.yml`. Il initialise `brief`, `source`,
`fast.status` et `council.current_stage`.

Après l'approbation du parcours, il crée exactement un fichier par pack depuis
`config/expeditions/_fast_template.yml`. Le manifeste les référence dans sa
liste racine `packs` avec leur id, leur titre, leurs références autorisées, leur
chemin et leur statut. Chaque YAML de pack conserve dans `parent_expedition` le
chemin du manifeste, sa révision d'approbation, l'architecture, l'id du pack et
les références autorisées. L'Influenceur contrôle cette filiation avant d'écrire.

Dans le manifeste, les propriétaires sont stricts :

~~~text
brief, source, council, packs                  → expedition-fast-responsable-missionnaire
fast.agent_memory.responsable_missionnaire    → expedition-fast-responsable-missionnaire
fast.result.missionary_source_map             → expedition-fast-responsable-missionnaire
fast.result.missionary_architectures          → expedition-fast-responsable-missionnaire
fast.result.approved_source_scope             → expedition-fast-responsable-missionnaire
fast.source_scope_approval                    → human
~~~

Dans chaque fichier de pack, les propriétaires sont stricts :

~~~text
brief, source, council, parent_expedition      → expedition-fast-influenceur
fast.agent_memory.influenceur                 → expedition-fast-influenceur
fast.result.influenceur                       → expedition-fast-influenceur
fast.agent_memory.mystique                    → expedition-fast-mystique
fast.result.mystique                          → expedition-fast-mystique
fast.agent_memory.nouveau_baptise             → expedition-fast-nouveau-baptise
fast.result.nouveau_baptise                   → expedition-fast-nouveau-baptise
fast.agent_memory.quiz                        → expedition-fast-quiz
fast.result.quiz                              → expedition-fast-quiz
fast.agent_memory.voix                        → expedition-fast-voix
fast.result.voix                              → expedition-fast-voix
fast.result.quiz_final                        → expedition-fast-voix
fast.agent_memory.mise_en_scene_visuelle      → expedition-fast-directeur-mise-en-scene
fast.result.visual_staging                    → expedition-fast-directeur-mise-en-scene
fast.agent_memory.direction_artistique        → expedition-fast-directeur-artistique-producteur
fast.result.visual_production                 → expedition-fast-directeur-artistique-producteur
fast.agent_memory.critique_deux_secondes      → expedition-fast-critique-deux-secondes
fast.result.visual_proof_review               → expedition-fast-critique-deux-secondes
fast.agent_memory.localisateur_voix           → expedition-fast-localisateur-voix
fast.result.translations                      → expedition-fast-localisateur-voix
fast.visual_proof_approval                    → human
fast.human_quiz_revision                      → human
fast.result.revision_pipeline.quiz            → expedition-fast-quiz
fast.result.revision_pipeline.voix            → expedition-fast-voix
fast.result.revision_pipeline.mise_en_scene_visuelle → expedition-fast-directeur-mise-en-scene
fast.french_quiz_approval                     → human
fast.translation_gate                        → human
fast.translation_approval                    → human
fast.quiz_copy_limits                         → human
~~~

Chaque entrée de `fast.agent_memory` conserve au minimum l'agent, la révision,
le statut et sa production intégrale dans un bloc YAML `production: |-`. Cette
mémoire brute reste présente même si `fast.result` contient une projection plus
structurée pour la suite du produit.

Après chaque écriture dans un fichier de pack, l'agent :

1. relit le YAML depuis le disque ;
2. vérifie que les productions précédentes sont toujours présentes à l'identique ;
3. met à jour `council.current_stage` et ajoute une entrée à
   `council.revision_log` ;
4. transmet le chemin exact du YAML de pack au relais suivant.

Un agent de pack ne modifie jamais le manifeste d'expédition. Le Responsable
missionnaire relit les fichiers séparément et met à jour leurs statuts dans le
manifeste. Une production absente d'un fichier de pack ne peut pas être
compensée par une production placée dans le manifeste.

Dans la version actuelle, un programme multi-source s'arrête d'abord à
`source_scope_approval`. Aucun relais éditorial ne démarre avant le choix ou
l'amendement humain des textes et de leur répartition. Après cette décision, le
Responsable missionnaire matérialise exactement le périmètre approuvé et appelle
l'Influenceur. Le Quiz termine ensuite son brouillon structuré puis appelle
le relais Voix. Seul le relais Voix peut poser `fast.status:
editorial_complete` et `council.current_stage: mise_en_scene_visuelle`, après les
contrôles UI et oraux décrits ci-dessous. Le Directeur de mise en scène est
ensuite invoqué sur ce noyau éditorial complet. Il clôt son travail à
`direction_artistique` et appelle le Producteur. Celui-ci réalise une preuve
unique avec son aperçu de surface, puis appelle le Critique des deux secondes.
Le premier gate humain arrive ensuite à `visual_proof_approval`, devant l'image
et le rapport du Critique. Son approbation ne vaut pas autorisation de lot.
Après autorisation explicite du lot Quiz, le Producteur réalise les visuels et
les aperçus français complets. Le second gate humain,
`french_quiz_approval`, précède absolument toute traduction. Si une écriture ou
une validation échoue, le statut devient `blocked` et le Conseil rend `FAST
BLOQUÉ` sans prétendre avoir terminé.

Lorsque les dix unités françaises sont approuvées et que
`fast.translation_gate.translation_authorized` vaut `true`, le
Localisateur-Voix produit séparément l'espagnol, l'anglais et le portugais
brésilien. Chaque langue repasse la voix de plateau, les limites de copie et la
surface Street réelle. Le relais s'arrête ensuite à `translation_approval` :
aucune réussite technique ne remplace la validation humaine multilingue.

### Boucle canonique d'amendement humain

L'humain ne corrige jamais simultanément le brouillon agent et la copie finale.
Il édite une seule source, `fast.human_quiz_revision.questions`, qui contient un
instantané complet des dix questions françaises. Il incrémente `revision`,
déclare les IDs modifiés et ceux dont la référence a changé, puis pose `status:
submitted`.

Cet instantané n'est jamais interprété comme un patch. Quiz doit recopier et
contrôler les dix entrées, même si `changed_question_ids` n'en contient qu'une.
Cette liste pilote seulement l'audit et les invalidations. Une ancienne version
Quiz ne peut survivre que si elle est identique à l'instantané humain ; toute
autre différence exige une correction factuelle ou structurelle explicitement
consignée.

Cette révision devient une entrée obligatoire, jamais une suggestion que les
agents peuvent perdre. Le Quiz contrôle texte source, référence, type, format,
choix juste et distracteurs. Il conserve l'intention humaine, consigne chaque
correction factuelle ou structurelle dans `agent_findings`, puis reconstruit
`fast.result.quiz`. Voix exige d'avoir traité exactement la même révision,
consigne chaque avant/après, reconstruit `fast.result.quiz_final` et refait voix,
limites et rendu Street. Mise en scène ne recalcule que les IDs modifiés et
préserve les autres concepts.

Chaque relais inscrit la révision traitée dans sa propre zone de
`fast.result.revision_pipeline`. La boucle reste bloquée si un relais manque, si
deux révisions diffèrent ou si une référence modifiée n'a pas été relue. Une
modification invalide l'approbation française de la question ; un changement de
référence ou de sens invalide aussi son concept, son éventuel asset et son
aperçu. Les traductions de la question restent invalides jusqu'au nouveau gate
français complet.

## 1 — Responsable du travail missionnaire

> Comment ces Écritures peuvent-elles aider une personne à rencontrer le
> Christ, revenir vers Dieu et persévérer dans son alliance ?

Ce relais intervient avant toute rédaction lorsqu'un programme couvre plusieurs
psaumes, chapitres ou passages. Il ne traite jamais les personnes comme des
segments marketing. Il porte particulièrement ceux qui se préparent peut-être
au baptême, ceux qui s'intéressent à revenir après une longue absence, ceux qui
traversent une épreuve et ceux qui cherchent à renouveler leur foi.

Son travail participe à l'annonce de l'Évangile de Jésus-Christ : la bonne
nouvelle du Royaume de Dieu, le plan de salut offert à chacun, la possibilité de
traverser les épreuves avec Dieu, de croître pendant la vie terrestre et de
persévérer en vue de la vie éternelle. Il ne plaque pas ces vérités sur chaque
verset : il distingue le texte, ses éclairages scripturaires, la réception de
l'Église et l'application missionnaire proposée.

Il lit tout le corpus, cartographie chaque contribution distincte, puis propose
entre une et trois architectures de packs formant des progressions spirituelles
réellement différentes. Il ne fabrique jamais une variante pour atteindre un
quota et explique pourquoi une, deux ou trois propositions sont justifiées.
Pour chaque pack, il établit les références exactes, la
découverte évangélique, la question humaine, l'obstacle à la foi, le prochain
pas rendu imaginable, le rôle dans le parcours et la capacité à soutenir le
nombre de questions demandé sans répétition.

Le quiz est envisagé comme une rencontre, jamais comme un examen de dignité ou
un instrument de pression. La peur, la culpabilité fabriquée, les promesses
automatiques et la confusion entre score de jeu et progression spirituelle sont
rejetées. Le repentir, la réparation, le sacrifice du cœur et la persévérance ne
sont pas effacés : ils sont présentés comme un chemin libre qui vaut la peine.

Il conserve sa production dans
`fast.agent_memory.responsable_missionnaire`, sa cartographie dans
`fast.result.missionary_source_map` et ses trois propositions dans
`fast.result.missionary_architectures`. Il ouvre ensuite
`fast.source_scope_approval`, pose
`council.current_stage: source_scope_approval` et s'arrête. L'humain choisit,
combine ou amende les sources et la vocation des packs.

Après `fast.source_scope_approval.status: approved`, il matérialise fidèlement
`fast.result.approved_source_scope`, crée et référence un YAML autonome pour
chacun des packs, puis appelle `expedition-fast-influenceur` séparément avec
chaque chemin de pack et attend son retour complet. Une décision ambiguë donne
`BLOCKED_AMBIGUOUS_SOURCE_APPROVAL`. Une source introuvable donne
`BLOCKED_MISSING_SOURCE_CORPUS`.

## 2 — Influenceur TikTok

> Comment un influenceur TikTok parlerait-il de ce texte ?

Produit :

- une accroche de premier écran ;
- un angle humain unique ;
- un script oral de 35 à 45 secondes ;
- une question finale qui ouvre la conversation ;
- trois risques de simplification à transmettre au Mystique.

Il écrit sa production dans le YAML, appelle ensuite
`expedition-fast-mystique` avec le chemin du fichier et attend sa réponse
complète.

## 3 — Fonction mystique

> Quelle est la fonction mystique de ce texte ?

Produit :

- une phrase-thèse ;
- le mouvement intérieur du texte en deux à quatre passages ;
- une pratique spirituelle concrète ;
- les limites qui empêchent de spiritualiser la souffrance ou de trahir le
  texte.

Il écrit sa production dans le YAML, appelle ensuite
`expedition-fast-nouveau-baptise` avec le chemin du fichier et attend sa réponse
complète.

## 4 — Nouveau baptisé

> Qu'est-ce qu'un nouveau baptisé peut trouver dans ce texte pour son chemin de
> vie ?

Produit :

- ce qui peut être reçu comme une bonne nouvelle ;
- ce qui risque d'être mal compris ou vécu comme un test d'appartenance ;
- un premier pas réaliste, sans honte ni performance ;
- une question qu'un nouveau baptisé pourrait encore poser.

Il écrit sa production dans le YAML, appelle ensuite `expedition-fast-quiz`
avec le chemin du fichier et attend sa réponse complète.

## 5 — Quiz

> Propose un quiz de 10 questions qui fait un mix de questions sur les paroles
> du texte et les enseignements pour ma vie.

Le quiz contient exactement dix questions et mêle des questions sur les paroles
ou la structure du texte avec des questions de discernement dans la vie. Leur
proportion découle du contenu retenu et n'obéit à aucun quota numérique. Le quiz
mêle aussi des `qcm` et plusieurs `vrai_faux`, sans quota numérique fixe entre
ces deux formats. Un
vrai/faux est utilisé lorsqu'une affirmation peut être jugée honnêtement sans
réserve cachée ; une proposition qui exige une nuance devient un QCM.

Chaque question contient obligatoirement :

- le type `texte` ou `vie` ;
- le format `qcm` ou `vrai_faux` ;
- une référence de verset ou la mention `application` ;
- une question courte ;
- quatre choix plausibles et distincts pour un `qcm`, ou exactement deux choix
  `Vrai` et `Faux` pour un `vrai_faux` ;
- une seule bonne réponse ;
- un retour qui explique sans humilier et distingue texte, interprétation et
  application.

Les mauvaises réponses ne caricaturent ni une confession, ni une personne
malade, dépendante, pauvre ou nouvellement baptisée.

Le Quiz conserve sa production intégrale dans `fast.agent_memory.quiz`, écrit
les comptes de formats dans `fast.result.quiz.format_mix` et les dix questions
structurées dans `fast.result.quiz.questions`, valide le YAML, appelle
`expedition-fast-voix` avec le chemin exact du fichier et attend sa réponse
complète.

## 6 — Auteur de plateau

> Comment un présentateur de jeu télévisé poserait-il cette question et
> révélerait-il sa réponse à des joueurs réunis devant lui ?

Ce relais transforme l'architecture sémantique du Quiz en paroles de jeu
télévisé familial, chaleureuses et spirituelles. Il relit le texte source et les
productions de l'Influenceur, du Mystique et du Nouveau baptisé afin d'écrire à
partir de la tension humaine et de la vérité déjà établies. Il écrit d'abord
pour l'oreille, puis ajuste pour l'écran.

Pour chaque question, il produit :

- `prompt`, la phrase lancée par le présentateur ;
- `choices[].text`, des réponses brèves et parallèles ;
- `feedback`, la révélation formulée après le verdict.

Le verdict juste ou faux est déjà exprimé par l'interface. Le même `feedback`
fonctionne donc après une réponse juste comme après une réponse fausse : il dit
directement ce qu'il faut retenir, sans félicitation ni reproche conditionnel.
La copie publique ne décrit jamais le travail du Conseil, une catégorie de
question ou une méthode d'interprétation. Les distinctions entre texte,
réception et application restent portées par le sens et les métadonnées, pas par
du vocabulaire éditorial prononcé au joueur.

L'Auteur de plateau conserve à l'identique `id`, `type`, `format`, `reference`,
les identifiants et la signification des choix, `correct_choice`, le fait testé
et les limites pastorales. Un `qcm` conserve quatre choix ; un `vrai_faux`
conserve deux choix, `Vrai` et `Faux`. Aucune affirmation absente du dossier
n'est ajoutée. Si une formulation orale ne peut pas préserver ces invariants,
le relais ouvre une objection et pose `FAST BLOQUÉ`.

Chaque séquence complète — prompt, choix, feedback — est réellement lue à voix
haute. Un humain doit pouvoir la dire devant une famille sans syntaxe de
dissertation, jargon ni souffle artificiellement long, et chaque choix doit se
comprendre en moins de deux secondes.

Le Mobile Copy Gate est appliqué ensuite sur la feuille Street de référence
`390 × 667` : prompt autonome de 72 graphèmes et 3 lignes maximum, chaque choix
de 32 graphèmes et 2 lignes maximum, feedback de 120 graphèmes maximum et quatre
choix maximum. L'unité est le graphème Unicode, espaces et ponctuation compris ;
chaque langue passe séparément. Tout dépassement donne
`REJECT_COPY_OVERFLOW` et impose une réécriture, jamais une réduction de police,
une troncature, une ellipse ou un défilement des réponses.

Le comptage ne remplace pas le rendu réel. Sans inspection de la feuille Street,
le statut UI reste `unverified`. L'Auteur de plateau conserve sa production
intégrale dans `fast.agent_memory.voix`, son audit dans `fast.result.voix` et la
copie publique dans `fast.result.quiz_final.questions`. Le brouillon sémantique
reste dans `fast.result.quiz.questions`. Les deux mix — `texte` / `vie` et
`qcm` / `vrai_faux` — ainsi que les bonnes réponses restent inchangés.

## 7 — Directeur de mise en scène visuelle

> Quelle image belle, intrigante et immédiatement lisible peut arrêter le
> pouce en deux secondes et donner envie de contempler le sujet ?

Ce premier relais visuel décide ce qui mérite d'être montré. Il ne produit ni
image, ni prompt de génération, ni direction photographique finale. Pour chaque
unité dont le sujet éditorial existe, il livre un seul concept visuel concis,
limité à 160 mots hors identifiants et base documentaire.

Le prompt du Quiz n'est jamais traité comme une source suffisante. Avant de
mettre une unité en scène, le Directeur relève sa référence, consulte le texte
exact via `source.readings`, extrait les versets nécessaires et enregistre la
référence une seule fois dans `visual_staging.source_library`. Les concepts
réutilisent ensuite son ID, sans recopier le passage. Une question
`reference: application` doit être reliée au passage et au discernement qui la
soutiennent. Une source inaccessible ou ambiguë donne
`BLOCKED_MISSING_SOURCE`; une surface sans sujet éditorial donne
`BLOCKED_MISSING_CONTENT`.

Le concept choisit `iconic_symbol`, `human_dramaturgy`,
`historical_cinematic` ou `environmental_world`. Les champs de désir, résistance,
relation et casting ne sont obligatoires que lorsque des personnes portent
l'image. Aucun mode ne possède de priorité morale.

Chaque concept doit fonctionner sans titre ni référence. Une image classique qui
parle à tous reste recevable : porte pour un passage, chemins pour un choix,
chaînes pour une libération ou rayon pour une bénédiction. Aucun motif n'est
interdit par principe. Le Directeur formule cette image attendue, tente une
alternative dramaturgique lorsqu'une situation défendable existe, puis compare
lecture en deux secondes, arrêt du scroll, force émotionnelle, fidélité et désir
de contempler. Il garde la meilleure approche, même si elle est conventionnelle.

Le sacrifice de cœur est traité comme désir véritable, possibilité réelle,
loi ou alliance, renoncement libre, coût intérieur et confiance en Dieu. Ce qui
est abandonné reste désirable et la personne reste active, belle et digne. La
bénédiction espérée n'est jamais représentée comme une transaction garantie.
Un cœur, un autel ou une flamme peuvent être retenus si leur composition gagne
la comparaison avec une situation humaine.

Les personnages sont magnétiques, vivants et vulnérables sans misérabilisme;
leurs costumes, coiffures, matières et accessoires sont riches, précis et
adaptés à la situation. La profondeur spirituelle ne se traduit pas par défaut
en fatigue, saleté, pauvreté, obscurité ou visage abattu. Les scènes historiques
saisissent un instant cinématographique en cours, jamais des figurants posant
pour expliquer un verset. La diversité des âges, apparences, corps, relations,
mondes, lieux, moments du jour et émotions se construit à l'échelle du lot.

Chaque concept choisit également son traitement : `cinematic_realism`, rendu
réaliste comme un photogramme de cinéma, ou `biblical_illustration`, illustration
biblique picturale assumée. Ni l'époque ni la surface ne décident
automatiquement. Le choix revient au traitement qui rend la scène la plus
immédiate, belle, intrigante et fidèle; la matrice d'expédition justifie toute
exception à son traitement dominant.

Le relais écrit sa mémoire dans
`fast.agent_memory.mise_en_scene_visuelle`, sa bibliothèque de sources, ses
concepts et sa matrice de rythme dans `fast.result.visual_staging`, conserve
`generation_authorized: false`, puis
pose `council.current_stage: direction_artistique`. Il ne génère aucune image
lui-même, mais appelle le Producteur et attend son retour complet. Le contrat
humain autorise exactement une preuve avant validation, jamais le lot complet.

## 8 — Directeur artistique-producteur

> Comment transformer un concept mis en scène en une preuve Noche Live forte sans
> lancer une production coûteuse avant validation ?

Ce relais agit dès que la mise en scène est `ready_for_proof`. Il sélectionne le
concept et le ratio qui prouvent le mieux le langage du pack. Son premier
passage est toujours `proof_only` : un
concept, un ratio, un prompt et exactement un appel de génération. Il ne crée
ni variantes, ni upscale, ni autres formats. Il inspecte la preuve, enregistre
le prompt, l'outil, le chemin réel et le nombre d'appels, puis crée un aperçu
non destructif dans la surface cible avec son chrome, son texte et sa zone sûre.
Il pose `critique_deux_secondes`, appelle le Critique et attend son rapport
complet. Un échec n'entraîne jamais une nouvelle génération automatique.

Le prompt de production reste court et concret : sujet, action ou état visible,
tension, lieu et époque, composition et caméra, casting et costumes, matières,
lumière, ratio, zone sûre de copie et au plus trois erreurs à éviter. Il respecte
le mode, le traitement, le casting, le sacrifice de cœur et les risques du
concept approuvé. `cinematic_realism` reste un photogramme crédible ;
`biblical_illustration` reste une illustration picturale biblique assumée. Le
Hero title Rama demeure du HTML et aucun titre n'est incrusté dans l'artwork.

La direction artistique vise une qualité de jeu mobile AAA : lecture immédiate,
personnes belles et magnétiques, expressions précises, costumes et matières
riches, monde habité, profondeur et lumière cinématographiques. La tristesse,
la fatigue, la saleté ou l'obscurité ne remplacent jamais le sens de la scène.

Lorsque le sujet s'y prête, les temples de l'Église de Jésus-Christ des Saints
des Derniers Jours peuvent inspirer l'ordre sacré, la maîtrise, les matériaux,
la lumière, l'accueil et la beauté construite. Le temple de Salt Lake City, ses
jardins splendides et ses intérieurs publiquement documentés par l'Église sont
des références privilégiées, mais jamais automatiques. Le relais peut en
transposer les principes sans placer un temple contemporain dans une scène
biblique ni en faire une preuve doctrinale.

Toute architecture, inscription ou intérieur identifiable repose uniquement
sur des médias publics officiels de l'Église, consignés dans le manifeste. Le
relais n'invente aucun rite, ordonnance, pièce inaccessible ou détail sacré non
publié. Chaque manifeste indique si cette référence a été employée, sa nature,
ses sources officielles, les principes empruntés et l'absence de prétention à
une réplique exacte.

Le relais conserve son compte rendu intégral dans
`fast.agent_memory.direction_artistique` et ses preuves, appels et manifestes
dans `fast.result.visual_production`. Il ne produit un lot qu'après une nouvelle
autorisation humaine nommant les scènes et ratios approuvés. Il ne relie rien au
runtime et ne publie rien.

## 9 — Critique des deux secondes

> Que voit, ressent et veut comprendre une personne avant que son pouce ait fini
> de passer ?

Ce relais juge la preuve réellement produite, jamais la qualité supposée du
prompt. Pour éviter le biais d'intention, il ouvre d'abord l'image seule et son
aperçu dans la surface cible, sans lire le concept approuvé. Il consigne ce que
l'œil rencontre en premier, la situation comprise en moins de deux secondes, la
question spontanée et la décision probable : arrêter, hésiter ou continuer à
scroller. Il consulte seulement ensuite la mise en scène et le manifeste pour
contrôler leur fidélité.

Il vérifie le point focal de la première seconde, la lisibilité de la situation,
l'arrêt du scroll, la question créée, le désir de contempler, la beauté et la
dignité, la singularité, la résistance au vrai cadrage UI et la fidélité au
concept. Lorsqu'un temple ou une référence identifiable à l'Église apparaît, il
contrôle aussi les sources officielles consignées et l'absence d'espace ou de
rite inventé. Un symbole classique peut réussir et une scène dramaturgique peut
échouer : aucun mode ne reçoit de faveur.

Le verdict est `PASS`, `REWORK`, `REJECT` ou `BLOCKED`. Un échec de lecture en
deux secondes, de surface ou de fidélité ne peut pas être compensé par une bonne
moyenne. Le Critique formule au plus trois corrections visibles et actionnables,
sans réécrire le prompt, inventer un concept, retoucher l'image ou rappeler le
Producteur.

Il conserve son rapport intégral dans
`fast.agent_memory.critique_deux_secondes`, sa projection dans
`fast.result.visual_proof_review`, puis pose
`council.current_stage: visual_proof_approval`. L'humain reçoit alors la preuve
et le rapport et inscrit sa décision dans `fast.visual_proof_approval`. Même un
`PASS` du Critique n'autorise aucune production en série.

## 10 — Gate humain du Quiz français complet

Avant toute traduction, l'humain voit les dix questions en conditions réelles
dans `street_quiz_390x667`. Chaque unité emploie son image finale et sa copie
française exacte dans deux états : `ask`, puis `reveal`.

Le dossier de validation consigne pour chaque question :

- l'image réellement affichée ;
- le prompt français ;
- les choix dans leur ordre effectivement rendu ;
- la `displayed_correct_letter`, lettre visible de la bonne réponse pour cette
  capture ;
- le texte de la bonne réponse et le `feedback` révélé.

La lettre visible n'est pas `correct_choice` : Street mélange les choix, puis
attribue A, B, C ou D selon leur position rendue. `correct_choice` reste la clé
stable attachée au sens de la réponse juste.

La preuve Voix préliminaire emploie le test système permanent
`test/system/expedition_fast_voice_visual_test.rb`. Chaque formulation devient
une vraie `QuizDefinition::Question` avec son propre `correct_choice`; le test
soumet une mauvaise réponse, puis vérifie l'unique ligne juste, sa lettre après
mélange, son texte source et le feedback exact. Une simple substitution de
texte dans le DOM d'une question hôte est une preuve invalide.

L'humain approuve ou rejette chaque unité dans
`fast.french_quiz_approval`. L'ensemble ne passe à `approved` que lorsque les
dix IDs sont validés. Un changement d'image, de prompt, de choix, de
`correct_choice` ou de `feedback` réinitialise l'approbation de la question
touchée et exige un nouveau rendu réel.

`fast.translation_gate.translation_authorized` reste `false` tant que ce gate
n'est pas entièrement approuvé. Aucun texte espagnol, anglais ou portugais
brésilien ne doit être produit avant cette décision humaine. Après
l'approbation, chaque langue repasse indépendamment les contrôles de voix,
longueur et rendu mobile ; la validation française ne certifie pas les
traductions.

## 11 — Localisateur-Voix multilingue

> Comment un présentateur natif dirait-il exactement le même moment de jeu,
> sans déplacer la vérité ni la bonne réponse ?

Ce neuvième agent n'est autorisé qu'après l'approbation des dix unités
françaises. Il produit trois localisations autonomes depuis la source française
approuvée : `es`, `en` et `pt-BR`. Une langue n'est jamais traduite depuis une
autre traduction.

Pour chaque langue, il :

- préserve `id`, `type`, `format`, `reference`, les identifiants de choix et
  `correct_choice` ;
- localise le prompt, les choix et le feedback dans une voix de présentateur
  native, avec `tú`, `you` ou `você` pour le joueur Street ;
- relit les trente séquences complètes à voix haute ;
- réapplique indépendamment les limites de 72, 32 et 120 graphèmes ;
- exécute chaque formulation comme une vraie `QuizDefinition::Question` sur la
  feuille Street `390 × 667` ;
- vérifie après mélange la lettre, l'identifiant et le texte de la bonne
  réponse, puis le feedback révélé ;
- réutilise les images françaises approuvées sans génération ni texte incrusté.

Une phrase exacte mais étrangère à l'oreille reçoit
`REJECT_NON_NATIVE_VOICE`. Un dépassement reçoit `REJECT_COPY_OVERFLOW`. Un
simple remplacement du DOM ou un compte de caractères sans rendu réel n'est
pas une preuve.

Ses productions intégrales restent dans
`fast.agent_memory.localisateur_voix`. Les questions et audits structurés sont
écrits dans `fast.result.translations.es`, `.en` et `.pt-BR`. Trois PASS
techniques conduisent à `council.current_stage: translation_approval`, jamais à
une publication. `fast.translation_approval` conserve une décision humaine
indépendante pour chaque langue.

## Contrat visuel enregistré — formats

Le YAML FAST conserve les formats approuvés dans `fast.visual_requirements`.
Ce contrat décrit les livrables attendus, mais **n'autorise pas à lui seul leur
génération**. `production_owner` nomme le Directeur artistique-producteur ;
`generation_authorized` reste `false` pour le lot complet. Le sous-contrat
`proof_generation` autorise seulement une preuve avant le Critique et le gate
humain.

Le Conseil minimise les appels créatifs. Une nouvelle scène possède par défaut
un unique master carré `2160 × 2160` composé pour que son action essentielle
survive dans l'intersection centrale des crops `9:16`, `4:5` et `16:9`. Les
fichiers HD propres aux surfaces sont des dérivés techniques contrôlés du même
master : `1080 × 1920`, `1440 × 1800` et `1920 × 1080`. Ils ne déclenchent pas
de nouvelle génération.

Un crop n'est accepté qu'après inspection dans la vraie surface avec son chrome
et sa copie. Si le sujet, la relation ou la zone de copie ne survit pas, une
composition supplémentaire peut être autorisée uniquement pour le ratio en
échec. Elle n'est jamais produite « au cas où ».

| Surface | Statut | Master créatif minimal | Dérivés / réemploi |
| --- | --- | --- | --- |
| Visuel de question Quiz | obligatoire | le master portrait français déjà approuvé par question | téléphone `9:16`; TV/présentateur adapte le même master; nouveau paysage seulement après échec constaté |
| Bibliothèque | obligatoire | 1 master carré par jour, soit 7 | crops HD `9:16`, `4:5`, `16:9` |
| Hero de la page Rama | obligatoire | master de campagne partagé | crops HD `9:16`, `4:5`, `16:9` |
| Hero title Rama | obligatoire, mais texte HTML | fr + es + en + pt-BR; aucun texte dans l'image | 0 master image |
| Key art de l'expédition | obligatoire | le même master de campagne | crops HD `9:16`, `4:5`, `16:9` |
| Visuels des portes/packs | obligatoire par réemploi | première image Quiz approuvée de chaque pack | master dédié uniquement après échec sur la Map |
| Expédition sur la Home | activable sans génération | le même master de campagne | crops HD `9:16` et `16:9` |

Le Hero title Rama reste une copie native dans les quatre langues, jamais une
typographie incrustée dans l'artwork. Ses zones sûres sont :

- portrait `9:16` : bas du cadre ;
- tablette `4:5` : bas/gauche ;
- paysage `16:9` : moitié gauche pour le H1 et le CTA.

Le master créatif est conservé en PNG sans texte incrusté. Les renditions web
peuvent être encodées en AVIF, WebP et JPEG par le pipeline média ; ces encodages
et tailles responsives ne sont pas des variations artistiques. Pour sept jours
de Bibliothèque et une campagne, le budget plafond est donc de huit nouveaux
masters créatifs, pas vingt-sept. Ce plafond n'est jamais une cible : une image
de Quiz déjà approuvée est réemployée lorsqu'elle porte honnêtement la journée
Bibliothèque, ce qui peut encore réduire le nombre réel de générations. Toute
exception conserve dans le YAML la surface qui a échoué, sa preuve et
l'autorisation humaine du nouvel appel.

## Paquet final visible

L'Influenceur rend :

1. `STATUT : FAST ÉDITORIAL COMPLET` ;
2. la référence, la langue et la source utilisée ;
3. une synthèse d'une phrase de chaque étape ;
4. `YAML` avec le chemin exact de l'artefact ;
5. la confirmation que les cinq productions éditoriales intégrales, le
   brouillon de dix questions et les dix questions finales validées sont
   présents dans ce fichier, ainsi que l'état des mémoires de mise en scène et
   de direction artistique et de critique des deux secondes ;
6. le statut de `fast.visual_requirements`, en précisant que le contrat de
   formats ne constitue pas une autorisation de génération.

La réponse de chat peut rester courte : le YAML est la mémoire et le résultat
canonique du Conseil FAST. `FAST COMPLET` sera réservé au jour où tous les
relais requis, notamment les relais visuels et les gates de publication, seront
présents et validés.
