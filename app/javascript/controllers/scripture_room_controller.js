import { Controller } from "@hotwired/stimulus"
import { http } from "platform/http/client"

const LOCAL_PREFERENCE_KEY = "noche:scripture-reader-preference:v1"
const RESULT_REFRESH_MS = 8_000
const MESSAGE_LIMIT = 500
const CIRCLE_DRAFT_PREFIX = "noche:scripture-circle-draft:v1"
const CIRCLE_PENDING_PREFIX = "noche:scripture-circle-pending:v1"
const CIRCLE_COMPOSER_MAX_HEIGHT = 208
const CIRCLE_SELECTION_LIMIT = 1_000
const CIRCLE_SELECTION_CONTEXT_TRANSITION_MS = 140
const PANEL_TRANSITION_MS = 160
const READING_SETTLE_MS = 170
const READING_EYELINE_RATIO = 0.43

export default class extends Controller {
  static targets = [
    "layout", "readingStage", "companion", "marksTrigger", "circleTrigger", "panel", "settingsDialog",
    "settingsStatus", "noteDialog", "noteSelection", "noteTitle", "noteBody", "noteIntent",
    "noteTags", "noteNotebook", "noteLink", "noteBookmark", "noteSave", "selectionStatus",
    "marksList", "illustration", "verses", "toolsDialog", "toolResult", "undoBanner", "undoMessage",
    "circleComposer", "circleSelectionContext", "circleSelectionReference", "circleSelectionQuote",
    "circleSelectionStart", "circleSelectionEnd", "circleSelectionText"
  ]

  connect() {
    this.onSelection = this.onSelection.bind(this)
    this.onScroll = this.onScroll.bind(this)
    this.onComposerSubmit = this.onComposerSubmit.bind(this)
    this.element.addEventListener("scripture:selection", this.onSelection)
    this.element.addEventListener("submit", this.onComposerSubmit)
    this.sheet = this.element.querySelector(".scripture-sheet")
    this.sheet?.addEventListener("scroll", this.onScroll, { passive: true })
    this.preferences = this.initialPreferences()
    this.markCache = this.readMarkCache()
    this.applyPreferences()
    this.showPanelName(this.element.dataset.scriptureRoomInitialPanel || "read", { scroll: false, animate: false })
    this.initializeCircleComposers()
    this.refreshModerationResults()
    this.resultTimer = window.setInterval(() => this.refreshModerationResults(), RESULT_REFRESH_MS)
    this.element.dataset.readerScrollState = "idle"
    this.updateReadingProgress()
    window.requestAnimationFrame(() => { this.element.dataset.readerReady = "true" })
  }

  disconnect() {
    this.element.removeEventListener("scripture:selection", this.onSelection)
    this.element.removeEventListener("submit", this.onComposerSubmit)
    this.sheet?.removeEventListener("scroll", this.onScroll)
    if (this.resultTimer) window.clearInterval(this.resultTimer)
    if (this.progressTimer) window.clearTimeout(this.progressTimer)
    if (this.progressFrame) window.cancelAnimationFrame(this.progressFrame)
    if (this.readingSettleTimer) window.clearTimeout(this.readingSettleTimer)
    if (this.statusTimer) window.clearTimeout(this.statusTimer)
    this.clearPanelTransition()
    this.clearReadingAnchor()
    this.clearCircleSelectionFocus()
    this.clearCircleSelectionContextMotion()
    if (this.circleEventTimer) window.clearTimeout(this.circleEventTimer)
    delete this.element.dataset.readerReady
    delete this.element.dataset.readerScrollState
  }

  onSelection(event) {
    this.selection = event.detail?.passage || null
  }

  showPanelName(panel, { scroll = true, animate = true, focus = true } = {}) {
    if (!["read", "marks", "circle"].includes(panel)) return
    const previousPanel = this.hasLayoutTarget ? this.layoutTarget.dataset.activePanel : this.element.dataset.activePanel
    const isReading = panel === "read"
    const panelChanged = previousPanel !== panel
    if (panel !== "circle") this.clearCircleSelectionFocus()
    if (panelChanged) this.clearPanelTransition()
    this.element.dataset.activePanel = panel
    if (this.hasLayoutTarget) this.layoutTarget.dataset.activePanel = panel
    if (this.hasCompanionTarget) this.companionTarget.hidden = isReading
    this.panelTargets.forEach((target) => { target.hidden = isReading || target.dataset.readerPanel !== panel })
    this.syncPanelTriggers(panel)
    if (scroll && !isReading && window.matchMedia("(max-width: 767px)").matches) this.sheet?.scrollTo({ top: 0, behavior: "auto" })
    if (animate && panelChanged && !isReading) this.animatePanelChange(panel)
    if (panel === "circle") this.refreshModerationResults()
    if (!isReading && animate && panelChanged && focus) this.focusCompanionHeading(panel)
  }

  openMarks(event) {
    this.openPanel("marks", event)
  }

  openCircle(event) {
    this.openPanel("circle", event)
  }

  openPanel(panel, event) {
    event?.preventDefault()
    if (!["marks", "circle"].includes(panel)) return
    this.readerFocusBeforeCompanion = event?.currentTarget || this.triggerForPanel(panel)
    this.showPanelName(panel)
  }

  returnToReading(event) {
    event?.preventDefault()
    const previousPanel = this.element.dataset.activePanel
    this.showPanelName("read")
    window.requestAnimationFrame(() => this.restoreReaderFocus(previousPanel))
  }

  syncPanelTriggers(panel) {
    if (this.hasMarksTriggerTarget) this.marksTriggerTarget.setAttribute("aria-expanded", String(panel === "marks"))
    if (this.hasCircleTriggerTarget) this.circleTriggerTarget.setAttribute("aria-expanded", String(panel === "circle"))
  }

  triggerForPanel(panel) {
    if (panel === "circle" && this.hasCircleTriggerTarget) return this.circleTriggerTarget
    if (panel === "marks" && this.hasMarksTriggerTarget) return this.marksTriggerTarget
    return null
  }

  restoreReaderFocus(panel) {
    const target = this.readerFocusBeforeCompanion || this.triggerForPanel(panel)
    target?.focus({ preventScroll: true })
    this.readerFocusBeforeCompanion = null
  }

  focusCompanionHeading(panel) {
    const section = this.panelTargets.find((candidate) => candidate.dataset.readerPanel === panel)
    const heading = section?.querySelector("h2")
    if (!heading) return
    window.requestAnimationFrame(() => {
      if (this.element.dataset.activePanel === panel && !section.hidden) heading.focus({ preventScroll: true })
    })
  }

