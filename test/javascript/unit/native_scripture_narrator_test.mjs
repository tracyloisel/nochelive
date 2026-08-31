import assert from "node:assert/strict"
import test from "node:test"

import {
  NativeScriptureNarrator,
  selectLocalVoice,
  speechLocale
} from "../../../app/javascript/runtime/speech/native_scripture_narrator.js"

class FakeSpeechSynthesis {
  constructor() {
    this.calls = []
    this.current = null
  }

  speak(utterance) {
    this.current = utterance
    this.calls.push(["speak", utterance.text])
    utterance.onstart?.()
  }

  pause() { this.calls.push(["pause"]) }
  resume() { this.calls.push(["resume"]) }
  cancel() { this.calls.push(["cancel"]) }
  finish() { this.current?.onend?.() }
}

const localFrench = { name: "Thomas", lang: "fr-FR", localService: true, default: true }
const remoteFrench = { name: "Cloud", lang: "fr-FR", localService: false, default: true }

function buildNarrator({ voices = [localFrench], onState = () => {} } = {}) {
  const synth = new FakeSpeechSynthesis()
  const narrator = new NativeScriptureNarrator({
    synth,
    createUtterance: (text) => ({ text }),
    locale: "fr",
    verses: ["Premier verset.", "Deuxième verset."],
    voices,
    onState
  })
  return { narrator, synth }
}

test("selectLocalVoice never falls back to a remote voice", () => {
  assert.equal(selectLocalVoice([remoteFrench], "fr"), null)
  assert.equal(selectLocalVoice([remoteFrench, localFrench], "fr"), localFrench)
  assert.equal(speechLocale("pt-BR"), "pt-BR")
})

test("narrator speaks one verse at a time and advances to the end", () => {
  const states = []
  const { narrator, synth } = buildNarrator({ onState: (state) => states.push(state) })

  assert.equal(narrator.play(0), true)
  assert.deepEqual(synth.calls.at(-1), ["speak", "Premier verset."])
  assert.equal(synth.current.lang, "fr-FR")
  assert.equal(synth.current.voice, localFrench)

  synth.finish()
  assert.deepEqual(synth.calls.at(-1), ["speak", "Deuxième verset."])
  synth.finish()
  assert.equal(narrator.state, "idle")
  assert.deepEqual(states.at(-1), { state: "idle", index: null })
})

test("the single toggle pauses and resumes the current verse", () => {
  const { narrator, synth } = buildNarrator()

  narrator.toggle(1)
  assert.deepEqual(synth.calls.at(-1), ["speak", "Deuxième verset."])
  narrator.toggle()
  assert.equal(narrator.state, "paused")
  assert.deepEqual(synth.calls.at(-1), ["pause"])
  narrator.toggle()
  assert.equal(narrator.state, "playing")
  assert.deepEqual(synth.calls.at(-1), ["resume"])
})

test("narrator reports unavailable when no installed voice matches", () => {
  const { narrator, synth } = buildNarrator({ voices: [remoteFrench] })

  assert.equal(narrator.available(), false)
  assert.equal(narrator.play(), false)
  assert.equal(narrator.state, "unavailable")
  assert.equal(synth.calls.length, 0)
})

test("stop invalidates callbacks from the canceled utterance", () => {
  const { narrator, synth } = buildNarrator()
  narrator.play()
  const canceled = synth.current

  narrator.stop()
  canceled.onend()

  assert.equal(narrator.state, "idle")
  assert.equal(synth.calls.filter(([name]) => name === "speak").length, 1)
})
