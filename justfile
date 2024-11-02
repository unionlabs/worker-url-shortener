set shell := ["bash", "-c"]
set dotenv-load
set positional-arguments
set allow-duplicate-recipes
set allow-duplicate-variables

fmt:
  cargo fmt

lint:
  cargo clippy

build:
  cargo build --release --target wasm32-unknown-unknown

dev:
  wrangler --config='wrangler.toml' dev

dev-remote:
  wrangler --config='wrangler.toml' dev --remote

deploy:
  wrangler deploy --env='production' --config='wrangler.toml'

clean:
  rm -rf build
  rm -rf target
  rm -rf node_modules
