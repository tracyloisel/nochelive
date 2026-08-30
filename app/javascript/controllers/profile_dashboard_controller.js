import { Controller } from "@hotwired/stimulus"

const FOCUS_KEY = "noche:profile-editor-focus"
const RESULT_KEY = "noche:profile-editor-result"

export default class extends Controller {
  connect() {
    if (this.element.querySelector(".profile-editor-sheet")) return

    let key
    let result
    try {
      key = sessionStorage.getItem(FOCUS_KEY)
      result = sessionStorage.getItem(RESULT_KEY)
      sessionStorage.removeItem(FOCUS_KEY)
      sessionStorage.removeItem(RESULT_KEY)
    } catch (_) {}
    if (!key) return

    const trigger = this.element.querySelector(`[data-profile-editor-field="${CSS.escape(key)}"]`)
    trigger?.focus({ preventScroll: true })
    if (!trigger || result !== key || this.reduced()) return

    trigger.classList.add("is-saved")
    this.savedTimer = window.setTimeout(() => trigger.classList.remove("is-saved"), 820)
  }

  disconnect() {
    window.clearTimeout(this.savedTimer)
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
