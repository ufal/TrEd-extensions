#!/usr/bin/perl -w ###################################################################### 2009/08/12
#
# corpus_words.pl ###################################################################### Otakar Smrz

# $Id$

use strict;

use XML::Twig;

use Encode;


$/ = undef;

our $data;


while (my $document = decode "utf8", <>) {

    $data = {};

    $document =~ s/(&HT;(\s*\x{0640}+)?)//g and warn "$ARGV\n\tDeleting $1\n";

    $document =~ s/(&[A-Z][A-Za-z0-9]+;)//g and warn "$ARGV\n\tDeleting $1\n";

    $document =~ s/ & //g and warn "$ARGV\n\tDeleting &\n";

    $document =~ /(&(?!amp;|lt;|gt;))/ and warn "$ARGV\n\tVerify $1\n";

    $document =~ s/<seg id=([0-9]+)>/<seg id="$1">/g;

    my $source = XML::Twig->new(

            'ignore_elts'   => {

                            'HEADER'    => 1,
                            'FOOTER'    => 1,

                               },

            'twig_roots'    => {

                            'DOC/DOCNO' => 1,

                            'HEADLINE'  => 1,
                            'hl'        => 1,

                            'DATELINE'  => 1,

                            'P'         => 1,
                            'p'         => 1,

                               },

            'twig_handlers' => {

                            'DOC/DOCNO' =>  \&parse_docno,

                            'HEADLINE'  =>  \&parse_headline,
                            'hl'        =>  \&parse_headline,

                            'DATELINE'  =>  \&parse_dateline,

                            'P/seg'     =>  \&parse_seg,
                            'p/seg'     =>  \&parse_seg,

                            'P'         =>  \&parse_p,
                            'p'         =>  \&parse_p,

                               },

            'start_tag_handlers'    => {

                            'DOC'       =>  \&setup_doc,

                            'P'         =>  \&setup_p,
                            'p'         =>  \&setup_p,

                                       },

            );

    $source->parse($document);

    $source->purge();

    open X, '>', $ARGV . '.words.xml';

    select X;

    my $meta = "    " . '<revision>$' . 'Revision: ' . '$</revision>' . "\n" .
               "    " . '<date>$' . 'Date: ' . '$</date>' . "\n" .
               "    " . '<document>' . $data->{'document'} . '</document>';

    print << "<?xml?>";
<?xml version="1.0" encoding="utf-8"?>

<WordsLevel xmlns="http://ufal.mff.cuni.cz/pdt/pml/">
 <head>
  <schema href="words.schema.xml" />
 </head>
 <meta>
$meta
 </meta>
 <data>
<?xml?>

    my @id = (0);

    foreach my $para (@{$data->{'para'}}) {

        warn "$ARGV\n\tIgnoring empty paragraph after index $id[0]\n" and next unless exists $para->{'form'} and exists $para->{'unit'};

        local $\ = "\n";

        $id[0]++;

        @id = @id[0 .. 0];

        printf '<Para id="w-p%d">', @id;
        print  '<form>' . $para->{'form'} . '</form>';
        print  '<with>';

        foreach my $unit (@{$para->{'unit'}}) {

            $id[1]++;

            @id = @id[0 .. 1];

            printf '<Unit id="w-p%du%d">', @id;
            print  '<form>' . (encode "utf8", join " ", split " ", $unit->{'form'}) . '</form>';
            print  '</Unit>';
        }

        print  '</with>';
        print  '</Para>';
    }

    print << "<?xml?>";
 </data>
</WordsLevel>
<?xml?>

    close X;
}


sub setup_doc {

    my ($twig, $elem) = @_;

    $data->{'document'} = $elem->att('docid') || $elem->att('id') || '';

    # $elem->att('type')
    # $elem->att('language')

    $data->{'para'} = [];
}


sub parse_docno {

    my ($twig, $elem) = @_;

    die "$ARGV\n\tConflicts in document identification $data->{'document'}\n" if exists $data->{'document'} and $data->{'document'} ne '';

    $data->{'document'} = $elem->text();
}


sub setup_p {

    my ($twig, $elem) = @_;

    push @{$data->{'para'}}, {} unless @{$data->{'para'}} and not keys %{$data->{'para'}[-1]};
}


sub parse_headline {

    my ($twig, $elem) = @_;

    my $text = $elem->text();

    $twig->purge();

    process_text('HEADLINE', $text);
}


sub parse_dateline {

    my ($twig, $elem) = @_;

    my $text = $elem->text();

    $twig->purge();

    process_text('DATELINE', $text);
}


sub parse_seg {

    my ($twig, $elem) = @_;

    my $text = $elem->text();

    $twig->purge();

    process_text('TEXT', $text, 'units');
}


sub parse_p {

    my ($twig, $elem) = @_;

    die "$ARGV\n\tUnexpected structure of the document\n"  if grep { $_->name() eq 'seg' } $elem->children();

    my $text = $elem->text();

    $twig->purge();

    process_text('TEXT', $text) unless $text =~ /^\s*$/;
}


sub process_text {

    my ($meta, $text, $mode) = @_;

    push @{$data->{'para'}}, {} unless $mode or @{$data->{'para'}} and not keys %{$data->{'para'}[-1]};

    die "$ARGV\n\tUnexpected structure of the document\n"  if exists $data->{'para'}[-1]{'form'}
                                                                 and $data->{'para'}[-1]{'form'} ne ''
                                                                 and $data->{'para'}[-1]{'form'} ne $meta;

    $data->{'para'}[-1]{'form'} = $meta;

    $data->{'para'}[-1]{'unit'} = [] unless exists $data->{'para'}[-1]{'unit'};

    push @{$data->{'para'}[-1]{'unit'}}, { 'form' => $text };
}
