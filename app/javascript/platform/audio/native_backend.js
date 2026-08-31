import { audioSession } from "platform/audio/session"

const FALLBACK_CUES = [
  "round_start",
  "correct_gold",
  "notification_glint",
  "wrong_soft",
  "street_wrong_soft",
  "score_transfer",
  "crown_chime",
  "royal_fanfare",
  "street_royal_fanfare",
  "level_up",
  "chest",
  "dramatic_fire",
  "fire_whoosh",
  "flame_gold",
  "timer_tension",
  "tick",
  "tick_low",
  "round_open",
  "round_lock",
  "question_change",
  "celestial_breath",
  "duel_send",
  "stake_gain",
  "reveal",
  "study_refuge",
  "study_light",
  "study_miss",
  "study_turn"
]

const TICK_GAIN = { tick: 0.38, tick_low: 0.52 }
const BED_GAIN = { timer_tension: 0.32, study_refuge: 0.14 }
const BED_DUCK = { timer_tension: 0.10, study_refuge: 0.05 }
const BED_HIT_DUCK = { timer_tension: 0.20, study_refuge: 0.08 }
const HIT_GAIN = 0.78
const HIT_CUE_GAIN = { correct_gold: 0.32, notification_glint: 0.54, wrong_soft: 0.58 }
const STING_GAIN = 0.80
const CUT_MS = 240
const RETRIGGER_MS = 260
const TIMER_WARN_RATIO = 0.4
const TIMER_HOT_RATIO = 0.2
const BED_IN_MS = 160
const BED_OUT_MS = 380
const BED_DUCK_MS = 110
const BED_UNDUCK_MS = 280
const TICK_CUES = new Set(["tick", "tick_low"])
const HIT_CUES = new Set(["fire_whoosh", "flame_gold", "chest", "correct_gold", "notification_glint", "wrong_soft", "street_wrong_soft", "score_transfer", "crown_chime", "duel_send", "stake_gain", "study_light", "study_miss", "study_turn"])
const BED_CUES = new Set(["timer_tension", "study_refuge"])
const BED_IN = { timer_tension: BED_IN_MS, study_refuge: 1400 }
const BED_OUT = { timer_tension: BED_OUT_MS, study_refuge: 900 }
const STAGE_NODE_SELECTOR = "#street_quiz, #study_run, [data-stage-bed-value], [data-stage-sfx-value]"
const SCRIPTURE_BED_SELECTOR = ".scripture-veil[data-stage-bed-value]"
const GESTURES = ["pointerdown", "touchstart", "keydown", "click"]

const store = {
  context: audioSession.context,
  buffers: {},
  bufferPaths: {},
  loading: {},
  loadingPaths: {},
  pending: [],
  pool: {},
  poolPaths: {},
  out: null,
  liveVoices: [],
  stingerVoice: null,
  stingerGen: 0,
  bedName: null,
  bedEl: null,
  desiredBed: null,
  continuousBed: false,
  stingerEl: null,
  tickEl: null,
  fadeGen: 0,
  lastSfx: null,
  lastToken: null,
  timerEnd: null,
  timerDuration: null,
  lastRemain: null,
  lastHaloRemain: null,
  timerWake: null,
  hitCount: 0,
  stingCount: 0,
  voiceSeq: 0,
  lastCueName: null,
  lastCueAt: 0,
  muted: false,
  unlocked: audioSession.unlocked,
  armed: false
}

try {
  store.muted = window.localStorage?.getItem("noche_sfx_muted") === "1"
} catch (_error) {
  store.muted = false
}

store.pending ||= []
store.pool ||= {}
store.buffers ||= {}
store.bufferPaths ||= {}
store.loading ||= {}
store.loadingPaths ||= {}
store.poolPaths ||= {}
store.liveVoices ||= []
store.fadeGen = store.fadeGen || 0
store.stingerEl = store.stingerEl || null
store.tickEl = store.tickEl || null
store.stingerVoice = store.stingerVoice || null
store.stingerGen = store.stingerGen || 0
store.hitCount = store.hitCount || 0
store.stingCount = store.stingCount || 0
store.voiceSeq = store.voiceSeq || 0
store.lastCueAt = store.lastCueAt || 0
store.timerDuration = store.timerDuration || 0

