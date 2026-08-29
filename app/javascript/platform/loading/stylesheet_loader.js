const pending = new Map()

export function loadStylesheet(href, key) {
  if (!href || !key) return Promise.reject(new TypeError("stylesheet href and key are required"))

  const url = new URL(href, document.baseURI)
  if (url.origin !== window.location.origin) return Promise.reject(new TypeError("stylesheet must be same-origin"))

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
