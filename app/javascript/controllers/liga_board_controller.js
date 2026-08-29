import { Controller } from "@hotwired/stimulus"
import { haptic } from "haptics"
import { audioLoader } from "platform/audio/loader"
import { http } from "platform/http/client"

export default class extends Controller {
  static targets = [
    "board", "youBar", "filters", "invitation",
    "friendRank", "friendScore", "friendPack", "friendProgress", "rivalProfileName",
    "friendAvatar", "friendFallback", "invitationTitle", "notificationWarning", "send", "sendLabel", "success", "error"
  ]
  static values = { createUrl: String }

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

  openInvitation(event) {
    const trigger = event.currentTarget
    if (trigger.disabled) return
    haptic("tap")
    this.opponentId = trigger.dataset.personId
    this.invitationTitleTarget.textContent = trigger.dataset.personName.toLocaleUpperCase(document.documentElement.lang || undefined)
    this.rivalProfileNameTarget.textContent = trigger.dataset.personName
    this.notificationWarningTarget.querySelector("span").textContent =
      this.notificationWarningTarget.dataset.template.replace("__RIVAL__", trigger.dataset.personName)
    this.friendRankTarget.textContent = `#${trigger.dataset.personRank}`
    this.friendScoreTarget.textContent = trigger.dataset.personScore
    this.friendPackTarget.textContent = trigger.dataset.personPack || this.friendPackTarget.dataset.emptyLabel
    this.friendProgressTarget.textContent = trigger.dataset.personPackProgress || ""
    this.friendProgressTarget.hidden = !trigger.dataset.personPackProgress
    this.friendAvatarTarget.hidden = !trigger.dataset.personAvatar
    this.friendFallbackTarget.hidden = Boolean(trigger.dataset.personAvatar)
    this.friendAvatarTarget.src = trigger.dataset.personAvatar || ""
    this.friendFallbackTarget.textContent = trigger.dataset.personName.trim().charAt(0)
    this.invitationTarget.classList.remove("is-sent")
    this.invitationTarget.removeAttribute("aria-busy")
    this.successTarget.hidden = true
    this.errorTarget.hidden = true
    this.sendTarget.hidden = false
    this.sendTarget.disabled = false
    this.sendTarget.classList.remove("is-sending")
    this.sendLabelTarget.textContent = this.sendLabelTarget.dataset.idleLabel
    this.invitationTarget.showModal()
  }

  async sendInvitation() {
    if (!this.opponentId || this.sendTarget.disabled) return
    haptic("tap")
    this.sendTarget.disabled = true
    this.sendTarget.classList.add("is-sending")
    this.sendLabelTarget.textContent = this.sendLabelTarget.dataset.sendingLabel
    this.invitationTarget.setAttribute("aria-busy", "true")
    try {
      await http.json(this.createUrlValue, {
        method: "POST",
        body: JSON.stringify({ opponent_id: this.opponentId, source: "leaderboard" })
      })
      audioLoader.play("duel_send")
      haptic("success")
      this.invitationTarget.classList.add("is-sent")
      this.successTarget.hidden = false
      this.errorTarget.hidden = true
      this.sendTarget.hidden = true
      const row = this.element.querySelector(`[data-liga-person-id="${CSS.escape(this.opponentId)}"]`)
      row?.classList.add("is-challenged")
      window.setTimeout(() => this.invitationTarget.close(), this.reduce ? 0 : 700)
    } catch (_) {
      this.sendTarget.disabled = false
      this.sendTarget.classList.remove("is-sending")
      this.sendLabelTarget.textContent = this.sendLabelTarget.dataset.idleLabel
      this.errorTarget.hidden = false
    } finally {
      this.invitationTarget.removeAttribute("aria-busy")
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
    const changedRows = Array.from(this.element.querySelectorAll("[data-liga-person-id]"))
      .map((row) => {
        const old = before[row.dataset.ligaPersonId]
        if (!old || old.rank === row.dataset.ligaRank) return null
        const box = row.getBoundingClientRect()
        const isNearViewport = box.bottom >= -window.innerHeight && box.top <= window.innerHeight * 2
        if (!isNearViewport) return null
        return { row, old, box }
      })
      .filter(Boolean)
      .slice(0, 12)

    changedRows.forEach(({ row, old, box }) => {
      row.classList.add("is-flipping", "is-rank-changed")
      const movement = row.animate([
        { transform: `translate(${old.x - box.x}px, ${old.y - box.y}px)`, zIndex: 4 },
        { transform: "translate(0, 0)", zIndex: 1 }
      ], { duration: 480, easing: "cubic-bezier(.16, 1, .3, 1)" })
      movement.finished
        .catch(() => {})
        .finally(() => row.classList.remove("is-flipping", "is-rank-changed"))
    })
  }
}
