{
  stdenv,
  fetchzip,
}:

stdenv.mkDerivation {
  pname = "Zig master branch build";
  version = "0.14.0-dev.3271+bd237bced";

  src = fetchzip {
    url = "https://ziglang.org/builds/zig-linux-x86_64-0.14.0-dev.3271+bd237bced.tar.xz";
    hash = "sha256-eICnZSd/aYOmUJ8HJqzSoQN1EIuU80GOa47W/7tOysM=";
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
