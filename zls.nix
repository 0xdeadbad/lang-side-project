{
  stdenv,
  fetchzip,
}:
let
  version = "0.15.0";
in
stdenv.mkDerivation {
  pname = "zls-bin";
  version = "${version}";

  src = fetchzip {
    url = "https://builds.zigtools.org/zls-x86_64-linux-${version}.tar.xz";
    hash = "sha256-GtLRQuS8Jw8ltVT5mpZxmfAewQu5eXmk8d0Gh5ROtMk=";
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
