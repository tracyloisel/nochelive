# 061 — Street jugar HUD: crown, combo, fly score

Reviewed: 2026-08-27
Slice: `/jugar` overlay HUD only. Question sheet untouched. `Quizzes::Submit` / `Advance` / `Tally` unchanged (combo does **not** multiply points).
Tests: `Quizzes::HitStreak` + jugar overlay controllers + i18n + ui_chrome
Charter: `.cursor/skills/noche-conseil/SKILL.md` (PRIORITY)
Experience: `.cursor/skills/noche-night/SKILL.md`
UI: `.cursor/skills/noche-ui/SKILL.md`
Art: `.cursor/skills/noche-art/SKILL.md`
Hub theme: N/A (jugar, pas `/`)
Copy: `.cursor/skills/noche-i18n/SKILL.md` — `quiz.combo`, `quiz.on_fire` en es / pt-BR / en / fr

## Feeling

Fierté de **protéger une série**. Clarté : les points que je viens de gagner **arrivent** sur la couronne. Tension douce avant le tap suivant (🔥3 est encore là). Pas « lire un +8 collé au score ».

## 1 — Game experience

Boucle : tap → Bravo +N dans la scène → traînée dorée → couronne 34→42 (glow) → 🔥 monte et **reste** au Suivant. Une miss remet 🔥 à 0. Paliers 1 / 2 / 3 (En feu !) / 5 (flamme vive) / 10 (chest). Économie du score inchangée.

## 2 — UI design

Même capsule : avatar · nom / rang / niveau · pack / n/10 / dots · 👑 score · 🔥 combo · ☰ dans le verre. Light ivoire / Dark navy-glass, même anatomie. +N n’est plus imprimé à côté du score. Hamburger sans disque séparé.

États : idle 🔥0, spark, glow, hot, blaze, legend, break, land (couronne).

## 3 — Art direction

Or = couronne + traînée + CTA. Feu = `--fire`. Shout « En feu ! » crème sur la scène, très bref. Light : HUD ivoire, shout ivoire/ink. Dark : verre nuit, shout crème.

## Four seats

Street — un siège (tú). N/A live.

## Tension

La série à protéger entre les questions. Pas un multiplicateur.

## Finale

N/A (pack street). Q10 légende = chest overlay, pas royal_fanfare (cérémonie inchangée).

## Languages

- es: Racha / ¡En llamas!
- pt-BR: Sequência / Pegando fogo!
- en: Streak / On fire!
- fr: Série / En feu !

noche-i18n: PASS

## Scores (/10)

| Dimension | /10 |
|---|---|
| Fun | 8.5 |
| Clarté | 8.6 |
| Impact visuel | 8.3 |
| Feedback | 8.6 |
| Progression | 8.5 |
| Social | 8 |
| Immersion | 8.3 |
| Accessibilité | 8.2 |
| Cohérence NocheLive | 8.5 |
| Envie de continuer | 8.6 |

## Verdict

**PASS WITH NOTES** — systèmes HUD lisibles, combo réel, vol de points. Sheet question non touchée. `celestial_breath` stand-in toujours là. Jouer ~20 questions pour valider le rythme tap→vol→Suivant.

## What works

- +N quitte la scène et atterrit sur 👑.
- 🔥 survit au Suivant ; miss = 0.
- Anatomie identique Light / Dark.

## What feels weak

- 4 choix : sheet encore haute.
- Souffle d’entrée toujours un stand-in.
- Vol +N ~800 ms : Suivant est déjà là (voulu), le cerveau peut zapper le land si on tape trop vite.

## Required before approval

- Jouer un pack (et plus) les yeux hors du code.
- `street_quiz_visual_test` vert.

## Evidence (optional)

Joué Sœurs (Light, 1 miss après 🔥3) puis Abish (10 hits → 🔥10 legend). Vol : `+N` de scène disparaît, flyer unique, couronne tween. Ask suivante : 🔥 survit. Dark Q9 Abish : même anatomie.

## Night director

Oui, je relance pour voir si 🔥4 tient. Je ne toucherais plus à la question tant que le vol et la série se lisent au premier coup d’œil.
