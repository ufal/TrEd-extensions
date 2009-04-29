use 5.008;
use strict;
use warnings;

use TBLa2t::Common;
if (exists($INC{'TBLa2t/Common_phase3.pm'})) {
	do $INC{'TBLa2t/Common_phase3.pm'};
} else {
	require TBLa2t::Common_phase3;
}

our $tree_no; # number of the current tree in a file

#======================================================================

sub diff
{
	my ($gold_t_root, $est_t_root) = @_;

	my (%before, %after); # info about children in guess and true files:
												#   { parent's aid }{ child's functor }-> # of such cases
	my %t_nodes;          # { aid }->t-node from the true file

	info '=== ', $gold_t_root->get_id, " [", ++$tree_no, "]\n";

	# get structure from the 1st ("true") file
	for my $t_node ($gold_t_root->get_descendants) {
		next if $t_node->get_attr('is_generated') || $t_node->is_coap_root; # generated parents and coordinations are ignored
		for my $ch (real_children($t_node)) {
			$after{ aid($t_node) }{ $ch->get_attr('eff_func') }++;
		}
		$t_nodes{ aid($t_node) } = $t_node;
	}

	# get structure from the 2nd ("guess") file
	for my $t_node ($est_t_root->get_descendants) {
		next if $t_node->get_attr('is_generated') || $t_node->is_coap_root; # generated parents and coordinations are ignored
		my $aid = aid($t_node);
		my $t_true = $t_nodes{ $aid }; # the counterpart to the t-node from the true file
		unless ($t_true) { # the counterpart is not found
			info $t_node->get_id, ": counterpart not found\n";
			next;
		}
		for my $ch (real_children($t_node)) {
			$before{ $aid }{ $ch->get_attr('eff_func') }++;
		}
		info $t_node->get_id, " (", $t_node->get_attr('t_lemma'), "): ", $t_node->get_attr('functor'), " => ", $t_true->get_attr('functor'), "\n" if $t_node->get_attr('functor') ne $t_true->get_attr('functor');

		# debug print of generated nodes
		no warnings 'uninitialized';
		for my $func (sort keys %{$after{ $aid }}) {
			if ($after{ $aid }{ $func } > $before{ $aid }{ $func }) {
				info $t_node->get_id, " (", $t_node->get_attr('t_lemma'), "): ", "$func " x ($after{ $aid }{ $func } - $before{ $aid }{ $func }), "\n";
			}
		}
		use warnings 'uninitialized';

		# printing of training data
		defined $t_node->get_attr('t_lemma') or Report::fatal "No t_lemma: ".$t_node->get_id;
		print feature_string($t_node);
		no warnings 'uninitialized';
		for my $i (0..@func3-1) { # print input functors
#			printf "%d%s ", $before{ $aid }{ $func3[$i] }, $Common_phase3::uniq[$i];
			printf "%d ", $before{ $aid }{ $func3[$i] };
		}
		use warnings 'uninitialized';
		my $val = $t_nodes{ $aid }->get_attr('val_frame.rf');
		print $val && !ref($val)? $val." " : "--- "; # true valency frame #! muze byt pole -- prip. osetrit lepe
		print $t_true->get_attr('functor'), " "; # true functor
		no warnings 'uninitialized';
		for my $i (0..@func3-1) { # print true functors
#			printf "%d%s ", $after{ $aid }{ $func3[$i] }, $Common_phase3::uniq[$i];
			printf "%d ", $after{ $aid }{ $func3[$i] };
		}
		use warnings 'uninitialized';
		print "\n";
	}
}

#======================================================================

1;

