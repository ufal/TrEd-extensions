package SCzechW_to_SCzechM::Sentence_segmentation;

use 5.008;
use strict;
use warnings;
use Report;

use base qw(TectoMT::Block);

use TectoMT::Document;
use TectoMT::Bundle;
use TectoMT::Node;

sub process_document {
    my ($self,$document) = @_;
    my $text = $document->get_attr('czech_source_text');
    my $sentord;
    if ($document->get_bundles()) {
        Report::warn "Bundles already contained in the document are deleted ";
        $document->delete_all_bundles();
    }

    $text =~s/\./\.|/g;
    foreach my $sentence (grep {/\S/} split /\|/,$text ) {
        $sentord++;
        $sentence =~ s/\s+/ /gsxm;
        $sentence =~ s/^\s//gsxm;
        $sentence =~ s/\s$//gsxm;
        my $bundle = $document->new_bundle();
        $bundle->set_attr('czech_source_sentence',$sentence);
        $bundle->set_attr('id',"s$sentord");
    }
}

1;

=over

=item SCzechW_to_SCzechM::Sentence_segmentation


???????? OPRAVIT

The source Czech text (stored in the document attribute C<english_source_text>)
is segmented into a sequence of sentences using C<Lingua::EN::Tagger>. A new empty
bundle is created for each sentence and equipped with attributes C<english_source_sentence> and C<id>.

=back
=cut

# Copyright 2008 Zdenek Zabokrtsky