  openSettings(event) {
    event?.preventDefault()
    if (!this.hasSettingsDialogTarget) return
    this.openReaderDialog(this.settingsDialogTarget, this.settingsDialogTarget.querySelector("button"))
  }

  async closeSettings(event) {
    event?.preventDefault()
    if (this.hasSettingsDialogTarget) await this.closeReaderDialog(this.settingsDialogTarget)
  }

  changePreference(event) {
    const input = event.currentTarget
    const key = input.dataset.preferenceKey
    if (!key) return
    this.preferences[key] = input.type === "checkbox" ? input.checked : (key === "font_scale" ? Number(input.value) : input.value)
    this.applyPreferences()
    this.persistPreferences()
  }

  initialPreferences() {
    const server = {
      font_scale: Number(this.element.dataset.scriptureRoomFontScale || 100),
      line_height_key: this.element.dataset.scriptureRoomLineHeight || "comfortable",
      measure_key: this.element.dataset.scriptureRoomMeasure || "comfortable",
      font_family_key: this.element.dataset.scriptureRoomFontFamily || "editorial",
      background_key: this.element.dataset.scriptureRoomBackground || "paper",
      illustrations_enabled: this.element.dataset.scriptureRoomIllustrations !== "false"
    }
    if (this.element.dataset.scriptureRoomPreferencesUrl) return server
    try {
      return { ...server, ...JSON.parse(window.localStorage.getItem(LOCAL_PREFERENCE_KEY) || "{}") }
    } catch (_error) {
      return server
    }
  }

  applyPreferences() {
    const values = this.preferences
    this.element.style.setProperty("--reader-font-scale", Number(values.font_scale) / 100)
    this.element.dataset.readerLineHeight = values.line_height_key
    this.element.dataset.readerMeasure = values.measure_key
    this.element.dataset.readerFont = values.font_family_key
    this.element.dataset.readerBackground = values.background_key
    this.element.dataset.readerIllustrations = values.illustrations_enabled ? "true" : "false"
    this.element.querySelectorAll("[data-preference-key]").forEach((input) => {
      const key = input.dataset.preferenceKey
      if (input.type === "checkbox") input.checked = Boolean(values[key])
      else input.checked = String(input.value) === String(values[key])
    })
  }

  async persistPreferences() {
    const url = this.element.dataset.scriptureRoomPreferencesUrl
    if (!url) {
      window.localStorage.setItem(LOCAL_PREFERENCE_KEY, JSON.stringify(this.preferences))
      this.showSettingsStatus(this.element.dataset.preferenceSaved)
      return
    }
    try {
      this.preferences = await http.json(url, {
        method: "PATCH",
        body: JSON.stringify({ preference: this.preferences })
      })
      this.applyPreferences()
      this.showSettingsStatus(this.element.dataset.preferenceSaved)
    } catch (_error) {
      this.showSettingsStatus(this.element.dataset.actionError, true)
    }
  }

  showSettingsStatus(message, error = false) {
    if (!this.hasSettingsStatusTarget || !message) return
    this.settingsStatusTarget.textContent = message
    this.settingsStatusTarget.dataset.state = error ? "error" : "success"
    this.restartFeedbackMotion(this.settingsStatusTarget)
  }

  highlightSelection(event) {
    event?.preventDefault()
    this.openAnnotation(event, "highlight")
  }

  bookmarkSelection(event) {
    event?.preventDefault()
    this.createMark({ visual_style: "none", bookmark: true })
  }

  openNote(event) {
    event?.preventDefault()
    this.openAnnotation(event, "note")
  }

  discussSelection(event) {
    event?.preventDefault()
    const selection = this.circleSelectionFromPassage(this.selection)
    if (!selection) return this.showSelectionStatus(this.element.dataset.actionError, true)
    if (selection.selectedText.length > CIRCLE_SELECTION_LIMIT) {
      return this.showSelectionStatus(this.element.dataset.circleSelectionLimitError, true)
    }
    if (this.element.dataset.scriptureRoomCircleMode !== "active" || !this.hasCircleComposerTarget) {
      return this.showSelectionStatus(this.element.dataset.circleUnavailable, true)
    }

    // The palette is transient; the durable, keyboard-safe return point is the Circle trigger.
    this.readerFocusBeforeCompanion = this.triggerForPanel("circle") || event?.currentTarget
    this.consumeNativeSelection()
    this.showPanelName("circle", { focus: false })
    this.setCircleSelection(selection, { animate: true })
    this.focusCircleComposerForSelection()
  }

  clearCircleSelection(event) {
    event?.preventDefault()
    this.setCircleSelection(null)
    const field = this.hasCircleComposerTarget ? this.circleComposerTarget.querySelector("textarea") : null
    field?.focus({ preventScroll: true })
  }

  circleSelectionFromPassage(passage) {
    const selectedText = passage?.text?.toString().replace(/\s+/g, " ").trim()
    const startVerse = Number.parseInt(passage?.startVerse, 10)
    const endVerse = Number.parseInt(passage?.endVerse, 10)
    if (!selectedText || !Number.isInteger(startVerse) || !Number.isInteger(endVerse) || startVerse < 1 || endVerse < startVerse) return null

    return {
      selectedText,
      startVerse,
      endVerse,
      referenceLabel: passage?.reference?.toString().trim() || ""
    }
  }

  normalizedCircleSelection(selection) {
    const selectedText = selection?.selectedText?.toString().replace(/\s+/g, " ").trim()
    const startVerse = Number.parseInt(selection?.startVerse, 10)
    const endVerse = Number.parseInt(selection?.endVerse, 10)
    if (!selectedText || selectedText.length > CIRCLE_SELECTION_LIMIT || !Number.isInteger(startVerse) || !Number.isInteger(endVerse) || startVerse < 1 || endVerse < startVerse) return null

    return {
      selectedText,
      startVerse,
      endVerse,
      referenceLabel: selection?.referenceLabel?.toString().trim() || ""
    }
  }

