package SCzechW_to_SCzechM::Sentence_segmentation_in_paragraphs;

use 5.008;
use strict;
use warnings;
use Report;

use base qw(TectoMT::Block);

use TectoMT::Document;
use TectoMT::Bundle;
use TectoMT::Node;


use Fslib;


sub process_document {
    my ($self,$document) = @_;

    if ($document->get_bundles()) {
        Report::warn "Bundles already contained in the document are deleted ";
        $document->delete_all_bundles();
    }

    my $SCzechW_root = $document->get_attr('SCzechW');
    my @paragraphs = $SCzechW_root->value->elements('para');

    my $sentord;

    foreach my $paragraph (@paragraphs) {
        my @w_units = $paragraph->value->elements('w');
        my @tokens = map {$_->value->get_member('token')} @w_units;
        my @no_space_afters = map {$_->value->get_member('no_space_after')} @w_units;
        my @ids = map {$_->value->get_member('id')} @w_units;

        # first cycle: marking beginnings of sentences
        my %beginning_of_sentence;
        foreach my $i (1..$#tokens-1) {
            if ($tokens[$i] eq ".") {
                $beginning_of_sentence{$i+1} = 1;
#                print STDERR "BOS: $i-1\n";
            }
            else {
#                print STDERR "normal token $tokens[$i]\n";
            }
        }

        # second cycle:
        my $current_bundle;
        my $current_m_root;

        foreach my $i (0..$#tokens) {

            if ($i == 0 or $beginning_of_sentence{$i}) {
                $sentord++;
                my $current_bundle = $document->new_bundle();

                my $end_of_sentence_index = $i;
                while ($end_of_sentence_index < $#tokens
                           and not $beginning_of_sentence{$end_of_sentence_index+1}) {
                    $end_of_sentence_index++;
                }

                $current_bundle->set_attr('czech_source_sentence',
                                          (join " ", map {$tokens[$_]} ($i..$end_of_sentence_index)));
                my $bundle_id = "s$sentord";
                $current_bundle->set_attr('id',$bundle_id);

                $current_m_root = TectoMT::Node->new();
                $current_bundle->set_tree('SCzechM',$current_m_root);
                $current_m_root->set_attr('id', "SCzechM-$bundle_id");
            }

            my $new_m_node = TectoMT::Node->new();
            $new_m_node->set_parent($current_m_root);
            $new_m_node->set_attr('form',$tokens[$i]);
            my $id = $ids[$i];
            $id =~ s/SCzechW/SCzechM/;
            $new_m_node->set_attr('id',$id);

        }
    }
}

1;

=over

=item SCzechW_to_SCzechM::Sentence_segmentation_in_paragraphs

Create m-layer sentences by dividing tokens from the w-layer.
Sentences are not allowed to cross the paragraph boundaries.

=back
=cut

# Copyright 2008 Zdenek Zabokrtsky
