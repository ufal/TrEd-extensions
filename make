#!/bin/sh

if [ -z "$1" ]; then
   dirs=(*/)
else
   dirs=("$@")
fi

REPO=~pajas/WWW/tred/extensions
PACKER=~pajas/tred-devel/devel/pack_extension.sh

for d in ${dirs[@]%/}; do
    ~/tred-devel/devel/pack_extension.sh "$d" "$REPO"
done
