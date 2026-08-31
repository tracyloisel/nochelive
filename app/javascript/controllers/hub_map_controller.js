import { Controller } from "@hotwired/stimulus"
import { haptic } from "haptics"
import { EffectScope } from "platform/lifecycle/effect_scope"

export default class extends Controller {
  static targets = ["node", "tier", "expandBtn", "expeditionRail", "expeditionPrevious", "expeditionNext", "expeditionDot"]
  static values = { category: String, currentPackId: String, view: String }

  connect() {
    this.effectScope = new EffectScope()
    this.element.classList.add("is-entering")
    this.effectScope.frame(() => this.effectScope.frame(() => this.element.classList.add("is-ready")))
    this.expeditionResizeObserver = window.ResizeObserver
      ? new window.ResizeObserver(() => this.updateExpeditionControls())
      : null
    if (this.hasExpeditionRailTarget) {
      this.expeditionResizeObserver?.observe(this.expeditionRailTarget)
      this.centerSelectedExpedition()
      this.updateExpeditionControls()
    }
  }

  disconnect() {
    this.effectScope?.dispose()
    window.clearTimeout(this.hintTimer)
    this.expeditionResizeObserver?.disconnect()
  }

  prepareNavigation(event) {
    const destination = event.currentTarget.dataset.mapDestination
    if (!destination) return

    const direction = destination === "detail"
      ? "detail"
      : destination === "journey" && this.viewValue === "expeditions"
        ? "back"
        : destination === "expeditions" && this.viewValue === "journey"
          ? "forward"
          : "same"

    document.documentElement.dataset.streetMapTransition = direction
    window.setTimeout(() => {
      if (document.documentElement.dataset.streetMapTransition === direction) {
        delete document.documentElement.dataset.streetMapTransition
      }
    }, 900)
  }

  filter(event) {
    const category = event.currentTarget.dataset.category
    this.categoryValue = category
    this.element.querySelectorAll(".mapa-tab").forEach((tab) => {
      const active = tab.dataset.category === category
      tab.classList.toggle("is-active", active)
      tab.setAttribute("aria-selected", active ? "true" : "false")
    })
    this.nodeTargets.forEach((node) => node.classList.toggle("is-category-muted", node.dataset.category !== category))
    haptic("tap")
  }

  toggleTier(event) {
    const tier = event.currentTarget.closest(".mapa-tier")
    if (!tier?.classList.contains("is-collapsed")) return
    const open = tier.classList.toggle("is-open")
    const button = tier.querySelector(".mapa-tier-expand")
    button?.setAttribute("aria-expanded", open ? "true" : "false")
    haptic("tap")
  }

  tapNode(event) {
    const node = event.currentTarget
    if (!node.classList.contains("is-locked")) return
    event.preventDefault()
    node.classList.remove("is-denied")
    this.effectScope.frame(() => node.classList.add("is-denied"))
    this.nodeTargets.forEach((other) => other.classList.toggle("is-explaining", other === node))
    window.clearTimeout(this.hintTimer)
    this.hintTimer = window.setTimeout(() => node.classList.remove("is-explaining"), 2600)
    haptic("miss")
  }

  scrollExpeditions(event) {
    if (!this.hasExpeditionRailTarget) return

    const direction = Number(event.currentTarget.dataset.direction || 1)
    const distance = Math.max(this.expeditionRailTarget.clientWidth * 0.84, 240)
    this.expeditionRailTarget.scrollBy({
      left: direction * distance,
      behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "auto" : "smooth"
    })
    haptic("tap")
  }

  updateExpeditionControls() {
    if (!this.hasExpeditionRailTarget) return

    const rail = this.expeditionRailTarget
    const maxScroll = Math.max(rail.scrollWidth - rail.clientWidth, 0)
    const atStart = rail.scrollLeft <= 2
    const atEnd = rail.scrollLeft >= maxScroll - 2
    this.setExpeditionControlState(this.hasExpeditionPreviousTarget ? this.expeditionPreviousTarget : null, atStart)
    this.setExpeditionControlState(this.hasExpeditionNextTarget ? this.expeditionNextTarget : null, atEnd)
    this.updateExpeditionDots()
  }

  centerSelectedExpedition() {
    const rail = this.expeditionRailTarget
    const selected = rail.querySelector(".mapa-expedition-card.is-active")
    if (!selected) return

    const target = selected.offsetLeft - ((rail.clientWidth - selected.offsetWidth) / 2)
    rail.scrollLeft = Math.max(0, target)
  }

  setExpeditionControlState(control, disabled) {
    if (!control) return

    control.disabled = disabled
    control.setAttribute("aria-disabled", disabled ? "true" : "false")
  }

  updateExpeditionDots() {
    if (!this.hasExpeditionRailTarget || !this.hasExpeditionDotTarget) return

    const cards = Array.from(this.expeditionRailTarget.querySelectorAll(".mapa-expedition-card"))
    if (!cards.length) return

    const viewportCenter = this.expeditionRailTarget.scrollLeft + (this.expeditionRailTarget.clientWidth / 2)
    const nearestIndex = cards.reduce((nearest, card, index) => {
      const cardCenter = card.offsetLeft + (card.offsetWidth / 2)
      const nearestDistance = Math.abs((cards[nearest]?.offsetLeft + (cards[nearest]?.offsetWidth / 2)) - viewportCenter)
      return Math.abs(cardCenter - viewportCenter) < nearestDistance ? index : nearest
    }, 0)

    this.expeditionDotTargets.forEach((dot, index) => dot.classList.toggle("is-active", index === nearestIndex))
  }

}
