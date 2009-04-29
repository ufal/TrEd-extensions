use 5.008;
use warnings;
use strict;

#======================================================================
# Gets list of real children of the node. When children are in a coordination,
# it returns the coordination node. E.g. in case of sentence "Petr umyl hrnce a
# kastroly a zametl." nodes "Petr" and "a" (connecting "hrnce a kastroly") are
# returned for node "umyl". Besides, it fills attribute eff_func of real
# children with their effective functor (e.g. eff_func of that "a" is PAT).

sub real_children
{
	my ($node) = @_;
	my @children;
	$node or Report::fatal "Assertion failed";
	for my $eff ($node->get_eff_children) {
		my $real = $eff->get_transitive_coap_root;
		$real->set_attr('eff_func', $eff->get_attr('functor')) unless defined $real->get_attr('eff_func');
#		$real->get_attr('eff_func') eq $eff->get_attr('functor') or $real->set_attr('eff_func', '???');
		push @children, $real unless grep { $_ eq $real } @children;
	}
	return @children;
}

#======================================================================

sub totbl
{
	my ($ftbl, $t_root) = @_;
	my %before = (); # info about children in the files:
	                 #   { parent's aid }{ child's functor }-> # of such cases

	for my $t_node ($t_root->get_descendants) {
		next if $t_node->get_attr('is_generated') || $t_node->is_coap_root; # generated parents and coordinations are ignored
		defined $t_node->get_attr('t_lemma') or Report::fatal "Assertion failed";

		for my $ch (real_children($t_node)) {
			$before{ aid($t_node) }{ $ch->get_attr('eff_func') }++;
		}

		# printing of training data
		print $ftbl feature_string($t_node);
		no warnings 'uninitialized';
		for my $i (0..@func3-1) { # print input functors
			printf $ftbl "%d ", $before{ aid($t_node) }{ $func3[$i] };
		}
		use warnings 'uninitialized';
		print $ftbl "--- "; # true valency frame
		print $ftbl "--- "; # true functor
		no warnings 'uninitialized';
		for my $i (0..@func3-1) { # print true functors
			printf $ftbl "- ";
		}
		use warnings 'uninitialized';
		print $ftbl "\n";

	}

	for my $t_node ($t_root->get_descendants) {
		$t_node->set_attr('eff_func', undef);
	}
}

#======================================================================

sub merg
{
	my ($ftbl, $t_root) = @_;
	my %ftor_cnt = (); # {t-id}{functor} => # of children with the functor as stated by the rules
	
	# mark transformations
	for my $t_node ($t_root->get_descendants) {
		next if $t_node->get_attr('is_generated') || $t_node->is_coap_root; # generated parents and coordinations are ignored

		# read and check data
		my $line;
		defined ($line = <$ftbl>) or Report::fatal "Unexpected end of file";
		$line =~ s/(.*)\| ([0-9]+ )*$/$1/; # strip rule' numbers
		my ($val_frame, $func, $ftor_cnts) = parse_and_check_line($line, $t_node->get_attr('t_lemma'));

		# register new nodes in %ftor_cnt and perform change of the functor
		my $i = 0;
		for (split / +/, $ftor_cnts) {
			$ftor_cnt{ $t_node->get_id }{ $func3[$i] } = $_;
			$i++;
		}
		if ($t_node->get_attr('functor') ne $func) {
			info $t_node->get_id, ": ", $t_node->get_attr('functor'), " => $func\n";
			!$t_node->is_coap_root or Report::fatal "Assertion failed";
			$t_node->set_attr('functor', $func);
		}
		$t_node->set_attr('val_frame.rf', $val_frame) if $val_frame ne '---';
	}

	for my $t_node ($t_root->get_descendants) {
		next if $t_node->get_attr('is_generated') || $t_node->is_coap_root; # generated parents and coordinations are ignored
		my $tid = $t_node->get_id;

		# fill %nodes
		my %nodes = (); # { functor } => t_node's real children with this functor
		for my $ch (real_children($t_node)) {
			push @{$nodes{ $ch->get_attr('eff_func') } }, $ch;
		}

		# cope with inner actants if some is missing and some is extra
		my ($missing, $extra, $last);
		for my $func qw( ACT ADDR PAT ORIG EFF ) {
			$nodes{ $func } or @{$nodes{ $func }} = (); # to have it defined
			my $diff = $ftor_cnt{$tid}{$func} - @{$nodes{ $func }};
			if ($diff < 0) {
				$extra = $func;
				$last = 0;
			}
			elsif ($diff > 0) {
				$missing = $func;
				$last = 1;
			}
		}
		if ($missing && $extra) {
			@{$nodes{ $extra }} = sort { $a->get_attr('deepord') <=> $b->get_attr('deepord') } @{$nodes{ $extra }};
			my $node = $last? pop @{$nodes{ $extra }} : shift @{$nodes{ $extra }};
			push @{$nodes{ $missing }}, $node;
			if ($node->is_coap_root) {
				map { $_->set_attr('functor', $missing) } $node->get_direct_coap_members;
			}
			else {
				$node->set_attr('functor', $missing);
			}
			info "$tid: $extra --> $missing\n";
		}

		# add new nodes
		for my $func (@func3) {
			$nodes{ $func } or @{$nodes{ $func }} = (); # to have it defined
			my $diff = $ftor_cnt{$tid}{$func} - @{$nodes{ $func }};
			if ($diff < 0) {
				info "$tid: ", -$diff, " superfluous node(s) with $func\n";
			}
			while ($diff > 0) { # less nodes with the given functor than should be
				my $new_node = create_tnode($t_node, $func);
				info "$tid: new node with $func\n";
				push @{$nodes{ $func }}, $new_node;
				$diff--;
			}
		}

	}

	# make common modifications from generated modifications of members of a coordination
	for my $t_node ($t_root->get_descendants) {
		$t_node->is_coap_root or next;
		my %common; # { functor }{ parent } => generated children with this functor having this parent, which is a coordinated node
		my @coorded = $t_node->get_transitive_coap_members; # coordinated nodes
		for my $par (@coorded) {
			for my $ch (real_children($par)) {
				$common{ $ch->get_attr('functor') }{ $par->get_id } = $ch if $ch->get_attr('is_generated') && $ch->get_children == 0;
			}
		}
		for my $func (grep { keys %{$common{$_}} == @coorded } sort keys %common) {
			for my $ch_node (values %{$common{$func}}) {
				$ch_node->disconnect;
			}
			my $new_node = create_tnode($t_node, $func);
		}
	}

	for my $t_node ($t_root->get_descendants) {
		$t_node->set_attr('eff_func', undef);
	}

	# normalize deepords
	$t_root->normalize_node_ordering;
	
}

#======================================================================

1;

