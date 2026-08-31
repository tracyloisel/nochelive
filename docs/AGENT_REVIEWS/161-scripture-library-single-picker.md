# M161 — Bibliothèque des Écritures, sélecteur unique plein écran

Reviewed: 2026-08-31
Slice: one personal reading decision from the first glance to the reader or Circle; supersedes M158 after user review
Tests: focused controller, service, locale, routing, system and visual suites — green
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.agents/skills/noche-night/SKILL.md`
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Copy: `.agents/skills/noche-i18n/SKILL.md` — es, pt-BR, en, fr present and validated

## Feeling

An immediate invitation to read, not a feature index. In one glance the player should feel the scale of the scriptures, know the next useful action, and trust that every other reading choice remains one tap away.

## 1 — Game experience

The rushed-player loop is: see the unfinished chapter or first honest start → act once → choose a concrete passage in place or enter the reader → return exactly to the choice that launched it → continue or join Circle. There is no detour through a programme, history or community screen. The seven intentions are distinct: continue, recommendation, this week, bookmarks, canon, Rama and annual programme. The lone primary action is gold; for a visitor with no progress it becomes the equally clear **Parcourir**, never an empty dashboard.

## 2 — UI design

The two-second verb is **Continuer** for a reader and **Parcourir** for a new visitor. The image is the complete first viewport; the copy, search and action sit on dark local glass. Selection opens inline, moves focus to its heading without an animated wait, and has no duplicate-page cross-fade. Passage links exit only to the reader; Rama exits only to Circle. Search keeps books inline and opens exact references in the reader. Keyboard choice, close/focus return, loading, error, empty, disabled Rama, reduced motion and forced colors are covered. At 390×844, 768×1024 and 1440×900, all tested targets are at least 44 px and horizontal overflow is at most 1 px.

## 3 — Art direction

Celestial Dark comes from one full-bleed Psalms refuge world: a solitary robed reader, a cave, storm depth and a single gold shaft of light. The composition reserves the left field for ivory type while the figure holds the right-side story. Gold is limited to the primary action, fine rules, progress and small emblems; it never competes with the light beam or becomes headline ink. The reader is deliberately a quiet ivory destination, so opening it feels like passing through the world rather than switching products.

Artwork production: the existing Psalms refuge master was outpainted with image generation into a responsive wide scene, using the prompt: “Extend this source into a premium 16:9 full-bleed environment; preserve the solitary robed figure, cave and gold beam; leave left negative space; no text, logos or new people.” Output master: `media/masters/media/study/psalms-refuge-library-wide-v2.png`; manifest key: `scripture.library.psalms-refuge`; responsive derivatives were generated through the media pipeline.

## Theme engine (hub `/` only, or N/A)

N/A — this is a dedicated Celestial Dark scripture surface, not a Hub theme fork or user toggle.

## Four seats

N/A — personal street surface. Who: the current reader. Where: their living scripture library. What now: resume, start, or choose a passage. Around me: verified weekly completion and the separate Rama Circle only when it is truly available.

## Tension

Quiet momentum rather than competition: unfinished place → one clear reading → the week’s passages → a larger annual horizon. Search turns an intent into a chapter without breaking this rhythm.

## Finale

N/A. This surface begins and resumes reading; it does not claim a live-night finale.

## Languages

Copy read in **es**, **pt-BR**, **en**, **fr**. The selection, unavailable Rama state, search and all five library panels are localized; locale and YAML validation are green.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 8.6 |
| Clarté | 9.7 |
| Impact visuel | 9.4 |
| Feedback | 9.1 |
| Progression | 9.0 |
| Social | 8.5 |
| Immersion | 9.5 |
| Accessibilité | 9.3 |
| Cohérence NocheLive | 9.5 |
| Envie de continuer | 9.2 |

## Verdict

PASS

## What works

- One world fills the opening viewport at every production size; the illustration is no longer a card or a partial strip.
- Every reading choice lives on the same screen, with one precise inline result rather than parallel destination pages.
- Legacy GET URLs preserve bookmarked and shared entry points by redirecting to the equivalent library state or Circle; the quiz journey remains intentionally separate.
- A reader can open a chapter with keyboard or touch, stays inside the reader dialog while tabbing, and lands back on the initiating row or search field on close.
- The visitor state remains decisive: it has a real first action, not fabricated progress or a disabled primary path.
- Exact verse validation is immediate and local for all 82 books / 1,566 chapters: an impossible reference is stopped before the reader is opened, with no network-dependent pause.
- The inline panel can be dismissed by its visible control or Escape; its paginated choices append in place, and a failed Turbo request clears its loading state and explains what happened.

## What feels weak

- No blocking weakness remains. Editorial teams can enrich a future weekly theme, but the fallback continues to show published facts rather than invented copy.

## Required before approval

- None.

## Evidence

- Inspected screenshots: `tmp/street-shots/scripture-library/library-390x844.png`, `library-768x1024.png`, `library-1440x900.png`, plus the three `library-weekly-*` captures.
- Browser path inspected manually: Library → This week → Psalms 49 → reader → close → initiating passage; console reported no JavaScript errors.
- Final browser regression: at 390×844, 768×1024 and 1440×900 the hero equals the viewport height and the document has no horizontal scroll range; weekly selection closes by Escape and restores focus to `#cette-semaine`; `Jean 3:36` opens the reader and returns focus to the search field on close.
- Final focused pass — `env LIBRARY_SCREENSHOTS=1 bundle exec rails test` across visual library, reader-Escape, library controller, selection, resolver, legacy journey/Circle navigation, locale, media, helper and frontend-loading suites: **66 runs, 1,096 assertions, 0 failures**.
- `bundle exec rails zeitwerk:check`, syntax checks for the three changed controllers and `git diff --check` are green.
- Search, legacy redirects, inbound links, Circle exit, no-JavaScript deep links, keyboard/focus restoration and the four locales are covered by the focused suites.

## Night director

Yes. The opening does not ask the player to manage a library; it puts a meaningful reading in their hand, then makes every alternative feel one decisive tap away.