  setCircleSelection(selection, { animate = false, persist = true } = {}) {
    const ready = this.hasCircleComposerTarget && this.hasCircleSelectionContextTarget &&
      this.hasCircleSelectionReferenceTarget && this.hasCircleSelectionQuoteTarget &&
      this.hasCircleSelectionStartTarget && this.hasCircleSelectionEndTarget && this.hasCircleSelectionTextTarget
    if (!ready) return

    const context = this.normalizedCircleSelection(selection)
    this.circleSelectionStartTarget.value = context ? String(context.startVerse) : ""
    this.circleSelectionEndTarget.value = context ? String(context.endVerse) : ""
    this.circleSelectionTextTarget.value = context?.selectedText || ""
    this.circleSelectionReferenceTarget.textContent = context?.referenceLabel || ""
    this.circleSelectionQuoteTarget.textContent = context ? `“${context.selectedText}”` : ""
    this.circleSelectionContextTarget.hidden = !context

    if (context && animate) this.animateCircleSelectionContext()
    if (!context) this.clearCircleSelectionContextMotion()
    if (persist) this.persistCircleDraft(this.circleComposerTarget)
  }

  currentCircleSelection(form) {
    const isMainComposer = this.hasCircleComposerTarget && form === this.circleComposerTarget
    if (!isMainComposer || !this.hasCircleSelectionStartTarget || !this.hasCircleSelectionEndTarget || !this.hasCircleSelectionTextTarget) return null

    return this.normalizedCircleSelection({
      startVerse: this.circleSelectionStartTarget.value,
      endVerse: this.circleSelectionEndTarget.value,
      selectedText: this.circleSelectionTextTarget.value,
      referenceLabel: this.hasCircleSelectionReferenceTarget ? this.circleSelectionReferenceTarget.textContent : ""
    })
  }

  consumeNativeSelection() {
    window.getSelection()?.removeAllRanges()
    this.element.querySelector("[data-scripture-target='shareTrigger']")?.setAttribute("hidden", "")
  }

  focusCircleComposerForSelection() {
    this.clearCircleSelectionFocus()
    const delay = this.panelMotionEnabled() ? PANEL_TRANSITION_MS : 0
    this.circleSelectionFocusTimer = window.setTimeout(() => {
      this.circleSelectionFocusTimer = null
      if (this.element.dataset.activePanel !== "circle" || !this.hasCircleComposerTarget) return
      const field = this.circleComposerTarget.querySelector("textarea")
      if (!field) return
      this.resizeMessageField(field)
      field.focus({ preventScroll: true })
    }, delay)
  }

  clearCircleSelectionFocus() {
    if (this.circleSelectionFocusTimer) window.clearTimeout(this.circleSelectionFocusTimer)
    this.circleSelectionFocusTimer = null
  }

  animateCircleSelectionContext() {
    if (!this.hasCircleSelectionContextTarget || this.reducedMotion()) return
    this.clearCircleSelectionContextMotion()
    const context = this.circleSelectionContextTarget
    context.classList.remove("is-circle-selection-context-entering")
    void context.offsetWidth
    context.classList.add("is-circle-selection-context-entering")
    this.circleSelectionContextTimer = window.setTimeout(() => {
      context.classList.remove("is-circle-selection-context-entering")
      this.circleSelectionContextTimer = null
    }, CIRCLE_SELECTION_CONTEXT_TRANSITION_MS)
  }

  clearCircleSelectionContextMotion() {
    if (this.circleSelectionContextTimer) window.clearTimeout(this.circleSelectionContextTimer)
    this.circleSelectionContextTimer = null
    if (this.hasCircleSelectionContextTarget) this.circleSelectionContextTarget.classList.remove("is-circle-selection-context-entering")
  }

  openAnnotation(event, mode = "organize") {
    event?.preventDefault()
    if (!this.selection || !this.hasNoteDialogTarget) return
    this.editorReturnFocus = event?.currentTarget || this.editorReturnFocus
    const existing = this.markForSelection()
    this.editingMarkId = existing?.id || null
    this.populateEditor(existing, mode)
    const focusTarget = mode === "note" ? this.noteBodyTarget : this.noteDialogTarget.querySelector("input, select, textarea")
    this.openReaderDialog(this.noteDialogTarget, focusTarget)
  }

  async closeNote(event) {
    event?.preventDefault()
    if (this.hasNoteDialogTarget) await this.closeReaderDialog(this.noteDialogTarget)
    this.editorReturnFocus?.focus({ preventScroll: true })
  }

  async saveNote(event) {
    event?.preventDefault()
    const style = this.noteDialogTarget.querySelector('input[name="reader-note-style"]:checked')?.value || "none"
    const color = this.noteDialogTarget.querySelector('input[name="reader-note-color"]:checked')?.value || "gold"
    const saved = await this.createMark({
      visual_style: style,
      color_key: style === "none" ? null : color,
      intent_key: this.noteIntentTarget?.value || null,
      note_body: this.noteBodyTarget?.value?.trim() || null,
      bookmarked_at: this.noteBookmarkTarget?.checked ? new Date().toISOString() : null,
      tag_names: this.noteTagsTarget?.value || "",
      notebook_title: this.noteNotebookTarget?.value || "",
      target_reference: this.noteLinkTarget?.value || ""
    }, this.editingMarkId)
    if (saved) this.closeNote()
  }

  async createMark(extra, markId = null) {
    const passage = this.selection
    const url = this.element.dataset.scriptureRoomMarksUrl
    if (!passage || !url) return this.showSelectionStatus(this.element.dataset.actionError, true)
    const existing = markId ? this.markCache.find((mark) => Number(mark.id) === Number(markId)) : this.markForSelection()
    const payload = {
      reference: this.element.dataset.scriptureRoomReference,
      locale: this.element.dataset.scriptureRoomLocale,
      anchor_scope: passage.anchorScope || "passage",
      start_verse: passage.startVerse,
      start_offset: passage.startOffset,
      end_verse: passage.endVerse,
      end_offset: passage.endOffset,
      selected_text: passage.text,
      ...extra
    }
    try {
      const mark = await http.json(existing?.update_url || url, {
        method: existing ? "PATCH" : "POST",
        body: JSON.stringify({ mark: payload })
      })
      if (existing) this.element.dispatchEvent(new CustomEvent("scripture-room:mark-removed", { bubbles: true, detail: { id: existing.id } }))
      this.element.dispatchEvent(new CustomEvent("scripture-room:mark-created", { bubbles: true, detail: { mark } }))
      this.rememberMark(mark)
      this.appendMark(mark)
      this.showSelectionStatus(this.element.dataset.markSaved)
      return mark
    } catch (_error) {
      this.showSelectionStatus(this.element.dataset.markError, true)
      return null
    }
  }

