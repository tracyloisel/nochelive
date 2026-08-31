#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/v2-assets/overlays"
TYPEFACE="/System/Library/Fonts/Supplemental/DIN Condensed Bold.ttf"

mkdir -p "$OUT"

caption() {
  local file="$1"
  local words="$2"
  local size="$3"
  local y="$4"
  local color="$5"

  magick -size 1080x1920 xc:none \
    -font "$TYPEFACE" -pointsize "$size" -gravity North \
    -fill '#081321' -stroke '#081321' -strokewidth 8 -annotate "+0+$y" "$words" \
    -fill "$color" -stroke none -annotate "+0+$y" "$words" \
    -depth 8 "$file"
}

caption "$OUT/01-hook.png" '¿Y SI TU CLAMOR LLEGA?' 76 730 '#F5F6F3'
caption "$OUT/02-routes.png" 'SEIS RUTAS. UNA SEMANA.' 58 205 '#F5F6F3'
caption "$OUT/03-promise.png" 'UNA PROMESA EN SION' 58 205 '#F5F6F3'
caption "$OUT/04-gate-question.png" '¿QUIÉN ABRE LA PUERTA?' 76 205 '#F5F6F3'
caption "$OUT/05-house-question.png" '¿QUIÉN EDIFICA LA CASA?' 76 205 '#F5F6F3'
caption "$OUT/06-echo.png" 'EL ECO NO TERMINA' 58 205 '#F5F6F3'
caption "$OUT/07-song.png" 'EL CANTO QUEDA SUSPENDIDO' 58 205 '#F5F6F3'
caption "$OUT/08-known.png" '¿QUIÉN TE CONOCE?' 76 205 '#F5F6F3'
caption "$OUT/09-breath.png" 'TODO LO QUE RESPIRA' 76 205 '#F5F6F3'
caption "$OUT/10-mysteries.png" 'SEIS MISTERIOS. UNA RUTA.' 58 205 '#F5F6F3'

magick -size 1080x1920 xc:none \
  -fill 'rgba(8,19,33,0.94)' -stroke none -draw 'roundrectangle 90,630 990,1330 32,32' \
  -fill '#EDC56B' -stroke none -draw 'rectangle 125,680 955,682' \
  -fill '#17314D' -stroke '#526B85' -strokewidth 2 -draw 'roundrectangle 130,965 950,1051 18,18' \
  -fill '#17314D' -stroke '#526B85' -strokewidth 2 -draw 'roundrectangle 130,1070 950,1156 18,18' \
  -fill '#17314D' -stroke '#526B85' -strokewidth 2 -draw 'roundrectangle 130,1175 950,1261 18,18' \
  -font "$TYPEFACE" -gravity North \
  -pointsize 34 -fill '#EDC56B' -stroke none -annotate +0+705 'PREGUNTA 01' \
  -pointsize 62 -fill '#F5F6F3' -stroke '#081321' -strokewidth 4 -annotate +0+775 $'¿QUÉ PIDE EL\nAFLIGIDO?' \
  -pointsize 44 -fill '#F5F6F3' -stroke none -annotate +0+982 'SU CLAMOR' \
  -pointsize 44 -fill '#F5F6F3' -stroke none -annotate +0+1087 'UNA CORONA' \
  -pointsize 44 -fill '#F5F6F3' -stroke none -annotate +0+1192 'UN EJÉRCITO' \
  -depth 8 "$OUT/11-question-card.png"

magick -size 1080x1920 xc:none \
  -font "$TYPEFACE" -gravity North \
  -pointsize 82 -fill '#0D1A2C' -stroke '#EDC56B' -strokewidth 5 -annotate +0+410 $'DEL POLVO\nA LA ALABANZA' \
  -fill '#EDC56B' -stroke none -draw 'roundrectangle 120,1540 960,1652 28,28' \
  -pointsize 50 -fill '#0D1A2C' -stroke none -annotate +0+1560 'ABRE LA PRIMERA PISTA' \
  -depth 8 "$OUT/12-final.png"

printf 'Rendered overlays in %s\n' "$OUT"
