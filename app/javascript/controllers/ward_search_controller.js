import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "lat", "lng" ]

  connect() {
    this.lastSubmitted = this.signature()
    this.restoreCaret()
    this.locate()
  }

  queue() {
    window.clearTimeout(this.timer)
    this.start()
    this.timer = window.setTimeout(() => this.submit(), 320)
  }

  clearOnEscape(event) {
    if (!event.target.matches("#ward_q")) return
    if (!event.target.value) return
    event.preventDefault()
    event.target.value = ""
    this.submit()
  }

  locate() {
    const q = this.element.querySelector("#ward_q")?.value.trim() || ""
    if (q) return
    if (this.hasLatTarget && this.latTarget.value) return
    if (!navigator.geolocation) return

    this.start()
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        if (this.hasLatTarget) this.latTarget.value = pos.coords.latitude.toFixed(5)
        if (this.hasLngTarget) this.lngTarget.value = pos.coords.longitude.toFixed(5)
        this.submit()
      },
      () => {
        const q = this.element.querySelector("#ward_q")?.value.trim() || ""
        if (!q) this.stop()
      },
      { maximumAge: 300000, timeout: 8000, enableHighAccuracy: false }
    )
  }

  submit() {
    window.clearTimeout(this.timer)
    const next = this.signature()
    if (next === this.lastSubmitted) {
      this.stop()
      return
    }
    this.lastSubmitted = next
    this.start()
    this.element.requestSubmit()
  }

  start() {
    this.element.classList.add("is-searching")
    this.element.setAttribute("aria-busy", "true")
  }

  stop() {
    this.element.classList.remove("is-searching")
    this.element.removeAttribute("aria-busy")
  }

  signature() {
    const q = this.element.querySelector("#ward_q")?.value.trim() || ""
    const lat = this.hasLatTarget ? this.latTarget.value : ""
    const lng = this.hasLngTarget ? this.lngTarget.value : ""
    return `${q}|${lat}|${lng}`
  }

  restoreCaret() {
    const field = this.element.querySelector("#ward_q")
    if (!field?.value) return
    field.focus()
    const end = field.value.length
    try { field.setSelectionRange(end, end) } catch (_) { /* search inputs in some engines */ }
  }

  disconnect() {
    window.clearTimeout(this.timer)
  }
}
