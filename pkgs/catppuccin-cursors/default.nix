{ pkgs
, lib
, palettes ? [ ] # "frappe" "latte" "macchiato" "mocha"
, colors ? [ ] # "blue" "dark" "flamingo" "green" "lavender" "light" "maroon" "mauve" "peach" "pink" "red" "rosewater" "sapphire" "sky" "teal" "yellow"
}:
with lib;
let
  variants = mapCartesianProduct
    ({ palettes, colors }: palettes + colors)
    {
      palettes = map toLower palettes;
      colors =
        map
          (x:
            let
              x' = stringToCharacters x;
            in
            toUpper (head x') + toLower (concatStrings (tail x')))
          colors;
    };
  mkArgs = xs: "'" + concatStringsSep " " (map toLower xs) + "'";
in
pkgs.catppuccin-cursors.overrideAttrs (newAttrs: oldAttrs: {
  outputs = variants ++ [ "out" ];

  buildPhase = ''
    runHook preBuild

    patchShebangs .

    just build ${mkArgs palettes} ${mkArgs colors}

    runHook postBuild
  '';
})
