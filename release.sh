#! /bin/bash
EXTDIR=`dirname $(readlink -fen $0)`
. "$EXTDIR"/../admin/env.sh

WWW_TRED="$WWW"/tred
WWW_EXT=ufal:/home/pajas/WWW/tred/extensions/

for ext ; do
    rsync --exclude='*/.svn*' -avr "$WWW_TRED"/extensions/{$ext.zip,$ext/,index.html} "$WWW_EXT"
done