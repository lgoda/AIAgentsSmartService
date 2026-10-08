# GoHighLevel Reference
Last verified: 2026-10-08
Prefer live documentation and observed behaviour over this file; report any drift.

Vendor-specific facts for the `crm` skill. Placeholders: `<tenant>`, `<location-id>`, `<contact-id>`.

## Base and authentication

- API host: `services.leadconnectorhq.com`. A `Version` header is required and its value differs by API family: the conversations family uses a different value than most others. Check the live docs per family; a wrong version gives confusing 4xx responses.
- Use one Private Integration Token per tenant, scoped to that tenant's location, plus its `locationId`. Keep both in the tenant's secret store (secrets handling: integrations skill).
- Token scopes are granular. A 401 or 403 on one endpoint family while others work usually means a missing scope on the token, not a bad token.
- Listing locations does not work with a sub-account token. Take the location id from tenant config instead of discovering it.
- Credential modes: managed (the agency holds the token) versus self-service (the customer creates it). Record which mode a tenant uses, since rotation and scope changes differ.

## Contacts

- Inbound flow: upsert with phone only. Do not require email or name.
- A cold contact (first message, not yet created) has no contact id. Per-contact endpoints then return 400. Guard such steps with continue-on-error and fall back to the phone as key.
- The contact search index lags behind writes. Use GET by contact id as the authority, for example when reading DND.
- Duplicates return 409. Treat as "already exists" and look the contact up.

## Calendars and appointments

- Do not send `endTime` on create. Duration comes from the calendar's configured slot duration; the slot interval is only the spacing between offered slots.
- `meetingLocationType` is an enum; send only documented values.
- Always pass the timezone explicitly. Tool defaults have been wrong.
- Split updates: one call for time (start), another for details (title, notes, status). The detail update takes a JSON body in which empty fields are omitted, because a key-value or form body with empty values blanks existing data. PUT behaves as a partial update on these endpoints; confirm in live docs before relying on that for other objects.
- External "free" calendar events (synced from Google or Outlook) do not block slots. If the customer's real calendar matters, mark those events busy there or block time in the CRM calendar, otherwise double booking happens. Fix this in the CRM configuration, not in the prompt.
- To detect that an agent created an appointment, list the contact's appointments before and after the turn and diff.

## Date formats

- The per-contact appointments endpoint returns local time without an offset (for example `2026-10-08 15:00:00`).
- The calendar events endpoint returns ISO strings with an offset.
- Normalize both to one representation (UTC, or tenant-local with offset) at the boundary. Timezone storage rules: integrations skill.

## Do-not-disturb

- DND can be set per channel (for example WhatsApp, SMS, email, calls) or globally on the contact. Read the contact by id for the current per-channel state.
- Agents may set DND, never remove it.
- The CRM clears DND automatically when the customer sends a message. If your database says the contact opted out, set DND again after processing the inbound message.
- Opt-out order: final message, state update in your database, DND.
- A send that fails because DND is active is "NOT SENT, do not retry". Do not queue it for backoff.

## Workflows, opportunities and loops

- A CRM workflow triggered by a field change fires when automation writes that field, and can loop. Never write fields (tags, custom fields, stages) that a workflow watches.
- Adding a broadcast-workflow tag to a contact once silently stopped inbound forwarding for that contact, and a recovery job was needed. Test tag side effects on a test contact first.
- Workflow `customData` reaches the webhook as a flat object. Send a single token (such as the contact id) and let the automation derive everything else by reading the CRM. Avoid packing many fields into customData.
- Opportunities: choose the target pipeline with a classifier over the conversation or source, then create the opportunity in that pipeline's first stage.

## Errors and limits

- 401 unauthorized, 409 duplicate, 429 rate limited (back off), 5xx transient. Generic mapping and retry policy: integrations skill.
- Batch backfills with a cursor and small pages, and persist the cursor between runs.

## Using the MCP server

Many setups expose the API through generic MCP tools with a three-step pattern:

1. Search operations by keyword (for example "appointment", "contact", "dnd").
2. Describe the chosen operation to get exact parameters, method and body shape.
3. Execute it with the location id of the target tenant.

Describe before the first use of any operation: the description shows whether the body is JSON or key-value, which fields are required, and default values. Confirm the server is the one mapped to the target tenant before executing (automation domain skill).
