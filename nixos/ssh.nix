# Pins GitHub's host key system-wide (/etc/ssh/ssh_known_hosts), so `sudo
# nixos-rebuild switch` never blocks on an interactive host-key prompt when
# fetching flake inputs over git+ssh (e.g. the `secrets` and
# `minerva_owl_setup` inputs in flake.nix) - root has no ~/.ssh/known_hosts
# of its own, and per-user known_hosts (home-manager) never applies to it.
# Fingerprint verified against https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
{
  programs.ssh.knownHosts."github.com" = {
    hostNames = [ "github.com" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
  };
}
