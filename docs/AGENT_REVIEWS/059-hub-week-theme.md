# 059 — Game hub: theme engine + first fold

Reviewed: 2026-08-27 (polish pass + single-background audit)
Slice: Street `/` game hub. After the first direction pass, a polish pass: mini-HUD on scroll, compact empty rails, pulse/Liga contrast, honest progression copy, fewer boxes below the fold. Live-night seats untouched. Honest data only.
Tests: `bin/rails test test/services/hubs/ test/controllers/street_hub_controller_test.rb test/i18n/locale_files_test.rb test/helpers/application_helper_test.rb test/integration/ui_chrome_test.rb` — green. System: signed-in hub shell (mini HUD) green; guest hub flow reaches Jouer overlay. Phone 390×844: mini HUD 62px, empty rails ~57px, pulse `rgb(246,241,228)`, Liga chip ~29px. Jouer opens `/jugar`. Full suite not re-run in this loop.
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: `.cursor/skills/noche-hub-theme/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr valid and validated

## Feeling

Pride of a ficha, hunger to continue the pack, a quiet pull toward the next Noche Live, belonging to the house. Not “access the directory.”

## 1 — Game experience

Emotional objective: the phone opens on **who I am** and **what I play now**. Loop: see pack still → tap gold Jouer (press, 180ms halo, `chest` SFX, haptic unless Sonido is off) → `/jugar`. Reward on the hub is remaining pack curve points (max 103), not a fake +150. XP bar uses `Team::RANKS`. Crowns are league `total_score`. Live red / join only if a listed night is `playing`. Empty live is an honest 14-day silence, not a fake countdown.

Dead screens killed: rope map and Stories ticks off `/`. Dock Live is a gold medallion at rest; red pulse only when `playing`.

## 2 — UI design

2-second verb: gold **Jouer** on the hero still. HUD grid: avatar, name/rank, crowns, streak, full-width XP. First phone fold (390×844) shows identity, hero+Jouer, next-live (or honest empty), a peek of défi/online, dock. States: idle / pressed / launch on Jouer; live `none|scheduled|soon|imminent|playing`; dock `is-hot` only when playing; guest vs ficha. Tokens: `--surface-glass`, `--text-primary`, `--gold-primary`, `--button-primary`, `--overlay-soft/strong`, `--navigation-surface`. `data-hub-theme` / `atmosphere` / `accent` on `#street_world`. Profile gate still hides the feed.

## 3 — Art direction

Emotion: enter a biblical still, not a dashboard. Composition: full-bleed artwork, local top scrim + bottom glass gradient on the hero, gold as metal (CTA, dock Live, XP fill, crown pictos). Light/Dark from `config/media/hub_backdrops.yml` (pack/night tags, else ISO week). No user toggle. Dark is navy glass + cream type, not a black social skin. Gold type on cream Light kickers is vetoed (ink / cream on scrim).

## Theme engine (hub `/`)

Same Home. Manifest + artwork + `mode`. Atmosphere/accent attributes ready; CSS v1 consumes `mode` plus light atmosphere hooks (`glorious` / `dramatic` / `solemn`). Scenes swap without forking markup. On `/`, the preloaded manifest artwork is now the only narrative background from first paint: the legacy `.sky` marble hall is disabled for `is-game-hub-page`, and the UI entrance no longer fades from one image into another.

## Four seats

Street hub (who / where / what now / around me). Live night seats unchanged.

| Seat | Verb tonight |
|---|---|
| Host | Unchanged gold next on stage |
| Chapel (controller) | Unchanged Buzz |
| Remote | Unchanged A/B QCM |
| TV / Twitch | Unchanged 16:9 |

## Tension

Street loop, not a night band. What rises: pack step, remaining crowns on the chest, next Noche Live as it actually approaches. What would make this a quiet quiz: another rope map or five equal admin cards.

## Finale

N/A. Does not change the last live round.

## Languages

noche-i18n: **PASS**
- es: *Ningún desafío en curso* / *Pack n de total* / *Ver la Liga* / *Nadie en línea por ahora* — tú street, Noche Live untranslated
- pt-BR: *Nenhum desafio agora* / *ala* in the hint / *Ver a Liga* — not ramo
- fr: *Aucun défi en cours* / *Pack n sur total* / *0 terminés · Rois en cours* / *Personne en ligne pour l’instant* — tu on the phone
- en: *No challenge underway* / *Pack n of total* / *See the Liga* — not contestants

## Scores (/10)

Any dimension **< 8 must be reworked**. The previous 8.45 was too generous (sticky ficha, ink-on-navy pulse, ivory Liga tile, tall empty cards). This pass scores the **captures**, not the architecture.

| Dimension | /10 |
|---|---|
| Fun | 8.5 |
| Clarté | 8 |
| Impact visuel | 8.5 |
| Feedback | 8 |
| Progression | 8.5 |
| Social | 8 |
| Immersion | 8.5 |
| Accessibilité | 8 |
| Cohérence NocheLive | 8.5 |
| Envie de continuer | 8.5 |

Average **8.25**. Floor of 8 held after polish. Social is 8 because empty défi/online are now **designed actions** (Défier / Voir la Liga), not tall vacant tiles — still no invented friends. Accessibilité is 8 because pulse and Liga measure cream on glass (`rgb(246,241,228)`), not ink on navy; residual risk remains where the painting is bright behind type.

## Verdict

PASS WITH NOTES

## What works

- Full ficha only at rest. On scroll it becomes a 62px mini-HUD: avatar + name · rank + crowns + streak. Dock stays fixed.
- Empty social recomposes: compact rails with a verb, not equal-height vacant cards.
- Progression says *Pack 1 sur 17* and *0 terminés · Rois en cours* — the current pack is named, not “0 unlocked.”
- Pulse and Liga chips follow `--text-primary`. Liga is a 29px pill, not a 5rem ivory tile.
- Lower half uses hairlines and pills. Hero keeps the one big card. Jouer still reaches `/jugar`.

## What feels weak

- First fold is still two stacked cards (ficha + hero). The painting → panel gradient is softer, not yet “composed as one still.”
- Voyage dots can sit just under the mini-HUD while the hero scrolls away.
- Community pulse can still fight a bright patch of the painting; Light now uses ink plus a cream halo on community/progress/rails.
- WhatsApp spec PNGs still missing under `tmp/street-shots/temple-mockups/`.

## Required before approval

- Light capture at 390×844 (this polish was verified Dark, Tracy’s live session).
- Mini-HUD must not cover hero dots or “Étape n/10.”
- Pulse type must stay readable where the still is light. Full `bin/rails test` before merge.

## Evidence (optional)

Dark phone 390×844: fold = HUD + hero + live strip + peek of défi rail + dock. Scroll = mini-HUD + compact empty rails + Pack 1 sur 17. Pulse cream. Liga cream pill. Jouer → `/jugar`.

## Night director

Would I tap Jouer? Yes. Empty parish is no longer a dead floor — it asks Défier / Liga. Friday four-seat is unchanged.
