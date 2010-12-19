#!/usr/bin/perl

## This script converts ICON2010 data into ICON2009 data format. Feed
## the output to hydt-morph2pml.perl. Sometimes, syntax error in the
## data or missing </document> must be fixed, too.

while(<>){
    if (/<fs /) {
        s, ,/,g;
        s,fs/,,;
        s,="([^"]+)",=$1,g;
        s,='([^']+)',=$1,g;
    }
    print;
}
