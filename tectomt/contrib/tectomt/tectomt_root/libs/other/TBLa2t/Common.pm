package TBLa2t::Common;

use 5.008;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw($FNTBL info aid get_anode attr init_new_tnode init_copied_tnode add_is_member make_array fntbl_fnames);

use Report;

our $FNTBL = "$ENV{TMT_SHARED}/external_tools/fnTBL-1.1";

use Data::Dumper;

#======================================================================

sub info
{
	map { print STDERR $_ } @_;
}

#======================================================================

sub aid
{
	my ($t_node) = @_;
	$t_node or Report::fatal "Assertion failed";
	my $aid = $t_node->get_attr($t_node eq $t_node->get_root? 'atree.rf' : 'a/lex.rf');
	return defined $aid? $aid : "";
}

#======================================================================

sub get_anode
{
	my ($t_node) = @_;
	my $aid = aid($t_node);
	return $aid? $t_node->get_document->get_node_by_id($aid) : undef;
}

#======================================================================

my %_attr_default = ('m/lemma' => 6, 'afun' => 3, 'functor' => 3, 't_lemma' => 6, 'm/tag' => 15, 'gram/sempos' => 3, 'subfunctor' => 3);

sub attr
{
	my ($node, $attr) = @_;
	$_attr_default{$attr} or Report::fatal "Assertion failed ($attr)";
	$node or return '#' x $_attr_default{$attr};
	my $val = $node->get_attr($attr);
	return defined $val && $val ne ""? $val : '-' x $_attr_default{$attr};
}

#======================================================================

sub new_id
{
	my ($root) = @_;
	my $base = $root->get_id;
	$base =~ s/([0-9])[^0-9]*$/$1/; # base: from the beginning up to the last digit, if any
	$base .= "-new";
	my $no = 1;
	while ($root->get_document->id_is_indexed($base.$no)) { $no++ }
	return $base.$no;
}

#======================================================================

sub clone_id
{
	my ($orig) = @_;
	my $orig_id = $orig->get_id;
	my $suff = 'a';
	while ($orig->get_document->id_is_indexed($orig_id.$suff)) { $suff++ }
	return $orig_id.$suff;
}

#======================================================================

# Assigns (dirty) deepord -- place the node to the right/left of the subtree of its parent

sub set_order
{
	my ($t_node, $t_par, $ord_right) = @_;
	my @desc = map { $_->get_ordering_value } $t_par->get_ordered_descendants;
	@desc or @desc = ($t_par->get_ordering_value);
	$t_node->set_ordering_value($ord_right? $desc[-1] + 0.1 : $desc[0] - 0.1);
}

#======================================================================

# Assigns is_generated, nodetype, deepord, id, and parent to the new t-node

sub init_new_tnode
{
	my ($new_n, $parent, $ord_right) = @_;
	my $id = new_id($parent->get_root); # id must be got before set_parent -- is this still true?
	$new_n->set_attr('is_generated', 1);
	$new_n->set_attr('nodetype', 'complex');
	set_order($new_n, $parent, $ord_right);
	$new_n->set_parent($parent);
	$new_n->set_attr('id', $id); # id must be set after set_parent
}

#======================================================================

sub clone_value
{
	if (ref $_[0]) {
		my $val; # has to be here
		return eval Data::Dumper->new([$_[0]], ['val'])->Purity(1)->Dump;
	}
	else {
		return $_[0];
	}
}

sub init_copied_tnode
{
	my ($new_n, $orig, $parent) = @_;
	for my $attr (qw(t_lemma val_frame.rf functor subfunctor is_member is_parethesis is_state tfa coref_gram.rf coref_text.rf coref_special compl_rf nodetype sempos gram a quot is_dsp_root is_name_of_person)) {
		$new_n->set_attr($attr, clone_value($orig->get_attr($attr))) if defined $orig->get_attr($attr);
	}
	$new_n->set_attr('is_generated', 1);
	set_order($new_n, $parent, 1);
	$new_n->set_parent($parent);
	$new_n->set_attr('id', clone_id($orig)); # id must be set after set_parent
}

#======================================================================

# Determines which nodes are members of a coordination mainly on the basis of their functors.
# Recursive procedure. Returns effective functor of the input node.
# Nested coordinations are handled correctly. The procedure tries to be as robust as possible.

no warnings "recursion";

sub add_is_member
{
	my ($node) = @_;
	my %ch_func = (); # {functor} -> (children of $node having the functor)
	my $max; # functor with maximal number of children

	for my $ch ($node->get_children) {
		my $func = add_is_member($ch);
		push @{$ch_func{$func}}, $ch;
	}

	if ($node eq $node->get_root || !$node->is_coap_root) { # unless coord node ...
		map { $_->set_attr('is_member', undef) } $node->get_children; # ... it has no members
		return $node->get_attr('functor');
	}

	# only for coordinations from now
	for (sort keys %ch_func) {
		if (@{$ch_func{$_}} >= 2) {
#			!defined $max or info "# ", $node->get_id, ": conflicting functors ($max vs. $_)\n";
			$max = $_;
		}
	}

	unless (defined $max) { # no functor with at least 2 nodes
		if ($node->get_children) {
			if (scalar($node->get_direct_coap_members)) { # some children are members => retain everything
#				info "^ ", $node->get_id, ": children unchanged\n";
				map { return $_->get_attr('functor') } $node->get_direct_coap_members; # any child being a member
			}
			else { # none of the children is member => they all become members
#				info "@ ", $node->get_id, ": all children forced to be members\n";
				map { $_->set_attr('is_member', 1) } $node->get_children;
				return $node->get_leftmost_child->get_attr('functor');
			}
		}
		else { # no children => nothing to solve
#			info "\$ ", $node->get_id, ": coord without members\n";
			return $node->get_attr('functor');
		}
	}

	map { $_->set_attr('is_member', undef) } $node->get_children;
	map { $_->set_attr('is_member', 1) } @{$ch_func{$max}};
	return $max;
}

use warnings "recursion";

#======================================================================

sub make_array
{
	my ($aref) = @_;
	return () if !defined $aref || $aref eq '';
	return @$aref if UNIVERSAL::isa($aref, "ARRAY");
	# else assume $aref is just one member, but this is weird
	Report::debug "Not an array reference nor undef (".ref($aref).") is the argument of make_array()";
	return ($aref);
}

#======================================================================

sub fntbl_fnames
{
	my ($fname, $phase) = @_;
	$fname =~ s/\.[^\/]*$/\./;
	return ($fname.$phase."i.tbl", $fname.$phase."o.tbl");
}

#======================================================================

1;

