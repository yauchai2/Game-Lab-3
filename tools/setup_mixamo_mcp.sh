#!/usr/bin/env bash
# Register the official Playwright MCP for a local, already signed-in browser.
# Run on the user's machine; this does not connect a cloud task to that machine.
set -euo pipefail
TASK_MCP_NAME="playwright-mixamo"
TASK_MCP_VERSION="0.0.85"
TASK_MCP_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/game-lab-3/mixamo-downloads"
TASK_MCP_COMMAND=(codex mcp add "$TASK_MCP_NAME" -- npx --yes "@playwright/mcp@$TASK_MCP_VERSION" --extension --output-dir "$TASK_MCP_DATA" --codegen none --redact-url-params code,access_token,id_token,refresh_token)
if [[ "${1:-}" == "--print" ]]; then
  printf '%q ' "${TASK_MCP_COMMAND[@]}"
  printf '\n'
  exit 0
fi
if [[ $# -gt 0 ]]; then
  printf 'Usage: %s [--print]\n' "$0" >&2
  exit 2
fi
for TASK_MCP_DEPENDENCY in codex node npx; do
  if ! command -v "$TASK_MCP_DEPENDENCY" >/dev/null 2>&1; then
    printf 'Missing prerequisite: %s. Install it before running this helper.\n' "$TASK_MCP_DEPENDENCY" >&2
    exit 1
  fi
done
if codex mcp get "$TASK_MCP_NAME" >/dev/null 2>&1; then
  printf 'MCP server %s already exists; leaving its configuration unchanged.\n' "$TASK_MCP_NAME"
  exit 0
fi
umask 077
mkdir -p "$TASK_MCP_DATA"
chmod 700 "$TASK_MCP_DATA"
"${TASK_MCP_COMMAND[@]}"
printf '\nRegistered %s. Next install the official Playwright Extension:\n%s\n' "$TASK_MCP_NAME" 'https://playwright.dev/mcp/configuration/browser-extension'
printf 'Reload the MCP client, connect the intended browser tab, and sign in to Mixamo yourself.\n'
printf 'Registration alone does not confirm a browser, Adobe login, or successful download.\n'
printf 'Private downloads: %s\n' "$TASK_MCP_DATA"
