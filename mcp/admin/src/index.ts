import { McpServer } from "@modelcontextprotocol/server"
import { serveStdio } from "@modelcontextprotocol/server/stdio"
import * as z from "zod/v4"

const baseUrl = process.env.NOCHE_ADMIN_API_URL?.replace(/\/$/, "")
const token = process.env.NOCHE_ADMIN_API_TOKEN

if (!baseUrl || !token) {
  console.error("NOCHE_ADMIN_API_URL and NOCHE_ADMIN_API_TOKEN are required")
  process.exit(1)
}

async function api(path: string, init: RequestInit = {}) {
  const response = await fetch(`${baseUrl}${path}`, {
    ...init,
    headers: {
      "Authorization": `Bearer ${token}`,
      "Content-Type": "application/json",
      ...init.headers
    }
  })
  const body = await response.json()
  if (!response.ok) throw new Error(body.error || `Admin API returned ${response.status}`)
  return body
}

function result(value: unknown) {
  return { content: [{ type: "text" as const, text: JSON.stringify(value, null, 2) }] }
}

const messageKinds = [
  "daily_verse", "study_reading", "duel_invitation", "duel_reminder",
  "duel_result_won", "duel_result_finished", "duel_result_tie",
  "night_tomorrow", "night_starting_soon"
] as const
const translationSchema = z.object({ title: z.string().min(1).max(80), body: z.string().min(1).max(180) })
const translationsSchema = z.object({
  es: translationSchema,
  "pt-BR": translationSchema,
  fr: translationSchema,
  en: translationSchema
})

