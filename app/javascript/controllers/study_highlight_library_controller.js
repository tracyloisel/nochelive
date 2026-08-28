import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "item", "query", "filter", "more", "empty", "results" ]
  static values = {
    limit: { type: Number, default: 8 },
    moreTemplate: String,
    less: String,
    resultsTemplate: String
  }

  connect() {
    this.collection = "all"
    this.expanded = false
    this.render()
  }

  search() {
    this.expanded = false
    this.render()
  }

  filter(event) {
    this.collection = event.currentTarget.dataset.collection
    this.expanded = false
    this.filterTargets.forEach((button) => {
      const selected = button === event.currentTarget
      button.classList.toggle("is-active", selected)
      button.setAttribute("aria-pressed", selected ? "true" : "false")
    })
    this.render()
  }

  toggleMore() {
    this.expanded = !this.expanded
    this.render()
  }

  render() {
    const query = this.normalize(this.queryTarget.value)
    const matches = this.itemTargets.filter((item) => {
      const sameCollection = this.collection === "all" || item.dataset.collection === this.collection
      const sameText = !query || this.normalize(item.dataset.searchText).includes(query)
      return sameCollection && sameText
    })
    const showEveryMatch = query.length > 0 || this.expanded

    this.itemTargets.forEach((item) => {
      const matchIndex = matches.indexOf(item)
      item.hidden = matchIndex < 0 || (!showEveryMatch && matchIndex >= this.limitValue)
    })

    this.emptyTarget.hidden = matches.length > 0
    this.resultsTarget.textContent = this.resultsTemplateValue.replace("__COUNT__", matches.length)
    const remaining = Math.max(0, matches.length - this.limitValue)
    this.moreTarget.hidden = query.length > 0 || remaining === 0
    this.moreTarget.textContent = this.expanded
      ? this.lessValue
      : this.moreTemplateValue.replace("__COUNT__", remaining)
    this.moreTarget.setAttribute("aria-expanded", this.expanded ? "true" : "false")
  }

  normalize(value) {
    return String(value || "")
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLocaleLowerCase()
      .trim()
  }
}
