# n8n Workflow Patterns
Last verified: 2026-10-08
Prefer live documentation and observed behaviour over this file; report any drift.

For generic node and workflow architecture, the optional third-party `n8n-workflow-patterns` skill applies. This file holds only the conventions that this framework relies on.

## Structure

- One large workflow per product may expose several entry points: inbound webhook, schedule, post-event webhook, and an execute-workflow trigger.
- Shared, parameterised sub-workflows are reused across tenants. Changes to them are additive only.
- A single-tenant client gets a clone of the shared workflow with new webhook paths. After cloning, check: tenant id, credentials (wrong billing account), and null client filters that pull other tenants' data.
- Tenant configuration lives as an object literal in one Code node, optionally exposed through a config webhook.
- Write the router as a pure function in a Code node so it can be diff-tested across all routes offline.

## Naming

- Number node prefixes to encode the flow (`1.`, `3.1`, `3b`); letter suffixes mark branches. Keep the existing convention.
- Workflow names: `WF_<Tenant>_<Purpose>`.
- Webhook paths: kebab-case with a tenant suffix.

## Agent node

- Put the invariant rulebook in the system message and volatile values (dates, contact data, history) in the user text. This enables prompt caching and can cut latency several times over. Moving invariant content into the user text breaks caching.
- Choose one reply style per workflow and state it: a dedicated node sends the reply, or a send tool is mandatory every turn.
- Run any classifier after the reply is sent, with `continueRegularOutput` so its failure does not block the reply.
- `memoryBufferWindow` is RAM-only and is lost on restart or workflow edit. Do not rely on it for durable state.
- The model selector `modelIndex` is 1-based.
- A transient model-provider error (for example a 404) can kill the run. Add retry or a fallback model.
- Prompt design itself belongs to the conversational-agents skill.

## Debounce

Collapse bursts of inbound messages into one agent run:

1. Save `{key, execution_id}`.
2. Wait about 15 seconds.
3. Only the newest execution for that key proceeds; older ones stop.
4. Re-check right before sending.

The key falls back to the phone number when the contact does not exist yet.

## Code nodes

- Use `this.helpers.httpRequest` inside try/catch, with short timeouts.
- In `$fromAI(name, description, type, default)`, giving a default removes the parameter from the required set. Omit the default when the value is mandatory.
- Test offline before publishing: extract the logic, run a case battery (normal, empty, malformed, boundary), compare outputs.
- Retry, timeout and idempotency design is in the integrations skill.

## Executions debugging

- Retention is short (about two days, pruned by count). Capture execution ids and node data early.
- After a restart, interrupted runs show `canceled`, not `error`. Waiting executions are not listed by the API.
- Open per-node run data to find the failed node inside a "success" run.
- A green workflow does not prove the feature works; check the downstream effect.

## Chat webhook contract

- Request: POST `{sessionId, action: 'sendMessage', chatInput}`. Voice input is multipart with an `audioData` part.
- Response: `{output, suggestedQuestions[]}`, parsed tolerantly by the client.
- The call is synchronous with a 30 second client timeout and no automatic retry (it would duplicate replies). Retry is manual.
- The session id lives in memory per page load. Test memory with fresh sessions.
- Widget-side behaviour is covered in the messaging skill.
