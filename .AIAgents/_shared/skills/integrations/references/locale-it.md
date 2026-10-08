# Italian Market Defaults
Last verified: 2026-10-08
Prefer live documentation and observed behaviour over this file; report any drift.

Use for projects serving Italian customers. These are defaults; the project context overrides them.

## Time and hours

- Timezone is Europe/Rome (CET/CEST, DST changes in March and October). Pass it explicitly everywhere.
- Business windows are typically Monday to Saturday with a lunch pause; confirm per client and encode them as data.

## Phone numbers

- Normalize to E.164 with `+39`. Strip `+39` and `0039` only for display.
- `+39 3...` is mobile and can usually reach WhatsApp. `+39 0...` is landline: voice only.
- `+39 8...` and `+39 1...` are special-rate or service numbers. Discard them from outreach lists.

## Language register

- Use the formal "Lei" form with customers. No emoji.
- For text to speech, write numbers in words and add pronunciation hints for brand names and foreign words.
- Speech recognition misreads place names and surnames. Fix with boosted keywords plus a deterministic alias table, not prompt wording alone.

## Addresses

- Map postcode to province with a table.
- Geocode with the locality as a constraint; discard results that fall in a different municipality than the one given.

## Compliance

- Disclosing that the caller is an AI (AI Act, art. 50) is an open question per project; record the decision in the project context.
- A caller asking about GDPR or "where did you get my number" is a legal request: escalate to a human and do not answer on the merits.
