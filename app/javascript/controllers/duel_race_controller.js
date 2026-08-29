import { Controller } from "@hotwired/stimulus"
import { haptic } from "haptics"
import { EffectScope } from "platform/lifecycle/effect_scope"
import { SafeStorage } from "platform/storage/safe_storage"
import { streetDuelRaceTimeline } from "runtime/street/quiz_timeline"

const CELEBRATION_EVENTS = new Set(["you_passed", "you_tied", "official_ahead", "official_tie"])
const LIVE_EVENTS = new Set(["rival_passed", "rival_tied", "official_behind"])

export default class extends Controller {
  static values = { event: String, run: String, race: String, signature: String }

  connect() {
    this.effects = new EffectScope()
    this.reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.storage = new SafeStorage(this.sessionStorage)
    this.eventful = this.eventValue !== "idle"

    if (this.reduced || this.storage.get(this.storageKey()) === "1") {
      this.compact({ instant: true })
      return
    }

    this.storage.set(this.storageKey(), "1")
    this.element.classList.add("is-race-pending")

    const timeline = streetDuelRaceTimeline({ event: this.eventful })
    this.effects.timeout(() => this.present(), timeline.reveal)
    this.effects.timeout(() => this.compact(), timeline.compact)
  }

  disconnect() {
    this.effects?.dispose()
  }

  present() {
    this.element.classList.remove("is-race-pending", "is-race-compact", "is-race-instant")
    this.element.classList.add("is-race-expanded", "is-race-presenting", "is-race-arriving")

    if (CELEBRATION_EVENTS.has(this.eventValue)) haptic("reward")
    if (LIVE_EVENTS.has(this.eventValue)) haptic("tap")

    this.effects.timeout(() => this.element.classList.remove("is-race-arriving"), 1100)
  }

  compact({ instant = false } = {}) {
    this.element.classList.remove("is-race-expanded", "is-race-presenting", "is-race-arriving", "is-race-pending")
    this.element.classList.add("is-race-compact")
    this.element.classList.toggle("is-race-instant", instant)
  }

  storageKey() {
    const phase = this.eventful ? `event:${this.signatureValue || this.eventValue}` : "intro"
    return [ "noche", "duel-race", this.runValue || "run", this.raceValue || "race", phase ].join(":")
  }

  get sessionStorage() {
    try {
      return window.sessionStorage
    } catch (_) {
      return null
    }
  }
}
