#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_ROOT/scripts/lib/config-reader.sh"
source "$PROJECT_ROOT/scripts/lib/time-guards.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

MIN_REASONABLE_EPOCH=1577836800
MAX_CLOCK_JUMP_SECONDS=3600
CONFIG_VALUES[MIN_REASONABLE_EPOCH]="$MIN_REASONABLE_EPOCH"
CONFIG_VALUES[MAX_CLOCK_JUMP_SECONDS]="$MAX_CLOCK_JUMP_SECONDS"

TEST_EPOCH=1700000000
TEST_BOOT_ID="11111111-2222-3333-4444-555555555555"
TEST_BOOTTIME=100
TEST_SYNC_STATUS="synchronized"
TEST_PROVIDER="test-verified-provider"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

ACTUAL_EPOCH="$(get_current_epoch)" ||
  fail "system Epoch reader did not return a value"
[[ "$ACTUAL_EPOCH" =~ ^[0-9]+$ ]] ||
  fail "system Epoch reader returned a non-integer"

get_current_epoch() {
  printf '%s\n' "$TEST_EPOCH"
}

clock_read_boot_id() {
  printf '%s\n' "$TEST_BOOT_ID"
}

clock_read_boottime_seconds() {
  printf '%s\n' "$TEST_BOOTTIME"
}

if is_clock_reasonable 1700000000; then
  pass "Epoch above MIN_REASONABLE_EPOCH is reasonable"
else
  fail "reasonable Epoch was rejected"
fi

for invalid_epoch in "" -1 0 1577836800 invalid; do
  if is_clock_reasonable "$invalid_epoch" 2>/dev/null; then
    fail "invalid or not-later-than-minimum Epoch was accepted: $invalid_epoch"
  fi
done
pass "negative, missing-range, and malformed Epochs are rejected"

if detect_clock_jump "$TEST_DIR/no-provider.json" no; then
  fail "unverified default sync provider was accepted"
else
  [[ "$?" -eq 9 ]] || fail "unverified provider returned an unexpected status"
fi
[[ ! -e "$TEST_DIR/no-provider.json" ]] ||
  fail "unverified provider created a clock baseline"
pass "unverified sync provider fails closed without writing state"

clock_sync_evidence() {
  CLOCK_SYNC_PROVIDER="$TEST_PROVIDER"
  CLOCK_SYNC_STATUS="$TEST_SYNC_STATUS"
  return 0
}

TEST_SYNC_STATUS="unsynchronized"
if detect_clock_jump "$TEST_DIR/unsynchronized.json" no; then
  fail "unsynchronized provider result was accepted"
else
  [[ "$?" -eq 9 ]] || fail "unsynchronized result returned an unexpected status"
fi
[[ ! -e "$TEST_DIR/unsynchronized.json" ]] ||
  fail "unsynchronized result created a clock baseline"
pass "negative synchronization evidence is rejected"
TEST_SYNC_STATUS="synchronized"

STATE_PATH="$TEST_DIR/clock-state.json"
detect_clock_jump "$STATE_PATH" no ||
  fail "positive provider evidence did not initialize a baseline"
[[ "$CLOCK_TRUST_STATUS" == "baseline_initialized" ]] ||
  fail "initial baseline status was not reported"
pass "missing state initializes only with sync evidence and no live records"

TEST_PROVIDER="different-provider"
TEST_EPOCH=1700000005
TEST_BOOTTIME=105
if detect_clock_jump "$STATE_PATH" no; then
  fail "clock-state provider change was accepted"
else
  [[ "$?" -eq 9 ]] || fail "provider change returned an unexpected status"
fi
TEST_PROVIDER="test-verified-provider"
pass "provider change is rejected without replacing the trusted baseline"

TEST_EPOCH=1700000010
TEST_BOOTTIME=110
detect_clock_jump "$STATE_PATH" no ||
  fail "same-boot sample within the jump threshold was rejected"
[[ "$CLOCK_TRUST_STATUS" == "trusted_same_boot" ]] ||
  fail "same-boot trusted status was not reported"
pass "same-boot Epoch and boottime deltas within threshold are trusted"

