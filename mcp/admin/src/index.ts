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
    description: "Edit the schedule, presenter language, broadcast delay, or missionary list of a Noche Live. It can only edit a session belonging to the supplied ward.",
    inputSchema: {
      ward_code: z.string(),
      session_code: z.string(),
      starts_at: z.string().optional().describe("ISO 8601 timestamp with timezone"),
      presenter_locale: z.enum(["es", "pt-BR", "fr", "en"]).optional(),
      broadcast_delay_ms: z.number().int().min(0).max(30000).optional(),
      missionary_names: z.array(z.string().min(1).max(32)).optional().describe("Complete replacement list; pass [] to remove all missionaries")
    }
  }, async ({ ward_code, session_code, ...input }) => result(await api(
    `/internal/admin/wards/${encodeURIComponent(ward_code)}/nights/${encodeURIComponent(session_code)}`,
    { method: "PATCH", body: JSON.stringify(input) }
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

  return server
}

void serveStdio(createServer)
