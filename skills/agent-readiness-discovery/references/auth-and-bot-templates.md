# Authentication Discovery and Bot Verification Templates

Replace `example.com` and `auth.example.com` with real service domains and issuers.

## 1. OAuth Protected Resource Metadata (RFC 9728)

- **Endpoint:** `GET /.well-known/oauth-protected-resource`
- **Status:** `200 OK`
- **Header:** `Content-Type: application/json`

```json
{
  "resource": "https://api.example.com",
  "authorization_servers": [
    "https://auth.example.com"
  ],
  "scopes_supported": [
    "read:data",
    "write:data"
  ],
  "bearer_methods_supported": [
    "header"
  ]
}
```

Recommended `401 Unauthorized` response header on protected API routes:

```http
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer resource_metadata="https://api.example.com/.well-known/oauth-protected-resource"
```

## 2. OAuth / OIDC Discovery (RFC 8414) + Auth.md `agent_auth`

- **Endpoint:** `GET /.well-known/oauth-authorization-server` (OAuth 2.0) and/or `GET /.well-known/openid-configuration` (OIDC)
- **Status:** `200 OK`
- **Header:** `Content-Type: application/json`
- **Invariant:** `issuer` MUST exactly match the URL listed in `authorization_servers` in the Protected Resource Metadata document.

```json
{
  "issuer": "https://auth.example.com",
  "authorization_endpoint": "https://auth.example.com/oauth/authorize",
  "token_endpoint": "https://auth.example.com/oauth/token",
  "jwks_uri": "https://auth.example.com/.well-known/jwks.json",
  "grant_types_supported": [
    "authorization_code",
    "client_credentials",
    "refresh_token"
  ],
  "response_types_supported": [
    "code"
  ],
  "agent_auth": {
    "skill": "https://example.com/auth.md",
    "register_uri": "https://auth.example.com/agent/auth",
    "identity_types_supported": [
      "identity_assertion",
      "anonymous"
    ],
    "identity_assertion": {
      "assertion_types_supported": [
        "urn:ietf:params:oauth:token-type:id-jag",
        "verified_email"
      ],
      "credential_types_supported": [
        "oauth_client"
      ],
      "claim_uri": "https://auth.example.com/agent/claim",
      "revocation_uri": "https://auth.example.com/agent/revoke",
      "events_supported": [
        "https://schemas.openid.net/secevent/caep/event-type/credential-change"
      ]
    },
    "anonymous": {
      "credential_types_supported": [
        "api_key"
      ],
      "claim_uri": "https://auth.example.com/agent/claim"
    }
  }
}
```

Flow-specific field requirements inside `agent_auth`:

- **ID-JAG:** Include `identity_types_supported: ["identity_assertion"]`, `identity_assertion.assertion_types_supported` with `urn:ietf:params:oauth:token-type:id-jag`, and `credential_types_supported`. Include `revocation_uri` and the revocation event in `events_supported` when supported (scanners may warn if omitted).
- **Verified email:** Include `identity_assertion.assertion_types_supported` with `verified_email`, `credential_types_supported`, and `claim_uri`.
- **Anonymous:** Include `identity_types_supported: ["anonymous"]`, `anonymous.credential_types_supported`, and `claim_uri`.

Only include flows the authorization server genuinely implements.

## 3. `/auth.md` Agent Registration Guide

- **Endpoint:** `GET /auth.md`
- **Status:** `200 OK`
- **Header:** `Content-Type: text/markdown; charset=utf-8`
- **Requirement:** Must contain an H1 heading that includes `auth.md` (for example, `# auth.md` or `# Example auth.md`).

### Option A: OAuth-Backed `/auth.md`

```markdown
# Example auth.md

Authentication and registration guide for AI agents accessing Example APIs.

## Discovery Metadata

- Protected Resource Metadata: `https://example.com/.well-known/oauth-protected-resource`
- Authorization Server Metadata: `https://auth.example.com/.well-known/oauth-authorization-server`

## Agent Registration

- Registration endpoint: `POST https://auth.example.com/agent/auth`
- Supported flows: ID-JAG (`urn:ietf:params:oauth:token-type:id-jag`), `verified_email`, or `anonymous`
- Claim URL (when applicable): `https://auth.example.com/agent/claim`

## Using Credentials

Send issued bearer tokens in the HTTP `Authorization` header:

`Authorization: Bearer <access_token>`
```

### Option B: Self-Contained `/auth.md` (No OAuth Metadata Available)

When OAuth metadata is not published, make `/auth.md` completely self-contained:

```markdown
# Example auth.md

This document explains how automated AI agents register and authenticate with Example APIs.

## Audience

Autonomous and user-assisted AI agents requesting programmatic access to `https://api.example.com`.

## Registration and Provisioning

- Endpoint: `POST https://api.example.com/v1/agent/register`
- Supported methods: `verified_email` (requires email confirmation link) or API key provisioning via account settings.
- Scopes: `read:data` (default), `write:data` (requires approval).

## Credential Usage

Attach your issued credential using the `Authorization` header on every request:

`Authorization: Bearer <token>`

Rotate or revoke compromised credentials via `POST https://api.example.com/v1/agent/revoke`.
```

Safety note: Never send live `POST /agent/auth` requests during passive scanning or verification.

## 4. Web Bot Auth (IETF WebBotAuth)

### Directory JWKS

- **Endpoint:** `GET /.well-known/http-message-signatures-directory`
- **Status:** `200 OK`
- **Header:** `Content-Type: application/http-message-signatures-directory+json` (or `application/json`)

```json
{
  "keys": [
    {
      "kty": "OKP",
      "crv": "Ed25519",
      "kid": "bot-key-2026-01",
      "use": "sig",
      "x": "REPLACE_WITH_BASE64URL_PUBLIC_KEY"
    }
  ]
}
```

### Signed Outbound Bot Request Headers

When your bot or agent sends outbound HTTP requests, include RFC 9421 HTTP Message Signature headers plus `Signature-Agent`:

```http
Signature-Agent: "https://example.com"
Signature-Input: sig1=("@authority" "signature-agent");created=1763800000;expires=1763800300;keyid="bot-key-2026-01";alg="ed25519";nonce="random-nonce";tag="web-bot-auth"
Signature: sig1=:BASE64_SIGNATURE_BYTES:
```

On Cloudflare, Web Bot Auth provides built-in verification for incoming signed bot traffic, while Workers can serve the JWKS directory and sign outbound `fetch` calls.
