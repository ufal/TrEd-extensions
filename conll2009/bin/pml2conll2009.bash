#!/bin/bash

if [ ${BASH_VERSION%%.*} -lt 3 ] ; then
    echo Wrong Bash version >&2
    exit 1
fi

NAME=pml2conll2009.bash
VERSION=0.2

function ShowHelp () {
    echo $NAME version $VERSION
    usage
    cat <<HELP

DESCRIPTION

  This script converts the PML data created by conll2009-to-pml.sh
  back to CoNLL-ST-2009 format.

OPTIONS:

  -v|--version          - show version
  -u|--usage            - show usage
  -h|--help             - show this help
  -b|--btred            - path to btred

  -g|--group <strip-suffix> <add-suffix>

    While processing files, the files with names that differ only in
    the suffix will be output to the same output file. For examlpe

    $NAME -g '-??.pml' .conll cz-01.pml cz-02.pml en-??.pml

    will create two output files, cz.conll and en.conll.

AUTHORS:
    Copyright (c) 2009 by
      Jan Stepanek <jan.stepanek[at]matfyz.cz>
HELP
}

function usage () {
    cat <<USAGE
USAGE: $NAME [-b path_to_btred] [-g strip add] file.pml..
USAGE
}

if ((!$#)) || [[ $1 == -h || $1 == --help ]] ; then
    ShowHelp
    exit
elif [[ $1 == -u || $1 == --usage ]] ; then
    usage
    exit
elif [[ $1 == -v || $1 == --version ]] ; then
    echo $VERSION
    exit
fi

STRIP=''
ADD=.conll
BTRED=btred

while [[ $1 == -* ]] ; do
    if [[ $1 == -b* || $1 == --btred ]] ; then
        if [[ $1 == -b? ]] ; then
            BTRED=${1#-b}
            shift
        else
            BTRED=$2
            shift 2
        fi
    elif [[ $1 == -g* || $1 == --group ]] ; then
        if [[ $1 == -g? ]] ; then
            STRIP=${1#-g}
            shift
        else
            STRIP=$2
            shift 2
        fi
        ADD=$1
        shift
    else
        echo Unknown option "$1" >&2
        exit
    fi
done

bindir=$(readlink -f ${0%/*})

for file ; do
    : > ${file%$STRIP}$ADD 
done

for file ; do
    $BTRED -I "$bindir"/pml2conll "$file" >> ${file%$STRIP}$ADD 
done
