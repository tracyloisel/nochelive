import { Controller } from "@hotwired/stimulus"

const QUALIFIED_READ_MS = 10_000
const QUALIFIED_SCROLL_RATIO = 0.5
const DEEP_LINK_HIGHLIGHT = "scripture-deep-link"
const PROFILE_HIGHLIGHT = "scripture-profile-highlights"
const HIGHLIGHT_SAVE_DELAY_MS = 450

export default class extends Controller {
  static targets = [
    "frame", "loading", "verse", "shareTrigger", "shareDialog",
    "selection", "whatsapp", "x", "copyStatus", "deleteHighlight"
  ]

  connect() {
    this.onFrameLoad = this.onFrameLoad.bind(this)
    this.onKey = this.onKey.bind(this)
    this.onMissing = this.onMissing.bind(this)
    this.onSelectionChange = this.onSelectionChange.bind(this)
    this.onSelectionScroll = this.onSelectionScroll.bind(this)
    this.onHighlightClick = this.onHighlightClick.bind(this)
    if (this.hasFrameTarget) {
      this.frameTarget.addEventListener("turbo:frame-load", this.onFrameLoad)
      this.frameTarget.addEventListener("turbo:frame-missing", this.onMissing)
    }
    window.addEventListener("keydown", this.onKey)
    document.addEventListener("selectionchange", this.onSelectionChange)
    if (this.open()) this.afterOpen()
  }

  disconnect() {
    this.frameTarget?.removeEventListener("turbo:frame-load", this.onFrameLoad)
    this.frameTarget?.removeEventListener("turbo:frame-missing", this.onMissing)
    window.removeEventListener("keydown", this.onKey)
    document.removeEventListener("selectionchange", this.onSelectionChange)
    this.stopSelectionTracking()
    this.stopReadTracking()
    this.unlock()
  }

  prepare(event) {
    this.dismissed = false
    this.pendingReadingLink = event?.currentTarget?.closest("[data-scripture-reading-link]")
    this.lock()
    if (this.hasLoadingTarget) this.loadingTarget.hidden = false
  }

  close(event) {
    event?.preventDefault()
    this.dismissed = true
    this.stopSelectionTracking()
    this.stopReadTracking()
    this.hideLoading()
    this.unlock()
    if (this.hasFrameTarget && this.frameTarget.querySelector(".scripture-veil")) {
      this.frameTarget.replaceChildren()
      window.NocheLiveAudio?.playFrom?.(document)
      return
    }
    if (window.history.length > 1) history.back()
    else window.location.href = "/"
  }

  onFrameLoad() {
    this.hideLoading()
    if (this.dismissed) {
      this.frameTarget?.replaceChildren()
      this.unlock()
      window.NocheLiveAudio?.playFrom?.(document)
      return
    }
    if (this.open()) {
      this.afterOpen()
      this.markPendingReadingOpened()
    }
    else this.unlock()
  }

  onMissing(event) {
    event.preventDefault()
    this.stopReadTracking()
    this.hideLoading()
    this.unlock()
  }

  onKey(event) {
    if (event.key !== "Escape") return
    if (this.hasShareDialogTarget && this.shareDialogTarget.open) {
      event.preventDefault()
      this.closeShare()
      return
    }
    if (!this.open() && this.loadingHidden()) return
    event.preventDefault()
    this.close(event)
  }

  afterOpen() {
    this.lock()
    document.querySelector("[data-scripture-close]")?.focus({ preventScroll: true })
    const focus = document.querySelector("[data-scripture-focus]")
    if (focus) {
      focus.scrollIntoView({ block: "center", behavior: this.reduced() ? "auto" : "smooth" })
    }
    this.startSelectionTracking()
    this.startReadTracking()
  }

  startSelectionTracking() {
    this.stopSelectionTracking()
    this.selectionSheet = this.readerVeil()?.querySelector(".scripture-sheet")
    this.selectionSheet?.addEventListener("scroll", this.onSelectionScroll, { passive: true })
    this.selectionSheet?.addEventListener("click", this.onHighlightClick)
    this.restoreProfileHighlights()
    this.restoreDeepLinkSelection()
  }

