# M122 — Notifications sous contrôle

Reviewed: 2026-08-29
Slice: one player-facing notification choice, not a permission dashboard
Tests: notification UI, locale, system and delivery-lock suites — 46 runs, 451 assertions, 0 failures; `node --test test/javascript/service_worker_push_test.mjs` — 6 passes
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — profile-world Celestial Light surface, not hub atmosphere
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr read and parity-tested

## Feeling

The player must feel agency and calm: every alert is visibly optional, the system permission arrives only after a deliberate first choice, and every choice can be reversed here. It should feel like tuning a game companion, never filling out an administration form.

## 1 — Game experience

Anticipation is carried by three concrete promises: the next Noche Live, a rival's answer, or a passage for the road. The action is one compact switch. The result is an immediate state change plus saved feedback. The next want remains visible without making any category preselected. There is no automatic permission interruption in express onboarding and no notification prompt during a live round.

## 2 — UI design

The two-second verb is “choose your alerts.” All three categories live in one measured vertical folio at every breakpoint. Switches expose inactive, active, loading-disabled, unsupported, system-denied and expired-device behavior through existing Stimulus states. Visible controls retain a 44 px target and cannot expand into multiline CTAs. The verse frequency and local time stay inside their category row.

## 3 — Art direction

Celestial Light comes from the existing profile gathering artwork. The translucent ivory folio, restrained gold hairline, small medallions and warm status signal preserve Noche Live's signature without turning every choice into a gold CTA. One continuous list replaces the orphaned card grid and keeps the chapel-world composition visible around the settings.

## Theme engine

N/A. This is the existing profile-world Celestial Light family and introduces no theme toggle or forked hub markup.

## Four seats

Street flow, not a live-night seat screen. Who: the current player. Where: this browser/device. What now: choose exactly which moments may reach this device. Around me: my ward night, player challenges, and scripture journey.

## Tension

The street loop rises from useful future moments rather than urgency theater. Copy states the notification cap and makes “never during the rounds” explicit, protecting the live game's tension instead of competing with it.

## Finale

N/A. Notification delivery can bring a player back to the exact live entrance, duel, result or scripture destination, but this settings slice does not alter scoring or a finale.

## Languages

Copy was rewritten natively in **es**, **pt-BR**, **en** and **fr**. Locale parity and model/controller locale tests are green. Long device-and-player CTA sentences were removed in every locale.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8.0 |
| Clarté | 9.4 |
| Impact visuel | 8.8 |
| Feedback | 8.8 |
| Progression | 8.2 |
| Social | 8.2 |
| Immersion | 8.8 |
| Accessibilité | 9.1 |
| Cohérence NocheLive | 9.2 |
| Envie de continuer | 8.4 |

## Verdict

PASS

## What works

- One stable column at 390×844, 768×1024 and 1440×900; no orphan card or horizontal overflow.
- Compact semantic switches make the state scannable without repeating the player's name or device in every action.
- Permission timing is explained before the first choice, with system-denied and unsupported states still readable.
- The existing destination-opening push behavior remains covered by service-worker tests.

## What feels weak

- Browser-native time and select controls vary slightly by platform, but remain token-framed, legible and contained.

## Required before approval

- None for the interface itself. Production delivery remains blocked pending the separate editorial sign-off in `docs/NOTIFICATION_EDITORIAL_APPROVAL.md`.

## Evidence

- Reference mockup: `tmp/street-shots/temple-mockups/mockup-notification-settings-celestial-light.png`.
- Final captures: `tmp/push-shots/settings-default-390x844.png`, `settings-default-768x1024.png`, `settings-default-1440x900.png`, and `settings-authorized-390x844.png`.
- Browser console: no warnings or errors after final local reload.
- Automated geometry asserts one column, no horizontal overflow, contained controls, and 44–48 px switch height at all three widths.

## Night director

Yes. The screen gets out of the way quickly, keeps the future Noche/duel/scripture moments desirable, and returns the player to the game without making permission management feel like the game itself.
