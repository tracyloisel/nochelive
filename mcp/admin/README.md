# Noche Live Admin MCP

Private local MCP server for administering Noche Live through the authenticated Rails admin API. The server never connects directly to PostgreSQL and never stores the admin secret in this repository.

## Architecture and security

The MCP process runs locally over STDIO. Every tool calls `https://nochelive.com/internal/admin/...` with the private bearer token stored in `NOCHE_ADMIN_API_TOKEN`.

- Keep `NOCHE_ADMIN_API_TOKEN` out of Git, screenshots, logs, prompts, and shell history.
- Use the same secret configured on the Render web service.
- The API refuses tokens shorter than 32 characters.
- Administrative mutations are logged without including the secret or player device identifiers.
- Profile merging requires a preview followed by a short-lived, single-use confirmation.
- A Noche Live can only be edited or finished through the rama that owns it.
- Teams are persistent rama data. A Live session can list and clone them, but cannot create an ad-hoc team.

## Install and verify

From the repository root:

```sh
cd mcp/admin
npm ci
npm run typecheck
```

To test that the process starts, provide the two required environment variables. The server waits silently for MCP messages on STDIN when startup succeeds.

```sh
export NOCHE_ADMIN_API_URL="https://nochelive.com"
export NOCHE_ADMIN_API_TOKEN="replace-with-the-render-secret"
npm start
```

Stop the manual test with `Ctrl-C`.

## Configure Codex

Codex supports local STDIO MCP servers. Its desktop app, CLI, and IDE extension share the MCP configuration on the same host. The default configuration file is `~/.codex/config.toml`; a trusted project can instead use `.codex/config.toml`.

Add the following configuration, adapting `cwd` if the repository moves:

```toml
[mcp_servers.nochelive_admin]
command = "./bin/start"
cwd = "/Users/tracyloisel/00-Codes/nochelive/mcp/admin"
startup_timeout_sec = 20
tool_timeout_sec = 60
enabled = true

[mcp_servers.nochelive_admin.env]
NOCHE_ADMIN_API_URL = "https://nochelive.com"
```

The launcher reads `NOCHE_ADMIN_API_TOKEN` from the macOS Keychain item named `com.nochelive.admin-api-token`, so the secret does not appear in `config.toml`. After saving, restart Codex. In the desktop app, the equivalent flow is **Settings → MCP servers → Add server → STDIO**, then save and restart. Use `/mcp` to confirm that `nochelive_admin` is connected.

