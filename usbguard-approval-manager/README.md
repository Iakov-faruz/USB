# USBGuard Approval Manager

A command-line and text-interface manager for controlled temporary and
permanent USBGuard approvals.

## Requirements baseline

Implementation follows the approved SRS v4.5 baseline in [../USB.md](../USB.md).
The prior v4.4 specification is retained as historical reference.
G-01 and restore/deployment safety evidence remain mandatory gates before
implementing or enabling dependent policy-changing operations.

The application code, configuration, deployment units, and tests are kept in
this directory. The specification, implementation roadmap, and prompt catalog
remain at the repository root.

## Project status

The foundation includes a strict configuration reader, shared result model,
atomic JSON writer, and focused unit tests. The USBGuard adapter and
policy-changing operations have not been implemented.

## Development rules

- Keep components small, modular, and focused on one responsibility.
- Preserve the approved SRS baseline and stop on unresolved security behavior.
- Do not change USBGuard policy on the development host.
- Run policy-changing integration tests only in an isolated lab VM with
  USB passthrough and a verified recovery route.

## Local checks

From this directory, run the unit tests with:

```sh
bash tests/unit/test_config_reader.sh
bash tests/unit/test_result.sh
python3 -m unittest discover -s tests/unit -p 'test_*.py'
```