  appendMark(mark) {
    if (!this.hasMarksListTarget) return
    this.marksListTarget.querySelector("[data-reader-marks-empty]")?.remove()
    this.marksListTarget.querySelector(`[data-mark-id="${mark.id}"]`)?.remove()
    const article = document.createElement("article")
    article.className = "reader-mark-card is-new"
    article.dataset.markId = mark.id
    article.dataset.markType = mark.note_body ? "note" : (mark.bookmarked_at ? "bookmark" : "highlight")
    const meta = document.createElement("strong")
    meta.textContent = mark.anchor_scope === "chapter" ? this.element.dataset.readerChapterTitle : (mark.start_verse === mark.end_verse ? `v.${mark.start_verse}` : `v.${mark.start_verse}–${mark.end_verse}`)
    article.append(meta)
    if (mark.selected_text) {
      const quote = document.createElement("blockquote")
      quote.textContent = `“${mark.selected_text}”`
      article.append(quote)
    }
    if (mark.note_body) {
      const note = document.createElement("p")
      note.textContent = mark.note_body
      article.append(note)
    }
    const taxonomyValues = [mark.intent_key, ...(mark.tags || []).map((tag) => `#${tag}`), ...(mark.notebooks || []).map((notebook) => notebook.title), ...(mark.links || []).map((link) => `↗ ${link.reference}`)].filter(Boolean)
    if (taxonomyValues.length) {
      const taxonomy = document.createElement("div")
      taxonomy.className = "reader-mark-taxonomy"
      taxonomyValues.forEach((value) => { const item = document.createElement("span"); item.textContent = value; taxonomy.append(item) })
      article.append(taxonomy)
    }
    if (mark.delete_url) {
      const actions = document.createElement("div")
      actions.className = "reader-mark-actions"
      const edit = document.createElement("button")
      edit.type = "button"
      edit.className = "reader-text-action"
      edit.dataset.action = "scripture-room#editMark"
      edit.dataset.markId = mark.id
      edit.textContent = this.element.dataset.markUpdateLabel
      const remove = document.createElement("button")
      remove.type = "button"
      remove.className = "reader-text-action"
      remove.dataset.action = "scripture-room#removeMark"
      remove.dataset.markUrl = mark.delete_url
      remove.textContent = this.element.dataset.markDeleteLabel
      actions.append(edit, remove)
      article.append(actions)
    }
    this.marksListTarget.append(article)
  }

  async removeMark(event) {
    const button = event.currentTarget
    try {
      await http.json(button.dataset.markUrl, { method: "DELETE" })
      const card = button.closest("[data-mark-id]")
      const id = card?.dataset.markId
      this.removedMark = this.markCache.find((mark) => Number(mark.id) === Number(id))
      this.markCache = this.markCache.filter((mark) => Number(mark.id) !== Number(id))
      if (this.removedMark?.anchor_scope === "chapter") this.setChapterBookmarkState(false)
      card?.remove()
      this.element.dispatchEvent(new CustomEvent("scripture-room:mark-removed", { bubbles: true, detail: { id } }))
      this.showUndo()
    } catch (_error) {
      this.showSelectionStatus(this.element.dataset.actionError, true)
    }
  }

  async restoreMark(event) {
    event?.preventDefault()
    if (!this.removedMark?.restore_url) return
    try {
      const mark = await http.json(this.removedMark.restore_url, { method: "POST" })
      this.rememberMark(mark)
      this.appendMark(mark)
      if (mark.anchor_scope === "chapter") this.setChapterBookmarkState(true, mark.id)
      this.element.dispatchEvent(new CustomEvent("scripture-room:mark-created", { bubbles: true, detail: { mark } }))
      this.hideUndo()
    } catch (_error) {
      this.showSelectionStatus(this.element.dataset.actionError, true)
    }
  }

  showUndo() {
    if (!this.hasUndoBannerTarget || !this.removedMark) return
    this.undoBannerTarget.hidden = false
    this.restartFeedbackMotion(this.undoBannerTarget)
    if (this.undoTimer) window.clearTimeout(this.undoTimer)
    this.undoTimer = window.setTimeout(() => this.hideUndo(), 7000)
  }

  hideUndo() {
    if (this.hasUndoBannerTarget) this.undoBannerTarget.hidden = true
    this.removedMark = null
  }

  setChapterBookmarkState(active, id = null) {
    const button = this.element.querySelector(".reader-chapter-bookmark")
    if (!button) return
    button.classList.toggle("is-active", active)
    button.setAttribute("aria-pressed", active ? "true" : "false")
    button.dataset.chapterMarkId = id || ""
  }

  editMark(event) {
    const mark = this.markCache.find((item) => Number(item.id) === Number(event.currentTarget.dataset.markId))
    if (!mark) return
    this.selection = {
      anchorScope: mark.anchor_scope,
      startVerse: mark.start_verse,
      startOffset: mark.start_offset,
      endVerse: mark.end_verse,
      endOffset: mark.end_offset,
      text: mark.selected_text || this.element.dataset.readerChapterTitle,
      profileHighlightId: mark.id
    }
    this.openAnnotation(event, "edit")
  }

  filterMarks(event) {
    const filter = event.currentTarget.dataset.markFilter
    this.element.querySelectorAll("[data-mark-filter]").forEach((button) => button.setAttribute("aria-pressed", button === event.currentTarget ? "true" : "false"))
    this.marksListTarget.querySelectorAll("[data-mark-type]").forEach((card) => { card.hidden = filter !== "all" && card.dataset.markType !== filter })
  }

  bookmarkChapter(event) {
    event?.preventDefault()
    const button = event?.currentTarget
    const existing = this.markCache.find((mark) => mark.anchor_scope === "chapter")
    this.selection = { anchorScope: "chapter", startVerse: null, startOffset: null, endVerse: null, endOffset: null, text: null, profileHighlightId: existing?.id }
    this.createMark({ visual_style: "none", bookmark: true }, existing?.id).then((mark) => {
      if (!mark || !button) return
      button.classList.add("is-active")
      button.setAttribute("aria-pressed", "true")
      button.dataset.chapterMarkId = mark.id
    })
  }

  openTools(event) {
    event?.preventDefault()
    if (!this.selection || !this.hasToolsDialogTarget) return
    this.toolsReturnFocus = event.currentTarget
    if (this.hasToolResultTarget) this.toolResultTarget.hidden = true
    this.openReaderDialog(this.toolsDialogTarget, this.toolsDialogTarget.querySelector("button"))
  }

  async closeTools(event) {
    event?.preventDefault()
    if (this.hasToolsDialogTarget) await this.closeReaderDialog(this.toolsDialogTarget)
    this.toolsReturnFocus?.focus({ preventScroll: true })
  }