  stopSelectionTracking() {
    if (this.highlightSaveTimer) window.clearTimeout(this.highlightSaveTimer)
    if (this.pendingProfilePassage) this.saveProfileHighlight(this.pendingProfilePassage, { updateUi: false })
    this.selectionSheet?.removeEventListener("scroll", this.onSelectionScroll)
    this.selectionSheet?.removeEventListener("click", this.onHighlightClick)
    this.selectionSheet = null
    if (this.selectionFrame) cancelAnimationFrame(this.selectionFrame)
    this.selectionFrame = null
    this.highlightSaveTimer = null
    this.pendingProfilePassage = null
    this.profileHighlights = []
    this.profileHighlightRanges = []
    this.selectedPassage = null
    this.deepLinkRange = null
    this.hideShareTrigger()
    if (this.hasShareDialogTarget && this.shareDialogTarget.open) this.shareDialogTarget.close()
    if (window.CSS?.highlights) {
      CSS.highlights.delete(DEEP_LINK_HIGHLIGHT)
      CSS.highlights.delete(PROFILE_HIGHLIGHT)
    }
  }

  onSelectionChange() {
    if (this.hasShareDialogTarget && this.shareDialogTarget.open) return
    if (this.selectionFrame) cancelAnimationFrame(this.selectionFrame)
    this.selectionFrame = requestAnimationFrame(() => this.captureSelection())
  }

  onSelectionScroll() {
    if (this.selectedPassage?.range) this.positionShareTrigger(this.selectedPassage.range)
  }

  onHighlightClick(event) {
    const selection = window.getSelection()
    if (!selection?.isCollapsed || this.shareDialogTarget?.open) return

    const highlight = this.profileHighlights?.find((item) =>
      this.highlightRangesFromCoordinates(item).some((range) =>
        Array.from(range.getClientRects()).some((rect) =>
          event.clientX >= rect.left && event.clientX <= rect.right &&
            event.clientY >= rect.top && event.clientY <= rect.bottom
        )
      )
    )
    if (!highlight) return

    const range = this.rangeFromCoordinates(highlight)
    if (!range || range.collapsed) return
    selection.removeAllRanges()
    selection.addRange(range)
    this.captureSelection()
  }

  captureSelection() {
    this.selectionFrame = null
    const selection = window.getSelection()
    if (!selection || selection.isCollapsed || selection.rangeCount === 0) {
      this.hideShareTrigger()
      return
    }

    const range = selection.getRangeAt(0)
    const passage = this.passageFromRange(range)
    if (!passage) {
      this.hideShareTrigger()
      return
    }

    const restoredDeepLink = this.deepLinkRange && this.sameRange(range, this.deepLinkRange)
    if (this.deepLinkRange && !restoredDeepLink) {
      this.clearDeepLinkHighlight()
    }
    this.verseTargets.forEach((verse) => verse.classList.remove("is-focus"))
    const existing = this.profileHighlights?.find((highlight) => this.sameHighlight(highlight, {
      start_verse: passage.startVerse,
      end_verse: passage.endVerse,
      start_offset: passage.startOffset,
      end_offset: passage.endOffset
    }))
    passage.profileHighlightId = existing?.id
    this.selectedPassage = passage
    this.updateShareTargets(passage)
    this.positionShareTrigger(range)
    if (!restoredDeepLink && !existing) this.scheduleProfileHighlight(passage)
  }

