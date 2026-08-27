import { Controller } from "@hotwired/stimulus"

// Controls header compaction on scroll.
// Progressively compacts HUD header after 100-140px of scroll.
// No hide/show - just progressive resizing.
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
    const scrollY = this.scroller?.scrollTop || 0
    const threshold = 100
    const maxCompaction = 140

    if (scrollY <= threshold) {
      this.element.classList.remove("is-compact")
      this.element.style.setProperty("--scroll-progress", "0")
      return
    }

    this.element.classList.add("is-compact")

    // Progressive compaction
    const progress = Math.min((scrollY - threshold) / (maxCompaction - threshold), 1)
    this.element.style.setProperty("--scroll-progress", String(progress))
  }
}
