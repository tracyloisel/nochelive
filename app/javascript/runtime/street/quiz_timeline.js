const FULL_MOTION = Object.freeze({
  ask: Object.freeze({ reveal: 0, cue: 80, unlock: 380 }),
  result: Object.freeze({ feedback: 100, bars: 180, reward: 300, actions: 1240 }),
  ceremony: Object.freeze({ fanfare: 140, reward: 700, chest: 1180, chestOpen: 1360, content: 2000, done: 2500 })
})

const REDUCED_MOTION = Object.freeze({
  ask: Object.freeze({ reveal: 0, cue: 0, unlock: 0 }),
  result: Object.freeze({ feedback: 0, bars: 0, reward: 0, actions: 0 }),
  ceremony: Object.freeze({ fanfare: 0, reward: 0, chest: 0, chestOpen: 0, content: 0, done: 0 })
})

const DUEL_RACE_MOTION = Object.freeze({
  intro: Object.freeze({ reveal: 80, compact: 3000 }),
  event: Object.freeze({ reveal: 420, compact: 3800 })
})

const DUEL_RACE_REDUCED = Object.freeze({ reveal: 0, compact: 0 })

const CUE_GAINS = Object.freeze({
  celestial_breath: 0.26,
  round_start: 0.4,
  correct_gold: 0.42,
  fire_whoosh: 0.24,
  street_wrong_soft: 0.17,
  dramatic_fire: 0.38,
  street_royal_fanfare: 0.48
})

export function streetQuizTimeline({ reduced = false } = {}) {
  return reduced ? REDUCED_MOTION : FULL_MOTION
}

export function streetDuelRaceTimeline({ reduced = false, event = false } = {}) {
  if (reduced) return DUEL_RACE_REDUCED

  return DUEL_RACE_MOTION[event ? "event" : "intro"]
}

export function streetCueGain(name) {
  return CUE_GAINS[name] ?? 0.38
}
