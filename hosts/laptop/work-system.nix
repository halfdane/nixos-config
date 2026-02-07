{ config, pkgs, lib, ... }:

let
  # Corporate CA certificates directory
  # When imported via flake, use relative path
  certDir = ./certificates;
  hasCerts = builtins.pathExists certDir;
in
{
  # Install corporate CA certificates system-wide (for curl, wget, git, etc)
  security.pki.certificateFiles = 
    if hasCerts then
      let
        certFiles = builtins.attrNames (builtins.readDir certDir);
        isCertFile = name: lib.hasSuffix ".pem" name;
      in
        map (f: "${certDir}/${f}") (builtins.filter isCertFile certFiles)
    else [];
  
  # Also add certificates to system packages for extra compatibility
  security.pki.certificates = 
    if hasCerts then
      let
        certFiles = builtins.attrNames (builtins.readDir certDir);
        isCertFile = name: lib.hasSuffix ".pem" name;
      in
        map (f: builtins.readFile (certDir + "/${f}")) (builtins.filter isCertFile certFiles)
    else [];
}
