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
            # TODO: remove inputs
            inherit inputs myLib;
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
          # TODO: rename `all` to `cached` or something
          all = pkgs.linkFarm "mypkgs-all" includedPackages;
          pkgs-update-scripts = packages.update-scripts;
          pkgs-update-scripts-all = packages.update-scripts-all;
          flakes-update-scripts = flakes.update-scripts;
        });
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    hyprlang = {
      url = "github:hyprwm/hyprlang";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprutils.follows = "hyprutils";
      inputs.systems.follows = "systems";
    };

    hyprutils = {
      url = "github:hyprwm/hyprutils";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    hyprwayland-scanner = {
      url = "github:hyprwm/hyprwayland-scanner";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    systems.url = "github:nix-systems/default-linux";

    ####################

    crt = {
      url = "github:spitulax/crt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprlang.follows = "hyprlang";
      inputs.hyprutils.follows = "hyprutils";
      inputs.systems.follows = "systems";
    };

    hyprpaper = {
      url = "github:hyprwm/hyprpaper";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprlang.follows = "hyprlang";
      inputs.hyprutils.follows = "hyprutils";
      inputs.hyprwayland-scanner.follows = "hyprwayland-scanner";
      inputs.systems.follows = "systems";
    };

    hyprpicker = {
      url = "github:hyprwm/hyprpicker";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprutils.follows = "hyprutils";
      inputs.hyprwayland-scanner.follows = "hyprwayland-scanner";
      inputs.systems.follows = "systems";
    };

    hyprpolkitagent = {
      url = "github:hyprwm/hyprpolkitagent";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprutils.follows = "hyprutils";
      inputs.systems.follows = "systems";
    };

    pasteme = {
      url = "github:spitulax/pasteme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
