import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.restoreCaret()
    this.revealYou()
  }

  queue(event) {
    if (event.target.matches("select")) {
      this.submit()
      return
    }
    window.clearTimeout(this.timer)
    this.timer = window.setTimeout(() => this.submit(), 320)
  }

  clearOnEscape(event) {
    if (!event.target.matches("#leaderboard_q")) return
    if (!event.target.value) return
    event.preventDefault()
    event.target.value = ""
    this.submit()
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

  revealYou() {
    if (window.location.hash !== "#liga-you") return
    const row = document.getElementById("liga-you")
    if (!row) return
    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    row.scrollIntoView({ block: "center", behavior: reduce ? "auto" : "smooth" })
  }

  disconnect() {
    window.clearTimeout(this.timer)
  }
}
