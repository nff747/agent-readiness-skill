<div align="center">

# 🤖 Agent Readiness Discovery (`agent-readiness-discovery`)

[![Lunar Paradox](https://img.shields.io/badge/Organization-Lunar_Paradox-0a0e1a?style=for-the-badge&logo=probot&logoColor=d7b886)](https://lunarparadox.com)
[![Live Interactive Sandbox](https://img.shields.io/badge/Live_Sandbox-Interactive_Auditor-06b6d4?style=for-the-badge&logo=googlechrome&logoColor=white)](https://nff747.github.io/agent-readiness-skill/)
### An open `agentskills.io` standard skill to make any website or API 100% AI-agent ready.

[![Agent Skills](https://img.shields.io/badge/Agent_Skills-v0.2.0-06b6d4?style=for-the-badge&logo=probot&logoColor=white)](https://schemas.agentskills.io/discovery/0.2.0/schema.json)
[![isitagentready](https://img.shields.io/badge/isitagentready.com-100%25_PASS-10b981?style=for-the-badge&logo=checkmarx&logoColor=white)](https://isitagentready.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-f59e0b?style=for-the-badge)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/nff747/agent-readiness-skill?style=for-the-badge&color=8b5cf6)](https://github.com/nff747/agent-readiness-skill/stargazers)

<p align="center">
  <b>Teach Claude Code, Cursor, Copilot, Codex, and Gemini CLI how to pass all 18 machine-readable discovery, authentication, bot verification, and agentic commerce standards in minutes.</b>
</p>

</div>


## 🎬 10-Second Terminal Walkthrough

See  audit a production Next.js / Cloudflare site and patch all failing specs in real time:

```text
$ npx skills add nff747/agent-readiness-skill
✔ Added agent-readiness-discovery to .claude/skills/ (v0.2.0)

$ claude
> Audit my site localhost:3000 for AI agent readiness and fix failing endpoints.

🤖 Running agent-readiness-discovery audit...
  ✖ [FAIL] /.well-known/api-catalog (RFC 9727) -> Missing linkset+json
  ✖ [FAIL] /.well-known/agent-card.json (A2A)  -> Missing A2A Agent Card
  ✖ [FAIL] /.well-known/mcp/server-card.json   -> Missing SEP-1649 manifest
  ✖ [FAIL] /auth.md                             -> 404 Not Found
  ✖ [FAIL] Accept: text/markdown negotiation   -> No Vary: Accept header

🔧 Generating RFC-compliant manifests & middleware handlers...
  ✔ Created app/.well-known/api-catalog/route.ts (application/linkset+json)
  ✔ Created app/.well-known/agent-card.json/route.ts
  ✔ Created app/.well-known/mcp/server-card.json/route.ts
  ✔ Created public/auth.md (Authentication guide for autonomous agents)
  ✔ Injected Vary: Accept Markdown transformer in middleware.ts

🚀 Re-running pre-flight validation:
  ======================================================
  Audit Target: http://localhost:3000
  Result: 18 / 18 CHECKS PASSED (100% Agent Ready)
  Score on isitagentready.com: A+
  ======================================================
```

---

## ⚡ The Problem: 16+ Competing Specs to Make a Site "Agent Ready"

When autonomous AI agents (Claude, ChatGPT, OpenAI Operator, Google Gemini, OpenClaw) try to interact with your site, they need machine-readable discovery manifests, auth protocols, and content negotiation. 

Instead of reading RFC 9727, RFC 9728, A2A, MCP SEP-1649, WebMCP, DNS-AID, Web Bot Auth, ACP, AP2, MPP, UCP, x402, `auth.md`, Content Signals, and Markdown negotiation, install this skill and prompt your agent:

> *"Audit our site for AI agent readiness and implement all required well-known manifests and headers to pass `isitagentready.com`."*

---

## 🚀 Quick Install (1 Line)

### With GitHub CLI
```bash
gh skill install nff747/agent-readiness-skill agent-readiness-discovery
```

### With `npx skills`
```bash
npx skills add nff747/agent-readiness-skill
```

### Manual Install for Claude Code or Cursor
```bash
# For Claude Code (.claude/skills)
git clone https://github.com/nff747/agent-readiness-skill.git /tmp/ars && \
  mkdir -p .claude/skills && \
  cp -r /tmp/ars/skills/agent-readiness-discovery .claude/skills/ && \
  rm -rf /tmp/ars

# For Cursor (.cursor/skills)
mkdir -p .cursor/skills && \
  git clone https://github.com/nff747/agent-readiness-skill.git /tmp/ars && \
  cp -r /tmp/ars/skills/agent-readiness-discovery .cursor/skills/ && \
  rm -rf /tmp/ars
```

---

## 📊 Complete 18-Check Specification Matrix

| Category | Check / Protocol | Standard / RFC | Endpoint or Header |
| :--- | :--- | :--- | :--- |
| **Discovery** | API Catalog | [RFC 9727](https://www.rfc-editor.org/rfc/rfc9727) | `GET /.well-known/api-catalog` (`application/linkset+json`) |
| **Discovery** | Link Response Headers | [RFC 8288](https://www.rfc-editor.org/rfc/rfc8288) | `Link: </.well-known/api-catalog>; rel="api-catalog"` |
| **Discovery** | A2A Agent Card | Agent-to-Agent v1 | `GET /.well-known/agent-card.json` |
| **Discovery** | Agent Skills Index | [agentskills.io v0.2.0](https://schemas.agentskills.io) | `GET /.well-known/agent-skills/index.json` |
| **Discovery** | MCP Server Card | [SEP-1649](https://modelcontextprotocol.io) | `GET /.well-known/mcp/server-card.json` |
| **Browser** | WebMCP | Model Context DOM API | `navigator.modelContext.registerTool()` on page load |
| **DNS** | DNS-AID | DNS SVCB/HTTPS Records | `_agents.<domain>` ServiceMode records + DNSSEC |
| **Auth** | OAuth Protected Resource | [RFC 9728](https://www.rfc-editor.org/rfc/rfc9728) | `GET /.well-known/oauth-protected-resource` |
| **Auth** | OAuth / OIDC Server | [RFC 8414](https://www.rfc-editor.org/rfc/rfc8414) | `GET /.well-known/oauth-authorization-server` |
| **Auth** | Agent Auth Guide | [auth.md](https://auth.md) | `GET /auth.md` (Markdown with H1 `# auth.md`) |
| **Bot Verify** | Web Bot Auth | IETF WebBotAuth / RFC 9421 | `GET /.well-known/http-message-signatures-directory` |
| **Signals** | Content Signals | Robots.txt Standard | `Content-Signal: ai-train=no, search=yes, ai-input=no` |
| **Content** | Markdown for Agents | HTTP Content Negotiation | `Accept: text/markdown` negotiation with `Vary: Accept` |
| **Commerce** | ACP | Agentic Commerce Protocol | `GET /.well-known/acp.json` |
| **Commerce** | AP2 | Google Agent Payments | A2A Agent Card `capabilities.extensions` |
| **Commerce** | MPP | Machine Payment Protocol | `/openapi.json` with `x-payment-info` |
| **Commerce** | UCP | Universal Commerce Protocol| `GET /.well-known/ucp` |
| **Commerce** | x402 | HTTP 402 Micropayments | HTTP `402 Payment Required` on protected API routes |

---

## 🛠️ Included Executable CLI Auditor

This repository includes a standalone local pre-flight auditor script (`scripts/check-readiness.sh`) that tests any live domain or local dev server without needing an AI agent:

```bash
# Audit any public website
./scripts/check-readiness.sh example.com

# Audit a local staging or dev environment
./scripts/check-readiness.sh localhost:3000
```

### Script Capabilities
- Verifies `Link` headers on `/`.
- Confirms RFC 9727 `application/linkset+json` Content-Type on `/.well-known/api-catalog`.
- Tests `robots.txt` for `Content-Signal` directives.
- Tests `Accept: text/markdown` content negotiation and ensures `Vary: Accept` is present.
- Validates all `/.well-known/*` endpoints and `/auth.md` H1 heading compliance.
- Queries Cloudflare DoH (`https://cloudflare-dns.com/dns-query`) for DNS-AID SVCB/HTTPS records and checks DNSSEC Authenticated Data (`AD: true`).

---

## 🧠 What's Inside the Skill?

```text
skills/agent-readiness-discovery/
├── SKILL.md                                 # Core workflow, triage rules, and scanner lookup table
└── references/
    ├── discovery-templates.md               # RFC 9727, Link headers, A2A, Agent Skills, MCP, WebMCP, DNS-AID
    ├── auth-and-bot-templates.md            # OAuth PRM (RFC 9728), OIDC, auth.md, Web Bot Auth JWKS
    ├── commerce-and-content-templates.md     # ACP, AP2, MPP, UCP, x402, robots.txt, Cloudflare Worker negotiation
    └── validation-checklist.md              # curl/jq commands, sha256 calculation, and isitagentready API checks
```

---

## ⚠️ Top Implementation Gotchas Avoided by this Skill

1. **The API Catalog Content-Type Trap:** Returning `application/json` instead of `application/linkset+json` causes RFC 9727 validation failure even when JSON is structurally valid.
2. **Missing `auth.md` H1 Heading:** `/auth.md` must be served from the root as plain Markdown with an H1 heading containing `auth.md`.
3. **CDN Caching Poisoning on Markdown:** When serving `Accept: text/markdown`, omitting `Vary: Accept` can cause CDNs to serve raw Markdown to regular browser visitors.
4. **Unsigned DNS-AID Records:** DNS-AID records under `_agents.<domain>` must have DNSSEC enabled so validating resolvers set `AD: true`.
5. **Passive Audit Safety:** The skill enforces passive-only verification so agents never accidentally trigger live account creation via `POST /agent/auth`.

---

## 🤝 Contributing

Contributions and updates to track evolving specifications are welcome! Please open an issue or pull request.

## 📄 License

[MIT](LICENSE) © 2026 [nff747](https://github.com/nff747)

---

*A component of the [Lunar Paradox](https://lunarparadox.com) applied systems & graphics laboratory. Engineered by nff747.*
