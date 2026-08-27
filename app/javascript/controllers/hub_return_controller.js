import { Controller } from "@hotwired/stimulus"

// Handles quiz return reward injection.
// Triggered by data-returning-from-quiz attribute or Turbo turbo:render event.
// Sequential reward animations (total ~1.5s).
export default class extends Controller {
  static values = { quizCompleted: Boolean, rankUp: Boolean }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    this.processReturn()
  }

  processReturn() {
    // Check for return state
    const returning = this.element.classList.contains("is-returning-from-quiz")
    const rankUp = this.hasRankUpValue && this.rankUpValue
    const quizCompleted = this.hasQuizCompletedValue && this.quizCompletedValue

    if (!returning && !rankUp && !quizCompleted) return

    const sequence = [
      // 1. Hero already visible
      { delay: 0, action: () => {} },
      // 2. Pack complete badge
      { delay: 200, action: () => this.showPackComplete() },
      // 3. Chest opens
      { delay: 500, action: () => this.openChest() },
      // 4. Crown increment
      { delay: 800, action: () => this.incrementCrowns() },
      // 5. Streak grows
      { delay: 1000, action: () => this.growStreak() },
      // 6. XP bar advances
      { delay: 1200, action: () => this.advanceXPBar() },
      // 7. New pack appears
      { delay: 1400, action: () => this.revealNewPack() },
    ]

    sequence.forEach(({ delay, action }) => {
      setTimeout(action, delay)
    })
  }

  showPackComplete() {
    const badge = this.element.querySelector(".hub-pack-complete")
    if (badge) {
      badge.classList.add("is-pop-in")
    }
  }

  openChest() {
    const chest = this.element.querySelector(".hub-reward-chest")
    if (chest) {
      chest.classList.add("is-opening")
    }
  }

  incrementCrowns() {
    const crownEl = this.element.querySelector(".quiz-hud-score span[data-score], .hub-reward-value span")
    if (crownEl && crownEl.dataset.gain) {
      const gain = parseInt(crownEl.dataset.gain, 10)
      if (gain > 0) {
        const float = document.createElement("span")
        float.className = "is-gain-float"
        float.textContent = `+${gain}`
        crownEl.appendChild(float)
        float.addEventListener("animationend", () => float.remove(), { once: true })
      }
    }
  }

  growStreak() {
    const streak = this.element.querySelector(".quiz-hud-streak")
    if (streak) {
      streak.classList.add("is-grew")
      const handler = () => streak.classList.remove("is-grew")
      streak.addEventListener("animationend", handler, { once: true })
    }
  }

  advanceXPBar() {
    const xpBar = this.element.querySelector(".quiz-progress-bar")
    if (xpBar) {
      xpBar.classList.add("is-advancing")
    }
  }

  revealNewPack() {
    const newPack = this.element.querySelector(".hub-slide.is-new")
    if (newPack) {
      newPack.classList.add("is-revealed")
    }
  }
}