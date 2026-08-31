import { Controller } from "@hotwired/stimulus"

const SNAPS = ["open", "mid", "peek"]
const AVOID = "button, a, input, textarea, select, .choice-btn, .quiz-bar, .quiz-next, label, .btn, summary, details, .home-menu"

export default class extends Controller {
  static targets = ["handle", "body"]
  static values = {
    snap: { type: String, default: "mid" },
    peekRatio: { type: Number, default: 0.16 },
    midRatio: { type: Number, default: 0.52 },
    openLabel: { type: String, default: "" },
    midLabel: { type: String, default: "" },
    peekLabel: { type: String, default: "" }
  }

  connect() {
    this.shift = 0
    this.dragging = false
    this.moved = false
    this.onMove = this.onMove.bind(this)
    this.onUp = this.onUp.bind(this)
    this.layout()
    this.snapTo(this.snapValue, false)
    this.resize = () => {
      if (this.dragging) return
      this.layout()
      this.shift = this.points[this.snapValue] ?? this.points.mid
      this.paint()
    }
    window.addEventListener("resize", this.resize)
    this.ro = new ResizeObserver(this.resize)
    this.ro.observe(this.element)
  }

  disconnect() {
    window.removeEventListener("resize", this.resize)
    this.ro?.disconnect()
    this.unbind()
  }

  start(event) {
    if (event.pointerType === "mouse" && event.button !== 0) return
    if (event.target.closest(AVOID) && !event.target.closest("[data-sheet-target=handle]")) return
    if (this.snapValue === "open" && this.inBody(event.target) && !event.target.closest("[data-sheet-target=handle]")) return

    this.dragging = true
    this.moved = false
    this.startSnap = this.snapValue
    this.startY = event.clientY
    this.startShift = this.shift
    this.lastY = event.clientY
    this.lastAt = performance.now()
    this.velocity = 0
    this.element.classList.add("is-dragging")
    event.target.setPointerCapture?.(event.pointerId)
    window.addEventListener("pointermove", this.onMove)
    window.addEventListener("pointerup", this.onUp)
    window.addEventListener("pointercancel", this.onUp)
  }

  cycle(event) {
    if (this.moved) return
    this.layout()
    const start = SNAPS.indexOf(this.snapValue)
    for (let step = 1; step <= SNAPS.length; step += 1) {
      const name = SNAPS[(start + step) % SNAPS.length]
      if (Math.abs(this.points[name] - this.points[this.snapValue]) > 16) {
        this.snapTo(name, true)
        break
      }
    }
    event.preventDefault()
  }

  onMove(event) {
    if (!this.dragging) return
    const y = event.clientY
    const delta = y - this.startY
    if (Math.abs(delta) > 6) this.moved = true
    const now = performance.now()
    const dt = Math.max(1, now - this.lastAt)
    this.velocity = (y - this.lastY) / dt
    this.lastY = y
    this.lastAt = now
    this.shift = this.clamp(this.startShift + delta)
    this.paint()
  }

  onUp() {
    if (!this.dragging) return
    this.dragging = false
    this.element.classList.remove("is-dragging")
    this.unbind()
    if (this.startSnap === "peek" && this.moved && (this.velocity > 0.5 || (this.shift - this.startShift) > 72)) {
      this.dispatch("dismiss")
      this.snapTo("peek", true)
      return
    }
    this.snapTo(this.nearest(), true)
  }

  layout() {
    const vh = this.element.parentElement?.clientHeight || window.innerHeight
    const height = this.element.offsetHeight || vh * 0.9
    this.points = {
      open: 0,
      mid: Math.max(0, height - vh * this.midRatioValue),
      peek: Math.max(0, height - vh * this.peekRatioValue)
    }
  }

  nearest() {
    this.layout()
    if (this.velocity > 0.55) return this.snapValue === "open" ? "mid" : "peek"
    if (this.velocity < -0.55) return this.snapValue === "peek" ? "mid" : "open"
    return SNAPS.reduce((best, name) => {
      const closer = Math.abs(this.shift - this.points[name]) < Math.abs(this.shift - this.points[best])
      return closer ? name : best
    }, this.snapValue)
  }

  snapTo(name, animate) {
    this.layout()
    this.snapValue = SNAPS.includes(name) ? name : "mid"
    this.shift = this.points[this.snapValue]
    this.element.dataset.sheetSnap = this.snapValue
    this.element.classList.toggle("is-animating", animate && !this.reduced())
    this.paint()
    this.announce()
  }

  paint() {
    this.element.style.setProperty("--sheet-shift", `${this.shift}px`)
  }

  clamp(value) {
    this.layout()
    return Math.min(this.points.peek, Math.max(this.points.open, value))
  }

  announce() {
    if (!this.hasHandleTarget) return
    const labels = {
      open: this.openLabelValue,
      mid: this.midLabelValue,
      peek: this.peekLabelValue
    }
    const text = labels[this.snapValue]
    if (text) this.handleTarget.setAttribute("aria-valuetext", text)
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  unbind() {
    window.removeEventListener("pointermove", this.onMove)
    window.removeEventListener("pointerup", this.onUp)
    window.removeEventListener("pointercancel", this.onUp)
  }

  inBody(node) {
    if (this.hasBodyTarget) return this.bodyTarget.contains(node)
    return Boolean(node.closest(".play-sheet-body, .desk-pane"))
  }
}
