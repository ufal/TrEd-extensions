use 5.008;
use warnings;
use strict;

#======================================================================

sub feature_touple
{
	my ($t_node) = @_;
	my $a_node = get_anode($t_node);
	return (
		adjust_lemma($a_node),
		tag($a_node),
		attr($a_node, 'afun'),
		attr($t_node, 'functor')
		);
}

#======================================================================

sub compound_feature
{
	my @c_feat = ();
	my @outarr = ();
	while (my $node = shift @_) {
		my @f = feature_touple($node);
		for my $i (0..3) { push @{$c_feat[$i]}, $f[$i] }
	}
	for my $i (0..3) {
		push @outarr, ($c_feat[$i]? (join '+', @{$c_feat[$i]}) : '---');
	}
	return @outarr;
}
	
#======================================================================

sub feature_string
{
	my ($t_node) = @_;
	my $outstr = "";
	my @list;

	$outstr = sprintf "%s %s %s %s  %s %s %s %s ", feature_touple($t_node), feature_touple($t_node->get_parent);
	for (@list = (), my $n = $t_node->get_right_neighbor; $n; $n = $n->get_right_neighbor) { push @list, $n }
	$outstr .= sprintf " %s %s %s %s ", compound_feature(@list);
	for (@list = (), my $n = $t_node->get_left_neighbor; $n; $n = $n->get_left_neighbor) { push @list, $n }
	$outstr .= sprintf " %s %s %s %s ", compound_feature(@list);
	$outstr .= sprintf " %s %s %s %s", compound_feature($t_node->get_ordered_children);
	return $outstr;
}

#======================================================================

sub totbl
{
	my ($ftbl, $t_root) = @_;
	for my $t_node ($t_root->get_descendants) {
		printf $ftbl "%s - -\n",
			feature_string($t_node);
	}
}

#======================================================================

