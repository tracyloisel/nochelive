import { Controller } from "@hotwired/stimulus"

const GEO_TIMEOUT = 5000

export default class extends Controller {
  static targets = [ "lat", "lng", "locate", "statusCopy" ]
  static values = {
    wait: String,
    locationUnavailable: String
  }

  connect() {
    this.locateGen = 0
    this.lastSubmitted = this.signature()
    this.restoreCaret()
    this.revealLocate()
  }

  queue() {
    if (this.queryValue()) this.locateGen += 1
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

  askLocate(event) {
    event.preventDefault()
    this.requestPosition()
  }

  requestPosition() {
    if (!this.canLocate()) return
    if (this.hasLatTarget && this.latTarget.value) return

    this.locateGen += 1
    const gen = this.locateGen
    this.start()
    window.clearTimeout(this.geoTimer)
    this.geoTimer = window.setTimeout(() => this.abortLocate(gen), GEO_TIMEOUT)

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        if (gen !== this.locateGen) return
        window.clearTimeout(this.geoTimer)
        if (this.hasLatTarget) this.latTarget.value = pos.coords.latitude.toFixed(5)
        if (this.hasLngTarget) this.lngTarget.value = pos.coords.longitude.toFixed(5)
        this.hideLocate()
        this.submit()
      },
      (err) => {
        if (gen !== this.locateGen) return
        window.clearTimeout(this.geoTimer)
        if (err?.code === 1) this.hideLocate()
        this.failLocate()
      },
      { maximumAge: 300000, timeout: 4000, enableHighAccuracy: false }
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
    this.element.classList.remove("is-search-error")
    this.setStatus(this.waitValue)
    this.element.classList.add("is-searching")
    this.element.setAttribute("aria-busy", "true")
  }

  stop() {
    this.element.classList.remove("is-searching")
    this.element.removeAttribute("aria-busy")
  }

  failLocate() {
    this.stop()
    this.setStatus(this.locationUnavailableValue)
    this.element.classList.add("is-search-error")
  }

  setStatus(copy) {
    if (!this.hasStatusCopyTarget || !copy) return
    this.statusCopyTarget.textContent = copy
  }

  signature() {
    const q = this.queryValue()
    const lat = this.hasLatTarget ? this.latTarget.value : ""
    const lng = this.hasLngTarget ? this.lngTarget.value : ""
    return `${q}|${lat}|${lng}`
  }

  restoreCaret() {
    const field = this.field()
    if (!field?.value) return
    if (window.matchMedia("(pointer: coarse)").matches) return
    field.focus()
    const end = field.value.length
    try { field.setSelectionRange(end, end) } catch (_) { /* search inputs in some engines */ }
  }

  revealLocate() {
    if (!this.hasLocateTarget) return
    if (!this.canLocate()) return
    if (this.hasLatTarget && this.latTarget.value) return
    this.locateTarget.hidden = false
  }

  hideLocate() {
    if (!this.hasLocateTarget) return
    this.locateTarget.hidden = true
  }

  canLocate() {
    return Boolean(navigator.geolocation)
  }

  abortLocate(gen) {
    if (gen !== this.locateGen) return
    this.locateGen += 1
    this.failLocate()
  }

  field() {
    return this.element.querySelector("#ward_q")
  }

  queryValue() {
    return this.field()?.value.trim() || ""
  }

  disconnect() {
    window.clearTimeout(this.timer)
    window.clearTimeout(this.geoTimer)
  }
}
