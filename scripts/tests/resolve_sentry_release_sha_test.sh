#!/usr/bin/env bash
# Tests for resolve-sentry-release-sha.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVE_SH="${SCRIPT_DIR}/../resolve-sentry-release-sha.sh"

fail=0
assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "${expected}" != "${actual}" ]]; then
    echo "FAIL: ${name}: expected '${expected}', got '${actual}'" >&2
    fail=1
  else
    echo "PASS: ${name}"
  fi
}

assert_exit() {
  local name="$1" expected_code="$2"
  shift 2
  set +e
  "$@" >/dev/null 2>&1
  local code=$?
  set -e
  if [[ "${code}" -ne "${expected_code}" ]]; then
    echo "FAIL: ${name}: expected exit ${expected_code}, got ${code}" >&2
    fail=1
  else
    echo "PASS: ${name}"
  fi
}

SHA40='abcdef0123456789abcdef0123456789abcdef01'

# Disabled: success, no output
out="$(ENABLE_SENTRY=false SENTRY_SECRET_NAME='' APP_VERSION=Build.${SHA40} bash "${RESOLVE_SH}" || true)"
assert_eq "disabled produces no sha" "" "${out}"
assert_exit "disabled exits 0" 0 \
  env ENABLE_SENTRY=false APP_VERSION=Build.${SHA40} bash "${RESOLVE_SH}"

# Enabled without secret name fails
assert_exit "enabled requires secret name" 1 \
  env ENABLE_SENTRY=true SENTRY_SECRET_NAME='' APP_VERSION=Build.${SHA40} bash "${RESOLVE_SH}"

# Derive from Build.<sha>
out="$(ENABLE_SENTRY=true SENTRY_SECRET_NAME=my-sentry APP_VERSION=Build.${SHA40} bash "${RESOLVE_SH}")"
# Last non-empty line is the sha (script also prints a status line)
sha="$(echo "${out}" | tail -n1)"
assert_eq "derive from app-version" "${SHA40}" "${sha}"

# Override wins
out="$(ENABLE_SENTRY=true SENTRY_SECRET_NAME=my-sentry SENTRY_RELEASE_SHA=deadbeef \
  APP_VERSION=Build.${SHA40} bash "${RESOLVE_SH}")"
sha="$(echo "${out}" | tail -n1)"
assert_eq "override sentry-release-sha" "deadbeef" "${sha}"

# Invalid app-version fails
assert_exit "invalid app-version fails" 1 \
  env ENABLE_SENTRY=true SENTRY_SECRET_NAME=my-sentry APP_VERSION=latest bash "${RESOLVE_SH}"

assert_exit "short sha Build tag fails" 1 \
  env ENABLE_SENTRY=true SENTRY_SECRET_NAME=my-sentry APP_VERSION=Build.abc bash "${RESOLVE_SH}"

# GITHUB_OUTPUT write
gout="$(mktemp)"
ENABLE_SENTRY=true SENTRY_SECRET_NAME=my-sentry APP_VERSION=Build.${SHA40} \
  GITHUB_OUTPUT="${gout}" bash "${RESOLVE_SH}" >/dev/null
assert_eq "writes GITHUB_OUTPUT" "sha=${SHA40}" "$(cat "${gout}")"
rm -f "${gout}"

if [[ "${fail}" -ne 0 ]]; then
  echo "Some resolve-sentry-release-sha tests failed" >&2
  exit 1
fi
echo "All resolve-sentry-release-sha tests passed"
