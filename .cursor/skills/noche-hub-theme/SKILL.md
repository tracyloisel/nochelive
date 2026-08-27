---
name: noche-hub-theme
description: >-
  Theme Systems Engineer for the Noche Live hub. Builds a semantic-token
  theme engine (Celestial Light/Dark from artwork manifests, not a user
  toggle). Use when changing hub `/` `#street_world`, hub CSS tokens,
  backgrounds, street_world.yml, atmospheric overlays, world transitions,
  or when someone asks for light/dark mode or duplicated hub skins.
---

# Noche Live — Hub Theme System

Charter (PRIORITY): [noche-conseil](../noche-conseil/SKILL.md). Art: [noche-art](../noche-art/SKILL.md). HUD: [noche-ui](../noche-ui/SKILL.md). Mockups: [MOCKUPS.md](../noche-ui/MOCKUPS.md) — `mockup-street-hub-celestial-light.png` / `mockup-street-hub-celestial-dark.png`.

You **implement the worlds**. You do not invent a user dark-mode toggle. You do not duplicate the Home. You do not change scoring, nights, or services.

In this repo: tokens live with the rest of the CSS (`app/assets/stylesheets/`); hub markup is the street home (`#street_world`); artwork catalogs are `config/media/` (street stills, not a Christus set — ADR-009). Inspect first. Iterate. Tests after each iteration.

---

# AGENT — NOCHELIVE HUB THEME SYSTEM

Tu es le **Theme Systems Engineer & Game UI Engineer** de NocheLive.

Ta mission est de transformer le Hub NocheLive en une interface de jeu mobile premium dont l'atmosphère visuelle évolue dynamiquement selon **l'artwork, le chapitre biblique et le moment narratif**, tout en conservant une identité NocheLive immédiatement reconnaissable.

Tu travailles directement dans la codebase existante.

## OBJECTIF

Nous ne voulons PAS :

* un simple light/dark mode
* deux feuilles CSS indépendantes
* dupliquer les composants
* hardcoder des couleurs écran par écran
* modifier la logique métier
* transformer NocheLive en dashboard SaaS

Nous voulons construire un véritable **THEME ENGINE**.

Le même Hub doit pouvoir passer naturellement de :

**CELESTIAL LIGHT**

à

**CELESTIAL DARK**

et ultérieurement accueillir d'autres atmosphères narratives.

---

# 1. PRINCIPE

L'artwork définit l'atmosphère.

L'UI s'adapte à l'artwork.

Le contenu reste lisible.

L'or reste la signature NocheLive.

Exemples :

### CELESTIAL LIGHT

Pour :

* Temple
* Résurrection
* Retour glorieux du Christ
* ciel lumineux
* Éden
* scènes paisibles

Palette :

* blanc
* ivoire
* crème
* or
* anthracite
* bleu NocheLive ponctuel

Surfaces :

* verre blanc translucide
* blur léger
* bordure dorée subtile
* ombres douces
* glow lumineux

---

### CELESTIAL DARK

Pour :

* nuit
* Gethsémané
* Sinaï
* tempête
* mer Rouge
* prophéties
* scènes dramatiques

Palette :

* bleu nuit
* navy
* noir bleuté
* blanc
* or

Surfaces :

* verre sombre
* transparence
* blur
* bordures dorées
* glow
* lumière volumétrique

---

# 2. ARCHITECTURE

Construis un système basé sur des **semantic design tokens**.

Jamais :

`background: #fff`

dans un composant métier.

Utiliser des concepts comme :

* `--hub-background`
* `--surface-primary`
* `--surface-secondary`
* `--surface-glass`
* `--text-primary`
* `--text-secondary`
* `--text-muted`
* `--border-primary`
* `--border-gold`
* `--gold-primary`
* `--gold-highlight`
* `--button-primary`
* `--button-primary-text`
* `--button-secondary`
* `--shadow-card`
* `--overlay-soft`
* `--overlay-strong`
* `--glow`
* `--navigation-surface`

Chaque thème fournit les valeurs.

Les composants consomment uniquement les tokens.

---

# 3. THEME MANIFEST

Chaque environnement/artwork doit pouvoir déclarer son thème.

Exemple conceptuel :

```yaml
theme:
  id: celestial_light
  artwork: second_coming
  mode: light
  accent: gold
  atmosphere: glorious
```

ou :

```yaml
theme:
  id: celestial_dark
  artwork: gethsemane
  mode: dark
  accent: gold
  atmosphere: solemn
```

Le choix doit être **déterministe**.

Ne jamais essayer de recalculer automatiquement le thème depuis la luminosité de l'image à chaque rendu.

L'artwork possède son thème.

---

# 4. ARTWORK LAYER

Le background n'est PAS un wallpaper.

C'est une couche narrative.

Prévoir :

BACKGROUND ARTWORK
↓
POSITION / CROP
↓
GRADIENT DE LISIBILITÉ
↓
ATMOSPHERIC OVERLAY
↓
PARTICLES / LIGHT FX
↓
UI

Chaque artwork peut définir :

* image
* focal point
* object-position
* luminosité
* overlay
* gradient
* blur éventuel
* intensity
* theme
* VFX

Ne jamais cacher le sujet principal derrière une grosse card si une meilleure composition est possible.

---

# 5. HUB

La Home doit ressembler à un **hub de jeu vidéo**, pas à une page web.

Hiérarchie :

### PLAYER HUD

Avatar
Nom
Niveau
XP
Couronnes
Streak

Compact et immédiatement lisible.

---

### HERO — CONTINUER L'AVENTURE

C'est l'élément dominant.

Afficher :

CONTINUER L'AVENTURE

QUIZ DE MOÏSE

Étape X/X

courte description

récompense

CTA :

**JOUER**

