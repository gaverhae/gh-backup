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

mkdir -p $DIR/_backups

TODAY=$(date -I)

if [ -d "$DIR"/_backups/$TODAY.tar.gz ]; then
  echo "Backup already done today."
  exit 1
fi

tmp=$(mktemp -d)
trap "rm -rf $tmp" EXIT

mkdir $tmp/$TODAY
cd $tmp/$TODAY

get_repos() (
  url=https://api.github.com/user/repos
  auth="Authorization: Bearer $GITHUB_TOKEN"
  tmp_dir=$(mktemp -d)
  trap "rm -rf $tmp_dir" EXIT
  while [ -n "$url" ]; do
    curl $url \
         -H "$auth" \
         -H "Accept: application/vnd.github+json" \
         -H "X-GitHub-Api-Version: 2022-11-28" \
         --silent \
         --fail \
         -o >(jq -r '.[].ssh_url' >> $tmp_dir/resp) \
         -D $tmp_dir/headers
    url=$(cat $tmp_dir/headers \
           | tr -d '\r' \
           | grep "link:" \
           | grep -Po '(?<=<)([^>]*)(?=>; rel="next")' \
           || true)
  done
  cat $tmp_dir/resp
)

REPOS=$(get_repos)

log=$(mktemp)
for r in $REPOS; do
  echo $r | sed 's/git@github.com://'
  if ! git clone --bare $r >$log 2>&1; then
    echo "Something went wrong. Output from git clone:"
    echo "--"
    cat $log
    echo "--"
    exit 1
  fi
done

cd ..

tar -I 'gzip -9' -cf $TODAY.tar.gz $TODAY
mv $TODAY.tar.gz "$DIR"/_backups/
