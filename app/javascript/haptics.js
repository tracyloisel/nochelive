const PATTERNS = {
  tap: 12,
  success: [ 16, 40, 28 ],
  miss: [ 10, 40, 10 ],
  streakBreak: [ 24, 55, 12 ],
  reward: [ 18, 50, 24, 50, 36 ],
  blaze: [ 20, 40, 22, 40, 32, 50, 40 ],
  legend: [ 24, 40, 18, 40, 28, 50, 36, 60, 48 ]
}

export function haptic(kind) {
  if (!navigator.vibrate) return
  if (navigator.userActivation && !navigator.userActivation.hasBeenActive) return
  const pattern = PATTERNS[kind]
  if (pattern == null) return
  try {
    navigator.vibrate(pattern)
  } catch (_error) {}
}
