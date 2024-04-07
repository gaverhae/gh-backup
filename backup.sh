#!/usr/bin/env bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "This script requires a GitHub token in the GITHUB_TOKEN env var."
  echo "You can set it by adding the following line to .envrc.private:"
  echo
  echo "export GITHUB_TOKEN=<your token>"
  echo
  echo "The token should have metadata read access to all the repositories you"
  echo "want to backup."
  exit 1
fi

TODAY=$(date -I)

if [ -d "$DIR"/_backups/$TODAY.tar.gz ]; then
  echo "Backup already done today."
  exit 1
fi

tmp=$(mktemp -d)
trap "rm -rf $tmp" EXIT

mkdir $tmp/$TODAY
cd $tmp/$TODAY

REPOS=$(curl --silent \
             -H "Authorization: Bearer $GITHUB_TOKEN" \
             https://api.github.com/user/repos \
        | jq -r '.[].ssh_url')

for r in $REPOS; do
  echo $r
  git clone --bare $r
done

cd ..

GZIP=-9 tar czf $TODAY.tar.gz $TODAY
mv $TODAY.tar.gz "$DIR"/_backups/
