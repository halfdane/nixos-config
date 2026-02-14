let 
  personal = {
    name = "halfdane";
    email = "REDACTED_PERSONAL_EMAIL";
    account = "halfdane";
    directory = "halfdane";
    repos = [
      "halfdane/duality_keyboard"
      "halfdane/spotify-player"
    ];
  };
in
{
  username = "tvollert";
  fullName = "a user";

  github = {
    inherit personal;
    system = personal // {
      directory = "nixos-config";
    };
    work = {
      name = "REDACTED_WORK_NAME";
      email = "REDACTED_WORK_EMAIL";
      account = "TomVollerthun1337";
      directory = "work";
      repos = [
        "tsc:otto-ec/tech-rules-of-play"
        "tsc:otto-ec/milliseconds_make_millions"
        "roadie:otto-ec/roadie_otto-business-catalog"
        "roadie:otto-ec/roadie_backstage-platform-services"
        "roadie:otto-ec/roadie_backstage"
        "roadie:otto-ec/roadie_backstage-community-plugins"
        "roadie:otto-ec/roadie_backstage-docs-entrypage"
      ];
    };
  };
}
