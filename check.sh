#!/bin/bash

# This script should be placed in the root directory on the HTTP
# server from where TrEd reads its extensions. It checks the integrity
# of the configuration and reports any duplicates, missing files or
# broken references.

set -eu

echo % Common files:
comm -12 <(ls core) <(ls external) \
| grep -vE '^(extensions\.lst~?|index\.html)$'

echo
echo % Common extensions in lists:
comm -12 <(sort core/extensions.lst) <(sort external/extensions.lst)

echo
echo % Zip files with no links:
for dir in core external ; do
    sed 's/$/.zip/' "$dir"/extensions.lst \
    | grep -vFf- <(ls "$dir")  \
    | sed -n '/.zip$/ { s=^='"$dir/"'=;s/\.zip$//; p}'
done

echo
echo % Listed non-existent:
for dir in core external ; do
    while read ext ; do 
        dir_found=0
        [[ -d $dir/$ext ]] && dir_found=1
        zip_found=0
        [[ -f $dir/$ext.zip ]] && zip_found=1
        if (( ! dir_found || ! zip_found )) ; then
            echo $dir/$ext dir: $dir_found zip: $zip_found
        fi
    done < "$dir"/extensions.lst
done

echo
echo % Package link broken:
for dir in core external ; do
    grep -o '<repository[^>]*' "$dir"/*/package.xml | grep -v "<repository.*$dir"
done
