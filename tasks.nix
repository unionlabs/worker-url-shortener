{
  fmt.exec = ''
    taplo fmt *.toml
    cargo fmt --all --check
    nixfmt *.nix --width=100
  '';
  lint.exec = ''
    taplo lint *.toml
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
}
