#!/usr/bin/env bash

# Read-only production catalog diagnostic. It never prints credentials.
set -u

base_url="${CATALOG_BASE_URL:-https://catalog.smartmovie.app}"
base_url="${base_url%/}"
endpoint="$base_url/v2/capabilities"

printf 'SmartMovie catalog live check\nEndpoint: %s\n' "$endpoint"

if ! command -v curl >/dev/null 2>&1; then
  printf 'FAIL curl is required\n'
  exit 1
fi

host="$(printf '%s' "$base_url" | sed -E 's#^[a-zA-Z]+://([^/:]+).*$#\1#')"
if command -v dscacheutil >/dev/null 2>&1; then
  if dscacheutil -q host -a name "$host" | grep -q '^ip_address:'; then
    printf 'PASS DNS resolves %s\n' "$host"
  else
    printf 'FAIL DNS does not resolve %s\n' "$host"
    exit 2
  fi
else
  printf 'INFO DNS resolver check unavailable; curl will verify connectivity\n'
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
status="$(curl --silent --show-error --location --connect-timeout 5 --max-time 15 \
  --output "$tmp" --write-out '%{http_code}' "$endpoint" 2>/dev/null || true)"

case "$status" in
  2*)
    if grep -q '"api_version"' "$tmp" && grep -q '"catalog"' "$tmp"; then
      printf 'PASS Worker responded with capabilities (%s)\n' "$status"
      exit 0
    fi
    printf 'FAIL Worker returned non-canonical capabilities (%s)\n' "$status"
    exit 3
    ;;
  401|403)
    printf 'FAIL Worker is reachable but rejected the public request (%s)\n' "$status"
    exit 4
    ;;
  000)
    printf 'FAIL Worker could not be reached (network/TLS/DNS)\n'
    exit 5
    ;;
  *)
    printf 'FAIL Worker responded with HTTP %s\n' "$status"
    exit 6
    ;;
esac
