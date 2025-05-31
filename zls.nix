{
  stdenv,
  fetchzip,
}:

stdenv.mkDerivation {
  pname = "zls-bin";
  version = "0.14.0";

  src = fetchzip {
    url = "https://builds.zigtools.org/zls-linux-x86_64-0.14.0.tar.xz";
    hash = "sha256-8SwZ8BqqjB15bXhimWUqfWiQogmS0twbvehqVLzR7dw=";
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
