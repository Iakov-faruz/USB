#!/usr/bin/env bash
# scripts/lib/config-reader.sh
# USBGuard Approval Manager — Secure Configuration Reader
# Implements load_config() per SRS SEC-01, SEC-02. Reads KEY=VALUE without source/eval.
set -euo pipefail

readonly CONFIG_READER_VERSION="1.0.0"

declare -rA ALLOWED_KEYS=(
  ["TEMP_TTL_SECONDS"]="3600|60|2592000"
  ["MIN_REASONABLE_EPOCH"]="1577836800||"
  ["MAX_CLOCK_JUMP_SECONDS"]="3600|1|86400"
)

declare -gA CONFIG_VALUES=()

load_config() {
  local file_path="$1"
  if [[ -z "$file_path" ]]; then
    echo "config-reader: ERROR: load_config requires a file path argument" >&2
    return 2
  fi
  if [[ ! -f "$file_path" ]]; then
    echo "config-reader: ERROR: config file not found: $file_path" >&2
    return 2
  fi
  if [[ ! -r "$file_path" ]]; then
    echo "config-reader: ERROR: config file not readable: $file_path" >&2
    return 2
  fi
  CONFIG_VALUES=()
  local line_number=0
  local raw_line key value