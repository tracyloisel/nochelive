import { Controller } from "@hotwired/stimulus"

const FOCUS_KEY = "noche:profile-editor-focus"
const RESULT_KEY = "noche:profile-editor-result"

export default class extends Controller {
  static targets = [ "input", "count", "sheet" ]
  static values = { key: String, countLabel: String, cancelUrl: String }

  connect() {
    this.updateCount()
  }

  disconnect() {
    window.clearTimeout(this.leaveTimer)
  }

  updateCount() {
    if (!this.hasInputTarget || !this.hasCountTarget) return

    const maximum = Number(this.inputTarget.maxLength)
    const count = this.inputTarget.value.length
    this.countTarget.textContent = `${count}/${maximum}`
    this.countTarget.setAttribute("aria-label", this.countLabelValue.replace("__COUNT__", count.toString()))
  }

  rememberFocus() {
    try {
      sessionStorage.setItem(FOCUS_KEY, this.keyValue)
    } catch (_) {}
  }

  close(event) {
    event.preventDefault()
    const destination = event.currentTarget.href || this.cancelUrlValue
    this.leave(destination)
  }

  closeFromBackdrop(event) {
    if (event.target !== this.element) return

    event.preventDefault()
    this.leave(this.cancelUrlValue)
  }

  closeOnEscape(event) {
    if (event.key !== "Escape") return

    event.preventDefault()
    this.leave(this.cancelUrlValue)
  }

  leave(destination) {
    if (this.element.classList.contains("is-loading") || this.element.classList.contains("is-leaving")) return

    this.rememberFocus()
    if (this.reduced()) {
      this.navigate(destination)
      return
    }

    this.element.classList.add("is-leaving")
    let finished = false
    const finish = () => {
      if (finished) return

      finished = true
      this.sheetTarget.removeEventListener("animationend", onAnimationEnd)
      window.clearTimeout(this.leaveTimer)
      this.navigate(destination)
    }
    const onAnimationEnd = (animationEvent) => {
      if (animationEvent.animationName === "profile-editor-sheet-leave") finish()
    }
    this.sheetTarget.addEventListener("animationend", onAnimationEnd)
    this.leaveTimer = window.setTimeout(finish, 280)
  }

  navigate(destination) {
    if (window.Turbo) {
      window.Turbo.visit(destination)
    } else {
      window.location.assign(destination)
    }
  }

  beginSubmit(event) {
    this.rememberFocus()
    this.element.classList.add("is-loading")
    this.element.setAttribute("aria-busy", "true")
    event.currentTarget.querySelectorAll("button[type=submit]").forEach((control) => {
      control.disabled = true
    })
  }

  finishSubmit(event) {
    if (event.detail.success) {
      try {
        sessionStorage.setItem(RESULT_KEY, this.keyValue)
      } catch (_) {}
      return
    }

    try {
      sessionStorage.removeItem(RESULT_KEY)
    } catch (_) {}
    this.element.classList.remove("is-loading")
    this.element.removeAttribute("aria-busy")
    event.target.querySelectorAll("button[type=submit]").forEach((control) => {
      control.disabled = false
    })
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
