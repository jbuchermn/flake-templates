{
  description = "clash starter project on nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    clash.url = "github:clash-lang/clash-compiler";
    clash.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig.allow-import-from-derivation = true; # cabal2nix uses IFD

  outputs = { self, nixpkgs, flake-utils, clash }:
    let
      ghcVer = "ghc9101";
      ghcVerClash = "ghc910";

      topModule = "Sample";
      hdl = "verilog";

      makeHaskellOverlay = overlay: final: prev: {
        haskell = prev.haskell // {
          packages = prev.haskell.packages // {
            ${ghcVer} = prev.haskell.packages."${ghcVer}".override (oldArgs: {
              overrides =
                prev.lib.composeExtensions (oldArgs.overrides or (_: _: { }))
                  (overlay prev);
            });
          };
        };
      };

      out = system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              clash.overlays.${ghcVerClash}
              self.overlays.default
            ];
            config.allowBroken = true;
          };

        in
        {
          # Use this to debug packages in nix repl
          # debug-pkgs = pkgs;

          packages = rec {
            default = sample;
            sample = pkgs.haskell.packages.${ghcVer}.sample;
          };

          checks = {
            inherit (self.packages.${system}) sample;
          };

          devShells.default =
            let
              haskellPackages = pkgs.haskell.packages.${ghcVer};
            in
            haskellPackages.shellFor {
              packages = p: [
                self.packages.${system}.sample
              ];

              buildInputs = with haskellPackages; [
                clash-ghc

                cabal-install
                haskell-language-server
              ];

              withHoogle = true;
            };
        };
    in
    flake-utils.lib.eachDefaultSystem out // {
      overlays = {
        default = makeHaskellOverlay
          (prev: hfinal: hprev:
            {
              inherit (prev."clashPackages-${ghcVerClash}")
                clash-ghc
                clash-prelude
                clash-lib
                ghc-typelits-natnormalise
                ghc-typelits-knownnat
                ghc-typelits-extra
                ;

              sample =
                let
                  hs-build = hprev.callCabal2nix "sample" ./. { };
                in
                prev.haskell.lib.overrideCabal hs-build (drv: {
                  enableLibraryProfiling = false;

                  buildTools = [
                    hfinal.clash-ghc
                  ];

                  postBuild = ''
                    clash ${topModule} --${hdl} \
                        -package-db dist/package.conf.inplace
                  '';

                  postInstall = ''
                    mkdir -p "$out/share"
                    cp -r "${hdl}/" "$out/share/${hdl}"
                  '';
                });
            }
          );
      };
    };
}