sub merg
{
	my ($ftbl, $t_root) = @_;
	my @descs = () ; # list of (t-node, description of a transformation)-pairs

	NODE: for my $node ($t_root->get_descendants) {
		# read the input
		my $pml_lemma = adjust_lemma($node->get_lex_anode);

		my $line; # an input line
		defined ($line = <$ftbl>) or Report::fatal "Unexpected end of file";
		$line =~ /^(\S+) .* (\S+) \S+ \| ([0-9]+ )*$/ or Report::fatal "Bad line in the input file: \"$line\""; # strip rule' numbers
		my ($lemma, $desc) = ($1, $2);
#		$lemma eq $pml_lemma or Report::fatal "The input files do not match ($lemma vs. $pml_lemma)";
		undef $pml_lemma; undef $lemma; undef $line;
		$desc ne '-' or next;

		# fill the appropriate data structures with input data
		my $t_node = $node; # new variable, since we need to move all over the tree
		$desc =~ /^([^+:;|]+)(\+([^;|]+))?(:([^;|]+))?(;([^|]+))?(\|(.+))?$/ or Report::fatal "Error in description of a transformation"; #! puvodni anglicke
#		$desc =~ /^([^+:;|]+)(\+([^:;|]*))?(:([^;|]*))?(;([^|]*))?(\|(.*))?/ or Report::fatal "Error in description of a transformation"; #! puvodni ceske
		my ($trans, @char2desc, @new_functors, @cop_functors, @succs);
		$trans        = $1; # a transformation
		@char2desc    = split /\+/, $3 if defined $3; # [ char-'A' ] -> its description
		@new_functors = split /\+/, $5 if defined $5; # list of functors of new nodes
		@cop_functors = split /\+/, $7 if defined $7; # list of functors of copied nodes
		@succs        = split /\+/, $9 if defined $9; # list of chars of successors
		
		info $t_node->get_id, ' ', $trans, ' ', (join '+', @char2desc), ' :', (join '+', @new_functors), ' ;', (join '+', @cop_functors), ' |', (join '+', @succs), "\n";
		unshift @char2desc, (undef, undef); # so that the first record is for 'A'

		# match the transformation in the tree
		my @nodes_in_trans = (); # [ char-'A' ] -> the corresponding node
		my ($ls, $rs) = split /->/, $trans;
		my @l_side = split //, $ls; # left side of transformation split into characters
		defined $ls && defined $rs or Report::fatal "Error in description of $trans";
		shift @l_side eq 'A' && shift @l_side eq '(' && shift @l_side eq 'B' or Report::fatal "Error in description of $trans";
		$nodes_in_trans[0] = $t_node->get_parent; # 'A'
		info "  A = ", $t_node->get_parent eq $t_root? "<root>" : $t_node->get_parent->get_attr('t_lemma'), "\n";
		$nodes_in_trans[1] = $t_node; # 'B'
		info "  B = ", $t_node->get_attr('t_lemma'), "\n";
		my $letter = 'C'; # which node should be processed now
		while (defined ($_ = shift @l_side)) {
			/[A-Z,()]/ or Report::fatal "Error in description of $trans";
			/,/  and do { $t_node = $t_node->get_right_neighbor };
			/\)/ and do { $t_node = $t_node->get_parent };
			/\(/ and do { $t_node = $t_node->get_leftmost_child };
			/[A-Z]/ and do {
				$_ eq $letter or Report::fatal "Error in description of $trans";
				$t_node = $t_node->get_right_neighbor while $t_node && get_anode($t_node)->get_attr('afun') ne $char2desc[ ord($letter)-ord('A') ];
				unless ($t_node) { # no node with the given description found
					info "Cannot apply the transformation ($_ = ", $char2desc[ ord($letter)-ord('A') ], ")\n";
					next NODE;
				}
				$nodes_in_trans[ ord($letter)-ord('A') ] = $t_node;
				info "  $letter = ", $t_node->get_attr('t_lemma'), "\n";
				$letter++;
			};
		}

		# only jot down transformations (for fear of changing the structure while reading)
		push @descs, [ $trans, \@nodes_in_trans, \@new_functors, \@cop_functors, \@succs ];
	} # a node


	for (@descs) {
		my ($trans, $nodes_in_trans, $new_functors, $cop_functors, $succs) = @$_; # similar meaning as above
		info "# $trans\n";

		# cut and rehang the nodes
		my ($ls, $rs) = split /->/, $trans;
		my @r_side = split //, $rs; # right side of transformation split into characters
		if ($nodes_in_trans->[0] eq $t_root && $r_side[0] ne 'A') { # the root of the sentence must remain at its place
			info "Cannot apply the transformation (the root should move)\n";
			next;
		}
		my $t_node; # the last visited node; and its parent
		my $t_par = $nodes_in_trans->[0]->get_parent; # transformed subtree will hang on A's parent
		unless ($t_par) {
			info "Due to previous transformations, A has no parent\n";
			next;
		}
		while (grep {$t_par eq $_} (@$nodes_in_trans)) { # this can happen only when a previous transformation is applied to these nodes
			info "  ! subroot had to be moved (", $t_par->get_id, ")\n";
			$t_par = $t_par->get_parent;
		}
		for (@$nodes_in_trans) { $_->disconnect unless $_->is_root } # now we can safely cut off nodes
		while (defined ($_ = shift @r_side)) {
			/[A-Za-z,()*]/ or Report::fatal "Error in description of $trans";
			/,/  and do { };
			/\)/ and do { $t_node = $t_par; $t_par = $t_par->get_parent };
			/\(/ and do { $t_par = $t_node; $t_node = undef; };
			/[A-Za-z]/ and do {
				my $letter = $_;
				my $is_copy = $letter =~ /[a-z]/; # the node is a copy of another node
				$letter = uc $letter;
				$t_node = $nodes_in_trans->[ ord($letter)-ord('A') ];

				if ($is_copy) { # if this is a copy, create new node and set its attributes
					my $orig = $t_node;
					$t_node = clone_tnode($orig, $t_par);
					my $new_funct = shift @$cop_functors;
					$t_node->set_attr('functor', $new_funct) unless $new_funct eq '@';
				}
				else {
					$t_node->set_parent($t_par) if $t_par; # unless $t_par, we are at 'A' and it has been root of the sentence and it actually has not been cut off
				}
			};
			/\*/ and do {
				$t_node = new_tnode($t_par);
				$t_node->set_attr('functor', shift @$new_functors);
				$t_node->get_attr('functor') or Report::fatal "Error in description of $trans"; # a functor is missing
			};
		}
		undef @r_side;

		# put ids of deleted nodes into successors' a/aux.rf and relocate children
		for my $node (@$nodes_in_trans) {
			if (!$node->get_parent && $node ne $t_root) { # the node is deleted
				my $succ_char = shift @$succs; # description of its successor
				defined $succ_char or Report::fatal "Error in description of $trans: ". $node->get_attr('t_lemma');
				my $succ; # its successor
				$succ = $succ_char =~ /[A-Z]/? $nodes_in_trans->[ ord($succ_char)-ord('A') ] : $t_root->get_leftmost_child; # back-off successor unless given
				$succ->add_aux_anodes($node->get_anodes) unless $succ_char eq '0';
				map { $_->set_parent($succ) } make_array($node->get_children);
			}
		}

		# normalize deepords
		$t_root->normalize_node_ordering;

	} # a transformation

	add_is_member($t_root);
	$t_root->get_leftmost_child->set_attr('is_member', undef) if $t_root->get_leftmost_child;

}

#======================================================================

1;

