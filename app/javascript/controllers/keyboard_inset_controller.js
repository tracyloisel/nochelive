import { Controller } from "@hotwired/stimulus"

const FIELD = "input:not([type=hidden]):not([type=radio]):not([type=checkbox]), textarea, select"

// iOS already pans the focused field above the keyboard. Measuring
// visualViewport, writing --keyboard-inset, and scrolling on every
// resize/scroll fight that pan and make the rama picker tremble.
export default class extends Controller {
  connect() {
    this.onFocusIn = (event) => this.onFocus(event)
    this.onFocusOut = (event) => this.onBlur(event)
    this.element.addEventListener("focusin", this.onFocusIn)
    this.element.addEventListener("focusout", this.onFocusOut)
  }

  onFocus(event) {
    if (!event.target.matches(FIELD)) return
    this.element.classList.add("is-keyboard")
  }

  onBlur(event) {
    if (!event.target.matches(FIELD)) return
    window.setTimeout(() => {
      const current = document.activeElement
      if (current?.matches?.(FIELD) && this.element.contains(current)) return
      this.element.classList.remove("is-keyboard")
    }, 80)
  }

  disconnect() {
    this.element.removeEventListener("focusin", this.onFocusIn)
    this.element.removeEventListener("focusout", this.onFocusOut)
    this.element.classList.remove("is-keyboard")
  }
}
