{ config, pkgs, inputs, lib, ... }: 
let
  userConfig = import ./user-config.nix;
  
  username = userConfig.username;
  homeDir = "/home/${username}";
  workDir = "${homeDir}/work";
in
{
  home.username = username;
  home.homeDirectory = homeDir;
  home.stateVersion = "25.11";

  # Add ~/bin to PATH
  home.sessionPath = [ "${homeDir}/bin" ];

  home.packages = with pkgs; [
        pkgs.htop
        pkgs.curl
        kdePackages.kate
        kdePackages.kdeconnect-kde
        vscode
        keepassxc
        chromium
        pkgs.maestral
        pkgs.maestral-gui
        pkgs.gh
        pkgs.direnv
        pkgs.sqlite
        pkgs.fzf
    ];

  # Enable bash to source Home Manager session variables
  programs.bash = {
    enable = true;
    initExtra = ''
      # Source Home Manager session variables
      . "/etc/profiles/per-user/${username}/etc/profile.d/hm-session-vars.sh"
    '';
  };

  # Fish shell - modern shell with better defaults
  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "plugin-git";
        src = pkgs.fishPlugins.plugin-git.src;
      }
    ];
    shellAbbrs = {};
    functions = {};
  };

  # Enable direnv for automatic gh auth switching
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    
    # Automatically load .envrc from parent directories
    stdlib = ''
      # Load parent .envrc files automatically
      source_up_if_exists
    '';
  };

  # Git configuration with directory-based identity switching
  programs.git = {
    enable = true;
    
    settings = {
      user.name = userConfig.personalGitName;
      user.email = userConfig.personalGitEmail;
      init.defaultBranch = "main";
      
      # Use GitHub CLI for authentication
      credential.helper = "!${pkgs.gh}/bin/gh auth git-credential";
    };
  };

  # Direnv config for personal directory (auto-switch to personal gh account)
  home.file."halfdane/.envrc".text = ''
    # Auto-switch to personal GitHub account when entering this directory
    gh auth switch --user ${userConfig.personalGitAccount}
  '';

  # Clone personal repositories script
  home.file."bin/clone-personal-repos".text = ''
    #!/usr/bin/env bash
    set -e
    
    # Switch to personal GitHub account
    echo "Switching to personal GitHub account..."
    gh auth switch --user ${userConfig.personalGitAccount} || {
      echo "Personal account not found. Please add it first:"
      echo "  gh auth login --web"
      exit 1
    }
    
    PERSONAL_DIR="${homeDir}/halfdane"
    mkdir -p "$PERSONAL_DIR"
    
    repos=(
      ${lib.concatMapStringsSep "\n      " (repo: ''"${repo}"'') userConfig.personalRepos}
    )
    
    for repo in "''${repos[@]}"; do
      repo_name=$(basename "$repo" .git)
      if [ ! -d "$PERSONAL_DIR/$repo_name" ]; then
        echo "Cloning $repo_name..."
        gh repo clone "$repo" "$PERSONAL_DIR/$repo_name"
      else
        echo "$repo_name already exists, skipping"
      fi
    done
  '';
  
  home.file."bin/clone-personal-repos".executable = true;
  home.file."bin/nrs".text = ''
    #!/usr/bin/env bash
    cd ~/nixos-config
    nix flake update work-config
    sudo nixos-rebuild switch --flake .#vm-qemu
  '';
  home.file."bin/nrs".executable = true;

  # Create directories on activation
  home.activation.createDirectories = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${homeDir}/halfdane
    mkdir -p ${homeDir}/bin
  '';

}
