{ config, pkgs, lib, ... }:

let
  # Work configuration values
  # Version controlled in enterprise GitHub
  workGitName = "REDACTED_WORK_NAME";
  workGitEmail = "REDACTED_WORK_EMAIL";
  workGitAccount = "TomVollerthun1337";
  
  # Work repositories to clone into ~/work/
  workRepos = [
    "tsc:otto-ec/tech-rules-of-play"
    "tsc:otto-ec/milliseconds_make_millions"
    "roadie:otto-ec/roadie_otto-business-catalog"
    "roadie:otto-ec/roadie_backstage-platform-services"
    "roadie:otto-ec/roadie_backstage"
    "roadie:otto-ec/roadie_backstage-community-plugins"
    "roadie:otto-ec/roadie_backstage-docs-entrypage"
  ];
in
{
  # Direnv config for work directory (auto-switch to work gh account)
  home.file."work/.envrc".text = ''
    # Auto-switch to work GitHub account when entering this directory
    gh auth switch --user ${workGitAccount}
    
    # Set Git identity via environment variables
    export GIT_AUTHOR_NAME="${workGitName}"
    export GIT_AUTHOR_EMAIL="${workGitEmail}"
    export GIT_COMMITTER_NAME="${workGitName}"
    export GIT_COMMITTER_EMAIL="${workGitEmail}"
  '';

  # Clone work repositories script
  # home.file."bin/clone-work-repos".text = ''
  #   #!/usr/bin/env bash
  #   set -e
    
  #   # Switch to work GitHub account
  #   echo "Switching to work GitHub account..."
  #   gh auth switch --user ${workGitAccount} || {
  #     echo "Work account not found. Please add it first:"
  #     echo "  gh auth login --web"
  #     exit 1
  #   }
    
  #   repos=(
  #     ${lib.concatMapStringsSep "\n      " (repo: ''"${repo}"'') workRepos}
  #   )
    
  #   for repo in "''${repos[@]}"; do
  #     # Check if repo has a subdirectory prefix (e.g., "subdir:owner/repo")
  #     if [[ "$repo" == *":"* ]]; then
  #       subdir="''${repo%%:*}"
  #       repo_path="''${repo#*:}"
  #       target_dir="$WORK_DIR/$subdir"
  #     else
  #       repo_path="$repo"
  #       target_dir="$WORK_DIR"
  #     fi
      
  #     repo_name=$(basename "$repo_path" .git)
  #     full_path="$target_dir/$repo_name"
      
  #     if [ ! -d "$full_path" ]; then
  #       echo "Cloning $repo_name to $target_dir..."
  #       mkdir -p "$target_dir"
  #       gh repo clone "$repo_path" "$full_path"
  #     else
  #       echo "$repo_name already exists at $full_path, skipping"
  #     fi
  #   done
  # '';
  
  # home.file."bin/clone-work-repos".executable = true;

}
