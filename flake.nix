{
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
                packages = with pkgs; [
                  jq
                  git
                  bun
                  just
                  direnv
                  binaryen
                  nixfmt-rfc-style
                  nodePackages_latest.nodejs
                ];
                scripts = {
                  fmt.exec = ''
                    nixfmt *.nix --width=100
                    just --fmt --unstable
                    cargo fmt --all --check
                  '';
                  lint.exec = ''
                    cargo clippy --all-targets --all-features
                  '';
                  build.exec = ''
                    cargo build --release --target wasm32-unknown-unknown
                  '';
                  dev.exec = ''
                    bunx wrangler@latest --config='wrangler.toml' dev
                  '';
                  dev-remote.exec = ''
                    bunx wrangler@latest --config='wrangler.toml' dev --remote
                  '';
                  deploy.exec = ''
                    bunx wrangler@latest deploy --env='production' --config='wrangler.toml'
                  '';
                  clean.exec = ''
                    rm -rf build
                    rm -rf target
                    rm -rf node_modules
                  '';
                };
                enterShell = '''';

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
