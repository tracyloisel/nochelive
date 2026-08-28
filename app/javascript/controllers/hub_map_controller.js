import { Controller } from "@hotwired/stimulus"
import { haptic } from "haptics"

export default class extends Controller {
  static targets = ["node", "tier", "expandBtn"]
  static values = { category: String, currentPackId: String }

  connect() {
    this.element.classList.add("is-entering")
    requestAnimationFrame(() => requestAnimationFrame(() => this.element.classList.add("is-ready")))
    this.focusTimer = window.setTimeout(() => this.focusCurrent(), 650)
  }

  disconnect() {
    window.clearTimeout(this.focusTimer)
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
    requestAnimationFrame(() => node.classList.add("is-denied"))
    this.nodeTargets.forEach((other) => other.classList.toggle("is-explaining", other === node))
    window.clearTimeout(this.hintTimer)
    this.hintTimer = window.setTimeout(() => node.classList.remove("is-explaining"), 2600)
    haptic("miss")
  }

  focusCurrent() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    const current = this.nodeTargets.find((node) => node.dataset.packId === this.currentPackIdValue)
    if (!current) return

    const hudBottom = document.querySelector(".home-menu.is-hud")?.getBoundingClientRect().bottom || 0
    const dockTop = document.querySelector(".navigation-dock")?.getBoundingClientRect().top || window.innerHeight
    const rect = current.getBoundingClientRect()
    const breathingRoom = 16
    const alreadyVisible = rect.top >= hudBottom + breathingRoom && rect.bottom <= dockTop - breathingRoom

    if (!alreadyVisible) current.scrollIntoView({ behavior: "smooth", block: "center" })
  }
}
