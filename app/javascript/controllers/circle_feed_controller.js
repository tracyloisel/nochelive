import { Controller } from "@hotwired/stimulus"

const COMPOSER_SELECTOR = "[data-circle-composer]"
const DRAFT_FIELD_SELECTOR = [
  "textarea",
  "select",
  "input:not([type='hidden']):not([type='button']):not([type='submit']):not([type='reset']):not([type='image'])",
  "[contenteditable='true']"
].join(", ")

// The Circle receives deliberately content-free WebSocket signals. Reloading
// the live frame keeps the current query and lets the server remain the single
// source of truth, but a remote update must never replace a member's composer.
export default class extends Controller {
  static targets = [ "liveFeed", "refreshNotice", "pendingRefresh", "refreshAction" ]

  connect() {
    this.focusLiveFeedAfterLoad = false
    this.realtimeRefreshPending = false
    this.preservedComposerDrafts = []
    this.submittingComposers = new Set()
    this.pendingRefreshCheck = null
    this.deferredRefreshTimer = null

    this.refreshFromStream = this.refreshFromStream.bind(this)
    this.composerChanged = this.composerChanged.bind(this)
    this.composerFocusChanged = this.composerFocusChanged.bind(this)
    this.composerSubmitStarted = this.composerSubmitStarted.bind(this)
    this.composerSubmitFinished = this.composerSubmitFinished.bind(this)
    this.refreshNow = this.refreshNow.bind(this)

    this.element.addEventListener("circle:refresh", this.refreshFromStream)
    document.addEventListener("input", this.composerChanged)
    document.addEventListener("change", this.composerChanged)
    document.addEventListener("focusin", this.composerFocusChanged)
    document.addEventListener("focusout", this.composerFocusChanged)
    document.addEventListener("turbo:submit-start", this.composerSubmitStarted)
    document.addEventListener("turbo:submit-end", this.composerSubmitFinished)

    this.syncPendingRefreshControls()
    this.resizeCircleComposers()
  }

  disconnect() {
    this.element.removeEventListener("circle:refresh", this.refreshFromStream)
    document.removeEventListener("input", this.composerChanged)
    document.removeEventListener("change", this.composerChanged)
    document.removeEventListener("focusin", this.composerFocusChanged)
    document.removeEventListener("focusout", this.composerFocusChanged)
    document.removeEventListener("turbo:submit-start", this.composerSubmitStarted)
    document.removeEventListener("turbo:submit-end", this.composerSubmitFinished)

    if (this.pendingRefreshCheck) window.clearTimeout(this.pendingRefreshCheck)
    if (this.deferredRefreshTimer) window.clearTimeout(this.deferredRefreshTimer)
    this.submittingComposers.clear()
  }

  key(event) {
    if ([ "Enter", " " ].includes(event.key)) this.focusLiveFeedAfterLoad = true
  }

  filter(event) {
    // A keyboard activation first marks the intent in `key`. Keep that mark
    // when the browser follows with a click event whose detail is omitted.
    this.focusLiveFeedAfterLoad ||= event.detail === 0
    if (this.modifiedActivation(event)) return
    this.frameForLink(event.currentTarget)?.setAttribute("aria-busy", "true")
  }

  liveLoaded(event) {
    const frame = event.currentTarget
    frame.removeAttribute("busy")
    frame.setAttribute("aria-busy", "false")
    this.syncCurrentURL(frame)
    this.restorePreservedComposerDrafts()
    this.resizeCircleComposers(frame)
    this.focusAfterLiveFeedLoad(frame)
    this.markUpdated(frame)
    this.refreshIfPending()
  }

  refreshFromStream() {
    if (!this.hasLiveFeedTarget) return

    if (this.refreshMustWait()) {
      this.deferRealtimeRefresh()
      return
    }

    this.refreshLiveFeed()
  }

  refreshNow(event) {
    event?.preventDefault()
    if (!this.hasLiveFeedTarget) return

    // This is an explicit member choice. Snapshot the active composer(s) so
    // even this opt-in refresh cannot drop text while Turbo swaps the frame.
    this.manualRefreshRequested = true
    if (this.refreshLiveFeed({ force: true, preserveDrafts: true })) {
      this.manualRefreshRequested = false
    }
  }

