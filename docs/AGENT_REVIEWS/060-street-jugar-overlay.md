# 060 — Street jugar overlay (convergence mockup)

Reviewed: 2026-08-27
Slice: `/jugar` gameplay only. Pack ceremony, hub `/`, live seats untouched. Métier (`Quizzes::Submit` / `Advance` / `Tally`) inchangé. Numéro **060** : 059 est déjà le hub thème.
Tests: `bin/rails test` overlay unitaire + contrôleurs + i18n + ui_chrome — vert. Suite visuelle système **pas encore rejouée** dans cette passe.
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A (jugar, pas `/`)
Copy: `.cursor/skills/noche-i18n/SKILL.md` — `quiz.from_the_book`, `quiz.almost`, `quiz.not_this_time` en es / pt-BR / en / fr

## Feeling

Être **dans** la scène biblique, pas dans un questionnaire. Tension courte → tap → fierté ou « Presque » gentil → envie du Suivant. Pas « accéder au quiz ».

## Baseline (avant overlay CSS)

Ancienne anatomie trois-bandes : tête crème Noche Live + rail 10 points + still encadré + feuille ivoire.

```text
Current feeling (baseline phone 01-ask):
- web chrome: 3/10
- immersion: 5/10
- reward: 6/10
- motion: 6/10
- readability: 8/10
```

## Architecture

- Thème par still : `config/media/quiz_stills.yml` → `Quizzes::Chrome.call(question:)` pose `data-quiz-theme`, `data-quiz-atmosphere`, `data-quiz-glass` (soft / medium / strong). Pas de sample luminance à la requête.
- Markup jugar : `#street_quiz.is-overlay` → `home/_street_overlay` (HUD, monde, dock Lire/Suivant + sheet). Cérémonie et non-jugar gardent le reel trois-bandes.
- Stimulus : `quiz_controller` — lock entrée 550 ms, tween score affiché → réel (380 ms), haptic tap / success / miss. Street audio toujours `data-stage-*` (pas `quiz#cue`).
- SFX ask non-slam : `celestial_breath`. Slam Q10 : `round_start`. Hit / miss : `correct_gold` / `wrong_soft`. Mute = Sonido.

## Screenshots

Mockup : `tmp/street-shots/temple-mockups/mockup-street-jugar-celestial-dark.png`

| État | Fichier |
|---|---|
| Ask (Q2, 4 choix, Dark medium) | `tmp/street-shots/quiz-overlay/ask-v3.png` |
| Correct (Q1 David) | `tmp/street-shots/quiz-overlay/correct-v3.png` |
| Wrong « Presque » | `tmp/street-shots/quiz-overlay/wrong-v3.png` |
| Wrong 360×800 | `tmp/street-shots/quiz-overlay/wrong-360.png` |

## Choix UI

- Header web (lockup + rail crème) **absent** pendant le play. HUD verre : avatar, nom, rang + niveau réel, pack, `n / 10`, dots, score réel, hamburger.
- Accueil = `street.nav_hub` dans le tiroir (plus de lockup cliquable).
- Sheet verre + kicker livre + question serif + pastilles A/B/C. Settled = même sheet, ticks/croix, % réels, Lire + Suivant **au-dessus** de la sheet (`.quiz-dock`).
- Wrong : `quiz.almost` (« Presque »), jamais ÉCHEC/FAUX.
- Timer / halo : inchangés (`.play-timer`, `is-timer-warn` / `is-timer-hot`).

## Timings

| Beat | ms |
|---|---|
| Still in | 300 |
| HUD in | 250 (delay 120) |
| Sheet in | 350 (delay 220) |
| Choices stagger | 70 |
| Enter lock (taps) | 550 cap |
| Score tween | 380 |
| Tally width | 520 + 70 stagger |
| Press | scale 0.97 / 120 |

Un joueur qui sait déjà ne doit pas attendre la fin des VFX pour Suivant : le CTA est dans le HTML settled dès la réponse autoritative.

## SFX / haptics

- `celestial_breath` est **nommé** et servi en MP3. L’enregistrement actuel est un stand-in (copie de `fire_whoosh`) — OpenRouter 402. Residual.
- Haptics : `app/javascript/haptics.js` (tap / success / miss / reward). No-op si `vibrate` absent.
- Reduced-motion : coupe enter / praise / next breathe, **pas** l’audio.

## Light / Dark

Tokens `--surface-glass-soft|medium|strong` + `--quiz-text`. Dark joué (Rois, glass medium). Light (Éden soft) **pas screenshoté** dans cette passe.

## Tests

Verts : Chrome catalog, street jugar overlay markup, submit hit/miss/expire, rewind, cérémonie Q10, helper audio `celestial_breath`, i18n parity, ui_chrome overlay. Système `street_quiz_visual_test` à rejouer.

## Scores (/10)

Conseil (toute note &lt; 8 = rework). **Moyenne globale encore sous 8.7** — la boucle continue.

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 8 |
| Impact visuel | 8 |
| Feedback | 8 |
| Progression | 8 |
| Social | 8 (rival chip conservé, non rejoué ici) |
| Immersion | 8 |
| Accessibilité | 8 |
| Cohérence NocheLive | 8 |
| Envie de continuer | 8 |

Final scorecard (plan) :

| Axis | /10 |
|---|---|
| Visual Fidelity | 8.3 |
| Game Feel | 8.2 |
| Motion | 8.0 |
| SFX | 7.4 |
| HUD Clarity | 8.4 |
| Artwork Immersion | 8.5 |
| Answer Readability | 8.3 |
| Reward Satisfaction | 8.4 |
| Mobile Ergonomics | 8.1 |
| NocheLive Identity | 8.5 |
| Performance | 8.0 |
| Rhythm | 8.2 |

## Verdict

**PASS WITH NOTES** — anatomie overlay jouable, feeling jeu (plus webapp trois-bandes). Stop interdit : SFX stand-in, pack 10 incomplet, Light non capturé, tests système overlay à vert.

## What works

- Full-bleed still + HUD flottant + sheet verre A/B/C.
- Settled transform : Super / Presque, tally réel, Lire + Suivant or.
- Score HUD 0→5 interpolé sur Q1 (précédent affiché → réel).
- 360 : 4 choix + CTAs encore présents.

## What feels weak

- `celestial_breath` n’est pas encore un souffle unique.
- Hamburger encore un disque à part (proche du HUD, pas *dans* la capsule mockup).
- 4 choix : sheet haute, moins de peinture.
- Light / timed halo / duel non rejoués visuellement cette passe.

## Required before approval

- Générer un vrai `celestial_breath.mp3` (Lyria) ; rejouer 10 questions avec le son.
- Capturer un still Light (Éden / soft).
- `bin/rails test test/system/street_quiz_visual_test.rb` vert.
- Pack complet sans friction tap→Suivant.

## Night director

Street, pas live. J’ouvrirais bien la question suivante — le header web ne me sort plus du jeu. Je ne signerais pas « fini » tant que le souffle d’entrée n’est pas le bon son et qu’un pack de 10 n’a pas été joué les yeux hors du code.
