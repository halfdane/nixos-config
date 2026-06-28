{ lib, fetchFromGitHub, stdenv, python3, makeWrapper }:

let
  python = python3.withPackages (ps: with ps; [
    boto3
    pyqt6
    ruamel-yaml
  ]);
in
stdenv.mkDerivation {
  pname = "logsmith";
  version = "11.0.2";  

  src = fetchFromGitHub {
    owner = "otto-de";
    repo = "logsmith";
    rev = "11.0.2";
    hash = "sha256-xAD8H8jkK7RIUez2xzzqh0HHiF2Iaf4ZfGpStjd80Og=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ python ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    src_dir=$out/share/logsmith
    mkdir -p $src_dir $out/bin

    cp -r . $src_dir/

    makeWrapper ${python}/bin/python $out/bin/logsmith \
      --add-flags "$src_dir/app/run.py" \
      --set PYTHONPATH "$src_dir"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Trayicon to assume your favorite AWS roles and manage GCP config";
    homepage = "https://github.com/otto-de/logsmith";
    license = licenses.asl20;
    mainProgram = "logsmith";
  };
}
