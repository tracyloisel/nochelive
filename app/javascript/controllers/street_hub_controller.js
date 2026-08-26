import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "map" ]
  static values = { currentPack: String, rankUp: Boolean }

  connect() {
    this.scrollToCurrent()
    if (this.rankUpValue) this.syncRankUp()
  }

  scrollToCurrent() {
    const id = this.currentPackValue
    if (!id) return
    const node = this.element.querySelector(`#pack-${id}`)
    if (!node) return
    requestAnimationFrame(() => {
      const map = this.hasMapTarget ? this.mapTarget : null
      if (!map?.classList.contains("is-rope")) {
        node.scrollIntoView({
          behavior: this.reduced() ? "auto" : "smooth",
          block: "nearest",
          inline: "nearest"
        })
      }
      if (!this.reduced()) {
        node.classList.add("is-beacon-active")
        this.beaconTimer = window.setTimeout(() => node.classList.remove("is-beacon-active"), 2600)
      }
    })
  }

  syncRankUp() {
    const card = this.element.querySelector(".street-card.is-player.is-rank-up")
    if (!card) return
    window.setTimeout(() => {
      window.NocheLiveAudio?.play?.("level_up")
    }, 120)
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  disconnect() {
    window.clearTimeout(this.beaconTimer)
  }
}
