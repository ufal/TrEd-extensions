# -*- cperl -*-

use strict;
BEGIN {
  import PML_T_View;
  $PDT_25_T::mwe_folding = 1;
  $PDT_25_T::show_legend = 0;
}

#This hash and its use in after_redraw_hook() is needed to keep constant
#order of annotators between trees in files that include multiple
#annotators' annotations. 
our %annotator;

# Numerical positions of roots of all trees. Drawing of arrows is a bit faster.
# But the main reason is that (while using the standard methods) the SVG print
# crashes on coreference arrows leading to nodes in diferrent trees.
our %root_index;

sub detect {
  return (PML::SchemaDescription() =~ m/^PDT 2\.5/ and PML::SchemaName() eq 'tdata') ? 1 : 0;
}

sub allow_switch_context_hook {
  return 'stop' unless detect();
}

sub switch_context_hook {
  my $cur_stylesheet = GetCurrentStylesheet();
  if ($cur_stylesheet ne 'PDT_25_T') {
    SetCurrentStylesheet('PDT_25_T');
    Redraw() if GUI();
  }
  return;
}

sub toggle_clause_coloring {
  PDT_25_A::toggle_clause_coloring();
}

sub toggle_mwe_folding {
  return unless SchemaName() eq 'tdata';
  $PDT_25_T::mwe_folding = !$PDT_25_T::mwe_folding;
  my $mwe_mapping = FileUserData('mwe');

  my $new_this = $this;
  if ($PDT_25_T::mwe_folding and exists $mwe_mapping->{$this->{id}}) {
    $new_this = $mwe_mapping->{$this->{id}};
  } elsif (!$PDT_25_T::mwe_folding and exists $this->{'mwe_root'}) {
    $new_this = $this->{'mwe_root'};
  }
  $this = $new_this;
  
  foreach my $tree (GetTrees()) {
    rehang_mwes($tree);
  }

  ChangingFile(0);
}

sub rehang_mwes {
  my $tree = shift;
  return unless $tree->{'_mwe_ok'};
  my $mapping = FileUserData('mwe');

  $tree->{hide} = 0;
  foreach my $node ($tree->descendants) {
    if (exists($node->{'mwe_parent'})) {
      if ($PDT_25_T::mwe_folding) {
        CutPaste($node, $node->{'mwe_parent'});
      } else {
        CutPaste($node, $node->{'std_parent'});
      }
    }

    if (exists $node->{'mwe_refs'}) {
      foreach my $ref (@{$node->{'mwe_refs'}}) {
        $node->{$ref->[0]} = ListV(ListSubtract($node->{$ref->[0]}, List($ref->[1], $ref->[2])));
        AddToList($node, $ref->[0], $PDT_25_T::mwe_folding ? $ref->[2] : $ref->[1]);
      }
    }

    if (exists $mapping->{$node->{id}}) {
      $node->{hide} = $PDT_25_T::mwe_folding ? 1 : 0;
    } elsif (exists $node->{'mwe_root'}) {
      $node->{hide} = $PDT_25_T::mwe_folding ? 0 : 1;
    } else {
      $node->{hide} = 0;
    }
  }
}

sub toggle_legend {
  $PDT_25_T::show_legend = !$PDT_25_T::show_legend;
  ChangingFile(0);
}