function catalog() {
  try {
    const source = document.getElementById("noche_sfx_catalog")?.textContent
    return source ? JSON.parse(source) : {}
  } catch (_error) {
    return {}
  }
}

function cueNames() {
  let audio = null
  try {
    const source = document.getElementById("noche_resource_manifest")?.textContent
    audio = source ? JSON.parse(source).audio : null
  } catch (_error) { /* malformed manifests fall back to the active DOM cue */ }
  const node = stageNode(document)
  const declared = [ ...Object.keys(catalog()), ...(audio?.cues || []), audio?.bed, node?.dataset.stageSfxValue, node?.dataset.stageBedValue, "tick" ].filter(Boolean)
  return declared.length ? [ ...new Set(declared) ] : [ "tick" ]
}

function publicAssetUrl(path) {
  const host = document.documentElement?.dataset?.assetHost || ""
  return `${host}${path}`
}

function cuePath(name) {
  return catalog()[name] || publicAssetUrl(`/sfx/${name}.mp3`)
}

function clampGain(value) {
  const n = Number(value)
  if (!Number.isFinite(n)) return 0.85
  return Math.min(1, Math.max(0, n))
}

function contextClass() {
  return window.AudioContext || window.webkitAudioContext || null
}

function ensureContext() {
  const AudioCtx = contextClass()
  if (!AudioCtx) return null
  store.context = store.context || new AudioCtx()
  return store.context
}

function tapContext(ctx) {
  if (!ctx) return
  try {
    const buffer = ctx.createBuffer(1, 1, ctx.sampleRate || 22050)
    const source = ctx.createBufferSource()
    source.buffer = buffer
    source.connect(ctx.destination)
    source.start(0)
  } catch (_error) {
    // Older engines reject a 1-frame buffer; HTML5 still plays.
  }
}

function makeAudio(path) {
  const el = new Audio()
  el.preload = "auto"
  el.playsInline = true
  el.setAttribute("playsinline", "")
  el.setAttribute("webkit-playsinline", "true")
  try { el.crossOrigin = "anonymous" } catch (_error) { /* file:// */ }
  el.src = path
  return el
}

function gateElement() {
  return document.getElementById("noche_sfx_gate")
}

function unlockHtmlSync() {
  const path = cuePath("tick")
  const gate = gateElement() || store.htmlUnlock || makeAudio(path)
  store.htmlUnlock = gate
  gate.playsInline = true
  gate.muted = false
  try { gate.volume = 0.01 } catch (_error) { /* some engines freeze volume */ }
  const play = gate.play()
  if (play && play.then) {
    play.then(() => {
      try { gate.pause() } catch (_error) { /* already paused */ }
      try { gate.currentTime = 0 } catch (_error) { /* not seekable yet */ }
      try { gate.volume = 1 } catch (_error) { /* ignore */ }
    }).catch(() => {})
  }
}

function unlockWebSync() {
  const ctx = ensureContext()
  if (!ctx) return
  tapContext(ctx)
  if (ctx.state === "suspended") ctx.resume().catch(() => {})
}

function voiceEl(name) {
  const path = cuePath(name)
  if (store.poolPaths[name] !== path) {
    ;(store.pool[name] || []).forEach((el) => {
      try { el.pause() } catch (_error) { /* already stopped */ }
    })
    store.pool[name] = []
    store.poolPaths[name] = path
  }
  const pool = (store.pool[name] ||= [])
  if (!pool[0]) pool[0] = makeAudio(path)
  return pool[0]
}

function isTick(name) {
  return TICK_CUES.has(name)
}

