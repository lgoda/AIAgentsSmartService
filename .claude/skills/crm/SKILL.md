---
name: crm
description: CRM as system of record for contacts, appointments and do-not-disturb state, with vendor-neutral rules for upserts, search lag, dates, partial updates, trigger loops and backfills. Use when automation reads or writes CRM contacts, calendars, opportunities or CRM workflows.
metadata:
  managed-by: aiagents
---

# Skill: crm

## Purpose

Keep automation and the CRM consistent. The CRM owns contacts, appointments and consent; automation reads it and writes narrowly. Live changes follow the automation domain skill.

## When to use

- Creating, finding or updating contacts, appointments or opportunities
- Applying or checking do-not-disturb (DND) state
- CRM workflows that call the automation, or automation changing fields they watch

## Hard rules

- The CRM is the system of record. Fix availability there, never in a prompt or a second store.
- Scope every call to one tenant and one location or account; use only that tenant's credentials.
- Upsert contacts by normalized phone (format: integrations skill). A first message may arrive before the contact exists: fall back to the phone as key, and let per-contact calls that fail on it continue.
- Search indexes lag writes. For authoritative state (DND, a just-created appointment), read by id, never by search.
- Send an explicit timezone, from tenant config, with every appointment time. Normalize offsetless local times and ISO-with-offset times before comparing.
- Prefer partial updates; split time changes from detail changes. An empty field in a full-replace or key-value body blanks data.
- Automation may set DND, never remove it; removal is human.
- The CRM can auto-clear DND when the customer writes. If your database says DND, re-apply it.
- Opt-out order: final message, own state update, then DND. A send rejected because DND is active means "not sent, do not retry".
- Never write a field a CRM workflow triggers on; it loops.
- Backfills use cursor pagination in small resumable batches, dry run first.
- Detect an agent-created appointment by diffing appointments before and after its turn.

## Workflow

1. Identify tenant, location and credential scope; confirm the operation semantics in live docs.
2. Read the current object by id.
3. Build the smallest payload with explicit timezone and normalized phone.
4. Write, re-read by id, compare.
5. Bulk work: one-batch dry run, then run with a stored cursor.

## Verification

- Re-read by id: only the intended fields changed.
- Appointments: start and timezone correct in the CRM, and the slot now blocks booking.
- DND: read the contact by id after the customer writes again.

## Failure modes

- Double booking -> availability outside the CRM, or external events do not block slots -> model it in the CRM.
- Appointment shifted by hours -> missing timezone, or offsetless time compared with ISO -> pass tenant timezone, normalize.
- Contact "not found" after create -> index lag -> read by id.
- Fields blanked -> full-replace body -> partial update.
- Endless workflow runs -> automation writes a trigger field -> write a different field.
- Auth, duplicate, rate-limit errors: integrations skill.

## References

| Sub-task | Open |
|---|---|
| Working with GoHighLevel specifically | references/gohighlevel.md |
