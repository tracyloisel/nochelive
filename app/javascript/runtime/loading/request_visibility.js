const PURPOSE_HEADERS = ["X-Sec-Purpose", "Sec-Purpose", "Purpose"]

function readHeader(headers, name) {
  if (!headers) return null
  if (typeof headers.get === "function") return headers.get(name)

  const key = Object.keys(headers).find((candidate) => candidate.toLowerCase() === name.toLowerCase())
  return key ? headers[key] : null
}

function requestHeaders(event) {
  return event?.detail?.fetchOptions?.headers || event?.detail?.request?.headers
}

export function isPredictiveRequest(event) {
  const headers = requestHeaders(event)
  const purpose = PURPOSE_HEADERS.map((name) => readHeader(headers, name)).find(Boolean)
  return String(purpose || "").split(/[\s,;]+/).some((token) => token.toLowerCase() === "prefetch")
}
