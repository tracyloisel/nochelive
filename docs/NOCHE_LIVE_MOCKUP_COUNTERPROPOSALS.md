# Noche Live — contre-proposition de mockup simplifiée

**Décision :** on conserve le thème et l'écran de quiz existants. La refonte porte
uniquement sur la page publique de la Noche et ses états dans le temps.

**Direction visuelle :** sentiment d'appartenance avant le départ, puis urgence joyeuse
pendant le Live. L'artwork du pack remplit le fond et détermine Celestial Light ou
Dark. Les informations reposent sur quelques surfaces de verre locales ; un seul CTA
en verre doré porte l'action. Les transitions d'heure et de leader reçoivent un bref
éclat ou pulse, supprimé en réduction de mouvement.

## 1. Avant le Live

```text
┌──────────────────────────────────┐
│        ARTWORK DU PACK           │
│        ROIS ET PROPHÈTES         │
│   Samedi 29 août · 20 h 00       │
│          DANS 2 J 04 H           │
├──────────────────────────────────┤
│        [ JE M'INSCRIS ]          │
├──────────────────────────────────┤
│  24 inscrits                     │
│  Carmen · Tracy · Ingrid · …     │
├──────────────────────────────────┤
│  À LIRE AVANT LE LIVE            │
│  1 Rois 3 · 1 Rois 18 · …        │
└──────────────────────────────────┘
```

Une seule image : celle du pack. Pas d'illustration propre à la Noche.

## 2. Lobby, 30 minutes avant

```text
┌──────────────────────────────────┐
│  ROIS ET PROPHÈTES               │
│       DÉPART DANS 18:42          │
├──────────────────────────────────┤
│  MON ÉQUIPE                      │
│  Nazareth · 5 joueurs [REJOINDRE]│
│  Béthel    · 4 joueurs [REJOINDRE]│
│  Jéricho   · 6 joueurs [REJOINDRE]│
└──────────────────────────────────┘
```

Ce sont uniquement les équipes déjà créées dans la rama. Le lobby ne permet ni de
créer ni d'éditer une équipe. Pas de Host et pas de bouton de lancement : le quiz
démarre à l'heure prévue.

## 3. Player pendant le Live

Player est exactement le quiz actuel :

![Quiz actuel conservé sans modification](../tmp/street-shots/quiz-overlay/ask-v3.png)

Le seul ajout pendant une question est la tuile Défi existante
`.duel-quiz-rail`. Elle reste montée et transforme son contenu lorsque les événements
s'enchaînent, y compris toutes les deux secondes, sans recouvrir ni bloquer les choix.
L'écran de score final ajoute `Retour à la Noche Live`.

## 4. Watch pendant le Live

```text
┌──────────────────────────────────┐
│ ROIS ET PROPHÈTES · EN DIRECT    │
│ Fin dans 36:26                   │
│                                  │
│      [ S'INSCRIRE ET JOUER ]     │
├──────────────────────────────────┤
│ CLASSEMENT DES ÉQUIPES           │
│ 1  Nazareth       284 pts        │
│ 2  Béthel         251 pts        │
│ 3  Jéricho        219 pts        │
├──────────────────────────────────┤
│ QUESTIONS                        │
│ Q1  9/9  ██████████              │
│ Q2  8/9  █████████░              │
│ Q3  6/9  ██████░░░░              │
├──────────────────────────────────┤
│ Nazareth vient de prendre la tête│
└──────────────────────────────────┘
```

Le CTA s'adapte : `S'inscrire et jouer`, `Choisir une équipe`, `Commencer le quiz`
ou `Continuer le quiz`. Le joueur choisit parmi les équipes existantes. Il ouvre un
flow court ; Watch ne devient pas un formulaire. Sur TV, ce CTA devient un QR code.

Le classement est exclusivement celui des équipes. Son calcul est affichable en une
phrase : **total de l'équipe = somme des points de ses joueurs**.

## 5. Watch final

À l'heure de fermeture, le CTA disparaît et le même écran fige le classement final.
Un joueur interrompu voit `Temps écoulé`, son score partiel pour l'équipe, puis
`Voir la Noche Live`. Aucune cérémonie parallèle, aucun écran de présentateur et
aucun thème de quiz supplémentaire ne sont nécessaires.

## Hors périmètre

- rôle ou console de présentateur ;
- lancement et clôture manuels normaux ;
- création ou édition d'une équipe depuis la Noche ;
- thème de quiz spécifique au Live ;
- classement individuel principal sur Watch ;
- moyenne ou normalisation du score d'équipe ;
- chat, discussion ou tableau de bord analytique.
