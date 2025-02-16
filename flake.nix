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
              stdenv = pkgs.stdenvNoCC;
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
          zig-dev = (
            import ./zig.nix {
              stdenv = pkgs.stdenvNoCC;
              fetchzip = pkgs.fetchzip;
            }
          );
          zls-dev = (
            import ./zls.nix {
              stdenv = pkgs.stdenvNoCC;
              fetchzip = pkgs.fetchzip;
            }
          );
        in
        {
          default = pkgs.mkShell {
            packages = [
              zig-dev
              zls-dev
              pkgs.wakatime-cli
            ];
          };
        }
      );
    };
}
