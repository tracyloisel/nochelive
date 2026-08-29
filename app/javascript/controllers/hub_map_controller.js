import { Controller } from "@hotwired/stimulus"
import { haptic } from "haptics"
import { EffectScope } from "platform/lifecycle/effect_scope"

export default class extends Controller {
  static targets = ["node", "tier", "expandBtn"]
  static values = { category: String, currentPackId: String }

  connect() {
    this.effectScope = new EffectScope()
    this.element.classList.add("is-entering")
    this.effectScope.frame(() => this.effectScope.frame(() => this.element.classList.add("is-ready")))
  }

  disconnect() {
    this.effectScope?.dispose()
    window.clearTimeout(this.hintTimer)
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

}
