{
  description = "URL Shortener Worker";
  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";

    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";

    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      devenv,
      nixpkgs,
      systems,
      ...
    }@inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      });
      devShells = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              {
                # https://devenv.sh/reference/options/
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

                # for development only
                # this is the default location when you run d1 with `--local`
                env.D1_DATABASE_FILEPATH =
                  let
                    dbDir = ".wrangler/state/v3/d1/miniflare-D1DatabaseObject";
                  in
                  "${dbDir}/$(${pkgs.findutils}/bin/find ${dbDir} -maxdepth 1 -name '*.sqlite' ! -name '*-shm' ! -name '*-wal' -printf '%f\n' | head -n1)";

                packages = with pkgs; [
                  jq
                  git
                  bun
                  taplo
                  direnv
                  sqlite
                  deadnix
                  sqlfluff
                  binaryen
                  nixfmt-rfc-style
                  nodePackages_latest.nodejs
                ];
              }
            ];
          };
        }
      );
    };

  nixConfig = {
    extra-substituters = "https://devenv.cachix.org";
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
  };

}
