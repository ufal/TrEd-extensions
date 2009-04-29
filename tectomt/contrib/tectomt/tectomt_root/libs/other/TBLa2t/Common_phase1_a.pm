use 5.008;
use warnings;
use strict;
use Report;

#======================================================================

sub merg
{
	my ($ftbl, $t_root) = @_;
	my %succs = (); # { id of a deleted t-node } -> its successor (or undef, if deleted and s. not known)
	my $document = $t_root->get_document;
	my %a2t = (); # { a-id } -> t-node (because a-layer get_eff_parent must be used)

	for my $t_node ($t_root->get_self_and_descendants) {
		$a2t{ aid($t_node) } = $t_node;
	}

	# mark transformations
	for my $t_node ($t_root->get_descendants) {
		my $a_node = $t_node->get_lex_anode; # a-node for $t_node
		my $pml_lemma = adjust_lemma($a_node);

		my $line;
		defined ($line = <$ftbl>) or Report::fatal "Unexpected end of file";
		$line =~ s/(.*)\| ([0-9]+ )*$/$1/; # strip rule' numbers
		$line =~ /^(\S+) .* (\S+) (\S+) \S+ \S+ $/ or Report::fatal "Bad line in the input file: \"$line\"";
		my ($lemma, $ftor, $del_par) = ($1, $2, $3);
#		$lemma eq $pml_lemma or Report::fatal "The input files do not match ($lemma vs. $pml_lemma)";
	
		# get the e-parent of the node in question (have to be the same as in the TBL file)
		my $a_epar = ($a_node->get_eff_parents)[0];
		my $t_epar = $a2t{ $a_epar->get_id };
		$t_epar or Report::fatal "Assertion failed";

		# register transformations
		if ($del_par eq 'D' && $t_epar ne $t_root) { # the root cannot be deleted -- ignore the rule
			my $t_echild = $t_node; # successor of a node is always its child (ergo special handling of coordinations); alas when coord node is not annotated right, this does not hold true
			while ($t_echild->is_coap_member && $t_echild->get_parent->is_coap_root) { $t_echild = $t_echild->get_parent }
			$succs{ $t_epar->get_id } = $t_echild unless $t_epar eq $t_echild; # condition for weird coords
		}
		if ($ftor eq 'xxx') {
			$succs{ $t_node->get_id } = undef unless exists $succs{ $t_node->get_id }
		}
		elsif ($t_node->get_attr('functor') ne '---') {
			$t_node->set_attr('functor', $ftor) unless $t_node->is_coap_root xor $ftor =~ /^(CONJ|CONFR|DISJ|GRAD|ADVS|CSQ|REAS|CONTRA|APPS|OPER)$/;
		}
	}


	# delete leaves to be deleted
	my $done;
	do {
		$done = 1;
		for my $t_node_id (sort keys %succs) {
			my $t_node = $document->get_node_by_id($t_node_id); # the t-node to be deleted
			$t_node or Report::fatal "Assertion failed: $t_node_id";
			next if $t_node->get_children > 0; # only leaves
			$done = 0;
			info $t_node_id, ", ", $t_node->get_attr('t_lemma'), "\n";
			my $a_node = $t_node->get_lex_anode; # the a-node to be deleted

			# move the deleted node and "its" previously deleted nodes into a/aux.rf of the their successor
			$t_node->get_parent->add_aux_anodes($a_node) unless $a_node->get_attr('afun') =~ /^Aux[GKX]$/;
			$t_node->get_parent->add_aux_anodes($t_node->get_aux_anodes);

			# delete it
			map { $succs{$_} = undef } grep { defined $succs{$_} && $succs{$_} eq $t_node } keys %succs; # in successors, delete the deleted node (another successor will be assigned later)
			$t_node->disconnect;
			delete $succs{ $t_node_id };
		}
	} until $done;

	# if no successor, fill in one
	for my $t_node_id (grep { !defined $succs{$_} } sort keys %succs) {
		my $t_node = $document->get_node_by_id($t_node_id); # a node to be deleted
		$t_node or Report::fatal "Assertion failed: $t_node_id";
		$t_node->get_children > 0 or Report::fatal "Assertion failed: $t_node_id";
		info $t_node_id, ", ", $t_node->get_attr('t_lemma'), ": ";
		if ($t_node->get_children == 1) { # clear case
			info "implicit successor assigned\n";
			$succs{$t_node_id} = $t_node->get_leftmost_child;
		}
		else { # more candidates -- give it up
			info "has ", scalar($t_node->get_children), " children, will be retained\n";
			delete $succs{$t_node_id};
			$t_node->set_attr('functor','RSTR') if $t_node->get_attr('functor') eq 'xxx';
		}
	}

	
	# delete inner nodes to be deleted
	while (my @nodes = sort keys %succs) {
		# select the "lowest" node
		my $t_node_id = $nodes[0];
		while (defined $succs { $t_node_id } && exists $succs{ $succs { $t_node_id }->get_id }) {
			$t_node_id = $succs{ $t_node_id }->get_id;
		}
			
		# get the real nodes
		my $t_node = $document->get_node_by_id($t_node_id); # a node to be deleted
		$t_node or Report::fatal "Assertion failed: $t_node_id";
		my $a_node = $t_node->get_lex_anode; # a-node for $t_node
		defined $succs{$t_node_id} or Report::fatal "Assertion failed";
		my $succ = $succs{$t_node_id}; # successor of the node being deleted; t-node

		# rehang the successor and the children
		info $t_node_id, ", ", $t_node->get_attr('t_lemma'), ": onto ", $succ->get_attr('t_lemma');
		$succ->set_parent($t_node->get_parent); # rehang the successor
		map { $_->set_parent($succ) } grep { $_->get_id ne $succ->get_id } $t_node->get_children; # rehang the children
		map { $succs{$_} = $succ } grep { defined $succs{$_} && $succs{$_} eq $t_node } keys %succs; # in %succs, change the deleted node into its successor

		# move the deleted node and "its" previously deleted nodes into a/aux.rf of the their successor
		for my $exp_succ ($succ->is_coap_root? $succ->get_transitive_coap_members : ($succ)) {
			$exp_succ->add_aux_anodes($a_node);
			$exp_succ->add_aux_anodes($t_node->get_aux_anodes);
		}
		
		# finally, delete the node
		$t_node->disconnect;
		delete $succs{ $t_node_id };

		info "\n";
	}
}

#======================================================================

1;