  async openOrganizer(event) {
    const returnFocus = this.toolsReturnFocus
    await this.closeTools(event)
    this.openAnnotation({ preventDefault() {}, currentTarget: returnFocus }, "organize")
  }

  async openLinkEditor(event) {
    const returnFocus = this.toolsReturnFocus
    await this.closeTools(event)
    this.openAnnotation({ preventDefault() {}, currentTarget: returnFocus }, "organize")
    this.noteLinkTarget?.focus({ preventScroll: true })
  }

  searchSelection() {
    const needle = this.selection?.text?.trim().toLocaleLowerCase(this.element.dataset.scriptureRoomLocale)
    if (!needle) return
    const count = Array.from(this.element.querySelectorAll("[data-scripture-verse-text]")).reduce((total, verse) => {
      const haystack = verse.textContent.toLocaleLowerCase(this.element.dataset.scriptureRoomLocale)
      let cursor = 0
      let matches = 0
      while ((cursor = haystack.indexOf(needle, cursor)) >= 0) { matches += 1; cursor += Math.max(needle.length, 1) }
      return total + matches
    }, 0)
    this.showToolResult((this.element.dataset.searchResultsTemplate || "__COUNT__").replace("__COUNT__", count))
  }

  defineSelection() {
    this.showToolResult(this.element.dataset.definitionUnavailable)
  }

  async copySelection() {
    const passage = this.selection
    if (!passage?.text) return
    const verse = passage.startVerse === passage.endVerse ? passage.startVerse : `${passage.startVerse}–${passage.endVerse}`
    const copy = `“${passage.text}” — ${this.element.dataset.readerChapterTitle}:${verse}\n${this.element.dataset.scriptureShareUrl || ""}`.trim()
    try {
      await navigator.clipboard.writeText(copy)
      this.showToolResult(this.element.dataset.selectionCopied)
    } catch (_error) {
      this.showToolResult(this.element.dataset.actionError)
    }
  }

  showToolResult(message) {
    if (!this.hasToolResultTarget) return
    this.toolResultTarget.textContent = message
    this.toolResultTarget.hidden = false
    this.restartFeedbackMotion(this.toolResultTarget)
  }

  readMarkCache() {
    try {
      return JSON.parse(this.element.querySelector("[data-scripture-mark-cache]")?.textContent || "[]")
    } catch (_error) {
      return []
    }
  }

  markForSelection() {
    if (!this.selection) return null
    if (this.selection.profileHighlightId) return this.markCache.find((mark) => Number(mark.id) === Number(this.selection.profileHighlightId))
    return this.markCache.find((mark) => mark.anchor_scope === (this.selection.anchorScope || "passage") &&
      Number(mark.start_verse) === Number(this.selection.startVerse) && Number(mark.end_verse) === Number(this.selection.endVerse) &&
      Number(mark.start_offset) === Number(this.selection.startOffset) && Number(mark.end_offset) === Number(this.selection.endOffset))
  }

  rememberMark(mark) {
    this.markCache = this.markCache.filter((item) => Number(item.id) !== Number(mark.id))
    this.markCache.push(mark)
  }

  populateEditor(mark, mode) {
    if (this.hasNoteSelectionTarget) this.noteSelectionTarget.textContent = `“${this.selection.text || this.element.dataset.readerChapterTitle}”`
    if (this.hasNoteTitleTarget) this.noteTitleTarget.textContent = mark ? this.element.dataset.markEditTitle : this.element.dataset.markCreateTitle
    if (this.hasNoteSaveTarget) this.noteSaveTarget.textContent = mark ? this.element.dataset.markUpdateLabel : this.element.dataset.markSaveLabel
    const style = mark?.visual_style || (mode === "note" ? "none" : "highlight")
    const color = mark?.color_key || "gold"
    this.noteDialogTarget.querySelectorAll('input[name="reader-note-style"]').forEach((input) => { input.checked = input.value === style })
    this.noteDialogTarget.querySelectorAll('input[name="reader-note-color"]').forEach((input) => { input.checked = input.value === color })
    if (this.hasNoteBodyTarget) this.noteBodyTarget.value = mark?.note_body || ""
    if (this.hasNoteIntentTarget) this.noteIntentTarget.value = mark?.intent_key || ""
    if (this.hasNoteTagsTarget) this.noteTagsTarget.value = (mark?.tags || []).join(", ")
    if (this.hasNoteNotebookTarget) this.noteNotebookTarget.value = mark?.notebooks?.[0]?.title || ""
    if (this.hasNoteLinkTarget) this.noteLinkTarget.value = mark?.links?.[0]?.reference || ""
    if (this.hasNoteBookmarkTarget) this.noteBookmarkTarget.checked = Boolean(mark?.bookmarked_at)
  }

  showSelectionStatus(message, error = false) {
    if (!this.hasSelectionStatusTarget || !message) return
    this.selectionStatusTarget.textContent = message
    this.selectionStatusTarget.hidden = false
    this.selectionStatusTarget.classList.toggle("is-error", error)
    this.restartFeedbackMotion(this.selectionStatusTarget)
    if (this.statusTimer) window.clearTimeout(this.statusTimer)
    this.statusTimer = window.setTimeout(() => { this.selectionStatusTarget.hidden = true }, 3500)
  }

  togglePostEditor(event) {
    const editorId = event.currentTarget.dataset.postEditor
    const editor = document.getElementById(editorId)
    if (!editor) return
    const open = editor.hidden

    if (editor.dataset.circleInlineEditor !== undefined) {
      this.element.querySelectorAll("[data-circle-inline-editor]").forEach((candidate) => {
        if (candidate === editor) return
        candidate.hidden = true
        candidate.classList.remove("is-circle-editor-open")
        this.setPostEditorExpanded(candidate.id, false)
      })
    }

    editor.hidden = !open
    editor.classList.toggle("is-circle-editor-open", false)
    this.setPostEditorExpanded(editorId, open)
    if (!open) return

    window.requestAnimationFrame(() => {
      editor.classList.add("is-circle-editor-open")
      const field = editor.querySelector("textarea")
      if (field) {
        this.resizeMessageField(field)
        this.syncMessageForm(field.closest("form"))
      }
      editor.querySelector("textarea, select")?.focus({ preventScroll: true })
    })
  }

  setPostEditorExpanded(editorId, expanded) {
    this.element.querySelectorAll("[data-post-editor]").forEach((button) => {
      if (button.dataset.postEditor === editorId) button.setAttribute("aria-expanded", expanded ? "true" : "false")
    })
  }

