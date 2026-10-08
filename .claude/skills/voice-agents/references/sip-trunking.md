# SIP Trunking Reference
Last verified: 2026-10-08
Prefer live documentation and observed behaviour over this file; report any drift.

Scope: connecting phone numbers from a carrier to a voice platform. Agent behavior lives in SKILL.md.

## Model

- Numbers are imported into the voice platform as custom numbers with a termination URI that points at the carrier trunk.
- Inbound DID routing to the platform is configured at the carrier, not through the platform API. A number can look correct in the platform and still receive nothing.
- Binding a number to an agent is a separate step on the platform. See the platform reference.

## Carrier differences

- Carriers differ: some authenticate by IP over TCP, others by username and password (digest) over UDP.
- Never inherit another client's trunk configuration. Copy nothing but the checklist; each tenant gets its own trunk and credentials.
- Twilio Elastic SIP: use a tenant-specific termination domain over TCP, with credentials or IP access control on that trunk.

## Network checklist

1. Allowlist the voice platform's egress IP ranges at the carrier. Check current ranges in the platform's documentation.
2. Allow the carrier's signaling and media ranges on any firewall in the path.
3. Confirm transport (TCP or UDP) matches on both sides.
4. Confirm the termination URI uses the tenant's domain, not a shared one.

## Credentials

- The platform never returns the stored auth password.
- To change either value, rewrite username and password together. Updating only one can leave a mismatch you cannot read back.
- Keep the credentials in the secret store of the project; never in repo files or change records.

## Diagnostics

Separate network faults from auth faults before changing anything:

1. Send a manual SIP OPTIONS probe to the trunk endpoint from outside.
   - No response or timeout: network, firewall or allowlist problem.
   - Response with 401, 403 or 407: reachable; credentials or IP authorization problem.
   - Response 200: signaling path is fine; look at routing or the agent.
2. Place a test call from the designated test number only.
3. For intermittent faults, take a SIP packet capture on the trunk and read the call setup: which side hung up, which response code, retries.

## Symptoms

| Symptom | Likely cause |
|---|---|
| Call rings out, agent never answers | DID not routed to the platform at the carrier |
| Immediate failure on outbound | Egress IP not allowlisted, or wrong termination URI |
| 401 or 403 on outbound | Credentials mismatch or wrong auth mode for the carrier |
| One-way or no audio | Media range blocked, or NAT issue; check capture |
| Works on one tenant only | Trunk or domain shared or copied incorrectly |
