# short urls 🐻 📉

## Usage

> [!NOTE]
> When running locally, replace `https://shorted.unionlabs.workers.dev` with `http://localhost:8787`

### Shorten a URL

```bash
curl --url https://shorted.unionlabs.workers.dev/create \
  --request 'POST' \
  # TODO switch to application/json
  --header 'Content-Type: text' \
  --header 'Origin: https://docs.union.build' \
  --data-binary 'https://docs.union.build/reference/graphql/?query=%7B%20__typename%20%7D'
```

This will return a short id, for example:

```sh
7312a5
```

### Expand a short URL

```bash
curl --url https://shorted.unionlabs.workers.dev/7312a5
```
