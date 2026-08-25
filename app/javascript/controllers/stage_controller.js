import { Controller } from "@hotwired/stimulus"

const FALLBACK_CUES = [
  "round_start",
  "buzzer_hit",
  "correct_gold",
  "wrong_soft",
  "royal_fanfare",
  "level_up",
  "chest",
  "dramatic_fire",
  "fire_whoosh",
  "timer_tension",
  "tick",
  "tick_low",
  "round_open",
  "round_lock",
  "question_change",
  "reveal"
]

const TICK_GAIN = { tick: 0.42, tick_low: 0.58 }
const BED_GAIN = 0.35
const BED_DUCK = 0.11
const STING_GAIN = 0.85
const CUT_MS = 55
const TICK_CUES = new Set(["tick", "tick_low"])
const BED_CUE = "timer_tension"
const GESTURES = ["pointerdown", "touchstart", "keydown", "click"]

const store = window.NocheLiveAudio = window.NocheLiveAudio || {
  context: null,
  buffers: {},
  loading: {},
  pending: [],
  pool: {},
  bedName: null,
  bedEl: null,
  desiredBed: null,
  stingerEl: null,
  tickEl: null,
  fadeGen: 0,
  lastSfx: null,
  lastToken: null,
  timerEnd: null,
  lastRemain: null,
  timerFrame: null,
  muted: false,
  unlocked: false,
  armed: false
}

try {
  store.muted = window.localStorage?.getItem("noche_sfx_muted") === "1"
} catch (_error) {
  store.muted = false
}

store.pending ||= []
store.pool ||= {}
store.fadeGen = store.fadeGen || 0
store.stingerEl = store.stingerEl || null
store.tickEl = store.tickEl || null

function catalog() {
  return window.NocheSfx || {}
}

function cueNames() {
  const names = Object.keys(catalog())
  return names.length ? names : FALLBACK_CUES
}

function cuePath(name) {
  return catalog()[name] || `/sfx/${name}.mp3`
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
  const pool = (store.pool[name] ||= [])
  if (!pool[0]) pool[0] = makeAudio(cuePath(name))
  return pool[0]
}

function preload() {
  cueNames().forEach((name) => voiceEl(name).load())
}

function isTick(name) {
  return TICK_CUES.has(name)
}

function isBed(name) {
  return name === BED_CUE
}

function stingerPlaying() {
  const el = store.stingerEl
  return !!(el && !el.paused && !el.ended)
}

function cutEl(el, ms = CUT_MS) {
  if (!el) return
  const gen = ++store.fadeGen
  el.dataset.fadeGen = String(gen)
  let from = 0
  try { from = el.volume } catch (_error) { from = 0 }
  if (ms <= 0 || from <= 0.02) {
    try { el.pause() } catch (_error) { /* ignore */ }
    try { el.currentTime = 0 } catch (_error) { /* ignore */ }
    return
  }
  const t0 = performance.now()
  const step = (now) => {
    if (el.dataset.fadeGen !== String(gen)) return
    const t = Math.min(1, (now - t0) / ms)
    try { el.volume = from * (1 - t) } catch (_error) { /* ignore */ }
    if (t < 1) {
      requestAnimationFrame(step)
      return
    }
    try { el.pause() } catch (_error) { /* ignore */ }
    try { el.currentTime = 0 } catch (_error) { /* ignore */ }
  }
  requestAnimationFrame(step)
}

function duckBed() {
  if (!store.bedEl) return
  try { store.bedEl.volume = BED_DUCK } catch (_error) { /* ignore */ }
}

function unduckBed() {
  if (!store.bedEl || store.muted) return
  try { store.bedEl.volume = BED_GAIN } catch (_error) { /* ignore */ }
}

