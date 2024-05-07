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
      pkgsFor = eachSystem (system:
        import nixpkgs {
          inherit system;
        });
    in
    {
      packages = eachSystem (system:
        let
          pkgs = pkgsFor.${system};
          packages = import ./pkgs { inherit inputs pkgs; };
        in
        packages // {
          all = pkgs.symlinkJoin {
            name = "all";
            paths = builtins.attrValues packages;
          };
        });
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    waybar.url = "github:Alexays/Waybar";
    waybar.inputs.nixpkgs.follows = "nixpkgs";

    hyprlock.url = "github:hyprwm/hyprlock";
    hyprlock.inputs.nixpkgs.follows = "nixpkgs";
  };
}
