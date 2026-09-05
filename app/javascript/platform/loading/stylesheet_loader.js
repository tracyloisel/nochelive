const pending = new Map()

function isAllowedStylesheetUrl(url) {
  if (url.protocol !== "http:" && url.protocol !== "https:") return false
  if (url.origin === window.location.origin) return true

  try {
    const assetHost = new URL(document.documentElement?.dataset?.assetHost)
    return (assetHost.protocol === "http:" || assetHost.protocol === "https:") && url.origin === assetHost.origin
  } catch {
    return false
  }
}

export function loadStylesheet(href, key) {
  if (!href || !key) return Promise.reject(new TypeError("stylesheet href and key are required"))

  const url = new URL(href, document.baseURI)
  if (!isAllowedStylesheetUrl(url)) return Promise.reject(new TypeError("stylesheet must be same-origin or use the configured asset host"))

  if (pending.has(key)) return pending.get(key)
  const existing = document.head.querySelector(`link[data-runtime-stylesheet="${CSS.escape(key)}"]`)
  if (existing) return Promise.resolve({ link: existing, owned: false })

  const link = document.createElement("link")
  link.rel = "stylesheet"
  link.href = url.href
  link.dataset.runtimeStylesheet = key
  link.dataset.turboTrack = "dynamic"

  const promise = new Promise((resolve, reject) => {
    link.addEventListener("load", () => resolve({ link, owned: true }), { once: true })
    link.addEventListener("error", () => {
      link.remove()
      reject(new Error(`stylesheet failed: ${key}`))
    }, { once: true })
    document.head.append(link)
  }).finally(() => pending.delete(key))

  pending.set(key, promise)
  return promise
}

export function releaseStylesheet(resource) {
  if (resource?.owned) resource.link?.remove()
}