function isBed(name) {
  return BED_CUES.has(name)
}

function isHit(name) {
  return HIT_CUES.has(name)
}

function outNode() {
  const ctx = ensureContext()
  if (!ctx) return null
  if (!store.out) {
    store.out = ctx.createGain()
    store.out.connect(ctx.destination)
  }
  return store.out
}

function decodeBuffer(ctx, raw) {
  const copy = raw.slice(0)
  return new Promise((resolve, reject) => {
    let settled = false
    const ok = (buf) => {
      if (settled) return
      settled = true
      resolve(buf)
    }
    const fail = (err) => {
      if (settled) return
      settled = true
      reject(err || new Error("decode"))
    }
    try {
      const result = ctx.decodeAudioData(copy, ok, fail)
      if (result && typeof result.then === "function") result.then(ok, fail)
    } catch (err) {
      fail(err)
    }
  })
}

function loadBuffer(name) {
  const path = cuePath(name)
  if (store.bufferPaths[name] !== path) {
    delete store.buffers[name]
    delete store.loading[name]
    store.bufferPaths[name] = path
    store.loadingPaths[name] = path
  }
  if (store.buffers[name]) return Promise.resolve(store.buffers[name])
  if (store.loading[name] && store.loadingPaths[name] === path) return store.loading[name]
  const ctx = ensureContext()
  if (!ctx || !name) return Promise.resolve(null)
  store.loadingPaths[name] = path
  const job = fetch(path, { credentials: "same-origin" })
    .then((res) => {
      if (!res.ok) throw new Error("sfx")
      return res.arrayBuffer()
    })
    .then((raw) => decodeBuffer(ctx, raw))
    .then((buf) => {
      if (store.loadingPaths[name] !== path) return null
      store.buffers[name] = buf
      store.bufferPaths[name] = path
      delete store.loading[name]
      return buf
    })
    .catch(() => {
      if (store.loadingPaths[name] === path) delete store.loading[name]
      return null
    })
  store.loading[name] = job
  return job
}

function preload() {
  cueNames().forEach((name) => {
    if (isBed(name)) return
    loadBuffer(name)
  })
}

function dropVoice(voice) {
  if (!voice) return
  store.liveVoices = store.liveVoices.filter((row) => row !== voice)
}

function spawnVoice(buf, gainValue) {
  const ctx = store.context
  const dest = outNode()
  const source = ctx.createBufferSource()
  const gain = ctx.createGain()
  source.buffer = buf
  gain.gain.setValueAtTime(clampGain(gainValue), ctx.currentTime)
  source.connect(gain)
  gain.connect(dest)
  const voice = { source, gain, dead: false }
  store.liveVoices.push(voice)
  return voice
}

function fadeStopVoice(voice, ms) {
  if (!voice || voice.dead) return
  voice.dead = true
  const ctx = store.context
  if (!ctx) return
  const now = ctx.currentTime
  const dur = Math.max(0, ms) / 1000
  try {
    voice.gain.gain.cancelScheduledValues(now)
    voice.gain.gain.setValueAtTime(voice.gain.gain.value, now)
    if (dur > 0) {
      voice.gain.gain.linearRampToValueAtTime(0, now + dur)
      voice.source.stop(now + dur)
    } else {
      voice.gain.gain.setValueAtTime(0, now)
      voice.source.stop(now)
    }
  } catch (_error) {
    try { voice.source.stop() } catch (_err) { /* already stopped */ }
  }
}

function hushWeb() {
  store.stingerGen += 1
  store.liveVoices.slice().forEach((voice) => fadeStopVoice(voice, 0))
  store.liveVoices = []
  store.stingerVoice = null
  store.hitCount = 0
  store.stingCount = 0
}

function bedLive() {
  return !!(store.bedEl && !store.bedEl.paused)
}

