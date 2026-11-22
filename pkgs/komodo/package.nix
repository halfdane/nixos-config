{
  lib,
  mkKdeDerivation,
  fetchFromGitLab,
}:
mkKdeDerivation {
  pname = "komodo";
  version = "1.6.0-unstable-2026-11-21";

  src = fetchFromGitLab {
    domain = "invent.kde.org";
    owner = "utilities";
    repo = "komodo";
    rev = "a911b5ad821a9423c7fa5def22bd71c2e3417c46";
    hash = "sha256-jXMkk2gaxkXFq7+Jdq6xiOAA0fpZBNgsAWl4c10WEY4=";
  };

  meta = {
    description = "Todo manager for the todo.txt specification";
    homepage = "https://apps.kde.org/komodo/";
    license = lib.licenses.gpl2Plus;
    mainProgram = "komodo";
  };
}
