#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ASSETS="$ROOT/v2-assets"
WORK="$ROOT/v2-build"
SFX="$(cd "$ROOT/../../../../public/sfx" && pwd)"
OUT="$ROOT/del-polvo-a-la-alabanza-v2-trailer-es.mp4"

mkdir -p "$WORK"

# Hard cuts are intentional: the pacing is a study-trailer hook, not a calm slideshow.
ffmpeg -n -hide_banner -loglevel error -loop 1 -framerate 30 -i "$ASSETS/01-harp-and-ash.png" -t 2.4 \
  -vf "scale=1280:-2,crop=1080:1920:x='(in_w-out_w)/2+18*sin(t*0.8)':y='(in_h-out_h)/2+12*cos(t*0.6)',eq=contrast=1.08:saturation=1.04" \
  -r 30 -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -an "$WORK/01-hook.mp4"

ffmpeg -n -hide_banner -loglevel error -loop 1 -framerate 30 -i "$ASSETS/02-gate-and-path.png" -t 2.8 \
  -vf "scale=1280:-2,crop=1080:1920:x='(in_w-out_w)/2':y='(in_h-out_h)/2-30*sin(t*0.45)',eq=contrast=1.06:saturation=1.03" \
  -r 30 -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -an "$WORK/02-gate.mp4"

ffmpeg -n -hide_banner -loglevel error -loop 1 -framerate 30 -i "$ASSETS/03-house-and-path.png" -t 3.2 \
  -vf "scale=1280:-2,crop=1080:1920:x='(in_w-out_w)/2-25*sin(t*0.35)':y='(in_h-out_h)/2+20*cos(t*0.35)',eq=contrast=1.05:saturation=1.04" \
  -r 30 -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -an "$WORK/03-house.mp4"

ffmpeg -n -hide_banner -loglevel error -loop 1 -framerate 30 -i "$ASSETS/01-harp-and-ash.png" -t 2.2 \
  -vf "scale=1280:-2,crop=1080:1920:x='(in_w-out_w)/2-45*sin(t*0.6)':y='(in_h-out_h)/2+45*sin(t*0.3)',eq=contrast=1.12:saturation=0.92" \
  -r 30 -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -an "$WORK/04-river.mp4"

ffmpeg -n -hide_banner -loglevel error -loop 1 -framerate 30 -i "$ASSETS/04-six-lights.png" -t 10.4 \
  -vf "scale=1280:-2,crop=1080:1920:x='(in_w-out_w)/2+30*sin(t*0.22)':y='(in_h-out_h)/2-35*sin(t*0.16)',eq=contrast=1.04:saturation=1.05" \
  -r 30 -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -an "$WORK/05-route.mp4"

ffmpeg -n -hide_banner -loglevel error \
  -i "$WORK/01-hook.mp4" -i "$WORK/02-gate.mp4" -i "$WORK/03-house.mp4" -i "$WORK/04-river.mp4" -i "$WORK/05-route.mp4" \
  -filter_complex "[0:v][1:v][2:v][3:v][4:v]concat=n=5:v=1:a=0[base]" -map "[base]" \
  -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -an "$WORK/base.mp4"

# The final card shows one real expedition question without giving its answer.
bash "$ROOT/render-del-polvo-v2-overlays.sh"
OVERLAYS="$ROOT/v2-assets/overlays"
ffmpeg -n -hide_banner -loglevel error -i "$WORK/base.mp4" \
  -loop 1 -framerate 30 -i "$OVERLAYS/01-hook.png" \
  -loop 1 -framerate 30 -i "$OVERLAYS/02-routes.png" \
  -loop 1 -framerate 30 -i "$OVERLAYS/03-promise.png" \
  -loop 1 -framerate 30 -i "$OVERLAYS/04-gate-question.png" \
  -loop 1 -framerate 30 -i "$OVERLAYS/05-house-question.png" \
  -loop 1 -framerate 30 -i "$OVERLAYS/06-echo.png" \
  -loop 1 -framerate 30 -i "$OVERLAYS/07-song.png" \
  -loop 1 -framerate 30 -i "$OVERLAYS/08-known.png" \
  -loop 1 -framerate 30 -i "$OVERLAYS/09-breath.png" \
  -loop 1 -framerate 30 -i "$OVERLAYS/10-mysteries.png" \
  -loop 1 -framerate 30 -i "$OVERLAYS/11-question-card.png" \
  -loop 1 -framerate 30 -i "$OVERLAYS/12-final.png" \
  -filter_complex "[0:v][1:v]overlay=0:0:enable='between(t,0.00,1.15)'[v1];[v1][2:v]overlay=0:0:enable='between(t,1.15,2.40)'[v2];[v2][3:v]overlay=0:0:enable='between(t,2.40,3.65)'[v3];[v3][4:v]overlay=0:0:enable='between(t,3.65,5.20)'[v4];[v4][5:v]overlay=0:0:enable='between(t,5.20,6.80)'[v5];[v5][6:v]overlay=0:0:enable='between(t,6.80,8.35)'[v6];[v6][7:v]overlay=0:0:enable='between(t,8.35,10.55)'[v7];[v7][8:v]overlay=0:0:enable='between(t,10.55,12.80)'[v8];[v8][9:v]overlay=0:0:enable='between(t,12.80,15.15)'[v9];[v9][10:v]overlay=0:0:enable='between(t,15.15,16.90)'[v10];[v10][11:v]overlay=0:0:enable='between(t,16.90,19.05)'[v11];[v11][12:v]overlay=0:0:enable='between(t,19.05,21.00)'[v12]" \
  -map "[v12]" -t 21 -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -an "$WORK/picture.mp4"

ffmpeg -n -hide_banner -loglevel error -i "$WORK/picture.mp4" \
  -i "$SFX/timer_tension.mp3" -i "$SFX/round_open.mp3" -i "$SFX/dramatic_fire.mp3" -i "$SFX/round_lock.mp3" -i "$SFX/reveal.mp3" -i "$SFX/fire_whoosh.mp3" -i "$SFX/royal_fanfare.mp3" \
  -filter_complex "[1:a]atrim=0:21,volume=0.14,afade=t=out:st=19.8:d=1.2[bed];[2:a]volume=0.70,adelay=0:all=1[open];[3:a]volume=0.62,adelay=3150:all=1[fire];[4:a]volume=0.70,adelay=7200:all=1[lock];[5:a]volume=0.70,adelay=11700:all=1[reveal];[6:a]volume=0.62,adelay=14800:all=1[whoosh];[7:a]volume=0.74,adelay=17050:all=1[fanfare];[bed][open][fire][lock][reveal][whoosh][fanfare]amix=inputs=7:duration=first:normalize=0,alimiter=limit=0.95[a]" \
  -map 0:v -map "[a]" -t 21 -c:v copy -c:a aac -b:a 192k -movflags +faststart "$OUT"

printf 'Rendered %s\n' "$OUT"
