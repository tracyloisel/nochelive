const FALLBACK_PATH = "/"

function safeNotificationPath(candidate) {
  if (typeof candidate !== "string" || !candidate.startsWith("/") || candidate.startsWith("//")) return FALLBACK_PATH

  try {
    const url = new URL(candidate, self.location.origin)
    if (url.origin !== self.location.origin || url.username || url.password) return FALLBACK_PATH
    return `${url.pathname}${url.search}${url.hash}`
  } catch (_) {
    return FALLBACK_PATH
  }
}

function notificationPayload(event) {
  let raw = {}
  try { raw = event.data ? event.data.json() : {} } catch (_) {}
  const options = raw.options && typeof raw.options === "object" ? raw.options : raw
  const data = options.data && typeof options.data === "object" ? options.data : {}

  return {
    title: typeof raw.title === "string" && raw.title.trim() ? raw.title : "Noche Live",
    options: {
      body: typeof options.body === "string" ? options.body : "",
      tag: typeof options.tag === "string" ? options.tag : "noche-live",
      icon: typeof options.icon === "string" ? options.icon : "/icon-192.png",
      badge: typeof options.badge === "string" ? options.badge : "/favicon-32.png",
      data: { ...data, path: safeNotificationPath(data.path) }
    }
  }
}

self.addEventListener("install", () => self.skipWaiting())

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim())
})

self.addEventListener("fetch", () => {})

self.addEventListener("push", (event) => {
  const payload = notificationPayload(event)
  event.waitUntil(self.registration.showNotification(payload.title, payload.options))
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const destination = safeNotificationPath(event.notification?.data?.path)

  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({ type: "window", includeUncontrolled: true })
    const exact = windows.find((client) => {
      try {
        const url = new URL(client.url)
        return `${url.pathname}${url.search}${url.hash}` === destination
      } catch (_) {
        return false
      }
    })
    if (exact && "focus" in exact) return exact.focus()

    const reusable = windows.find((client) => "navigate" in client && "focus" in client)
    if (reusable) {
      await reusable.navigate(destination)
      return reusable.focus()
    }

    if (self.clients.openWindow) return self.clients.openWindow(destination)
  })().catch(async () => {
    if (self.clients.openWindow) return self.clients.openWindow(FALLBACK_PATH)
  }))
})

self.addEventListener("pushsubscriptionchange", (event) => {
  event.waitUntil(self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((windows) => {
    windows.forEach((client) => client.postMessage({ type: "noche:push-subscription-change" }))
  }))
})

self.NochePushTest = { safeNotificationPath, notificationPayload }
