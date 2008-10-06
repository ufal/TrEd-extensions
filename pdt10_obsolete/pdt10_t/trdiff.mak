# -*- cperl -*-
package TR_Diff;

BEGIN { import Tectogrammatic; }

#key-binding-adopt Tectogrammatic

use vars qw($usenames $onlylemma $onlyfunc $onlydep $onlymissing
            $excludelemma $summary @standard_check_list
            $summary
            $check_dependency $check_presence $check_attributes $id);

{
use integer;
use vars qw($compare_all $check_presence $check_dependency
	    $check_attributes $questionmarks_as_empty $dash_as_threedashes
	    @standard_check_list $id);
$compare_all=1;
$check_presence=1;
$check_dependency=1;
$check_attributes=1;
$questionmarks_as_empty=1;      # ignore difference between '???' and '' in attrs
$dash_as_threedashes=1;         # ignore difference between '-' and '---' in attrs
@standard_check_list=		# list of attributes to check
  qw(func form trlemma lemma origf del memberof gram sentmod deontmod TR);

$id="ord";			# (numeric) attribute which identifies
                                # elements to compare

#bind clear_diff_attrs to Alt+-
sub clear_diff_attrs {
  foreach my $tree (GetTrees()) {
    foreach my $node ($tree,$tree->descendants) {
      delete $node->{_group_};
      delete $node->{_diff_in_};
      delete $node->{_diff_dep_};
      delete $node->{_diff_attrs_}
    }
  }
}

sub switch_context_hook {
  my ($precontext,$context)=@_;
  # if this file has no balloon pattern, I understand it as a reason to override
  # its display settings!
  return unless ($precontext ne $context);
  return unless $grp->{FSFile};
  remove_diff_patterns();
  add_diff_patterns();
  Redraw_FSFile();
  return;
}

sub pre_switch_context_hook {
  remove_diff_patterns();
  return;
}

# insert remove_diff_patterns as menu Add diff patterns
sub add_diff_patterns {
  return unless $grp->{FSFile};
  my @pat=GetDisplayAttrs();
  my $hint=GetBalloonPattern();

  SetDisplayAttrs(@pat,
'style:<? #diff ?><? "#{Line-fill:red}#{Line-dash:- -}" if $${_diff_dep_} ?>',
'style:<? #diff ?><? join "",map{"#{Text[$_]-fill:orange}"} split  " ",$${_diff_attrs_} ?>',
'style:<? #diff ?><? "#{Oval-fill:darkorange}#{Node-addwidth:4}#{Node-addheight:4}" if $${_diff_attrs_} ?>',
'style:<? #diff ?><? "#{Oval-fill:cyan}#{Line-fill:cyan}#{Line-dash:- -}" if $${_diff_in_} ?>',
'style:<? #diff ?><? "#{Line-fill:black}#{Line-dash:- -}" if $${_diff_attrs_}=~/ TR/ ?>',
'<? #diff ?>${_group_}');
  SetBalloonPattern($hint.
		    "\n".'Diffs in:${_diff_attrs_}'
		   );
}

# insert remove_diff_patterns as menu Remove diff patterns
sub remove_diff_patterns {
  return unless $grp->{FSFile};
  my $hint=GetBalloonPattern();
  $hint=~s/\n.*_diff_.*(?:\n|$)//g;
  SetBalloonPattern($hint);
  SetDisplayAttrs(grep { !/\#diff.*(?:\n?|$)/ } GetDisplayAttrs());
}

sub current_node_change_hook {
  my ($node,$prev)=@_;
  return unless (exists($node->{_group_}));
  foreach my $win (TrEdWindows()) {
    next if ($win eq $grp);
    next unless ($win->{FSFile} and $win->{macroContext} eq 'TR_Diff');
    my $r=$win->{FSFile}->tree($win->{treeNo});
    while ($r and $r->{_group_} ne $node->{_group_}) {
      $r=$r->following();
    }
    SetCurrentNodeInOtherWin($win,$r) if ($r);
    CenterOtherWinTo($win,$r) if ($r);
  }
  return;
}

#bind find_next_difference to space menu Goto next difference
sub find_next_difference {
  my $node=$this->following;
  while ($node and not
	 ($node->{_diff_dep_} or
	  $node->{_diff_attrs_} or
	  $node->{_diff_in_})) {
    $node=$node->following;
  }
  $this=$node if ($node);
  $FileChanged=0;
  $Redraw='none'
}


#bind find_next_difference_in_file to Alt+space menu Goto next difference in file
sub find_next_difference_in_file {
  my $node;
  my $next = 1;
  LOOP:
  while ($next) {
    $node=$this->following;
    while ($node) {
      last LOOP if ($node->{_diff_dep_} or
		    $node->{_diff_attrs_} or
		    $node->{_diff_in_});
      $node=$node->following;
    }
    $next = TieNextTree();
  }
  if ($node) {
    $this=$node;
    $grp->{treeView}->set_showHidden(1) if IsHidden($node);
    $Redraw='tie';
  } else {
    $Redraw='tie'
  }
  $FileChanged=0;
}


sub get_anotator_names {
  my (@files)=@_;
  my $filecount=$#files+1;
  my ($eb,$ab,$zu,$ik,$h,$jh,$vr)=(0,0,0,0);
  my %names;
  my $name;
  foreach my $f (@files) {
    $name=$f;
    if ($usenames) {
      $name="ZU".($zu?$zu+1:""),$zu++ if ($f=~/zu?\.fs/i);
      $name="EB".($eb?$eb+1:""),$eb++ if ($f=~/eb?\.fs/i);
      $name="AB".($ab?$ab+1:""),$ab++ if ($f=~/ab?\.fs/i);
      $name="IK".($ik?$ik+1:""),$ik++ if ($f=~/ik?\.fs/i);
      $name="H".($ik?$ik+1:""),$ik++ if ($f=~/h\.fs/i);
      $name="VR".($ik?$ik+1:""),$ik++ if ($f=~/vr?\.fs/i);
      $name="JH".($ik?$ik+1:""),$ik++ if ($f=~/jh?\.fs/i);
    }
    $names{$f}=$name;
  }
  return %names;
}

sub Max {
  my $max=0;
  foreach (@_) {
    $max=$_ if $_>$max;
  }
  return $max;
}

sub diff_trees {
  my $summary=shift;
  my %T=@_;
  my @names=keys %T;
  # %T is a has of the form id => tree, where id is any textual identifier
  # of the tree

  foreach my $tree (values %T) {
    print "Prepairing tree\n";
    # count all nodes, visible nodes and nodes added on TR-layer
    my $acount=0;
    my $trcount=0;
    my $newcount=0;
    my $node=$tree;
    while($node) {
      if (IsHidden($node) or $node->{TR} eq 'hide') {
	$acount++;
      } else {
	$trcount++;
	$acount++;
	$newcount++ if ($node->{$id}=~/\./);
      }
      delete $node->{_group_};
      delete $node->{_diff_in_};
      delete $node->{_diff_dep_};
      delete $node->{_diff_attrs_};

      $node=$node->following();
    }
    # store the information in $tree
    $tree->{acount}=$acount;
    $tree->{trcount}=$trcount;
    $tree->{newcount}=$newcount;
  }

  my $total=0;
  my %total=undef;
  my $total_dependency=0;
  my $total_restoration=0;
  my $total_values=0;
  my %restoration=map { $_ => 0 } 1..@names;
  my %dependency=map { $_ => 0 } 1..@names;
  my %value=map { $_ => 0 } 1..@names;

  my $any=0;
  my $alldiffs=0;
  my $node;

  my %G=();
  foreach my $f (sort @names) {
    print "Creating groups for $f\n";
    # create groups of corresponding old nodes, i.e. nodes not created
    # by anotators
    if ($T{$f}) {
      $node=$T{$f}; # or NextVisibleNode if all are to be compared
      while ($node) {
	if ($node->{$id}!~/\./) {
	  if (! exists $G{$node->{$id}}) { 
	    $G{$node->{$id}} = { }; # structure: $G{ ord }->{ file } == node_from_file_at_ord
	  }
	  $G{$node->{$id}}->{$f}=$node;
	  $node->{_group_}=$node->{$id};
	}
	$node=$node->following();
      }
    }
  }

  # create groups of nodes added by anotators that correspond
  # dunno how to make it easily, so I'm working hard (looking for func)
  my $g;
  my $grpid=0;
  my $parent_grp;
  my $son;
  for (my $i=0; $i < @names; $i++) {
    if ($T{$names[$i]}) {
      $node=$T{$names[$i]};
      while ($node) {
       unless (exists $node->{_group_} and $node->{_group_} ne "") {
	  $g="N$grpid";
	  $grpid++;
	  if (! exists $G{$g}) {
	    $G{$g} = { };
	  }
	  $G{$g}->{$names[$i]}=$node;
	  $node->{"_group_"}=$g;
	  $parent_grp= $node->parent->{_group_};
	  for (my $j=$i+1; $j < @names; $j++) {
	    if (exists ($G{$parent_grp}->{$names[$j]})) {
	      $son=$G{$parent_grp}->{$names[$j]}->firstson;
	    SON: while ($son) {
		if ((!exists($son->{_group_}) or $son->{_group_} eq "")
		    and ($son->{func} eq $node->{func})) {
		  $son->{"_group_"}=$g;
		  $G{$g}->{$names[$j]}=$son;
		  last SON;
		}
		$son=$son->rbrother;
	      }
	    }
	  }
	}
	$node=$node->following;
      }
    }
  }
  # well, wasn't so difficult :)

  # Now have look on the groups:
  my ($A,$B);
  my %valhash;
  foreach my $g (sort { $A=~/N?([0-9]+)/;
			$A=$1;
			$A+=1000*($a=~/^N/);
			$b=~/N?([0-9]+)/;
			$B=$1;
			$B+=1000*($b=~/^N/);
			$A <=> $B }
		 keys(%G)) {

    next if $g eq "";
    my $Gr=$G{$g};
    my $diffs=0;

    my @grps=keys(%$Gr);

    if ($check_presence) {
      # check if all files have node in this group
      if (@grps != @names) {
	$diffs++;
	$total_restoration++;
	$restoration{max(scalar(@names)-scalar(@grps),scalar(@grps))}++;

	foreach my $node (values %$Gr) {
	  $node->{_diff_in_}=join(" ",@grps);
	  print "DIFF in $node->{_diff_in_}\n";
	}
      }
    }

    # check for (parent) structure differences but ignore changes,
    # if parents are alone, i.e. not associated in groups

    if ($check_dependency) {
      undef %valhash;
      my $diff_them=0;

      foreach my $f (@grps) {
	if ($Gr->{$f}->parent) {
	  $valhash{$Gr->{$f}->parent->{"_group_"}}.=" $f";
	  $diff_them++ if (keys(%{$G{$Gr->{$f}->parent->{"_group_"}}})>1);
	} else {
	  $valhash{"none"}.=" $f";
	}
      }

      if ($diff_them and keys (%valhash) > 1) {
	$diffs++;
	$total_dependency++;
	my @a;
	$dependency{Max(map { my @a=split " ",$valhash{$_}; scalar(@a) } %valhash)}++;
	foreach my $f (@grps) {
	  $Gr->{$f}->{_diff_dep_}=$valhash{$Gr->{$f}->parent->{"_group_"}};
	  print "DIFF DEP: ",$Gr->{$f}->{_diff_dep_},"\n";
	}
      }
    }

    #check for value differences
    if ($check_attributes) {
      foreach my $attr (@standard_check_list) {
	undef %valhash;
	foreach my $f (@grps) {
	  my $key=$Gr->{$f}->{$attr};
	  if ($questionmarks_as_empty and $key eq "???") {
	    $key="";
	  }
	  if ($dash_as_threedashes and $key eq "---") {
	    $key="-";
	  }
	  $valhash{$key}.=" $f";
	}
	if (keys (%valhash) > 1) {
	  my @a;
	  $value{Max( map { scalar(@a=split " ",$valhash{$_}) } %valhash)}++;
	  $diffs++;
	  $total{$attr}++;
	  foreach my $f (@grps) {
	    print "Attr diff in $attr\n";
	    $Gr->{$f}->{_diff_attrs_}.=" $attr";
	  }
	}
      }
      $alldiffs+=$diffs;
      $total+=$diffs;
    }
  }

  return unless $summary;
  my @summary=();
  push @summary, "Comparison of @names\n\nFile statistics:\n" if ($summary);
  
  foreach my $f (@names) {            
    push @summary, 
    "$f:\n\tTotal:\t$T{$f}->{acount} nodes\n",
    "\tOn TR:\t$T{$f}->{trcount} nodes\n",
    "\tNew:\t$T{$f}->{newcount} nodes\n\n";
  }
  
  foreach (keys %total) {
    $total_values+=$total{$_};
  }
  
  delete $total{''};
  
  push @summary,
  "Diferences statistics:\n",
  "\tTotal:\t$total differences\n",
  "\tStructure:\t$total_dependency\n",
  "\tRestoration:\t$total_restoration\n",
  "\tAttributes:\t$total_values\n",
  map ({ "\t  -- $_:\t$total{$_}\n" } keys(%total)),
  "\n";
  
  if ($total_restoration) {
    push @summary, 
    "Restoration - detailed statiscics:\n",
    "\tOf $total_restoration differences, there were\n",
    map ({ "\t      ".pack("A4",$restoration{$_})." agreements of $_\n" }
	 grep {$restoration{$_}>0} keys %restoration),
      "\n";
  }
  if ($total_dependency) {
    push @summary, 
    "Dependency - detailed statiscics:\n",
    "\tOf $total_dependency differences, there were\n",
    map ({ "\t      ".pack("A4",$dependency{$_})." agreements of $_\n" }
	 grep {$dependency{$_}>0} keys %dependency),
      "\n";
  }
  if ($total_values) {
    push @summary, 
    "Values of attributes - detailed statiscics:\n",
    "\tOf $total_values differences, there were\n",
    map ({ "\t      ".pack("A4",$value{$_})." agreements of $_\n" }
	 grep {$value{$_}>0} keys %value),
      "\n";
  }
  return @summary;
}

#bind DiffTRFiles to equal menu Compare trees
#bind DiffWholeTRFiles to Alt+equal menu Compare files
#bind DiffTRFiles_select_attrs to Ctrl+equal menu Choose attributes to compare
#bind DiffTRFiles_with_summary to Ctrl+plus menu Compare trees with summary

sub DiffTRFiles_select_attrs {
  ListQuery("Select attributes to compare","multiple",$grp->{FSFile}->FS->list,\@standard_check_list);
  $FileChanged=0;
  $Redraw='none';
}

sub DiffTRFiles_with_summary {
  require Tk::ROText;
  my @summary=TR_Diff->DiffTRFiles(1);
  
  my $top=ToplevelFrame();

  print "creating dialog\n";
  my $d=$top->DialogBox('-title'   => "Comparizon summary",
			'-width'   => '8c',
			'-buttons' => ["OK"]);
  print "created dialog\n";
  $d->bind('all','<Escape>'=> [sub { shift; 
				     shift->{selected_button}='OK'; 
				   },$d ]);

  my $t= $d->Scrolled(qw/ROText
                         -relief sunken
                         -borderwidth 2
		         -height 30 
                         -scrollbars e/,
		      '-tabs' => [qw/1c 4c/]
		     );
  $t->pack(qw/-expand yes -fill both/);

  $t->insert('0.0',join "",@summary);
  $t->BindMouseWheelVert();
  $t->BindMouseWheelHoriz("Shift");
  $t->focus;
  print "showing dialog\n";
  &main::ShowDialog($d);
  $FileChanged=0;
}

sub DiffTRFiles {
  my ($class,$summary)=@_;
  my $fg=$TredMacro::grp->{framegroup};
  my @T;
  my ($fs,$tree);
  foreach my $win (@{$fg->{treeWindows}}) {
    next unless $compare_all or $win->{macroContext} eq 'TR_Diff';
    $fs=$win->{FSFile};
    if ($fs) {
      $tree=$fs->treeList()->[$win->{treeNo}];
      push @T,($fs->filename()."##".($win->{treeNo}+1) => $tree) if $tree;
    }
  }
  $FileChanged=0;
  if (@T>2) {
    $Redraw='all';
    return diff_trees($summary,@T);
  } else {
    $Redraw='none';
  }
}

sub DiffWholeTRFiles {
  my ($class,$summary)=@_;
  my $fg=$TredMacro::grp->{framegroup};
  my @T;
  my $i=0;
  do {
    @T=();
    foreach my $win (@{$fg->{treeWindows}}) {
      next unless $compare_all or $win->{macroContext} eq 'TR_Diff';
      my $fs=$win->{FSFile};
      if ($fs) {
	my $tree;
	$tree=$fs->treeList()->[$i] if $i<=$fs->lastTreeNo();
	push @T,($fs->filename()."##".($i+1) => $tree) if $tree;
      }
    }
    $i++;
    print STDERR "$i: @T\n";
    diff_trees($summary,@T) if @T>2
  } while (@T>2);
  $FileChanged=0;
  $Redraw='all';
}
}