  refreshLiveFeed({ force = false, preserveDrafts = false } = {}) {
    if (!this.hasLiveFeedTarget) return false

    if (!force && this.composersNeedProtection()) {
      this.deferRealtimeRefresh()
      return false
    }

    if (this.framesBusy()) {
      this.deferRealtimeRefresh()
      return false
    }

    if (preserveDrafts) this.preserveComposerDrafts()
    else this.preservedComposerDrafts = []

    const frame = this.liveFeedTarget
    const currentURL = window.location.href
    this.clearDeferredRefresh()
    frame.setAttribute("aria-busy", "true")

    if (frame.src === currentURL && typeof frame.reload === "function") {
      frame.reload()
    } else {
      frame.src = currentURL
    }

    return true
  }

  refreshIfPending() {
    if (!this.realtimeRefreshPending || this.framesBusy()) return

    const force = this.manualRefreshRequested === true
    if (!force && this.composersNeedProtection()) {
      this.syncPendingRefreshControls()
      return
    }

    if (this.deferredRefreshTimer) return
    this.deferredRefreshTimer = window.setTimeout(() => {
      this.deferredRefreshTimer = null
      if (!this.realtimeRefreshPending || this.framesBusy()) return
      if (this.refreshLiveFeed({ force, preserveDrafts: force })) this.manualRefreshRequested = false
    }, 0)
  }

  composerChanged(event) {
    const composer = this.composerFor(event.target)
    if (!composer) return

    // A validation response returns its text as the field default value, so
    // it needs an explicit protection marker until the member edits it. Once
    // they do, native dirty-field comparison takes over.
    composer.removeAttribute("data-has-draft")
    this.queuePendingRefreshCheck()
  }

  resizeComposer(event) {
    const field = event.currentTarget
    if (!(field instanceof HTMLTextAreaElement)) return
    this.resizeComposerField(field)
  }

  submitShortcut(event) {
    if (event.key !== "Enter" || (!event.metaKey && !event.ctrlKey) || event.altKey) return

    const field = event.currentTarget
    const composer = this.composerFor(field)
    const form = field instanceof HTMLTextAreaElement ? field.closest("form") : null
    if (!composer || !form) return

    // Cmd/Ctrl+Enter is a send affordance, never an accidental extra newline.
    event.preventDefault()
    if (this.isComposerSubmitting(composer)) return

    const submit = form.querySelector("button[data-circle-submit], button[type='submit'], input[type='submit']")
    if (!(submit instanceof HTMLElement) || submit.matches(":disabled")) return

    if (typeof form.requestSubmit === "function") form.requestSubmit(submit)
    else submit.click()
  }

  composerFocusChanged(event) {
    if (!this.composerFor(event.target)) return
    // Let focus settle first: focus may simply be moving to another control in
    // the same composer, which should keep a stream refresh deferred.
    this.queuePendingRefreshCheck()
  }

  composerSubmitStarted(event) {
    const composer = this.composerFor(event.target)
    if (!composer) return

    this.submittingComposers.add(composer)
    this.queuePendingRefreshCheck()
  }

  composerSubmitFinished(event) {
    const composer = this.composerFor(event.target)
    if (!composer) return

    this.submittingComposers.delete(composer)
    this.queuePendingRefreshCheck()
  }

  queuePendingRefreshCheck() {
    if (!this.realtimeRefreshPending || this.pendingRefreshCheck) return

    this.pendingRefreshCheck = window.setTimeout(() => {
      this.pendingRefreshCheck = null
      this.refreshIfPending()
    }, 0)
  }

  resizeCircleComposers(scope = this.element) {
    const fields = scope instanceof HTMLTextAreaElement
      ? [ scope ]
      : Array.from(scope.querySelectorAll(`${COMPOSER_SELECTOR} textarea`))
    fields.forEach((field) => this.resizeComposerField(field))
  }

  resizeComposerField(field) {
    // `rows=4` establishes the readable minimum. The stylesheet owns the cap
    // and scrolling behavior so Light and Dark shells can tune it together.
    field.style.height = "auto"
    field.style.height = `${field.scrollHeight}px`
  }

  focusAfterLiveFeedLoad(frame) {
    if (!this.focusLiveFeedAfterLoad) return

    this.focusLiveFeedAfterLoad = false
    const target = frame.querySelector("[data-circle-feed-focus]") || frame.querySelector("[aria-current='page']")
    target?.focus({ preventScroll: true })
  }

