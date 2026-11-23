# Commerce, Content Signals, and Markdown Negotiation Templates

Replace `example.com`, wallet addresses, and facilitator URLs with production values.

## 1. Content Signals in `robots.txt`

- **Endpoint:** `GET /robots.txt`
- **Status:** `200 OK`
- **Header:** `Content-Type: text/plain; charset=utf-8`

Declare explicit preferences for `ai-train`, `search`, and `ai-input`:

```text
User-agent: *
Content-Signal: ai-train=no, search=yes, ai-input=no
Allow: /
```

Adjust values (`yes` or `no`) per site policy (for example, `ai-train=no, search=yes, ai-input=yes` for documentation sites that want RAG/grounding usage without model training).

## 2. Markdown for Agents (`Accept: text/markdown`)

Serve Markdown when `Accept` explicitly prefers `text/markdown`, while keeping `text/html` as the default for standard browsers. Always set `Vary: Accept`.

### Cloudflare Worker Pattern

```javascript
export default {
  async fetch(request, env) {
    const accept = request.headers.get("Accept") || "";
    const wantsMarkdown = accept.includes("text/markdown");

    if (!wantsMarkdown) {
      const htmlResp = await fetch(request);
      const res = new Response(htmlResp.body, htmlResp);
      res.headers.append("Vary", "Accept");
      return res;
    }

    // Serve pre-rendered Markdown or convert HTML to clean Markdown
    const url = new URL(request.url);
    const mdPath = url.pathname === "/" ? "/index.md" : `${url.pathname.replace(/\/$/, "")}.md`;
    const mdResp = await env.ASSETS.fetch(new Request(new URL(mdPath, url.origin)));

    if (mdResp.ok) {
      return new Response(mdResp.body, {
        status: 200,
        headers: {
          "Content-Type": "text/markdown; charset=utf-8",
          "Vary": "Accept"
        }
      });
    }

    // Fallback: pass through HTML with Vary: Accept if no Markdown representation exists
    const fallback = await fetch(request);
    const res = new Response(fallback.body, fallback);
    res.headers.append("Vary", "Accept");
    return res;
  }
};
```

## 3. ACP Discovery Document (Agentic Commerce Protocol)

- **Endpoint:** `GET /.well-known/acp.json`
- **Status:** `200 OK`
- **Header:** `Content-Type: application/json`

```json
{
  "protocol": {
    "name": "acp",
    "version": "1.0.0"
  },
  "api_base_url": "https://api.example.com/acp/v1",
  "transports": [
    "rest"
  ],
  "capabilities": {
    "services": [
      "checkout",
      "order_status"
    ]
  }
}
```

## 4. AP2 (Agent Payments Protocol) Extension on A2A Agent Card

Add this entry inside `capabilities.extensions` in `/.well-known/agent-card.json`:

```json
{
  "capabilities": {
    "extensions": [
      {
        "uri": "https://github.com/google-agentic-commerce/AP2/tree/v0.1.0",
        "description": "Supports cryptographically signed AP2 payment mandates.",
        "required": true,
        "params": {
          "roles": [
            "merchant"
          ]
        }
      }
    ]
  }
}
```

Valid `params.roles` values: `merchant`, `shopper`, `credentials-provider`, `payment-processor`. Set `"required": true` for merchant agents.

## 5. MPP Payment Discovery (Machine Payment Protocol)

- **Endpoint:** `GET /openapi.json`
- **Status:** `200 OK`
- **Header:** `Content-Type: application/json`

Include `x-payment-info` on payable operations (`intent`: `charge` or `session`; `method`: `tempo`, `stripe`, `lightning`, or `card`; `amount`), plus optional `currency`, `description`, and top-level `x-service-info`:

```json
{
  "openapi": "3.1.0",
  "info": {
    "title": "Example Paid API",
    "version": "1.0.0"
  },
  "x-service-info": {
    "categories": [
      "data",
      "analytics"
    ]
  },
  "paths": {
    "/v1/reports/generate": {
      "post": {
        "summary": "Generate a market intelligence report",
        "x-payment-info": {
          "intent": "charge",
          "method": "stripe",
          "amount": "0.50",
          "currency": "USD",
          "description": "Per-report generation fee"
        },
        "responses": {
          "200": {
            "description": "Generated report"
          },
          "402": {
            "description": "Payment Required"
          }
        }
      }
    }
  }
}
```

## 6. Universal Commerce Protocol (UCP)

- **Endpoint:** `GET /.well-known/ucp`
- **Status:** `200 OK`
- **Header:** `Content-Type: application/json`
- **Requirement:** All referenced spec URLs and schema URLs must be publicly reachable (HTTP 200).

```json
{
  "protocol_version": "2026-01",
  "services": [
    {
      "id": "content-access",
      "name": "Paid Content Access",
      "spec": "https://ucp.dev/specification/overview/"
    }
  ],
  "capabilities": [
    "checkout",
    "content_licensing"
  ],
  "endpoints": {
    "checkout": "https://api.example.com/ucp/checkout",
    "verify": "https://api.example.com/ucp/verify"
  }
}
```

## 7. x402 Payment Protocol

Install the framework adapter (`@x402/hono`, `@x402/express`, or `@x402/next`) and protect payable routes so unauthenticated/unpaid requests return HTTP `402` with machine-readable payment requirements.

### Example (`@x402/hono`)

```typescript
import { Hono } from "hono";
import { paymentMiddleware } from "@x402/hono";

const app = new Hono();

app.use(
  "/api/premium/*",
  paymentMiddleware(
    process.env.X402_WALLET_ADDRESS!,
    {
      "/api/premium/data": {
        price: "$0.01",
        network: "base"
      }
    },
    {
      url: process.env.X402_FACILITATOR_URL!
    }
  )
);

app.get("/api/premium/data", (c) => c.json({ ok: true }));

export default app;
```
