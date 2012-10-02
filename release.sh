#! /bin/bash
EXTDIR=`dirname $(readlink -fen $0)`
. "$EXTDIR"/../admin/env.sh

WWW_TRED="$WWW"/tred
WWW_EXT=ufal:/home/www/html/tred/extensions/core/

for ext ; do
    ext=${ext%/}
    rsync --exclude='*/.svn*' -avr "$WWW_TRED"/extensions/{$ext.zip,$ext,index.html} "$WWW_EXT"
    wget http://ufal.ms.mff.cuni.cz/tred/extensions/core/extensions.lst -O- | grep -q "^$ext$" || echo "PROBLEM: $ext missing in file \`extensions.lst' at the server!" >&2
done

