---
name: messaging
description: Rules for WhatsApp and website chat channels - the 24h window, templates, delivery status, inbound filtering, human takeover, consent and operator alerts. Use when sending, receiving or automating customer messages on any chat channel.
metadata:
  managed-by: aiagents
---

# Skill: messaging

## Purpose

Send and receive customer messages reliably. A provider accepting a send is not delivery; most rules close that gap.

## When to use

- Sending free text, templates or follow-ups on WhatsApp or similar channels
- Processing inbound messages (filtering, media, bursts)
- Adding human takeover, consent checks or operator alerts
- Embedding or changing a website chat widget

Live changes follow the automation domain skill; webhook auth, idempotency and retries the integrations skill; debounce the n8n skill (`references/patterns.md`).

## Hard rules

- Free text outside the 24h window is not delivered, yet the API still answers success. Allow free-text follow-ups only inside a safety margin (for example 23.5h); otherwise send a template.
- Templates are scoped to one provider account. Never reuse a template identifier across accounts; a cross-account branch can fail silently.
- Template variables must never be empty. Body limit is 1024 characters. Start approval first; it has the longest lead time.
- Ignore inbound messages sent by the business itself, group chats and broadcasts. Drop filler lines ("wait...") and debounce bursts.
- Media may arrive without content: degrade to text and ask the user to write. Transcribe voice notes; use vision for photos.
- Human takeover: when staff reply from the phone, pause the agent on that chat for N hours. Detect it as a sent message matching no stored hash of the agent's own replies.
- Re-check consent and do-not-disturb inside the sending worker for marketing messages, at send time.
- Automated follow-ups use deterministic text, never an LLM.
- Send operator alerts on a channel separate from customer traffic, with escaped content (HTML mode); an unescaped Markdown character can drop the alert.

## Workflow

1. Identify provider and account; open the provider reference.
2. Choose type from the window: free text inside the margin, otherwise a filled template.
3. Gate marketing sends on a fresh consent check in the worker.
4. Send, store message id and reply hash, then poll status to a final state.
5. On inbound: filter, debounce, handle media, check the takeover pause, then invoke the agent.

## Verification

- Require status delivered or read, not a created response.
- Send to a designated test number and confirm on the handset, once outside the window to prove the template path.
- For takeover, reply from the phone and confirm the agent stays silent.

## Failure modes

- Created, later failed -> free text outside the window -> poll status; use a template.
- Template silent or rejected -> other account's template or empty variable -> use the owning account's; validate variables.
- Agent answers its own echoes -> business-sent messages not filtered -> drop at intake.
- Agent talks over staff -> takeover undetected -> compare stored reply hashes.
- Alert never arrives -> unescaped markup -> HTML mode with escaping.

## References

| Sub-task | Open |
|---|---|
| Sending or receiving on a specific WhatsApp provider | references/whatsapp-providers.md |
| Embedding or changing a website chat widget | references/chat-widget.md |
