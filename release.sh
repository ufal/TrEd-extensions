#! /bin/bash

for ext ; do
    rsync --exclude='*/.svn*' -avr /home/pajas/WWW/tred/extensions/{$ext.zip,$ext/,index.html} ufal:/home/pajas/WWW/tred/extensions/
done
