{
  pkgs,
  config,
  ...
}:
{
  inherit (config.flake-root) projectRootFile;
  package = pkgs.treefmt;
  programs = {
    taplo.enable = true;
    statix.enable = true;
    nixfmt.enable = true;
    rustfmt.enable = true;
    yamlfmt.enable = true;
    deadnix.enable = true;
    mdformat.enable = true;
    actionlint.enable = true;
    shellcheck.enable = true;
  };
  #
  settings = {
    formatter = {
      "sqlfluff-format" = {
        command = "sqlfluff";
        includes = [ "*.sql" ];
        options = [
          # `--dialect sqlite`
          "format"
          "--dialect=sqlite"
          "schema.sql"

        ];
      };
      actionlint.options = [
        "--help"
      ];

      nixfmt = {
        options = [ ];
        includes = [ "*.nix" ];
      };
      shellcheck.options = [
        "--shell=bash"
        "--check-sourced"
      ];
      yamlfmt.options = [
        "-formatter"
        "retain_line_breaks=true"
      ];
      statix.options = [ "explain" ];
      mdformat.options = [ "--number" ];
    };
    global = {
      hidden = true;
      excludes = [

      ];
    };
  };

}