  composerToggled(event) {
    const shell = event.currentTarget
    if (!shell?.open) {
      this.syncComposerShell(shell?.querySelector("[data-circle-composer]"))
      return
    }

    window.requestAnimationFrame(() => {
      const field = shell.querySelector("textarea")
      if (!field) return
      this.resizeMessageField(field)
      this.syncMessageForm(field.closest("form"))
      field.focus({ preventScroll: true })
    })
  }

  collapseComposer(event) {
    event.preventDefault()
    const shell = event.currentTarget.closest("[data-circle-composer-shell]")
    if (shell?.open) shell.open = false
  }

  composerFieldFocused(event) {
    const field = event.currentTarget
    if (field.value.length > MESSAGE_LIMIT) return
    const form = field.closest("[data-circle-composer]")
    this.clearMessageError(form)
  }

  messageMetadataChanged(event) {
    const form = event.currentTarget.closest("[data-circle-composer]")
    this.persistCircleDraft(form)
    this.syncComposerShell(form)
  }

  messageInput(event) {
    const field = event.currentTarget
    const form = field.closest("[data-circle-composer]")
    this.countMessage(event)
    this.resizeMessageField(field)
    this.persistCircleDraft(form)
    this.syncComposerShell(form)
  }

  countMessage(event) {
    const field = event.currentTarget
    const form = field.closest("form")
    const count = field.value.length
    const counter = form?.querySelector("[data-message-counter]")
    if (counter) counter.textContent = `${count} / ${MESSAGE_LIMIT}`
    field.setAttribute("aria-invalid", count > MESSAGE_LIMIT ? "true" : "false")
    form?.classList.toggle("is-over-limit", count > MESSAGE_LIMIT)
    const error = form?.querySelector("[data-message-error]")
    if (error) {
      error.textContent = count > MESSAGE_LIMIT ? this.element.dataset.messageLimitError : ""
      error.hidden = count <= MESSAGE_LIMIT
    }
    this.syncMessageForm(form)
  }

  onComposerSubmit(event) {
    const form = event.target.closest("[data-circle-composer]")
    if (!form) return
    const field = form.querySelector("textarea")
    if (!field) return
    const blank = field.value.trim().length === 0
    const overLimit = field.value.length > MESSAGE_LIMIT
    if (blank || overLimit) {
      event.preventDefault()
      field.setAttribute("aria-invalid", "true")
      this.showMessageError(form, overLimit ? this.element.dataset.messageLimitError : this.element.dataset.messageBlankError)
      field.focus()
    }
  }

  composerSubmitStart(event) {
    const form = event.currentTarget
    const field = form.querySelector("textarea")
    if (!field || field.value.trim().length === 0 || field.value.length > MESSAGE_LIMIT) return

    this.persistCircleDraft(form)
    this.rememberCircleSubmission(form)
    form.dataset.circleSubmitting = "true"
    form.setAttribute("aria-busy", "true")
    field.readOnly = true
    form.querySelectorAll("input[type=radio], button").forEach((control) => { control.disabled = true })
    const submit = form.querySelector("[data-circle-submit]")
    const label = submit?.querySelector("[data-circle-submit-label]")
    if (label && submit?.dataset.circleSendingLabel) {
      submit.dataset.circleSubmitLabel = label.textContent
      label.textContent = submit.dataset.circleSendingLabel
    }
  }

  composerSubmitEnd(event) {
    if (event.detail?.success) return
    const form = event.currentTarget
    this.setComposerSubmitting(form, false)
    this.showMessageError(form, this.element.dataset.circleSendFailed)
  }

  setComposerSubmitting(form, submitting) {
    if (!form) return
    const field = form.querySelector("textarea")
    form.toggleAttribute("aria-busy", submitting)
    if (submitting) form.dataset.circleSubmitting = "true"
    else delete form.dataset.circleSubmitting
    if (field) field.readOnly = submitting
    form.querySelectorAll("input[type=radio], button").forEach((control) => {
      if (control.matches("[data-circle-submit]")) return
      control.disabled = submitting
    })
    const submit = form.querySelector("[data-circle-submit]")
    if (!submit) return
    const label = submit.querySelector("[data-circle-submit-label]")
    if (!submitting && label && submit.dataset.circleSubmitLabel) {
      label.textContent = submit.dataset.circleSubmitLabel
      delete submit.dataset.circleSubmitLabel
    }
    if (!submitting) this.syncMessageForm(form)
  }

  syncMessageForm(form) {
    if (!form || form.dataset.circleSubmitting === "true") return
    const field = form.querySelector("textarea")
    const submit = form.querySelector("[data-circle-submit]")
    if (!field || !submit) return
    const canSubmit = field.value.trim().length > 0 && field.value.length <= MESSAGE_LIMIT
    submit.disabled = !canSubmit
  }

  showMessageError(form, message) {
    const error = form?.querySelector("[data-message-error]")
    if (!error || !message) return
    error.textContent = message
    error.hidden = false
    this.restartFeedbackMotion(error)
  }

  clearMessageError(form) {
    const error = form?.querySelector("[data-message-error]")
    if (!error) return
    error.textContent = ""
    error.hidden = true
  }

  showMessageStatus(form, message) {
    const status = form?.querySelector("[data-message-status]")
    if (!status || !message) return
    status.textContent = message
    status.hidden = false
    this.restartFeedbackMotion(status)
  }

  initializeCircleComposers() {
    this.element.querySelectorAll("[data-circle-composer]").forEach((form) => {
      this.restoreCircleDraft(form)
      const field = form.querySelector("textarea")
      if (field) {
        this.countMessage({ currentTarget: field })
        if (form.closest("details")?.open !== false) this.resizeMessageField(field)
      }
      this.syncComposerShell(form)
    })
    this.restorePendingCircleSubmission()
    this.focusCircleEventPost()
    this.clearCircleEventLocation()
  }

  circleDraftKey(form) {
    if (!form) return null
    const scope = this.element.dataset.circlePersonId
    const reference = this.element.dataset.scriptureRoomReference
    if (!scope || !reference) return null
    const kind = form.dataset.circleComposerKind || "post"
    const parentId = form.querySelector('input[name="post[parent_id]"]')?.value || ""
    return [ CIRCLE_DRAFT_PREFIX, scope, reference, kind, parentId ].join(":")
  }

  circlePendingKey() {
    const scope = this.element.dataset.circlePersonId
    const reference = this.element.dataset.scriptureRoomReference
    if (!scope || !reference) return null
    return [ CIRCLE_PENDING_PREFIX, scope, reference ].join(":")
  }

