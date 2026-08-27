import { Controller } from "@hotwired/stimulus"

// Controls the challenge duel bar animation.
// On connect: bar grows from center to match scores.
// On Turbo update: rival score change triggers micro pop + "+N" near avatar.
export default class extends Controller {
  static targets = ["bar", "youScore", "themScore", "youFace", "themFace"]
  static values = { youScore: Number, themScore: Number }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.settle()
      return
    }

    this.paintBar()
  }

  paintBar() {
    if (!this.hasBarTarget) return
    const youScore = this.youScoreValue
    const themScore = this.themScoreValue
    const total = youScore + themScore
    if (total <= 0) return
    this.barTarget.style.setProperty("--hub-you-share", `${youScore / total * 100}%`)
    requestAnimationFrame(() => this.barTarget.classList.add("is-drawn"))
  }

  settle() {
    this.paintBar()
    this.barTarget?.classList.add("is-drawn")
    this.element.classList.add("is-settled")
  }
}
