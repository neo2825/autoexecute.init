# inite-config-scripts

A small collection of cross-platform scripts to create an `inite.config` file at the root of a removable drive (pendrive).

Included:
- `init_inite_config.sh` — Bash script for Linux/macOS
- `init_inite_config.ps1` — PowerShell script for Windows
- `init_inite_config.py` — Cross-platform Python script

Each script attempts to auto-detect a removable drive, or you can pass an explicit mount path / drive letter. They will prompt before overwriting an existing `inite.config` unless run with `--force`/`-Force`.

Usage examples are in the scripts' headers. Use at your own risk — detection is heuristic; pass an explicit path if uncertain.