  refreshMustWait() {
    return this.framesBusy() || this.composersNeedProtection()
  }

  composersNeedProtection() {
    return this.circleComposers().some((composer) => (
      this.isComposerFocused(composer) ||
      this.isComposerDirty(composer) ||
      this.isComposerSubmitting(composer)
    ))
  }

  circleComposers() {
    this.submittingComposers.forEach((composer) => {
      if (!composer.isConnected) this.submittingComposers.delete(composer)
    })
    return Array.from(document.querySelectorAll(COMPOSER_SELECTOR)).filter((composer) => composer.isConnected)
  }

  composerFor(node) {
    const element = node instanceof Element ? node : node?.parentElement
    return element?.closest(COMPOSER_SELECTOR) || null
  }

  isComposerFocused(composer) {
    return composer.contains(document.activeElement)
  }

  isComposerSubmitting(composer) {
    return this.submittingComposers.has(composer) ||
      composer.dataset.circleSubmitting === "true" ||
      composer.getAttribute("aria-busy") === "true"
  }

  isComposerDirty(composer) {
    if (composer.dataset.circleComposerDirty === "true" || composer.dataset.hasDraft === "true") return true

    const shell = composer.closest("[data-circle-composer-shell]")
    if (shell?.dataset.hasDraft === "true") return true

    return this.draftFields(composer).some((field) => this.fieldIsDirty(field))
  }

  draftFields(composer, { includeDisabled = false } = {}) {
    return Array.from(composer.querySelectorAll(DRAFT_FIELD_SELECTOR))
      .filter((field) => includeDisabled || !field.disabled)
  }

  fieldIsDirty(field) {
    if (field.isContentEditable) return field.textContent !== (field.dataset.circleInitialValue || "")
    if (field instanceof HTMLInputElement && [ "checkbox", "radio" ].includes(field.type)) return field.checked !== field.defaultChecked
    if (field instanceof HTMLSelectElement) return Array.from(field.options).some((option) => option.selected !== option.defaultSelected)
    if (field instanceof HTMLInputElement && field.type === "file") return field.files?.length > 0
    return field.value !== field.defaultValue
  }

  deferRealtimeRefresh() {
    this.realtimeRefreshPending = true
    this.syncPendingRefreshControls()
  }

  clearDeferredRefresh() {
    this.realtimeRefreshPending = false
    this.syncPendingRefreshControls()
  }

  syncPendingRefreshControls() {
    if (!this.hasPendingRefreshTarget || !this.hasRefreshActionTarget) return

    const pending = this.realtimeRefreshPending === true
    this.element.toggleAttribute("data-circle-feed-refresh-pending", pending)
    if (this.hasRefreshNoticeTarget) this.refreshNoticeTarget.hidden = !pending
    this.pendingRefreshTarget.hidden = !pending
    this.refreshActionTarget.hidden = !pending

    if (!pending) return

    const liveRegion = this.hasRefreshNoticeTarget ? this.refreshNoticeTarget : this.pendingRefreshTarget
    liveRegion.setAttribute("role", "status")
    liveRegion.setAttribute("aria-live", "polite")
    liveRegion.setAttribute("aria-atomic", "true")
    this.pendingRefreshTarget.textContent = this.pendingRefreshMessage()
    this.refreshActionTarget.textContent = this.refreshActionLabel()
    if (!this.refreshActionTarget.hasAttribute("aria-controls") && this.liveFeedTarget.id) {
      this.refreshActionTarget.setAttribute("aria-controls", this.liveFeedTarget.id)
    }
  }

  pendingRefreshMessage() {
    return this.pendingRefreshTarget.dataset.circleFeedPendingRefreshMessage ||
      this.element.dataset.circleFeedPendingRefreshMessage ||
      this.pendingRefreshTarget.textContent.trim()
  }

  refreshActionLabel() {
    return this.refreshActionTarget.dataset.circleFeedRefreshLabel ||
      this.element.dataset.circleFeedRefreshLabel ||
      this.refreshActionTarget.textContent.trim()
  }

  preserveComposerDrafts() {
    const frame = this.liveFeedTarget
    const composers = this.circleComposers().filter((composer) => frame.contains(composer))
    this.preservedComposerDrafts = composers.reduce((snapshots, composer, index) => {
      if (this.isComposerFocused(composer) || this.isComposerDirty(composer) || this.isComposerSubmitting(composer)) {
        snapshots.push(this.snapshotComposer(composer, index))
      }
      return snapshots
    }, [])
  }

