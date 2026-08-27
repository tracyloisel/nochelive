import { Controller } from "@hotwired/stimulus"
import { haptic } from "haptics"

export default class extends Controller {
  static targets = [
    "board", "youBar", "filters", "challenge", "opponentName",
    "opponentMeta", "challengeTitle", "send", "success"
  ]
  static values = { createUrl: String, packId: String }

  connect() {
    this.reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches
    this.firstVisit()
    this.observeYou()
    this.animateFromSnapshot()
    this.beforeCache = () => this.snapshot()
    document.addEventListener("turbo:before-cache", this.beforeCache)
  }

  disconnect() {
    this.youObserver?.disconnect()
    document.removeEventListener("turbo:before-cache", this.beforeCache)
  }

  firstVisit() {
    const key = "noche_liga_seen"
    let seen = false
    try {
      seen = sessionStorage.getItem(key) === "1"
      sessionStorage.setItem(key, "1")
    } catch (_) { /* private mode */ }
    if (seen || this.reduce) this.element.classList.remove("is-liga-enter")
  }

  observeYou() {
    if (!this.hasYouBarTarget) return
    const you = this.element.querySelector("#liga-you")
    if (!you) return
    this.youObserver = new IntersectionObserver(([entry]) => {
      this.youBarTarget.classList.toggle("is-hidden", entry.isIntersecting)
    }, { threshold: 0.35 })
    this.youObserver.observe(you)
  }

  searchFocus() {
    this.element.classList.add("is-searching")
  }

  searchBlur(event) {
    if (!event.currentTarget.value) this.element.classList.remove("is-searching")
  }

  openFilters() {
    this.filtersTarget.showModal()
  }

  resetFilters() {
    const ward = this.filtersTarget.querySelector("[name=ward_code]")
    const pack = this.filtersTarget.querySelector("[name=filter_pack_id][value='']")
    if (ward) ward.checked = true
    if (pack) pack.checked = true
  }

  applyFilters() {
    const ward = this.filtersTarget.querySelector("[name=ward_code]:checked")?.value
    const pack = this.filtersTarget.querySelector("[name=filter_pack_id]:checked")?.value
    if (!ward) return
    this.filtersTarget.close()
    this.boardTarget.classList.add("is-filtering")
    const url = new URL(`/ramas/${encodeURIComponent(ward)}/liga`, window.location.origin)
    if (pack) url.searchParams.set("pack_id", pack)
    window.setTimeout(() => window.Turbo.visit(url.toString()), this.reduce ? 0 : 180)
  }

  openChallenge(event) {
    const trigger = event.currentTarget
    if (trigger.disabled) return
    haptic("tap")
    this.opponentId = trigger.dataset.personId
    this.opponentNameTarget.textContent = trigger.dataset.personName
    this.challengeTitleTarget.textContent = `${trigger.dataset.personName}`
    this.opponentMetaTarget.textContent = `#${trigger.dataset.personRank} · ${trigger.dataset.personScore}`
    this.successTarget.hidden = true
    this.sendTarget.hidden = false
    this.challengeTarget.showModal()
  }

  async sendChallenge() {
    if (!this.opponentId || this.sendTarget.disabled) return
    haptic("tap")
    this.sendTarget.disabled = true
    this.sendTarget.classList.add("is-sending")
    try {
      const token = document.querySelector("meta[name=csrf-token]")?.content
      const response = await fetch(this.createUrlValue, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          "X-CSRF-Token": token
        },
        body: JSON.stringify({ opponent_id: this.opponentId, pack_id: this.packIdValue })
      })
      if (!response.ok) throw new Error("challenge failed")
      window.NocheLiveAudio?.play?.("duel_send")
      haptic("success")
      this.challengeTarget.classList.add("is-sent")
      this.successTarget.hidden = false
      this.sendTarget.hidden = true
      const row = this.element.querySelector(`[data-liga-person-id="${CSS.escape(this.opponentId)}"]`)
      row?.classList.add("is-challenged")
      window.setTimeout(() => this.challengeTarget.close(), this.reduce ? 0 : 700)
    } catch (_) {
      this.sendTarget.disabled = false
      this.sendTarget.classList.remove("is-sending")
    }
  }

  leaveForChallenges() {
    this.snapshot()
    document.documentElement.dataset.streetTransition = "forward"
  }

  snapshot() {
    const rows = {}
    this.element.querySelectorAll("[data-liga-person-id]").forEach((row) => {
      const box = row.getBoundingClientRect()
      rows[row.dataset.ligaPersonId] = { x: box.x, y: box.y, rank: row.dataset.ligaRank }
    })
    try { sessionStorage.setItem("noche_liga_positions", JSON.stringify(rows)) } catch (_) { /* no-op */ }
  }

  animateFromSnapshot() {
    if (this.reduce) return
    let before
    try {
      before = JSON.parse(sessionStorage.getItem("noche_liga_positions") || "null")
      sessionStorage.removeItem("noche_liga_positions")
    } catch (_) { return }
    if (!before) return
    this.element.querySelectorAll("[data-liga-person-id]").forEach((row) => {
      const old = before[row.dataset.ligaPersonId]
      if (!old || old.rank === row.dataset.ligaRank) return
      const box = row.getBoundingClientRect()
      row.animate([
        { transform: `translate(${old.x - box.x}px, ${old.y - box.y}px)`, zIndex: 4 },
        { transform: "translate(0, 0)", zIndex: 1 }
      ], { duration: 450, easing: "cubic-bezier(.16, 1, .3, 1)" })
      row.classList.add("is-rank-changed")
    })
  }
}
