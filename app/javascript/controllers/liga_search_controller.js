import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.restoreCaret()
  }

  queue(event) {
    if (event.target.matches("select")) {
      this.submit()
      return
    }
    window.clearTimeout(this.timer)
    this.timer = window.setTimeout(() => this.submit(), 320)
  }

  submit() {
    window.clearTimeout(this.timer)
    this.element.querySelectorAll("[name]").forEach((field) => {
      if (!field.value) field.disabled = true
    })
    this.element.requestSubmit()
  }

  restoreCaret() {
    const field = this.element.querySelector("#leaderboard_q")
    if (!field?.value) return
    field.focus()
    const end = field.value.length
    try { field.setSelectionRange(end, end) } catch (_) { /* search inputs in some engines */ }
  }

  disconnect() {
    window.clearTimeout(this.timer)
  }
}
