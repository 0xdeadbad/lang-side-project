{
  stdenv,
  fetchzip,
}:
let
  version = "0.15.1";
in
stdenv.mkDerivation {
  pname = "zig-bin";
  version = "${version}";

  src = fetchzip {
    url = "ziglang.org/download/${version}/zig-x86_64-linux-${version}.tar.xz";
    hash = "sha256-4IDg2hjtCLT5QyzVCiYCy7Hg541tWv7ZAOVJHBQRWXk=";
  };

  phases = [
    "unpackPhase"
    "installPhase"
  ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/lib

    cp zig $out/bin
    cp -r lib $out/lib/zig
  '';
}
