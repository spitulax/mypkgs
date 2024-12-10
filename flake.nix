{
  description = "My nix packages";

  nixConfig = {
    extra-substituters = [
      "spitulax.cachix.org"
    ];
    extra-trusted-public-keys = [
      "spitulax.cachix.org-1:GQRdtUgc9vwHTkfukneFHFXLPOo0G/2lj2nRw66ENmU="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      inherit (self) outputs;
      inherit (nixpkgs) lib;
      myLib = import ./lib { inherit lib; };

      systems = [ "x86_64-linux" "aarch64-linux" ];
      eachSystem = f: lib.genAttrs systems f;
      foreachSystem = f: lib.genAttrs systems f;

      pkgsFor = foreachSystem (system:
        import nixpkgs {
          inherit system;
        });
      utilsFor = foreachSystem
        (system:
          pkgsFor.${system}.callPackage ./utils { inherit myLib outputs; }
        );

      packagesFor = foreachSystem
        (system:
          import ./pkgs {
            inherit myLib;
            pkgs = pkgsFor.${system};
            utils = utilsFor.${system};
          }
        );
      flakesFor = foreachSystem
        (system:
          import ./flakes {
            inherit myLib;
            pkgs = pkgsFor.${system};
            utils = utilsFor.${system};
          }
        );
    in
    {
      flakes = lib.mapAttrs (_: v: v.flakes) flakesFor;

      packages = eachSystem (system:
        let
          pkgs = pkgsFor.${system};
          packages = packagesFor.${system};
          flakes = flakesFor.${system};
          includedPackages = myLib.includedPackages packages.packages;
          excludedPackages = myLib.excludedPackages packages.packages;
        in
        includedPackages
        // excludedPackages
        # Only non-excluded packages are regularly cached
        // {
          cached = pkgs.linkFarm "mypkgs-cached" includedPackages;
          pkgs-update-scripts = packages.update-scripts;
          pkgs-update-scripts-all = packages.update-scripts-all;
          flakes-update-scripts = flakes.update-scripts;
        });
    };
}
