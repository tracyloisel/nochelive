import { Controller } from "@hotwired/stimulus"
import { audioLoader } from "platform/audio/loader"
import { NativeScriptureNarrator } from "runtime/speech/native_scripture_narrator"

export default class extends Controller {
  static targets = ["toggle", "playIcon", "pauseIcon", "verse"]

  connect() {
    this.synth = window.speechSynthesis
    this.onVoicesChanged = this.onVoicesChanged.bind(this)
    this.narrator = new NativeScriptureNarrator({
      synth: this.synth,
      createUtterance: window.SpeechSynthesisUtterance
        ? (text) => new window.SpeechSynthesisUtterance(text)
        : null,
      locale: this.element.dataset.scriptureAudioLocale,
      verses: this.verseTargets.map((verse) => verse.querySelector("[data-scripture-verse-text]")?.textContent?.trim()).filter(Boolean),
      voices: this.availableVoices(),
      onState: ({ state, index }) => this.renderState(state, index)
    })

    this.synth?.addEventListener?.("voiceschanged", this.onVoicesChanged)
    this.renderState("idle", null)
  }

  disconnect() {
    this.synth?.removeEventListener?.("voiceschanged", this.onVoicesChanged)
    this.narrator?.stop({ notify: false })
    this.clearSpeakingVerse()
  }

  toggle(event) {
    event?.preventDefault()
    this.narrator.setVoices(this.availableVoices())
    if (this.narrator.state !== "playing" && this.narrator.state !== "paused") audioLoader.releaseAsk()
    this.narrator.toggle(this.startIndex())
  }

  onVoicesChanged() {
    this.narrator.setVoices(this.availableVoices())
    this.renderState(this.narrator.state, this.narrator.index)
  }

  availableVoices() {
    try {
      return this.synth?.getVoices?.() || []
    } catch (_error) {
      return []
    }
  }

  startIndex() {
    const anchor = this.element.querySelector(".scripture-verse.is-reading-anchor")
    const fallbackNumber = this.element.dataset.scriptureAudioStartVerse
    const verse = anchor || this.verseTargets.find((candidate) => candidate.dataset.scriptureVerseNumber === fallbackNumber)
    return Math.max(this.verseTargets.indexOf(verse), 0)
  }

  renderState(state, index) {
    const playing = state === "playing"
    const available = this.narrator?.available() || false
    const label = playing ? this.element.dataset.scriptureAudioPauseLabel : this.element.dataset.scriptureAudioPlayLabel
    const unavailable = this.element.dataset.scriptureAudioUnavailableLabel

    this.element.dataset.scriptureAudioState = state
    this.toggleTargets.forEach((button) => {
      button.disabled = !available
      button.setAttribute("aria-label", available ? label : unavailable)
      button.setAttribute("title", available ? label : unavailable)
      button.setAttribute("aria-pressed", String(playing))
    })
    this.playIconTargets.forEach((icon) => { icon.hidden = playing })
    this.pauseIconTargets.forEach((icon) => { icon.hidden = !playing })
    this.markSpeakingVerse(index)
  }

  markSpeakingVerse(index) {
    this.clearSpeakingVerse()
    if (!Number.isInteger(index)) return
    const verse = this.verseTargets[index]
    if (!verse) return
    this.speakingVerse = verse
    verse.classList.add("is-speaking")
    if (!this.verseIsComfortablyVisible(verse)) {
      verse.scrollIntoView({ block: "center", behavior: this.reducedMotion() ? "auto" : "smooth" })
    }
  }

  clearSpeakingVerse() {
    this.speakingVerse?.classList.remove("is-speaking")
    this.speakingVerse = null
  }

  verseIsComfortablyVisible(verse) {
    const sheet = this.element.querySelector(".scripture-sheet")
    if (!sheet) return true
    const verseBounds = verse.getBoundingClientRect()
    const sheetBounds = sheet.getBoundingClientRect()
    const top = sheetBounds.top + 96
    const bottom = sheetBounds.bottom - 72
    return verseBounds.top >= top && verseBounds.bottom <= bottom
  }

  reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