Official reference: [OpenAI documentation — Model Context Protocol](https://developers.openai.com/codex/mcp).

## Tool reference and examples

The examples below show both a natural-language request that can be given to Codex and the structured input received by the tool. Codes and IDs are illustrative.

### `search_wards`

Search ramas by name, public code, or city. Returns at most 25 results.

> Cherche la rama de Benidorm.

```json
{ "query": "Benidorm" }
```

### `inspect_ward`

Inspect one rama and list up to 100 profiles with their avatar, points, and creation date.

> Inspecte la rama RAMA et montre-moi ses profils.

```json
{ "ward_code": "RAMA" }
```

### `platform_stats`

Return aggregate platform statistics without personal player data.

> Donne-moi les statistiques globales de Noche Live.

```json
{}
```

### `ward_stats`

Return aggregate activity statistics for one rama.

> Donne-moi les statistiques de la rama RAMA.

```json
{ "ward_code": "RAMA" }
```

### `people_seen_today`

List unique people active on a given day through either the street experience or a live night. With no scope filter, the query covers the whole platform. `country` accepts an ISO country code such as `ES` or a country name. `date` defaults to today in the requested timezone.

> Qui s'est connecté aujourd'hui en Espagne ?

```json
{
  "country": "ES",
  "timezone": "Europe/Madrid"
}
```

For one rama on a historical date:

```json
{
  "ward_code": "RAMA",
  "date": "2026-08-28",
  "timezone": "Europe/Madrid"
}
```

### `create_ward_team`

Create a persistent team for one rama. The emblem must be one of `leon`, `fuego`, `paloma`, `corona`, `ola`, or `estrella`. A duplicate name in the same rama is rejected.

> Crée l'équipe Les Oliviers dans la rama RAMA.

```json
{
  "ward_code": "RAMA",
  "name": "Les Oliviers",
  "emblem": "paloma"
}
```

### `preview_profile_merge`

Preview a merge between two same-name profiles in the same rama. The oldest profile is selected as keeper. No player data changes at this step.

> Prépare la fusion des profils 41 et 96 dans la rama RAMA.

```json
{
  "ward_code": "RAMA",
  "first_id": 41,
  "second_id": 96
}
```

Inspect the returned keeper, source, and effect before using the returned `confirmation` value.

### `confirm_profile_merge`

Execute exactly one previously previewed merge. The confirmation token is short-lived and single-use.

> Confirme la fusion que nous venons de vérifier.

```json
{
  "confirmation": "short-lived-confirmation-returned-by-preview"
}
```

### `create_noche_live`

Create a new Noche Live owned by an explicit rama. `starts_at` must be an ISO 8601 timestamp including its UTC offset. `quiz_ids` is a non-empty ordered list of pack IDs from the existing `/jugar` catalog. The lobby opens automatically 30 minutes before launch; the Noche closes one hour after launch. The response exposes one canonical public URL plus the registration and play destinations.

> Crée une Noche Live pour la rama RAMA le 30 août à 19 h 30 avec les quiz Rois, Moïse et Nazareno dans cet ordre.

```json
{
  "ward_code": "RAMA",
  "starts_at": "2026-08-30T19:30:00+02:00",
  "quiz_ids": ["coronas", "moises", "nazareno"]
}
```

There is no presenter credential, console, broadcast delay, custom poster, or host list in this contract. The first/current quiz supplies the artwork.

### `edit_noche_live`

Edit the schedule or complete ordered quiz list of an existing scheduled Noche Live. `ward_code` is mandatory even when the session code is known; the API rejects cross-rama edits. Omitted fields remain unchanged.

> Décale la Noche Live DAVID de la rama RAMA à 20 h et utilise deux quiz.

```json
{
  "ward_code": "RAMA",
  "session_code": "DAVID",
  "starts_at": "2026-08-30T20:00:00+02:00",
  "quiz_ids": ["coronas", "moises"]
}
```

Finishing is exposed separately so the irreversible lifecycle change stays explicit.

### `finish_noche_live`

Close an existing Noche Live immediately and broadcast its final Watch state. `ward_code` is mandatory even when the session code is known; the API rejects cross-rama requests. Retrying the same request is safe.

> Ferme la Noche Live X8MPU de la rama RAMA.

```json
{
  "ward_code": "RAMA",
  "session_code": "X8MPU"
}
```

The response returns the night with `status: "finished"`, its fixed end time, and the final team-score projection.

## Notification editorial workshop

The notification tools are deliberately separate from delivery. They can create drafts, render exact four-language previews, and approve an immutable proposal. They cannot enable web push or send a notification.

The safe sequence is:

1. `draft_notification_message` or `draft_notification_verse`;
2. `preview_notification_editorial` and review all four locales and destinations;
3. edit the draft if necessary with `edit_notification_editorial_draft`, then preview again;
4. `preview_notification_editorial_approval` to receive a 15-minute, one-use confirmation;
5. `approve_notification_editorial` only after the displayed digest and complete preview are accepted.

Use `list_notification_editorials` at any time to see what is still a draft and what has been approved. Approved entries are immutable; corrections use a new `editorial_key` so the audit trail remains honest.

Message drafts require exact placeholder sets:

| Message kind | Required body placeholders |
|---|---|
| `daily_verse` | `%{reference}` |
| `study_reading` | `%{title}` |
| `duel_invitation`, `duel_reminder` | `%{name}`, `%{pack}` |
| `duel_result_won`, `duel_result_finished`, `duel_result_tie` | `%{name}`, `%{pack}` |
| `night_tomorrow`, `night_starting_soon` | `%{time}` |

Verse drafts require a local publication date, canonical `study` path, verse number, and theme. Preview derives the citation and exact scripture deep link independently for Español, Português, Français, and English. An invalid reference is rejected. No approved entry for a date must ultimately mean no editorial delivery.

Actual test pushes and production activation are intentionally not exposed in this first workshop. They require a separate, explicitly confirmed test-recipient workflow after the copy and calendar have been approved.

## Expected errors

- `401 Unauthorized`: the token is absent, different from Render, or too short.
- `404 Not Found`: the rama/session code does not exist, or the session does not belong to the supplied rama.
- `422 Unprocessable Entity`: invalid timestamp, locale, quiz list, persistent team, merge pair, or expired confirmation.
- MCP startup failure: check `NOCHE_ADMIN_API_URL`, `NOCHE_ADMIN_API_TOKEN`, `cwd`, then run `npm run typecheck` and restart Codex.

## Development checks

Run the focused application tests and MCP type check before deploying changes:

```sh
bin/rails test test/controllers/admin_api_test.rb
npm --prefix mcp/admin run typecheck
```
