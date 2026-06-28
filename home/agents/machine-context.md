---
applyTo: "**"
---

# Machine Context

## OS

This is a NixOS-machine. Do not assume any tools are globally installed.

## Shell

The shell is **fish**. All terminal commands must use valid fish syntax. Do not use bash syntax — it will fail.

Common bash-isms to avoid and their fish equivalents:

| Bash | Fish |
|------|------|
| `cmd1 && cmd2` | `cmd1; and cmd2` |
| `export VAR=value` | `set -x VAR value` |
| `$(cmd)` | `(cmd)` |
| `if [ ... ]; then` | `if test ...; ... end` |
| `cmd > file 2>&1` | `cmd > file 2>&1` (ok) or `cmd &> file` (not valid in fish — use `cmd > file 2>&1`) |
| `cmd 2> /dev/null` | `cmd 2>/dev/null` |

When writing multi-line scripts, use fish syntax throughout (`end` instead of `fi`/`done`/`}`, etc.).

## Running Tools with Nix

If a tool is not found, do not fail or ask immediately. Instead:

1. **Wrap the command** using `nix-shell -p <package> --run '<command>'`, making your best guess at the nixpkgs package name.
2. **If that fails**, try to determine the correct package name on your own (e.g., by searching or reasoning about nixpkgs naming conventions).
3. **If that also fails**, ask the user for the correct package name.

Example — running a Python script:
```fish
nix-shell -p python3 --run 'python3 script.py'
```

## Using Project specific tools

If a tool is necessary for a project (tofu for terraform tests in a terraform project), you *MAY* run the tests with `nix-shell` to make sure things work, but you *MUST* also create or update a flake.nix and an .envrc file in that directory, so the user can reproduce the workflows without much hassle.

A good dev setup has:

- **`flake.nix`** exposing `devShells.default` (toolchain + LSP + linter).
- **`.envrc`** containing `use flake` so direnv loads the shell automatically.
- **Cross-platform systems.** Always support macOS *and* Linux (the team is
  mostly on mac) via `flake-utils.lib.eachDefaultSystem`.
- **A `shellHook` that echoes the most important commands**, so entering the
  shell prints how to build/run/test.
- **A `Taskfile.yml`** that wraps and documents the common commands (build, run,
  test, lint). Tasks are the canonical entry points — put real commands there. 