import { Controller } from "@hotwired/stimulus"
import { haptic } from "haptics"
import { audioLoader } from "platform/audio/loader"
import { motionDirector } from "runtime/motion/runtime"

const EASE_OUT = [0.22, 1, 0.36, 1]
const ANIM_DELAY = 80
const ANIM_DURATION = 450
const COUNT_MS = 500
const LANG_STAGGER = 50
const ROW_STAGGER = 70

export default class extends Controller {
  static targets = ["chapter"]
  static values = { countdown: Number }

  #observer = null
  #ran = false
  #phaseTimers = []
  #controls = []
  #expanded = false
  #aboutPressed = false

  connect() {
    motionDirector.setReducedMotion(this.reduced())
    if (this.reduced()) {
      this.instantReveal()
      return
    }

    this.#observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting && !this.#ran) {
            this.#observer.disconnect()
            this.#reveal()
          }
        })
      },
      { rootMargin: "0px 0px 18% 0px" }
    )
    this.#observer.observe(this.element)

    document.addEventListener("turbo:visit", () => {
      this.#observer?.disconnect()
    })
  }

  openExpand() {
    haptic("tap")
    if (this.#expanded) return
    this.#expanded = true
    const details = this.element.querySelector(".stats-world-expand details")
    if (details) {
      const fullList = this.element.querySelector(".stats-world-list-full")
      if (fullList) fullList.style.display = "block"
      details.classList.add("is-expanded")
      this.#animateWorld(fullList)
      audioLoader.play("question_change")
    }
  }

  aboutClick() {
    if (!this.#aboutPressed) {
      haptic("tap")
      this.#aboutPressed = true
    }
  }

  disconnect() {
    this.#observer?.disconnect()
    this.#phaseTimers.forEach((t) => window.clearTimeout(t))
    this.#phaseTimers = []
    this.#controls.forEach((controls) => controls.cancel?.())
    this.#controls = []
  }

  #reveal() {
    this.#ran = true
    this.element.classList.add("is-reveal-running")

    // Background + HUD entry
    this.#applyCSS(this.element, {
      transform: "scale(1.025)",
      opacity: "0",
      transition: "none"
    })
    this.element.style.transformOrigin = "center 0%"

    const bgTimer = this.#phase(700, () => {
      this.#applyCSS(this.element, {
        transform: "scale(1)",
        opacity: "1",
        transition: "opacity 700ms ease, transform 700ms ease"
      })
    }, 0)

    // HUD entry
    const hud = this.element.querySelector(".stats-header")
    if (hud) {
      this.#applyCSS(hud, { opacity: "0", transform: "translateY(-12px)" })
      this.#phase(380, () => {
        this.#applyCSS(hud, {
          opacity: "1",
          transform: "translateY(0)",
          transition: "opacity 380ms ease, transform 380ms cubic-bezier(.22,1,.36,1)"
        })
      }, 400)
    }

    // Title + rules
    const ruleL = this.element.querySelector(".stats-header-rule-l")
    const ruleR = this.element.querySelector(".stats-header-rule-r")
    if (ruleL && ruleR) {
      this.#phase(400, () => {
        ruleL.style.transition = "width 400ms cubic-bezier(.22,1,.36,1)"
        ruleR.style.transition = "width 400ms cubic-bezier(.22,1,.36,1)"
        ruleL.style.width = "24px"
        ruleR.style.width = "24px"
      }, 600)
    }

    // Chapters cascade
    const chapters = this.chapterTargets
    chapters.forEach((chapter, i) => {
      chapter.style.opacity = "0"
      chapter.style.transform = "translateY(20px) scale(.985)"
      chapter.style.transition = "none"
      const delay = i * ANIM_DELAY
      this.#phase(ANIM_DURATION, () => {
        chapter.style.transition =
          `opacity ${ANIM_DURATION}ms cubic-bezier(${EASE_OUT.join(",")}), ` +
          `transform ${ANIM_DURATION}ms cubic-bezier(${EASE_OUT.join(",")})`
        chapter.style.opacity = "1"
        chapter.style.transform = "translateY(0) scale(1)"
        chapter.classList.add("is-visible")

        if (i === 0) this.#startChapter(chapter, "house")
        if (i === 1) this.#startChapter(chapter, "path", delay + ANIM_DURATION + 100)
        if (i === 2) this.#startChapter(chapter, "meet", delay + ANIM_DURATION + ANIM_DELAY + ANIM_DURATION)
        if (i === 3) this.#startChapter(chapter, "invitations")
        if (i === 4) this.#startChapter(chapter, "world", delay + ANIM_DURATION + ANIM_DELAY * 2 + ANIM_DURATION)
      }, 800 + delay)
    })
  }

  #startChapter(chapter, type, startDelay = 0) {
    if (type === "house") this.#animateHouse(chapter)
    else if (type === "path") this.#animatePath(chapter, startDelay)
    else if (type === "meet") this.#animateMeet(chapter)
    else if (type === "invitations") this.#animateMeet(chapter)
    else if (type === "world") this.#animateWorld(chapter)
  }

  #animateHouse(chapter) {
    const counters = chapter.querySelectorAll("[data-stat-counter]")
    counters.forEach((counter) => {
      const val = Number(counter.closest("[data-stat-value]")?.dataset.statValue || counter.dataset.statValue || 0)
      this.#animateCounter(counter, val, COUNT_MS)
    })

    // Stats langs stagger
    const langs = chapter.querySelectorAll("[data-stat-lang='item']")
    langs.forEach((lang, i) => {
      const timer = this.#phase(LANG_STAGGER * i, () => {
        lang.style.opacity = "1"
        lang.style.transition = "opacity 200ms ease"
        const dot = lang.querySelector(".stats-lang-dot-fill")
        if (dot) {
          dot.style.transform = "scale(0)"
          dot.style.transition = "none"
          this.#phase(80, () => {
            dot.style.transition = "transform 250ms cubic-bezier(.22,1,.36,1)"
            dot.style.transform = "scale(1.15)"
            this.#phase(120, () => {
              dot.style.transform = "scale(1)"
            }, 200)
          }, 120)
        }
        const countEl = lang.querySelector("[data-stat-current]")
        if (countEl) {
          const parent = lang.querySelector("[data-stat-value]")
          const val = Number(parent?.dataset.statValue || 0)
          if (val > 0) this.#animateCounter(countEl, val, COUNT_MS * 0.7)
        }
      }, 0)
      this.#phaseTimers.push(timer)
    })
  }

  #animatePath(chapter, delay) {
    // Hero counter first
    const heroCounter = chapter.querySelector(".stats-path-hero [data-stat-counter]")
    if (heroCounter) {
      const parent = chapter.querySelector(".stats-path-hero [data-stat-value]")
      const val = Number(parent?.dataset.statValue || 0)
      this.#phase(0, () => this.#animateCounter(heroCounter, val, COUNT_MS), delay)
    }

    // Gold dust travel to correct
    this.#phase(delay + COUNT_MS, () => {
      const spark = document.createElement("span")
      spark.className = "stats-path-spark"
      spark.setAttribute("aria-hidden", "true")
      const heroTile = chapter.querySelector(".stats-path-hero .stats-tile")
      const correctTile = chapter.querySelector(".stats-path-row .stats-tile-inline:first-child")
      if (heroTile && correctTile) {
        const from = heroTile.getBoundingClientRect()
        const to = correctTile.getBoundingClientRect()
        spark.style.left = `${from.left + from.width / 2}px`
        spark.style.top = `${from.top + from.height / 2}px`
        spark.style.setProperty("--spark-x", `${to.left + to.width / 2 - from.left - from.width / 2}px`)
        spark.style.setProperty("--spark-y", `${to.top + to.height / 2 - from.top - from.height / 2}px`)
        heroTile.parentElement.appendChild(spark)
        this.#phase(50, () => {
          spark.style.opacity = "1"
          spark.style.transform = `translateX(${spark.style.getPropertyValue("--spark-x")}) translateY(${spark.style.getPropertyValue("--spark-y")})`
        }, 0)
        this.#phase(800, () => spark.remove(), 0)
      }
    }, 0)

    // Correct/Wrong counters
    const inlineCounters = chapter.querySelectorAll(".stats-path-row [data-stat-counter]")
    inlineCounters.forEach((counter) => {
      const parent = counter.closest("[data-stat-value]")
      const val = Number(parent?.dataset.statValue || 0)
      this.#phase(delay + 200, () => this.#animateCounter(counter, val, COUNT_MS), 0)
    })

    // Circle percentage
    this.#phase(delay + COUNT_MS + 200, () => {
      this.#animateCircle(chapter, delay + COUNT_MS + 200)
    }, 0)
  }

  #animateCircle(chapter, startAt) {
    const svg = chapter.querySelector(".stats-path-svg")
    const ring = chapter.querySelector(".stats-path-ring")
    const pctEl = chapter.querySelector(".stats-path-pct [data-stat-current]")
    if (!svg || !ring || !pctEl) return

    const circumference = 314.159
    const share = this.element.style.getPropertyValue("--stats-path-share").replace("%", "")
    const targetPct = Math.min(100, Math.max(0, Number(share) || 0))
    const targetDash = circumference - (circumference * targetPct / 100)
    const duration = 600

    const controls = motionDirector.count(0, targetPct, {
      duration: duration / 1000,
      onUpdate: (value) => {
        ring.style.strokeDashoffset = circumference - (circumference * (value / 100))
        pctEl.textContent = Math.round(value)
      }
    })
    this.#controls.push(controls)

    // Gold chime on completion
    this.#phase(duration, () => {
      audioLoader.play("correct_gold")
    }, 0)
  }

  #animateMeet(chapter) {
    // Swords rotate slightly
    const swords = chapter.querySelectorAll('[data-stat-value]')
    swords.forEach((tile, i) => {
      const ico = tile.querySelector(".stats-tile-ico")
      if (ico && i === 0) {
        ico.style.transform = "rotate(-5deg)"
        ico.style.transition = "transform 300ms cubic-bezier(.22,1,.36,1)"
        this.#phase(200, () => { ico.style.transform = "rotate(0)" }, 0)
      }
    })

    // Counters
    const counters = chapter.querySelectorAll("[data-stat-counter]")
    counters.forEach((counter) => {
      const parent = counter.closest("[data-stat-value]")
      const val = Number(parent?.dataset.statValue || 0)
      this.#animateCounter(counter, val, COUNT_MS)
    })
  }

  #animateWorld(chapter) {
    const rows = chapter.querySelectorAll("[data-stat-world-row]")
    rows.forEach((row, i) => {
      const isExpanded = !row.closest(".stats-world-list-full")?.parentElement?.classList.contains("is-expanded")
      if (!isExpanded && i >= 5) return

      this.#phase(ROW_STAGGER * i, () => {
        row.style.opacity = "0"
        row.style.transform = "translateY(8px)"
        row.style.transition = "none"
        this.#phase(200, () => {
          row.style.transition = "opacity 350ms cubic-bezier(.22,1,.36,1), transform 350ms cubic-bezier(.22,1,.36,1)"
          row.style.opacity = "1"
          row.style.transform = "translateY(0)"
          row.classList.add("is-visible")

          const badge = row.querySelector(".stats-world-badge")
          if (badge && i < 3) {
            const medal = badge.querySelector(".stats-world-medal")
            if (medal) {
              const scale = 1.12 - i * 0.06
              medal.style.transform = "scale(0)"
              medal.style.transition = "none"
              this.#phase(100, () => {
                medal.style.transition = "transform 400ms cubic-bezier(.22,1,.36,1)"
                medal.style.transform = `scale(${scale})`
                if (i === 0) {
                  this.#phase(400, () => {
                    medal.style.transform = "scale(1)"
                    // Gold sheen
                    const sheen = document.createElement("span")
                    sheen.className = "stats-world-sheen"
                    sheen.setAttribute("aria-hidden", "true")
                    badge.appendChild(sheen)
                    this.#phase(800, () => sheen.remove(), 0)
                  }, 0)
                }
              }, 0)
            }
          }

          // Counter for score
          const scoreCounter = row.querySelector("[data-stat-counter]")
          if (scoreCounter) {
            const info = row.closest("[data-stat-world-row]")
            const scoreEl = row.querySelector(".stats-world-score")
            if (scoreEl) {
              const val = Number(scoreEl.dataset.statValue || 0)
              this.#animateCounter(scoreCounter.querySelector("[data-stat-current]"), val, COUNT_MS * 0.8)
            }
          }

          // First rank chime
          if (i === 0) {
            this.#phase(300, () => audioLoader.play("stake_gain"), 0)
          }
        }, 0)
      }, 0)
    })
  }

  #animateCounter(el, target, duration) {
    const current = el?.matches?.("[data-stat-current]")
      ? el
      : el?.querySelector?.("[data-stat-current]")

    if (!current) return

    if (this.reduced()) {
      current.textContent = this.#formatNumber(target)
      return
    }

    const controls = motionDirector.count(0, target, {
      duration: duration / 1000,
      onUpdate: (value) => { current.textContent = this.#formatNumber(Math.round(value)) }
    })
    this.#controls.push(controls)
  }

  #formatNumber(n) {
    try {
      return new Intl.NumberFormat(I18n.locale).format(n)
    } catch {
      return n.toLocaleString()
    }
  }

  #phase(ms, fn, delay) {
    const timer = window.setTimeout(fn, delay + ms)
    this.#phaseTimers.push(timer)
    return timer
  }

  #applyCSS(el, props) {
    Object.entries(props).forEach(([key, val]) => {
      el.style[key] = val
    })
  }

  instantReveal() {
    this.element.classList.add("is-reveal-instant")
    this.element.querySelectorAll("[data-stat-current]").forEach((el) => {
      const parent = el.closest("[data-stat-value]")
      if (!parent) return
      el.textContent = this.#formatNumber(Number(parent.dataset.statValue || 0))
    })
    const ring = this.element.querySelector(".stats-path-ring")
    if (ring) {
      const share = this.element.style.getPropertyValue("--stats-path-share").replace("%", "")
      const circumference = 314.159
      const targetPct = Math.min(100, Math.max(0, Number(share) || 0))
      ring.style.strokeDasharray = circumference
      ring.style.strokeDashoffset = circumference - (circumference * targetPct / 100)
    }
    this.element.querySelectorAll("[data-stat-world-row]").forEach((row) => {
      row.style.opacity = "1"
      row.style.transform = "translateY(0)"
      row.classList.add("is-visible")
    })
  }

  reduced() {
    return window.matchMedia("(prefers-reduced-motion: reduce)").matches
  }
}
