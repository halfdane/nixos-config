{ githubConfig, homeDir, ... }:
{
  # Direnv config for GitHub account
  home.file."${githubConfig.account}/.envrc".text = ''
    # Auto-switch to GitHub account when entering this directory
    gh auth switch --user ${githubConfig.account}
  '';

  imports = [ ../../modules/clone-repos.nix ];
  cloneRepos = [
    {
      repos = githubConfig.repos;
      account = githubConfig.account;
      targetDir = "${homeDir}/${githubConfig.account}";
      scriptName = "clone-${githubConfig.account}-repos";
    }
  ];
}
