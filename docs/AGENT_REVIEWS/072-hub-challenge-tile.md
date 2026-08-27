# 072 — Hub défi tile (Celestial Light + Dark)

Reviewed: 2026-08-27
Slice: around-me **Défi en cours** tile — waiting VS capsule vs scored split bar, live names/scores
Tests: `bin/rails test test/services/hubs/screen_test.rb test/services/quizzes/ensure_hub_duel_test.rb test/controllers/street_hub_controller_test.rb test/i18n/locale_files_test.rb`
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: `.cursor/skills/noche-hub-theme/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr valid and validated

## Feeling

Rivalry and tension: someone in the rama is already in the fight. Waiting = face-off (animal keys, VS). Scored = the race is on, live numbers, finish first.

## 1 — Game experience

Loop: see the rival → tap the door → play or open the défi. No admin share/accept chrome on the hub tile. Empty rail still invites Défier. Scores are the duel’s, never 78/103. Streak subline only from a real `HitStreak` ≥ 2.

## 2 — UI design

2-second verb: DÉFI EN COURS + chevron door. States: empty, waiting (VS capsule), scored (split bar). Same ERB; Light ink-on-paper / Dark cream-on-charcoal via hub tokens. Gold = kicker, chevron, rings, hairline.

## 3 — Art direction

Ivory physical VS object on both families. Light: paper card, serif name, fire/navy bar. Dark: charcoal card, large given name, gold/silver animal rings. Not a dashboard row.

## Theme engine (hub `/`)

Same Home. Tile consumes `--surface-primary`, `--border-gold`, `--text-primary`, `--gold-primary`. Mode from `#street_world[data-hub-theme]`. No toggle, no forked markup.

## Four seats

Street hub around-me: who (HUD) / where (rama) / what now (Jouer) / around me (this tile).

| Seat | Verb tonight |
|---|---|
| Host | N/A street |
| Chapel (controller) | N/A street |
| Remote | N/A street |
| TV / Twitch | N/A street |

## Tension

The tile is a live duel, not a shortcut to `/desafios`. Waiting holds the stare. Scores make the chase readable.

## Finale

N/A street pack.

## Languages

es source `hub.rival_streak` / existing `hub.challenge_now`, `hub.finish_first`. fr thin space before `!`. pt-BR *acertou seguidas*. en warm, not “contestant”.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 8 |
| Feedback | 8 |
| Progression | 8 |
| Social | 9 |
| Immersion | 8 |
| Accessibilité | 8 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 8 |

## Verdict

PASS

## What works

- Two honest anatomies, one component, theme tokens
- Live given name / display_name / animal keys / duel scores
- Door to `/jugar` or `/desafio/:token`

## What feels weak

- Half-width around-me column is tight for the scored bar on a 390 phone
- Resolved duels still say finish-first (mockup caption)

## Required before approval

- None.

## Evidence (optional)

Seed: `bin/rails noche:hub_challenge` as LoopDefi vs Pili in RAMA.

## Night director

I would tap it — the rival is on the home, not buried in an inbox.
