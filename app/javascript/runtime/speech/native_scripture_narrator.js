const LOCALE_TAGS = {
  en: "en-US",
  es: "es-ES",
  fr: "fr-FR",
  "pt-BR": "pt-BR"
}

export function speechLocale(locale) {
  return LOCALE_TAGS[locale] || locale || "en-US"
}

export function selectLocalVoice(voices, locale) {
  const tag = speechLocale(locale).toLowerCase()
  const language = tag.split("-")[0]
  const localVoices = Array.from(voices || []).filter((voice) => voice?.localService === true)
  const exact = localVoices.filter((voice) => voice.lang?.toLowerCase() === tag)
  const matching = exact.length > 0
    ? exact
    : localVoices.filter((voice) => voice.lang?.toLowerCase().split("-")[0] === language)

  return matching.find((voice) => voice.default) || matching[0] || null
}

export class NativeScriptureNarrator {
  constructor({ synth, createUtterance, locale, verses, voices = [], onState = () => {} }) {
    this.synth = synth
    this.createUtterance = createUtterance
    this.locale = locale
    this.verses = Array.from(verses || [])
    this.voices = Array.from(voices || [])
    this.onState = onState
    this.state = "idle"
    this.index = null
    this.session = 0
    this.currentUtterance = null
  }

  setVoices(voices) {
    this.voices = Array.from(voices || [])
    if (this.state === "unavailable" && this.available()) this.changeState("idle", null)
  }

  available() {
    return Boolean(this.synth && this.createUtterance && selectLocalVoice(this.voices, this.locale))
  }

  toggle(startIndex = 0) {
    if (this.state === "playing") return this.pause()
    if (this.state === "paused") return this.resume()
    return this.play(startIndex)
  }

  play(startIndex = 0) {
    const voice = selectLocalVoice(this.voices, this.locale)
    if (!this.synth || !this.createUtterance || !voice || this.verses.length === 0) {
      this.changeState("unavailable", null)
      return false
    }

    this.stop({ notify: false })
    const index = Math.min(Math.max(Number(startIndex) || 0, 0), this.verses.length - 1)
    const session = ++this.session
    this.speak(index, voice, session)
    return true
  }

  pause() {
    if (this.state !== "playing") return false
    this.synth.pause()
    this.changeState("paused", this.index)
    return true
  }

  resume() {
    if (this.state !== "paused") return false
    this.synth.resume()
    this.changeState("playing", this.index)
    return true
  }

  stop({ notify = true } = {}) {
    this.session += 1
    this.currentUtterance = null
    this.synth?.cancel?.()
    if (notify) this.changeState("idle", null)
  }

  speak(index, voice, session) {
    if (session !== this.session) return
    if (index >= this.verses.length) {
      this.currentUtterance = null
      this.changeState("idle", null)
      return
    }

    const utterance = this.createUtterance(this.verses[index])
    utterance.lang = speechLocale(this.locale)
    utterance.voice = voice
    utterance.onstart = () => {
      if (session === this.session) this.changeState("playing", index)
    }
    utterance.onend = () => {
      if (session !== this.session) return
      this.currentUtterance = null
      this.speak(index + 1, voice, session)
    }
    utterance.onerror = () => {
      if (session !== this.session) return
      this.currentUtterance = null
      this.changeState("error", index)
    }
    this.currentUtterance = utterance
    this.changeState("playing", index)
    this.synth.speak(utterance)
  }

  changeState(state, index) {
    this.state = state
    this.index = index
    this.onState({ state, index })
  }
}
