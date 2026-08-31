import { Controller } from "@hotwired/stimulus"

// Controls header compaction on scroll.
// Compacts the HUD header once the editorial surface moves below its hero.
export default class extends Controller {
  connect() {
    this.scrollHandler = this.onScroll.bind(this)
    this.scroller = this.element.querySelector(".street-hub-feed")
    this.scroller?.addEventListener("scroll", this.scrollHandler, { passive: true })
    this.onScroll()
  }

  disconnect() {
    this.scroller?.removeEventListener("scroll", this.scrollHandler)
  }

  onScroll() {
    const compact = (this.scroller?.scrollTop || 0) > 100
    this.element.classList.toggle("is-compact", compact)
  }
}
