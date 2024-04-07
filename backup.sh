#!/usr/bin/env bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR

TODAY=$(date -I)

if [ -d $TODAY ]; then
    echo "Backup already done?"
    exit 1
fi

mkdir $TODAY
cd $TODAY

REPOS=$(curl -s 'https://api.github.com/users/gaverhae/repos' | jq -r '.[].ssh_url')

for r in $REPOS; do
    git clone --bare $r
done

cd ..

GZIP=-9 tar czf $TODAY.tar.gz $TODAY
rm -rf $TODAY
