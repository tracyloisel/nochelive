import { Controller } from "@hotwired/stimulus"
import { http } from "platform/http/client"
import { EffectScope } from "platform/lifecycle/effect_scope"

export default class extends Controller {
  static targets = ["form", "input", "list", "option", "status", "row", "selection", "selectionFrame", "selectionStatus"]
  static values = { errorMessage: String }

  connect() {
    this.effectScope = new EffectScope()
    this.index = -1
    if (this.hasSelectionFrameTarget) {
      this.effectScope.listen(this.selectionFrameTarget, "turbo:frame-load", () => this.selectionLoaded())
      this.effectScope.listen(this.selectionFrameTarget, "turbo:frame-missing", (event) => this.selectionMissing(event))
    }
    this.effectScope.listen(document, "turbo:fetch-request-error", (event) => this.fetchRequestError(event))
    this.restorePosition()
  }

  disconnect() {
    this.effectScope?.dispose()
    this.abort?.abort()
    this.moreAbort?.abort()
  }

  change() {
    this.cancelSuggest?.()
    this.clearSearchState()
    if (this.inputTarget.value.trim().length < 2) return this.close()
    this.cancelSuggest = this.effectScope.timeout(() => this.suggest(), 180)
  }

  async suggest() {
    this.abort?.abort()
    this.abort = new AbortController()
    const url = this.searchURL({ suggest: true })

    try {
      const response = await http.request(url, { signal: this.abort.signal }, { accept: "text/html" })
      if (response.redirected) return this.renderRedirectOption(response.url)
      await this.renderSearchResponse(response)
    } catch (error) {
      if (error.name === "AbortError") return
      if (error.response) return this.renderSearchResponse(error.response)
      this.showSearchError()
    }
  }

