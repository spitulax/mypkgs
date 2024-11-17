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
      inherit (nixpkgs) lib;
      systems = [ "x86_64-linux" "aarch64-linux" ];
      eachSystem = f: lib.genAttrs systems f;
      myLib = import ./lib { inherit lib; };
      pkgsFor = eachSystem (system:
        import nixpkgs {
          inherit system;
        });
    in
    {
      packages = eachSystem (system:
        let
          pkgs = pkgsFor.${system};
          packages = import ./pkgs { inherit inputs pkgs myLib; };
          excludedPackages = lib.filterAttrs (_: v: v ? excluded && v.excluded) packages;
          includedPackages = lib.filterAttrs (_: v: !(v ? excluded) || !v.excluded) packages;
        in
        includedPackages
        // {
          all = pkgs.linkFarm "all" includedPackages;
        }
        // lib.mapAttrs (_: v: v.derivation) excludedPackages);
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

    hyprland-protocols = {
      url = "github:hyprwm/hyprland-protocols";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    systems.url = "github:nix-systems/default-linux";

    ####################

    crt = {
      url = "github:spitulax/crt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gripper = {
      url = "github:spitulax/gripper";
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

    hyprsunset = {
      url = "github:hyprwm/hyprsunset";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprutils.follows = "hyprutils";
      inputs.hyprwayland-scanner.follows = "hyprwayland-scanner";
      inputs.hyprland-protocols.follows = "hyprland-protocols";
      inputs.systems.follows = "systems";
    };

    ols = {
      url = "github:DanielGavin/ols";
      flake = false;
    };

    pasteme = {
      url = "github:spitulax/pasteme";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    waybar = {
      url = "github:Alexays/Waybar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
