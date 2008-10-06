package SCzechA_to_SCzechT::Recompute_deepord;

use 5.008;
use strict;
use warnings;

use base qw(TectoMT::Block);

use TectoMT::Document;
use TectoMT::Bundle;
use TectoMT::Node;


sub process_document {
    my ($self,$document) = @_;

    foreach my $bundle ($document->get_bundles()) {
        my $t_aux_root = $bundle->get_tree('SCzechT');
        my $deepord;
        foreach my $t_node (sort {$a->get_attr('deepord')<=>$b->get_attr('deepord')} $t_aux_root->get_descendants) {
            $deepord++;
            $t_node->set_attr('deepord',$deepord);
        }
    }
}

1;


=over

=item SCzechA_to_SCzechT::Recompute_deepord

When finishing the topological changes of SCzechT trees, the C<deepord>
attribute is to be recomputed so that it does not contain any holes
or fractional numbers.

=back
=cut

# Copyright 2008 Zdenek Zabokrtsky