  passageFromRange(range) {
    const body = this.readerVeil()?.querySelector(".scripture-body")
    if (!body || !body.contains(range.startContainer) || !body.contains(range.endContainer)) return null

    const firstVerse = this.closestVerse(range.startContainer)
    const lastVerse = this.closestVerse(range.endContainer)
    const first = this.verseTargets.indexOf(firstVerse)
    const last = this.verseTargets.indexOf(lastVerse)
    if (first < 0 || last < first) return null

    const firstText = firstVerse.querySelector("[data-scripture-verse-text]")
    const lastText = lastVerse.querySelector("[data-scripture-verse-text]")
    if (!firstText || !lastText) return null

    const start = firstText.contains(range.startContainer)
      ? this.offsetWithin(firstText, range.startContainer, range.startOffset)
      : 0
    const end = lastText.contains(range.endContainer)
      ? this.offsetWithin(lastText, range.endContainer, range.endOffset)
      : lastText.textContent.length
    if (range.collapsed || (first === last && end <= start)) return null

    const from = firstVerse.dataset.scriptureVerseNumber
    const to = lastVerse.dataset.scriptureVerseNumber
    const title = this.readerVeil()?.querySelector("#scripture-title")?.textContent?.trim()
    const reference = title && from && to
      ? `${title}:${from === to ? from : `${from}–${to}`}`
      : null
    const shareBase = this.readerVeil()?.dataset.scriptureShareUrl?.replace(/\/$/, "")
    if (!reference || !shareBase) return null

    const segment = from === to ? from : `${from}-${to}`
    const url = new URL(`${shareBase}/${segment}`, window.location.origin)
    url.searchParams.set("start", start)
    url.searchParams.set("end", end)

    const coordinates = {
      start_verse: Number.parseInt(from, 10),
      end_verse: Number.parseInt(to, 10),
      start_offset: start,
      end_offset: end
    }
    const highlightRanges = this.highlightRangesFromCoordinates(coordinates)
    const text = highlightRanges.map((highlightRange) => highlightRange.toString()).join(" ").replace(/\s+/g, " ").trim()
    if (!text) return null
    return {
      reference,
      text,
      url: url.href,
      range: range.cloneRange(),
      highlightRanges,
      study: this.readerVeil()?.dataset.scriptureReference,
      locale: this.readerVeil()?.dataset.scriptureLocale,
      highlightUrl: this.readerVeil()?.dataset.scriptureHighlightUrl,
      startVerse: coordinates.start_verse,
      endVerse: coordinates.end_verse,
      startOffset: start,
      endOffset: end
    }
  }

  closestVerse(node) {
    const element = node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement
    return element?.closest("[data-scripture-target~='verse']")
  }

  offsetWithin(element, node, offset) {
    const range = document.createRange()
    range.selectNodeContents(element)
    range.setEnd(node, offset)
    return range.toString().length
  }

  updateShareTargets(passage) {
    const veil = this.readerVeil()
    const title = veil?.dataset.scriptureShareTitleTemplate?.replace("__REFERENCE__", passage.reference) || passage.reference
    const message = veil?.dataset.scriptureShareMessageTemplate?.replace("__REFERENCE__", passage.reference) || passage.reference
    if (this.hasSelectionTarget) this.selectionTarget.textContent = title

    const whatsapp = new URL("https://wa.me/")
    whatsapp.searchParams.set("text", `${message}\n${passage.url}`)
    if (this.hasWhatsappTarget) this.whatsappTarget.href = whatsapp.href

    const x = new URL("https://twitter.com/intent/tweet")
    x.searchParams.set("text", message)
    x.searchParams.set("url", passage.url)
    if (this.hasXTarget) this.xTarget.href = x.href
    if (this.hasCopyStatusTarget) this.copyStatusTarget.hidden = true
    if (this.hasDeleteHighlightTarget) this.deleteHighlightTarget.hidden = !passage.profileHighlightId
  }

