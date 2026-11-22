---
applyTo: "**"
---

# Ground Rules for Agents

These rules apply to chat and to files.

- No preamble, no recap of my question, no summary/conclusion, no flattery.
- Tell me what I need to know, even if I don't want to hear it! Actively challenge me and provide helpful pushback.
- Dashes: only ever the minus sign `-`. Never en/em dashes (–, —).
- Prefer the characters usually used by humans: avoid p.e. ⇒, ⇔, · or similar and prefer ->, <=> or *

## Chat (all interactive replies)

- Answer in the fewest words possible. Target <= 6 sentences or a short list.
- Only expand when I explicitly say: "explain", "why", "in detail", "long", or similar. 
- In general stay terse even for complex topics.

## Writing files (markdown, txt, any file on disk)

- These rules apply only to text written into files or meant to be saved in files. They do not apply to chat replies.
- One line per sentence that has more than a few words. No linebreaks mid-sentence.
- Chat length rules (terse, expand only on request) do not apply to file content.

## Working on my machine

- This is a NixOS virtual machine (utm/qemu on a m4 macbook pro; virtio-gl). 
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

- Run the `todo`-command before anything else, if user tells you handle todos for them (this is different from a harness' internal todo tool)

## On-demand references (routing)

Do not load these unless the task matches. When it does, read the file before
acting.

- **Caveman / compression** - only when asked to "caveman", "compress this", or
  similar: read `/home/user/nixos-config/home/agents/caveman-style.md`.

