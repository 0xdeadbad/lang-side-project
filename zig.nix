{
  stdenv,
  fetchzip,
}:

stdenv.mkDerivation {
  pname = "Zig master branch build";
  version = "0.14.0-dev.3222+8a3aebaee";

  outputs = [
    "out"
    "lib"
    "doc"
  ];

  src = fetchzip {
    url = "https://ziglang.org/builds/zig-linux-x86-0.14.0-dev.3222+8a3aebaee.tar.xz";
    hash = "sha256-lb7WUbESmuQ7KDxMvJ4OdKa6K6+elE0sOrZw5WuCjqI=";
  };

  phases = [
    "unpackPhase"
    "installPhase"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp zig $out/bin
    cp -r lib $out
    cp -r doc $out
  '';
}