  restoreCircleDraft(form) {
    const key = this.circleDraftKey(form)
    if (!key) return false
    try {
      const draft = JSON.parse(window.sessionStorage.getItem(key) || "null")
      if (!draft || typeof draft.body !== "string") return false
      const field = form.querySelector("textarea")
      if (!field) return false
      field.value = draft.body
      if (draft.kind) {
        Array.from(form.querySelectorAll('input[name="post[kind]"]')).forEach((input) => {
          input.checked = input.value === draft.kind
        })
      }
      const anonymous = form.querySelector('input[type="checkbox"][name="post[anonymous]"]')
      if (anonymous && typeof draft.anonymous === "boolean") anonymous.checked = draft.anonymous
      if (this.hasCircleComposerTarget && form === this.circleComposerTarget) {
        this.setCircleSelection(draft.selection, { persist: false })
      }
      return true
    } catch (_error) {
      return false
    }
  }

  persistCircleDraft(form) {
    const key = this.circleDraftKey(form)
    const field = form?.querySelector("textarea")
    if (!key || !field) return
    try {
      const selection = this.currentCircleSelection(form)
      if (field.value.length === 0 && !selection) {
        window.sessionStorage.removeItem(key)
        return
      }
      const kind = form.querySelector('input[name="post[kind]"]:checked')?.value || form.dataset.circleComposerKind
      const anonymous = form.querySelector('input[type="checkbox"][name="post[anonymous]"]')
      window.sessionStorage.setItem(key, JSON.stringify({
        body: field.value,
        kind,
        selection,
        anonymous: anonymous ? anonymous.checked : undefined,
        savedAt: Date.now()
      }))
    } catch (_error) {
      // Browser privacy settings can disable storage; publishing still works normally.
    }
  }

  clearCircleDraftByKey(key) {
    if (!key) return
    try {
      window.sessionStorage.removeItem(key)
    } catch (_error) {
      // Nothing else is required when storage is unavailable.
    }
  }

  rememberCircleSubmission(form) {
    const pendingKey = this.circlePendingKey()
    const draftKey = this.circleDraftKey(form)
    if (!pendingKey || !draftKey) return
    try {
      window.sessionStorage.setItem(pendingKey, JSON.stringify({ draftKey, submittedAt: Date.now() }))
    } catch (_error) {
      // The server redirect remains the source of truth without session storage.
    }
  }

  restorePendingCircleSubmission() {
    const pendingKey = this.circlePendingKey()
    if (!pendingKey) return
    try {
      const pending = JSON.parse(window.sessionStorage.getItem(pendingKey) || "null")
      if (!pending?.draftKey) return
      const form = Array.from(this.element.querySelectorAll("[data-circle-composer]")).find((candidate) => this.circleDraftKey(candidate) === pending.draftKey)
      if (this.element.dataset.circleEventPostId) {
        this.clearCircleDraftByKey(pending.draftKey)
        this.resetConfirmedComposer(form)
      } else {
        this.showMessageStatus(form, this.element.dataset.circleDraftRestored)
      }
      window.sessionStorage.removeItem(pendingKey)
    } catch (_error) {
      // A malformed or unavailable session value must never block the reader.
    }
  }

  resetConfirmedComposer(form) {
    const field = form?.querySelector("textarea")
    if (!field) return
    field.value = form.dataset.circleComposerKind === "edit" ? (field.dataset.circleInitialValue || "") : ""
    const anonymous = form.querySelector('input[type="checkbox"][name="post[anonymous]"]')
    if (anonymous) anonymous.checked = anonymous.defaultChecked
    if (this.hasCircleComposerTarget && form === this.circleComposerTarget) this.setCircleSelection(null, { persist: false })
    this.countMessage({ currentTarget: field })
    this.resizeMessageField(field)
    this.syncComposerShell(form)
  }

  syncComposerShell(form) {
    const shell = form?.closest("[data-circle-composer-shell]")
    const field = form?.querySelector("textarea")
    if (!shell || !field) return
    const hasDraft = field.value.trim().length > 0
    shell.dataset.hasDraft = hasDraft ? "true" : "false"
    const indicator = shell.querySelector("[data-circle-draft-indicator]")
    if (indicator) indicator.hidden = !hasDraft
  }

  resizeMessageField(field) {
    if (!field) return
    field.style.height = "auto"
    const height = Math.min(Math.max(field.scrollHeight, 0), CIRCLE_COMPOSER_MAX_HEIGHT)
    if (height > 0) field.style.height = `${height}px`
    field.style.overflowY = field.scrollHeight > CIRCLE_COMPOSER_MAX_HEIGHT ? "auto" : "hidden"
  }

  focusCircleEventPost() {
    const postId = this.element.dataset.circleEventPostId
    if (!postId) return
    const post = this.element.querySelector(`[data-circle-post-id="${postId}"]`)
    if (!post) return
    this.circleEventTimer = window.setTimeout(() => {
      post.scrollIntoView({ block: "nearest", behavior: this.reducedMotion() ? "auto" : "smooth" })
      post.focus({ preventScroll: true })
    }, this.reducedMotion() ? 0 : 80)
  }

  clearCircleEventLocation() {
    if (!this.element.dataset.circleEventPostId || !window.history?.replaceState) return
    const location = new URL(window.location.href)
    location.searchParams.delete("circle_event")
    location.searchParams.delete("circle_post")
    window.history.replaceState(window.history.state, "", `${location.pathname}${location.search}${location.hash}`)
  }

  async refreshModerationResults() {
    if (document.visibilityState === "hidden" || this.element.dataset.activePanel !== "circle") return
    await Promise.all(Array.from(this.element.querySelectorAll("[data-moderation-results-url]")).map(async (card) => {
      try {
        const result = await http.json(card.dataset.moderationResultsUrl)
        this.updateModerationCard(card, result)
      } catch (_error) {
        // The next interval retries; ward access remains enforced by the server.
      }
    }))
  }

  updateModerationCard(card, result) {
    if (result.status && result.status !== "open") {
      window.location.reload()
      return
    }
    const write = (selector, value) => { const node = card.querySelector(selector); if (node) node.textContent = value }
    write("[data-vote-yes-count]", result.yes_count)
    write("[data-vote-no-count]", result.no_count)
    write("[data-vote-yes-percent]", `${result.yes_percentage}%`)
    write("[data-vote-no-percent]", `${result.no_percentage}%`)
    const yesBar = card.querySelector("[data-vote-yes-bar]")
    const noBar = card.querySelector("[data-vote-no-bar]")
    if (yesBar) yesBar.style.width = `${result.yes_percentage}%`
    if (noBar) noBar.style.width = `${result.no_percentage}%`
    const total = card.querySelector("[data-vote-total]")
    if (total) total.textContent = (card.dataset.votesTemplate || "__COUNT__").replace("__COUNT__", result.total_count)
  }

