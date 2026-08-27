# Game Vision — Noche Live

Noche Live is a **premium mobile video game**: biblical adventure, live game show, and parish community — not a webapp with game décor.

People in the room and people at home play the **same night**. Chapel phones are controllers. The TV tells. Remote players play *with* them.

It is not a quiz app with a church skin.
It is not a livestream with a few buttons.
It is not a SaaS dashboard.
It is a **shared adventure** where teams shout, buzz, move, guess, and come back from behind.

**Décor tells the story. UI adapts.** Celestial Light or Celestial Dark follows the artwork and the moment — never a user theme toggle. Gold is the signature. Charter: `.cursor/skills/noche-conseil/SKILL.md` (**PRIORITY**). Hub worlds: `.cursor/skills/noche-hub-theme/SKILL.md`.

## The feeling we protect

A good night feels like this:

```text
WELCOME → CURIOSITY → EASY SUCCESS → COMPETITION
→ LAUGHTER → SURPRISE → RIVALRY → POWER-UP
→ COMEBACK → CHAOS → BIG FINAL → CELEBRATION
```

A player should want another round. Not because the software worked, but because something happened between humans.

## What players remember

Optimize for memories, not features:

- Abuela María buzzed first and the room exploded.
- David's stone hit Goliath on the last tap.
- The remote team opened a chest and stole the crown.
- Everyone had to put the phone down and become a statue.

Never optimize for: "the leaderboard updated."

## Player-first test

After every slice:

> What must the player **feel** here? What will they remember?

If the honest answer is “they can access the feature,” a UI, or a database event, the slice is not done.

## Personas (must all work)

| Persona | Need |
|---|---|
| Lucía, 8 | Big taps, movement, almost no Bible knowledge required |
| Carlos, 17 | Real competition, skill, a chance to win |
| Abuela María, 67 | Huge buttons, short text, present in the room |
| Daniel, 35, remote | A real activity, never a spectator with a confirmation button |
| Presentador | One obvious next action while 15 people talk around him |

A design that only works for Carlos fails.

## Non-negotiables

- PostgreSQL is authoritative. Browsers never decide winners.
- Remote play is A or B (equivalent, or different but equally fun).
- Rewards are free, earned, family-safe. Never monetized.
- Knowledgeable adults must not automatically dominate children. Reward speed, movement, creativity, teamwork, luck, and observation — not only trivia.
- Session-local progression is enough for v1.

## Current north-star slice

A family can buzz, throw at Goliath, become a statue, mime Jonah (or live the storm at home), almost say Jezabel, run for a pot that sounds like a harp, tap the kings in time, freeze when the music stops, shout prophet names, judge who showed wisdom, stand for the last word, rise to Rey, and hear a child’s name on the wall. The night is playable end to end. The next memory is a playtest.

Shipping charter: `.cursor/skills/noche-conseil/SKILL.md` (Experience → UI → Art; any score **< 8/10** is rework). Written verdicts: `docs/AGENT_REVIEWS/`. The 15-category table in `docs/GAME_QUALITY.md` is history, not the gate.
