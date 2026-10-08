---
name: mcp-servers
description: Build and test MCP servers that let AI agents act on business systems safely - write-gating, strict schemas, agent-facing errors, tenant auth, stateless transport. Use when creating or changing an MCP server or tool, or debugging a tool that voice or chat agents call.
metadata:
  managed-by: aiagents
---

# Skill: mcp-servers

## Purpose

Expose business operations to AI agents through tools that are hard to misuse.

## When to use

- Creating an MCP server or adding or changing a tool
- Designing schemas, errors, auth or tenancy
- Debugging a tool that a voice or chat agent calls wrongly
- Writing tests or smoke checks

## Hard rules

- Register write tools only behind an explicit flag; default is read-only.
- No catch-all or raw pass-through tool. One tool per business operation.
- Strict input schemas that reject unknown keys; loose ones let models invent fields.
- Narrow tools: scalar update, nested patch and full replace are separate, mutually exclusive.
- Guard destructive paths: block edits to live or active objects unless explicitly allowed; reject partial collections that would wipe data.
- Descriptions carry usage guidance ("if ambiguous, resolve with a read tool, never guess"). Server instructions carry the workflow: catalog first, confirm before writes.
- Errors carry a code, a hint and the next safe tool. Redact secrets.
- For voice consumers return failures as plain text `TOOL_ERROR: <label> failed: <reason>`, not a protocol error flag.
- One API key per tenant, sent on initialize. Allow disabling any environment fallback key. Or authenticate as the real user so row-level security applies.
- Key format `prefix_<rowId>_<secret>`; store only a sha256 hash plus scopes. Reject a wrong prefix before any query.
- Write tools accept an optional `idempotencyKey` and forward it as `Idempotency-Key` (design: integrations skill).
- Stateless HTTP: fresh server per request, JSON responses. Route GET and DELETE on the MCP path to the transport (fixed 405s hang clients). Expose `/health`.
- No side effects on import: split the server factory from the entrypoint.

## Workflow

1. Define each operation once as endpoint plus tool, one schema feeding validation and OpenAPI.
2. Decide read or write. Write: flag, guards, idempotency key.
3. Write descriptions and errors from the caller's view.
4. Test and smoke-test, then ship per the automation domain skill.

## Verification

- Unit tests inject and mock the HTTP client: method and path mapping, error mapping, every guard.
- Run a handshake (initialize, list tools, one read) against the deployed URL.
- Confirm the effect in the backing system after a write, not the tool response.
- Confirm write tools are absent with the flag off and a bad key is rejected.
- Trigger a failure via the real consumer and read what the agent receives.

## Failure modes

- Invented keys -> loose schema -> make strict.
- Data wiped -> partial list treated as full replace -> reject partials, add a patch tool.
- Voice agent ignores failure -> flagged error swallowed -> plain-text `TOOL_ERROR`.
- Client hangs on connect -> fixed 405 on GET or DELETE -> route to transport.
- Tests hang -> work at import time -> move to entrypoint.
- Duplicate bookings -> agent retried a write -> forward the idempotency key.

## References

None. This skill is self-contained.
