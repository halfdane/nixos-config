{ config, lib, pkgs, ... }:
let
  cfg = config.programs.todo;
  configFile = "${config.xdg.configHome}/todo/config";
  todoCommand = pkgs.runCommand "todo-command" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
    install -Dm755 ${./todo/todo-wrapper.sh} $out/bin/todo
    patchShebangs $out/bin/todo
    wrapProgram $out/bin/todo \
      --set TODOTXT_CFG_FILE ${configFile} \
      --prefix PATH : ${pkgs.todo-txt-cli}/bin
  '';
  todoActions = pkgs.runCommand "todo-actions" { } ''
    install -Dm755 ${./todo/otto-mate.sh} $out/otto-mate/otto-mate
    install -Dm644 ${./todo/otto-mate-guide.md} $out/otto-mate/otto-mate-guide.md
    patchShebangs $out/otto-mate/otto-mate
  '';
  greeting = pkgs.runCommand "todo-greeting" { } ''
    install -Dm755 ${./todo/greeting.sh} $out/bin/todo-greeting
    patchShebangs $out/bin/todo-greeting
  '';
in
{
  options.programs.todo = {
    enable = lib.mkEnableOption "todo.txt command line with a greeting in interactive shells";
    directory = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/utm/todo";
      description = "Directory that holds todo.txt, inbox.txt and done.txt.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.todo-txt-cli todoCommand ];

    xdg.configFile."todo/config".text = ''
      export TODO_DIR=${cfg.directory}
      export TODO_ACTIONS_DIR=${todoActions}
      export TODOTXT_DATE_ON_ADD=1
    '';

    programs.zsh.initContent = ''
      autoload -U +X bashcompinit && bashcompinit
      source ${pkgs.todo-txt-cli}/share/bash-completion/completions/todo
      complete -F _todo todo
      ${greeting}/bin/todo-greeting ${lib.escapeShellArg cfg.directory}
    '';
  };
}
