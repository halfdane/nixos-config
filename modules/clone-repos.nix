# Repo Cloning Home Manager Module
# Provides a reusable way to declare repo cloning scripts for any account/target.

{ config, pkgs, lib, ... }:
{
  options.cloneRepos = lib.mkOption {
    type = lib.types.listOf (lib.types.submodule {
      options = {
        repos = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "List of repositories to clone (owner/repo or subdir:owner/repo).";
        };
        account = lib.mkOption {
          type = lib.types.str;
          description = "GitHub account to use for authentication.";
        };
        targetDir = lib.mkOption {
          type = lib.types.str;
          description = "Target directory for cloning repos.";
        };
        scriptName = lib.mkOption {
          type = lib.types.str;
          description = "Name of the script to generate in ~/bin/.";
        };
      };
    });
    default = [];
    description = "List of repo cloning script definitions.";
  };

  config = {
    home.file = lib.mkMerge (
      map (
        script: {
          "bin/${script.scriptName}" = {
            text = ''
              #!/usr/bin/env bash
              set -e
              echo "Switching to GitHub account..."
              gh auth switch --user ${script.account} || {
                echo "Account not found. Please add it first:"
                echo "  gh auth login --web"
                exit 1
              }
              TARGET_DIR="${script.targetDir}"
              mkdir -p "$TARGET_DIR"
              repos="${lib.concatMapStringsSep " " (repo: repo) script.repos}"
              for repo in $repos; do
                if [[ "$repo" == *":"* ]]; then
                  subdir="''${repo%%:*}"
                  repo_path="''${repo#*:}"
                  target_dir="$TARGET_DIR/''${subdir}"
                else
                  repo_path="''${repo}"
                  target_dir="$TARGET_DIR"
                fi
                repo_name=$(basename "''${repo_path}" .git)
                full_path="$target_dir/''${repo_name}"
                if [ ! -d "''${full_path}" ]; then
                  echo "Cloning ''${repo_name} to ''${target_dir}..."
                  mkdir -p "''${target_dir}"
                  gh repo clone "''${repo_path}" "''${full_path}"
                else
                  echo "''${repo_name} already exists at ''${full_path}, skipping"
                fi
              done
            '';
            executable = true;
          };
        }
      ) config.cloneRepos
    );
  };
}
