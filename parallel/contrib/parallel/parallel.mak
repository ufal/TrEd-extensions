# -*- cperl -*-

package Parallel_Treebank;

#binding-context Parallel_Treebank
sub NoOp {}

use strict;

BEGIN { import TredMacro; }

#include <contrib/support/arrows.inc>
use warnings;

## detect files with the expected PML schema
sub detect {
  return (((PML::SchemaName()||'') eq 'parallel') ? 1 : 0);
}
push @TredMacro::AUTO_CONTEXT_GUESSING, sub {
  my $current = CurrentContext();
  return __PACKAGE__ if detect();
  return;
};
sub allow_switch_context_hook {
  return 'stop' unless detect();
}

#bind toggle_layout to l menu Toggle Layout (side by side / one below the other)
our $trees_side_by_side = 0;
sub toggle_layout {
  $trees_side_by_side=!$trees_side_by_side;
}

#bind toggle_arrow_style to s menu Toggle Alignment Arrow Style (straight / curved)
our $straight_arrows = 1;
sub toggle_arrow_style {
  $straight_arrows = !$straight_arrows;
}

## get document_a or document_b
sub get_subdocument {
  my ($fsfile,$which)=@_;
  return undef unless ref($fsfile->metaData('refnames')) and ref($fsfile->appData('ref'));
  my $refid = $fsfile->metaData('refnames')->{$which};
  return defined($refid) && $fsfile->appData('ref')->{$refid};
}

sub get_document_a {
  return get_subdocument($_[0]||$grp->{FSFile},'document_a');
}

sub get_document_b {
  return get_subdocument($_[0]||$grp->{FSFile},'document_b');
}

our %b_node;

## give TrEd a list of nodes to display (nodes from document_a followed by nodes from document_b)
sub get_nodelist_hook {
  my ($fsfile,$tree_no,$current,$show_hidden)=@_;
  my $root = $fsfile->tree($tree_no);
  my @nodes;
  my $arf = $root->{'tree_a.rf'}; $arf=~s/^.*#//;
  my $brf = $root->{'tree_b.rf'}; $brf=~s/^.*#//;
  my $a_root = PML::GetNodeByID($arf, get_document_a());
  my $b_root = PML::GetNodeByID($brf, get_document_b());
  push @nodes, sort {$a->{order}<=>$b->{order}} ($a_root, $a_root->descendants)
    if $a_root;
  my @b_nodes;
  @b_nodes = sort {$a->{order}<=>$b->{order}} ($b_root, $b_root->descendants)
    if $b_root;
  %b_node=();
  @b_node{@b_nodes}=();
  push @nodes, @b_nodes;
  return [ \@nodes, $current ];
}

# positioning, node style options, and alignment arrows
our %alignments;
sub node_style_hook {
  my ($node,$styles) = @_;
  if (exists $b_node{$node}) {
    AddStyle($styles,'Node',
	     -shape => 'rectangle',
	     -segment=>'0/0',
	    );
  } else {
    AddStyle($styles,'Node',
	     $trees_side_by_side ? (-segment=>'0/1') : (-segment=>'1/0')
	    );
    my $targets = $alignments{$node->{'xml:id'}};
    if ($targets and @$targets) {
      my $bfile = get_document_b();
      DrawArrows($node,$styles,
		 [ map {{
		   -target => PML::GetNodeByID($_,$bfile),
		     ($straight_arrows ? (
		       -smooth => 0,
		       -frac => "0.0",
		       -raise => "0.0",
		      ) : (
			-smooth => 1,
			-raise => -25,
			-frac => -0.12,
		       )),
		   -arrow => 'last',
		   -arrowshape => '12,20,6',
		   -fill => 'lightgray',
		   # other options: -tag -arrow -arrowshape -width -smooth -fill -dash
		 }} @$targets],
		 {
		   # options common to all edges
		  }
		);
    }
  }
}

sub root_style_hook {
  my ($node,$styles,$opts)=@_;
  %alignments=();
  for my $c ($root->children) {
    my $arf = $c->{'a.rf'};
    my $brf = $c->{'b.rf'};
    $arf=~s/^.*#//;
    $brf=~s/^.*#//;
    push @{$alignments{$arf}},$brf;
  }
  DrawArrows_init();
}
sub after_redraw_hook {
  %alignments=();
  DrawArrows_cleanup();
}

# drag and drop creates/removes alignment arrows
sub node_release_hook {
  my ($node,$target)=@_;

  # source mode and target node must be from document_a and document_b respectively 
  # or vice versa
  if (exists($b_node{$node}) xor exists($b_node{$target})) {
    my @ab = exists($b_node{$target}) ? qw(a b) : qw(b a);
    my @ids = ($node->{'xml:id'}, $target->{'xml:id'});
    # try to find an existing alignment first
    for my $alignment ($root->children) {
      my @refs = map $alignment->{"$_.rf"}, @ab;
      s{^.*#}{} for (@refs);
      if ($refs[0] eq $ids[0] and $refs[1] eq $ids[1]) {
	# these two nodes are already aligned
	DeleteLeafNode($alignment);
	Redraw_FSFile_Tree();
	ChangingFile(1);
	return 'stop';
      }
    }
    # no alignment exists yet, creating a new one
    my $doc_name2doc_id = FileMetaData('refnames');
    my $alignment = FSNode->new({
      "$ab[0].rf" => $doc_name2doc_id->{"document_$ab[0]"}."#$ids[0]",
      "$ab[1].rf" => $doc_name2doc_id->{"document_$ab[1]"}."#$ids[1]",
    },1);
    PasteNode($alignment,$root);
    Redraw_FSFile_Tree();
    ChangingFile(1);
    return 'stop';
  }
  return;
}

1;
