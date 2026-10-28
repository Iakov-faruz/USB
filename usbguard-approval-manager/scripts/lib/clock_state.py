#!/usr/bin/env python3
"""Validate clock-state.json and apply the SRS v4.5 clock-trust rules."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import NoReturn, TypedDict

SCHEMA_VERSION = 1
STATE_KEYS = {
    "schema_version",
    "last_trusted_epoch",
    "sync_provider",
    "sync_status",
    "boot_id",
    "last_trusted_boottime_seconds",
}
PROVIDER_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$")
BOOT_ID_PATTERN = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-"
    r"[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)


class ClockStateError(Exception):
    """Clock evidence or persisted state is invalid or unavailable."""


class ClockState(TypedDict):
    schema_version: int
    last_trusted_epoch: int
    sync_provider: str
    sync_status: str
    boot_id: str
    last_trusted_boottime_seconds: int


def _reject_json_constant(value: str) -> NoReturn:
    raise ValueError(f"invalid JSON constant: {value}")


def _reject_duplicate_keys(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result: dict[str, object] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def _read_state(path: Path) -> ClockState | None:
    try:
        raw = path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return None
    except OSError as error:
        raise ClockStateError("clock state is unavailable") from error

    try:
        state = json.loads(
            raw,
            parse_constant=_reject_json_constant,
            object_pairs_hook=_reject_duplicate_keys,
        )
    except (json.JSONDecodeError, UnicodeDecodeError, ValueError):
        return None

    if not isinstance(state, dict) or set(state) != STATE_KEYS:
        return None
    schema_version = state["schema_version"]
    epoch = state["last_trusted_epoch"]
    boottime = state["last_trusted_boottime_seconds"]
    provider = state["sync_provider"]
    sync_status = state["sync_status"]
    boot_id = state["boot_id"]
    if type(schema_version) is not int or schema_version != SCHEMA_VERSION:
        return None
    if type(epoch) is not int or epoch <= 0:
        return None
    if type(boottime) is not int:
        return None
    if boottime < 0:
        return None
    if not isinstance(provider, str) or not PROVIDER_PATTERN.fullmatch(provider):
        return None
    if sync_status != "synchronized":
        return None
    if not isinstance(boot_id, str) or not BOOT_ID_PATTERN.fullmatch(boot_id):
        return None
    return {
        "schema_version": schema_version,
        "last_trusted_epoch": epoch,
        "sync_provider": provider,
        "sync_status": sync_status,
        "boot_id": boot_id,
        "last_trusted_boottime_seconds": boottime,
    }


def _make_state(
    epoch: int,
    provider: str,
    boot_id: str,
    boottime_seconds: int,
) -> ClockState:
    return {
        "schema_version": SCHEMA_VERSION,
        "last_trusted_epoch": epoch,
        "sync_provider": provider,
        "sync_status": "synchronized",
        "boot_id": boot_id,
        "last_trusted_boottime_seconds": boottime_seconds,
    }


def _atomic_write(path: Path, state: dict[str, object]) -> None:
    writer_path = Path(__file__).with_name("atomic-write.py")
    try:
        result = subprocess.run(
            [
                sys.executable,
                str(writer_path),
                "--file",
                str(path),
                "--data",
                json.dumps(state, separators=(",", ":"), allow_nan=False),
            ],
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
    except OSError as error:
        raise ClockStateError("atomic clock-state writer could not be started") from error
    if result.returncode != 0:
        raise ClockStateError("atomic clock-state write failed")


def evaluate_clock(
    path: Path,
    *,
    epoch: int,
    provider: str,
    sync_status: str,
    boot_id: str,
    boottime_seconds: int,
    min_reasonable_epoch: int,
    max_clock_jump_seconds: int,
    has_non_expired_records: bool,
) -> str:
    if type(epoch) is not int or epoch <= min_reasonable_epoch:
        return "untrusted_clock"
    if type(boottime_seconds) is not int or boottime_seconds < 0:
        return "untrusted_clock"
    if not PROVIDER_PATTERN.fullmatch(provider):
        return "untrusted_clock"
    if sync_status != "synchronized":
        return "untrusted_clock"
    if not BOOT_ID_PATTERN.fullmatch(boot_id):
        return "untrusted_clock"
    if type(min_reasonable_epoch) is not int or min_reasonable_epoch < 0:
        return "untrusted_clock"
    if type(max_clock_jump_seconds) is not int or max_clock_jump_seconds < 1:
        return "untrusted_clock"

    previous = _read_state(path)
    if previous is None:
        if has_non_expired_records:
            return "recovery_required"
        _atomic_write(path, _make_state(epoch, provider, boot_id, boottime_seconds))
        return "baseline_initialized"

    if previous["sync_provider"] != provider:
        return "untrusted_clock"

    previous_epoch = previous["last_trusted_epoch"]
    previous_boottime = previous["last_trusted_boottime_seconds"]
    if epoch < previous_epoch:
        return "untrusted_clock"

    if previous["boot_id"] == boot_id:
        if boottime_seconds < previous_boottime:
            return "untrusted_clock"
        epoch_delta = epoch - previous_epoch
        boottime_delta = boottime_seconds - previous_boottime
        if abs(epoch_delta - boottime_delta) > max_clock_jump_seconds:
            return "untrusted_clock"
        outcome = "trusted_same_boot"
    else:
        outcome = "trusted_after_reboot"

    _atomic_write(path, _make_state(epoch, provider, boot_id, boottime_seconds))
    return outcome


def _parse_args(arguments: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--state", required=True, type=Path)
    parser.add_argument("--epoch", required=True, type=int)
    parser.add_argument("--provider", required=True)
    parser.add_argument("--sync-status", required=True)
    parser.add_argument("--boot-id", required=True)
    parser.add_argument("--boottime-seconds", required=True, type=int)
    parser.add_argument("--min-reasonable-epoch", required=True, type=int)
    parser.add_argument("--max-clock-jump-seconds", required=True, type=int)
    parser.add_argument(
        "--has-non-expired-records", choices=("yes", "no"), required=True
    )
    return parser.parse_args(arguments)


def main(arguments: list[str] | None = None) -> int:
    options = _parse_args(sys.argv[1:] if arguments is None else arguments)
    try:
        outcome = evaluate_clock(
            options.state,
            epoch=options.epoch,
            provider=options.provider,
            sync_status=options.sync_status,
            boot_id=options.boot_id,
            boottime_seconds=options.boottime_seconds,
            min_reasonable_epoch=options.min_reasonable_epoch,
            max_clock_jump_seconds=options.max_clock_jump_seconds,
            has_non_expired_records=options.has_non_expired_records == "yes",
        )
    except ClockStateError as error:
        print(f"clock-state: ERROR: {error}", file=sys.stderr)
        return 1

    print(outcome)
    return 0 if outcome.startswith("trusted_") or outcome == "baseline_initialized" else 9


if __name__ == "__main__":
    raise SystemExit(main())