function stopStinger() {
  const el = store.stingerEl
  store.stingerEl = null
  if (el) cutEl(el)
  unduckBed()
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

function playStinger(name, gainValue) {
  const el = voiceEl(name)
  const prev = store.stingerEl
  if (prev && prev !== el) cutEl(prev)
  store.stingerEl = el
  duckBed()
  el.onended = () => {
    if (store.stingerEl !== el) return
    store.stingerEl = null
    unduckBed()
  }
  startVoice(el, gainValue).catch(() => {
    queueStinger(name, gainValue)
  })
}

function playTick(name, gainValue) {
  if (stingerPlaying()) return
  const el = voiceEl(name)
  const prev = store.tickEl
  if (prev && prev !== el) {
    try { prev.pause() } catch (_error) { /* ignore */ }
    try { prev.currentTime = 0 } catch (_error) { /* ignore */ }
  }
  store.tickEl = el
  startVoice(el, gainValue).catch(() => {})
}

function playCue(name, gainValue) {
  if (store.muted || !name || !cueNames().includes(name)) return
  if (isBed(name)) {
    startBed(name)
    return
  }
  if (isTick(name)) {
    if (!store.unlocked) return
    playTick(name, gainValue ?? TICK_GAIN[name] ?? 0.42)
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
  Object.values(store.pool).forEach((nodes) => {
    nodes.forEach((el) => {
      el.dataset.fadeGen = String(++store.fadeGen)
      try { el.pause() } catch (_error) { /* ignore */ }
      try { el.currentTime = 0 } catch (_error) { /* ignore */ }
    })
  })
  const gate = store.htmlUnlock || gateElement()
  if (gate) {
    try { gate.pause() } catch (_error) { /* ignore */ }
  }
}

function stopBed() {
  const el = store.bedEl
  if (el) {
    try { el.pause() } catch (_error) { /* ignore */ }
  }
  store.bedEl = null
  store.bedName = null
}

function startBed(name) {
  store.desiredBed = name
  if (store.muted || !name) {
    stopBed()
    return
  }
  if (store.bedName === name && store.bedEl && !store.bedEl.paused) return
  if (!store.unlocked) return

  stopBed()
  const el = makeAudio(cuePath(name))
  el.loop = true
  try { el.volume = stingerPlaying() ? BED_DUCK : BED_GAIN } catch (_error) { /* ignore */ }
  store.bedEl = el
  store.bedName = name
  const play = el.play()
  if (play && play.catch) {
    play.catch(() => {
      store.bedEl = null
      store.bedName = null
    })
  }
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
  return root.querySelector("#night_play, #night_watch, #night_presenter, #street_quiz")
    || root.querySelector("[data-stage-sfx-value]")
}

function playFrom(root) {
  const node = stageNode(root || document)
  const sfx = node?.dataset.stageSfxValue
  const token = node?.dataset.stageSfxTokenValue || sfx
  const fx = node?.dataset.stageFxValue
  const bed = node?.dataset.stageBedValue
  if (sfx && (sfx !== store.lastSfx || token !== store.lastToken)) {
    store.lastSfx = sfx
    store.lastToken = token
    playCue(sfx)
  }
  if (fx) flash(fx)
  syncBed(bed)
  syncTimer(node)
}

function syncTimer(node) {
  const raw = node?.dataset.stageTimerEndValue || node?.getAttribute?.("data-stage-timer-end-value")
  const duration = Number(node?.dataset.stageTimerDurationValue || node?.getAttribute?.("data-stage-timer-duration-value") || 0)
  const parsed = raw ? Date.parse(raw) : NaN
  const nextEnd = Number.isFinite(parsed) && duration > 0 ? parsed : null
  if (nextEnd === store.timerEnd) {
    if (store.timerEnd && !store.timerFrame) timerTick()
    return
  }
  store.timerEnd = nextEnd
  store.lastRemain = null
  if (store.timerFrame) cancelAnimationFrame(store.timerFrame)
  store.timerFrame = null
  if (store.timerEnd) timerTick()
}

function timerTick() {
  if (!store.timerEnd) return
  const remainMs = Math.max(0, store.timerEnd - Date.now())
  const remain = Math.ceil(remainMs / 1000)
  if (store.lastRemain !== null && remain < store.lastRemain && remain >= 0) {
    const low = remain <= 5
    playCue(low ? "tick_low" : "tick", TICK_GAIN[low ? "tick_low" : "tick"])
  }
  store.lastRemain = remain
  if (remainMs > 0) {
    store.timerFrame = requestAnimationFrame(timerTick)
    return
  }
  store.timerFrame = null
  store.desiredBed = null
  stopBed()
}

function flash(name) {
  document.body.classList.remove("is-fx-gold", "is-fx-reveal", "is-fx-shake", "is-fx-level", "is-fx-finale")
  const map = { shake: "is-fx-shake", reveal: "is-fx-reveal", level: "is-fx-level", finale: "is-fx-finale" }
  document.body.classList.add(map[name] || "is-fx-gold")
}

function afterUnlock() {
  preload()
  flushPending()
  if (store.desiredBed) startBed(store.desiredBed)
  playFrom(document)
  if (store.timerEnd && !store.timerFrame) timerTick()
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
  if (store.desiredBed && (!store.bedEl || store.bedEl.paused)) startBed(store.desiredBed)
}

function armGestures() {
  if (store.armed) return
  store.armed = true
  GESTURES.forEach((type) => {
    const passive = type !== "keydown"
    document.addEventListener(type, onGesture, { capture: true, passive })
  })
  document.addEventListener("visibilitychange", () => {
    if (document.hidden || !store.unlocked || store.muted) return
    unlockWebSync()
    if (store.desiredBed) startBed(store.desiredBed)
  })
  window.addEventListener("pageshow", () => {
    if (!store.unlocked || store.muted) return
    unlockWebSync()
    if (store.desiredBed) startBed(store.desiredBed)
  })
  document.addEventListener("turbo:load", () => playFrom(document))
  document.addEventListener("turbo:render", () => playFrom(document))
  document.addEventListener("turbo:frame-render", () => playFrom(document))
  document.addEventListener("turbo:after-stream-render", () => playFrom(document))
  document.addEventListener("turbo:before-stream-render", () => {
    requestAnimationFrame(() => playFrom(document))
  })
}

store.play = playCue
store.unlock = onGesture
store.playFrom = playFrom
store.flash = flash

export default class extends Controller {
  static targets = ["mute"]

  connect() {
    try {
      store.muted = window.localStorage?.getItem("noche_sfx_muted") === "1"
    } catch (_error) {
      store.muted = false
    }
    this.syncMute()
    armGestures()
    playFrom(document)
    if (store.unlocked && !store.muted) afterUnlock()
  }

  disconnect() {
    // Keep the shared store (bed, pool, timer) alive across Turbo body swaps.
  }

  toggleMute(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    if (!store.unlocked) {
      store.unlocked = true
      unlockHtmlSync()
      unlockWebSync()
      afterUnlock()
      this.syncMute()
      return
    }
    store.muted = !store.muted
    try {
      window.localStorage.setItem("noche_sfx_muted", store.muted ? "1" : "0")
    } catch (_error) { /* private mode */ }
    this.syncMute()
    if (store.muted) {
      store.desiredBed = null
      stopBed()
      hushHtml()
      return
    }
    onGesture()
  }

  play(name, gainValue = 0.85) {
    playCue(name, gainValue)
  }

  flash(name) {
    flash(name)
  }

  syncMute() {
    if (!this.hasMuteTarget) return
    this.muteTarget.setAttribute("aria-pressed", store.muted ? "true" : "false")
    this.muteTarget.classList.toggle("is-muted", store.muted)
    const word = this.muteTarget.querySelector(".word")
    const on = this.muteTarget.dataset.soundOn || "Sonido"
    const off = this.muteTarget.dataset.soundOff || "Sonido off"
    if (word) word.textContent = store.muted ? off : on
    this.muteTarget.setAttribute("aria-label", store.muted ? off : on)
  }
}
