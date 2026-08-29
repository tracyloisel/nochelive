export class HttpError extends Error {
  constructor(message, { response = null, cause = null } = {}) {
    super(message, { cause })
    this.name = "HttpError"
    this.response = response
    this.status = response?.status ?? null
  }
}

function csrfFromDocument() {
  return typeof document === "undefined" ? "" : document.querySelector("meta[name='csrf-token']")?.content || ""
}

function mergeHeaders(input, additions) {
  const headers = new Headers(input || {})
  Object.entries(additions).forEach(([name, value]) => {
    if (value && !headers.has(name)) headers.set(name, value)
  })
  return headers
}

export function createHttpClient({
  fetchImpl = globalThis.fetch?.bind(globalThis),
  csrfToken = csrfFromDocument,
  renderTurboStream = (html) => globalThis.Turbo?.renderStreamMessage?.(html),
  timers = globalThis
} = {}) {
  if (typeof fetchImpl !== "function") throw new TypeError("fetch implementation is required")

  async function request(url, options = {}, { accept, json = false, timeoutMs = 0 } = {}) {
    const controller = new AbortController()
    const externalSignal = options.signal
    const abortFromExternal = () => controller.abort(externalSignal.reason)
    if (externalSignal?.aborted) abortFromExternal()
    else externalSignal?.addEventListener?.("abort", abortFromExternal, { once: true })

    const timeout = timeoutMs > 0 ? timers.setTimeout(() => controller.abort(new Error("request timeout")), timeoutMs) : null
    const method = (options.method || "GET").toUpperCase()
    const headers = mergeHeaders(options.headers, {
      Accept: accept,
      "Content-Type": json ? "application/json" : null,
      "X-CSRF-Token": method === "GET" || method === "HEAD" ? null : csrfToken()
    })

    try {
      const response = await fetchImpl(url, {
        credentials: "same-origin",
        ...options,
        headers,
        signal: controller.signal
      })
      if (!response.ok) throw new HttpError(`HTTP ${response.status}`, { response })
      return response
    } catch (error) {
      if (error instanceof HttpError || error?.name === "AbortError") throw error
      throw new HttpError("Network request failed", { cause: error })
    } finally {
      if (timeout != null) timers.clearTimeout(timeout)
      externalSignal?.removeEventListener?.("abort", abortFromExternal)
    }
  }

  return {
    request,
    async json(url, options = {}, requestOptions = {}) {
      const response = await request(url, options, { ...requestOptions, accept: "application/json", json: options.body != null })
      if (response.status === 204) return null
      return response.json()
    },
    async turboStream(url, options = {}, requestOptions = {}) {
      const response = await request(url, options, { ...requestOptions, accept: "text/vnd.turbo-stream.html" })
      const html = await response.text()
      if (html) renderTurboStream(html)
      return html
    },
    telemetry(url, payload, { keepalive = true, signal } = {}) {
      return request(url, {
        method: "POST",
        body: JSON.stringify(payload),
        keepalive,
        signal
      }, { accept: "application/json", json: true })
    }
  }
}

export const http = createHttpClient()
