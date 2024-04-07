#!/usr/bin/env bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

TODAY=$(date -I)

if [ -d "$DIR"/_backups/$TODAY.tar.gz ]; then
    echo "Backup already done?"
    exit 1
fi

tmp=$(mktemp -d)
trap "rm -rf $tmp" EXIT

mkdir $tmp/$TODAY
cd $tmp/$TODAY

REPOS=$(curl -s 'https://api.github.com/users/gaverhae/repos' | jq -r '.[].ssh_url')

for r in $REPOS; do
    git clone --bare $r
done

cd ..

GZIP=-9 tar czf $TODAY.tar.gz $TODAY
mv $TODAY.tar.gz "$DIR"/_backups/
