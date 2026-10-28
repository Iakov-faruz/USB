# G-01 Lab Preflight Report

**Checked:** 2026-10-28 20:45 (UTC+02:00)  
**Overall G-01 status:** `UNVERIFIED`  
**Scope:** Read-only VM inspection and unit tests. No USBGuard policy or service
changes were made.

## Environment observations

| Check | Observation | Result |
|---|---|---|
| VM identity | Hostname `vbox`, user `yf`, Kali Linux x86_64, kernel `7.0.12+kali-amd64` | Recorded |
| USBGuard CLI | `/usr/bin/usbguard`, version `1.1.4` | Installed |
| USBGuard service | `inactive`; `systemctl is-enabled` reports `disabled` | Not ready for IPC integration |
| Read-only IPC query | `usbguard list-devices` returned `IPC connect: service=usbguard: Connection refused`, exit status `1` | IPC unavailable |
| Daemon configuration | `/etc/usbguard/usbguard-daemon.conf` is `root:root`, mode `0600`; it was inspected read-only with `sudo`. | Read |
| Persistent policy settings | `RuleFile=/etc/usbguard/rules.conf` and `RuleFolder=/etc/usbguard/rules.d/` are both configured. USBGuard 1.1.4's local man page permits using both together. | Both sources identified |
| Rule file | `/etc/usbguard/rules.conf` is `root:root`, mode `0600`, and contains zero active rule lines. | Read-only observation |
| Rule folder | `/etc/usbguard/rules.d/` exists and contains no files. | Read-only observation |
| Service unit | Journal entries include warnings about unsupported `ConditionKernelCommandLine` and `ConditionPathExists` keys. Their impact on startup has not been determined. | Follow up; cause unverified |
| Recovery evidence | Snapshot, USB passthrough, attached-device safety, and console recovery were not independently verified in this check | `UNVERIFIED` |

The VM had previously been described as an isolated lab with a snapshot, but
that assertion does not verify its current USB passthrough, policy, or recovery
state. The configuration and policy locations were inspected read-only with
`sudo`; the daemon was not started. The service remains inactive, so the
configured persistent sources do not establish which rules are currently
loaded or how runtime policy changes behave.

## Project files and tests

The transferred project did not contain the new read-only USBGuard adapter or
its unit test. At the initial transfer, the following two files were copied
into the user-owned project directory, without overwriting existing files:

- `scripts/lib/usbguard-policy.sh`
- `tests/unit/test_policy_read.sh`

Their local and VM SHA-256 values matched:

| File | SHA-256 |
|---|---|
| `scripts/lib/usbguard-policy.sh` | `4b1d41b969b9f600135cd6f3a144b3877b450bcd7078029aaeac60106a2a7fcc` |
| `tests/unit/test_policy_read.sh` | `62c1c01c98491746d0a83bb3683bac7a3f6fbfe41f0f42a43e29fa87bd421d02` |

The adapter was subsequently corrected locally to accept both configured
policy sources. That updated revision has not been copied to the VM: a
non-interactive SSH recheck returned `Permission denied (publickey,password)`.
The earlier VM mock-test result therefore applies only to the initial
transferred revision, not this correction.

Results:

- VM: all transferred shell syntax checks passed.
- VM: config-reader (35 checks), result-model, lock, logger, time-guard, and
  Python unit tests (21 tests) passed.
- VM: mocked read-only adapter tests passed after the two files were copied.
  The adapter test puts its fake `usbguard` and `pgrep` commands first in
  `PATH`; it did not exercise the real daemon.
- Development environment (WSL): all unit test scripts and all 21 Python
  tests passed; `git diff --check` passed.

## Gate decision

G-01 remains `UNVERIFIED`, not `PASS`: the USBGuard service is disabled and
inactive, IPC is unavailable, loaded runtime policy and USB behavior were not
verified, and lab recovery prerequisites were not rechecked. No
`allow-device`, `append-rule`, `remove-rule`, or `block-device` operation was
run. No service was enabled or started.

Do not implement or run policy-changing adapter operations until an
administrator verifies the daemon configuration, active/persistent policy,
disposable USB test device, snapshot, and independent recovery route. Continue
only with read-only or mocked work until those prerequisites are evidenced.
