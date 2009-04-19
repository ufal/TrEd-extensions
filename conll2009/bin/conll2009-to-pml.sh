#! /bin/bash

## Converts CONLL 2009 ST data to PML.
## Author: Jan Stepanek

if (( ! $# )) || [[ $1 == -h || $1 == --help ]] ; then
    cat <<-EOF
	Usage: ${0##*/} conll-files..
	EOF
    exit 1
fi

btred=btred
sentences_per_file=50

while (( $# )) ; do
    if [[ -f "$1" ]] ; then
        bin=$(readlink -f "${0%/*}")
        max=$(perl -e 'while (<>){@num = /(\t)/g ; $max = scalar(@num) if @num > $max } print "$max\n"' "$1")
        ((max-=14))
        arglist=''
        for n in $(seq 1 $max) ; do arglist=$arglist,APRED_$n ;done
        "$bin"/conll2pml -R conll2009 -r -o "$1" -m $sentences_per_file -c ID,FORM,LEMMA,PLEMMA,POS,PPOS,FEAT,PFEAT,HEAD,PHEAD,DEPREL,PDEPREL,FILLPRED,PRED$arglist "$1"
        sed -i~ 's/\(<s:member name="apred_1">\)/<s:member name="apreds" type="feats.type"\/>\1/' "$1_schema.xml"
        "$btred" -S -I "$bin"/args.btred "$1"_*.pml
        "$bin"/remove_argN.sh "$1"_schema.xml
    else
        echo Skipping "$1" >&2
    fi
    shift
done
