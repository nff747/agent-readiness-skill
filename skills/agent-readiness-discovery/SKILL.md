---
name: agent-readiness-discovery
description: Implement, audit, and validate AI agent discovery, authentication, bot verification, content negotiation, and agentic commerce protocols for websites and APIs. Use when adding or fixing well-known discovery endpoints (api-catalog, agent-card.json, agent-skills/index.json, mcp/server-card.json, openid-configuration, oauth-authorization-server, oauth-protected-resource, http-message-signatures-directory, acp.json, ucp), Link response headers, auth.md, Web Bot Auth, WebMCP, DNS-AID (_agents SVCB/HTTPS), AP2, MPP (openapi.json x-payment-info), x402, Content-Signal in robots.txt, Markdown for Agents, or failing isitagentready.com scan checks.
---

# Agent Readiness Discovery

## Summary

Audit, implement, and validate machine-readable discovery, authentication, bot verification, content negotiation, and agentic commerce standards so AI agents and readiness scanners can interact with a website or API reliably.

## When to Use

Use this skill when:

- Auditing a website or API for AI agent readiness or fixing failing `isitagentready.com` scan checks.
- Implementing `/.well-known/*` discovery endpoints, `Link` response headers, `/auth.md`, `robots.txt` `Content-Signal` directives, or `Accept: text/markdown` content negotiation.
- Exposing browser-side tools via WebMCP or DNS-level agent endpoints via DNS-AID (`_agents` `SVCB`/`HTTPS` records with DNSSEC).
- Adding agentic payment and commerce protocols (ACP, AP2 on A2A, MPP, UCP, or x402).
- Deploying discovery metadata at the edge (such as Cloudflare Workers, Transform Rules, Access, or Agents SDK).

## Reference Files

Load the relevant reference file before generating artifacts or code so schemas, headers, and edge patterns match each specification exactly:

- `references/discovery-templates.md` - Schemas and templates for API Catalog (RFC 9727), `Link` headers (RFC 8288), A2A Agent Card, Agent Skills Index v0.2.0, MCP Server Card (SEP-1649), WebMCP, and DNS-AID.
- `references/auth-and-bot-templates.md` - Schemas and templates for `/auth.md`, OAuth/OIDC Discovery (RFC 8414), OAuth Protected Resource Metadata (RFC 9728), `agent_auth` flows (ID-JAG, verified email, anonymous), and Web Bot Auth JWKS/headers.
- `references/commerce-and-content-templates.md` - Schemas, middleware, and edge snippets for ACP, AP2, MPP (`/openapi.json`), UCP, x402, `robots.txt` Content Signals, and Markdown for Agents negotiation.
- `references/validation-checklist.md` - Local pre-flight `curl`/`dig`/`shasum` verification commands, scanner API invocation, check-path mapping, and troubleshooting.

## Workflow

### Step 1: Triage Scope by Site Type

Only implement protocols backed by real capabilities. Do not publish dummy commerce, A2A, or MCP manifests on sites that do not offer those services.

| Capability Group | Static / Content Site | Public or Authenticated API | Agent / MCP Service | Commerce / Paid API |
| :--- | :--- | :--- | :--- | :--- |
| Content Signals (`robots.txt`) & Markdown for Agents | Required | Recommended | Recommended | Recommended |
| `Link` Headers & API Catalog (`/.well-known/api-catalog`) | Optional (if API exists) | Required | Required | Required |
| OAuth/OIDC, OAuth PRM, `/auth.md` | Skip unless gated | Required if authenticated | Required if authenticated | Required if authenticated |
| A2A Agent Card, MCP Server Card, Agent Skills Index, DNS-AID | Optional (Skills/WebMCP) | Optional | Required | Optional (A2A needed for AP2) |
| WebMCP (`navigator.modelContext`) | Recommended for interactive UI | Optional | Optional | Recommended for interactive UI |
| Web Bot Auth (JWKS + signed requests) | Only if site sends bot traffic | Only if service sends bot traffic | Required if agent makes outbound requests | Optional |
| ACP, AP2, MPP, UCP, x402 | Skip | Only for paid endpoints | Only for payable actions | Required (pick matching protocol) |

### Step 2: Map Failing Checks to Specs

Use this lookup table to route any failing scanner check or implementation request directly to its target path, requirements, and template reference.