function bedTarget() {
  if (store.muted) return 0
  const name = store.bedName || store.desiredBed || "timer_tension"
  if (store.stingCount > 0) return BED_DUCK[name] ?? BED_DUCK.timer_tension
  if (store.hitCount > 0) return BED_HIT_DUCK[name] ?? BED_HIT_DUCK.timer_tension
  return BED_GAIN[name] ?? BED_GAIN.timer_tension
}

function fadeEl(el, to, ms, done) {
  if (!el) {
    done?.()
    return
  }
  const gen = ++store.fadeGen
  el.dataset.fadeGen = String(gen)
  let from = 0
  try { from = el.volume } catch (_error) { from = 0 }
  const target = clampGain(to)
  if (ms <= 0 || Math.abs(from - target) < 0.02) {
    try { el.volume = target } catch (_error) { /* ignore */ }
    done?.()
    return
  }
  const t0 = performance.now()
  const step = (now) => {
    if (el.dataset.fadeGen !== String(gen)) return
    const t = Math.min(1, (now - t0) / ms)
    try { el.volume = from + (target - from) * t } catch (_error) { /* ignore */ }
    if (t < 1) {
      requestAnimationFrame(step)
      return
    }
    done?.()
  }
  requestAnimationFrame(step)
}

function applyDuck() {
  if (!store.bedEl || store.muted) return
  const ducking = store.stingCount > 0 || store.hitCount > 0
  fadeEl(store.bedEl, bedTarget(), ducking ? BED_DUCK_MS : BED_UNDUCK_MS)
}

function cutEl(el, ms = CUT_MS) {
  if (!el) return
  fadeEl(el, 0, ms, () => {
    try { el.pause() } catch (_error) { /* ignore */ }
    try { el.currentTime = 0 } catch (_error) { /* ignore */ }
  })
}

function nextVoiceSeq(el) {
  const token = ++store.voiceSeq
  el.dataset.voiceSeq = String(token)
  return token
}

function voiceLive(el) {
  return !!(el && !el.paused && !el.ended)
}

function stopStinger() {
  store.stingerGen += 1
  const voice = store.stingerVoice
  store.stingerVoice = null
  store.stingCount = 0
  if (voice) fadeStopVoice(voice, CUT_MS)
  const el = store.stingerEl
  store.stingerEl = null
  if (el) {
    el.dataset.voiceSeq = String(++store.voiceSeq)
    el.onended = null
    cutEl(el)
  }
  applyDuck()
}

function startVoice(el, gainValue) {
  el.dataset.fadeGen = String(++store.fadeGen)
  try { el.pause() } catch (_error) { /* ignore */ }
  try { el.currentTime = 0 } catch (_error) { /* iOS before loadedmetadata */ }
  el.muted = false
  try { el.volume = clampGain(gainValue) } catch (_error) { /* ignore */ }
  const play = el.play()
  if (play && play.catch) return play
  return Promise.resolve()
}

function queueStinger(name, gainValue) {
  store.pending = [[name, gainValue]]
}

function playHitHtml(name, gainValue) {
  const el = voiceEl(name)
  const live = voiceLive(el)
  if (!live) store.hitCount += 1
  const token = nextVoiceSeq(el)
  el.onended = () => {
    if (el.dataset.voiceSeq !== String(token)) return
    store.hitCount = Math.max(0, store.hitCount - 1)
    applyDuck()
  }
  applyDuck()
  startVoice(el, gainValue).catch(() => {
    if (el.dataset.voiceSeq !== String(token)) return
    queueStinger(name, gainValue)
    store.hitCount = Math.max(0, store.hitCount - 1)
    applyDuck()
  })
}

