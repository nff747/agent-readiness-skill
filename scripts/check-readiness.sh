#!/usr/bin/env bash
# ==============================================================================
# Agent Readiness Local Auditor & Pre-Flight Verification Tool
# Audits any domain against all 18 AI agent discovery, auth, and commerce specs.
# Author: nff747 <nff747@users.noreply.github.com>
# License: MIT
# ==============================================================================

set -euo pipefail

DOMAIN="${1:-}"
if [[ -z "$DOMAIN" ]]; then
  echo "Usage: $0 <domain-or-url>"
  echo "Example: $0 example.com"
  exit 1
fi

# Normalize domain (strip protocol, trailing slash, path)
DOMAIN="${DOMAIN#http://}"
DOMAIN="${DOMAIN#https://}"
DOMAIN="${DOMAIN%%/*}"
BASE_URL="https://${DOMAIN}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

pass() { echo -e "  [${GREEN}PASS${NC}] $1"; }
fail() { echo -e "  [${RED}FAIL${NC}] $1"; }
warn() { echo -e "  [${YELLOW}WARN${NC}] $1"; }
info() { echo -e "  [${CYAN}INFO${NC}] $1"; }

echo -e "\n${BOLD}======================================================================${NC}"
echo -e "${BOLD} AI AGENT READINESS PRE-FLIGHT AUDIT // ${CYAN}${BASE_URL}${NC}"
echo -e "${BOLD}======================================================================${NC}\n"

# 1. Homepage Link Headers
echo -e "${BOLD}[1/7] Discoverability & Link Response Headers${NC}"
LINK_HEADER=$(curl -sI -L --max-time 10 "${BASE_URL}/" | grep -i '^link:' || true)
if [[ -n "$LINK_HEADER" ]]; then
  pass "Homepage Link header detected:"
  echo "$LINK_HEADER" | sed 's/^/         /'
else
  fail "No RFC 8288 Link headers found on ${BASE_URL}/"
fi

# 2. Robots.txt & Content-Signals
echo -e "\n${BOLD}[2/7] robots.txt & Content-Signal Directives${NC}"
ROBOTS_TXT=$(curl -sL --max-time 10 "${BASE_URL}/robots.txt" || true)
if echo "$ROBOTS_TXT" | grep -qi "Content-Signal"; then
  pass "Content-Signal directive present in robots.txt:"
  echo "$ROBOTS_TXT" | grep -i "Content-Signal" | sed 's/^/         /'
else
  warn "Content-Signal directive not declared in robots.txt"
fi

# 3. Content Negotiation (Markdown for Agents)
echo -e "\n${BOLD}[3/7] Markdown for Agents (Accept: text/markdown)${NC}"
MD_RESP=$(curl -sI -H "Accept: text/markdown" --max-time 10 "${BASE_URL}/" || true)
MD_CONTENT_TYPE=$(echo "$MD_RESP" | grep -i '^content-type:' || true)
VARY_HEADER=$(echo "$MD_RESP" | grep -i '^vary:' || true)

if echo "$MD_CONTENT_TYPE" | grep -qi "text/markdown"; then
  pass "Responded with Content-Type: text/markdown"
  if echo "$VARY_HEADER" | grep -qi "Accept"; then
    pass "Vary: Accept header present for CDN safety"
  else
    warn "Missing 'Vary: Accept' header (required for CDN cache isolation)"
  fi
else
  warn "Did not return text/markdown on Accept: text/markdown (returned: ${MD_CONTENT_TYPE:-none})"
fi

# 4. Standard Discovery Endpoints
echo -e "\n${BOLD}[4/7] /.well-known/* Machine-Readable Endpoints${NC}"

check_endpoint() {
  local name="$1"
  local url="$2"
  local expected_ct="$3"
  
  local resp
  resp=$(curl -sI -L --max-time 10 "$url" || true)
  local status
  status=$(echo "$resp" | grep -E '^HTTP/' | tail -n 1 | awk '{print $2}' || true)
  local ct
  ct=$(echo "$resp" | grep -i '^content-type:' | head -n 1 || true)

  if [[ "$status" == "200" ]]; then
    if [[ -n "$expected_ct" ]] && echo "$ct" | grep -qi "$expected_ct"; then
      pass "$name (HTTP 200, $expected_ct)"
    else
      pass "$name (HTTP 200, Content-Type: ${ct:-unknown})"
    fi
  else
    fail "$name -> HTTP ${status:-unreachable} ($url)"
  fi
}

check_endpoint "RFC 9727 API Catalog" "${BASE_URL}/.well-known/api-catalog" "application/linkset+json"
check_endpoint "A2A Agent Card" "${BASE_URL}/.well-known/agent-card.json" "application/json"
check_endpoint "Agent Skills Discovery Index" "${BASE_URL}/.well-known/agent-skills/index.json" "application/json"
check_endpoint "MCP Server Card (SEP-1649)" "${BASE_URL}/.well-known/mcp/server-card.json" "application/json"
check_endpoint "OAuth Protected Resource" "${BASE_URL}/.well-known/oauth-protected-resource" "application/json"
check_endpoint "OAuth Authorization Server" "${BASE_URL}/.well-known/oauth-authorization-server" "application/json"
check_endpoint "Web Bot Auth JWKS" "${BASE_URL}/.well-known/http-message-signatures-directory" "json"

# 5. Agent Auth Documentation (/auth.md)
echo -e "\n${BOLD}[5/7] Agent Authentication Guide (/auth.md)${NC}"
AUTH_MD_HEAD=$(curl -sL --max-time 10 "${BASE_URL}/auth.md" | head -n 10 || true)
if echo "$AUTH_MD_HEAD" | grep -qiE '^# .*auth\.md'; then
  pass "/auth.md accessible with required H1 heading"
else
  fail "/auth.md missing or does not contain required H1 'auth.md' header"
fi

# 6. Commerce & Payment Protocols
echo -e "\n${BOLD}[6/7] Agentic Commerce Protocols (ACP, MPP, UCP, x402)${NC}"
check_endpoint "ACP Manifest" "${BASE_URL}/.well-known/acp.json" "json"
check_endpoint "UCP Protocol Manifest" "${BASE_URL}/.well-known/ucp" "json"
check_endpoint "OpenAPI Specification (MPP)" "${BASE_URL}/openapi.json" "json"

# 7. DNS-AID via Cloudflare DoH
echo -e "\n${BOLD}[7/7] DNS-AID Resolution (_agents.${DOMAIN})${NC}"
DOH_RESP=$(curl -s -H "accept: application/dns-json" "https://cloudflare-dns.com/dns-query?name=_index._agents.${DOMAIN}&type=HTTPS&do=1" || true)
if echo "$DOH_RESP" | grep -qi '"AD":true'; then
  pass "DNS-AID record found with DNSSEC Authenticated Data (AD: true)"
elif echo "$DOH_RESP" | grep -qi '"Answer"'; then
  warn "DNS-AID record found but DNSSEC is not authenticated (AD: false)"
else
  info "No DNS-AID record found under _agents.${DOMAIN} (optional if not hosting DNS agent endpoints)"
fi

echo -e "\n${BOLD}======================================================================${NC}"
echo -e "${GREEN}Pre-flight verification scan completed!${NC}"
echo -e "To run the authoritative remote scan:"
echo -e "  ${CYAN}curl -X POST https://isitagentready.com/api/scan -H 'Content-Type: application/json' -d '{\"url\": \"${BASE_URL}\"}' | jq .${NC}"
echo -e "${BOLD}======================================================================${NC}\n"
