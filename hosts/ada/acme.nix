{ config, lib, ... }:
{
  # ---------------------------------------------------------------------------
  # Let's Encrypt wildcard cert for *.micasaestu.casa via netcup DNS-01 challenge.
  #
  # DNS-01 means: no inbound ports are required for cert issuance.
  # The ACME client (lego) writes a TXT record to the netcup DNS API to prove
  # domain ownership, then removes it after the challenge succeeds.
  #
  # The credential file (sourced as shell env before lego runs) must contain:
  #   NETCUP_CUSTOMER_NUMBER=<your 8-digit customer number>
  #   NETCUP_API_KEY=<your API key>
  #   NETCUP_API_PASSWORD=<your API password>
  # ---------------------------------------------------------------------------

  age.secrets."netcup.age" = {
    file = ./../../secrets/netcup.age;
    # The acme user (created by security.acme) must be able to read this file.
    owner = "acme";
    group = "acme";
  };

  security.acme = {
    acceptTerms = true;

    defaults = {
      email = "REDACTED_PERSONAL_EMAIL";
    };

    certs."micasaestu.casa" = {
      # Request both the wildcard and the apex domain in one cert.
      domain = "*.micasaestu.casa";
      extraDomainNames = [ "micasaestu.casa" ];

      dnsProvider = "netcup";
      credentialsFile = config.age.secrets."netcup.age".path;

      # Allow nginx to read the issued cert files.
      group = config.services.nginx.group;
    };
  };

  # Ensure nginx is reloaded whenever the cert is renewed.
  systemd.services."acme-micasaestu.casa" = {
    serviceConfig.Group = lib.mkForce config.services.nginx.group;
  };

  # Any nginx vhost using this cert must redirect HTTP to HTTPS.
  # Serving content over plain HTTP with a valid cert available is a mistake.
  assertions =
    let
      acmeVhosts = lib.filterAttrs
        (_: v: (v.useACMEHost or null) == "micasaestu.casa")
        config.services.nginx.virtualHosts;
      insecureVhosts = lib.filterAttrs
        (_: v: !(v.forceSSL or false) && !(v.onlySSL or false))
        acmeVhosts;
    in [{
      assertion = insecureVhosts == {};
      message = ''
        These nginx virtualHosts use the micasaestu.casa ACME cert but do not
        set forceSSL = true or onlySSL = true:
          ${lib.concatStringsSep "\n  " (lib.attrNames insecureVhosts)}
        Add forceSSL = true to each.
      '';
    }];
}