function playStingerHtml(name, gainValue) {
  const el = voiceEl(name)
  const prev = store.stingerEl
  if (prev && prev !== el) {
    prev.dataset.voiceSeq = String(++store.voiceSeq)
    prev.onended = null
    store.stingCount = Math.max(0, store.stingCount - 1)
    store.stingerEl = null
    cutEl(prev, CUT_MS)
  }
  const live = prev === el && voiceLive(el)
  if (!live) store.stingCount += 1
  const token = nextVoiceSeq(el)
  store.stingerEl = el
  el.onended = () => {
    if (el.dataset.voiceSeq !== String(token)) return
    if (store.stingerEl === el) store.stingerEl = null
    store.stingCount = Math.max(0, store.stingCount - 1)
    applyDuck()
  }
  applyDuck()
  startVoice(el, gainValue).catch(() => {
    if (el.dataset.voiceSeq !== String(token)) return
    queueStinger(name, gainValue)
    if (store.stingerEl === el) store.stingerEl = null
    store.stingCount = Math.max(0, store.stingCount - 1)
    applyDuck()
  })
}

function playTickHtml(name, gainValue) {
  if (bedLive()) return
  const el = voiceEl(name)
  const prev = store.tickEl
  if (prev && prev !== el) {
    try { prev.pause() } catch (_error) { /* ignore */ }
    try { prev.currentTime = 0 } catch (_error) { /* ignore */ }
  }
  store.tickEl = el
  startVoice(el, gainValue).catch(() => {})
}

function playHit(name, gainValue) {
  loadBuffer(name).then((buf) => {
    if (store.muted) return
    if (!buf) {
      if (!bedLive()) playHitHtml(name, gainValue)
      return
    }
    const voice = spawnVoice(buf, gainValue)
    store.hitCount += 1
    applyDuck()
    voice.source.onended = () => {
      dropVoice(voice)
      if (voice.counted === false) return
      voice.counted = false
      store.hitCount = Math.max(0, store.hitCount - 1)
      applyDuck()
    }
    voice.counted = true
    try {
      voice.source.start(0)
    } catch (_error) {
      dropVoice(voice)
      store.hitCount = Math.max(0, store.hitCount - 1)
      applyDuck()
    }
  })
}

function playStinger(name, gainValue) {
  const gen = ++store.stingerGen
  loadBuffer(name).then((buf) => {
    if (gen !== store.stingerGen) return
    if (store.muted) return
    if (!buf) {
      if (!bedLive()) playStingerHtml(name, gainValue)
      return
    }
    const prev = store.stingerVoice
    if (prev) fadeStopVoice(prev, CUT_MS)
    const voice = spawnVoice(buf, gainValue)
    store.stingerVoice = voice
    store.stingCount = 1
    applyDuck()
    voice.source.onended = () => {
      dropVoice(voice)
      if (store.stingerVoice !== voice) return
      store.stingerVoice = null
      store.stingCount = 0
      applyDuck()
    }
    try {
      voice.source.start(0)
    } catch (_error) {
      dropVoice(voice)
      if (store.stingerVoice === voice) {
        store.stingerVoice = null
        store.stingCount = 0
        applyDuck()
      }
    }
  })
}

function playTick(name, gainValue) {
  loadBuffer(name).then((buf) => {
    if (store.muted || !store.unlocked) return
    if (!buf) {
      playTickHtml(name, gainValue)
      return
    }
    const voice = spawnVoice(buf, gainValue)
    voice.source.onended = () => dropVoice(voice)
    try {
      voice.source.start(0)
    } catch (_error) {
      dropVoice(voice)
    }
  })
}

function tooSoon(name) {
  const now = performance.now()
  if (store.lastCueName === name && (now - store.lastCueAt) < RETRIGGER_MS) return true
  store.lastCueName = name
  store.lastCueAt = now
  return false
}

function playCue(name, gainValue) {
  if (store.muted || !name || !cueNames().includes(name)) return
  if (isBed(name)) {
    startBed(name)
    return
  }
  if (isTick(name)) {
    if (!store.unlocked) return
    playTick(name, gainValue ?? TICK_GAIN[name] ?? 0.38)
    return
  }
  if (tooSoon(name)) return
  if (isHit(name)) {
    playHit(name, gainValue ?? HIT_CUE_GAIN[name] ?? HIT_GAIN)
    return
  }
  playStinger(name, gainValue ?? STING_GAIN)
}

