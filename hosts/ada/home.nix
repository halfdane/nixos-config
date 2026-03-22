# Minimal home configuration for ada
{ config, pkgs, ... }:
{
  home.username = "halfdane";
  home.homeDirectory = "/home/halfdane";

  programs.beets = {
    enable = true;
    settings = {
      directory = "/mnt/storagebox/media/music/";
      library = "/mnt/storagebox/media/music/library.db";
      plugins = [ "info" "scrub" "missing" "duplicates" "ftintitle" "fetchart" "musicbrainz" "spotify" "lyrics" "lastgenre" ];
      import = {
        move = true;
        duplicate_action = "merge";
        incremental = true;
        incremental_skip_later = false;
      };
      paths = {
        default = "$album_artist_no_feat/$year-$album/$track-$title";
      };
      asciify_paths = true;

      musicbrainz = {
        genres = false;
        data_source_mismatch_penalty = 0.1;  # Lower penalty = preferred
      };
      spotify.data_source_mismatch_penalty = 0.9;
      lastgenre = {
        canonical = true;
        whitelist = true;
        count = 3;
      };
      lyrics = {
        auto = true;
        dist_thresh = 0.11;
        fallback = null;
        force = false;
        print = false;
        sources = [ "lrclib" ];
        synced = false;
      };
    };
  };
}
