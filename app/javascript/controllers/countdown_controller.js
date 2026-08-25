import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { end: String, duration: Number, reloadUrl: String, expireUrl: String }
  static targets = ["label", "bar"]

  connect() {
    this.tick()
  }

  disconnect() {
    if (this.frame) cancelAnimationFrame(this.frame)
  }

  tick() {
    const remainMs = Math.max(0, Date.parse(this.endValue) - Date.now())
    const remain = Math.ceil(remainMs / 1000)
    if (this.hasLabelTarget) this.labelTarget.textContent = remain
    if (this.hasBarTarget && this.durationValue > 0) {
      this.barTarget.style.transform = `scaleX(${Math.min(1, remainMs / (this.durationValue * 1000))})`
    }
    this.element.classList.toggle("is-low", remain > 0 && remain <= 5)
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
