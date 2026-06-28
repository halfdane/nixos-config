# Agent rules shared across VS Code Copilot Chat, GitHub Copilot CLI and opencode.
#
# The canonical files live in the repo and are linked into each tool's global
# location with mkOutOfStoreSymlink, so edits in the repo take effect without a
# rebuild (matching the vscode_settings.json / firefox bookmarks pattern).
{ config, lib, ... }:
let
  cfg = config.programs.agents;
  repoRoot = "/home/user/nixos-config";
  machineContext = "${repoRoot}/home/agents/machine-context.md";
  opencodeConfig = "${repoRoot}/home/agents/opencode.jsonc";
  link = path: config.lib.file.mkOutOfStoreSymlink path;
in
{
  options.programs.agents = {
    enable = lib.mkEnableOption "shared agent rules for Copilot Chat, Copilot CLI and opencode";
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      # GitHub Copilot CLI — global (per-user) custom instructions.
      ".copilot/copilot-instructions.md".source = link machineContext;

      # opencode — global instructions and permission rules.
      ".config/opencode/AGENTS.md".source = link machineContext;
      ".config/opencode/opencode.jsonc".source = link opencodeConfig;

      # VS Code Copilot Chat — global instructions location is configured in
      # vscode_settings.json (chat.instructionsFilesLocations: ~/global-instructions).
      # Needs the applyTo frontmatter to always apply, which the shared file carries.
      "global-instructions/machine-context.instructions.md".source = link machineContext;
    };
  };
}
