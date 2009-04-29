package SCzechM_to_SCzechA::Fill_afun;

use 5.008;
use strict;
use warnings;
use Report;

use base qw(TectoMT::Block);

use TectoMT::Document;
use TectoMT::Bundle;
use TectoMT::Node;

use AutoAfun::Main;

sub process_document {
    my ($self,$document) = @_;

    foreach my $bundle ($document->get_bundles()) {
        my $a_root = $bundle->get_tree('SCzechA');

        AutoAfun::Main::assign_afun_auto_tree($a_root->get_tied_fsnode);
    }
}

1;


=over

=item SCzechM_to_SCzechA::Fill_afun

Assign the values of analytical functions of a-nodes.

=back
=cut

# Copyright 2008 Zdenek Zabokrtsky