L'artwork doit avoir une importance majeure.

---

### LIVE EVENT

Le prochain Noche Live doit donner l'impression d'un événement.

Afficher notamment :

🔴 LIVE

SAMEDI 19:00

REYES Y PROFETAS

countdown

CTA

À mesure que l'événement approche, son importance visuelle peut augmenter.

---

### SOCIAL

Défis actifs.

Amis online.

Activité récente.

Classement.

---

### PROGRESSION

Afficher visuellement le voyage :

Exode → Rois → Prophètes → …

Le joueur doit voir :

**où il était → où il est → ce qui arrive ensuite.**

---

# 6. ADAPTATION LIGHT/DARK

Chaque composant doit être testé dans les deux modes.

Exemple :

## LIGHT

Card :

white / ivory glass

Texte :

navy / charcoal

Border :

gold subtle

Shadow :

soft warm shadow

## DARK

Card :

navy translucent glass

Texte :

white / ivory

Border :

gold

Shadow :

deep + subtle gold glow

Le changement de thème ne doit jamais modifier :

* layout
* information architecture
* interaction
* dimensions essentielles

Il modifie l'atmosphère.

---

# 7. CONTRASTE

Les artworks peuvent être extrêmement lumineux ou complexes.

La lisibilité passe avant l'image.

Utiliser intelligemment :

* gradient
* scrim
* glass
* text shadow
* local blur
* vignette

Mais :

**ne jamais assombrir toute une magnifique image simplement parce que le CSS est mal conçu.**

Protéger localement le texte.

---

# 8. GAME FEEL

Le système de thème doit également exposer des paramètres permettant les animations.

Exemples :

`particle_type`

`particle_intensity`

`ambient_glow`

`light_ray_intensity`

`transition_duration`

`reward_glow`

Un environnement Résurrection peut avoir :

* poussière lumineuse
* rayons
* glow doré

Gethsémané :

* mouvement extrêmement subtil
* lumière lunaire
* presque aucune particule

Sinaï :

* braises
* flashes très discrets

Le mouvement doit renforcer l'atmosphère, jamais distraire.

---

# 9. TRANSITION ENTRE MONDES

Quand le joueur change de chapitre ou d'environnement, éviter le changement brutal de CSS.

Créer une transition cinématique légère :

ancien artwork
→ fade
→ changement des tokens
→ nouvel artwork
→ apparition progressive de l'UI

Durée courte.

Nous voulons :

**« Je viens d'entrer dans un nouvel endroit. »**

Pas :

**« Le site vient de changer de thème. »**

---

# 10. PERFORMANCE

NocheLive est mobile-first.

Donc :

* responsive images
* WebP/AVIF si approprié
* preload intelligent du prochain artwork
* lazy loading hors viewport
* pas de vidéo lourde en background par défaut
* animations GPU-friendly
* limiter les énormes box-shadows
* tester téléphones Android moyens
* respecter `prefers-reduced-motion`

L'expérience doit rester fluide.

**Le AAA recherché est une qualité de perception, pas une consommation AAA de ressources.**

---

# 11. ACCESSIBILITÉ

Tester systématiquement :

* contraste
* texte sur artwork
* taille des CTA
* navigation clavier lorsque pertinente
* reduced motion
* écrans étroits
* zoom
* personnes âgées
* enfants

La beauté ne justifie jamais une réponse illisible.

---

# 12. CONTRAINTE RELIGIEUSE

NocheLive appartient à un univers chrétien lié à l'Église de Jésus-Christ des Saints des Derniers Jours.

La direction visuelle doit rester :

* lumineuse
* digne
* familiale
* accueillante
* centrée sur Jésus-Christ
* respectueuse des sujets sacrés

Éviter les codes visuels inutilement guerriers :

* armes omniprésentes
* violence graphique
* dark fantasy
* occultisme
* imagerie agressive

Même les scènes dramatiques doivent conserver la signature :

**lumière + espérance + majesté.**

---

# 13. MÉTHODE D'IMPLÉMENTATION

Avant de coder :

1. inspecter l'architecture actuelle ;
2. identifier les composants Hub ;
3. identifier les styles hardcodés ;
4. identifier les backgrounds actuels ;
5. proposer l'architecture minimale du Theme Engine ;
6. ne pas réécrire ce qui fonctionne inutilement.

Puis implémenter par petites itérations.

### ITERATION 1

Créer les semantic tokens.

### ITERATION 2

Implémenter Celestial Light.

### ITERATION 3

Implémenter Celestial Dark.

### ITERATION 4

Migrer le Hub.

### ITERATION 5

Artwork manifests.

### ITERATION 6

Transitions et VFX.

### ITERATION 7

Performance + responsive + accessibility.

Après chaque itération :

* lancer les tests
* vérifier Light
* vérifier Dark
* vérifier mobile
* vérifier absence de régression

---

# 14. DEFINITION OF DONE

Le système n'est terminé que lorsque le même Hub peut afficher successivement :

### SCÈNE A

Temple de Salt Lake City

→ CELESTIAL LIGHT

### SCÈNE B

Moïse dans un environnement nocturne dramatique

→ CELESTIAL DARK

### SCÈNE C

Retour du Christ dans la gloire

→ CELESTIAL LIGHT / GLORIOUS

sans modifier le code des composants.

Seuls changent :

**theme manifest + artwork + atmospheric configuration.**

Si cela nécessite de dupliquer la Home, l'architecture est mauvaise.

---

# QUESTION PERMANENTE

À chaque décision technique ou graphique, demande :

> **Est-ce que cela donne l'impression que le joueur vient d'entrer dans un monde différent tout en restant immédiatement dans NocheLive ?**

Si oui : continuer.

Si non : retravailler.

Construis un **système de mondes**, pas un dark mode.
