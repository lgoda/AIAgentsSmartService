# Chat widget
Last verified: 2026-10-08
Prefer live documentation and observed behaviour over this file; report any drift.

Pattern for a website chat widget that talks to an automation webhook. The webhook contract itself (request and reply shape) is defined by the n8n skill; auth and timeouts by the integrations skill.

## Packaging

- Ship one IIFE bundle with the CSS injected into the JavaScript, so a customer site needs a single script tag.
- Expose a global init function, for example `window.<Brand>ChatBot.init(config)`. Calling init again replaces any earlier instance instead of mounting a second one.
- Keep one official embed variant. Older variants drifted from the current one, and hardcoded webhook URLs remained in public files. When replacing an embed, delete the old files and search for stale URLs.

## Configuration

- Layer configuration: defaults, then client config, then runtime config. Deep merge per section; arrays are replaced, not concatenated.
- Webhook URL precedence: runtime config, then build-time environment value, then none. With none, show a graceful "unavailable" state instead of failing silently or calling a wrong endpoint.
- Use a `__RUNTIME__` sentinel in build output to mean "the host page supplies this at runtime", so builds are not rebuilt per client.
- Client copy (greeting, labels, chip text) and business rules live in config. Brand rules live in the project's agent instructions, not in widget code.

## Chips (suggested replies)

- Before the first message, show static chips from config.
- After each answer, show AI-suggested chips returned with the reply. Validate them (count, length, plain text) before rendering.

## Accessibility

- Dialog semantics: `role="dialog"`, labelled, focus trapped while open, focus returned to the launcher on close.
- Escape closes the widget.
- Respect `prefers-reduced-motion`.
- Meet WCAG contrast for text and controls, including with client brand colours.

## Safe rendering

- Render replies with a small markdown parser that emits UI nodes (for React, elements), never `dangerouslySetInnerHTML` or raw HTML insertion. Model output and webhook replies are untrusted.
- Allow only links with safe schemes, opened with `rel="noopener noreferrer"`.

## Storage

- Wrap every `localStorage` and `sessionStorage` access in try/catch. Sandboxed iframes and some privacy modes throw on access. The widget must work with no storage, losing only history.

## Testing

1. Load the embed on a bare page and on a page with hostile CSS.
2. Test with storage blocked and with a missing webhook (expect the unavailable state).
3. Send a message end to end and confirm the automation execution, not only the on-screen reply.
4. Tab through the dialog and close with Escape.
5. Search the repository and public files for hardcoded webhook URLs.
