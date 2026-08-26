import { Controller } from "@hotwired/stimulus"

const PRESSABLE = "button, .btn, .choice-btn, .quiz-bar, .quiz-next, .team-pick, .person-pick, .buzz, .emblem-choice, .avatar-choice, .choice-chip, .picture-card, .night-hit, .ward-hit, .rama-night, .rama-pin, summary, a.btn, .quiet-link, .home-menu-btn, .home-menu-row, .chrome-face, .lang-opt, .paper-door, .story-close, .story-tick, .story-live, .story-audience, .story-score, .street-map-door-play, .about-reach-chip, .street-pulse"

export default class extends Controller {
  connect() {
    this.onDown = this.onDown.bind(this)
    this.element.addEventListener("pointerdown", this.onDown)
  }

  disconnect() {
    this.element.removeEventListener("pointerdown", this.onDown)
  }

  onDown(event) {
    if (event.pointerType === "mouse" && event.button !== 0) return
    const target = event.target.closest(PRESSABLE)
    if (!target || target.disabled || target.getAttribute("aria-disabled") === "true") return
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    this.ripple(target, event)
    target.classList.add("is-pressed")
    const up = () => {
      target.classList.remove("is-pressed")
      window.removeEventListener("pointerup", up)
      window.removeEventListener("pointercancel", up)
    }
    window.addEventListener("pointerup", up)
    window.addEventListener("pointercancel", up)
  }

  ripple(target, event) {
    const rect = target.getBoundingClientRect()
    const size = Math.max(rect.width, rect.height) * 1.15
    const span = document.createElement("span")
    span.className = "ripple"
    span.style.width = span.style.height = `${size}px`
    span.style.left = `${event.clientX - rect.left - size / 2}px`
    span.style.top = `${event.clientY - rect.top - size / 2}px`
    target.classList.add("has-ripple")
    target.append(span)
    span.addEventListener("animationend", () => span.remove())
  }
}