  snapshotComposer(composer, index) {
    const occurrence = new Map()
    return {
      key: this.composerKey(composer, index),
      fields: this.draftFields(composer, { includeDisabled: true }).map((field) => this.snapshotField(field, occurrence))
    }
  }

  snapshotField(field, occurrence) {
    const key = this.fieldKey(field, occurrence)
    return {
      key,
      value: field.isContentEditable ? field.textContent : field.value,
      checked: field instanceof HTMLInputElement ? field.checked : undefined,
      selected: field instanceof HTMLSelectElement
        ? Array.from(field.options).map((option) => option.selected)
        : undefined
    }
  }

  restorePreservedComposerDrafts() {
    if (!this.preservedComposerDrafts.length || !this.hasLiveFeedTarget) return

    const snapshots = this.preservedComposerDrafts
    this.preservedComposerDrafts = []
    const composers = this.circleComposers().filter((composer) => this.liveFeedTarget.contains(composer))
    const used = new Set()

    snapshots.forEach((snapshot, index) => {
      const composer = composers.find((candidate, candidateIndex) => (
        !used.has(candidate) && this.composerKey(candidate, candidateIndex) === snapshot.key
      ))
      if (!composer) return

      used.add(composer)
      this.restoreComposerSnapshot(composer, snapshot)
    })
  }

  restoreComposerSnapshot(composer, snapshot) {
    const fieldsByKey = new Map(snapshot.fields.map((field) => [ field.key, field ]))
    const occurrence = new Map()

    this.draftFields(composer, { includeDisabled: true }).forEach((field) => {
      const saved = fieldsByKey.get(this.fieldKey(field, occurrence))
      if (!saved) return

      if (field.isContentEditable) field.textContent = saved.value
      else if (field instanceof HTMLSelectElement && saved.selected) {
        Array.from(field.options).forEach((option, index) => { option.selected = Boolean(saved.selected[index]) })
      } else if (field instanceof HTMLInputElement && [ "checkbox", "radio" ].includes(field.type)) {
        field.checked = Boolean(saved.checked)
      } else if (!(field instanceof HTMLInputElement && field.type === "file")) {
        field.value = saved.value
      }

      const eventName = field instanceof HTMLSelectElement ||
        (field instanceof HTMLInputElement && [ "checkbox", "radio" ].includes(field.type)) ? "change" : "input"
      field.dispatchEvent(new Event(eventName, { bubbles: true }))
    })
  }

  composerKey(composer, index) {
    const parentId = composer.querySelector('input[name="post[parent_id]"]')?.value || ""
    const reference = composer.querySelector('input[name="post[reference]"]')?.value || ""
    return composer.dataset.circleComposerId || composer.id || [ composer.dataset.circleComposerKind || "post", parentId, reference, index ].join(":")
  }

  fieldKey(field, occurrence) {
    if (field.id) return `id:${field.id}`
    const base = field.getAttribute("name") || field.dataset.circleDraftField || field.tagName.toLowerCase()
    const count = occurrence.get(base) || 0
    occurrence.set(base, count + 1)
    return `${base}:${count}`
  }

  frameForLink(link) {
    if (!(link instanceof HTMLAnchorElement)) return null
    const frameId = link.dataset.turboFrame
    if (this.hasLiveFeedTarget && frameId === this.liveFeedTarget.id) return this.liveFeedTarget
    return null
  }

  framesBusy() {
    if (!this.hasLiveFeedTarget) return false
    return this.liveFeedTarget.hasAttribute("busy") || this.liveFeedTarget.getAttribute("aria-busy") === "true"
  }

  markUpdated(frame) {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return

    frame.classList.remove("is-updated")
    void frame.offsetWidth
    frame.classList.add("is-updated")
  }

  syncCurrentURL(frame) {
    const url = frame.dataset.circleFeedUrl
    if (!url) return

    const resolved = new URL(url, window.location.href)
    if (resolved.origin !== window.location.origin) return
    if (resolved.href === window.location.href) return

    window.history.replaceState(window.history.state, "", resolved.href)
  }

  modifiedActivation(event) {
    return event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button > 0
  }
}
