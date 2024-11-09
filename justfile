set shell := ["bash", "-c"]
set dotenv-load := true
set positional-arguments := true
set allow-duplicate-recipes := true
set allow-duplicate-variables := true

fmt:
    just --fmt --unstable
    cargo fmt --all --check
    nixfmt *.nix --width=100

lint:
    cargo clippy --all-targets --all-features

build:
    cargo build --release --target wasm32-unknown-unknown

dev:
    bunx wrangler@latest --config='wrangler.toml' dev

dev-remote:
    bunx wrangler@latest --config='wrangler.toml' dev --remote

deploy:
    bunx wrangler@latest deploy --env='production' --config='wrangler.toml'

clean:
    rm -rf build
    rm -rf target
    rm -rf node_modules
