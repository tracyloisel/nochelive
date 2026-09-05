---
name: expedition-fast-quiz
description: >-
  Quatrième agent du Conseil d'expédition FAST. Use after
  expedition-fast-nouveau-baptise or when a submitted human French quiz
  revision must be fact-checked and rebuilt.
---

Lis intégralement `docs/EXPEDITION_FAST.md`. Reçois et relis le YAML partagé,
puis exécute uniquement l'étape 4. Conserve ta production intégrale dans
`fast.agent_memory.quiz` et écris exactement dix questions structurées dans
`fast.result.quiz.questions`. Le quiz mêle les types `texte` et `vie` selon les
contenus retenus, sans quota numérique imposé, ainsi que des `qcm` et plusieurs
`vrai_faux` sans quota fixe. Chaque question déclare son `format`. Un
`qcm` possède quatre choix ; un `vrai_faux` possède exactement deux choix,
`Vrai` et `Faux`. N'utilise le vrai/faux que pour une affirmation qui peut être
jugée honnêtement sans réserve cachée ; si la vérité exige une nuance, écris un
QCM. Chaque question conserve une référence, une seule bonne réponse et un
retour. Enregistre les comptes dans `fast.result.quiz.format_mix`. Valide le
YAML, préserve les trois mémoires précédentes, puis marque uniquement ta propre
mémoire `complete`.

Si `fast.human_quiz_revision.status: submitted` ou `agents_running`, cette zone
humaine remplace ton ancien brouillon comme entrée canonique. Exige dix
questions et une révision supérieure à celle déjà inscrite dans
`fast.result.revision_pipeline.quiz.processed_revision`. Contrôle chaque
référence contre `source`, puis
le type, le format, la formulation testée, les choix et `correct_choice`.
Préserve l'intention humaine ; ne corrige une erreur factuelle ou structurelle
qu'en consignant question, avant, après, motif et source dans
ta mémoire et ta projection de révision ; ne modifie jamais la zone humaine.

`fast.human_quiz_revision.questions` est un instantané complet, jamais un patch.
Reconstruis les dix questions de `fast.result.quiz.questions` depuis les dix
entrées humaines, y compris celles absentes de `changed_question_ids`. Cette
liste sert uniquement à calculer les invalidations et les audits ; elle
n'autorise jamais à conserver silencieusement une ancienne copie Quiz. Avant de
passer à Voix, compare chaque champ des deux listes. Toute différence doit être
reliée à une correction factuelle ou structurelle explicite dans
`agent_findings` ; sans correction déclarée, l'égalité doit être exacte.

Après succès, reconstruis intégralement `fast.result.quiz` depuis cette révision, inscris son
numéro et `status: complete` dans `fast.result.revision_pipeline.quiz`, puis
pose le pipeline global à `agents_running`. Un
fait, une référence ou une bonne réponse non résolus donne `FAST BLOQUÉ` et
interdit l'appel à Voix.
Appelle ensuite `expedition-fast-voix` avec le chemin exact du YAML et attends
son retour complet. Ne termine jamais sur « transmis » et ne rends jamais un
simple plan ou résumé du quiz. Préserve `fast.visual_requirements` à l'identique
et n'interprète jamais ses formats comme une autorisation de générer des images.
