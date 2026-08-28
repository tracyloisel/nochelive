import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dialog", "title", "whatsapp", "x", "copyStatus" ]

  open(event) {
    event.preventDefault()
    const button = event.currentTarget
    this.url = new URL(button.dataset.shareUrl, window.location.origin).href
    const title = button.dataset.shareTitle || document.title
    const message = button.dataset.shareMessage || title

    this.titleTarget.textContent = title
    const whatsapp = new URL("https://wa.me/")
    whatsapp.searchParams.set("text", `${message}\n${this.url}`)
    this.whatsappTarget.href = whatsapp.href

    const x = new URL("https://twitter.com/intent/tweet")
    x.searchParams.set("text", message)
    x.searchParams.set("url", this.url)
    this.xTarget.href = x.href
    this.copyStatusTarget.hidden = true
    this.dialogTarget.showModal()
    this.dialogTarget.focus({ preventScroll: true })
  }

  close(event) {
    event?.preventDefault()
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close(event)
  }

  closed() {
    this.copyStatusTarget.hidden = true
  }

  async copyLink(event) {
    event.preventDefault()
    if (!this.url) return

    try {
      await navigator.clipboard.writeText(this.url)
    } catch (_error) {
      this.copyWithFallback(this.url)
    }
    this.copyStatusTarget.hidden = false
  }

  copyWithFallback(value) {
    const field = document.createElement("textarea")
    field.value = value
    field.setAttribute("readonly", "")
    field.style.position = "fixed"
    field.style.opacity = "0"
    document.body.appendChild(field)
    field.select()
    document.execCommand("copy")
    field.remove()
  }
}