sub get_value_line_hook {
  my ($fsfile,$treeNo)=@_;
  return unless $fsfile;
  my $tree = $fsfile->tree($treeNo);
  return unless $tree;
  my ($a_tree) = GetANodes($tree);
  return unless ($a_tree);
  
  my $mwe_mapping = FileUserData('mwe');
  
  my $node = $tree->following;
  my %refers_to;
    while ($node) {
    foreach (GetANodeIDs($node)) {
      push @{$refers_to{$_}}, $node;
      push(@{$refers_to{$_}}, $mwe_mapping->{$node->{id}}) if exists $mwe_mapping->{$node->{id}};
    }
    $node = $node->following;
  }
  
  $node = $a_tree->following;
  my @sent=();
  while ($node) {
    push @sent,$node if not exists $node->{'_representant'};
    $node=$node->following();
  }
  
  my @out;
  my @colors = qw(#ff00ff #ffa500 #0000ff #3cb371 #ff0000 #9932cc #00008b #006400 #8b0000 #008b8b);
  foreach $node (sort { $a->{ord} <=> $b->{ord} } @sent) {
    my $token = join(" ", map { $_->{token} } ListV($node->attr('m/w')));
    my $form = $node->attr('m/form');
    push @out, ([$form, @{$refers_to{$node->{id}} || []}, 'anode:'.$node->{id}]);
    if ($PDT_25_A::clause_coloring and $node->{clause_number}) {
      push @{$out[-1]}, '-foreground=>'.$colors[$node->{clause_number} % 10];
    }
    unless ($node->attr('m/w/[-1]/no_space_after')) {
      push @out, ([" ","space"]);
    }
  }
  
  return \@out;
}

sub get_nodelist_hook {
  my ($fsfile, $treeNo, $current) = @_;

  my $tree = $fsfile->tree($treeNo);
  prepare_mwe_folding($tree) if not $tree->{'_mwe_ok'};
  prepare_styles($tree) if not $tree->{'_styles_ok'};

  my @out = sort { $a->{deepord} <=> $b->{deepord} } ($tree, $tree->descendants);
  $current = $tree if not $current or $current->root != $tree;

  return [ \@out, $current ];
}

sub draw_legend {
  my $canvas = shift;

  $canvas->createRectangle(10, 10, 810, 265, -fill => 'LightYellow1', -outline => 'black', -width => 1);
  my @font_conf = (-anchor => 'w', -font => 'sans 10', -width => 230);
  my $stipples = TrEd::NodeGroups::dense_stipples($grp);

  # First column
  $canvas->createOval(25, 25, 32, 32, -fill => CustomColor('tnode'), -outline => 'black', -width => 1);
  $canvas->createText(40, 28, @font_conf, -text => 'Standard node or Root');
  $canvas->createOval(25, 45, 32, 52, -fill => CustomColor('tfa_t'), -outline => 'black', -width => 1);
  $canvas->createText(40, 48, @font_conf, -text => 'Non-contrastive contextually bound node');
  $canvas->createOval(25, 65, 32, 72, -fill => CustomColor('tfa_f'), -outline => 'black', -width => 1);
  $canvas->createText(40, 68, @font_conf, -text => 'Contextually non-bound node');
  $canvas->createOval(25, 85, 32, 92, -fill => CustomColor('tfa_c'), -outline => 'black', -width => 1);
  $canvas->createText(40, 88, @font_conf, -text => 'Contrastive contextually bound node');

  $canvas->createLine(25, 103, 270, 103, -fill => 'grey');

  $canvas->createOval(25, 115, 32, 122, -fill => CustomColor('tnode'), -outline => 'black', -width => 1);
  $canvas->createText(40, 118, @font_conf, -text => 'Node with a surface form');
  $canvas->createRectangle(25, 135, 32, 142, -fill => CustomColor('tnode'), -outline => 'black', -width => 1);
  $canvas->createText(40, 138, @font_conf, -text => 'Generated node');

  # Second column
  @font_conf = (-anchor => 'w', -font => 'sans 10', -width => 160);

  $canvas->createOval(312, 38, 319, 45, -fill => CustomColor('tnode_coord'), -outline => 'black', -width => 1);
  $canvas->createOval(295, 21, 336, 62, -outline => CustomColor('line_coord'), -width => 1, -dash => [5,5]);
  $canvas->createText(344, 41, @font_conf, -text => 'Coordination/Apposition root');
  $canvas->createRectangle(298, 73, 332, 107, -fill => 'white', -outline => undef);
  $canvas->createRectangle(300, 75, 330, 105, -fill => 'red', -stipple => $stipples->[0], -outline => undef);
  $canvas->createText(344, 90, @font_conf, -text => 'Multiword entity');
  $canvas->createPolygon(316, 120, 322.9, 132, 309.1, 132, -fill => CustomColor('mwe_node'), -outline => 'black');
  $canvas->createText(344, 127, @font_conf, -text => 'Folded multiword entity');

  # Third column
  @font_conf = (-anchor => 'w', -font => 'sans 10', -width => 240);

  # arrows
  $canvas->createLine(530, 28, 580, 28, -arrow => 'last', -arrowshape => [16, 18, 3], -fill => CustomColor('arrow_grammatical'));
  $canvas->createText(588, 28, @font_conf, -text => 'Grammatical coreference');
  $canvas->createLine(530, 48, 580, 48, -arrow => 'last', -arrowshape => [16, 18, 3], -fill => CustomColor('arrow_textual'));
  $canvas->createText(588, 48, @font_conf, -text => 'Textual coreference');
  $canvas->createLine(530, 68, 580, 68, -arrow => 'last', -arrowshape => [16, 18, 3], -fill => CustomColor('arrow_compl'));
  $canvas->createText(588, 68, @font_conf, -text => 'Second dependency');

  # edges
  $canvas->createLine(530, 88, 580, 88, -fill => CustomColor('line_normal'), -width => 2);
  $canvas->createText(588, 88, @font_conf, -text => 'Dependency');
  $canvas->createLine(530, 108, 580, 108, -fill => CustomColor('line_coord'), -width => 1);
  $canvas->createText(588, 108, @font_conf, -text => 'Non-dependency (paratactic structure)');
  $canvas->createLine(530, 128, 580, 128, -fill => CustomColor('line_comm'), -width => 2);
  $canvas->createText(588, 128, @font_conf, -text => 'Non-dependency (shared modifier)');
  $canvas->createLine(530, 148, 580, 148, -fill => CustomColor('line_normal'), -width => 1, -dash => [2, 4]);
  $canvas->createText(588, 148, @font_conf, -text => 'Non-dependency (other)');

  $canvas->createLine(25, 163, 795, 163, -fill => 'gray');
  
  # MWE types
  $canvas->createText(25, 182, -anchor => 'w', @font_conf, -text => 'Multiword entity types:');
  @font_conf = (-anchor => 'w', -font => 'sans 10', -width => 108);

  # First column
  $canvas->createRectangle(23, 198, 47, 222, -fill => 'white', -outline => undef);
  $canvas->createRectangle(25, 200, 45, 220, -fill => 'red', -stipple => $stipples->[0], -outline => undef);
  $canvas->createText(59, 210, @font_conf, -text => 'Semlex');
  $canvas->createRectangle(23, 228, 47, 252, -fill => 'white', -outline => undef);
  $canvas->createRectangle(25, 230, 45, 250, -fill => 'olive drab', -stipple => $stipples->[0], -outline => undef);
  $canvas->createText(59, 240, @font_conf, -text => 'Person');

  # Second column
  $canvas->createRectangle(180, 198, 200, 222, -fill => 'white', -outline => undef);
  $canvas->createRectangle(182, 200, 202, 220, -fill => 'hot pink', -stipple => $stipples->[0], -outline => undef);
  $canvas->createText(216, 210, @font_conf, -text => 'Institution');
  $canvas->createRectangle(180, 228, 200, 252, -fill => 'white', -outline => undef);
  $canvas->createRectangle(182, 230, 202, 250, -fill => 'turquoise1', -stipple => $stipples->[0], -outline => undef);
  $canvas->createText(216, 240, @font_conf, -text => 'Location');

  # Third column
  $canvas->createRectangle(337, 198, 361, 222, -fill => 'white', -outline => undef);
  $canvas->createRectangle(339, 200, 359, 220, -fill => 'plum', -stipple => $stipples->[0], -outline => undef);
  $canvas->createText(373, 210, @font_conf, -text => 'Object');
  $canvas->createRectangle(337, 228, 361, 252, -fill => 'white', -outline => undef);
  $canvas->createRectangle(339, 230, 359, 250, -fill => 'light slate blue', -stipple => $stipples->[0], -outline => undef);
  $canvas->createText(373, 240, @font_conf, -text => 'Address');

  # Fourth column
  $canvas->createRectangle(494, 198, 518, 222, -fill => 'white', -outline => undef);
  $canvas->createRectangle(496, 200, 516, 220, -fill => 'lime green', -stipple => $stipples->[0], -outline => undef);
  $canvas->createText(530, 210, @font_conf, -text => 'Time');
  $canvas->createRectangle(494, 228, 518, 252, -fill => 'white', -outline => undef);
  $canvas->createRectangle(496, 230, 516, 250, -fill => '#8aa3ff', -stipple => $stipples->[0], -outline => undef);
  $canvas->createText(530, 240, @font_conf, -text => 'Biblio');

  # Fifth column
  $canvas->createRectangle(651, 198, 671, 222, -fill => 'white', -outline => undef);
  $canvas->createRectangle(653, 200, 673, 220, -fill => '#8a535c', -stipple => $stipples->[0], -outline => undef);
  $canvas->createText(687, 210, @font_conf, -text => 'Foreign');
  $canvas->createRectangle(651, 228, 671, 252, -fill => 'white', -outline => undef);
  $canvas->createRectangle(653, 230, 673, 250, -fill => 'orange1', -stipple => $stipples->[0], -outline => undef);
  $canvas->createText(687, 240, @font_conf, -text => 'Number');
}

sub after_redraw_hook {
  my $treeview = shift;
  PML_T::after_redraw_hook($treeview);

  if ($PDT_25_T::show_legend) {
    draw_legend($treeview->realcanvas());
  }

  return if $PDT_25_T::mwe_folding;

  # The same colours as those used in the annotation tool sem-ann, 
  # except for red for 'real mwes' - i.e. SemLex entries other than NEs
  my %mwe_colours = ( 
    lexeme      => 'red', #originally 'maroon'
    person      => 'olive drab',
    institution => 'hot pink',
    location    => 'turquoise1',
    object      => 'plum',
    address     => 'light slate blue',
    time        => 'lime green',
    biblio      => '#8aa3ff',
    foreign     => '#8a535c',
    number      => 'orange1'
  );
  my @stipples = (qw(dense1 dense2 dense5 dense6));

  my @groups;
  my @group_colors;
  my @group_stipples;
  
  foreach my $snode ( ListV( $root->attr('mwes') || ()) ) {
    my $name = $snode->{annotator};
    $annotator{$name} = (keys %annotator) + 1 if not $annotator{$name};
    my $mwe_type = $snode->{type};
    my @group = map { GetNodeByID($_) } ListV( $snode->{'tnode.rfs'} );
    push @groups, [@group];
    push @group_colors, $mwe_colours{$mwe_type};
    push @group_stipples, $stipples[ $annotator{$name} -1 ];
  }
  TrEd::NodeGroups::draw_groups(
    $grp,
    \@groups,
    {
      colors   => \@group_colors,
      stipples => \@group_stipples
    }
  );
}

sub AnalyticalTree {
  return unless SchemaName() eq 'tdata';
  return unless SwitchToAFile();
  my $t_root = $root;
  my $t_node = exists $this->{'mwe_root'} ? $this->{'mwe_root'} : $this;
  SwitchContext('PDT_25_A');
  my $fsfile = $grp->{FSFile};

  #find current tree and new $this
  my $trees = $fsfile->treeList;
  my $treeNo = $fsfile->currentTreeNo+0;
  TREE: for (my $i=0; $i<=$#$trees; $i++) {
    foreach my $a_rf (GetANodeIDs($t_root)) {
      $a_rf =~ s/^.*?#//;
      if ($trees->[$i]->{id} eq $a_rf) {
	      $treeNo = $i;
	      last TREE;
      }
    }
  }

  TredMacro::GotoTree($treeNo+1); # changes $root and $this
  my $a_ids = GetNodeHash($fsfile);
  my $first =
    first {
      ref($a_ids->{$_}) and ($a_ids->{$_}->root == $root) ? 1 : 0
    } GetANodeIDs($t_node);
  my $a_node = $a_ids->{$first};
  if ($PDT_25_A::clause_folding) {
    if ($a_node->{'clause_number'}) {
      $a_node = FileUserData('clauses')->{$a_node->{id}};
    } else {
      $a_node = $a_node->root;
    }
  }
  $this = $a_node;
  ChangingFile(0);
  return 1;
}

sub expand_ordering {
  my $tree = shift;
  my $attr = shift || 'deepord';
  foreach my $node ($tree->descendants) {
    $node->{$attr} *= 1000;
  }
}

sub normalize_ordering {
  my $tree = shift;
  my $attr = shift || 'deepord';
  my $index = 1;
  foreach my $node ( sort { $a->{$attr} <=> $b->{$attr} } $tree->descendants ) {
    $node->{$attr} = $index++;
  }
}

sub prepare_mwe_folding {
  my $tree = shift;
  my $mapping = FileUserData('mwe') || {};
  expand_ordering($tree);
  my @mwe_nodes = ();

  foreach my $mwe (ListV($tree->{mwes})) {
    my $mwe_node = NewSon($tree);
    $mwe_node->set_type_by_name($tree->type()->schema(), 't-node.type');
    $mwe_node->{id} = $mwe->{id};
    $mwe_node->{type} = $mwe->{type};
    AddToNodeHash($mwe_node->{id}, $mwe_node);

    if ($mwe->{'basic-form'}) {
      $mwe_node->{label} = $mwe->{'basic-form'};
    } else {
      # basic-form was not added manualy -> let's create it from a-layer
      # First, get corresponding a-nodes
      my @a_nodes = sort { $a->{ord} <=> $b->{ord} } map { GetANodes(GetNodeByID($_)) } ListV($mwe->{'tnode.rfs'});
      # add AuxX and AuxG (interpunction) a-nodes to the list
      for (my $i = 0; $i < @a_nodes; $i++) {
        my $a_node = $a_nodes[$i];
        my $next_in_mwe = $a_nodes[$i+1];
        my $next_by_ord = NextNodeLinear($a_node, "ord");
        if ($next_in_mwe                                # $i is not the last
            and $a_node->{ord}+1 < $next_in_mwe->{ord}  # there is a gap after it
            and $next_by_ord->{afun} =~ /^Aux[XG]$/     # with interpunction within
            and ($next_by_ord->parent == $a_node        # governed by either left
              or $next_by_ord->parent == $next_in_mwe)  # or right a-node node
           ) {
          splice(@a_nodes, $i+1, 0, $next_by_ord);
        }
      }
      # add AuxX nad AuxG at the left and right from MWE
      my $next = NextNodeLinear($a_nodes[-1], "ord");
      if ($next and $next->{afun} =~ /^Aux[XG]$/
          and $next->parent == $a_nodes[-1]) {
        push(@a_nodes, $next);
      }
      my $prev = PrevNodeLinear($a_nodes[0], "ord");
      if ($next and $next->{afun} =~ /^Aux[XG]$/
          and $next->parent == $a_nodes[0]) {
        push(@a_nodes, $next);
      }

      # Second, assemble the sentence
      my $label = $a_nodes[0]->attr('m/form');
      for (my $i = 1; $i <= $#a_nodes; $i++) {
        unless ($a_nodes[$i-1]->attr('m/w/no_space_after') and ($a_nodes[$i]->{ord} - $a_nodes[$i-1]->{ord} == 1)) {
          $label .= ' ';
        }
        $label .= $a_nodes[$i]->attr('m/form');
      }
      $mwe_node->{label} = $label;
    }

    foreach my $id (ListV($mwe->{'tnode.rfs'})) {
      $mapping->{$id} = $mwe_node;
    }

    push @mwe_nodes, [$mwe_node, $mwe];
  }

  foreach my $mwe (@mwe_nodes) {
    my @roots = ();
    my $root;
    my @children = ();

    foreach my $node ( map { GetNodeByID($_) } ListV($mwe->[1]->{'tnode.rfs'}) ) {
      if (not exists($mapping->{$node->parent->{id}}) or $mapping->{$node->parent->{id}} != $mwe->[0]) {
        # If the MWE is a foreign phrase (i.e. node #Forn with one-level-children representing the phrase),
        # hide the #Forn node together with others
        # It is supposed (and not tested) that WHOLE foreign phrase is marked as a MWE.
        if ($node->parent->{nodetype} eq "list" and $node->parent()->{t_lemma} eq "#Forn") {
          # root is #Forn (one level higher than $node)
          push @roots, $node->parent();
          # and #Forn becomes part of a MWE, so it is affected by collapsing
          $mapping->{$node->parent()->{id}} = $mwe->[0];
        } else {
          push @roots, $node;
        }
      }

      push @children, grep { not exists($mapping->{$_->{id}}) } $node->children;
    }

    #if (scalar(@roots) > 1) {
    #  my $members = 0;
    #  my %parents = ();
    #  foreach my $r (@roots) {
    #    $members++ if $r->{is_member};
    #    $parents{$r->parent->{id}} = 1;
    #  }

    #  if ($members > 0 and $members != scalar(@roots)) {
    #    print STDERR "WARNING: is_member mismatch in MWE ".$mwe->[0]->{id}."\n";
    #  }
    #  if (scalar keys %parents > 1) {
    #    print STDERR "WARNING: multiple parents of MWE ".$mwe->[0]->{id}."\n";
    #  }
    #}

    { use List::MoreUtils;
    if (uniq(@roots) > 1) { # in case of #Forn and many FPHR, all @roots are same
      # Find root that is the most upper one, closest to the tree-root
      my $min_node;
      my $min_depth = 999;
      foreach my $r (@roots) {
        my $_r = $r->parent;
        my $depth = 0;
        while ($_r) {
          $depth++;
          $_r = $_r->parent;
        }
        if ($depth < $min_depth) {
          $min_depth = $depth;
          $min_node = $r;
        }
      }
      $root = $min_node;
    } else {
      $root = $roots[0];
    }}

    $mwe->[0]->{functor} = $root->{functor};
    $mwe->[0]->{is_member} = 1 if $root->{is_member};
    $mwe->[0]->{is_parenthesis} = 1 if $root->{is_parenthesis};
    $mwe->[0]->{deepord} = $root->{deepord} - 1;
    $mwe->[0]->{'mwe_root'} = $root;

    my $parent = $root->parent;
    if (exists($mapping->{$parent->{id}})) {
      CutPaste($mwe->[0], $mapping->{$parent->{id}});
    } else {
      CutPaste($mwe->[0], $parent);
    }

    foreach my $node (@children) {
      $node->{'std_parent'} = $node->parent;
      $node->{'mwe_parent'} = $mwe->[0];
    }
  }

  $tree->{hide} = 0;
  foreach my $node ($tree->descendants) {
    if (exists $node->{'mwe_root'}) {
      $node->{hide} = $PDT_25_T::mwe_folding ? 0 : 1;
    } elsif (exists $mapping->{$node->{id}}) {
      $node->{hide} = $PDT_25_T::mwe_folding ? 1 : 0;
    } else {
      $node->{hide} = 0;
    }

    foreach my $attr ('compl.rf', 'coref_gram.rf', 'coref_text.rf') {
      foreach my $ref (ListV($node->{$attr})) {
        my $ref_node = GetNodeByID($ref);
        my ($mwe_begin, $mwe_end); 

        if (exists $mapping->{$node->{id}}) {
          $mwe_begin = $mapping->{$node->{id}};
        } else {
          $mwe_begin = $node; 
        }

        if (exists $mapping->{$ref_node->{id}}) {
          $mwe_end = $mapping->{$ref_node->{id}}->{id};
        } else {
          $mwe_end = $ref_node->{id};
        }

        # Happens when both the beginning and the end of the arrow are within the same MWE
        next if $mwe_begin->{id} eq $mwe_end;
        
        if ($mwe_begin != $node) {
          AddToListUniq($mwe_begin, $attr, $mwe_end);
        } elsif ($mwe_end ne $ref_node->{id}) {
          $node->{$attr} = ListV(ListSubtract($node->{$attr}, List($ref_node->{id})));
          push @{$node->{'mwe_refs'}}, [ $attr, $ref_node->{id}, $mwe_end ];
        }
      }
    }
  }

  FileUserData('mwe', $mapping);
  normalize_ordering($tree);
  $tree->{'_mwe_ok'} = 1;
  rehang_mwes($tree);
}

# We need to overload this because of the folded MWE nodes
sub IsCoord {
  my $node=$_[0] || $this;
  return 0 unless $node;
  return 0 if exists $node->{'mwe_root'};
  return $node->{functor} =~ /^(?:ADVS|APPS|CONFR|CONJ|CONTRA|CSQ|DISJ|GRAD|OPER|REAS)$/;
}

sub prepare_styles {
  my $tree = shift;
  my $coord_decor = '#{Line-decoration:shape=oval;coords=-20,-20,20,20;outline='.CustomColor('line_coord').';width=1;dash=5,5 }';
  $coord_decor .= '#{Line-arrow:&}#{Line-arrowshape:&}#{Line-tag:&}#{Line-smooth:&}';
  $coord_decor .= '#{Oval-fill:'.CustomColor('tnode_coord').'}';

  # For coordination roots
  my $k1 = '20 / sqrt((xp-xn)**2 + (yp-yn)**2)';
  my $x1 = 'xn-(xn-xp)*'.$k1;
  my $y1 = 'yn-(yn-yp)*'.$k1;
  # For coordination members
  my $k2 = '(1 - 20 / sqrt((xp-xn)**2 + (yp-yn)**2))';
  my $x2 = 'xn-(xn-xp)*'.$k2;
  my $y2 = 'yn-(yn-yp)*'.$k2;

  foreach my $node ($tree->descendants) {
    my ($style, $coords, $width, $color, $dash) = ('', '', '', '');
    my $nondep = ($node->{functor} =~ m/^(?:PAR|PARTL|VOCAT|RHEM|CM|FPHR|PREC)$/ or $node->parent == $tree);

    if (IsCoord($node)) {
      $style .= $coord_decor;
      $coords = "n,n,n,n&$x1,$y1";
      $width = '0&';
      $color = 'white&';
      $dash = '&';
    } else {
      $coords = 'n,n';
    }
    if (IsCoord($node->parent)) {
      $coords .= ",$x2,$y2";
    } else {
      $coords .= ',p,p';
    }

    if (IsCoord($node->parent) and not $nondep) {
      $color .= $node->{is_member} ? CustomColor('line_coord') : CustomColor('line_comm');
    } elsif (IsCoord($node)) {
      $color .= $nondep ? CustomColor('line_normal') : CustomColor('line_coord');
    } elsif ($node->{is_member}) {
      $color .= CustomColor('error');
    }

    $width .= '1' if $node->{is_member} or $nondep or (IsCoord($node) and not (IsCoord($node->parent) and not $node->{is_member}));
    $dash .= '2,4' if $nondep;

    $style .= "#{Line-coords:$coords}";
    $style .= "#{Line-fill:$color}" if $color;
    $style .= "#{Line-width:$width}" if $width;
    $style .= "#{Line-dash:$dash}" if $dash;

    $node->{style} = $style;
  }

  $tree->{style} = '';
  $tree->{'_styles_ok'} = 1;
}

# Overloading methods from PML_T because of new visualization of paratactic structures.
# Arrows have to end before the node on the border of the decorative circle around the
# coordination root.
sub node_style_hook {
  my ($node,$styles)=@_;
  if ($node->{'coref_text.rf'} or $node->{'coref_gram.rf'} or $node->{'compl.rf'}) {
    my @gram = grep {$_ ne "" } ListV($node->{'coref_gram.rf'});
    my @text = grep {$_ ne "" } ListV($node->{'coref_text.rf'});
    my @compl = grep {$_ ne "" } ListV($node->{'compl.rf'});
    DrawCorefArrows($node,$styles,
      [@gram,@text,@compl],
      [ (map 'grammatical',@gram),
        (map 'textual',@text),
        (map 'compl',@compl)
      ],
    );
  }
  return 1;
}

sub DrawCorefArrows {
  my ($node, $styles, $target_ids, $arrow_types) = @_;
  my (@coords, @colors, @dash, @tags);
  my ($rotate_prv_snt, $rotate_nxt_snt, $rotate_dfr_doc) = (0, 0, 0);
  my %line = GetStyles($styles, 'Line');

  foreach my $target_id (@$target_ids) {
    my $arrow_type = 'arrow_'.(shift @$arrow_types);

    my $target_node = GetNodeByID($target_id);
    next if $target_node->{hide};

    if ($target_node) {
      if (not exists $root_index{$target_node->root->{id}}) {
        my @trees = GetTrees();
        for (my $i = 0; $i < scalar(@trees); $i++) {
          $root_index{$trees[$i]->{id}} = $i;
        }
      }

      my $pos = $root_index{$target_node->root->{id}} - CurrentTreeNumber();
      if ($pos != 0) {
        my $lemma = $target_node->{'mwe_root'} ? $target_node->{label} : $target_node->{t_lemma};
        $PML_T::coreflemmas_hash{$node->{id}} .= ' '.$lemma;
      }
        
      if ($pos == 0) { # same sentence
        my $T = "[?\$node->{id} eq '$target_id'?]";
        my $X = "(x$T-xn)";
        my $Y = "(y$T-yn)";
        my $D = "sqrt($X**2+$Y**2)";
        my $BX = 'n';
        my $BY = 'n';
        my $MX = "((x$T+xn)/2 - $Y*(25/$D+0.12))";
        my $MY = "((y$T+yn)/2 + $X*(25/$D+0.12))";
        my $EX = "x$T";
        my $EY = "y$T";
        my $K1 = "20 / sqrt(($MX-xn)**2 + ($MY-yn)**2)";
        my $K2 = "20 / sqrt((x$T-$MX)**2 + (y$T-$MY)**2)";
        
        if (IsCoord($node)) {
          $BX = "xn-(xn-$MX)*$K1";
          $BY = "yn-(yn-$MY)*$K1";
        }
        if (IsCoord($target_node)) {
          $EX = "x$T+($MX-x$T)*$K2";
          $EY = "y$T+($MY-y$T)*$K2";
        }
        
        push @coords, "$BX,$BY,$MX,$MY,$EX,$EY";
      } else {
        if ($pos < 0) {
          push @coords, "n,n,n-30,n+$rotate_prv_snt";
          $rotate_prv_snt += 10;
        } else {
          push @coords, "n,n,n+30,n+$rotate_nxt_snt";
          $rotate_nxt_snt += 10;
        }
      }

      push @colors, CustomColor($arrow_type);
    } else {
      push @coords, "n,n,n+$rotate_dfr_doc,n-25";
      $rotate_dfr_doc += 10;
      push @colors, CustomColor('error');
    }

    push @tags, $arrow_type;
  }

  if (@coords) {
    TredMacro::AddStyle(
      $styles, 'Line',
      -coords => ( $line{-coords} || '' ) .'&'. join( '&', @coords ),
      -arrow      => ( $line{-arrow} || '' ) . ( '&last' x @coords ),
      -arrowshape => ( $line{-arrowshape} || '' ) . ( '&16,18,3' x @coords ),
      -dash => ( $line{-dash} || '' ) .'&'. join( '&', @dash ),
      -width => ( $line{-width} || '' ) . ( '&1' x @coords ),
      -fill => ( $line{-fill} || '' ) .'&'. join( '&', @colors ),
      -tag  => ( $line{-tag}  || '' ) .'&'. join( '&', @tags ),
      -smooth => ( $line{-smooth} || '' ) . ( '&1' x @coords )
    );
  }
  return;
}

1;

