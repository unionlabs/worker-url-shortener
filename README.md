# URL Shortener - Cloudflare Worker

## Development

### Prerequisites

You have two options:

Option one (recommended):

- [install](https://devenv.sh/getting-started/) `devenv` && run `devenv up`
- done.

Now you can run `dev`, `fmt`, etc. (tasks are defined in [`tasks.nix`](./tasks.nix))

Option two: follow Cloudflare's [guide](https://developers.cloudflare.com/workers/languages/rust/)

- [install `Node.js`](https://nodejs.org/en/learn/getting-started/how-to-install-nodejs)
- [install `wrangler`](https://bun.sh/docs/installation)
- [install `rust`](https://www.rust-lang.org/tools/install)

> [!NOTE]
> the rest of the guide assumes you're using `devenv`
>
> if you're installing stuff manully,
> take a look at [`tasks.nix`](./tasks.nix) for the commands

Once you've installed the prerequisites, you can run:

dev server

```bash
dev
```

rowser-based sqlite viewer

```bash
d1-viewer
```

seed local d1 database with data

```bash
d1-seed
```

shorten a URL

```bash
curl --url http://localhost:8787/create \
  --request 'POST' \
  --data-binary 'https://docs.union.build/reference/graphql/?query=%7B%20__typename%20%7D'
```

now refresh the d1 viewer page and you should see the new record

## Usage

> [!NOTE]
> When running locally use `http://localhost:8787`

### Shorten a URL

```bash
curl --url http://localhost:8787/create \
  --request 'POST' \
  --data-binary 'https://docs.union.build/reference/graphql/?query=%7B%20__typename%20%7D'
```

This will return a short the shortened URL, for example:

```sh
# example
https://localhost/26
```

### Expand a short URL

```bash
curl --url http://localhost:8787/26
```
