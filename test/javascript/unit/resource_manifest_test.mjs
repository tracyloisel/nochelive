import test from "node:test"
import assert from "node:assert/strict"
import { ResourceManifest } from "../../../app/javascript/runtime/loading/resource_manifest.js"
import { ResourcePolicy } from "../../../app/javascript/runtime/loading/resource_policy.js"

test("resource manifest validates context, resource classes and budgets", () => {
  const manifest = new ResourceManifest({
    context: "street.quiz.ask",
    styles: ["shell", "street_play", "shell"],
    controllers: ["quiz"],
    prefetch: { nextScreen: true, maxBytes: 180_000 },
    classes: { "style.shell": "critical", "screen.next": "predictive" }
  })
  const policy = new ResourcePolicy(manifest)

  assert.deepEqual(manifest.styles, ["shell", "street_play"])
  assert.equal(policy.allows("style.shell", "initial"), true)
  assert.equal(policy.allows("screen.next", "initial"), false)
  assert.equal(policy.allows("screen.next", "predictive"), true)
  assert.throws(() => new ResourceManifest({ context: "bad context" }), /invalid/)
  assert.throws(() => new ResourceManifest({ context: "hub", prefetch: { maxBytes: 180_001 } }), /budget/)
})
