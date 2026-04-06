{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    # This pins requirements.txt provided by zephyr-nix.pythonEnv.
    zephyr.url = "github:zmkfirmware/zephyr/v3.5.0+zmk-fixes";
    zephyr.flake = false;

    # Zephyr sdk and toolchain (used by devShell).
    zephyr-nix.url = "github:nix-community/zephyr-nix";
    zephyr-nix.inputs.zephyr.follows = "zephyr";
    zephyr-nix.inputs.nixpkgs.follows = "nixpkgs";

    # ZMK Nix build system.
    zmk-nix.url = "github:lilyinstarlight/zmk-nix";
    zmk-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        {
          pkgs,
          system,
          ...
        }:
        let
          inherit (inputs.nixpkgs) lib;
          builders = inputs.zmk-nix.legacyPackages.${system};
          zephyr = inputs.zephyr-nix.packages.${system};

          # Source files relevant to ZMK builds.
          src = lib.sourceFilesBySuffices inputs.self [
            ".board"
            ".cmake"
            ".conf"
            ".defconfig"
            ".dts"
            ".dtsi"
            ".json"
            ".keymap"
            ".overlay"
            ".shield"
            ".yml"
            "_defconfig"
          ];

          zephyrDepsHash = "sha256-Z1vYgRGa7zZS67pdwgqq+suyDDKKBfinMnG/NsN1mw0=";
        in
        {
          # ── Formatters ────────────────────────────────────────────────────────
          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.yamlfmt.enable = true;
          };

          # ── Packages ──────────────────────────────────────────────────────────
          packages = rec {
            # Left half with ZMK Studio enabled.
            firmware-left = builders.buildKeyboard {
              inherit src zephyrDepsHash;
              name = "firmware-left";
              board = "eyelash_sofle_left";
              shield = "nice_view";
              enableZmkStudio = true;
              extraCmakeFlags = [ "-DCONFIG_ZMK_STUDIO_LOCKING=n" ];
              meta = {
                description = "Eyelash Sofle left half firmware (ZMK Studio)";
                license = lib.licenses.mit;
                platforms = lib.platforms.all;
              };
            };

            # Right half.
            firmware-right = builders.buildKeyboard {
              inherit src zephyrDepsHash;
              name = "firmware-right";
              board = "eyelash_sofle_right";
              shield = "nice_view";
              meta = {
                description = "Eyelash Sofle right half firmware";
                license = lib.licenses.mit;
                platforms = lib.platforms.all;
              };
            };

            # Settings reset firmware (used to clear bluetooth bonds).
            firmware-reset = builders.buildKeyboard {
              inherit src zephyrDepsHash;
              name = "firmware-reset";
              board = "nice_nano_v2";
              shield = "settings_reset";
              meta = {
                description = "Settings reset firmware for nice!nano v2";
                license = lib.licenses.mit;
                platforms = lib.platforms.all;
              };
            };

            # Default: all three firmware files in one directory with distinct names.
            default =
              let
                rename =
                  drv: filename:
                  pkgs.runCommand filename { } ''
                    mkdir -p $out
                    cp ${drv}/zmk.uf2 $out/${filename}
                  '';
              in
              pkgs.symlinkJoin {
                name = "eyelash-sofle-firmware";
                paths = [
                  (rename firmware-left "eyelash_sofle_left.uf2")
                  (rename firmware-right "eyelash_sofle_right.uf2")
                  (rename firmware-reset "settings_reset.uf2")
                ];
              };
          };

          # ── Dev shells ────────────────────────────────────────────────────────
          devShells =
            let
              keymap_drawer = pkgs.python3Packages.callPackage ./nix/keymap-drawer.nix { };
            in
            {
              # Shell for just/west local build workflow.
              default = pkgs.mkShellNoCC {
                packages = [
                  zephyr.pythonEnv
                  (zephyr.sdk-0_16.override { targets = [ "arm-zephyr-eabi" ]; })

                  pkgs.cmake
                  pkgs.dtc
                  pkgs.gcc
                  pkgs.ninja

                  pkgs.just
                  pkgs.yq # Make sure yq resolves to python-yq.

                  keymap_drawer

                  # -- Used by just_recipes and west_commands. Most systems already have them. --
                  # pkgs.gawk
                  # pkgs.unixtools.column
                  # pkgs.coreutils # cp, cut, echo, mkdir, sort, tail, tee, uniq, wc
                  # pkgs.diffutils
                  # pkgs.findutils # find, xargs
                  # pkgs.gnugrep
                  # pkgs.gnused
                ];

                env = {
                  PYTHONPATH = "${zephyr.pythonEnv}/${zephyr.pythonEnv.sitePackages}";
                };

                shellHook = ''
                  export ZMK_BUILD_DIR=$(pwd)/.build;
                  export ZMK_SRC_DIR=$(pwd)/zmk/app;
                '';
              };

              # zmk-nix's own devShell (alternative to the above).
              zmk-nix = inputs.zmk-nix.devShells.${system}.default;
            };
        };
    };
}
