{ githubConfig, ... }:
{
  # Direnv config for GitHub account
  home.file."${githubConfig.directory}/.envrc".text = ''
    # Auto-switch to GitHub account when entering this directory
    gh auth switch --user ${githubConfig.account}

    export GIT_AUTHOR_NAME="${githubConfig.name}"
    export GIT_AUTHOR_EMAIL="${githubConfig.email}"
    export GIT_COMMITTER_NAME="${githubConfig.name}"
    export GIT_COMMITTER_EMAIL="${githubConfig.email}"
  '';

  imports = [ ../../modules/clone-repos.nix ];
  cloneRepos = [
    {
      repos = githubConfig.repos;
      account = githubConfig.account;
      targetDir = "${githubConfig.directory}/${githubConfig.account}";
      scriptName = "clone-${githubConfig.account}-repos";
    }
  ];
}
