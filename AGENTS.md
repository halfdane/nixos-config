# Repository conventions for agents

This file documents repo-specific patterns. opencode and GitHub Copilot CLI read
it automatically when working inside this repo. Follow these conventions before
inventing your own.

## Home Manager modules (`home/`)

`home/default.nix` is a plain list of module paths that every host imports. Each
module in `home/` defines a **custom option** and gates its config behind an
`enable` flag — it does **not** unconditionally apply config. Hosts opt in from
`hosts/<host>/home.nix` with `programs.<name>.enable = true;`.

This keeps every host importing the same module set while only activating what it
needs. Do **not** add per-host `imports = [ ../../home/foo.nix ];` blocks — wire
features through the enable flag instead.

Pattern: a module defines `options.programs.<name>.enable` (via
`lib.mkEnableOption`) and wraps its real config in `lib.mkIf cfg.enable { ... }`.
Copy an existing one — see `home/agents.nix` or `home/plasma_hacking.nix`.

Steps to add a new home feature:

1. Create `home/<name>.nix` using the pattern above.
2. Add `./<name>.nix` to the list in `home/default.nix`.
3. Enable it on the relevant host(s) with `programs.<name>.enable = true;` next to
   the other `programs.*.enable` lines in `hosts/<host>/home.nix`.

## Editable-via-repo files (`mkOutOfStoreSymlink`)

For config that the user edits frequently and wants to take effect **without a
rebuild**, point `home.file."<dest>".source` at
`config.lib.file.mkOutOfStoreSymlink "/home/user/nixos-config/<path>"` instead of
copying into the Nix store. See `home/agents.nix` or `home/vscode.nix`. Trade-off:
the absolute repo path makes it machine/host-specific.

## Deploy

Deploy with `task` (default task = `deploy:curie`). The "Git tree is dirty"
warning during deploy is benign. See `Taskfile.yml`.
