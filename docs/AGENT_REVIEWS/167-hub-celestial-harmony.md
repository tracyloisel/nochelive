# M167 — Hub Celestial Harmony

Reviewed: 2026-08-31
Slice: semantic Celestial Light/Dark materials, collision-safe Hero and accessible voyage rail
Tests: `bundle exec rails test test/system/hub_streaming_rails_visual_test.rb` — 2 runs, 1236 assertions, 0 failures; `bundle exec rails test test/system/hub_guest_states_visual_test.rb` — 2 runs, 486 assertions, 0 failures
Charter: `.agents/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: N/A — no quiz, score, reward or Live-night rule changed
UI: `.agents/skills/noche-ui/SKILL.md`
Art: `.agents/skills/noche-art/SKILL.md`
Hub theme: `.agents/skills/noche-hub-theme/SKILL.md`
Copy: N/A — no player-facing wording moved

## Feeling

The Hub should feel like entering one continuous sacred world: dawn in Celestial Light, moonlit depth in Celestial Dark, with a clear invitation to continue rather than a collection of opaque web cards.

## 1 — Game experience

The opening hierarchy remains immediate: player identity, the adventure to continue, one gold Play action, then the nearby social and community loop. The voyage dots make the Hero visibly plural without competing with the play action. The rail keeps forum, challenge, Live and local activity discoverable as distinct destinations; no new score, countdown or reward claim was invented for decoration.

## 2 — UI design

The same Hub markup now consumes a compact semantic material vocabulary. Light uses local pearl/ivory contrast panes with ink copy; Dark uses night-blue glass with cream copy and gold edges. Photo cards retain a local scrim only where copy needs it. The Hero clears the unchanged HUD at narrow widths, copy/action/leaderboard do not overlap, labels do not truncate at 320 px, and the dock compacts only inside the Hub.

Inactive Hero slides are `inert`, `aria-hidden`, and removed from keyboard focus. The dots retain 44 × 44 px targets, keep the selected state stable during smooth scrolling, and are the only visible carousel control. Reduced-motion behavior remains respected.

States checked: idle/current voyage, inactive voyage, keyboard dot navigation, hover/focus-visible card states, guest/empty Hub, no parish association, and no linked players.

## 3 — Art direction

Salt Lake remains a visible narrative subject rather than a wallpaper: Light preserves the sunrise, ivory temple and sky; Dark preserves the moonlit city and volumetric depth. The protected copy field is deliberately local, never a full-screen milk wash. Gold is confined to the metal signature, emphasis and primary action; Light headings remain ink, Dark headings remain cream.

## Theme engine

The Home is still one component tree. Theme-specific values are supplied through semantic Hub tokens, while the explicit Salt Lake Light/Dark artwork manifests select the world deterministically. The information architecture, dimensions and interactions remain shared; only the material, overlay and contrast change.

## Scores (/10)

| Dimension | /10 |
|---|---:|
| Fun | 9.1 |
| Clarté | 9.5 |
| Impact visuel | 9.4 |
| Feedback | 9.1 |
| Progression | 9.3 |
| Social | 9.1 |
| Immersion | 9.5 |
| Accessibilité | 9.6 |
| Cohérence NocheLive | 9.7 |
| Envie de continuer | 9.3 |

## Verdict

PASS

## What works

- One Light/Dark anatomy with artwork-led materials, not duplicated Homes.
- Salt Lake stays visible while local glass preserves readable copy.
- The Hero, CTA, leaderboard, voyage dots and dock coexist at 320 px without collision.
- The horizontal rail keeps card borders, focus rings and touch targets inside its viewport.
- Dead quick-action styling and overlapping, superseded Hub rules were removed after caller checks.

## What feels weak

- The strongest visual difference between worlds is intentionally material and lighting rather than layout; future artwork can make the narrative shift even more dramatic without changing the Hub contract.

## Required before approval

- None.

## Evidence

- Screenshots visually reviewed at 320 × 568, 390 × 844, 768 × 1024 and 1440 × 900 in Celestial Light and Celestial Dark, including guest/empty states.
- Salt Lake, Hero copy, CTA, live/social rail, installation card and priority section were checked for contrast, clipping and overlap.
- System assertions cover text visibility, collision-free layout, focus isolation for inactive slides and stable dot state after navigation.
- Console clean in the rendered visual matrix. No new permission or notification flow is present in this slice; the existing invitation flow was not altered.

## Night director

Yes. The player sees a world, a clear next action and a lively path beyond it in one glance, then can explore without visual friction.
