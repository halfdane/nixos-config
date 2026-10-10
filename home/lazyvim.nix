{ config, lib, pkgs, ... }:
let
  cfg = config.programs.lazyvim;
  repoDir = "/home/user/nixos-config/home/lazyvim";
in
{
  options.programs.lazyvim.enable = lib.mkEnableOption "Neovim with LazyVim (config editable in repo, plugins fetched by lazy.nvim)";

  config = lib.mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = false;
      viAlias = true;
      vimAlias = true;
      withRuby = false;
      withPython3 = true;
      # programs.neovim generates nvim/init.lua itself, so the repo files are
      # linked individually instead of linking the whole directory.
      initLua = ''
        require("config.lazy")
      '';
      extraPackages = with pkgs; [
        git gcc gnumake tree-sitter ripgrep fd lazygit unzip curl
        nil nixfmt lua-language-server stylua
      ];
    };

    xdg.configFile = lib.genAttrs [ "lua" "lazy-lock.json" "lazyvim.json" ] (n: {
      source = config.lib.file.mkOutOfStoreSymlink "${repoDir}/${n}";
      target = "nvim/${n}";
    });
  };
}
