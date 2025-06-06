{
  pkgs ? import <nixpkgs> { },
  zig ? import ./zig.nix {
    stdenv = pkgs.stdenv;
    fetchzip = pkgs.fetchzip;
  },
}:

pkgs.stdenv.mkDerivation {
  name = "parse-lisp-perhaps";
  src = ./.;

  # unpackPhase = ''
  #   for srcFile in $src; do
  #       cp -r $srcFile $(stripHash $srcFile)
  #   done
  # '';

  nativeBuildInputs = [
    zig
  ];

  # configurePhase = ''

  # '';

  buildPhase = ''
    export ZIG_LOCAL_CACHE_DIR=$TMPDIR
    export ZIG_GLOBAL_CACHE_DIR=$TMPDIR

    zig build -femit-bin=$TMPDIR/zig-out
  '';

  installPhase = ''
    cp $TMPDIR/zig-out/bin/parse-lisp-perhaps $out/bin
  '';
}
