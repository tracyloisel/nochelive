import assert from "node:assert/strict"
import test from "node:test"

import { haptic } from "../../../app/javascript/haptics.js"

function withNavigator(value, callback) {
  const previous = Object.getOwnPropertyDescriptor(globalThis, "navigator")
  Object.defineProperty(globalThis, "navigator", { configurable: true, value })
  try {
    callback()
  } finally {
    if (previous) Object.defineProperty(globalThis, "navigator", previous)
    else delete globalThis.navigator
  }
}

test("does not request vibration before a user activation", () => {
  const calls = []
  withNavigator({
    userActivation: { hasBeenActive: false },
    vibrate: (pattern) => calls.push(pattern)
  }, () => haptic("reward"))

  assert.deepEqual(calls, [])
})

test("plays the named pattern after a user activation", () => {
  const calls = []
  withNavigator({
    userActivation: { hasBeenActive: true },
    vibrate: (pattern) => calls.push(pattern)
  }, () => haptic("success"))

  assert.deepEqual(calls, [[ 16, 40, 28 ]])
})

test("keeps compatibility when userActivation is unavailable", () => {
  const calls = []
  withNavigator({ vibrate: (pattern) => calls.push(pattern) }, () => haptic("tap"))

  assert.deepEqual(calls, [12])
})
