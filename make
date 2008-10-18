#!/bin/sh

if [ -z "$1" ]; then
   cd `dirname $0`
   dirs=(*/)
else
   dirs=("$@")
fi

WWW=~pajas/WWW/tred
REPO=$WWW/extensions
DEVEL=~pajas/tred-devel/devel
PACKER=$DEVEL/pack_extension.sh
EXTDIR=`dirname $(readlink -fen $0)`
pod2xhtml=$DEVEL/pod_to_xhtml


for d in "${dirs[@]%/}"; do
    ~/tred-devel/devel/pack_extension.sh "$d" "$REPO"
done

(
cd $REPO;
echo '<extensions>';
for d in `cat extensions.lst |grep -v '^!' | grep -E '^\s*(-|\w)+\s*$'`; do
    if [ -f "$d/package.xml" ]; then
	cat "$d/package.xml" |grep -v '^<?xml'
    fi
done;
echo '</extensions>';
) | xsltproc package2html.xsl - > "$REPO/index.html"


for d in pdt20; do
  for e in "$d"/contrib/*; do
    pushd $e
    ls *.mac *.mak *.inc | sort -k 1,1 -t . -d | xargs podselect > "$WWW/pdt20.pod"
    "$pod2xhtml" --css blue.css --infile "$WWW/pdt20.pod" \
	--outfile "$WWW/pdt20.html" --title "Documentation for the pdt20 extension"
    popd $e
  done
done
