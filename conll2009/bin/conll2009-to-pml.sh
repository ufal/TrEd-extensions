#!/bin/bash
# conll2009-to-pml.sh     pajas@ufal.mff.cuni.cz     2009/04/21 12:22:25

PARSED_OPTS=$(
  getopt -n 'conll2009-to-pml.sh' --shell bash \
    -o huvt:b:z \
    -l help \
    -l usage \
    -l version \
    -l trees-per-file \
    -l btred \
    -l gzip \
  -- "$@"
)
if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi
eval set -- "$PARSED_OPTS"

VERSION=1.0
PRINT_USAGE=0
PRINT_HELP=0
PRINT_VERSION=0
btred=btred
sentences_per_file=50
gzip=0

while true ; do
    case "$1" in
	-u|--usage) PRINT_USAGE=1; shift ;;
	-h|--help) PRINT_HELP=1; shift ;;
	-v|--version) PRINT_VERSION=1; shift ;;
	-t|--trees-per-file) sentences_per_file=$2; shift 2 ; break ;;
	-b|--btred) btred=$2; shift 2 ; break ;;
	-z|--gzip) gzip=1; shift 1 ; break ;;
	--) shift ; break ;;
	*) echo "Internal error while processing command-line options!" ; exit 1 ;;
    esac
done

function usage () {
    cat <<USAGE
conll2009-to-pml.sh [-t|--trees-per-file N] [-z|--gzip] [-b|--btred path_to_btred] file(s).conll
  or
conll2009-to-pml.sh [-h|--help]|[-u|--usage]|[-v|--version]
USAGE
}

function help () {
    echo "conll2009-to-pml.sh version $VERSION" 
    usage
    cat <<HELP

DESCRIPTION:

	This script converts data in CoNLL 2009 Shared Task format to
 	the Prague Markup Language format suitable for use with the Tree
 	Editor Tred and for querying with PML-TQ.

OPTIONS:
 -h|--help    - print this help and exit
 -u|--usage   - print a short usage and exit
 -v|--version - print version and exit
 
 -t|--trees-per-file <N> 

	number of trees per resulting PML file (default is $sentences_per_file)

 -b|--btred <path> 

	path to btred or start_btred executable (default is '$btred')
 
 -z|--gzip

	do not gzip resulting PML files

AUTHORS:
    Copyright (c) 2009 by
      Jan Stepanek <stepanek@ufal.mff.cuni.cz>
      Petr Pajas <pajas@ufal.mff.cuni.cz>
HELP
}

if [ $PRINT_VERSION = 1 ]; then echo Version: $VERSION; exit; fi
if [ $PRINT_HELP = 1 ]; then help; exit; fi
if [ $PRINT_USAGE = 1 ]; then usage; exit; fi

apreds='<member name="apreds" xmlns="http://ufal.mff.cuni.cz/pdt/pml/schema/">
  <list ordered="0">
    <structure>
      <member name="target.rf">
        <cdata format="PMLREF"/>
      </member>
     <member name="label">
       <cdata format="any"/>
     </member>
    </structure>
  </list>
</member>
<member role="#ID" name="xml:id" as_attribute="1" xmlns="http://ufal.mff.cuni.cz/pdt/pml/schema/">
  <cdata format="ID"/>
</member>'
apreds=$(echo "$apreds" | tr '\n' ' ')

columns="ID,FORM,LEMMA,PLEMMA,POS,PPOS,FEAT,PFEAT,HEAD,PHEAD,DEPREL,PDEPREL,FILLPRED,PRED"
bin=$(readlink -f "${0%/*}")

while (( $# )) ; do
    if [[ -f "$1" ]] ; then
        max=$(perl -e 'while (<>){@num = /(\t)/g ; $max = scalar(@num) if @num > $max } print "$max\n"' "$1")
        ((max-=14))
        arglist=''
        for n in $(seq 1 $max) ; do arglist=$arglist,APRED_$n ;done

        "$bin"/conll2pml -R conll2009 -r -o "$1" -m $sentences_per_file -c $columns$arglist "$1"
        sed -i~ 's%\(<s:member name="apred_1">\)%'"$apreds"'\1%' "$1_schema.xml"
        "$btred" -q -S -I "$bin"/args.btred "$1"_*.pml
	rm "$1_schema.xml"
	if [ $gzip = 1 ]; then
	    gzip -9 "$1"_*.pml
	fi
    else
        echo Skipping "$1" >&2
    fi
    shift
done
