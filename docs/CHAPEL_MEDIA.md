# Chapel / meetinghouse media

Noche Live nights often happen in an LDS **meetinghouse**. Movement does **not** belong in the chapel pews.

| Room | Use |
|---|---|
| Chapel (pews, stand, piano) | Seated rounds: buzz, choices, taboo, vote |
| Cultural hall (wood floor, stage curtain, folding chairs) | David, statue, mime, freeze, harp hunt |
| Temple | Never. Do not generate or depict. |

## Generate with OpenRouter

Export your key, then run stills first (cheap, TV-ready):

```bash
export OPENROUTER_API_KEY=sk-or-...

# Hero movement verbs, slideshow only
ruby script/generate_chapel_media.rb --mode slides --only david_goliath,statue_david,scavenger_harp,taboo_nabot,mime_jonah

# Optional 5s clips (costs more)
ruby script/generate_chapel_media.rb --mode video --only scavenger_harp,statue_david
```

Defaults:

- Image: `black-forest-labs/flux.2-flex` (`OPENROUTER_IMAGE_MODEL`)
- Video: `bytedance/seedance-2.0-mini`, 5s, 720p, 16:9, no audio (`OPENROUTER_VIDEO_MODEL`)

Files land in `public/media/challenges/<round_id>/slides/01.jpg` and `clip.mp4`. The watch TV uses them when present; phones keep the SVG marks if media is missing.

## Marks (emblems, icons, avatars)

```bash
ruby script/generate_marks.rb
ruby script/generate_marks.rb --only avatars --force
```

Files: `public/marks/emblems`, `public/marks/icons`, `public/marks/avatars`. SVG fallbacks stay if a file is missing.

## Prompts

- World lock: `config/media/chapel_world.yml`
- Per-round shots: `config/media/chapel_challenges.yml`

No readable game UI in the picture. No crucifix. No temple interiors.
