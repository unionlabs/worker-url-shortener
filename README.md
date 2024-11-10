# URL Shortener - Cloudflare Worker

## Usage

> [!NOTE]
> When running locally use `http://localhost:8787`

### Shorten a URL

```bash
wrangler dev --config='wrangler.toml' dev --preview
```

```bash
curl --url http://localhost:8787/create \
  --request 'POST' \
  --data-binary 'https://docs.union.build/reference/graphql/?query=%7B%20__typename%20%7D'
```

This will return a short id, for example:

```sh
7312a5
```

### Expand a short URL

```bash
curl --url http://localhost:8787/7312a5
```
