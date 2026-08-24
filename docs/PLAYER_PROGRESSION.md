# Player Progression

Night XP is **session-local**. Fichas and season ranks live on the **rama**.

A ficha is a `Person` in a `Ward`: usage name, chosen avatar, optional apellido (only when another person shares the given name), and a favorite year (not a date of birth). « Solo esta noche » skips the ficha.

## What a player becomes

```text
Novicio → Explorador → Guerrero → Consejero → Profeta → Leyenda
```

Team rise:

```text
Campamento → Tribu → Reino → Dinastía
```

If after round 10 the only change is a bigger number, progression has failed.

## XP sources (diverse skills)

| Source | Skill | Why |
|---|---|---|
| Correct answer | Knowledge | Carlos still matters |
| Fastest buzz | Speed | Lucía can beat an adult |
| Physical / rapid tap | Movement | Body skill, not trivia |
| Creative / mime / pose | Creativity | Different winners |
| Team all present | Teamwork | Remote + room together |
| Streak | Consistency | Visible heat |
| Comeback | Drama | Losing stays fun |
| Participation | Inclusion | Abuela María is never zero |

Knowledgeable adults must not automatically dominate.

## Temporary roles

```text
Rey        next correct ×2          ← shipped M12
Profeta    one clue
Guerrero   +1 physical attempt
Escriba    may submit the team answer
Mensajero  delivers a steal / secret mission
```

Rey is granted when a team crosses a rank. Same flag as the chest’s Corona del Rey. Spent on the next correct (a rank-up on that same score grants it again).

Do not build the rest of the RPG before a family has played the night.

## Streaks and comebacks

Show `RACHA ×3` when a team chains success.
If one team runs away, later nights need underdog bonus, steal, or higher-value finales.

M1 minimum: XP on score events, visible rank on the team, streak counter. Chest unlock is queued immediately after the buzz moment is real.

## Implemented

- Team XP from ScoreEvents
- Visible rank + bar toward the next rank
- Streak on correct, reset on miss
- Cofre de Salomón at 20 XP
- Rey on rank-up (next correct ×2)
- Rama fichas (avatar + apellido on homonym + año favorito de cuatro cifras)
- Presenter ficha desk (edit, merge, reveal year)
- Night roster + named missionaries remembered with the night
- WardTeam season XP applied once when the night closes (thresholds ×4)
