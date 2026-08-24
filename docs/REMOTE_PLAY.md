# Remote Play

Remote players are **players**. If Daniel only watches and taps OK, the round is not shippable.

## Grade scale

```text
A — equivalent or better
B — different but equally fun
C — playable but inferior
D — spectator only
F — impossible
```

Production requirement: **A or B** for interactive rounds. A few deliberate spectator beats are allowed.

## Question every round must answer

> What does the person at home DO?

## Intended first-game grades

| Round | Room | Remote | Grade target |
|---|---|---|---|
| Salomón (buzzer) | Buzz + answer | Same buzz + answer | A |
| Multiple choice / true-false | Tap choice | Same tap | A |
| David vs Goliat | Throw foam stones | Hold-to-aim / rapid tap skill | B |
| Freeze dance | Freeze in the room | Freeze the on-screen figure | B |
| Mime / statue | Body in the room | Guess or recreate on phone | B |
| Drawing | Shared paper | Draw on device | B |
| Finale | Room ritual + phones | Same stakes, adapted input | B |

Rejected remote pattern:

```text
Press OK when the room is finished.
```

## Implemented

- Buzzer: Grade A
- David: Grade B (rapid tap / sling)
- Estatua de David: Grade B (hold 8s at home; body in the room)
- Jonás: Grade B (live the story at home — storm, fish, shore; mime in the room). He does not guess the room.
- Palabras prohibidas: Grade B (type a guess at home; shout in the room). A miss does not auto-incorrect.
- El arpa de David: Grade B (hunt something that sounds at home; hunt in the room). Claim does not auto-score.
- El orden de los reyes: Grade A (same shuffled names, same tap sequence, same auto-score)
- La danza de David: Grade B (freeze the body in the room; catch the figure at home in 2s). Early tap is ignored.
- La noche de los profetas: Grade A (same stand-up, same crown slam, same ceremony)
- Nombres de profetas: Grade B (shout in the room; type three names at home). A short list does not auto-incorrect.
- El juicio de Salomón: Grade A (same emblem tap, cannot vote yourself, same tally)

## Implemented in M1

Join asks sala vs casa. Buzzer is Grade A. David uses a 10-tap sling (Grade B). Spectator is opt-in.

## M1 remote contract

The first buzzer is Grade A: Daniel holds the same giant button, races the same lock, sees the same place, and can submit the team answer if he is on a team.

Spectator mode is a separate, deliberate D-grade seat — only for people who chose *Ver*.
