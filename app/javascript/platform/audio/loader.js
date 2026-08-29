import { audioSession } from "platform/audio/session"

const GESTURES = ["pointerdown", "touchstart", "keydown", "click"]
const store = {
  armed: false,
  backend: null,
  connected: false,
  idleWarmup: null,
  loading: null,
  warming: null,
  pending: []
}

function mark(state) {
  document.documentElement.dataset.audioRuntime = state
}

function gateElement() {
  return document.getElementById("noche_sfx_gate")
}

function syncUnlock() {
  if (audioSession.unlocked) return
  audioSession.unlocked = true
  mark("unlocking")

  const gate = gateElement()
  if (gate) {
    gate.muted = false
    try { gate.volume = 0.01 } catch (_error) { /* immutable volume */ }
    const play = gate.play()
    play?.then?.(() => {
      try { gate.pause() } catch (_error) { /* already paused */ }
      try { gate.currentTime = 0 } catch (_error) { /* not seekable yet */ }
      try { gate.volume = 1 } catch (_error) { /* immutable volume */ }
    }).catch(() => {})
  }

  const AudioContextClass = window.AudioContext || window.webkitAudioContext
  if (!AudioContextClass) return
  try {
    audioSession.context ||= new AudioContextClass()
    const buffer = audioSession.context.createBuffer(1, 1, audioSession.context.sampleRate || 22_050)
    const source = audioSession.context.createBufferSource()
    source.buffer = buffer
    source.connect(audioSession.context.destination)
    source.start(0)
    if (audioSession.context.state === "suspended") audioSession.context.resume().catch(() => {})
  } catch (_error) { /* HTML audio remains available */ }
}

function disarm() {
  if (!store.armed) return
  store.armed = false
  GESTURES.forEach((type) => document.removeEventListener(type, onGesture, true))
}

function arm() {
  if (store.armed || store.backend) return
  store.armed = true
  GESTURES.forEach((type) => document.addEventListener(type, onGesture, { capture: true, passive: type !== "keydown" }))
}

function flush() {
  const backend = store.backend
  if (!backend) return
  store.pending.splice(0).forEach(([method, args]) => backend[method]?.(...args))
}

function warmBackend() {
  if (store.backend) return Promise.resolve(store.backend)
  if (store.warming) return store.warming

  store.warming = import("platform/audio/native_backend")
    .then(({ nativeAudio }) => nativeAudio)
    .catch((error) => {
      store.warming = null
      throw error
    })
  return store.warming
}

function cancelWarmup() {
  if (store.idleWarmup == null) return
  window.clearTimeout(store.idleWarmup)
  store.idleWarmup = null
}

function scheduleWarmup() {
  if (store.backend || store.warming || store.idleWarmup != null) return
  const run = () => {
    store.idleWarmup = null
    if (store.connected) warmBackend().catch(() => {})
  }
  store.idleWarmup = window.setTimeout(run, 0)
}

function loadBackend() {
  if (store.backend) return Promise.resolve(store.backend)
  if (store.loading) return store.loading
  cancelWarmup()
  store.loading = warmBackend().then((nativeAudio) => {
    store.backend = nativeAudio
    store.loading = null
    store.warming = null
    disarm()
    if (store.connected) {
      nativeAudio.connect()
      flush()
      mark("ready")
    } else {
      store.pending = []
      nativeAudio.disconnect()
      mark("idle")
    }
    return nativeAudio
  }).catch((error) => {
    store.loading = null
    arm()
    mark("failed")
    throw error
  })
  return store.loading
}

function onGesture(event) {
  if (event?.target?.closest?.(".mute")) return
  syncUnlock()
  loadBackend().catch(() => {})
}

function queue(method, args) {
  if (store.backend) return store.backend[method]?.(...args)
  store.pending.push([method, args])
}

function muted() {
  if (store.backend) return store.backend.muted()
  try { return window.localStorage?.getItem("noche_sfx_muted") === "1" } catch (_error) { return false }
}

export const audioLoader = {
  connect() {
    store.connected = true
    if (store.backend) {
      store.backend.connect()
      mark("ready")
    }
    else {
      mark("waiting")
      arm()
      scheduleWarmup()
    }
  },
  disconnect() {
    store.connected = false
    store.pending = []
    cancelWarmup()
    disarm()
    store.backend?.disconnect?.()
    mark("idle")
  },
  flash(name) {
    document.body.classList.remove("is-fx-gold", "is-fx-reveal", "is-fx-shake", "is-fx-level", "is-fx-finale")
    const map = { shake: "is-fx-shake", reveal: "is-fx-reveal", level: "is-fx-level", finale: "is-fx-finale" }
    document.body.classList.add(map[name] || "is-fx-gold")
  },
  muted,
  unlocked() { return audioSession.unlocked },
  play(...args) { return queue("play", args) },
  playFrom(...args) { return queue("playFrom", args) },
  releaseAsk(...args) { return queue("releaseAsk", args) },
  toggleMute() {
    syncUnlock()
    return loadBackend().then((backend) => backend.toggleMute())
  },
  unlock() {
    syncUnlock()
    return loadBackend()
  }
}
