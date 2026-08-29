import test from "node:test"
import assert from "node:assert/strict"
import { isPredictiveRequest } from "../../../app/javascript/runtime/loading/request_visibility.js"

test("predictive Turbo fetches stay out of the player loading state", () => {
  assert.equal(isPredictiveRequest({
    detail: { fetchOptions: { headers: { "X-Sec-Purpose": "prefetch" } } }
  }), true)

  assert.equal(isPredictiveRequest({
    detail: { request: { headers: new Headers({ "Sec-Purpose": "prefetch;prerender" }) } }
  }), true)

  assert.equal(isPredictiveRequest({
    detail: { request: { headers: new Headers({ Purpose: "prefetch" }) } }
  }), true)
})

test("foreground Turbo fetches still drive the player loading state", () => {
  assert.equal(isPredictiveRequest({
    detail: { fetchOptions: { headers: { Accept: "text/html" } } }
  }), false)
  assert.equal(isPredictiveRequest(), false)
})
