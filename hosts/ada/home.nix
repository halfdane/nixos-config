# Minimal home configuration for ada
{ config, pkgs, ... }:
{
  programs.beets = {
    enable = true;
    settings = {
      directory = "/mnt/storagebox/media/library/music/";
      library = "/mnt/storagebox/media/library/music/library.db";
      plugins = [ 
        "fetchart" 
        "ftintitle" 
        "musicbrainz" 
        "spotify" 
        "lyrics" 
        "lastgenre" 
        "convert"
        "the"
      ];
      import = {
        move = true;
        duplicate_action = "merge";
        incremental_skip_later = false;
      };
      paths = {
        default = "%the{$album_artist_no_feat}/$year-$album/$track-$title";
      };
      asciify_paths = true;
      convert = {
        auto = true;
        format = "opus";
        no_convert = "^path::\.(flac)$";
        never_convert_lossy_formats = "yes";
        formats.opus = "ffmpeg -i $source -y -vn -acodec libopus -ab 128k $dest";
      };

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
