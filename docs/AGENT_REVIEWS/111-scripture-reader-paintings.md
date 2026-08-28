# M111 — Passage paintings in the scripture reader

Reviewed: 2026-08-28
Slice: the chapter reader and its indexable public chapter page
Tests: `bin/rails test test/services/scriptures/illustrations_test.rb test/controllers/scriptures_controller_test.rb` — 12 runs, 84 assertions, 0 failures; `bin/rails test test/i18n/locale_files_test.rb` — 8 runs, 150 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: N/A
Copy: `.agents/skills/noche-i18n/SKILL.md` — existing quiz questions and answers reused through localized `copy`; es, pt-BR, en, fr parity green

## Feeling

Wonder and recognition: the reader should suddenly see the scene it has been describing, then want to continue through the chapter.

## 1 — Game experience

The loop is quiet but real: read → recognize the illustrated moment → receive a short localized meaning → continue reading. Paintings are anchored after their actual verses. Chapters with many eligible images are deliberately reduced to three scenes spread across the text, preventing the reader from becoming a gallery or an interruption pile.

## 2 — UI design

The verb remains **read**. Images need no extra control or administrative choice. They reserve their aspect ratio before loading, use native lazy loading, and carry a localized alt plus caption. In the in-game reader they run to the edges of the reading chamber; on the public chapter page they stay a centered painting inside the readable column.

States: no artwork = unchanged reader; loading = reserved frame without layout shift; available = painting + citation + caption; missing/unsafe media = silently omitted; dense chapter = at most three editorial beats.

## 3 — Art direction

The emotion is reverent wonder. The biblical artwork becomes the décor for one beat, while the surrounding reader remains Celestial Light paper. Gold is limited to the hairline and citation; body copy stays ink. No tall milky veil is added over the painting and no headline competes with it.

## Theme engine

N/A — this is a quiet reading chamber, not the hub.

## Four seats

N/A — scripture reading surface.

## Tension

No game-show tension is appropriate. Rhythm comes from a scarce visual reveal after a meaningful verse, followed immediately by the next scripture text.

## Finale

N/A.

## Languages

No new sentence was introduced. Illustration alt and caption reuse the localized street-quiz question and answer. The citation is composed from the chapter title returned in the active scripture locale. Four-language parity test: PASS.

`noche-i18n`: PASS — es / pt-BR / fr / en remain native because the reader consumes the same reviewed copy as the source question.

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8 |
| Clarté | 10 |
| Impact visuel | 9 |
| Feedback | 8 |
| Progression | 8 |
| Social | 8 |
| Immersion | 10 |
| Accessibilité | 9 |
| Cohérence NocheLive | 9 |
| Envie de continuer | 9 |

## Verdict

PASS

## What works

- Existing quiz metadata becomes a zero-maintenance semantic illustration index.
- The scene appears at the verse it belongs to in both reader surfaces.
- Public chapter pages expose the first painting through Open Graph and schema.org `primaryImageOfPage`.
- Missing, unsafe, duplicate, and over-dense artwork cases fail quietly without harming scripture access.

## What feels weak

- The source collection mixes some painterly and more animated illustration styles; a future art pass can curate individual replacements without changing reader code.

## Required before approval

- None.

## Evidence

Mobile visual check at 390 × 844 on the public French chapter and the full-screen in-game reader. 1 Samuel 16 inserts scenes after verses 13 and 23 without console errors.

## Night director

Yes: the image pays off the reading without turning scripture into another quiz, and the next verse remains the obvious next action.
