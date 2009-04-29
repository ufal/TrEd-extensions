use 5.008;
use warnings;
use strict;

#======================================================================

sub totbl
{
	my ($ftbl, $t_root) = @_;

	for my $t_node ($t_root->get_descendants) {
		$t_node->get_lex_anode or next;
		defined $t_node->get_attr('t_lemma') or Report::fatal "Assertion failed";

		# printing of training data
		print $ftbl feature_string($t_node);
		print $ftbl "---\n"; # true functor
	}
}

#======================================================================

sub merg
{
	my ($ftbl, $t_root) = @_;
	
	for my $t_node ($t_root->get_descendants) {
		$t_node->get_lex_anode or next;

		# read and check data
		my $line;
		defined ($line = <$ftbl>) or Report::fatal "Unexpected end of file";
		$line =~ s/(.*)\| ([0-9]+ )*$/$1/; # strip rule' numbers
		my $a_node = get_anode($t_node);
		my $func = parse_and_check_line($line, adjust_lemma($a_node));
		$t_node->set_attr('functor', $func);
		if (!$t_node->is_coap_root && grep { $_->is_coap_member } $t_node->get_children) { $t_node->set_attr('functor', 'CONJ') } # otherwise the error propagates to the children
	}
}

#======================================================================

1;

