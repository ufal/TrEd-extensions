use 5.008;
use warnings;
use strict;

use TBLa2t::Common;
#if (exists($INC{'TBLa2t/Common_phase4.pm'})) {
#	do $INC{'TBLa2t/Common_phase4.pm'};
#} else {
#	require TBLa2t::Common_phase4;
#}

our $tree_no; # number of the current tree in a file

#======================================================================

sub diff
{
	my ($gold_t_root, $est_t_root) = @_;

	my %after;   # info about children in guess and true files:
							 #   { parent's aid }{ child's functor }->child's t_lemma
	my %t_nodes; # { aid }->t-node from the true file
	
	info '=== ', $gold_t_root->get_id, " [", ++$tree_no, "]\n";

	# get structure from the 1st ("true") file
	for my $t_node ($gold_t_root->get_descendants) {
		if (aid($t_node)) {
			$t_nodes{ aid($t_node) } = $t_node;
		}
		else {
			my $t_par = ($t_node->get_eff_parents)[0];
			$t_par or Report::fatal "Assertion failed: ".$t_node->get_id;
			unless (aid($t_par)) {
				info "Nor the node ", $t_node->get_id, " nor its eparent have their aids\n";
				next;
			}
			$after{ aid($t_par) }{ $t_node->get_attr('functor') } = $t_node;
		}
	}

	# get structure from the 2nd ("guess") file
	for my $t_node ($est_t_root->get_descendants) {
		my $t_par = ($t_node->get_eff_parents)[0]; # t-parent of the node
		$t_par or Report::fatal "Assertion failed: ".$t_node->get_id;
		my $pair = aid($t_node)? $t_nodes{ aid($t_node) } : $after{ aid($t_par) }{ $t_node->get_attr('functor') };
		defined $pair or next;

		# printing of training data
		print feature_string($t_node); # print features
		print true_values($t_node, $pair); # print true values of classes
	}
}

#======================================================================

1;

