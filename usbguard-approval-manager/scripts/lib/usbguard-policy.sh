#!/usr/bin/env bash
# Read-only USBGuard queries. Write operations stay unavailable until G-01.

if [[ -z "${USBAM_USB_POLICY_LOADED+x}" ]]; then
  declare -g USBAM_POLICY_STDOUT=""
  declare -g USBAM_POLICY_STDERR=""
  declare -g USBAM_POLICY_ERROR_CODE=""
  declare -g USBAM_POLICY_VERSION=""
  declare -g USBAM_DAEMON_CONFIG_PATH="/etc/usbguard/usbguard-daemon.conf"
  declare -ga USBAM_BLOCKED_DEVICES=()
  declare -ga USBAM_ACTIVE_RULES=()
  # Maps each configured RuleFile/RuleFolder key to its validated path.
  declare -gA USBAM_PERSISTENT_POLICY_PATHS=()
  declare -g USBAM_DAEMON_STATUS="unknown"
  declare -g USBAM_IPC_STATUS="unknown"
  declare -gr USBAM_USB_POLICY_LOADED=1
fi

usbguard_policy_error() {
  printf 'usbguard-policy: ERROR: %s\n' "$1" >&2
}

usbguard_policy_timeout() {
  if declare -F get_config >/dev/null 2>&1; then
    get_config IPC_TIMEOUT_SECONDS
  else
    printf '%s\n' "${IPC_TIMEOUT_SECONDS:-5}"
  fi
}

usbguard_policy_run_readonly() {
  local timeout_seconds temp_dir status
  USBAM_POLICY_STDOUT=""
  USBAM_POLICY_STDERR=""
  USBAM_POLICY_ERROR_CODE=""

  if (( $# == 0 )); then
    usbguard_policy_error "a read-only USBGuard subcommand is required"
    USBAM_POLICY_ERROR_CODE="invalid_arguments"
    return 1
  fi
  case "$1:$#" in
    --version:1|list-rules:1|list-devices:1)
      ;;
    list-devices:2)
      if [[ "$2" != "--blocked" ]]; then
        usbguard_policy_error "unsupported read-only USBGuard query"
        USBAM_POLICY_ERROR_CODE="invalid_command"
        return 1
      fi
      ;;
    *)
      usbguard_policy_error "unsupported read-only USBGuard query"
      USBAM_POLICY_ERROR_CODE="invalid_command"
      return 1
      ;;
  esac
  if ! timeout_seconds="$(usbguard_policy_timeout)" ||
    [[ ! "$timeout_seconds" =~ ^[1-9][0-9]*$ ]]; then
    usbguard_policy_error "IPC_TIMEOUT_SECONDS must be a positive integer"
    USBAM_POLICY_ERROR_CODE="invalid_timeout"
    return 1
  fi
  if ! command -v timeout >/dev/null 2>&1; then
    usbguard_policy_error "the timeout utility is unavailable"
    USBAM_POLICY_ERROR_CODE="timeout_unavailable"
    return 1
  fi
  if ! command -v usbguard >/dev/null 2>&1; then
    usbguard_policy_error "the usbguard CLI is unavailable"
    USBAM_POLICY_ERROR_CODE="usbguard_unavailable"
    return 1
  fi
  if ! temp_dir="$(mktemp -d)"; then
    usbguard_policy_error "unable to create a private command-output directory"
    USBAM_POLICY_ERROR_CODE="temporary_storage_unavailable"
    return 1
  fi

  if timeout --foreground --signal=TERM --kill-after=1s \
    "${timeout_seconds}s" usbguard "$@" \
    > "$temp_dir/stdout" 2> "$temp_dir/stderr"; then
    status=0
  else
    status=$?
  fi

  USBAM_POLICY_STDOUT="$(<"$temp_dir/stdout")"
  USBAM_POLICY_STDERR="$(<"$temp_dir/stderr")"
  if ! rm -rf -- "$temp_dir"; then
    usbguard_policy_error "unable to remove private command-output files"
    USBAM_POLICY_ERROR_CODE="temporary_storage_cleanup_failed"
    return 1
  fi

  if (( status == 0 )); then
    return 0
  fi
  if (( status == 124 || status == 137 )); then
    USBAM_POLICY_ERROR_CODE="command_timeout"
    usbguard_policy_error "USBGuard query exceeded ${timeout_seconds}s"
    return 1
  fi
  USBAM_POLICY_ERROR_CODE="command_failed"
  usbguard_policy_error "USBGuard query failed with exit status $status"
  return 1
}

