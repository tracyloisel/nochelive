const WARN_RATIO = 0.4
const HOT_RATIO = 0.2

export function countdownProjection({ endAt, now, durationSeconds = 0, ask = false }) {
  const remainMs = Math.max(0, endAt - now)
  const rawSeconds = Math.ceil(remainMs / 1_000)
  const seconds = ask && durationSeconds > 0 ? Math.min(durationSeconds, rawSeconds) : rawSeconds
  const ratio = durationSeconds > 0 ? Math.min(1, remainMs / (durationSeconds * 1_000)) : 0

  let warn = false
  let hot = false
  if (ask && durationSeconds > 0 && seconds > 0) {
    hot = seconds <= durationSeconds * HOT_RATIO
    warn = !hot && seconds <= durationSeconds * WARN_RATIO
  } else if (!ask) {
    warn = seconds > 10 && seconds <= 20
    hot = seconds > 0 && seconds <= 10
  }

  return Object.freeze({ remainMs, seconds, ratio, warn, hot, expired: remainMs <= 0 })
}

export function nextSecondDelay(remainMs) {
  if (remainMs <= 0) return 0
  const remainder = remainMs % 1_000
  return Math.max(16, (remainder || 1_000) + 8)
}
