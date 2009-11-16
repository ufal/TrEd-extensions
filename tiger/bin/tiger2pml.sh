#!/bin/bash

script_dir="$(dirname "$0")"
xsl="$script_dir"/tiger2pml.xsl

if [ -z "$1" ]; then 
    echo "Usage: $0 tiger_release.xml [output_dir]"
    echo "The script requires 8GB ram, xsltproc and XSH (http://xsh.sourceforge.net)"
    exit 1;
fi
input="$1"
output="$(basename ${input%.xml}.pml)"
output_dir="."

if [ -n "$2" ]; then
    output_dir="$2"
fi
if [ -d "$output_dir" ];
    mkdir -p "$output_dir" || exit 1
fi

arch="$(uname -m)"
mem="$(free -g|grep '^Mem:'|sed $'s/  */\t/g'|cut -f2)"

if [ -n "$arch" ] && [ "$arch" = 'x86_64' ] && [ -n "$mem" ] && [ "$mem" -gt 8 ] ; then

    xsltproc "$xsl" "$input" > "$output_dir/$output"
    "$script_dir"/split_tiger.xsh "$output_dir/$output"

else
    echo "This script ($0) must be run on a 64bit platform with at least 8GB of RAM" 1>&2
    echo "This is $arch with $mem GB of RAM" 1>&2
    exit 1
fi
