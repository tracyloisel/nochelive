# 037 — Hub drops the five-tab dock

Reviewed: 2026-08-26
Slice: Street hub `/` and liga `/liga` no longer show the five-icon bottom nav (Hub · Tienda · Ranking · Amigos · Perfil). Gold Jugar stays. Ranking, history, and play stay in the hamburger; profile stays the avatar; invite stays on the rival rail.
Tests: `test/controllers/street_hub_controller_test.rb`, `test/controllers/street_leaderboards_controller_test.rb`, `test/system/street_quiz_visual_test.rb`, `test/i18n/locale_files_test.rb`
Gate: `.cursor/skills/noche-ui/SKILL.md` (street chrome, not a night seat)
Copy: removed unused `street.nav_label` / `nav_shop` / `nav_friends` / `nav_profile` / `nav_shop_soon` in es, pt-BR, en, fr. `nav_hub` and `nav_ranking` stay for the drawer.

## Four seats

N/A (street pack).

## Tension

N/A.

## Finale

Unchanged.

## Languages

noche-i18n: PASS — no new copy; dead dock labels removed in all four locales.

## Verdict

PASS

## What works

- Hub first fold is map + liga + Jugar. No dummy Tienda tab.
- Liga is a paper board, not a second dock.
- Destinations that existed (ranking, profile, invite) still have a door.

## What feels weak

- Temple hub mockup still paints a 5-tab bar. Product KEEP is no dock.

## Required before approval

- None.

## Night director

Would I play another round? Yes — the gold Jugar is the verb; the five stubs were chrome noise.
