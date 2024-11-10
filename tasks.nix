{
  wrangler.exec = ''
    bunx wrangler@latest --config='wrangler.toml' "$@"
  '';
  fmt.exec = ''
    taplo fmt *.toml
    nixfmt *.nix --width=100
    cargo fmt --all -- --config-path=rustfmt.toml
    sqlfluff format --dialect sqlite ./schema.sql
  '';
  lint.exec = ''
    taplo lint *.toml
    cargo clippy --all-targets --all-features
    sqlfluff lint --dialect sqlite ./schema.sql
    deadnix --no-lambda-pattern-names && statix check .
  '';
  build.exec = ''
    cargo build --release --target wasm32-unknown-unknown
  '';
  # optional: `--remote`
  dev.exec = ''
    bunx wrangler@latest --config='wrangler.toml' dev "$@"
  '';
  d1-create-database.exec = ''
    bunx wrangler@latest --config='wrangler.toml' d1 create url-short-d1 "$@"
  '';
  # optional: `--local`, `--remote`
  d1-bootstrap.exec = ''
    bunx wrangler@latest --config='wrangler.toml' d1 execute url-short-d1 --file='schema.sql'
  '';
  # optional: `--local`, `--remote`
  # required: `--command="SELECT * FROM urls"`
  d1-query.exec = ''
    bunx wrangler@latest --config='wrangler.toml' d1 execute url-short-d1 "$@"
  '';
  d1-seed.exec = ''
    bash ./scripts/seed.sh
  '';
  # only works locally in development
  d1-viewer.exec = ''
    bunx @outerbase/studio@latest $(eval echo $D1_DATABASE_FILEPATH) --port=4000
  '';
  deploy.exec = ''
    bunx wrangler@latest deploy --env='production' --config='wrangler.toml'
  '';
  rustdoc.exec = ''
    cargo rustdoc -- --default-theme='ayu'
  '';
  clean.exec = ''
    rm -rf build
    rm -rf target
    rm -rf node_modules
  '';
}
