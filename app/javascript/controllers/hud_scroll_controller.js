import { Controller } from "@hotwired/stimulus"

// Gives every shared page HUD the same two-state behavior: it belongs to the
// page at rest, then becomes a floating instrument after the content scrolls.
export default class extends Controller {
  connect() {
    this.hud = document.querySelector("body > .home-menu:is(.is-hud, .has-desktop-hud)")
    if (!this.hud) return

    this.scrollSource = document.querySelector("[data-hud-scroll-source]")
    this.companions = Array.from(document.querySelectorAll("[data-hud-scroll-companion]"))
    this.handleScroll = this.onScroll.bind(this)

    window.addEventListener("scroll", this.handleScroll, { passive: true })
    this.scrollSource?.addEventListener("scroll", this.handleScroll, { passive: true })
    this.sync()
  }

  disconnect() {
    if (this.handleScroll) {
      window.removeEventListener("scroll", this.handleScroll)
      this.scrollSource?.removeEventListener("scroll", this.handleScroll)
    }
    this.setCompact(false)
  }

  onScroll() {
    this.sync()
  }

  sync() {
    const pageScroll = window.scrollY || document.documentElement.scrollTop || 0
    const localScroll = this.scrollSource?.scrollTop || 0
    this.setCompact(Math.max(pageScroll, localScroll) > 84)
  }

  setCompact(compact) {
    this.hud?.classList.toggle("is-compact", compact)
    this.companions?.forEach((element) => element.classList.toggle("is-compact", compact))
  }
}
