#!/usr/bin/env bash
# Resolve the raw git SHA used for Sentry release secret patching.
#
# Inputs (env):
#   ENABLE_SENTRY       - "true" to enable (anything else = disabled / no-op success)
#   SENTRY_SECRET_NAME  - required when enabled
#   SENTRY_RELEASE_SHA  - optional explicit override (raw SHA)
#   APP_VERSION         - deployed artifact tag, typically Build.<40-hex>
#
# Outputs (stdout):
#   When disabled: prints nothing, exits 0
#   When enabled:  prints the raw SHA, exits 0
#   On error:      message on stderr, exits 1
#
# Also writes sha=<value> to $GITHUB_OUTPUT when that file is set (GHA).
set -euo pipefail

ENABLE_SENTRY="${ENABLE_SENTRY:-false}"
SENTRY_SECRET_NAME="${SENTRY_SECRET_NAME:-}"
SENTRY_RELEASE_SHA="${SENTRY_RELEASE_SHA:-}"
APP_VERSION="${APP_VERSION:-}"

if [[ "${ENABLE_SENTRY}" != "true" ]]; then
  exit 0
fi

if [[ -z "${SENTRY_SECRET_NAME}" ]]; then
  echo "error: sentry-secret-name is required when enable-sentry is true" >&2
  exit 1
fi

sha=""
if [[ -n "${SENTRY_RELEASE_SHA}" ]]; then
  sha="${SENTRY_RELEASE_SHA}"
elif [[ "${APP_VERSION}" =~ ^Build\.([0-9a-f]{40})$ ]]; then
  sha="${BASH_REMATCH[1]}"
else
  echo "error: cannot derive Sentry release SHA from app-version '${APP_VERSION}' (expected Build.<40-hex> or set sentry-release-sha)" >&2
  exit 1
fi

if [[ -z "${sha}" ]]; then
  echo "error: resolved Sentry release SHA is empty" >&2
  exit 1
fi

echo "Resolved Sentry release SHA from app-version (or override)"
echo "${sha}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "sha=${sha}" >>"${GITHUB_OUTPUT}"
fi
