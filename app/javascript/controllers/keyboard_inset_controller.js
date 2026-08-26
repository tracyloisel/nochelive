import { Controller } from "@hotwired/stimulus"

const FIELD = "input:not([type=hidden]):not([type=radio]):not([type=checkbox]), textarea, select"

export default class extends Controller {
  connect() {
    this.baseHeight = this.visibleHeight()
    this.onViewport = () => this.sync()
    this.onFocusIn = (event) => this.onFocus(event)
    this.onFocusOut = (event) => this.onBlur(event)
    this.element.addEventListener("focusin", this.onFocusIn)
    this.element.addEventListener("focusout", this.onFocusOut)
    window.visualViewport?.addEventListener("resize", this.onViewport)
    window.visualViewport?.addEventListener("scroll", this.onViewport)
    window.addEventListener("resize", this.onViewport)
  }

  onFocus(event) {
    if (!event.target.matches(FIELD)) return
    this.active = event.target
    this.sync()
    window.setTimeout(() => this.sync(), 60)
    window.setTimeout(() => this.sync(), 350)
  }

  onBlur(event) {
    if (!event.target.matches(FIELD)) return
    window.setTimeout(() => {
      if (this.field()) return
      this.active = null
      this.sync()
    }, 80)
  }

  field() {
    const current = document.activeElement
    if (current?.matches?.(FIELD) && this.element.contains(current)) return current
    return null
  }

  visibleHeight() {
    return window.visualViewport?.height || window.innerHeight
  }

  sync() {
    const field = this.field()
    const root = document.documentElement

    if (!field) {
      this.baseHeight = this.visibleHeight()
      root.style.setProperty("--keyboard-inset", "0px")
      this.element.classList.remove("is-keyboard")
      return
    }

    const vv = window.visualViewport
    const fromViewport = vv ? Math.round(window.innerHeight - vv.height - vv.offsetTop) : 0
    const fromBaseline = Math.round(this.baseHeight - this.visibleHeight())
    const inset = Math.max(0, fromViewport, fromBaseline)
    root.style.setProperty("--keyboard-inset", `${inset}px`)
    this.element.classList.toggle("is-keyboard", inset > 24)
    this.keepFieldVisible(field, vv)
  }

  keepFieldVisible(field, vv) {
    const scroller = document.scrollingElement || document.documentElement
    if (vv) {
      const rect = field.getBoundingClientRect()
      const top = vv.offsetTop + 16
      const bottom = vv.offsetTop + vv.height - 16
      if (rect.top >= top && rect.bottom <= bottom) return
      scroller.scrollTop += rect.top - (vv.offsetTop + (vv.height - rect.height) / 2)
      return
    }

    field.scrollIntoView({ block: "center", inline: "nearest", behavior: "auto" })
  }

  disconnect() {
    this.element.removeEventListener("focusin", this.onFocusIn)
    this.element.removeEventListener("focusout", this.onFocusOut)
    window.visualViewport?.removeEventListener("resize", this.onViewport)
    window.visualViewport?.removeEventListener("scroll", this.onViewport)
    window.removeEventListener("resize", this.onViewport)
    document.documentElement.style.setProperty("--keyboard-inset", "0px")
  }
}
