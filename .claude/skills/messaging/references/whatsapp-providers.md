# WhatsApp providers
Last verified: 2026-10-08
Prefer live documentation and observed behaviour over this file; report any drift.

Channel-agnostic rules (window, takeover, consent) live in the messaging skill. This file holds per-provider specifics. Always confirm against the provider's current documentation.

## Template-based business API provider (for example Twilio WABA)

- Templates are created as Content Templates and referenced by a content identifier (`ContentSid`) at send time.
- Marketing messages need the MARKETING template category.
- Templates and their identifiers belong to one provider account. A template referenced across accounts fails; a cross-account quick-reply branch failed silently, so test button replies in the owning account.
- All variables must be non-empty. Body limit is 1024 characters.
- Meta approval has the longest lead time. Submit templates before building the flow around them.
- A successful API response only means the message was accepted. Poll the message status to see delivery or failure.

## CRM-native Cloud API (through the CRM conversations API)

- The send call returns 201 even when the message is not delivered. Poll the message status and treat `failed` as the real result.
- The 24h window still applies; outside it use an approved template.
- Contact, consent and do-not-disturb handling belong to the crm skill.

## Self-hosted WhatsApp gateway (whatsapp-web.js-based, for example OpenWA)

- Authenticate with the `X-API-Key` header.
- chatId format is `<digits>@c.us`. Newer privacy ids (LID) can appear instead of phone numbers; resolve them through the contacts endpoint before replying or storing a phone.
- Sessions can go "zombie": status says ready while the socket is dead. Probe the session live with a real call; if dead, stop then start it. Never DELETE the session, which forces a new QR scan.
- Connecting a new session can kill the others on the same host, and a gateway restart drops all sessions. Plan restarts and reconnect checks.
- Outbound webhooks are HMAC-signed (`sha256=` prefix) and carry an idempotency key and a retry count header. Verification and dedup rules are in the integrations skill.
- Wait about 2 seconds between sends to avoid throttling or bans.
- Formatting: `*bold*`, `_italic_`, `~strike~`.

## Shared-inbox tool (for example Chatwoot)

- Agent Bots are attached per inbox and route that inbox's events to the automation. Isolation between clients or brands is per inbox, so never share one bot across tenants.
- Log outbound template sends as private notes so human agents see what the automation sent.
- Human replies from the inbox are the takeover signal; map them to the pause rule.

## Click-to-chat links

- Format: `wa.me/<digits>?text=<url-encoded text>`. Digits only, with country code, no plus sign or spaces.
- The prefilled text is a user-editable suggestion, not a trusted command. Use a short token in it to attribute the source, and treat it as untrusted input.

## QR onboarding links

- Customers scan a QR to link their number or session. Issue links as HMAC-signed, expiring, purpose-scoped tokens: valid for one purpose (for example "link session for tenant X") and a short time.
- Verify signature, expiry and purpose on every use. Never put long-lived secrets or API keys in the link.
- After a scan, verify the session is really connected by a live probe, not only by the scan callback.

## Checks when a provider misbehaves

1. Fetch the message status by id, not the send response.
2. Confirm window state: when did the customer last write?
3. Confirm the template belongs to the account that sent it.
4. For gateways, probe session health live before blaming content.
