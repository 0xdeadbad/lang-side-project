{
  pkgs ? import <nixpkgs> { },
}:
let
  zig-dev = (
    import ./zig.nix {
      stdenv = pkgs.stdenv;
      fetchzip = pkgs.fetchzip;
    }
  );
  zls-dev = (
    import ./zls.nix {
      stdenv = pkgs.stdenvNoCC;
      fetchzip = pkgs.fetchzip;
    }
  );
  wakatime = pkgs.wakatime-cli;
  tree-sitter-zig = (with pkgs; tree-sitter-grammars.tree-sitter-zig);
in
pkgs.mkShell {
  packages = [
    zig-dev
    zls-dev
    wakatime
    tree-sitter-zig
  ];
}