  async submit(event) {
    if (!window.Turbo) {
      this.formTarget.classList.add("is-loading")
      this.formTarget.setAttribute("aria-busy", "true")
      return
    }

    event.preventDefault()
    this.startSearchLoading()
    this.abort?.abort()
    this.abort = new AbortController()

    try {
      const response = await http.request(this.searchURL(), { signal: this.abort.signal }, { accept: "text/html" })
      if (response.redirected) return this.openResolvedURL(response.url)
      await this.renderSearchResponse(response)
      this.finishSearchLoading()
    } catch (error) {
      if (error.name === "AbortError") return this.finishSearchLoading()
      if (error.response) {
        await this.renderSearchResponse(error.response)
      } else {
        this.showSearchError()
      }
      this.finishSearchLoading()
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
    this.index = event.key === "ArrowDown"
      ? (this.index + 1) % options.length
      : (this.index - 1 + options.length) % options.length
    options.forEach((option, index) => option.setAttribute("aria-selected", index === this.index ? "true" : "false"))
    this.inputTarget.setAttribute("aria-activedescendant", options[this.index].id)
  }

  clear() {
    this.abort?.abort()
    this.inputTarget.value = ""
    this.statusTarget.textContent = ""
    this.clearSearchState()
    this.close(true)
  }

  choose(event) {
    this.close()
    const link = event.currentTarget
    if (link.dataset.turboFrame !== "library_selection") return

    const row = this.rowForURL(link.href)
    if (row) this.prepareSelection(row)
  }

  remember(event) {
    const row = event.currentTarget
    history.replaceState({ ...history.state, libraryScrollY: window.scrollY, libraryFocus: row.id }, "")
    if (row.dataset.turboFrame !== "library_selection") return

    this.prepareSelection(row)
  }

  navigateSelection(event) {
    const link = event.currentTarget
    if (link.dataset.turboFrame !== "library_selection") return

    link.classList.add("is-loading")
    link.setAttribute("aria-busy", "true")
    if (this.hasSelectionFrameTarget) this.selectionFrameTarget.setAttribute("aria-busy", "true")
  }

  closeSelectionOnEscape(event) {
    if (event.key !== "Escape" || event.defaultPrevented) return

    const selection = this.selectionElement()
    if (!selection || (!selection.contains(event.target) && !selection.contains(document.activeElement))) return

    event.preventDefault()
    event.stopPropagation()
    this.closeSelection()
  }

  closeSelection(event) {
    event?.preventDefault()

    const selection = this.selectionElement()
    if (!selection) return

    const origin = this.rowForSelection(selection)
    const frame = selection.closest("turbo-frame#library_selection") || (this.hasSelectionFrameTarget ? this.selectionFrameTarget : null)

    this.rowTargets.forEach((row) => {
      row.classList.remove("is-active", "is-loading")
      row.removeAttribute("aria-current")
      row.removeAttribute("aria-busy")
      if (row.hasAttribute("aria-expanded")) row.setAttribute("aria-expanded", "false")
    })
    frame?.removeAttribute("src")
    frame?.removeAttribute("aria-busy")
    frame?.replaceChildren()
    this.clearSelectionURL(origin)

    this.effectScope.frame(() => {
      origin?.scrollIntoView({ block: "center", behavior: "auto" })
      origin?.focus({ preventScroll: true })
    })
  }

  async loadMore(event) {
    event.preventDefault()

    const trigger = event.currentTarget
    if (trigger.getAttribute("aria-busy") === "true") return

    const selection = trigger.closest("#selection")
    const list = selection?.querySelector("#scripture-library-selection-items")
    const currentItem = trigger.closest(".scripture-library-selection__list-item")
    if (!selection || !list || !currentItem) return

    this.moreAbort?.abort()
    this.moreAbort = new AbortController()
    const restoreFocus = document.activeElement === trigger
    this.setMoreLoading(trigger, list, selection)

    try {
      const response = await http.request(trigger.href, { signal: this.moreAbort.signal }, { accept: "text/html" })
      if (!response.ok || response.redirected) throw new Error("Unable to load more library items")

      const responseDocument = new DOMParser().parseFromString(await response.text(), "text/html")
      const incomingSelection = responseDocument.querySelector("#selection")
      const incomingList = incomingSelection?.querySelector("#scripture-library-selection-items")
      const incomingItems = [...(incomingList?.children || [])]
      if (!incomingItems.length || incomingSelection?.dataset.selectionKey !== selection.dataset.selectionKey) {
        throw new Error("Unexpected library pagination response")
      }

      const appendedItems = incomingItems.map((item) => document.importNode(item, true))
      currentItem.replaceWith(...appendedItems)
      this.selectionStatusFor(selection).textContent = selection.dataset.moreLoadedMessage || ""
      list.removeAttribute("aria-busy")

      if (restoreFocus) {
        appendedItems.find((item) => item.querySelector("a"))?.querySelector("a")?.focus({ preventScroll: true })
      }
    } catch (error) {
      if (error.name === "AbortError") return
      this.selectionStatusFor(selection).textContent = selection.dataset.moreErrorMessage || ""
      trigger.classList.remove("is-loading")
      trigger.removeAttribute("aria-busy")
      list.removeAttribute("aria-busy")
    } finally {
      this.moreAbort = null
    }
  }

  selectionLoaded() {
    this.clearLoadingStates()
    this.finishSearchLoading()
    this.statusTarget.textContent = ""
    this.statusTarget.classList.remove("is-error")
    this.effectScope.frame(() => {
      // Turbo emits its frame event just before Stimulus has always refreshed
      // its target registry. Querying the settled frame keeps the keyboard
      // hand-off deterministic instead of leaving focus on the row.
      const selection = this.hasSelectionTarget
        ? this.selectionTarget
        : this.element.querySelector("#selection")
      if (!selection) return
      selection.focus({ preventScroll: true })
      selection.scrollIntoView({
        block: "start",
        behavior: "auto"
      })
    })
  }

  selectionElement() {
    return this.hasSelectionTarget ? this.selectionTarget : this.element.querySelector("#selection")
  }

  rowForSelection(selection) {
    return this.rowTargets.find((row) => row.dataset.libraryRow === selection.dataset.selectionKey)
  }

  clearSelectionURL(origin) {
    const url = new URL(window.location.href)
    url.searchParams.delete("section")
    url.searchParams.delete("collection")
    url.searchParams.delete("book")
    url.searchParams.delete("unit")
    url.searchParams.delete("cursor")
    url.searchParams.delete("anchor")
    url.hash = "choisir-lecture"
    window.history.replaceState(
      { ...(window.history.state || {}), libraryScrollY: window.scrollY, libraryFocus: origin?.id },
      "",
      `${url.pathname}${url.search}${url.hash}`
    )
  }

  selectionStatusFor(selection) {
    return selection.querySelector("[data-library-search-target~='selectionStatus']") || { textContent: "" }
  }

  setMoreLoading(trigger, list, selection) {
    trigger.classList.add("is-loading")
    trigger.setAttribute("aria-busy", "true")
    list.setAttribute("aria-busy", "true")
    this.selectionStatusFor(selection).textContent = selection.dataset.moreLoadingMessage || ""
  }

  selectionMissing(event) {
    event.preventDefault()
    this.clearLoadingStates()
    this.finishSearchLoading()
    this.showSearchError()
  }

  fetchRequestError(event) {
    if (!this.handlesFetchError(event)) return

    this.clearLoadingStates()
    this.finishSearchLoading()
    this.showSearchError()
  }

  handlesFetchError(event) {
    const target = event.target
    const targetIsNode = target instanceof Node
    if (target === this.formTarget || (targetIsNode && this.formTarget.contains(target))) return true
    if (this.hasSelectionFrameTarget &&
      (target === this.selectionFrameTarget || (targetIsNode && this.selectionFrameTarget.contains(target)))) return true

    const requestURL = event.detail?.request?.url
    if (!requestURL) return false

    try {
      const requestPath = new URL(requestURL, window.location.origin).pathname
      const searchPath = new URL(this.formTarget.action, window.location.origin).pathname
      const libraryPath = new URL(window.location.href).pathname
      const searchIsBusy = this.formTarget.classList.contains("is-loading")
      const selectionIsBusy = this.hasSelectionFrameTarget && this.selectionFrameTarget.getAttribute("aria-busy") === "true"
      return (searchIsBusy || selectionIsBusy) && [searchPath, libraryPath].includes(requestPath)
    } catch (_) {
      return false
    }
  }

  restorePosition() {
    const hash = decodeURIComponent(window.location.hash.slice(1))
    const anchor = hash ? document.getElementById(hash) : null
    if (anchor) {
      this.effectScope.frame(() => {
        anchor.scrollIntoView({ block: "start", behavior: "instant" })
        const focusTarget = anchor.id === "selection" ? anchor : anchor.closest("a, button") || anchor
        focusTarget.focus?.({ preventScroll: true })
        anchor.classList.add("is-arrival")
      })
      return
    }

    if (history.state?.libraryScrollY == null) return
    this.effectScope.frame(() => {
      window.scrollTo({ top: history.state.libraryScrollY, behavior: "instant" })
      document.getElementById(history.state.libraryFocus)?.focus({ preventScroll: true })
    })
  }

  searchURL({ suggest = false } = {}) {
    const url = new URL(this.formTarget.action, window.location.origin)
    url.searchParams.set("q", this.inputTarget.value)
    const locale = this.formTarget.querySelector("input[name=locale]")?.value
    if (locale) url.searchParams.set("locale", locale)
    if (suggest) url.searchParams.set("suggest", "1")
    return url
  }

  async renderSearchResponse(response) {
    const document = new DOMParser().parseFromString(await response.text(), "text/html")
    const list = document.querySelector("#scripture-library-suggestions")
    const status = document.querySelector("#scripture-library-search-status")
    this.listTarget.innerHTML = list?.innerHTML || ""
    const message = status?.textContent?.trim() || (!response.ok && this.hasErrorMessageValue ? this.errorMessageValue : "")
    this.statusTarget.textContent = message
    this.statusTarget.classList.toggle("is-error", Boolean(message))
    this.index = -1
    this.open(this.listTarget.children.length > 0)
  }

  renderRedirectOption(url) {
    const link = document.createElement("a")
    const reader = new URL(url, window.location.origin).pathname.includes("/escrituras/")
    link.href = url
    link.id = "scripture-library-option-0"
    link.role = "option"
    link.tabIndex = -1
    link.dataset.librarySearchTarget = "option"
    link.dataset.turboFrame = reader ? "_top" : "library_selection"
    link.dataset.action = reader
      ? "click->library-search#choose click->scripture-launcher#prepare"
      : "click->library-search#choose"
    if (!reader) link.dataset.turboAction = "advance"

    const label = document.createElement("span")
    label.textContent = this.inputTarget.value.trim()
    const arrow = document.createElement("b")
    arrow.setAttribute("aria-hidden", "true")
    arrow.textContent = "→"
    link.append(label, arrow)
    this.listTarget.replaceChildren(link)
    this.index = -1
    this.open(true)
  }

  openResolvedURL(url) {
    const resolved = new URL(url, window.location.origin)
    const reader = resolved.pathname.includes("/escrituras/")
    const target = reader ? "_top" : "library_selection"

    if (!reader) {
      const row = this.rowForURL(resolved)
      if (row) this.prepareSelection(row)
    }

    const link = document.createElement("a")
    link.href = resolved.toString()
    link.hidden = true
    link.dataset.turboFrame = target
    if (reader) {
      link.dataset.action = "click->scripture-launcher#prepare"
      link.dataset.scriptureChapterTitle = this.inputTarget.value.trim()
    } else {
      link.dataset.turboAction = "advance"
    }
    this.element.append(link)
    this.effectScope.frame(() => {
      link.click()
      if (reader) this.finishSearchLoading()
      this.effectScope.frame(() => link.remove())
    })
  }

  rowForURL(url) {
    const section = new URL(url, window.location.origin).searchParams.get("section")
    const key = { canon: "collection", program: "annual" }[section] || section
    return this.rowTargets.find((row) => row.dataset.libraryRow === key)
  }

  prepareSelection(row) {
    if (!this.hasSelectionFrameTarget) return
    this.rowTargets.forEach((candidate) => {
      candidate.classList.toggle("is-active", candidate === row)
      if (candidate === row) {
        candidate.setAttribute("aria-current", "true")
        candidate.setAttribute("aria-expanded", "true")
      } else {
        candidate.removeAttribute("aria-current")
        if (candidate.hasAttribute("aria-expanded")) candidate.setAttribute("aria-expanded", "false")
      }
    })
    row.after(this.selectionFrameTarget)
    row.classList.add("is-loading")
    row.setAttribute("aria-busy", "true")
    this.selectionFrameTarget.setAttribute("aria-busy", "true")
    const title = row.querySelector("strong")?.textContent?.trim()
    if (title) this.statusTarget.textContent = `${title}…`
  }

  startSearchLoading() {
    this.formTarget.classList.add("is-loading")
    this.formTarget.setAttribute("aria-busy", "true")
    this.formTarget.querySelectorAll("button, input").forEach((control) => { control.disabled = true })
  }

  finishSearchLoading() {
    this.formTarget.classList.remove("is-loading")
    this.formTarget.setAttribute("aria-busy", "false")
    this.formTarget.querySelectorAll("button, input").forEach((control) => { control.disabled = false })
  }

  clearSearchState() {
    this.statusTarget.textContent = ""
    this.statusTarget.classList.remove("is-error")
    this.finishSearchLoading()
  }

  clearLoadingStates() {
    this.rowTargets.forEach((row) => {
      row.classList.remove("is-loading")
      row.removeAttribute("aria-busy")
    })
    this.element.querySelectorAll(".scripture-library-selection__item.is-loading").forEach((item) => {
      item.classList.remove("is-loading")
      item.removeAttribute("aria-busy")
    })
    if (this.hasSelectionFrameTarget) this.selectionFrameTarget.removeAttribute("aria-busy")
  }

  showSearchError() {
    this.close()
    this.statusTarget.textContent = this.hasErrorMessageValue ? this.errorMessageValue : ""
    this.statusTarget.classList.add("is-error")
  }

  open(show) {
    this.listTarget.hidden = !show
    this.inputTarget.setAttribute("aria-expanded", show ? "true" : "false")
  }

  close(focus = false) {
    this.open(false)
    this.index = -1
    this.inputTarget.removeAttribute("aria-activedescendant")
    if (focus) this.inputTarget.focus()
  }
}
