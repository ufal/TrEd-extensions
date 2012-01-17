#! /bin/bash
EXTDIR=`dirname $(readlink -fen $0)`
. "$EXTDIR"/../admin/env.sh

WWW_TRED="$WWW"/tred
WWW_EXT=ufal:/home/pajas/WWW/tred/extensions/

for ext ; do
    ext=${ext%/}
    rsync --exclude='*/.svn*' -avr "$WWW_TRED"/extensions/{$ext.zip,$ext,index.html} "$WWW_EXT"
    wget http://ufal.ms.mff.cuni.cz/~pajas/tred/extensions/extensions.lst -O- | grep -q "^$ext$" || echo "PROBLEM: $ext missing in file \`extensions.lst' at the server!" >&2
done

