# Validation Checklist and Scanner Reference

Run local pre-flight checks first so schema, header, digest, and DNS errors are caught before calling the remote scanner.

## 1. Local Pre-Flight Checks

Replace `example.com` with your target domain.

### Discovery and Headers

```bash
# Link headers on homepage
curl -sI https://example.com/ | grep -i '^link:'

# RFC 9727 API Catalog (must return 200 and application/linkset+json)
curl -i https://example.com/.well-known/api-catalog

# A2A Agent Card, Agent Skills Index, MCP Server Card
curl -fsS https://example.com/.well-known/agent-card.json | jq .
curl -fsS https://example.com/.well-known/agent-skills/index.json | jq .
curl -fsS https://example.com/.well-known/mcp/server-card.json | jq .
```

### Auth Discovery and Web Bot Auth (Passive Only)

```bash
# Auth.md (confirm H1 contains auth.md)
curl -fsS https://example.com/auth.md | head -n 20

# OAuth Protected Resource Metadata + Authorization Server Metadata
curl -fsS https://example.com/.well-known/oauth-protected-resource | jq .
curl -fsS https://example.com/.well-known/oauth-authorization-server | jq .
curl -fsS https://example.com/.well-known/openid-configuration | jq .

# Web Bot Auth JWKS (must contain >= 1 public key)
curl -fsS https://example.com/.well-known/http-message-signatures-directory | jq '.keys | length'
```

Never probe `POST /agent/auth` during passive validation.

### Content Signals and Markdown Negotiation

```bash
# robots.txt Content-Signal
curl -fsS https://example.com/robots.txt | grep -i 'Content-Signal'

# Markdown for Agents vs default browser HTML
curl -i -H "Accept: text/markdown" https://example.com/
curl -i -H "Accept: text/html" https://example.com/
```

Verify that `Accept: text/markdown` returns `Content-Type: text/markdown`, `Accept: text/html` returns `Content-Type: text/html`, and both include `Vary: Accept`.

### Commerce Protocols

```bash
curl -fsS https://example.com/.well-known/acp.json | jq .
curl -fsS https://example.com/openapi.json | jq '.paths | .. | .["x-payment-info"]? | select(. != null)'
curl -fsS https://example.com/.well-known/ucp | jq .
curl -i https://example.com/api/premium/data   # Expect HTTP 402 for x402 protected route
```

### DNS-AID via DNS-over-HTTPS (DoH)

The scanner queries Cloudflare DoH (`https://cloudflare-dns.com/dns-query`) with automatic fallback to Google DoH (`https://dns.google/resolve`), unless overridden via `ScanOptions.dohResolverUrl`.

```bash
# Check SVCB / HTTPS records and DNSSEC AD flag (AD: true)
curl -fsS -H "accept: application/dns-json" \
  "https://cloudflare-dns.com/dns-query?name=_a2a._agents.example.com&type=SVCB&do=1" | jq '{Status, AD, Answer}'

curl -fsS -H "accept: application/dns-json" \
  "https://cloudflare-dns.com/dns-query?name=_index._agents.example.com&type=HTTPS&do=1" | jq '{Status, AD, Answer}'
```

### Verify Agent Skill Artifact Digests

```bash
curl -fsS https://example.com/.well-known/agent-skills/query-api/SKILL.md | shasum -a 256
```

Compare the resulting 64-character hex digest against `sha256:{hex}` in `/.well-known/agent-skills/index.json`.

## 2. Run Remote Agent Readiness Scan

```bash
curl -fsS -X POST https://isitagentready.com/api/scan \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}' | jq '.checks'
```

## 3. Expected Passing Check Paths

Verify each implemented capability reports `"pass"`:

- `checks.discovery.apiCatalog.status`
- `checks.discoverability.linkHeaders.status`
- `checks.discovery.oauthDiscovery.status`
- `checks.discovery.oauthProtectedResource.status`
- `checks.discovery.a2aAgentCard.status`
- `checks.discovery.agentSkills.status`
- `checks.discovery.mcpServerCard.status`
- `checks.discovery.webMcp.status`
- `checks.discoverability.dnsAid.status`
- `checks.botAccessControl.webBotAuth.status`
- `checks.commerce.acp.status`
- `checks.commerce.mpp.status`
- `checks.commerce.ucp.status`
- `checks.commerce.x402.status`

Also confirm `authMd`, `ap2` (via A2A extensions), Content Signals (`robots.txt`), and Markdown for Agents negotiation checks report passing in the scan payload.

## 4. Common Failure Diagnostics

- **API Catalog fails despite HTTP 200:** Check `Content-Type` is literally `application/linkset+json`, and each `linkset` item has `anchor` plus `service-desc` / `service-doc`.
- **Auth.md warns or fails:** Confirm H1 contains `auth.md`, PRM includes `bearer_methods_supported: ["header"]`, `issuer` matches PRM `authorization_servers`, and `agent_auth` declares `skill`, `register_uri`, and a complete flow block (plus `revocation_uri` and `events_supported` for ID-JAG to avoid warnings).
- **Agent Skills fails:** Check `$schema` is `https://schemas.agentskills.io/discovery/0.2.0/schema.json` and the `sha256:` digest matches the live HTTP response body bytes (including trailing newlines).
- **WebMCP fails:** Ensure registration executes on page load without requiring user interaction and does not throw in headless Chromium.
- **DNS-AID fails:** Confirm records live under `_agents.<domain>`, use ServiceMode (`priority >= 1`, not AliasMode `0`), include `alpn`, and have DNSSEC enabled (`AD: true`).
