{
  "ada-luks-key.age".publicKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDHWGuX4TkCbSULp4k2DE6wAIzQc7+fQiDIflAZXj4Si root@ada"
  ];

  # Example secret for laptop, encrypted to both dedicated and host key
  # access with
  # agenix -i ~/.ssh/agenix/dedicated -d secrets/laptop-test.age
  # or
  # sudo agenix -i /etc/ssh/ssh_host_ed25519_key -d secrets/laptop-test.age
  "secrets/laptop-test.age".publicKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOx9sXjVaW0eYotn3mM9Ct9bBuBEseqsCtz+R1SGWYQD agenix-dedicated"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICciBSfBDLlD+btY8umPTuFOcWoGsTv+w3+Z4JjXJrL9 root@nixos"
  ];
}
