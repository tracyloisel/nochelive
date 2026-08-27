import { Controller } from "@hotwired/stimulus"

// Enhanced carousel controller with scale transforms and theme crossfade.
// Active card at scale(1), neighbors reduced. Dot capsule morph during swipe.
export default class extends Controller {
  static targets = [ "track", "dots" ]

  connect() {
    this.sync = this.sync.bind(this)
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
    this.dotsTarget.innerHTML = slides.map((slide, i) =>
      `<button type="button" class="hub-dot" data-index="${i}" aria-label="${this.slideLabel(slide)}"></button>`
    ).join("")
    this.dotsTarget.querySelectorAll(".hub-dot").forEach((dot) => {
      dot.addEventListener("click", () => this.go(Number(dot.dataset.index)))
    })
    this.sync()
  }

  snapToCurrent() {
    const slides = this.slides()
    const idx = Math.max(0, slides.findIndex((slide) => slide.dataset.kind === "current"))
    this.go(idx === -1 ? 0 : idx, true)
  }

  go(index, instant = false) {
    const slide = this.slides()[index]
    if (!slide) return
    slide.scrollIntoView({
      behavior: instant || this.reduced() ? "auto" : "smooth",
      inline: "start",
      block: "nearest"
    })
  }

  sync() {
    const slides = this.slides()
    if (!slides.length || !this.hasDotsTarget) return

    // Find the current slide
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

    const slideWidth = Math.max(1, this.trackTarget.clientWidth)
    const rawIndex = this.trackTarget.scrollLeft / slideWidth

    this.dotsTarget.querySelectorAll(".hub-dot").forEach((dot, i) => {
      dot.classList.toggle("is-on", i === best)
      dot.setAttribute("aria-current", i === best ? "true" : "false")
      const proximity = Math.max(0, 1 - Math.abs(rawIndex - i))
      dot.style.setProperty("--dot-progress", proximity.toFixed(3))
    })
  }

  slideLabel(slide) {
    const title = slide.querySelector(".hub-hero-title")?.textContent?.trim()
    const pack = slide.querySelector(".hub-hero-name")?.textContent?.trim()
    return [title, pack].filter(Boolean).join(" — ").replaceAll('"', "&quot;")
  }

  slides() {
    return Array.from(this.trackTarget?.querySelectorAll(".hub-slide") || [])
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
