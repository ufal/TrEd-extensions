#!/bin/bash

EXTDIR=`dirname $(readlink -fen $0)`
CURDIR=$(readlink -fen $PWD)

if [ -z "$1" ]; then
    if [ "$EXTDIR" != "$CURDIR" ]; then
	echo "Usage: ./make package_dir ... " 1>&2
	echo "No argument version only allowed from $EXTDIR!" 1>&2
	exit 1;
    fi
    dirs=(*/)
else
   dirs=("$@")
fi

WWW=~pajas/WWW/tred
REPO=$WWW/extensions
DEVEL=$(readlink -fen $EXTDIR/../tred/devel)
PACKER=$DEVEL/pack_extension.sh


for d in "${dirs[@]%/}"; do
    echo "*** Building extension $d"
    if ! grep -q "$d" "$REPO"/extensions.lst; then
	echo "Adding $d to extensions.lst"
	echo "$d" >> "$REPO"/extensions.lst
    fi

    if [ -f ".make.d/$d" ]; then
	( . ".make.d/$d" )
    fi

    "$PACKER" "$d" "$REPO"

done

# update repository HTML index
(
cd $REPO;
echo '<extensions>';
for d in `cat extensions.lst |grep -v '^!' | grep -E '^\s*(-|\w)+\s*$'`; do
    if [ -f "$d/package.xml" ]; then
	cat "$d/package.xml" |grep -v '^<?xml'
    fi
done;
echo '</extensions>';
) | xsltproc "$EXTDIR"/package2html.xsl - > "$REPO/index.html"

