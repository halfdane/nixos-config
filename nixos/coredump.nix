{ ... }:

{
  # Core dumps are not useful on these hosts and can consume substantial disk
  # space, so discard them instead of storing them under /var/lib/systemd/coredump.
  systemd.coredump.settings.Coredump = {
    Storage = "none";
    ProcessSizeMax = "0";
  };
}