TEST_EPOCH=1700005010
TEST_BOOTTIME=111
if detect_clock_jump "$STATE_PATH" no; then
  fail "same-boot clock jump over threshold was accepted"
else
  [[ "$?" -eq 9 ]] || fail "clock jump returned an unexpected status"
fi
[[ "$CLOCK_TRUST_STATUS" == "untrusted_clock" ]] ||
  fail "same-boot clock jump did not report untrusted status"
pass "same-boot jump over threshold is untrusted"

TEST_BOOT_ID="aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
TEST_EPOCH=1701000000
TEST_BOOTTIME=5
detect_clock_jump "$STATE_PATH" no ||
  fail "long powered-off interval after synchronized reboot was rejected"
[[ "$CLOCK_TRUST_STATUS" == "trusted_after_reboot" ]] ||
  fail "reboot trust status was not reported"
pass "synchronized reboot accepts a long unknown powered-off interval"

TEST_EPOCH=1700999999
TEST_BOOTTIME=10
if detect_clock_jump "$STATE_PATH" no; then
  fail "backward Epoch after reboot was accepted"
else
  [[ "$?" -eq 9 ]] || fail "backward Epoch returned an unexpected status"
fi
pass "backward Epoch after reboot is untrusted"

MISSING_FIELD="$TEST_DIR/missing-last-trusted-epoch.json"
printf '%s\n' \
  '{"schema_version":1,"sync_provider":"test-verified-provider","sync_status":"synchronized","boot_id":"aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee","last_trusted_boottime_seconds":5}' \
  > "$MISSING_FIELD"
TEST_EPOCH=1701000010
TEST_BOOTTIME=15
if detect_clock_jump "$MISSING_FIELD" yes; then
  fail "state missing last_trusted_epoch was accepted with live records"
else
  [[ "$?" -eq 9 ]] || fail "missing baseline returned an unexpected status"
fi
[[ "$CLOCK_TRUST_STATUS" == "recovery_required" ]] ||
  fail "missing baseline did not require recovery"
pass "missing trusted baseline with non-expired records requires recovery"

if detect_clock_jump "$MISSING_FIELD" no; then
  [[ "$CLOCK_TRUST_STATUS" == "baseline_initialized" ]] ||
    fail "missing-field state did not initialize a fresh baseline"
else
  fail "missing-field state without live records was not recoverable"
fi
pass "corrupt state without live records can establish a synchronized baseline"

CORRUPT_STATE="$TEST_DIR/corrupt.json"
printf '{not-json\n' > "$CORRUPT_STATE"
if detect_clock_jump "$CORRUPT_STATE" yes; then
  fail "corrupt state with live records was accepted"
else
  [[ "$?" -eq 9 ]] || fail "corrupt state returned an unexpected status"
fi
[[ "$CLOCK_TRUST_STATUS" == "recovery_required" ]] ||
  fail "corrupt state did not require recovery"
pass "corrupt state with live records requires recovery"

MISSING_STATE="$TEST_DIR/missing-state.json"
if detect_clock_jump "$MISSING_STATE" yes; then
  fail "missing state with live records was accepted"
else
  [[ "$?" -eq 9 ]] || fail "missing state returned an unexpected status"
fi
[[ "$CLOCK_TRUST_STATUS" == "recovery_required" ]] ||
  fail "missing state did not require recovery"
pass "missing state with live records requires recovery"

TEST_EPOCH=-1
if detect_clock_jump "$TEST_DIR/negative-epoch.json" no; then
  fail "negative current Epoch was trusted"
else
  [[ "$?" -eq 9 ]] || fail "negative Epoch returned an unexpected status"
fi
pass "negative current Epoch is rejected"

TEST_EPOCH=1701000010
TEST_BOOTTIME=-1
if detect_clock_jump "$TEST_DIR/negative-boottime.json" no; then
  fail "negative CLOCK_BOOTTIME sample was trusted"
else
  [[ "$?" -eq 9 ]] || fail "negative CLOCK_BOOTTIME returned an unexpected status"
fi
pass "negative CLOCK_BOOTTIME sample is rejected"

printf 'All time-guard checks passed\n'
