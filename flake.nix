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

    waybar = {
      url = "github:Alexays/Waybar/0.11.0"; # TEMP: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/wa/waybar/package.nix
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crt = {
      url = "github:spitulax/crt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gripper = {
      url = "github:spitulax/gripper";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ols = {
      url = "github:DanielGavin/ols";
      flake = false;
    };

    pasteme = {
      url = "github:spitulax/pasteme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
