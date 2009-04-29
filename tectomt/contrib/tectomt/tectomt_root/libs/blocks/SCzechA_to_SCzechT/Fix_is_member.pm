package SCzechA_to_SCzechT::Fix_is_member;

use 5.008;
use strict;
use warnings;

use base qw(TectoMT::Block);

use TectoMT::Document;
use TectoMT::Bundle;
use TectoMT::Node;


sub get_p_nonterminals {
    my ($a_node,$document) = @_;
    my @nonterminals = ($a_node->get_attr('p/nonterminals.rf'))?
        (grep {$_} map {$document->get_node_by_id($_)} @{$a_node->get_attr('p/nonterminals.rf')}):();
    return @nonterminals;
}

sub process_document {
    my ($self,$document) = @_;
    foreach my $bundle ($document->get_bundles()) {

        my $t_root = $bundle->get_tree('SCzechT');


        # (1) every member must be below coap
        foreach my $node (grep {$_->get_attr('is_member')} $t_root->get_descendants) {
            my $parent_functor =   $node->get_parent->get_attr('functor') || "";
            if ($parent_functor !~ /(APPS|CONJ|DISJ|ADVS|CSQ|GRAD|REAS|CONFR|CONTRA|OPER)/) {
                $node->set_attr('is_member',undef);
            }
        }


        # (2) there should be at least one member below every co/ap
        foreach my $node (grep {($_->get_attr('functor')||"") =~ /(APPS|CONJ|DISJ|ADVS|CSQ|GRAD|REAS|CONFR|CONTRA|OPER)/ }
                              $t_root->get_descendants) {
            if (not grep {$_->get_attr('is_member')} $node->get_children) {
                # !!! vetsinou jde opravdu o bezdetne PRECy, zbyvajici vyjimky by se musely o dost resit sloziteji
                $node->set_attr('functor','PREC');
            }
        }

    }
}

1;



#!!! totez co anglicky protejsek, asi by chtelo predelat na genericky blok

=over

=item SCzechA_to_SCzechT::Fix_is_member

The attribute C<is_member> is fixed: (1) is_member can be equal to
1 only below coap nodes, (2) below each coap node there has to be
at least one node with is_member equal to 1.

=back
=cut

# Copyright 2008 Zdenek Zabokrtsky
