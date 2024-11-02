# devenv docs https://devenv.sh
{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:

{
  dotenv.enable = true;
  languages.nix.enable = true;

  languages.rust = {
    enable = true;
    channel = "nightly";
    targets = [ "wasm32-unknown-unknown" ];
  };

  pre-commit.hooks = {
    clippy = {
      enable = true;
      settings.offline = false;
      extraPackages = [ pkgs.openssl ];
    };
    rustfmt.enable = true;
  };

  # if you need any tooling/packages throw them in here
  # you can search for available packages here https://search.nixos.org/packages
  packages = with pkgs; [
    jq
    git
    bun
    just
    direnv
    binaryen
    nixfmt-rfc-style
  ];
}