| Check / Standard | Endpoint or Mechanism | Key Requirements | Reference |
| :--- | :--- | :--- | :--- |
| `checks.discovery.apiCatalog` | `/.well-known/api-catalog` | HTTP 200, `Content-Type: application/linkset+json`, `linkset[]` with `anchor`, `service-desc`, `service-doc`, optional `status` | `references/discovery-templates.md` |
| `checks.discoverability.linkHeaders` | Homepage `Link` header | RFC 8288 relations: `api-catalog`, `service-desc`, `service-doc`, `describedby` | `references/discovery-templates.md` |
| `checks.discovery.a2aAgentCard` | `/.well-known/agent-card.json` | HTTP 200 JSON with `name`, `version`, `description`, `supportedInterfaces`, `capabilities`, `skills[]` | `references/discovery-templates.md` |
| `checks.discovery.agentSkills` | `/.well-known/agent-skills/index.json` | HTTP 200 JSON with v0.2.0 `$schema`, `skills[]` (`name`, `type`, `description`, `url`, `digest: "sha256:..."`) | `references/discovery-templates.md` |
| `checks.discovery.mcpServerCard` | `/.well-known/mcp/server-card.json` | HTTP 200 JSON with `serverInfo`, transport `endpoint`, `capabilities` | `references/discovery-templates.md` |
| `checks.discovery.webMcp` | Client JS on page load | `navigator.modelContext.registerTool()` with `name`, `description`, `inputSchema`, `execute`, `AbortController` signal | `references/discovery-templates.md` |
| `checks.discoverability.dnsAid` | `_agents.<domain>` DNS | ServiceMode `SVCB`/`HTTPS` with `alpn`, `port`, numeric `keyNNNNN` experimental params, DNSSEC signed | `references/discovery-templates.md` |
| `checks.discovery.oauthDiscovery` | `/.well-known/openid-configuration` or `/.well-known/oauth-authorization-server` | HTTP 200 JSON with `issuer`, `authorization_endpoint`, `token_endpoint`, `jwks_uri`, `grant_types_supported`, `response_types_supported` | `references/auth-and-bot-templates.md` |
| `checks.discovery.oauthProtectedResource` | `/.well-known/oauth-protected-resource` | HTTP 200 JSON with `resource`, `authorization_servers`, optional `scopes_supported`, optional `401` `WWW-Authenticate` | `references/auth-and-bot-templates.md` |
| `authMd` | `/auth.md` + OAuth PRM & AS metadata | Markdown with H1 containing `auth.md`; PRM `bearer_methods_supported: ["header"]`; AS `agent_auth` block or self-contained guide | `references/auth-and-bot-templates.md` |
| `checks.botAccessControl.webBotAuth` | `/.well-known/http-message-signatures-directory` | JWKS with at least 1 public key; outbound requests signed with `Signature-Agent` and `Signature-Input` | `references/auth-and-bot-templates.md` |
| Content Signals | `/robots.txt` | `Content-Signal: ai-train=..., search=..., ai-input=...` directives | `references/commerce-and-content-templates.md` |
| Markdown for Agents | HTTP `Accept` negotiation | Return `text/markdown` when `Accept: text/markdown` is sent; keep `text/html` default with `Vary: Accept` | `references/commerce-and-content-templates.md` |
| `checks.commerce.acp` | `/.well-known/acp.json` | HTTP 200 JSON with `protocol` (`name: "acp"`, `version`), `api_base_url`, `transports[]`, `capabilities.services[]` | `references/commerce-and-content-templates.md` |
| AP2 (Agent Payments Protocol) | A2A Agent Card extension | Extension URI `https://github.com/google-agentic-commerce/AP2/tree/v0.1.0`, `params.roles`, `required: true` for merchants | `references/commerce-and-content-templates.md` |
| `checks.commerce.mpp` | `/openapi.json` | HTTP 200 OpenAPI with `x-payment-info` (`intent`, `method`, `amount`) on payable operations and optional `x-service-info` | `references/commerce-and-content-templates.md` |
| `checks.commerce.ucp` | `/.well-known/ucp` | HTTP 200 JSON with `protocol_version`, `services`, `capabilities`, `endpoints` and reachable referenced schemas | `references/commerce-and-content-templates.md` |
| `checks.commerce.x402` | Protected API routes | `@x402/express`, `@x402/hono`, or `@x402/next` middleware returning HTTP `402` with facilitator URL and wallet address | `references/commerce-and-content-templates.md` |

### Step 3: Implement and Align Cross-Document Contracts

Before deploying, enforce cross-file invariants that frequently break scanners:

1. **Issuer parity:** Every URL in `/.well-known/oauth-protected-resource` `authorization_servers` must match the exact `issuer` string served at that server's `/.well-known/oauth-authorization-server` or `/.well-known/openid-configuration`.
2. **Link-to-endpoint parity:** Every target advertised in homepage `Link` headers or `/.well-known/api-catalog` (`service-desc`, `service-doc`, `status`) must return HTTP 200 with matching `Content-Type` (`application/linkset+json` for `api-catalog`, `application/json` or `application/openapi+json` for OpenAPI).
3. **Digest integrity:** Compute `sha256:{hex}` digests for `/.well-known/agent-skills/index.json` directly against the exact published bytes of each `SKILL.md` or archive after any edit.
4. **Content negotiation caching:** Always include `Vary: Accept` when serving Markdown vs HTML on the same URL so CDNs and browsers do not serve cached Markdown to browser users.
5. **Edge deployment:** When modifying origin servers is impractical (such as static hosts or SaaS sites), deploy `Link` headers via Cloudflare Transform Rules and well-known endpoints or Markdown negotiation via Cloudflare Workers.

### Step 4: Run Pre-Flight Verification and Live Scan

Follow `references/validation-checklist.md` to verify HTTP statuses, headers, JSON structure, SHA-256 digests, and DNS-AID DoH responses locally before invoking `POST https://isitagentready.com/api/scan` with `{"url": "https://<domain>"}`.

## Gotchas

- **Never probe write/registration endpoints during passive audits:** Do not send `POST /agent/auth` or similar registration calls when validating Auth.md; registration creates accounts, triggers emails, or issues credentials. Validate public discovery metadata only.
- **Wrong `Content-Type` on API Catalog:** Serving `/.well-known/api-catalog` as `application/json` instead of `application/linkset+json` causes RFC 9727 validation failures.
- **Missing `auth.md` H1 heading:** `/auth.md` must be served as Markdown from the root with an H1 heading containing `auth.md` (for example, `# auth.md` or `# Example auth.md`).
- **Unsigned DNS-AID zones:** Publishing `_agents` `SVCB`/`HTTPS` records without DNSSEC causes validating resolvers to omit authenticated data (`AD`) flags.
- **Unreachable UCP or API Catalog links:** Scanners verify that referenced spec URLs, OpenAPI specs, and schemas are reachable; broken internal links fail the check even when the manifest JSON is valid.
- **Browser-gated WebMCP registration:** WebMCP is detected by loading the page in a browser. Guard `navigator.modelContext` cleanly so non-supporting browsers do not throw, and register tools during initial page load rather than only after a user click.
