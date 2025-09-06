{
  description = "Zig dev env";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.unix;

      nixpkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          config = { };
          overlays = [ ];
        }
      );
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor."${system}";
          zig = (
            import ./zig.nix {
              stdenv = pkgs.stdenv;
              fetchzip = pkgs.fetchzip;
            }
          );
          zls = (
            import ./zls.nix {
              stdenv = pkgs.stdenvNoCC;
              fetchzip = pkgs.fetchzip;
            }
          );
        in
        {
          default = zig;
          zig = zig;
          zls = zls;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor."${system}";
          mkShell = pkgs.mkShell;
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
        {
          default = (
            import ./shell.nix {
              inherit pkgs;
            }
          );
        }
      );
    };
}
