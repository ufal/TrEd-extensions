use 5.008;
use strict;
use warnings;

use TBLa2t::Common;
if (exists($INC{'TBLa2t/Common_phaseF.pm'})) {
	do $INC{'TBLa2t/Common_phaseF.pm'};
} else {
	require TBLa2t::Common_phaseF;
}

our $tree_no; # number of the current tree in a file

#======================================================================

sub diff
{
	my ($gold_t_root) = @_;

	info '=== ', $gold_t_root->get_id, " [", ++$tree_no, "]\n";

	# generate the data from the 1st ("true") file
	for my $t_node ($gold_t_root->get_descendants) {
		$t_node->get_lex_anode or next;

		# printing of training data
#		defined $t_node->get_attr('t_lemma') or Report::fatal "No t_lemma: ".$t_node->get_id;
		print feature_string($t_node);
		print $t_node->get_attr('functor'); # true functor
		print "\n";
	}
}

#======================================================================

1;

