{ config, pkgs, lib, nixpkgsNavidrome, ... }:
let
  # AES-256-GCM encrypted passwords using navidrome's default key ("just for obfuscation").
  # Key = SHA256(defaultKey), nonce = 12 zero bytes. Each user's password is their username.
  # Recompute with:
  #   node -e "const c=require('crypto'),k=c.createHash('sha256').update('just for obfuscation').digest(),n=Buffer.alloc(12,0),ci=c.createCipheriv('aes-256-gcm',k,n);ci.update('<password>','utf8');ci.final();console.log(Buffer.concat([n,ci.getAuthTag()]).toString('base64'))"

  # Users to seed. Initial password = username (users should change after first login).
  initialUsers = [
    { id = "4e6f727468506f6c654672656401"; userName = "tom";      name = "Tom";      email = "tom@navidrome.local";      isAdmin = false; encPw = "AAAAAAAAAAAAAAAAMDIpn0tqUVDZ1oWoxEdW6/e6bA=="; }
    { id = "4e6f727468506f6c654672656402"; userName = "deanie";   name = "Deanie";   email = "deanie@navidrome.local";   isAdmin = false; encPw = "AAAAAAAAAAAAAAAAIDgl3jB2/PUz35DkSWyLBYGXuK5iIA=="; }
    { id = "4e6f727468506f6c654672656403"; userName = "lea";      name = "Lea";      email = "lea@navidrome.local";      isAdmin = false; encPw = "AAAAAAAAAAAAAAAAKDglcS/YP9ksI57qrDjaMCDlWA=="; }
    { id = "4e6f727468506f6c654672656404"; userName = "phillipp"; name = "Phillipp"; email = "phillipp@navidrome.local"; isAdmin = false; encPw = "AAAAAAAAAAAAAAAANDUt3DV6u4HGmkprL3IWV+T6vhMknqmm"; }
    { id = "4e6f727468506f6c654672656405"; userName = "ben";      name = "Ben";      email = "ben@navidrome.local";      isAdmin = false; encPw = "AAAAAAAAAAAAAAAAJjgq+a6pJL9gYf036NkuiCevYw=="; }
  ];

  insertStatements = lib.concatMapStringsSep "\n" (u: ''
    INSERT OR IGNORE INTO user (id, user_name, name, email, password, is_admin, created_at, updated_at)
    VALUES ('${u.id}', '${u.userName}', '${u.name}', '${u.email}', '${u.encPw}', ${if u.isAdmin then "1" else "0"}, datetime('now'), datetime('now'));
  '') initialUsers;

  seedScript = pkgs.writeShellScript "navidrome-seed-users" ''
    DB=/var/lib/navidrome/navidrome.db

    # Wait up to 30s for navidrome to create and migrate the DB
    for i in $(seq 1 30); do
      [ -f "$DB" ] && break
      echo "Waiting for navidrome DB... ($i)"
      sleep 1
    done

    if [ ! -f "$DB" ]; then
      echo "Navidrome DB not found after 30s, giving up"
      exit 1
    fi

    ${pkgs.sqlite}/bin/sqlite3 "$DB" << 'SQL'
    ${insertStatements}
    SQL
    echo "Navidrome user seeding complete"
  '';
in
{

  services.navidrome = {
    enable = true;
    package = nixpkgsNavidrome.navidrome;
    # openFirewall is intentionally omitted — wg0 is a trusted interface
    # (see nixos/wireguard.nix), so navidrome is reachable over the WireGuard
    # tunnel without opening any public ports.
    settings = {
      MusicFolder = "/data/Music";
      Address = "127.0.0.1";
    };
  };

  services.nginx.virtualHosts."music.micasaestu.casa" = {
    useACMEHost = "micasaestu.casa";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:4533";
      proxyWebsockets = true;
    };
  };

  systemd.services.navidrome-seed-users = {
    description = "Seed initial users into Navidrome";
    after = [ "navidrome.service" ];
    wants = [ "navidrome.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "navidrome";
      ExecStart = seedScript;
    };
  };

}