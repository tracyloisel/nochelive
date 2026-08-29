import { Controller } from "@hotwired/stimulus"
import { EffectScope } from "platform/lifecycle/effect_scope"
import { NetworkPolicy } from "platform/loading/network_policy"
import { ResourceLoader } from "platform/loading/resource_loader"
import { Clock } from "platform/time/clock"
import { LoadingDirector } from "runtime/loading/director"
import { PrefetchPolicy } from "runtime/loading/prefetch_policy"
import { isPredictiveRequest } from "runtime/loading/request_visibility"
import { ResourceManifest } from "runtime/loading/resource_manifest"
import { ResourcePolicy } from "runtime/loading/resource_policy"

export default class extends Controller {
  static targets = ["indicator"]

  connect() {
    this.effectScope = new EffectScope()
    this.manifest = this.readManifest()
    this.resourcePolicy = new ResourcePolicy(this.manifest)
    this.resourceLoader = new ResourceLoader()
    this.prefetchPolicy = new PrefetchPolicy({
      networkPolicy: new NetworkPolicy(),
      maxBytes: this.manifest.prefetch.maxBytes || 180_000
    })
    this.commandInFlight = false
    this.criticalReady = true
    this.director = new LoadingDirector({
      clock: new Clock(),
      render: (state) => this.render(state)
    })

    this.effectScope.listen(document, "turbo:before-fetch-request", (event) => {
      if (!isPredictiveRequest(event)) this.director.start()
    })
    this.effectScope.listen(document, "turbo:render", () => this.director.resolve())
    this.effectScope.listen(document, "turbo:frame-render", () => this.director.resolve())
    this.effectScope.listen(document, "turbo:submit-start", () => { this.commandInFlight = true })
    this.effectScope.listen(document, "turbo:submit-end", (event) => {
      this.commandInFlight = false
      if (event.detail?.success === false) this.director.fail()
      else this.director.resolve()
    })
    this.effectScope.listen(document, "turbo:before-prefetch", (event) => this.beforePrefetch(event))
    this.effectScope.listen(this.element, "noche:prefetch", (event) => this.prefetch(event))
    this.effectScope.listen(document, "visibilitychange", () => {
      if (document.hidden) this.prefetchPolicy.cancelAll("background")
    })
    this.effectScope.listen(document, "turbo:fetch-request-error", (event) => {
      if (!isPredictiveRequest(event)) this.director.fail()
    })
    this.effectScope.listen(document, "turbo:before-cache", () => this.director.resolve())
    this.effectScope.listen(window, "offline", () => this.director.offline())
    this.effectScope.listen(window, "online", () => this.director.online())

    if (navigator.onLine === false) this.director.offline()
  }

  disconnect() {
    this.prefetchPolicy?.cancelAll("disconnect")
    this.director?.dispose()
    this.effectScope?.dispose()
  }

  beforePrefetch(event) {
    const url = event.detail?.url?.toString?.() || event.target?.href
    const declared = this.manifest.prefetch.nextScreen && this.resourcePolicy.allows("screen.next", "predictive")
    const decision = this.prefetchPolicy.decide({
      key: url,
      bytes: this.manifest.prefetch.maxBytes,
      criticalReady: this.criticalReady && declared,
      commandInFlight: this.commandInFlight,
      visible: !document.hidden,
      cached: false,
      inFlight: false
    })
    if (!decision.allowed) event.preventDefault()
  }

  prefetch(event) {
    const { key = "screen.next", url, bytes = this.manifest.prefetch.maxBytes } = event.detail || {}
    const declared = this.manifest.prefetch.nextScreen && this.resourcePolicy.allows(key, "predictive")
    const decision = this.prefetchPolicy.decide({
      key: url,
      bytes,
      criticalReady: this.criticalReady && declared,
      commandInFlight: this.commandInFlight,
      visible: !document.hidden,
      cached: false,
      inFlight: false
    })
    if (!decision.allowed) return

    const controller = this.prefetchPolicy.begin(url)
    this.resourceLoader.fetch(url, url, {
      credentials: "same-origin",
      headers: { Accept: "text/html" },
      signal: controller.signal
    }).catch(() => {}).finally(() => this.prefetchPolicy.finish(url))
  }

  readManifest() {
    try {
      return ResourceManifest.fromElement(document.getElementById("noche_resource_manifest"))
    } catch (error) {
      console.warn("Invalid Noche resource manifest", error)
      return new ResourceManifest({ context: "shell", styles: ["shell"] })
    }
  }

  render(state) {
    document.documentElement.dataset.loadingState = state
    if (!this.hasIndicatorTarget) return

    const visible = ["visible", "slow"].includes(state)
    this.indicatorTarget.hidden = !visible
    this.indicatorTarget.setAttribute("aria-hidden", visible ? "false" : "true")
    this.indicatorTarget.dataset.state = state
  }
}
