{
  stdenv,
  fetchzip,
}:

stdenv.mkDerivation {
  pname = "zig-bin";
  version = "0.14.1";

  src = fetchzip {
    url = "https://ziglang.org/download/0.14.1/zig-x86_64-linux-0.14.1.tar.xz";
    hash = "sha256-4DtFNXBw+dDE6xClV+NFOTMn5Fn0g19i3mpE/bN4Qyk=";
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
