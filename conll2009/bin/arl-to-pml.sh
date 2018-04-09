#!/bin/bash
# arl-to-pml.sh     kopp@ufal.mff.cuni.cz     2018/04/04 10:40:00

# readlink -f does not work on Mac OSX, so here is a Perl-based workaround:
readlink_nf () {
    perl -MCwd -e 'print Cwd::abs_path(shift)' "$1"
}

VERSION=1.0
PRINT_USAGE=0
PRINT_HELP=0
PRINT_VERSION=0
btred=btred
sentences_per_file=50
gzip=0
out_dir=

args=()
while [ $# -gt 0 ]; do
    case "$1" in
        -u|--usage) PRINT_USAGE=1; shift; break ;;
        -h|--help) PRINT_HELP=1; shift; break ;;
        -v|--version) PRINT_VERSION=1; shift; break ;;
        -t|--trees-per-file) sentences_per_file=$2; shift 2 ;  ;;
        -b|--btred) btred=$2; shift 2 ;  ;;
        -z|--gzip) gzip=1; shift 1 ;  ;;
        -o|--out-dir) out_dir=$(readlink_nf "$2"); shift 2 ;  ;;
        --) shift ; break ;;
        -*) echo "Unknown command-line option: $1" ; exit 1 ;;
        *) args+=("$1"); shift ;;
    esac
done
eval set -- "${args[@]}"

function usage () {
    cat <<USAGE
arl-to-pml.sh [-t|--trees-per-file N] [-z|--gzip] [-b|--btred path_to_btred] file(s).conll
  or
arl-to-pml.sh [-h|--help]|[-u|--usage]|[-v|--version]
USAGE
}

function help () {
    echo "arl-to-pml.sh version $VERSION" 
    usage
    cat <<HELP

DESCRIPTION:

        This script converts data in CoNLL arl Shared Task format to
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
    Copyright (c) 2018 by
      Matyáš Kopp <kopp@ufal.ms.mff.cuni.cz>
      Jan Stepanek <stepanek@ufal.mff.cuni.cz>
      Petr Pajas <pajas@ufal.mff.cuni.cz>
HELP
}

if [ $PRINT_VERSION = 1 ]; then echo Version: $VERSION; exit; fi
if [ $PRINT_HELP = 1 ]; then help; exit; fi
if [ $PRINT_USAGE = 1 ]; then usage; exit; fi

columns="ID,TYPE,HEAD,DEPREL,ROOT,LEMMA,FORM,FORM_TRANSLITERATED,XPOS,GLOSS,MISK"
bin=$(readlink_nf "${0%/*}")

fixcolumns='
sub {
  my @sent = @_;
  my %map_old_ids=("-1/0" => 0);
  my $i=1;
  $map_old_ids{$_->{ID}} = ($i++) for (@sent);
  for my $tok (@sent) {
    $tok->{ID} = $map_old_ids{$tok->{ID}};
    if($tok->{HEAD} eq "-") {
      $tok->{HEAD} = $tok->{ID} + ($tok->{TYPE} eq "pref" ? 1 : -1 );
    } else {
      $tok->{HEAD} = $map_old_ids{$tok->{HEAD}};
    }
  }
  return \@sent;
}'
fixcolumns=$(echo "$fixcolumns" | tr '\n' ' ')

while (( $# )) ; do
    if [[ -f "$1" ]] ; then
        max=$(perl -e 'while (<>){@num = /(\t)/g ; $max = scalar(@num) if @num > $max } print "$max\n"' "$1")
        ((max-=13))
        # if there are no ARGS in the conll data, set max to 1
        if ((!max)) ; then max=1 ; fi
        echo -n "$1\t=>\t"
        out_prefix=`echo -n "${1%.txt}"| sed "s/[^\.-_0-9A-Za-z]/_/g"`
        echo "${out_prefix}_####.pml"
        if [ -n "$out_dir" ]; then
            out_prefix="$out_dir"/$(basename "$out_prefix")
        fi
        perl "$bin"/conll2pml --root-tag arl --technical-root --node-ids --id-prefix "${out_prefix}s" --order-attribute 'ord' --set-schema 'arl_schema.xml' --fix-columns "$fixcolumns" --out-prefix "$out_prefix" --max-sentences $sentences_per_file --columns $columns "$1"
        if [ $gzip = 1 ]; then
            gzip -9 "$out_prefix"_*.pml
        fi
    else
        echo Skipping "$1" >&2
    fi
    shift
done
