{ githubConfig, homeDir, ... }:
{
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
