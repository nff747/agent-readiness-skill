# Discovery, Browser, and DNS Templates

Replace `example.com` and placeholder URLs with the target service's domain and real endpoints.

## 1. API Catalog (RFC 9727)

- **Endpoint:** `GET /.well-known/api-catalog`
- **Status:** `200 OK`
- **Header:** `Content-Type: application/linkset+json`

```json
{
  "linkset": [
    {
      "anchor": "https://api.example.com/v1",
      "service-desc": [
        {
          "href": "https://example.com/openapi.json",
          "type": "application/openapi+json"
        }
      ],
      "service-doc": [
        {
          "href": "https://docs.example.com/api",
          "type": "text/html"
        }
      ],
      "status": [
        {
          "href": "https://api.example.com/health",
          "type": "application/json"
        }
      ]
    }
  ]
}
```

## 2. Link Response Headers (RFC 8288 & RFC 9727 Section 3)

Return on the homepage (`GET /`) as multiple `Link` headers or a comma-separated header:

```http
Link: </.well-known/api-catalog>; rel="api-catalog", </openapi.json>; rel="service-desc", <https://docs.example.com/api>; rel="service-doc", </.well-known/agent-card.json>; rel="describedby"
```

Cloudflare edge options:

- **Transform Rules:** Create an HTTP Response Header Modification rule matching `http.request.uri.path eq "/"` that adds `Link`.
- **Workers:** Clone the upstream response and append `response.headers.append("Link", '</.well-known/api-catalog>; rel="api-catalog"')`.

## 3. A2A Agent Card

- **Endpoint:** `GET /.well-known/agent-card.json`
- **Status:** `200 OK`
- **Header:** `Content-Type: application/json`

```json
{
  "name": "Example Agent",
  "version": "1.0.0",
  "description": "Assists agents with catalog queries and order status lookups.",
  "supportedInterfaces": [
    {
      "url": "https://agent.example.com/a2a",
      "protocolBinding": "JSONRPC"
    }
  ],
  "capabilities": {
    "streaming": true,
    "pushNotifications": false,
    "extensions": []
  },
  "skills": [
    {
      "id": "search-catalog",
      "name": "Search Catalog",
      "description": "Search products and retrieve structured pricing and availability."
    }
  ]
}
```

Note: If adding AP2 commerce support, populate `capabilities.extensions` per `references/commerce-and-content-templates.md`.

## 4. Agent Skills Discovery Index (v0.2.0)

- **Endpoint:** `GET /.well-known/agent-skills/index.json`
- **Status:** `200 OK`
- **Header:** `Content-Type: application/json`

```json
{
  "$schema": "https://schemas.agentskills.io/discovery/0.2.0/schema.json",
  "skills": [
    {
      "name": "query-api",
      "type": "skill-md",
      "description": "Authenticate and query the Example REST API with pagination and rate-limit handling.",
      "url": "https://example.com/.well-known/agent-skills/query-api/SKILL.md",
      "digest": "sha256:REPLACE_WITH_EXACT_64_CHAR_HEX_SHA256"
    }
  ]
}
```

Rules:

- `name` must be lowercase alphanumeric and hyphens only.
- `type` must be `"skill-md"` (single `SKILL.md`) or `"archive"` (bundled archive).
- Compute `digest` from the exact published artifact bytes:

```bash
printf "sha256:%s\n" "$(shasum -a 256 path/to/SKILL.md | awk '{print $1}')"
```

## 5. MCP Server Card (SEP-1649)

- **Endpoint:** `GET /.well-known/mcp/server-card.json`
- **Status:** `200 OK`
- **Header:** `Content-Type: application/json`

```json
{
  "serverInfo": {
    "name": "example-mcp-server",
    "version": "1.0.0"
  },
  "transport": {
    "type": "streamable-http",
    "endpoint": "https://example.com/mcp"
  },
  "endpoint": "https://example.com/mcp",
  "capabilities": {
    "tools": {
      "listChanged": true
    },
    "resources": {
      "subscribe": false,
      "listChanged": true
    },
    "prompts": {
      "listChanged": false
    }
  }
}
```

## 6. WebMCP (Browser Tool Registration)

Run on initial page load so headless browser scanners detect registered tools:

```javascript
const webMcpController = new AbortController();

function registerSiteTools() {
  if (!navigator.modelContext || typeof navigator.modelContext.registerTool !== "function") {
    return;
  }

  navigator.modelContext.registerTool(
    {
      name: "search_site",
      description: "Search articles, documentation, or products on Example.",
      inputSchema: {
        type: "object",
        properties: {
          query: { type: "string", description: "Search query text" },
          limit: { type: "integer", minimum: 1, maximum: 20, default: 5 }
        },
        required: ["query"]
      },
      execute: async ({ query, limit = 5 }) => {
        const res = await fetch(`/api/search?q=${encodeURIComponent(query)}&limit=${limit}`);
        if (!res.ok) throw new Error(`Search failed: ${res.status}`);
        return await res.json();
      }
    },
    { signal: webMcpController.signal }
  );
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", registerSiteTools);
} else {
  registerSiteTools();
}

// Call webMcpController.abort() when tearing down tools in an SPA route change.
```

## 7. DNS for AI Discovery (DNS-AID)

Publish ServiceMode `SVCB` (or `HTTPS` for HTTPS endpoints) records under `_agents.<domain>` and enable DNSSEC on the zone:

```dns
_index._agents.example.com. 3600 IN HTTPS 1 agent.example.com. alpn="h2,h3" port=443
_a2a._agents.example.com.   3600 IN SVCB  1 agent.example.com. alpn="a2a" port=443 mandatory=alpn,port
```

Guidelines:

- Use numeric `keyNNNNN` SvcParamKey names for experimental DNS-AID custom parameters until IANA-registered.
- Sign the public DNS zone with DNSSEC so validating DoH resolvers (`https://cloudflare-dns.com/dns-query`, fallback `https://dns.google/resolve`) return authenticated data (`AD: true`).
