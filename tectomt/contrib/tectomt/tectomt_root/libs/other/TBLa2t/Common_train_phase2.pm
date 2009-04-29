use 5.008;
use strict;
use warnings;

use Report;

use TBLa2t::Common;
if (exists($INC{'TBLa2t/Common_phase2.pm'})) {
	do $INC{'TBLa2t/Common_phase2.pm'};
} else {
	require TBLa2t::Common_phase2;
}

our $tree_no; # number of the current tree in a file

my %aid2char; # {a-node's id} -> a char representing it in a transformation
my $node_ch;  # the char representing an "old" node in transformation
my $new_node_ch; # the char representing a new node in transformation
my %del_nodes; # aids of nodes deleted in the transformation

#======================================================================

sub gen
{
	my ($node) = @_;
	$node or Report::fatal "Assertion failed";
	return $node->get_attr('is_generated')? 1:0;
}

#======================================================================

sub bad_trans
{
	info "\n  ! $_[0]\n";
	goto SKIP; # dirty, but seems to work
}

#======================================================================

sub get_trans
{
	my ($marked, $node, $what) = @_;
	if ($what) {
		$node_ch lt 'Z' or bad_trans("TOO COMPLICATED TRANSFORMATION");
		$aid2char{ aid($node) } = $node_ch++;
	}
	elsif (!aid($node)) {
		$new_node_ch lt '9' or bad_trans("TOO COMPLICATED TRANSFORMATION");
		$aid2char{ $node->get_id } = $new_node_ch++;
	}
	my @children = grep { $marked->{ aid($_)? aid($_) : $_->get_id } } $node->get_children;
	my $ch_str = join ',', sort map { get_trans($marked, $_, $what) } @children;
	if (!$what && aid($node) && !defined $aid2char{ aid($node) }) {
		bad_trans("LOST NODE IN TRANSFORMATION");
	}
	if (!$what) {
		delete $del_nodes{ aid($node) };
	}
	return (aid($node)? ($node->get_attr('is_generated')? lc($aid2char{ aid($node) }) : $aid2char{ aid($node) }) : '*') . ($ch_str ne ""? "(".$ch_str.")" : "");
}

#======================================================================

sub mark_to_tree
{
	my ($root, $a2t, $a_marked, $VYP) = @_;
	my %t_marked = (); # t-nodes being part of transformation; 1=permanent, 2=temporary

	my $count = -keys %$a_marked; # how much nodes has been marked newly

	# convert $a_marked into %t_marked
	for my $a_node (keys %$a_marked) {
		map { $t_marked{ $_->get_id } = 1 } @{$a2t->{$a_node}};
	}

	# mark all nodes on the path from the given nodes to the root
	for my $t_node (map { $root->get_document->get_node_by_id($_) } sort keys %t_marked) {
		$t_node or Report::fatal "Assertion failed";
		$t_node->get_root eq $root or Report::fatal "Assertion failed: ". $t_node->get_root->get_id. " vs. ". $root->get_id;
		for ( ; $t_node ne $root ; $t_node = $t_node->get_parent) {
			$t_node or Report::fatal "Assertion failed";
			$t_marked{ $t_node->get_id } or $t_marked{ $t_node->get_id } = 2;
		}
	}
	$t_marked{ $root->get_id } or $t_marked{ $root->get_id } = 2;

#	info join " ", map { "$_=>" . $t_marked{$_} } sort keys %t_marked;

	# unmark nodes on path from the root if they are marked temporarily and have 1 child
	my $t_node = $root;
	while ($t_marked{ $t_node->get_id } == 2) {
		my @m_child = grep { $t_marked{ $_->get_id } } $t_node->get_children;
		@m_child or bad_trans("NODES TO BE TRANSFORMED NOT FOUND IN THE OTHER TREE");
		last if @m_child > 1;
		delete $t_marked{ $t_node->get_id };
		$t_node = $m_child[0];
	}

	# mark all temporarily marked nodes as permanent ones
	for (keys %t_marked) {
		my $t_node = $root->get_document->get_node_by_id($_);
		$t_node or Report::fatal "Assertion failed";
		aid($t_node)? ($a_marked->{ aid($t_node) } = 1) : ($a_marked->{ $t_node->get_id } = 2);
	}

	$count += keys %$a_marked;

	return $count;
}

#======================================================================

