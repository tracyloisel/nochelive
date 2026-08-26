import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "map" ]
  static values = { currentPack: String }

  connect() {
    this.scrollToCurrent()
  }

  scrollToCurrent() {
    const id = this.currentPackValue
    if (!id) return
    const node = this.element.querySelector(`#pack-${id}`)
    if (!node) return
    const pin = () => {
      const map = this.hasMapTarget ? this.mapTarget : null
      if (map?.classList.contains("is-rope")) {
        const mapRect = map.getBoundingClientRect()
        const nodeRect = node.getBoundingClientRect()
        map.scrollTop += (nodeRect.top + nodeRect.height / 2) - (mapRect.top + mapRect.height * 0.42)
      } else {
        node.scrollIntoView({
          behavior: this.reduced() ? "auto" : "smooth",
          block: "nearest",
          inline: "nearest"
        })
      }
    }
    requestAnimationFrame(() => {
      pin()
      requestAnimationFrame(pin)
      if (!this.reduced()) {
        node.classList.add("is-beacon-active")
        this.beaconTimer = window.setTimeout(() => node.classList.remove("is-beacon-active"), 2600)
      }
    })
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  disconnect() {
    window.clearTimeout(this.beaconTimer)
  }
}
