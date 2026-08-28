import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    text: String,
    title: String,
    pack: String,
    runId: Number,
    copied: String,
    failed: String,
    endpoint: String,
    duelToken: String,
    source: String,
    impression: String
  }

  connect() {
    if (!this.hasImpressionValue || !this.impressionValue) return

    const key = `noche:viral:${this.impressionValue}:${this.duelTokenValue || this.packValue || "none"}`
    try {
      if (sessionStorage.getItem(key)) return
      sessionStorage.setItem(key, "1")
    } catch (_) {
      /* privacy mode: tracking remains best-effort */
    }
    this.track(this.impressionValue)
  }

  invite(event) {
    const button = event.currentTarget
    const url = button.dataset.streetShareUrlValue || this.urlValue || window.location.href
    const text = button.dataset.streetShareTextValue || this.textValue || ""
    const title = button.dataset.streetShareTitleValue || this.titleValue || document.title
    if (this.hasDuelTokenValue) this.track("invite_share_opened", { channel: "native" })
    this.shareOrCopy({ url, text, title, duelToken: this.duelTokenValue })
  }

  share(event) {
    event.preventDefault()
    if (this.hasDuelTokenValue) this.track("invite_share_opened", { channel: "native" })
    this.shareOrCopy({
      url: this.urlValue || window.location.href,
      text: this.textValue || "",
      title: this.titleValue || document.title,
      duelToken: this.duelTokenValue
    })
  }

  async challenge(event) {
    event.preventDefault()
    const packId = this.packValue || event.currentTarget.dataset.streetSharePackValue
    const runId = this.runIdValue || event.currentTarget.dataset.streetShareRunIdValue
    const endpoint = event.currentTarget.dataset.streetShareUrlValue || "/desafios"
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    try {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": token,
          Accept: "application/json"
        },
        body: JSON.stringify({ pack_id: packId, run_id: runId || undefined })
      })
      if (!response.ok) {
        this.toast(this.failMessage())
        return
      }
      const data = await response.json()
      if (!data?.url) {
        this.toast(this.failMessage())
        return
      }
      const url = new URL(data.url, window.location.origin).href
      const text = this.textValue || event.currentTarget.dataset.streetShareTextValue || ""
      this.duelTokenValue = data.token
      this.track("invite_share_opened", { channel: "native", pack_id: packId }, data.token)
      this.shareOrCopy({ url, text, title: this.titleValue || document.title, duelToken: data.token })
    } catch (_) {
      this.toast(this.failMessage())
    }
  }

  async shareOrCopy({ url, text, title, duelToken }) {
    const payload = { title, text: text ? `${text} ${url}` : url, url }
    if (navigator.share) {
      try {
        await navigator.share(payload)
        if (duelToken) this.track("invite_share_completed", { channel: "native" }, duelToken)
        return
      } catch (error) {
        if (error?.name === "AbortError") return
        /* fall through */
      }
    }
    try {
      await navigator.clipboard.writeText(payload.text || url)
      if (duelToken) this.track("invite_share_completed", { channel: "clipboard" }, duelToken)
      this.toast()
    } catch (_) {
      this.toast(this.failMessage())
    }
  }

  track(name, properties = {}, duelToken = this.duelTokenValue) {
    const endpoint = this.endpointValue || "/viral-events"
    const body = JSON.stringify({
      name,
      duel_token: duelToken || undefined,
      source: this.sourceValue || undefined,
      properties
    })
    const token = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(endpoint, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": token, Accept: "application/json" },
      body,
      keepalive: true
    }).catch(() => {})
  }

  toast(message) {
    const node = document.createElement("p")
    node.className = "street-share-toast"
    node.setAttribute("role", "status")
    node.textContent = message || this.copyMessage()
    document.body.appendChild(node)
    requestAnimationFrame(() => node.classList.add("is-visible"))
    setTimeout(() => node.remove(), 2400)
  }

  failMessage() {
    if (this.hasFailedValue && this.failedValue) return this.failedValue
    return document.body.dataset.streetShareFailed || this.copyMessage()
  }

  copyMessage() {
    if (this.hasCopiedValue && this.copiedValue) return this.copiedValue
    const host = this.element.closest("[data-street-share-copied-value]")
    const fromHost = host?.dataset?.streetShareCopiedValue
    if (fromHost) return fromHost
    return document.body.dataset.streetShareCopied || "Enlace copiado"
  }
}
