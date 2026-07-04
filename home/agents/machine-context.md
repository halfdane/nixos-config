---
applyTo: "**"
---

# Ground Rules

 - When reporting information to me, be extremely concise and sacrifice grammar for sake of concision. 
- No flattering language.
- Tell me what I need to know, even if I don't want to hear it!

## Working on my machine

- This is a NixOS virtual machine (utm/qemu on a m4 macbook pro). 
- The shell is **fish**. Use valid fish syntax for every command; bash syntax will fail. Key translations:

    - `cmd1 && cmd2` → `cmd1; and cmd2`
    - `export VAR=value` → `set -x VAR value`
    - `$(cmd)` → `(cmd)`
    - `if [ ... ]; then ... fi` → `if test ...; ...; end`
    - `cmd &> file` is invalid → use `cmd > file 2>&1`
    - Multi-line scripts: use `end` instead of `fi`/`done`/`}`.

- Running Tools with Nix

    - Wrap it: `nix-shell -p <package> --run '<command>'` (guess the nixpkgs name,
    e.g. `nix-shell -p python3 --run 'python3 script.py'`).
    - If that fails, reason out the correct package name (nixpkgs conventions).
    - Only then ask the user.

- Project-specific tools

    You may run a project's tools via `nix-shell` to verify things work, but you
    **must** also leave the project reproducible without it. A good dev setup has:

    - **`flake.nix`** exposing `devShells.default` (toolchain + LSP + linter),
    cross-platform for macOS *and* Linux via `flake-utils.lib.eachDefaultSystem`.
    - **`.envrc`** containing `use flake` so direnv loads the shell automatically.
    - **A `shellHook`** that echoes the key build/run/test commands.
    - **A `Taskfile.yml`** wrapping those commands as the canonical entry points.

## On-demand references (routing)

Do not load these unless the task matches. When it does, read the file before
acting.

- **Caveman / compression** — only when asked to "caveman", "compress this", or
  similar: read `/home/user/nixos-config/home/agents/caveman-style.md`.

