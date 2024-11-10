{
  description = "URL Shortener Worker";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";

    systems.url = "github:nix-systems/default";

    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";

    flake-root.url = "github:srid/flake-root";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      self,
      devenv,
      systems,
      treefmt-nix,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;
      imports = [
        inputs.devenv.flakeModule
        inputs.flake-root.flakeModule
        inputs.treefmt-nix.flakeModule
      ];
      perSystem =
        {
          config,
          self',
          pkgs,
          ...
        }:
        {
          treefmt.config = import ./treefmt.nix { inherit pkgs config treefmt-nix; };

          formatter = config.treefmt.build.wrapper;
          checks.formatting = config.treefmt.build.check self;

          packages.devenv-up = self'.devShells.default.config.procfileScript;

          devShells.default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              {
                scripts = import ./tasks.nix;
                dotenv.enable = true;
                languages.nix.enable = true;
                languages.rust = {
                  enable = true;
                  channel = "nightly";
                  targets = [ "wasm32-unknown-unknown" ];
                  components = [
                    "rustc"
                    "cargo"
                    "clippy"
                    "rustfmt"
                    "rust-analyzer"
                  ];
                };

                env.D1_DATABASE_FILEPATH =
                  let
                    dbDir = ".wrangler/state/v3/d1/miniflare-D1DatabaseObject";
                  in
                  "${dbDir}/$(${pkgs.findutils}/bin/find ${dbDir} -maxdepth 1 -name '*.sqlite' ! -name '*-shm' ! -name '*-wal' -printf '%f\n' | head -n1)";

                packages = with pkgs; [
                  jq
                  git
                  bun
                  direnv
                  sqlite
                  binaryen
                  nodePackages_latest.nodejs
                  taplo
                  deadnix
                  sqlfluff
                  nixfmt-rfc-style
                ];
              }
            ];
          };
        };
    };

  nixConfig = {
    extra-substituters = "https://devenv.cachix.org";
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
  };
}
