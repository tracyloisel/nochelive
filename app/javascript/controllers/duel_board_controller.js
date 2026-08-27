import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "lead", "reveal"]

  connect() {
    this.reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.enterOnce()
    this.animateCounts()
    this.observeSections()
  }

  disconnect() {
    this.observer?.disconnect()
    this.frames?.forEach((frame) => cancelAnimationFrame(frame))
  }

  enterOnce() {
    let seen = false
    try {
      seen = sessionStorage.getItem("noche_duels_seen") === "1"
      sessionStorage.setItem("noche_duels_seen", "1")
    } catch (_) { /* private mode */ }
    if (seen || this.reduce) {
      this.element.classList.remove("is-duel-enter")
      return
    }
    window.setTimeout(() => window.NocheLiveAudio?.play?.("celestial_breath"), 180)
  }

  animateCounts() {
    this.frames = []
    this.countTargets.forEach((node) => {
      const target = Number(node.dataset.countTo || 0)
      if (this.reduce) {
        node.textContent = target.toLocaleString()
        return
      }
      const start = performance.now()
      const tick = (now) => {
        const progress = Math.min(1, (now - start) / 450)
        const eased = 1 - Math.pow(1 - progress, 3)
        node.textContent = Math.round(target * eased).toLocaleString()
        if (progress < 1) this.frames.push(requestAnimationFrame(tick))
      }
      this.frames.push(requestAnimationFrame(tick))
    })
    if (this.hasLeadTarget && !this.reduce) {
      this.leadTarget.style.animationDelay = "500ms"
    }
  }

  observeSections() {
    if (!this.hasRevealTarget || this.reduce) return
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return
        entry.target.classList.add("is-revealed")
        this.observer.unobserve(entry.target)
      })
    }, { threshold: 0.25 })
    this.revealTargets.forEach((node) => this.observer.observe(node))
  }
}
