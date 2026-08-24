import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "tab", "pane", "query", "row", "empty" ]
  static values = {
    night: String,
    tab: { type: String, default: "respuestas" }
  }

  connect() {
    const stored = sessionStorage.getItem(this.tabKey)
    if (stored === "respuestas" || stored === "marcador") this.tabValue = stored
    this.apply()
    if (!this.hasQueryTarget) return

    const query = sessionStorage.getItem(this.queryKey)
    if (query) this.queryTarget.value = query
    this.filter()
  }

  show(event) {
    const pane = event.currentTarget.dataset.deskPane
    if (!pane) return

    this.tabValue = pane
    sessionStorage.setItem(this.tabKey, pane)
    this.apply()
  }

  filter() {
    if (!this.hasQueryTarget) return

    const needle = this.fold(this.queryTarget.value)
    sessionStorage.setItem(this.queryKey, this.queryTarget.value)
    let shown = 0
    this.rowTargets.forEach((row) => {
      const match = !needle || this.fold(row.dataset.deskHay || row.textContent).includes(needle)
      row.hidden = !match
      if (match) shown += 1
    })
    if (this.hasEmptyTarget) this.emptyTarget.hidden = shown > 0 || needle === ""
  }

  apply() {
    this.paneTargets.forEach((pane) => {
      pane.hidden = pane.dataset.deskPane !== this.tabValue
    })
    this.tabTargets.forEach((tab) => {
      const on = tab.dataset.deskPane === this.tabValue
      tab.classList.toggle("is-on", on)
      tab.classList.toggle("btn-navy", on)
      tab.classList.toggle("btn-ghost", !on)
      tab.setAttribute("aria-selected", on ? "true" : "false")
    })
  }

  get tabKey() {
    return `noche-desk-tab:${this.nightValue}`
  }

  get queryKey() {
    return `noche-desk-q:${this.nightValue}`
  }

  fold(value) {
    return value.toString().toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "")
  }
}