  resumeReading(event) {
    document.getElementById(`reader-verse-${event.currentTarget.dataset.resumeVerse}`)?.scrollIntoView({ block: "center", behavior: this.reducedMotion() ? "auto" : "smooth" })
  }

  animatePanelChange(panel) {
    if (!this.panelMotionEnabled()) return
    const target = this.panelTargets.find((candidate) => candidate.dataset.readerPanel === panel)
    if (!target) return

    target.classList.remove("is-reader-panel-entering")
    void target.offsetWidth
    target.classList.add("is-reader-panel-entering")
    this.panelTransitionTarget = target
    this.panelTransitionTimer = window.setTimeout(() => {
      target.classList.remove("is-reader-panel-entering")
      if (this.panelTransitionTarget === target) this.panelTransitionTarget = null
      this.panelTransitionTimer = null
    }, PANEL_TRANSITION_MS)
  }

  clearPanelTransition() {
    if (this.panelTransitionTimer) window.clearTimeout(this.panelTransitionTimer)
    this.panelTransitionTimer = null
    this.panelTransitionTarget?.classList.remove("is-reader-panel-entering")
    this.panelTransitionTarget = null
  }

  panelMotionEnabled() {
    return !this.reducedMotion() && window.matchMedia("(min-width: 768px)").matches
  }

  openReaderDialog(dialog, focusTarget) {
    if (!dialog || dialog.open) return
    dialog.showModal()
    window.requestAnimationFrame(() => focusTarget?.focus({ preventScroll: true }))
  }

  async closeReaderDialog(dialog) {
    if (!dialog?.open) return
    if (this.reducedMotion()) {
      dialog.close()
      return
    }

    dialog.classList.add("is-reader-dialog-closing")
    await new Promise((resolve) => window.setTimeout(resolve, 150))
    if (dialog.open) dialog.close()
    dialog.classList.remove("is-reader-dialog-closing")
  }

  restartFeedbackMotion(target) {
    if (this.reducedMotion() || !target) return
    target.classList.remove("is-reader-feedback-entering")
    void target.offsetWidth
    target.classList.add("is-reader-feedback-entering")
    window.setTimeout(() => target.classList.remove("is-reader-feedback-entering"), 200)
  }

  reducedMotion() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }

  onScroll() {
    this.beginReadingScroll()
    this.scheduleReadingProgress()
    if (this.progressTimer) window.clearTimeout(this.progressTimer)
    this.progressTimer = window.setTimeout(() => this.persistProgress(), 1200)
  }

  beginReadingScroll() {
    this.element.dataset.readerScrollState = "scrolling"
    this.clearReadingAnchor()
    if (this.readingSettleTimer) window.clearTimeout(this.readingSettleTimer)
    this.readingSettleTimer = window.setTimeout(() => this.settleReadingScroll(), READING_SETTLE_MS)
  }

  scheduleReadingProgress() {
    if (this.progressFrame) return
    this.progressFrame = window.requestAnimationFrame(() => {
      this.progressFrame = null
      this.updateReadingProgress()
    })
  }

  settleReadingScroll() {
    this.readingSettleTimer = null
    if (this.progressFrame) {
      window.cancelAnimationFrame(this.progressFrame)
      this.progressFrame = null
    }
    this.updateReadingProgress()
    this.element.dataset.readerScrollState = "settled"
    if (!this.currentVerse) return

    this.readingAnchorVerse = this.currentVerse
    this.readingAnchorVerse.classList.add("is-reading-anchor")
  }

  clearReadingAnchor() {
    this.readingAnchorVerse?.classList.remove("is-reading-anchor")
    this.readingAnchorVerse = null
  }

  updateReadingProgress() {
    const verses = Array.from(this.element.querySelectorAll("[data-scripture-verse-number]"))
    if (!verses.length) return
    const sheetBounds = this.sheet?.getBoundingClientRect()
    const eyeline = sheetBounds
      ? sheetBounds.top + (sheetBounds.height * READING_EYELINE_RATIO)
      : window.innerHeight * READING_EYELINE_RATIO
    const positionedVerses = verses.map((verse) => ({ verse, bounds: verse.getBoundingClientRect() }))
    const scrollable = Math.max((this.sheet?.scrollHeight || 0) - (this.sheet?.clientHeight || 0), 1)
    this.progressRatio = Math.min(1, Math.max(0, (this.sheet?.scrollTop || 0) / scrollable))
    const verseAtEyeline = positionedVerses.find(({ bounds }) => bounds.top <= eyeline && bounds.bottom >= eyeline)?.verse
    const lastPassedVerse = positionedVerses.filter(({ bounds }) => bounds.top <= eyeline).at(-1)?.verse
    this.currentVerse = this.progressRatio >= 0.985 ? verses.at(-1) : (verseAtEyeline || lastPassedVerse || verses[0])
    this.currentVerseIndex = verses.indexOf(this.currentVerse) + 1
    const progressLabel = (this.element.dataset.progressTemplate || "__CURRENT__ / __TOTAL__")
      .replace("__CURRENT__", this.currentVerseIndex)
      .replace("__TOTAL__", verses.length)
    this.element.querySelectorAll("[data-reading-progress-label]").forEach((label) => {
      label.textContent = progressLabel
      label.closest("[aria-label]")?.setAttribute("aria-label", progressLabel)
    })
    this.element.querySelectorAll("[data-reading-progress-bar]").forEach((bar) => {
      if (bar.parentElement?.offsetHeight > bar.parentElement?.offsetWidth) bar.style.height = `${this.progressRatio * 100}%`
      else bar.style.width = `${this.progressRatio * 100}%`
    })
  }

  async persistProgress() {
    const url = this.element.dataset.scriptureRoomProgressUrl
    if (!url || !this.currentVerse) return
    try {
      await http.json(url, {
        method: "PUT",
        keepalive: true,
        body: JSON.stringify({
          progress: {
            reference: this.element.dataset.scriptureRoomReference,
            locale: this.element.dataset.scriptureRoomLocale,
            last_verse: this.currentVerse.dataset.scriptureVerseNumber,
            progress_ratio: this.progressRatio,
            completed: this.progressRatio >= 0.98
          }
        })
      })
    } catch (_error) {
      // Reading never stops because progress persistence is unavailable.
    }
  }
}