  positionShareTrigger(range) {
    if (!this.hasShareTriggerTarget) return
    const rects = Array.from(range.getClientRects()).filter((rect) => rect.width || rect.height)
    const visible = rects.filter((rect) => rect.bottom > 0 && rect.top < window.innerHeight)
    const rect = visible.at(-1) || rects.at(-1)
    if (!rect) {
      this.hideShareTrigger()
      return
    }

    const size = 48
    const pad = 12
    const gap = 10
    const sheetRect = this.selectionSheet?.getBoundingClientRect()
    const minimumLeft = Math.max(pad, (sheetRect?.left || 0) + pad)
    const maximumRight = Math.min(window.innerWidth - pad, (sheetRect?.right || window.innerWidth) - pad)
    const right = rect.right + gap
    const left = rect.left - size - gap
    const centeredTop = rect.top + ((rect.height - size) / 2)
    const clampLeft = (value) => Math.min(maximumRight - size, Math.max(minimumLeft, value))
    const clampTop = (value) => Math.min(window.innerHeight - size - pad, Math.max(pad, value))
    const textRects = this.verseTargets.flatMap((verse) =>
      Array.from(verse.querySelector("[data-scripture-verse-text]")?.getClientRects() || [])
    ).filter((textRect) => textRect.width && textRect.height && textRect.bottom > 0 && textRect.top < window.innerHeight)
    const overlapsText = ({ left: candidateLeft, top: candidateTop }) => {
      const candidateRight = candidateLeft + size
      const candidateBottom = candidateTop + size
      return textRects.some((textRect) =>
        candidateRight > textRect.left - 3 && candidateLeft < textRect.right + 3 &&
          candidateBottom > textRect.top - 3 && candidateTop < textRect.bottom + 3
      )
    }
    const candidates = [
      { left: right, top: centeredTop },
      { left, top: centeredTop },
      { left: maximumRight - size, top: centeredTop },
      { left: maximumRight - size, top: rect.bottom + gap },
      { left: maximumRight - size, top: rect.top - size - gap },
      { left: rect.right - size, top: rect.bottom + gap },
      { left: rect.right - size, top: rect.top - size - gap }
    ].map((candidate) => ({ left: clampLeft(candidate.left), top: clampTop(candidate.top) }))
    const position = candidates.find((candidate) => !overlapsText(candidate)) || candidates[2]

    this.shareTriggerTarget.style.left = `${position.left}px`
    this.shareTriggerTarget.style.top = `${position.top}px`
    this.shareTriggerTarget.hidden = false
  }

  hideShareTrigger() {
    if (this.hasShareTriggerTarget) this.shareTriggerTarget.hidden = true
  }

  preserveSelection(event) {
    event.preventDefault()
  }

  openShare(event) {
    event.preventDefault()
    if (!this.selectedPassage || !this.hasShareDialogTarget) return
    this.updateShareTargets(this.selectedPassage)
    this.hideShareTrigger()
    this.shareDialogTarget.showModal()
    this.shareDialogTarget.focus({ preventScroll: true })
  }

  closeShare(event) {
    event?.preventDefault()
    if (this.hasShareDialogTarget && this.shareDialogTarget.open) this.shareDialogTarget.close()
  }

  closeShareOnBackdrop(event) {
    if (event.target === this.shareDialogTarget) this.closeShare(event)
  }

  shareClosed() {
    if (this.hasCopyStatusTarget) this.copyStatusTarget.hidden = true
    const selection = window.getSelection()
    if (selection && !selection.isCollapsed && selection.rangeCount > 0) this.captureSelection()
  }

