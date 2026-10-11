{ config, pkgs, inputs, lib, username, ... }:
let
  gitId = import "${inputs.secrets}/git-identities.nix";
in
{
  age = {
    identityPaths = [ "/run/agenix/user-ssh-key" ];
    secrets = {
      github-personal.file = "${inputs.secrets}/github-personal.age";
      github-work.file = "${inputs.secrets}/github-work.age";
    };
  };

  # Dedicated alias so the otto-ec work key is selected by hostname, not by
  # cwd/gitdir (Nix's flake-input git fetcher clones outside ~/work/, so the
  # gitdir:~/work/** include below never applies to it).
  programs.ssh.settings."github-otto-ec" = {
    HostName = "github.com";
    User = "git";
    IdentityFile = config.age.secrets.github-work.path;
    IdentitiesOnly = "yes";
  };

  # Plain github.com defaults to the personal key. This is what git actually
  # falls back to now that programs.git.settings.core.sshCommand has no
  # unconditional default - only the gitdir:~/work/** include below still
  # overrides it (with the work key) for repos under ~/work/.
  programs.ssh.settings."github.com" = {
    User = "git";
    IdentityFile = config.age.secrets.github-personal.path;
    IdentitiesOnly = "yes";
  };

  programs.vscode.enable = true;
  programs.firefox.enable = true;
  programs.ssh.enable = true;  
  programs.chromium.enable = true;
  
  programs.plasma_hacking.enable = true;
  programs.plasma.enable = true;

  programs.agents.enable = true;
  programs.lazyvim.enable = true;
  programs.fonts.enable = true;
  programs.minerva.enable = true;
  programs.minerva.updateNotifier.enable = true;
  services.neru = {
    enable = true;
    settings.hints.strategy = "contour";
    # Default "bottom" pushes labels for the bottom panel off-screen.
    settings.hints.ui = {
      placement = "center";
      # Smaller, translucent labels keep the target visible underneath.
      font_size = 9; # default 10
      # Theme surface colors at 60% alpha (0x99).
      background_color = {
        light = "#99EEF2FF";
        dark = "#990A1338";
      };
    };
    # Defaults (wl-kbptr) produce many duplicate hints per target.
    # Larger minimums and slack merge nested blobs into their parent.
    settings.hints.contour = {
      min_target_width = 12.0; # default 7
      min_target_height = 8.0; # default 3
      flat_line_height = 8.0; # default 6
      same_center_slack = 16.0; # default 8
      square_icon_size = 56.0; # default 40
      square_icon_slack = 10.0; # default 5
    };
    settings.hotkeys = {
      "Ctrl+Alt+Space" = "hints --action left_click";
      # Whole screen: includes the Plasma panel and window decorations.
      "Ctrl+Alt+Meta+Space" = "hints --action left_click --capture-scope screen";
      "Ctrl+Alt+G" = "grid";
      "Ctrl+Alt+C" = "recursive_grid --zoom-to-depth 1";
      "Ctrl+Alt+B" = "bisect --cursor-selection-mode hold";
      "Ctrl+Alt+S" = "scroll";
    };
  };
  programs.opencode.settings.enabled_providers = lib.mkForce [
    "github-copilot"
    "litellm"
  ];

  # The locked Minerva path CLI module invokes tar, which looks up gzip via
  # PATH. Keep the activation working until the fixed Minerva revision lands.
  home.activation.pathCliGzip = lib.hm.dag.entryBefore [ "pathCli" ] ''
    export PATH="${pkgs.gzip}/bin:$PATH"
  '';

  home.packages = with pkgs; [ 
    home-manager 
    github-copilot-cli
    kdePackages.kdeconnect-kde
    keepassxc
    libsecret
    supersonic
    voxtype
    vlc
    obsidian
    opencode
    inkscape
    tuxedo
    fanficfare
  ];

  # FanFicFare CLI config. include_images defaults off, but the royalroad.com
  # adapter crashes (AttributeError on None.startswith) when a cover image is
  # present and include_images is off, so force it on for that site.
  home.file.".fanficfare/personal.ini".text = ''
    [www.royalroad.com]
    include_images:true
  '';

  programs.git = {
    enable = true;
    settings = {
      user.name = gitId.personal.name;
      user.email = gitId.personal.email;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      # Absolute store path only (no -i/identity here) so non-interactive
      # contexts (home-manager activation, systemd units, cron - anything
      # without openssh on PATH) can still spawn ssh at all. Identity/key
      # selection is left entirely to ~/.ssh/config's Host-based routing
      # (github.com -> personal, github-otto-ec -> work), which this does
      # not override. This applies everywhere, unlike the gitdir:~/work/**
      # include below - e.g. apm-cli's marketplace cache lives under
      # ~/.apm/cache/, outside ~/work/**, so only an unconditional default
      # like this reaches it.
      core.sshCommand = "${pkgs.openssh}/bin/ssh";
    };
    includes = [{
      condition = "gitdir:~/work/**";
      contents = {
        user.name = gitId.work.name;
        user.email = gitId.work.email;
        # Absolute store path, not bare `ssh`: non-interactive contexts
        # (home-manager activation, systemd units, cron) don't reliably
        # inherit a PATH containing openssh.
        core.sshCommand = "${pkgs.openssh}/bin/ssh -i ${config.age.secrets.github-work.path} -o IdentitiesOnly=yes";
      };
    }];
  };

}
