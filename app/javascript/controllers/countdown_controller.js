import { Controller } from "@hotwired/stimulus"

const TIMER_WARN_RATIO = 0.4
const TIMER_HOT_RATIO = 0.2

export default class extends Controller {
  static values = { end: String, duration: Number, reloadUrl: String, expireUrl: String, ask: Boolean }
  static targets = ["label", "bar"]

  connect() {
    this.endAt = Date.parse(this.endValue)
    if (this.askValue && window.matchMedia("(prefers-reduced-motion: reduce)").matches) this.releaseAsk()
    this.tick()
  }

  disconnect() {
    if (this.frame) cancelAnimationFrame(this.frame)
  }

  askZones(remain) {
    if (this.askValue) {
      const duration = this.durationValue
      if (!(duration > 0) || remain <= 0) return { warn: false, hot: false }
      const hot = remain <= duration * TIMER_HOT_RATIO
      return { warn: !hot && remain <= duration * TIMER_WARN_RATIO, hot }
    }
    return {
      warn: remain > 10 && remain <= 20,
      hot: remain > 0 && remain <= 10
    }
  }

  releaseAsk() {
    if (!this.askValue || !(this.durationValue > 0) || this.previewReleased) return
    this.previewReleased = true
    const previewRemaining = Math.max(0, this.endAt - Date.now() - (this.durationValue * 1000))
    this.endAt -= previewRemaining
  }

  tick() {
    const remainMs = Math.max(0, this.endAt - Date.now())
    const rawRemain = Math.ceil(remainMs / 1000)
    const remain = this.askValue && this.durationValue > 0 ? Math.min(this.durationValue, rawRemain) : rawRemain
    if (this.hasLabelTarget) this.labelTarget.textContent = remain
    if (this.hasBarTarget && this.durationValue > 0) {
      this.barTarget.style.transform = `scaleX(${Math.min(1, remainMs / (this.durationValue * 1000))})`
    }
    const { warn, hot } = this.askZones(remain)
    this.element.classList.toggle("is-warn", warn)
    this.element.classList.toggle("is-low", hot)
    this.element.classList.toggle("is-empty", remain <= 0)
    if (remainMs > 0) {
      this.frame = requestAnimationFrame(() => this.tick())
      return
    }
    if (this.hasExpireUrlValue && this.expireUrlValue && !this.expired) {
      this.expired = true
      const token = document.querySelector('meta[name="csrf-token"]')?.content
      fetch(this.expireUrlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": token || "",
          Accept: "text/vnd.turbo-stream.html"
        },
        credentials: "same-origin"
      }).then((res) => res.text()).then((html) => {
        if (html && window.Turbo) window.Turbo.renderStreamMessage(html)
      }).catch(() => {})
      return
    }
    if (this.reloadUrlValue && !this.reloaded) {
      this.reloaded = true
      window.location = this.reloadUrlValue
    }
  }
}
