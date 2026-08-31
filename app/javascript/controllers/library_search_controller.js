import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "list", "option", "status", "row"]

  connect() {
    this.index = -1
    this.restorePosition()
    this.revealRows()
  }

  disconnect() {
    window.clearTimeout(this.timer)
    this.abort?.abort()
    this.observer?.disconnect()
  }

  change() {
    window.clearTimeout(this.timer)
    if (this.inputTarget.value.trim().length < 2) return this.close()
    this.timer = window.setTimeout(() => this.suggest(), 180)
  }

  async suggest() {
    this.abort?.abort()
    this.abort = new AbortController()
    const url = new URL(this.formTarget.action, window.location.origin)
    url.searchParams.set("q", this.inputTarget.value)
    const locale = this.formTarget.querySelector("input[name=locale]")?.value
    if (locale) url.searchParams.set("locale", locale)
    url.searchParams.set("suggest", "1")
    try {
      const response = await fetch(url, { headers: { Accept: "text/html" }, signal: this.abort.signal })
      if (response.redirected) return this.close()
      const document = new DOMParser().parseFromString(await response.text(), "text/html")
      const list = document.querySelector("#scripture-library-suggestions")
      const status = document.querySelector("#scripture-library-search-status")
      this.listTarget.innerHTML = list?.innerHTML || ""
      this.statusTarget.textContent = status?.textContent?.trim() || ""
      this.index = -1
      this.open(this.listTarget.children.length > 0)
    } catch (error) {
      if (error.name !== "AbortError") this.close()
    }
  }

  keydown(event) {
    const options = [...this.listTarget.querySelectorAll("[role=option]")]
    if (event.key === "Escape") return this.close(true)
    if (!["ArrowDown", "ArrowUp", "Enter"].includes(event.key) || options.length === 0) return
    if (event.key === "Enter" && this.index >= 0) {
      event.preventDefault()
      return options[this.index].click()
    }
    if (event.key === "Enter") return
    event.preventDefault()
    this.index = event.key === "ArrowDown" ? (this.index + 1) % options.length : (this.index - 1 + options.length) % options.length
    options.forEach((option, index) => option.setAttribute("aria-selected", index === this.index ? "true" : "false"))
    this.inputTarget.setAttribute("aria-activedescendant", options[this.index].id)
  }

  clear() {
    this.inputTarget.value = ""
    this.close(true)
  }

  submit() { this.formTarget.classList.add("is-loading") }

  remember(event) {
    const row = event.currentTarget
    history.replaceState({ ...history.state, libraryScrollY: window.scrollY, libraryFocus: row.id }, "")
  }

  restorePosition() {
    const anchor = window.location.hash && document.querySelector(window.location.hash)
    if (anchor) {
      window.requestAnimationFrame(() => {
        anchor.scrollIntoView({ block: "center", behavior: "instant" })
        anchor.focus({ preventScroll: true })
        anchor.classList.add("is-arrival")
      })
      return
    }
    if (history.state?.libraryScrollY == null) return
    window.requestAnimationFrame(() => {
      window.scrollTo({ top: history.state.libraryScrollY, behavior: "instant" })
      document.getElementById(history.state.libraryFocus)?.focus({ preventScroll: true })
    })
  }

  revealRows() {
    if (!("IntersectionObserver" in window) || window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.rowTargets.forEach((row) => row.classList.add("is-revealed"))
      return
    }
    this.observer = new IntersectionObserver((entries) => entries.forEach((entry) => {
      if (!entry.isIntersecting) return
      entry.target.classList.add("is-revealed")
      this.observer.unobserve(entry.target)
    }), { rootMargin: "0px 0px -5%", threshold: 0.08 })
    this.rowTargets.forEach((row) => this.observer.observe(row))
  }

  open(show) {
    this.listTarget.hidden = !show
    this.inputTarget.setAttribute("aria-expanded", show ? "true" : "false")
  }

  close(focus = false) {
    this.open(false)
    this.inputTarget.removeAttribute("aria-activedescendant")
    if (focus) this.inputTarget.focus()
  }
}