sub diff
{
	my ($gold_t_root, $est_t_root) = @_;

	my @a2t = (); # [file no: 0 or 1]->{a/t-node's id}->[corresp. t-node]
	my @moved = (); # [is_generated? 1:0]->{a-id} = whether this node's location differs between the trees; only nodes existing already on the a-layer are recorded
	my %aid2trans = (); # {a-node's id} = order number of the corresp. transformation; full only for 'B' node of every transformation
	my $file_no; # 0: golden tree; 1: estimated tree

	#---------------------------------------------------------------------
	# get structure of two corresponding trees
		
	info '=== ', $gold_t_root->get_id, " [", ++$tree_no, "]\n";

	# get structure from the 1st ("true") file
	my $a_root = get_anode($gold_t_root);
	for my $t_node ($gold_t_root->get_self_and_descendants) {
		# only nodes originating from an a-node (for others just get a2t)
		unless (aid($t_node)) {
			push @{ $a2t[0]->{ $t_node->get_id } }, $t_node;
			next;
		}
		
		# only nodes pointing into the sentence they are in (otherwise there will occur a problem below)
		# (it is correct to have it here -- "guess" file surely does not contain such nodes)
		my $a_node = get_anode($t_node);
		$a_node or Report::fatal "Assertion failed: " . aid($t_node);
		$a_root eq $a_node->get_root or next;

		# record the structure
		push @{ $a2t[0]->{ aid($t_node) } }, $t_node;
		$moved[ gen($t_node) ]{ aid($t_node) } = gen($t_node->get_parent).aid($t_node->get_parent) if $t_node ne $gold_t_root;
	}
	undef $a_root;

	# get structure from the 2nd ("guess") file
	for my $t_node ($est_t_root->get_self_and_descendants) {
		push @{ $a2t[1]->{ aid($t_node) } }, $t_node if aid($t_node);
		$t_node ne $est_t_root or next;
		aid($t_node) or next; #!! pripsano

		# change %moved
		#! na nasledujicich radcich bylo misto gen($t_node) drive 0, ale i kdyz ma t-uzel aid, muze byt generovan
		if (!exists $moved[ gen($t_node) ]{ aid($t_node) }) { # the node does not exist in the "true" file => it is marked as moved
			$moved[ gen($t_node) ]{ aid($t_node) } = 1;
		}
		elsif ($moved[ gen($t_node) ]{ aid($t_node) } eq gen($t_node->get_parent) . aid($t_node->get_parent)) { # the node has the same parents in both files => its record will be deleted (the usual case)
			delete $moved[ gen($t_node) ]{ aid($t_node) };
		}

	}

	# omit nodes with empty @{ $a2t[ 1 ]->{ $_ } } i.e. such that occur in the true file but not in the guess file i.e. they were accidentaly deleted and are lost
	for my $f (0..1) { # they can be non-generated or even generated
		for (sort keys %{$moved[ $f ]}) {
			defined $_ or Report::fatal "Assertion failed";
			unless ($a2t[ 1 ]->{ $_ }) {
				delete $moved[ $f ]{ $_ };
				info "  L $_\n";
			}
		}
	}

	# assistant print
	for my $k (0..1) {
		map { info "  M $k $_\n" } sort keys %{$moved[ $k ]};
	}


	#---------------------------------------------------------------------
	# search for transformations
	
	while (1) {
		$file_no = 1;

		my %marked = (); # {a/t-node's id} = whether involved in transformation (1/2)
		my $seed_id; # id of a-node beeing the seed of a transformation
		my @keys_1 = sort keys %{$moved[ 1 ]};
		my @keys_0 = sort keys %{$moved[ 0 ]};

		# mark "seed" nodes of a transformation
		if (@keys_1) {
			# this involves nodes' copying
			$seed_id = $keys_1[0];

			# mark the original and copied nodes as parts of the transformation
			$marked{ $seed_id } = 1;
			$a2t[ $file_no ]->{ $seed_id } or Report::fatal "Assertion failed: $seed_id";
			for my $t_node (@{ $a2t[ $file_no ]->{ $seed_id } }) {
				info " ## ", $t_node->get_attr('t_lemma'), " ";
			}
		}
		elsif (@keys_0) {
			# this is only nodes' movement
			$seed_id = $keys_0[0];
			$marked{ $seed_id } = 1; # mark the moved node

			# choose a child or the parent and prefer that one which moved
			my @seeds = make_array($a2t[ $file_no ]->{ $seed_id });
			@seeds == 1 or Report::fatal "Assertion failed";
			my $t_node = @seeds[0];
			info " -- ", $t_node->get_attr('t_lemma'), " ";
			for (grep { $moved[ gen($_) ]{ aid($_) } } $t_node->get_children) {
				$marked{ aid($_) } = 1;
				goto FOUND;
			}
			$marked{ aid($t_node->get_parent)? aid($t_node->get_parent) : $t_node->get_parent->get_id } = 1; # mark its parent #! puvodne jen aid($t_node->get_parent), ale to mohlo byt prazdne; toto stejne nepracuje dobre
			FOUND:
		}
		else { # we are finished
			last;
		}

		# mark also some other nodes
		my $changed; # something changed, has to switch the trees and repeat it
		my $first = 1; # we want to surely make loop for the first time
		do {
			# mark also other nodes so that the resulting structure is a tree
			info "[$file_no]";
			$changed = mark_to_tree($file_no? $est_t_root : $gold_t_root, \%{$a2t[ $file_no ]}, \%marked, $file_no);

			# check whether the marked nodes point into the sentence they are in
			my $a_root = get_anode($file_no? $est_t_root : $gold_t_root);
			for my $a_id (sort keys %marked) {
				$a_id or Report::fatal "Assertion failed";
				next if $marked{ $a_id } == 2; # id of an t-node, will not point into another sentence
				my $a_node = ($file_no? $est_t_root : $gold_t_root)->get_document->get_node_by_id($a_id);
				$a_node or Report::fatal "Assertion failed: $a_id";
				if ($a_root ne $a_node->get_root) { # a node from another sentence
					bad_trans("OUT-OF-SENTENCE LINK");
				}
			}

			# mark also "moved" children of nodes involved in transformation
			my $changed_children; # whether some children were added
			do {
				$changed_children = 0;
				for my $t_node (map { @{ $a2t[ $file_no ]->{$_} } } sort keys %marked) {
					for my $ch ($t_node->get_children) {
						if (aid($ch) && $moved[ gen($ch) ]{ aid($ch) }) {
							$changed_children = 1 if !$marked{ aid($ch) };
							$marked{ aid($ch) } = 1;
						}
					}
				}
				$changed ||= $changed_children;
			} while $changed_children;

			# switch the trees (useless in the last loop)
			$file_no = 1-$file_no;

			$changed ||= $first;
			$first = 0;

		} while $changed;


		#---------------------------------------------------------------------
		# write down a transformation

		%aid2char = ();
		$node_ch = 'A'; $new_node_ch = '0';

		info "\n";
		
		# for the "guess" file
		my $subroot; # subroot of the transformed tree
		for ($est_t_root->get_self_and_descendants) {
			if ($marked{ aid($_) }) {
				$subroot = $_;
				last;
			}
		}
		$subroot or Report::fatal "Assertion failed";
		!$subroot->get_parent || !$marked{ aid($subroot->get_parent) } or Report::fatal "Assertion failed";
		my $trans_str = get_trans(\%marked, $subroot, 1); # string with description of a transformation

		# for the "true" file
		for ($gold_t_root->get_self_and_descendants) {
			if ($marked{ aid($_)? aid($_) : $_->get_id }) {
				$subroot = $_;
				last;
			}
		}
		$subroot or Report::fatal "Assertion failed";
		!$subroot->get_parent || !$marked{ aid($subroot->get_parent) } or Report::fatal "Assertion failed";
		map { $del_nodes{$_} = 1 } keys %aid2char;
		$trans_str .= "->" . get_trans(\%marked, $subroot, 0);
		undef $subroot;

		# gather info about the transformation -- traverse all marked a-nodes sorted according their letters
		my $aid_of_B; # the node the transformation is assigned to
		my $new_desc = ""; # string with description of new nodes
		my $cop_desc = ""; # string with description of copied nodes
		my $suc_desc = ""; # string with description of successor nodes

		for (sort { $aid2char{$a} cmp $aid2char{$b} } keys %marked) {

			# unless new node, make debug print
			unless ($aid2char{$_} =~ /[0-9]/) {
				my $a_node = $est_t_root->get_document->get_node_by_id($_);
				$a_node or Report::fatal "Assertion failed";
				info "    ", $aid2char{$_}, " = ", ($a_node->get_parent? adjust_lemma($a_node):"<root>"), "\n";
			}

			# for a new node...
			if ($aid2char{$_} =~ /[0-9]/) {
				my $t_node = $a2t[0]->{ $_ }->[0];
				$t_node or Report::fatal "Assertion failed";
				$new_desc .= '+' . $t_node->get_attr('functor'); # ... note down its functor
			}

			# for a copied node...
			if ($aid2char{$_} =~ /[A-Z]/) {
				my @gen = grep { $_->get_attr('is_generated') } @{$a2t[0]->{ $_ }};
				for my $i (0..@gen-1) {
					my $t_node = $gen[$i];
					$t_node or Report::fatal "Assertion failed";
					my $true_func = $t_node->get_attr('functor');
					$t_node = $a2t[0]->{ $_ }->[$i];
					$t_node or Report::fatal "Assertion failed";
					$cop_desc .= '+' . ($t_node->get_attr('functor') eq $true_func? "@" : $true_func); # ... note down its functor or '@' if the same as in the original node
				}
			}

			# for a node deleted during the transformation...
			if ($del_nodes{$_}) {
				my $a_node_id = $_;
				my $t_node; # the node with aid of the deleted node in its a/aux.rf
				for my $n ($gold_t_root->get_self_and_descendants) {
					$t_node = $n if grep { $_ eq $a_node_id } make_array($n->get_attr('a/aux.rf'));
				}
				my $suc_char; # char of successor of a deleted node
				if ($t_node) {
					$suc_char = $aid2char{ aid($t_node) }; # is letter of the node
					defined $suc_char or $suc_char = '#'; # the successor is not part of the transformation
				}
				else {
					$suc_char = '0'; # the node should be totaly deleted
				}
				$suc_desc .= '+' . $suc_char;
			}
					

			# for 'B'-node ...				
			if ($aid2char{$_} eq 'B') {
				$aid_of_B = $_;
				$aid2trans{ $aid_of_B } = $trans_str; # write down the transformation to it
			}

			# for 'C' and further nodes ...
			if ($aid2char{$_} =~ /[C-Z]/) {
				my $t_node = $a2t[1]->{ $_ }->[0];
				my $a_node = $t_node->get_lex_anode;
				$a_node or Report::fatal "Assertion failed";
				$aid2trans{ $aid_of_B } .= '+' . $a_node->get_attr('afun'); # ... add its some characteristic
			}
		}
		$new_desc =~ s/^./:/; # description of new nodes will begin with ':'
		$cop_desc =~ s/^./;/; # description of new nodes will begin with ';'
		$suc_desc =~ s/^./\|/; # description of new nodes will begin with '|'
		defined $aid_of_B or goto SKIP; # in case of transformation with only one node -- it is strange
		$aid2trans{ $aid_of_B } .= $new_desc . $cop_desc . $suc_desc; # merge all info to 'B'-node
		info "    ", $aid2trans{ $aid_of_B }, "\n";

		#---------------------------------------------------------------------
		# epilogue
		
		SKIP:
		# delete solved items in @moved
		for (sort keys %marked) {
			info "  D 0 $_\n" if $moved[ 0 ]{ $_ };
			delete $moved[ 0 ]{ $_ };
			info "  D 1 $_\n" if $moved[ 1 ]{ $_ };
			delete $moved[ 1 ]{ $_ };
		}

	} # transformations
	
	# write down the output for one pair of trees
	for my $t_node ($est_t_root->get_descendants) {
		printf "%s - %s\n",
			feature_string($t_node),
			defined $aid2trans{ aid($t_node) }? $aid2trans{ aid($t_node) } : '-';
	}

}

#======================================================================

1;

# Uzly ve dvou sobe odpovidajicich stromech jsou povazovany za sobe odpovidajici, pokud odkazuji na stejny a-uzel a jsou oba (ne)generovane. (Mozny problem: 3 a vice uzlu odkazujicich na stejny a-uzel, ale to se asi nevyskytne.)
# Uzly vyskytujici se v transformacich tedy vystupuji pod svym aid, coz pusobi problem pri zpracovani nove vzniknuvsiho uzlu; osetreni:
# - do %moved se nove uzly nezapisuji, protoze kvuli nim se transformace nedela, jsou v ni jen trpeny
# - do a2t[0] se zapisuji; poznaji se (zde a vsude, kde opravdu uzel drzim) dle nedefinovaneho aid()
# - do marked se zapisuji; poznaji se dle hodnoty hashe = 2
