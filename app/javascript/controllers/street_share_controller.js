import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    text: String,
    title: String,
    pack: String,
    copied: String,
    failed: String
  }

  invite(event) {
    const button = event.currentTarget
    const url = button.dataset.streetShareUrlValue || this.urlValue || window.location.href
    const text = button.dataset.streetShareTextValue || this.textValue || ""
    const title = button.dataset.streetShareTitleValue || this.titleValue || document.title
    this.shareOrCopy({ url, text, title })
  }

  share(event) {
    event.preventDefault()
    this.shareOrCopy({
      url: this.urlValue || window.location.href,
      text: this.textValue || "",
      title: this.titleValue || document.title
    })
  }

  async challenge(event) {
    event.preventDefault()
    const packId = this.packValue || event.currentTarget.dataset.streetSharePackValue
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
        body: JSON.stringify({ pack_id: packId })
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
      this.shareOrCopy({ url, text, title: this.titleValue || document.title })
    } catch (_) {
      this.toast(this.failMessage())
    }
  }

  async shareOrCopy({ url, text, title }) {
    const payload = { title, text: text ? `${text} ${url}` : url, url }
    if (navigator.share) {
      try {
        await navigator.share(payload)
        return
      } catch (_) {
        /* fall through */
      }
    }
    try {
      await navigator.clipboard.writeText(payload.text || url)
      this.toast()
    } catch (_) {
      this.toast(this.failMessage())
    }
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
