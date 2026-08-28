# 110 — Parable collection

Reviewed: 2026-08-28
Slice: seven street packs, seventy questions, one rising solo loop
Tests: `bin/rails test` — 881 runs, 14,205 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: existing street-quiz board and HUD
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A — catalog content only
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr valid and validated

## Feeling

Curiosity becomes recognition, then reflection, mercy and the desire to act. The player should feel that each image from scripture opens into a personal choice, not merely a remembered fact.

## 1 — Game experience

Seven packs cover five families of Jesus's parables, unique Book of Mormon allegories, and prophetic parables from the Old Testament. Each pack follows the street curve: three untimed discoveries, three timed comprehension questions, three harder interpretation beats, then a 25-point synthesis slam. The loop remains question → choice → suspense → answer and short teaching → points and progress → next image.

## 2 — UI design

No new chrome was required. Every question uses the existing one-hand street board, three short choices, explicit timed state from question four onward, result feedback, scripture study link and visible pack progression. Titles and answers were kept compact enough for small phones and older players.

## 3 — Art direction

All seventy required paths exist and have explicit Celestial Light/Dark, atmosphere and glass tokens in `quiz_stills.yml`. Because OpenRouter returned `402 Insufficient credits`, the playable fallback set remasters existing Noche gouaches instead of leaving broken media. Seventy scene-specific final prompts are stored beside the manifest so the definitive 9:16 gouaches can replace the fallbacks without changing content or paths.

## Theme engine

N/A. The still decides Light/Dark through `Quizzes::Chrome`; there is no player theme toggle.

## Four seats

N/A — street seat only. The player always sees who they are, the current question, the rising score and what to do next.

## Tension

Questions 1–3 welcome without a clock. Questions 4–6 introduce 20-second pressure. Questions 7–9 tighten to 15 seconds and move from recall to meaning. Question 10 is always the thematic synthesis at 25 points. This avoids ten flat recall cards.

## Finale

Every pack closes on meaning rather than trivia: heaven's joy, the value of the Kingdom, mercy received and given, faithful service, humility, God's love, or prophetic warning. The slam is worth five times the opening question.

## Languages

- es — warm, direct source copy for one street player.
- pt-BR — native Brazilian vocabulary and rhythm; no Spanish or European Portuguese leftovers.
- fr — natural French, `tu` for the solo seat, with French punctuation spacing.
- en — warm family scripture-night voice, not formal quiz-show copy.

The three translation trees contain the same 371 keys.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8 |
| Clarté | 9 |
| Impact visuel | 8 |
| Feedback | 9 |
| Progression | 9 |
| Social | 8 |
| Immersion | 8 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS WITH NOTES

## What works

- The seven packs are editorially distinct and avoid duplicating Jesus's biblical teaching inside the Book of Mormon collection.
- Recall, meaning and application alternate inside the same fixed QCM mechanic.
- Scripture references, media paths, language keys and category taxonomy are mechanically validated.

## What feels weak

- The local fallback stills preserve style and playability but are less narratively exact than the prepared final prompts.

## Required before approval

- None for functional content approval.
- Restore OpenRouter image credit and rerun `ruby script/generate_quiz_media.rb --only perdido_encontrado,secretos_reino,amar_projimo,velar_servir,sobre_roca,simbolos_mormon,parabolas_profetas --force` for the final original-art pass.

## Night director

Yes. Each pack ends by asking what the story means, and the next pack changes emotional color rather than repeating the same biblical-fact rhythm.