function flushPending() {
  const queued = store.pending.splice(0)
  let stinger = null
  queued.forEach((item) => {
    if (isTick(item[0]) || isBed(item[0])) return
    stinger = item
  })
  if (stinger) playCue(stinger[0], stinger[1])
}

function hushHtml() {
  stopStinger()
  store.tickEl = null
  store.hitCount = 0
  store.stingCount = 0
  Object.values(store.pool).forEach((nodes) => {
    nodes.forEach((el) => {
      el.dataset.fadeGen = String(++store.fadeGen)
      el.dataset.voiceSeq = String(++store.voiceSeq)
      el.onended = null
      try { el.pause() } catch (_error) { /* ignore */ }
      try { el.currentTime = 0 } catch (_error) { /* ignore */ }
    })
  })
  const gate = store.htmlUnlock || gateElement()
  if (gate) {
    try { gate.pause() } catch (_error) { /* ignore */ }
  }
}

function hushAll() {
  hushWeb()
  hushHtml()
}

function stopBed(immediate = false) {
  const el = store.bedEl
  const name = store.bedName
  store.bedEl = null
  store.bedName = null
  if (!el) return
  fadeEl(el, 0, immediate ? 0 : (BED_OUT[name] ?? BED_OUT_MS), () => {
    try { el.pause() } catch (_error) { /* ignore */ }
    try { el.currentTime = 0 } catch (_error) { /* ignore */ }
  })
}

function startBed(name) {
  store.desiredBed = name
  if (store.muted || !name) {
    stopBed()
    return
  }
  if (store.bedName === name && store.bedEl && !store.bedEl.paused) {
    applyDuck()
    return
  }
  if (!store.unlocked) return

  stopBed()
  const el = makeAudio(cuePath(name))
  el.loop = true
  try { el.volume = 0 } catch (_error) { /* ignore */ }
  store.bedEl = el
  store.bedName = name
  const rise = () => {
    if (store.bedEl !== el || store.muted) return
    fadeEl(el, bedTarget(), BED_IN[name] ?? BED_IN_MS)
  }
  const play = el.play()
  if (play && play.then) {
    play.then(rise).catch(() => {
      if (store.bedEl === el) {
        store.bedEl = null
        store.bedName = null
      }
    })
    return
  }
  rise()
}

function releaseAsk({ preserveBed = false } = {}) {
  if (!preserveBed) store.desiredBed = null
  stopStinger()
  if (!preserveBed) stopBed()
  store.timerEnd = null
  store.timerDuration = null
  store.lastRemain = null
  store.lastHaloRemain = null
  if (store.timerWake) clearTimeout(store.timerWake)
  store.timerWake = null
  clearHalo()
}

function syncBed(name) {
  if (store.muted || !name) {
    store.desiredBed = null
    stopBed()
    return
  }
  startBed(name)
}

function stageNode(root) {
  const scripture = root?.matches?.(SCRIPTURE_BED_SELECTOR)
    ? root
    : root?.querySelector?.(SCRIPTURE_BED_SELECTOR)
  if (scripture) return scripture
  if (root?.matches?.(STAGE_NODE_SELECTOR)) return root
  return root?.querySelector?.(STAGE_NODE_SELECTOR)
}

function playFrom(root) {
  const node = stageNode(root || document)
  const sfx = node?.dataset.stageSfxValue
  const token = node?.dataset.stageSfxTokenValue || sfx
  const fx = node?.dataset.stageFxValue
  const bed = node?.dataset.stageBedValue
  store.continuousBed = node?.dataset.stageBedPolicyValue === "continuous"
  const manualCue = node?.dataset.stageCuePolicyValue === "manual"
  if (!manualCue && sfx && (sfx !== store.lastSfx || token !== store.lastToken)) {
    store.lastSfx = sfx
    store.lastToken = token
    playCue(sfx)
  }
  if (manualCue) clearFlash()
  else if (fx) flash(fx)
  if (manualCue && document.hidden) {
    store.desiredBed = bed || null
    stopStinger()
    stopBed()
  } else {
    syncBed(bed)
  }
  syncTimer(node)
}

