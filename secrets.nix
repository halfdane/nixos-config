{
  # Example secret for laptop, encrypted to both dedicated and host key
  # access with
  # agenix -i ~/.ssh/agenix/dedicated -d secrets/laptop-test.age
  # or
  # sudo agenix -i /etc/ssh/ssh_host_ed25519_key -d secrets/laptop-test.age
  "secets/laptop-test.agre".publicKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOx9sXjVaW0eYotn3mM9Ct9bBuBEseqsCtz+R1SGWYQD agenix-dedicated"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICciBSfBDLlD+btY8umPTuFOcWoGsTv+w3+Z4JjXJrL9 root@nixos"
  ];
  # Tailscale invitation key, accessible by both ada and laptop
  "secrets/tailscale-invite.age".publicKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPBv3YA8tvbpu6riWsDaMtSs7yqidiQpD9do6gBi2BQn root@ada"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICciBSfBDLlD+btY8umPTuFOcWoGsTv+w3+Z4JjXJrL9 root@nixos"
  ];
}