usbguard_policy_parse_records() {
  local output="$1"
  local -n records_ref="$2"
  local line
  local -a parsed=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    if [[ ! "$line" =~ ^[[:space:]]*[0-9]+: ]]; then
      usbguard_policy_error "USBGuard returned an unrecognized record"
      USBAM_POLICY_ERROR_CODE="invalid_command_output"
      return 1
    fi
    parsed+=("$line")
  done <<< "$output"

  records_ref=("${parsed[@]}")
}

get_usbguard_version() {
  USBAM_POLICY_VERSION=""
  if (( $# != 0 )); then
    usbguard_policy_error "get_usbguard_version accepts no arguments"
    return 1
  fi
  if ! usbguard_policy_run_readonly --version; then
    return 1
  fi
  if [[ -z "$USBAM_POLICY_STDOUT" ]]; then
    usbguard_policy_error "USBGuard returned an empty version"
    USBAM_POLICY_ERROR_CODE="empty_version"
    return 1
  fi
  USBAM_POLICY_VERSION="$USBAM_POLICY_STDOUT"
  printf '%s\n' "$USBAM_POLICY_VERSION"
}

list_blocked_devices() {
  if (( $# != 0 )); then
    usbguard_policy_error "list_blocked_devices accepts no arguments"
    return 1
  fi
  USBAM_BLOCKED_DEVICES=()
  if ! usbguard_policy_run_readonly list-devices --blocked; then
    return 1
  fi
  usbguard_policy_parse_records "$USBAM_POLICY_STDOUT" USBAM_BLOCKED_DEVICES
}

list_active_rules() {
  if (( $# != 0 )); then
    usbguard_policy_error "list_active_rules accepts no arguments"
    return 1
  fi
  USBAM_ACTIVE_RULES=()
  if ! usbguard_policy_run_readonly list-rules; then
    return 1
  fi
  usbguard_policy_parse_records "$USBAM_POLICY_STDOUT" USBAM_ACTIVE_RULES
}

get_active_rules() {
  list_active_rules "$@"
}

# Populates the source map only after every configured path is validated.
get_persistent_policy_paths() {
  local raw_line line key value line_number
  local rule_file=""
  local rule_folder=""

  USBAM_PERSISTENT_POLICY_PATHS=()
  USBAM_POLICY_ERROR_CODE=""
  if (( $# != 0 )); then
    usbguard_policy_error "get_persistent_policy_paths accepts no arguments"
    USBAM_POLICY_ERROR_CODE="invalid_arguments"
    return 1
  fi
  if [[ -L "$USBAM_DAEMON_CONFIG_PATH" ||
    ! -f "$USBAM_DAEMON_CONFIG_PATH" ||
    ! -r "$USBAM_DAEMON_CONFIG_PATH" ]]; then
    usbguard_policy_error "USBGuard daemon configuration is unavailable or unsafe"
    USBAM_POLICY_ERROR_CODE="daemon_config_unavailable"
    return 1
  fi

  line_number=0
  while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
    line_number=$((line_number + 1))
    if [[ "$raw_line" =~ [[:cntrl:]] ]]; then
      usbguard_policy_error "control character in daemon configuration line $line_number"
      USBAM_POLICY_ERROR_CODE="invalid_daemon_config"
      return 1
    fi
    line="${raw_line#"${raw_line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    if [[ ! "$line" =~ ^(RuleFile|RuleFolder)[[:space:]]*=[[:space:]]*(.*)$ ]]; then
      continue
    fi

    key="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    if [[ -z "$value" || "$value" != /* ||
      "$value" == *"/../"* || "$value" == */.. ]]; then
      usbguard_policy_error "invalid $key path in daemon configuration"
      USBAM_POLICY_ERROR_CODE="invalid_policy_path"
      return 1
    fi
    if [[ "$key" == "RuleFile" ]]; then
      if [[ -n "$rule_file" ]]; then
        usbguard_policy_error "duplicate RuleFile in daemon configuration"
        USBAM_POLICY_ERROR_CODE="ambiguous_policy_source"
        return 1
      fi
      rule_file="$value"
    else
      if [[ -n "$rule_folder" ]]; then
        usbguard_policy_error "duplicate RuleFolder in daemon configuration"
        USBAM_POLICY_ERROR_CODE="ambiguous_policy_source"
        return 1
      fi
      rule_folder="$value"
    fi
  done < "$USBAM_DAEMON_CONFIG_PATH"

  if [[ -z "$rule_file" && -z "$rule_folder" ]]; then
    usbguard_policy_error "daemon configuration does not identify a persistent policy source"
    USBAM_POLICY_ERROR_CODE="policy_source_unconfigured"
    return 1
  fi

  if [[ -n "$rule_file" ]]; then
    if [[ -L "$rule_file" || ! -f "$rule_file" || ! -r "$rule_file" ]]; then
      usbguard_policy_error "configured RuleFile is missing, unsafe, or unreadable"
      USBAM_POLICY_ERROR_CODE="policy_source_unavailable"
      return 1
    fi
    USBAM_PERSISTENT_POLICY_PATHS[RuleFile]="$rule_file"
  fi
  if [[ -n "$rule_folder" ]] &&
    [[ -L "$rule_folder" || ! -d "$rule_folder" ||
      ! -r "$rule_folder" || ! -x "$rule_folder" ]]; then
    usbguard_policy_error "configured RuleFolder is missing, unsafe, or unreadable"
    USBAM_POLICY_ERROR_CODE="policy_source_unavailable"
    USBAM_PERSISTENT_POLICY_PATHS=()
    return 1
  fi
  if [[ -n "$rule_folder" ]]; then
    USBAM_PERSISTENT_POLICY_PATHS[RuleFolder]="$rule_folder"
  fi
  return 0
}

check_daemon_status() {
  local timeout_seconds status
  USBAM_DAEMON_STATUS="unknown"
  USBAM_IPC_STATUS="unknown"
  USBAM_POLICY_ERROR_CODE=""

  if ! timeout_seconds="$(usbguard_policy_timeout)" ||
    [[ ! "$timeout_seconds" =~ ^[1-9][0-9]*$ ]]; then
    usbguard_policy_error "IPC_TIMEOUT_SECONDS must be a positive integer"
    USBAM_POLICY_ERROR_CODE="invalid_timeout"
    return 1
  fi
  if ! command -v timeout >/dev/null 2>&1 ||
    ! command -v pgrep >/dev/null 2>&1; then
    usbguard_policy_error "timeout or pgrep utility is unavailable"
    USBAM_POLICY_ERROR_CODE="status_utility_unavailable"
    return 1
  fi

  if timeout --foreground --signal=TERM --kill-after=1s \
    "${timeout_seconds}s" pgrep -x usbguard-daemon >/dev/null 2>&1; then
    USBAM_DAEMON_STATUS="running"
  else
    status=$?
    if (( status == 1 )); then
      USBAM_DAEMON_STATUS="stopped"
      USBAM_IPC_STATUS="unavailable"
      return 9
    fi
    if (( status == 124 || status == 137 )); then
      USBAM_POLICY_ERROR_CODE="daemon_check_timeout"
    else
      USBAM_POLICY_ERROR_CODE="daemon_check_failed"
    fi
    usbguard_policy_error "unable to determine USBGuard daemon status"
    return 1
  fi

  if usbguard_policy_run_readonly list-devices; then
    USBAM_IPC_STATUS="connected"
    return 0
  fi
  USBAM_IPC_STATUS="unavailable"
  return 9
}