function syncTimer(node) {
  const raw = node?.dataset.stageTimerEndValue || node?.getAttribute?.("data-stage-timer-end-value")
  const duration = Number(node?.dataset.stageTimerDurationValue || node?.getAttribute?.("data-stage-timer-duration-value") || 0)
  const parsed = raw ? Date.parse(raw) : NaN
  const nextEnd = Number.isFinite(parsed) && duration > 0 ? parsed : null
  store.timerDuration = nextEnd ? duration : 0
  if (nextEnd === store.timerEnd) {
    if (store.timerEnd && !store.timerWake) timerTick()
    return
  }
  store.timerEnd = nextEnd
  store.lastRemain = null
  store.lastHaloRemain = null
  if (store.timerWake) clearTimeout(store.timerWake)
  store.timerWake = null
  if (store.timerEnd) {
    timerTick()
    return
  }
  clearHalo()
}

function haloRoot() {
  return document.querySelector("#street_quiz")
}

function ensureHalo(root) {
  if (!root) return null
  let halo = root.querySelector(":scope > .timer-halo")
  if (halo) return halo
  halo = document.createElement("div")
  halo.className = "timer-halo"
  halo.setAttribute("aria-hidden", "true")
  root.appendChild(halo)
  return halo
}

function clearHalo() {
  store.lastHaloRemain = null
  document.querySelectorAll(".is-timer-warn, .is-timer-hot, .is-timer-pulse").forEach((el) => {
    el.classList.remove("is-timer-warn", "is-timer-hot", "is-timer-pulse")
  })
}

function syncHalo(remain, remainMs) {
  const root = haloRoot()
  if (!root) return
  const duration = Number(store.timerDuration) || 0
  const warnAt = duration * TIMER_WARN_RATIO
  const hotAt = duration * TIMER_HOT_RATIO
  if (!remainMs || remain <= 0 || !(duration > 0) || remain > warnAt) {
    root.classList.remove("is-timer-warn", "is-timer-hot", "is-timer-pulse")
    store.lastHaloRemain = null
    return
  }
  ensureHalo(root)
  const hot = remain <= hotAt
  root.classList.toggle("is-timer-warn", !hot)
  root.classList.toggle("is-timer-hot", hot)
  if (root.matches("#street_quiz[data-stage-cue-policy-value='manual']")) {
    root.classList.remove("is-timer-pulse")
    store.lastHaloRemain = remain
    return
  }
  if (store.lastHaloRemain === remain) return
  store.lastHaloRemain = remain
  root.classList.remove("is-timer-pulse")
  void root.offsetWidth
  root.classList.add("is-timer-pulse")
}

function timerTick() {
  if (!store.timerEnd) {
    clearHalo()
    return
  }
  const remainMs = Math.max(0, store.timerEnd - Date.now())
  const remain = Math.ceil(remainMs / 1000)
  syncHalo(remain, remainMs)
  store.lastRemain = remain
  if (remainMs > 0) {
    const nextSecond = remainMs % 1000 || 1000
    store.timerWake = setTimeout(timerTick, Math.max(16, Math.min(1000, nextSecond)))
    return
  }
  store.timerWake = null
  clearHalo()
  if (!store.continuousBed) {
    store.desiredBed = null
    stopBed()
  }
}

function flash(name) {
  clearFlash()
  const map = { shake: "is-fx-shake", reveal: "is-fx-reveal", level: "is-fx-level", finale: "is-fx-finale" }
  document.body.classList.add(map[name] || "is-fx-gold")
}

function clearFlash() {
  document.body.classList.remove("is-fx-gold", "is-fx-reveal", "is-fx-shake", "is-fx-level", "is-fx-finale")
}

