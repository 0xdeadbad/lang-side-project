{
  stdenv,
  fetchzip,
}:

stdenv.mkDerivation {
  pname = "ZLS master branch build";
  version = "0.14.0-dev.3222+8a3aebaee";

  src = fetchzip {
    url = "https://builds.zigtools.org/zls-linux-x86_64-0.14.0-dev.390+188a4c0.tar.xz";
    hash = "sha256-NwWsOdC49RCnmUi+tOtU+RvJRP3hpfpFK5oxyUeuc/c=";
    stripRoot = false;
  };

  phases = [
    "unpackPhase"
    "installPhase"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp zls $out/bin
  '';
}