  async copyLink(event) {
    event.preventDefault()
    if (!this.selectedPassage?.url) return

    try {
      await navigator.clipboard.writeText(this.selectedPassage.url)
    } catch (_error) {
      this.copyWithFallback(this.selectedPassage.url)
    }
    if (this.hasCopyStatusTarget) this.copyStatusTarget.hidden = false
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

  restoreProfileHighlights() {
    this.profileHighlights = []
    this.profileHighlightRanges = []
    const source = this.readerVeil()?.querySelector("[data-scripture-profile-highlights]")
    if (!source) return

    try {
      this.profileHighlights = JSON.parse(source.textContent || "[]")
      this.profileHighlightRanges = this.profileHighlights
        .flatMap((highlight) => this.highlightRangesFromCoordinates(highlight))
        .filter((range) => range && !range.collapsed)
      this.renderProfileHighlights()
    } catch (_error) {
      this.profileHighlights = []
      this.profileHighlightRanges = []
    }
  }

  scheduleProfileHighlight(passage) {
    if (!passage.highlightUrl || !passage.study) return
    if (this.highlightSaveTimer) window.clearTimeout(this.highlightSaveTimer)

    this.pendingProfilePassage = passage
    this.readerVeil().dataset.scriptureHighlightState = "pending"
    this.renderProfileHighlights()
    this.highlightSaveTimer = window.setTimeout(() => {
      this.highlightSaveTimer = null
      this.saveProfileHighlight(passage)
    }, HIGHLIGHT_SAVE_DELAY_MS)
  }

  async saveProfileHighlight(passage, { updateUi = true } = {}) {
    if (!passage?.highlightUrl || !passage.study) return
    const csrf = document.querySelector("meta[name='csrf-token']")?.content

    try {
      const response = await fetch(passage.highlightUrl, {
        method: "POST",
        credentials: "same-origin",
        keepalive: true,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          ...(csrf ? { "X-CSRF-Token": csrf } : {})
        },
        body: JSON.stringify({
          highlight: {
            reference: passage.study,
            locale: passage.locale,
            start_verse: passage.startVerse,
            end_verse: passage.endVerse,
            start_offset: passage.startOffset,
            end_offset: passage.endOffset,
            selected_text: passage.text.slice(0, 10_000)
          }
        })
      })
      if (!response.ok) throw new Error(`Scripture highlight failed: ${response.status}`)

      const highlight = await response.json()
      passage.profileHighlightId = highlight.id
      if (!this.profileHighlights?.some((item) => this.sameHighlight(item, highlight))) {
        this.profileHighlights?.push(highlight)
        this.profileHighlightRanges?.push(...passage.highlightRanges.map((range) => range.cloneRange()))
      }
      if (this.pendingProfilePassage === passage) this.pendingProfilePassage = null
      if (updateUi && this.open()) {
        this.readerVeil().dataset.scriptureHighlightState = "saved"
        this.renderProfileHighlights()
        if (this.selectedPassage === passage) this.updateShareTargets(passage)
      }
    } catch (_error) {
      if (this.pendingProfilePassage === passage) this.pendingProfilePassage = null
      if (updateUi && this.open()) {
        this.readerVeil().dataset.scriptureHighlightState = "error"
        this.renderProfileHighlights()
      }
    }
  }

  renderProfileHighlights() {
    if (!window.CSS?.highlights || !window.Highlight) return
    const ranges = [...(this.profileHighlightRanges || [])]
    const pending = this.pendingProfilePassage?.highlightRanges || []
    ranges.push(...pending)
    if (ranges.length > 0) CSS.highlights.set(PROFILE_HIGHLIGHT, new Highlight(...ranges))
    else CSS.highlights.delete(PROFILE_HIGHLIGHT)
  }

  rangeFromCoordinates(highlight) {
    const first = this.verseTargets.find((verse) =>
      Number.parseInt(verse.dataset.scriptureVerseNumber, 10) === Number(highlight.start_verse)
    )
    const last = this.verseTargets.find((verse) =>
      Number.parseInt(verse.dataset.scriptureVerseNumber, 10) === Number(highlight.end_verse)
    )
    const firstText = first?.querySelector("[data-scripture-verse-text]")
    const lastText = last?.querySelector("[data-scripture-verse-text]")
    if (!firstText || !lastText) return null

    const from = this.textBoundary(firstText, Number(highlight.start_offset))
    const to = this.textBoundary(lastText, Number(highlight.end_offset))
    const range = document.createRange()
    range.setStart(from.node, from.offset)
    range.setEnd(to.node, to.offset)
    return range
  }

  highlightRangesFromCoordinates(highlight) {
    const firstIndex = this.verseTargets.findIndex((verse) =>
      Number.parseInt(verse.dataset.scriptureVerseNumber, 10) === Number(highlight.start_verse)
    )
    const lastIndex = this.verseTargets.findIndex((verse) =>
      Number.parseInt(verse.dataset.scriptureVerseNumber, 10) === Number(highlight.end_verse)
    )
    if (firstIndex < 0 || lastIndex < firstIndex) return []

    return this.verseTargets.slice(firstIndex, lastIndex + 1).map((verse, index, verses) => {
      const text = verse.querySelector("[data-scripture-verse-text]")
      if (!text) return null
      const start = index === 0 ? Number(highlight.start_offset) : 0
      const end = index === verses.length - 1 ? Number(highlight.end_offset) : text.textContent.length
      const from = this.textBoundary(text, start)
      const to = this.textBoundary(text, end)
      const range = document.createRange()
      range.setStart(from.node, from.offset)
      range.setEnd(to.node, to.offset)
      return range.collapsed ? null : range
    }).filter(Boolean)
  }

