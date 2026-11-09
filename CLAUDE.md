# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Working with the user

- The user is a beginner learning Linux networking, Python and CI/CD. Explain every change in simple terms, keep code simple, and comment it well.
- Always plan before writing code, and wait for the user's approval before implementing.

## Project overview

"Firewall Segmentation as Code" has these parts:

- **Zones in YAML**: four network zones (`users`, `servers`, `dmz`, `mgmt`) and the traffic allowed between them.
- **Python package**: reads the YAML and generates nftables rules. The policy is **default-deny**, so only flows that are explicitly allowed get through.
- **Lab**: Linux network namespaces simulate the zones, so the generated rules can be tested on real traffic.
- **Tests**: pytest.
- **CI**: GitHub Actions.

## Environment

- Ubuntu 24.04 on WSL.
- `python3-venv` is **not** available. Always use `uv`, never `python -m venv` or bare `pip`:
  - Create the environment: `uv venv`
  - Install packages: `uv pip install <package>`
  - Run things: `uv run <command>` (for example `uv run pytest`)
  - Run a single test: `uv run pytest path/to/test_file.py::test_name`
- Creating network namespaces and loading nftables rules requires root (`sudo`).
