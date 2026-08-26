# 052 — Jugar rival chip: one ghost, live, N others

Reviewed: 2026-08-26
Slice: street jugar still overlay — chase one rival, green live dot, `+N más` from the board count already on `Quizzes::Leaderboard`
Tests: `bin/rails test test/services/quizzes/rival_test.rb test/controllers/street_plays_controller_test.rb test/i18n/locale_files_test.rb`
Gate: street pack — `.cursor/skills/noche-night/SKILL.md`
Copy: `.cursor/skills/noche-i18n/SKILL.md` — `street.shot_rival` / `shot_rival_more` in four locales
UI: `.cursor/skills/noche-ui/SKILL.md` — rival chip + score pill share `3.9rem`; live dot matches liga

## Four seats

N/A (street). Jugar job: see who you are chasing on this still, whether she is online, and that the rama is bigger than one name.

## Tension

N/A.

## Finale

N/A.

## Languages

noche-i18n: **PASS**
- es — A alcanzar: Carmen. +N más. Tú path.
- pt-BR — Pra alcançar. +N outro / outros.
- fr — À rattraper : Carmen. +N autre / autres. Tu.
- en — To catch: Carmen. +N more. Family, not CMS.

## Verdict

PASS WITH NOTES

## What works

- One chip even with a crowded board: the person immediately above you (or the next name if you lead).
- `+N más` reuses `board.players` — no extra SQL.
- Green `.street-live-dot` when that person’s device is in the 25s live window, same as liga.
- Score pill on the still is as tall as the chip (`3.9rem`), larger type, not a shrunk Carmen.

## What feels weak

- `+99 más` is honest but quiet. The liga remains the place to scan a hundred faces.
- The chip still does not say “rival” in the visible type (aria does). Name + gap + others has to carry the job.

## Required before approval

- None.

## Evidence (optional)

UI: still overlay, not a directory. Gold stays the gap pts; cream type for the others count; green for live.

## Night director

Would I play another pack? Yes — Carmen is the ghost to catch, not a mystery badge.
