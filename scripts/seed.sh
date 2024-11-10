#!/usr/bin/env bash
set -euo pipefail

# seed local d1 database with data

urls=(
  "https://docs.union.build/reference/graphql/?query=%7B__typename%7D"
  "https://docs.union.build/reference/graphql/?query=%7B%0A%20%20v1_daily_transfers%20%7B%0A%20%20%20%20count%0A%20%20%20%20day%0A%20%20%7D%0A%7D"
  "https://docs.union.build/reference/graphql/?query=%7B%0A%20%20get_route(%0A%20%20%20%20args%3A%20%7Bdestination_chain_id%3A%20%22stride-internal-1%22%2C%20receiver%3A%20%22me%22%2C%20source_chain_id%3A%20%2211155111%22%2C%20forward_chain_id%3A%20%22union-testnet-8%22%7D%0A%20%20)%20%7B%0A%20%20%20%20memo%0A%20%20%7D%0A%7D"
)

for url in "${urls[@]}"; do
  d1-query --local --command="INSERT INTO urls (url) VALUES ('$url');"
done
