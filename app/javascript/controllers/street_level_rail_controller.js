import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.reduced()) return
    this.element.querySelectorAll(".street-level-dot.filled, .street-level-dot.current, .street-level-dot.miss").forEach((dot) => {
      dot.classList.remove("is-rail-pop")
      void dot.offsetWidth
      dot.classList.add("is-rail-pop")
    })
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