  sameHighlight(one, two) {
    return Number(one.start_verse) === Number(two.start_verse) &&
      Number(one.end_verse) === Number(two.end_verse) &&
      Number(one.start_offset) === Number(two.start_offset) &&
      Number(one.end_offset) === Number(two.end_offset)
  }

  async removeHighlight(event) {
    event.preventDefault()
    const passage = this.selectedPassage
    if (!passage?.profileHighlightId || !passage.highlightUrl) return
    const csrf = document.querySelector("meta[name='csrf-token']")?.content

    try {
      const response = await fetch(`${passage.highlightUrl}/${encodeURIComponent(passage.profileHighlightId)}`, {
        method: "DELETE",
        credentials: "same-origin",
        headers: {
          "Accept": "application/json",
          ...(csrf ? { "X-CSRF-Token": csrf } : {})
        }
      })
      if (!response.ok) throw new Error(`Scripture highlight deletion failed: ${response.status}`)

      this.profileHighlights = this.profileHighlights.filter((highlight) =>
        Number(highlight.id) !== Number(passage.profileHighlightId)
      )
      this.profileHighlightRanges = this.profileHighlights.flatMap((highlight) =>
        this.highlightRangesFromCoordinates(highlight)
      )
      passage.profileHighlightId = null
      this.renderProfileHighlights()
      window.getSelection()?.removeAllRanges()
      this.hideShareTrigger()
      this.closeShare()
    } catch (_error) {
      if (this.hasDeleteHighlightTarget) this.deleteHighlightTarget.hidden = false
    }
  }

  restoreDeepLinkSelection() {
    const url = new URL(window.location.href)
    const start = Number.parseInt(url.searchParams.get("start"), 10)
    const end = Number.parseInt(url.searchParams.get("end"), 10)
    if (!Number.isFinite(start) || !Number.isFinite(end)) return

    const focused = this.verseTargets.filter((verse) => verse.classList.contains("is-focus"))
    const range = this.rangeFromCoordinates({
      start_verse: focused[0]?.dataset.scriptureVerseNumber,
      end_verse: focused.at(-1)?.dataset.scriptureVerseNumber,
      start_offset: start,
      end_offset: end
    })
    if (!range || range.collapsed) return

    focused.forEach((verse) => verse.classList.remove("is-focus"))
    this.deepLinkRange = range.cloneRange()
    if (window.CSS?.highlights && window.Highlight) {
      CSS.highlights.set(DEEP_LINK_HIGHLIGHT, new Highlight(range))
    }
    const selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(range)
    focused[0].scrollIntoView({ block: "center", behavior: this.reduced() ? "auto" : "smooth" })
  }

  textBoundary(element, requestedOffset) {
    const offset = Math.min(Math.max(requestedOffset, 0), element.textContent.length)
    const walker = document.createTreeWalker(element, NodeFilter.SHOW_TEXT)
    let remaining = offset
    let node = walker.nextNode()
    let last = node
    while (node) {
      if (remaining <= node.data.length) return { node, offset: remaining }
      remaining -= node.data.length
      last = node
      node = walker.nextNode()
    }
    return { node: last || element, offset: last?.data.length || 0 }
  }

  sameRange(one, two) {
    return one.startContainer === two.startContainer && one.startOffset === two.startOffset &&
      one.endContainer === two.endContainer && one.endOffset === two.endOffset
  }

  clearDeepLinkHighlight() {
    if (window.CSS?.highlights) CSS.highlights.delete(DEEP_LINK_HIGHLIGHT)
    this.deepLinkRange = null
  }

