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
        in
        packages // {
          all = pkgs.linkFarm "all" (builtins.removeAttrs self.packages.${system} [ "all" ]);
        });
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    waybar = {
      url = "github:Alexays/Waybar";
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

    odin = {
      url = "github:odin-lang/Odin";
      flake = false;
    };

    ols = {
      url = "github:DanielGavin/ols";
      flake = false;
    };
  };
}
