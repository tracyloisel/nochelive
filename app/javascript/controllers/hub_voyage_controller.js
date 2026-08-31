import { Controller } from "@hotwired/stimulus"

// Keeps the single adventure carousel accessible by swipe, keyboard, and dots.
export default class extends Controller {
  static targets = [ "track", "dots" ]

  connect() {
    this.sync = this.sync.bind(this)
    this.pendingIndex = null
    if (this.hasTrackTarget) {
      this.trackTarget.addEventListener("scroll", this.sync, { passive: true })
      this.buildDots()
      this.snapToCurrent()
    }
  }

  disconnect() {
    this.hasTrackTarget && this.trackTarget.removeEventListener("scroll", this.sync)
  }

  buildDots() {
    if (!this.hasDotsTarget) return
    const slides = this.slides()
    const dots = slides.map((slide, i) => {
      const dot = document.createElement("button")
      dot.type = "button"
      dot.className = "hub-dot"
      dot.dataset.index = i
      dot.setAttribute("aria-label", this.slideLabel(slide))
      return dot
    })

    this.dotsTarget.replaceChildren(...dots)
    dots.forEach((dot) => {
      dot.addEventListener("click", () => this.go(Number(dot.dataset.index)))
    })
  }

  snapToCurrent() {
    const slides = this.slides()
    const idx = Math.max(0, slides.findIndex((slide) => slide.dataset.kind === "current"))
    this.go(idx === -1 ? 0 : idx, true)
  }

  go(index, instant = false) {
    const slide = this.slides()[index]
    if (!slide) return
    this.pendingIndex = instant ? null : index
    this.trackTarget.scrollTo({
      left: slide.offsetLeft,
      behavior: instant || this.reduced() ? "auto" : "smooth",
    })
    this.setActive(index)
  }

  sync() {
    const slides = this.slides()
    if (!slides.length) return

    /* A programmatic smooth scroll emits an initial event before the viewport
       has moved. Keep the selected dot and its inert state stable until the
       requested slide reaches its snap point instead of flickering back to
       the previous slide for one frame. */
    if (this.pendingIndex !== null) {
      const intended = slides[this.pendingIndex]
      if (intended && Math.abs(this.trackTarget.scrollLeft - intended.offsetLeft) > 2) return
      this.pendingIndex = null
    }

    const track = this.trackTarget.getBoundingClientRect()
    const mid = track.left + track.width / 2
    let best = 0
    let dist = Infinity
    slides.forEach((slide, i) => {
      const box = slide.getBoundingClientRect()
      const d = Math.abs(box.left + box.width / 2 - mid)
      if (d < dist) {
        dist = d
        best = i
      }
    })

    this.setActive(best)
  }

  setActive(index) {
    this.slides().forEach((slide, i) => {
      const current = i === index
      slide.classList.toggle("is-current", current)
      slide.toggleAttribute("inert", !current)
      slide.setAttribute("aria-hidden", current ? "false" : "true")
    })

    if (!this.hasDotsTarget) return
    this.dotsTarget.querySelectorAll(".hub-dot").forEach((dot, i) => {
      const current = i === index
      dot.classList.toggle("is-on", current)
      dot.setAttribute("aria-current", current ? "true" : "false")
    })
  }

  slideLabel(slide) {
    const title = slide.querySelector(".hub-hero-title")?.textContent?.trim()
    const pack = slide.querySelector(".hub-hero-name")?.textContent?.trim()
    return [title, pack].filter(Boolean).join(" — ")
  }

  slides() {
    return Array.from(this.trackTarget?.querySelectorAll(".hub-slide") || [])
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