  readerVeil() {
    return document.querySelector(".scripture-veil:not(.is-loading)")
  }

  startReadTracking() {
    this.stopReadTracking()
    this.readVeil = document.querySelector(".scripture-veil[data-scripture-reference][data-scripture-read-url]")
    this.readSheet = this.readVeil?.querySelector(".scripture-sheet")
    if (!this.readVeil || !this.readSheet) return

    this.readElapsed = 0
    this.readLastTick = performance.now()
    this.readProgressReached = false
    this.readSending = false
    this.readSent = false
    this.onReadScroll = () => this.updateReadProgress()
    this.readSheet.addEventListener("scroll", this.onReadScroll, { passive: true })
    this.updateReadProgress()
    this.readTimer = window.setInterval(() => this.trackReadTime(), 250)
  }

  stopReadTracking() {
    if (this.readTimer) window.clearInterval(this.readTimer)
    if (this.readSheet && this.onReadScroll) {
      this.readSheet.removeEventListener("scroll", this.onReadScroll)
    }
    this.readTimer = null
    this.readSheet = null
    this.readVeil = null
    this.onReadScroll = null
  }

  trackReadTime() {
    const now = performance.now()
    if (document.visibilityState === "visible" && this.open()) {
      this.readElapsed += now - this.readLastTick
    }
    this.readLastTick = now
    this.qualifyReadIfReady()
  }

  updateReadProgress() {
    if (!this.readSheet) return

    const scrollable = this.readSheet.scrollHeight - this.readSheet.clientHeight
    const ratio = scrollable <= 1 ? 1 : this.readSheet.scrollTop / scrollable
    this.readProgressReached ||= ratio >= QUALIFIED_SCROLL_RATIO
    this.qualifyReadIfReady()
  }

  qualifyReadIfReady() {
    if (this.readSent || this.readSending) return
    if (!this.readProgressReached || this.readElapsed < QUALIFIED_READ_MS) return

    this.recordRead()
  }

  async recordRead() {
    this.readSending = true
    const csrf = document.querySelector("meta[name='csrf-token']")?.content

    try {
      const response = await fetch(this.readVeil.dataset.scriptureReadUrl, {
        method: "POST",
        credentials: "same-origin",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
          ...(csrf ? { "X-CSRF-Token": csrf } : {})
        },
        body: JSON.stringify({ reference: this.readVeil.dataset.scriptureReference })
      })
      if (!response.ok) throw new Error(`Scripture read failed: ${response.status}`)

      const payload = await response.json()
      const count = this.readVeil.querySelector("[data-scripture-read-count]")
      if (count && payload.reads_count > 0) {
        count.textContent = payload.label
        count.hidden = false
      }
      this.readSent = true
      this.stopReadTracking()
    } catch (_error) {
      this.readSent = true
      this.stopReadTracking()
    } finally {
      this.readSending = false
    }
  }

  markPendingReadingOpened() {
    const link = this.pendingReadingLink
    this.pendingReadingLink = null
    if (!link || link.classList.contains("is-opened")) return

    link.classList.add("is-opened")
    const state = link.querySelector(".study-reading-state")
    if (state) state.textContent = `✓ ${link.dataset.scriptureOpenedLabel}`

    const progress = document.querySelector("[data-scripture-progress]")
    if (!progress) return
    const opened = Number(progress.dataset.openedCount || 0) + 1
    const total = Number(progress.dataset.totalCount || 0)
    progress.dataset.openedCount = opened
    progress.textContent = progress.dataset.labelTemplate
      .replace("__OPENED__", opened)
      .replace("__TOTAL__", total)
  }

  open() {
    return !!document.querySelector(".scripture-veil:not(.is-loading)")
  }

  loadingHidden() {
    return !this.hasLoadingTarget || this.loadingTarget.hidden
  }

  hideLoading() {
    if (this.hasLoadingTarget) this.loadingTarget.hidden = true
  }

  lock() {
    document.documentElement.classList.add("is-scripture-open")
  }

  unlock() {
    document.documentElement.classList.remove("is-scripture-open")
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