function afterUnlock() {
  preload()
  flushPending()
  if (store.desiredBed) startBed(store.desiredBed)
  playFrom(document)
  if (store.timerEnd && !store.timerWake) timerTick()
}

function onGesture(event) {
  if (event?.target?.closest?.(".mute")) return
  if (!store.unlocked) {
    store.unlocked = true
    unlockHtmlSync()
    unlockWebSync()
    afterUnlock()
    return
  }
  if (store.muted) return
  unlockWebSync()
  flushPending()
  const bed = stageNode(document)?.dataset.stageBedValue
  if (bed && store.desiredBed === bed && (!store.bedEl || store.bedEl.paused)) startBed(bed)
}

function onVisibilityChange() {
  const node = stageNode(document)
  const manualStreet = node?.matches?.("#street_quiz[data-stage-cue-policy-value='manual']")
  if (document.hidden) {
    if (manualStreet) {
      stopStinger()
      stopBed()
    }
    return
  }
  if (manualStreet || !store.unlocked || store.muted) return
  unlockWebSync()
  const bed = node?.dataset.stageBedValue
  if (bed && store.desiredBed === bed) startBed(bed)
}

function onPageShow() {
  if (!store.unlocked || store.muted) return
  const node = stageNode(document)
  if (node?.matches?.("#street_quiz[data-stage-cue-policy-value='manual']")) return
  unlockWebSync()
  const bed = node?.dataset.stageBedValue
  if (bed && store.desiredBed === bed) startBed(bed)
}

function onTurboRender() {
  playFrom(document)
}

function armGestures() {
  if (store.armed) return
  store.armed = true
  GESTURES.forEach((type) => {
    const passive = type !== "keydown"
    document.addEventListener(type, onGesture, { capture: true, passive })
  })
  document.addEventListener("visibilitychange", onVisibilityChange)
  window.addEventListener("pageshow", onPageShow)
  document.addEventListener("turbo:load", onTurboRender)
  document.addEventListener("turbo:render", onTurboRender)
  document.addEventListener("turbo:frame-render", onTurboRender)
  document.addEventListener("turbo:after-stream-render", onTurboRender)
}

function disarmGestures() {
  if (!store.armed) return
  store.armed = false
  GESTURES.forEach((type) => document.removeEventListener(type, onGesture, true))
  document.removeEventListener("visibilitychange", onVisibilityChange)
  window.removeEventListener("pageshow", onPageShow)
  document.removeEventListener("turbo:load", onTurboRender)
  document.removeEventListener("turbo:render", onTurboRender)
  document.removeEventListener("turbo:frame-render", onTurboRender)
  document.removeEventListener("turbo:after-stream-render", onTurboRender)
}

export function connectAudio() {
  try {
    store.muted = window.localStorage?.getItem("noche_sfx_muted") === "1"
  } catch (_error) {
    store.muted = false
  }
  armGestures()
  playFrom(document)
  if (store.unlocked && !store.muted) afterUnlock()
  return store
}

export function disconnectAudio() {
  disarmGestures()
  releaseAsk()
  hushAll()
}

export function toggleMute() {
  if (!store.unlocked) {
    store.unlocked = true
    unlockHtmlSync()
    unlockWebSync()
    afterUnlock()
    return store.muted
  }
  store.muted = !store.muted
  try {
    window.localStorage.setItem("noche_sfx_muted", store.muted ? "1" : "0")
  } catch (_error) { /* private mode */ }
  if (store.muted) {
    store.desiredBed = null
    stopBed(true)
    hushAll()
  } else {
    onGesture()
    playFrom(document)
  }
  return store.muted
}

export function muted() {
  return store.muted
}

export const nativeAudio = {
  connect: connectAudio,
  disconnect: disconnectAudio,
  flash,
  muted,
  play: playCue,
  playFrom,
  releaseAsk,
  toggleMute,
  unlock: onGesture
}