function createServer() {
  const server = new McpServer({ name: "nochelive-admin", version: "0.1.0" })

  server.registerTool("search_wards", {
    description: "Search Noche Live wards by name, public code, or city.",
    inputSchema: { query: z.string().default("") }
  }, async ({ query }) => result(await api(`/internal/admin/wards?q=${encodeURIComponent(query)}`)))

  server.registerTool("inspect_ward", {
    description: "Inspect one ward and list its player profiles with avatar, points, and creation date.",
    inputSchema: { ward_code: z.string() }
  }, async ({ ward_code }) => result(await api(`/internal/admin/wards/${encodeURIComponent(ward_code)}`)))

  server.registerTool("platform_stats", {
    description: "Return aggregate Noche Live platform statistics without personal player data.",
    inputSchema: {}
  }, async () => result(await api("/internal/admin/stats")))

  server.registerTool("ward_stats", {
    description: "Return aggregate statistics for one Noche Live ward without personal player data.",
    inputSchema: { ward_code: z.string() }
  }, async ({ ward_code }) => result(await api(`/internal/admin/wards/${encodeURIComponent(ward_code)}/stats`)))

  server.registerTool("people_seen_today", {
    description: "List people active today worldwide, in one country, or in one ward. Combines street and live-night activity.",
    inputSchema: {
      country: z.string().optional().describe("ISO country code such as ES, or the country name"),
      ward_code: z.string().optional(),
      date: z.string().optional().describe("YYYY-MM-DD; defaults to today in the requested timezone"),
      timezone: z.string().default("Europe/Madrid")
    }
  }, async (input) => {
    const query = new URLSearchParams()
    for (const [key, value] of Object.entries(input)) if (value) query.set(key, value)
    return result(await api(`/internal/admin/people_seen_today?${query}`))
  })

  server.registerTool("rotate_presenter_code", {
    description: "Invalidate a ward's old presenter code and return a new code once.",
    inputSchema: { ward_code: z.string() }
  }, async ({ ward_code }) => result(await api(
    `/internal/admin/wards/${encodeURIComponent(ward_code)}/rotate_presenter_token`,
    { method: "POST", body: "{}" }
  )))

  server.registerTool("create_noche_live", {
    description: "Create a new scheduled Noche Live inside one ward. Returns its session code and player, presenter, and public paths.",
    inputSchema: {
      ward_code: z.string().describe("Public code of the ward that will own the Noche Live"),
      starts_at: z.string().describe("ISO 8601 timestamp with timezone, for example 2026-08-29T19:00:00+02:00"),
      presenter_locale: z.enum(["es", "pt-BR", "fr", "en"]).default("es"),
      broadcast_delay_ms: z.number().int().min(0).max(30000).default(0),
      missionary_names: z.array(z.string().min(1).max(32)).default([]),
      theme_id: z.string().default("reyes_y_profetas")
    }
  }, async ({ ward_code, ...input }) => result(await api(
    `/internal/admin/wards/${encodeURIComponent(ward_code)}/nights`,
    { method: "POST", body: JSON.stringify(input) }
  )))

  server.registerTool("edit_noche_live", {
    description: "Edit the schedule, presenter language, broadcast delay, event poster, or missionary list of a Noche Live. It can only edit a session belonging to the supplied ward.",
    inputSchema: {
      ward_code: z.string(),
      session_code: z.string(),
      starts_at: z.string().optional().describe("ISO 8601 timestamp with timezone"),
      presenter_locale: z.enum(["es", "pt-BR", "fr", "en"]).optional(),
      broadcast_delay_ms: z.number().int().min(0).max(30000).optional(),
      poster_path: z.string().regex(/^\/media\/nights\/events\/[a-z0-9][a-z0-9._-]*\.(?:jpe?g|png|webp)$/i).nullable().optional().describe("Deployed event poster path, or null to restore the theme poster"),
      missionary_names: z.array(z.string().min(1).max(32)).optional().describe("Complete replacement list; pass [] to remove all missionaries")
    }
  }, async ({ ward_code, session_code, ...input }) => result(await api(
    `/internal/admin/wards/${encodeURIComponent(ward_code)}/nights/${encodeURIComponent(session_code)}`,
    { method: "PATCH", body: JSON.stringify(input) }
  )))

  server.registerTool("finish_noche_live", {
    description: "Finish a Noche Live, record its final team results in the ward season, and broadcast the final state. The supplied session must belong to the supplied ward. Safe to retry if the first response is lost.",
    inputSchema: {
      ward_code: z.string().describe("Public code of the ward that owns the Noche Live"),
      session_code: z.string().describe("Session code of the Noche Live to finish")
    }
  }, async ({ ward_code, session_code }) => result(await api(
    `/internal/admin/wards/${encodeURIComponent(ward_code)}/nights/${encodeURIComponent(session_code)}/finish`,
    { method: "POST", body: "{}" }
  )))

  server.registerTool("preview_profile_merge", {
    description: "Preview a same-name, same-ward profile merge. Returns a short-lived one-use confirmation token without changing data.",
    inputSchema: { ward_code: z.string(), first_id: z.number().int(), second_id: z.number().int() }
  }, async (input) => result(await api("/internal/admin/profile_merges/preview", {
    method: "POST",
    body: JSON.stringify(input)
  })))

  server.registerTool("confirm_profile_merge", {
    description: "Execute exactly one previously previewed merge using its short-lived confirmation token.",
    inputSchema: { confirmation: z.string().min(20) }
  }, async ({ confirmation }) => result(await api("/internal/admin/profile_merges", {
    method: "POST",
    body: JSON.stringify({ confirmation })
  })))

  server.registerTool("list_notification_editorials", {
    description: "List notification message and verse proposals with their draft or approved status. This never sends or enables notifications.",
    inputSchema: {
      proposal_type: z.enum(["message", "verse"]).optional(),
      status: z.enum(["draft", "approved"]).optional()
    }
  }, async (input) => {
    const query = new URLSearchParams()
    for (const [key, value] of Object.entries(input)) if (value) query.set(key, value)
    return result(await api(`/internal/admin/notification_editorials?${query}`))
  })

  server.registerTool("draft_notification_message", {
    description: "Create a four-language notification message draft. Placeholders must match the selected message kind. This does not approve, send, or enable it.",
    inputSchema: {
      editorial_key: z.string().regex(/^[a-z0-9][a-z0-9._:-]*$/),
      notification_kind: z.enum(messageKinds),
      translations: translationsSchema
    }
  }, async ({ editorial_key, notification_kind, translations }) => result(await api(
    "/internal/admin/notification_editorials",
    {
      method: "POST",
      body: JSON.stringify({
        editorial_key,
        proposal_type: "message",
        payload: { notification_kind, translations }
      })
    }
  )))

  server.registerTool("draft_notification_verse", {
    description: "Create a dated scripture proposal and derive its canonical citation and destination in all four locales. This does not approve, send, or enable it.",
    inputSchema: {
      editorial_key: z.string().regex(/^[a-z0-9][a-z0-9._:-]*$/),
      publish_on: z.string().describe("YYYY-MM-DD local publication date"),
      study: z.string().describe("Canonical scripture study path, for example nt/john/3"),
      verse: z.number().int().positive(),
      theme: z.string().min(1).max(80)
    }
  }, async ({ editorial_key, ...payload }) => result(await api(
    "/internal/admin/notification_editorials",
    { method: "POST", body: JSON.stringify({ editorial_key, proposal_type: "verse", payload }) }
  )))

  server.registerTool("edit_notification_editorial_draft", {
    description: "Replace the payload of an existing draft. Approved proposals are immutable and must be superseded by a new editorial key.",
    inputSchema: {
      id: z.number().int().positive(),
      payload: z.record(z.string(), z.unknown())
    }
  }, async ({ id, payload }) => result(await api(
    `/internal/admin/notification_editorials/${id}`,
    { method: "PATCH", body: JSON.stringify({ payload }) }
  )))

  server.registerTool("preview_notification_editorial", {
    description: "Render the exact four-language notification copy, canonical citations, and sample deep links for review. No push is sent.",
    inputSchema: { id: z.number().int().positive() }
  }, async ({ id }) => result(await api(`/internal/admin/notification_editorials/${id}/preview`)))

  server.registerTool("preview_notification_editorial_approval", {
    description: "Review the exact immutable proposal and obtain a short-lived one-use confirmation token. This still does not send or enable notifications.",
    inputSchema: { id: z.number().int().positive() }
  }, async ({ id }) => result(await api(
    `/internal/admin/notification_editorials/${id}/approval_preview`,
    { method: "POST", body: "{}" }
  )))

  server.registerTool("approve_notification_editorial", {
    description: "Approve exactly one previously previewed editorial proposal using its short-lived confirmation. Approval never enables delivery or sends a push.",
    inputSchema: { id: z.number().int().positive(), confirmation: z.string().min(20) }
  }, async ({ id, confirmation }) => result(await api(
    `/internal/admin/notification_editorials/${id}/approve`,
    { method: "POST", body: JSON.stringify({ confirmation }) }
  )))

  return server
}

void serveStdio(createServer)
