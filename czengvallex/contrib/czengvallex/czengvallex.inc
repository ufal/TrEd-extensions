# -*- cperl -*-

BEGIN {
  import TredMacro;
  import PML; # for sub Schema
  # import PML_T; # for NewNode, but cannot include, conflicts with czengvallex
}

## --- Running Engvallex and PDT-Vallex

# use Data::Dumper;

#include functors.inc

my $debug = 0;

sub ReloadFramesPairs{
  if (defined $TrEd::FramesPairs::GUI::FramesPairs){
    my $frpas_file = ResolvePath(FileName(), "frames_pairs.xml", 1);
    my $frpas = TrEd::FramesPairs::GUI::Init({-framesPairs_file=>$frpas_file});

	if ($frpas->changed){
		if ($frpas->ask_doc_reload($win)){
			print STDERR "Reloading: $frpas_file\n";
		}	
	}
  }
  else{
      print STDERR "Not defined TrEd::FramesPairs::GUI::FramesPairs\n" if $debug;
  }
}
sub SaveFramesPairs {
  if (defined $TrEd::FramesPairs::GUI::FramesPairs) {
    my $frpas_file = ResolvePath(FileName(), "frames_pairs.xml", 1);

    my $frpas = TrEd::FramesPairs::GUI::Init({-framesPairs_file=>$frpas_file}); 
    if ($frpas->changed()) {
      if($frpas->ask_save($win)){
	      print STDERR "Saving: $frpas_file\n";
	  }
    }
  }
  else{
      print STDERR "Not defined TrEd::FramesPairs::GUI::FramesPairs\n" if $debug;
  }
}

sub OpenValLexicon
{
	if ($this->{id} =~ m/EnglishT/)
		{ OpenValLexicon_En(); }
	if ($this->{id} =~ m/^T/)
		{ OpenValLexicon_Cz(); }
}

sub ChooseValFrame
{
	if ($this->{id} =~ m/EnglishT/)
		{ ChooseValFrame_En(); }
	if ($this->{id} =~ m/^T/)
		{ ChooseValFrame_Cz(); }
}

sub FindVallex {
  my $lang = shift;
  return unless $lang =~ m/^(en|cz)$/;

  my $vallex_file =  ResolvePath(FileName(),"vallex_$lang.xml",1);

  $lang = "cs" if($lang eq "cz"); 

  my ($refid) = grep(/$lang/, AltV(FileMetaData('refnames')->{vallex}));
  return ($refid, $vallex_file);
}

sub AssignValencyFrames {
  my ($node,@frames)=@_;
  $node->{'val_frame.rf'} = undef;
  AddToAlt($node,'val_frame.rf', @frames);
}

sub _assigned_frame_pos_of
{
	my $node = shift || $this;
	return unless $node;
	if ($node->{'val_frame.rf'} ne q())
	{
		my ($refid, $vallex_file) = FindVallex('cz');
		my $V = ValLex::GUI::Init({-vallex_file=>$vallex_file});
		if ($V)
		{
			for my $id (AltV($node->{'val_frame.rf'}))
			{
				my $frame = $V->by_id( $id );
				if ($frame)
				{
					return lc($V->getPOS($V->getWordForFrame($frame)));
				}
			}
		}
	}
	return;
}

sub OpenFramesPairs{
	shift unless @_ and ref($_[0]);
	my $node = shift || $this;
	my %opts = @_;
	
	my $lang = ($node->{id}=~/^English/ ? "en" : "cs");
	my ($enode, $cnode, $evf, $cvf) = GetEnCsVerbPairWithFrames($node); 

	my $frpa_file = ResolvePath(FileName(), "frames_pairs.xml", 1);
	my ($refid_en,$vallex_en_file) = FindVallex('en'); 
	my ($refid_cs,$vallex_cs_file) = FindVallex('cz'); 
	
	my $evf_id=(defined $evf ? $evf->getAttribute('id') : ($lang eq "en" ? (first {$_ ne ""}  AltV($node->{'val_frame.rf'}) || "") : "")); 
	$evf_id=~s/\Q$refid_en\E#//;
	my $cvf_id=(defined $cvf ? $cvf->getAttribute('id') : ($lang eq "cs" ? (first {$_ ne ""} AltV($node->{'val_frame.rf'}) || "") : "")); 
	$cvf_id=~s/\Q$refid_cs\E#//;
	TrEd::FramesPairs::GUI::OpenEditor({
		-framesPairs_file => $frpa_file,
		-vallex_en_file => $vallex_en_file,
		-vallex_cs_file => $vallex_cs_file,
		-en_frame => $evf_id,
		-cs_frame => $cvf_id,
		-lang => $lang,
		%opts
	});
	ChangingFile(0);
	return;

}
sub OpenValLexicon_Cz
{
	shift unless @_ and ref($_[0]);
	my $node = shift || $this;
	my %opts = @_;
	$opts{-sempos}  ||= $node->attr('gram/sempos') || _assigned_frame_pos_of($node);

	local $ValLex::GUI::frameid_attr="val_frame.rf";
	local $ValLex::GUI::lemma_attr="t_lemma";
	local $ValLex::GUI::framere_attr=undef;
	local $ValLex::GUI::sempos_attr="gram/sempos";
	my ($refid,$vallex_file) = FindVallex('cz');
  	my $rf = $node ? join('|',map { my $x=$_;$x=~s/^\Q$refid\E#//;$x } AltV($node->{'val_frame.rf'})) : undef;
	ValLex::GUI::OpenEditor(
	{
		-vallex_file => $vallex_file,
		-lemma => $node ? $node->{t_lemma} : undef,
		-sempos => $node ? $node->attr('gram/sempos') : undef,
		-frameid => $rf,
		%opts
	});
	ChangingFile(0);
	return;
}

sub OpenValFrameList_Cz {
  shift unless @_ and ref($_[0]);
  my $node = shift || $this;
  my %opts = @_;

  local $ValLex::GUI::frameid_attr="val_frame.rf";
  local $ValLex::GUI::lemma_attr="t_lemma";
  local $ValLex::GUI::framere_attr=undef;
  local $ValLex::GUI::sempos_attr="gram/sempos";
  my ($refid,$vallex_file) = FindVallex('cz');
  my $rf = $node ? join('|',map { my $x=$_;$x=~s/^\Q$refid\E#//;$x } AltV($node->{'val_frame.rf'})) : undef;
  ValLex::GUI::ChooseFrame({
    -vallex_file => $vallex_file,
    -lemma => $node ? $node->{t_lemma} : undef,
    -sempos => $node ? $node->attr('gram/sempos') : undef,
    -lemma_attr => 't_lemma',
    -sempos_attr => 'gram/sempos',
    -frameid => $rf,
    -assignfunc => sub{},
    %opts
   });
  ChangingFile(0);
}

sub ChooseValFrame_Cz
{
	shift unless @_ and ref($_[0]);
	my $node = shift || $this;
	my %opts = @_;

	my $sempos = [ $opts{-sempos} || $node->attr('gram/sempos') || _assigned_frame_pos_of($node) ];
	if (!$sempos->[0]) {
		$sempos=['v'];
		ListQuery('Semantical POS','browse',[qw(v n)],$sempos) or return;
	}
	$opts{-sempos} = $sempos->[0];

  my $fsfile = $grp->{FSFile};
  OpenValFrameList_Cz(
    $node,
    -withdraw => 1,
    -assign_func => sub {
      my ($n, $ids, undef, $current_fsfile, $win, $chooser)=@_;
      $grp=$win->{focusedWindow};
      if ($current_fsfile == $fsfile) {
		  AssignValencyFrames($n,split /\|/,$ids);
      } else {
	my $top = $chooser ? $chooser->widget->toplevel : TopLevelFrame();
	$top-> messageBox(-icon=> 'error',
			  -message=> "Use Ctrl+Return to assign frame!",
			  -title=> 'Error', -type=> 'ok');
      }
    },
    %opts
   );
  ChangingFile(0);
}

sub OpenValFrameList_En {
  shift unless @_ and ref($_[0]);
  my $node = shift || $this;
  my %opts = @_;

  local $EngValLex::GUI::frameid_attr="val_frame.rf";
  local $EngValLex::GUI::lemma_attr="t_lemma";
  local $EngValLex::GUI::framere_attr=undef;
  local $EngValLex::GUI::sempos_attr="gram/sempos";
  $TrEd::EngValLex::Editor::reviewer_can_modify = 0;
  $TrEd::EngValLex::Editor::reviewer_can_delete = 0;

  my ($a_node, $foo) = SearchForNodeById($node->attr('a/lex.rf'));

  my ($refid,$vallex_file) = FindVallex('en');
  my $rf = $node ? join('|',map { my $x=$_;$x=~s/^\Q$refid\E#//;$x } AltV($node->{'val_frame.rf'})) : undef;
  TrEd::EngValLex::GUI::ChooseFrame({
	-vallex_file => $vallex_file,
    -lemma => $node ? $node->{t_lemma} : undef,
	-sempos => $node ? $node->attr('gram/sempos') : undef,
	-lemma_attr => 't_lemma',
	-sempos_attr => 'gram/sempos',
    -frameid => $rf,
    -assignfunc => sub{},
	-pos => $a_node->attr('tag'),
    %opts
  });
  ChangingFile(0);
}

sub ChooseValFrame_En {
  shift unless @_ and ref($_[0]);
  my $node = shift || $this;
  my %opts = @_;

  my $fsfile = $grp->{FSFile};
  OpenValFrameList_En(
    $node,
	-withdraw => 1,
    -assign_func => sub {
      my ($n, $ids, undef, $current_fsfile, $win, $chooser)=@_;
	  $grp = $win->{focusedWindow};
	  if ($current_fsfile == $fsfile)
	  {
		  AssignValencyFrames($n, split /\|/, $ids);
	  }
	  else
	  {
		  my $top = $chooser ? $chooser->widget->toplevel : TopLevelFrame();
		  $top->messageBox(-icon => 'error', -message => 'Use Ctrl + Return to assign frame!', -title => 'Error', -type => 'ok');
	  }
    },
    %opts
   );
  ChangingFile(0);
}

sub OpenValLexicon_En {
  shift unless @_ and ref($_[0]);
  my $node = shift || $this;
  my %opts = @_;

  local $TrEd::EngValLex::GUI::frameid_attr="val_frame.rf";
  local $TrEd::EngValLex::GUI::lemma_attr="t_lemma";
  local $TrEd::EngValLex::GUI::framere_attr=undef;
  local $TrEd::EngValLex::GUI::sempos_attr="gram/sempos";
  $TrEd::EngValLex::Editor::reviewer_can_modify = 0;
  $TrEd::EngValLex::Editor::reviewer_can_delete = 0;

  my ($a_node, $foo) = SearchForNodeById($node->attr('a/lex.rf'));

  my ($refid, $vallex_file) = FindVallex('en');
  my $rf = $node ? join('|',map { my $x=$_;$x=~s/^\Q$refid\E#//; $x} AltV($node->{'val_frame.rf'})) : undef;
  TrEd::EngValLex::GUI::OpenEditor(
  {
	-vallex_file => $vallex_file,
    -lemma => $node ? $node->{t_lemma} : undef,
    -sempos => $node ? $node->attr('gram/sempos') : undef,
    -frameid => $rf,
	-pos => $a_node->attr('tag'),
    %opts
  });
  ChangingFile(0);
  return;
}

sub frames_pairs_doc {
	my $frpa_file = ResolvePath(FileName(), "frames_pairs.xml", 1);

	return TrEd::FramesPairs::GUI::Init({-framesPairs_file=>$frpa_file});
}

## --->>

sub compute_ord($) {
    my $node = shift;
    my @children = $node->children;
    if (@children) {
        my $sum;
        foreach my $child (@children) {
            $sum += compute_ord($child);
        }
        $node->{_ord} = $sum / @children;
    } else {
        $node->{id} =~ /(\d+)$/;
        $node->{_ord} = $1;
    }
    return $node->{_ord};

}

sub switch_context_hook
{
	my $cur_stylesheet = GetCurrentStylesheet();
	if ($cur_stylesheet ne 'czengvallex')
	{
		SetCurrentStylesheet('czengvallex');
		Redraw() if GUI();
	}
	return;
}

my $colors = do { no warnings 'qw'; [qw(#CF9 #FDA #9FF #FAF #AFA #AAF #FAA)] };
my %ne_type_colors = ( 'location' => "#FAA", 'person' => '#AAF', 'organization' => '#AFA');

sub after_redraw_hook {
    return if !defined $root; # no warnings when using Tred's "reload current file" button
  
	my @zones = $root->{zones}->elements;
	foreach my $element (@zones){
		my ($name, $value) = @$element;
		if ($value->{language} eq "cs"){
			my $tree = $value->{trees}->{'a_tree'}; 

		    if (defined $tree) {
    	    	my %groups;
	
        		for my $node ($tree,$tree->descendants) {
		            my $group = $node->{clause_number};
        		    if (defined $group) {
                		push @{$groups{ $group }}, $node;
		            }
        		}

		        TrEd::NodeGroups::draw_groups(
        		    $grp,
    	        	[ map { $groups{$_} } sort {$a<=>$b} keys %groups ],
	        	    {
                	colors  => $colors,
	                stipples => TrEd::NodeGroups::dense_stipples($grp),
    	            x_shift => 0,
        		    }
		        );
        		my $stipple;

		        my $sub = sub {
        		    my ($w,$in)=@_;
		            my ($group_tag) = grep { /group_no_/ } $w->gettags('current');
        		    if (defined $group_tag) {
                		if ($in) {
		                    $stipple = $w->itemcget($group_tag,'-stipple');
        		            $w->itemconfigure($group_tag,-stipple => undef);
                		} else {
		                    $w->itemconfigure($group_tag,-stipple => $stipple);
        		            undef $stipple;
                		}
		            }
        		};

        		my $c = $grp->treeView->realcanvas;
		        $c->bind('group_line','<Enter>',[$sub,1]);
        		$c->bind('group_line','<Leave>',[$sub,0]);
    		}
		}
		elsif ($value->{language} eq "en"){
		    $tree = $value->{trees}->{'t_tree'};
			 
			if (defined $tree) {
		        my %groups;
        		for my $node ($tree,$tree->descendants) {
		            my $group = $node->{named_entity}->{number};
        		    if (defined $group) {
                		#my $c = $ne_type_colors{$node->{named_entity}->{type}};
		                #print STDERR "$c used for " . $node->{t_lemma} . "\n";
        		        push @{$groups{ $group }}, $node;
		            }
        		}

		        TrEd::NodeGroups::draw_groups(
        		    $grp,
		            [ map { $groups{$_} } sort {$a<=>$b} keys %groups ],
        		    {
                		colors  => [ map {$ne_type_colors{$groups{$_}->[0]->{named_entity}->{type}}} sort {$a<=>$b} keys %groups ],
		                stipples => TrEd::NodeGroups::dense_stipples($grp),
        		        x_shift => 0,
		            }
        		);
		        my $stipple;

        		my $sub = sub {
		            my ($w,$in)=@_;
        		    my ($group_tag) = grep { /group_no_/ } $w->gettags('current');
		            if (defined $group_tag) {
        	        	if ($in) {
            	        	$stipple = $w->itemcget($group_tag,'-stipple');
	                	    $w->itemconfigure($group_tag,-stipple => undef);
		                } else {
    		                $w->itemconfigure($group_tag,-stipple => $stipple);
        		            undef $stipple;
            		    }
            		}
	        	};

		        my $c = $grp->treeView->realcanvas;
        		$c->bind('group_line','<Enter>',[$sub,1]);
		        $c->bind('group_line','<Leave>',[$sub,0]);
    		}
		}
	}
}

sub get_status_line_hook {
	my $statusline="";
	
	if (defined $this->{'val_frame.rf'}){
	
		my @frames_elements_pairs = get_frames_elements_pairs($this);

		if ( scalar @frames_elements_pairs > 1 ){
			$statusline=[
				[
					"en_frame: " => [qw(label)],
					shift @frames_elements_pairs => [qw(value)],
					" cs_frame: " => [qw(label)],
					shift @frames_elements_pairs => [qw(value)], 
					" status: " => [qw(label)],
					shift @frames_elements_pairs => [qw(value)],
					" frames_pairs: " => [qw(label)]
				],
				[
					"label" => [-foreground => 'black' ],
					"value" => [-underline => 1]
				]
			];

			my $sep="";
			foreach my $fp (@frames_elements_pairs){
				push @{$statusline->[0]}, 
				  ($sep => [qw(label)], $fp => [qw(value)]);
				  $sep=", ";
			}

		}
	}

	return $statusline;
}

sub get_value_line_hook {
    my ($fsfile,$treeNo)=@_;
    return unless $fsfile;
    my $bundle = $fsfile->tree($treeNo);
    return unless $bundle;

	# generic subbundles
    my @zones = $bundle->{zones}->elements;
	
	#	my $active_node_id = $this->attr('a/lex.rf');
	
	my @out;
	foreach my $element ( @zones ) {
    	my ( $name, $value ) = @$element;
		if ($value->{language} eq "en"){

			my %refers_to;
			my $t_tree = $value->{trees}->{'t_tree'};
			for my $node ($t_tree, $t_tree->descendants){
				push @{$refers_to{$node->attr('a/lex.rf')}}, $node;
				foreach $a_aux (ListV($node->attr('a/aux.rf'))){
					push @{$refers_to{$a_aux}}, $node;
				}
			}

			my $tree = $value->{trees}->{'a_tree'};
			if (defined $tree){
				for my $node ( sort { $a->{ord} <=> $b->{ord} } $tree, $tree->descendants){
					push @out, ([$node->attr('form'),@{$refers_to{$node->{id}}||[]}, 'anode:',$node->{id}]) if defined $node->attr('form');
					push @out, ([" ", "space"]) unless ($node->attr('no_space_after'));
				}
			}
		}
		
		else{
			my $sent = $value->{sentence};
			push @out, (["\n" . $sent . "\n"]) if $sent; 
    	  #  $sentences .= $sent . "\n" if $sent;
	  }
    }
	return \@out;
    
}

sub _interleave {
    my @lists = @_;
    my $node_exists = 1;
    my @result = ();
    while ($node_exists) {
        $node_exists = 0;
        foreach my $list (@lists) {
            if (@$list) {
                push @result, shift(@$list);
                $node_exists = 1;
            }
        }
    }
    return @result;
}

sub vallex_doc {
  my $lang = shift;

  if ($lang eq "cs") {
    my ($refid,$vallex_file) = FindVallex('cz');
    my $V = ValLex::GUI::Init({-vallex_file=>$vallex_file});
    return $V;
  } elsif ($lang eq "en") {
    my ($refid,$vallex_file) = FindVallex('en');
    my $V = TrEd::EngValLex::GUI::Init({-vallex_file=>$vallex_file});
    return $V;
  } else {
    die "Bad language: $lang";
  }
}

sub _get_frame {
	my $node = shift;
	my $hint = "";
	my $refid, $vallex_file, $V, $frame;

	if ($node->{id} =~ m/EnglishT/){
		($refid, $vallex_file) = FindVallex('en');
    	$V = TrEd::EngValLex::GUI::Init({-vallex_file=>$vallex_file});
		my $fid = $node->{'val_frame.rf'};
		$fid=~s/^\Q$refid\E\#//;
    	($frame) = $V->TrEd::EngValLex::Extended::by_id( $fid ) if defined $V;
	}
	elsif($node->{id} =~ m/^T/){
		($refid, $vallex_file) = FindVallex('cz');	
    	$V = ValLex::GUI::Init({-vallex_file=>$vallex_file});
		my $fid = $node->{'val_frame.rf'};
		$fid=~s/^\Q$refid\E\#//;
    	$frame = $V->by_id( $fid ) if defined $V;
	}
	else{
		return "Bad node id : " . $node->{id};
	}

	$hint = wrap_line($V->serialize_frame($frame)) . "\n" if $frame;
	$hint .= wrap_line($V->getFrameExample($frame)) if $frame;
	return $hint;
}

sub wrap_line{
	#max lenght of hint line is 120

	my $strings = shift;
	my $new_string = "";

	my $first = 1;
	foreach my $string (split(/\n/,$strings)){
		$new_string .= "\n" if (!$first);
		$first=0;
		$new_string .= substr($string, 0, 120);
		$string = substr($string, 120);
		while (length($string) > 0){
			$new_string .= "\n" . substr($string, 0, 120);
			$string = substr($string, 120);
		}
	}
	return $new_string;
}

sub frame_by_id {
  my $lang = shift;
  my $fid = shift;

  if ($lang eq "cs") {
    my ($refid,$vallex_file) = FindVallex('cz');
    my $V = ValLex::GUI::Init({-vallex_file=>$vallex_file});
    my $frame = $V->by_id( $fid ) if defined $V;
    return $frame;
  } elsif ($lang eq "en") {
    my ($refid,$vallex_file) = FindVallex('en');
    my $V = TrEd::EngValLex::GUI::Init({-vallex_file=>$vallex_file});
    my ($frame) = $V->TrEd::EngValLex::Extended::by_id( $fid ) if defined $V;
    return $frame;
  } else {
    die "Bad language: $lang";
  }
}

sub FindNodeThatLinksToUs {
  my $targetid = shift;
  my $selected_node;
  
  my @zones = $root->{zones}->elements;
  foreach my $element (@zones){
	my ($name, $value) = @$element;
  	foreach my $tree (keys %{$value->{trees}}){
	    foreach my $node ($value->{trees}->{$tree}->descendants){
			return $node
			  	if $node->attr('valalign/manual/counterpart.rf') eq $targetid
            	 # manually linked to us
		          || ( defined $node->attr('alignment')
        		   && $node->attr('alignment')->[0]->{'counterpart.rf'} eq $targetid)
        	     # automatically linked to us
    	}
  	}
  }
  return undef;
}

sub FindNodeThatManuallyLinksToUs {
  my $targetid = shift;
  my $selected_node;
   
  my @zones = $root->{zones}->elements;
  foreach my $element (@zones){
	  my ($name, $value) = @$element;
	  foreach my $tree (keys %{$value->{trees}}){
	    foreach my $node ($value->{trees}->{$tree}->descendants){
	      return $node  if $node->attr('valalign/manual/counterpart.rf') eq $targetid;
    	}
  	  }
	}
  return undef;
}

sub valid_slot_pair {
  my $enode = shift;
  my $cnode = shift;

  return 0 if !defined $enode;
  return 0 if !defined $cnode;

  my $epar = $enode->parent();
  return 0 if !defined $epar;
  my $cpar = $cnode->parent();
  return 0 if !defined $cpar;

  return ($epar->attr('valalign/verb/counterpart.rf') eq $cpar->{id});
}

sub GetEnCsVerbPairWithFrames {
  # Given a Czech or English node return the ordered pair
  my $node = shift;

  print STDERR "GetEnCsVerbPairWithFrames: $node->{t_lemma}\n" if $debug;

  # Find the node counterpart (either linked manually or by David Marecek)
  my $ctrpartid = $node->attr('valalign/manual/counterpart.rf');
  if (! defined $ctrpartid
      && defined $node->attr('alignment') && $node->attr('alignment')->[0]->{'counterpart.rf'} ne "") {
    $ctrpartid = $node->attr('alignment')->[0]->{'counterpart.rf'};
  }

  if (! defined $ctrpartid) {
    my $revnode = FindNodeThatLinksToUs($node->{id});
    $ctrpartid = $revnode->{id} if defined $revnode;
  }
  print STDERR "Ctrpartid: $ctrpartid\n" if $debug;
  return undef if ! defined $ctrpartid; # no verb is aligned

  my $ctrpart = PML::GetNodeByID($ctrpartid);
  die "Failed to find aligned node $ctrpartid"  if ! defined $ctrpart;

  my ($enode, $cnode);
  if ($node->{id} =~ /EnglishT/) {
    $enode = $node;
    $cnode = $ctrpart;
  } elsif ($node->{id} =~ /^T/) {
    $cnode = $node;
    $enode = $ctrpart;
  } else {
    return undef; # Not a Czech or English t-node
  }
  my $cvfid = $cnode->attr('val_frame.rf');
  print STDERR "  cs valframe: $cvfid\n" if $debug;
  return undef if !defined $cvfid; # No valframe for Czech node
  my $evfid = $enode->attr('val_frame.rf');
  print STDERR "  en valframe: $evfid\n" if $debug;
  return undef if !defined $evfid; # No valframe for English node

  $cvfid=@{$cvfid}[0] if ref $cvfid;
  # $cvfid =~ s/^\Q$prefix\E\#//;
  $cvfid =~ s/^[^#]*\#//g;
  $evfid=@{$evfid}[0] if ref $evfid;
  # $cvfid =~ s/^\Q$prefix\E\#//;
  $evfid =~ s/^[^#]*\#//g;

  my $evf = frame_by_id("en", $evfid);
  my $cvf = frame_by_id("cs", $cvfid);

  return ($enode, $cnode, $evf, $cvf);
}

sub root_style_hook {
  # Redraw automatic links every time
  RedrawAllValLinks() if ($czengvallex::display_all_arrows || ($this->{id} =~ /^EnglishT|T/ && $this->{nodetype} ne "root"));
}

sub EditCzengvallexFunctor {
  ChangingFile(EditAttribute($this,'valalign/czengvallex_functor'));
  $this->set_attr('valalign/czengvallex_functor', undef)
    if ($this->attr('valalign/czengvallex_functor') eq '???');
}

sub EditNote {
  ChangingFile(EditAttribute($this,'valalign/note'));
}

sub AddNote {
	my @list=$this->type('valalign/note/type/')->get_values();
	my $dialog=[$list[0]];
	ListQuery('Comment type', browse, \@list, $dialog) or return;
	my $text=QueryString('Comment text', 'Text:');
	return unless defined $text;
	my %note=(type=>$dialog->[0], text=>$text);
	AddToList($this, 'valalign/note',\%note);
}

sub HandleAllCoApsSM {
  # Set valalign/czengvallex_functor for all coordination/apposition nodes
  my @zones = $root->{zones}->elements;
  foreach my $element (@zones){
	  my ($name, $value) = @$element;
	  foreach my $node (reverse $value->{trees}->{'t_tree'}->descendants){
      	HandleCoAps($node);
		HandleSM($node);
      }
  }
}

sub HandleCoApsSM{
  shift unless @_ and ref($_[0]);
  my $node = shift || $this;

  HandleCoAps($node);
  HandleSM($node);
}


sub HandleCoAps {
  # if the given node is a coordination, set valalign/czengvallex_functor to the functor
  # of the first dependent
  shift unless @_ and ref($_[0]);
  my $node = shift || $this;

  return if defined $node->attr('valalign/czengvallex_functor');
    # preserve defined

  return if $node->attr('nodetype') ne "coap";

  # try to find the ftor of the first member
  my @sons = grep {$_->attr('is_member')} $node->children();
  $node->set_attr('valalign/czengvallex_functor', $sons[0]->attr('valalign/czengvallex_functor') || $sons[0]->attr('functor'))
    if defined $sons[0];
}

sub HandleSM {
  # if the given node has functor "SM", set valalign/czengvallex_functor to the functor
  # of the first dependent
	shift unless @_ and ref($_[0]);
	my $node = shift || $this;

	return if defined $node->attr('valalign/czengvallex_functor');
	  #preserve defined

	return if $node->attr('functor') ne "SM";

	my @sons = $node->children();
	$node->set_attr('valalign/czengvallex_functor', $sons[0]->attr('valalign/czengvallex_functor') || $sons[0]->attr('functor'))
		if defined $sons[0];
}

sub SetStatusDeleted{
	#sets status="delete" for current frame_pair

	shift unless @_ and ref($_[0]);
	my $node = shift || $this;

  	my ($enode, $cnode, $evf, $cvf) = GetEnCsVerbPairWithFrames($node);
  	return if ! defined $enode || ! defined $cnode;

  	my $frpas = frames_pairs_doc();
    my $framepair = get_existing_framepair($evf, $cvf);
    if (defined $framepair) {
  
  		my $answer=questionQuery("Deleting frame pair", "Do you want to delete frame pair for ".$enode->{t_lemma} . " and " . $cnode->{t_lemma} . "? ", "Yes", "No");
  		return 0 if ($answer eq "No");
		
		$framepair->setAttribute("status", "deleted");
		$frpas->set_change_status(1);
	
	}
}

sub RedrawAllValLinks {
  # Redraw valency alignments of all en nodes

  my @zones = $root->{zones}->elements;
  foreach my $element (@zones){
	  my ($name, $value) = @$element;
	  next if ($value->{language} ne "en");
	  foreach my $node ($value->{trees}->{'t_tree'}->descendants) {
	      RedrawValLinks($node);
      }
  }
}


sub RedrawValLinks {
  # Redraw valency alignments at a given node
  shift unless @_ and ref($_[0]);
  my $node = shift || $this;
  my %opts = @_;

  $czengvallex::current_draw=$this;
  
  my ($enode, $cnode, $evf, $cvf) = GetEnCsVerbPairWithFrames($node);
  return if ! defined $enode || ! defined $cnode;
  RedrawValLinksForEnCsVerbs($enode, $cnode, $evf, $cvf);
}


sub RedrawValLinksForEnCsVerbs {
  my ($enode, $cnode, $evf, $cvf) = @_;

  # link the verbs
  $enode->set_attr('valalign/verb/counterpart.rf', $cnode->{id});

  my @esons = $enode->children();
  my @csons = $cnode->children();

  # clean original links
  foreach my $son (@esons, @csons) {
    $son->set_attr('valalign/vallex/status', undef);
    $son->set_attr('valalign/vallex/counterpart.rf', undef);
    $son->set_attr('valalign/auto/aligned', undef);
    $son->set_attr('valalign/auto/counterpart.rf', undef);
  }

  # make manual links point from en to cs if they lead the other way
  #foreach my $cson (@csons) {
  #  my $ectrpartid = $cson->attr('valalign/manual/counterpart.rf');
  #  if (defined $ectrpartid) {
  #    my $ectrpart = PML::GetNodeByID($ectrpartid);
  #    $ectrpart->set_attr('valalign/manual/counterpart.rf', $cson->{id});
  #    $ectrpart->set_attr('valalign/manual/aligned', $cson->attr("valalign/manual/aligned"));
  #    $cson->set_attr('valalign/manual/counterpart.rf', undef);
  #    $cson->set_attr('valalign/manual/aligned', undef);
  #  }
  #}

  if (defined $cvf && defined $evf) {
    # Draw green arrows: vallex projection in the data
    # each English son gets linked to the corresponding Czech son
    my $framepair = get_existing_framepair($evf, $cvf);
    if (defined $framepair) {
      # load the mapping from functor to functor
      my $eftor_to_cftor = load_eftor_to_cftor($framepair);
  
      my %eftor_to_son = map {
          ($_->attr('valalign/czengvallex_functor') || $_->{functor}, $_)
        } $enode->children();
      my %cftor_to_son = map {
          ($_->attr('valalign/czengvallex_functor') || $_->{functor}, $_)
        } $cnode->children();
  
      foreach my $eson (@esons) {
        my $eftor = $eson->attr('valalign/czengvallex_functor') || $eson->{functor};
		if (!defined $eftor) {
          $eson->set_attr('valalign/vallex/status', "not-in-frame");
        } else {
		  if ($eftor=~/^(RHEM|ATT|PREC|SM|PAR)$/){
			$eson->set_attr('valalign/not_collect',1);	
		  }	
          my $cftor = $eftor_to_cftor->{$eftor};
          if ($cftor eq "---") {
            # vallex specifies explicit no counterpart
            $eson->set_attr('valalign/vallex/status', "unaligned");
          } else {
            # vallex specifies a slot
            my $cson = $cftor_to_son{$cftor};
            if (defined $cson) {
              $eson->set_attr('valalign/vallex/status', "aligned");
              $eson->set_attr('valalign/vallex/counterpart.rf', $cson->{id});
            }
          }
        }
      }
    }
  }

  sub RotateNotCollect {
	$this->set_attr('valalign/not_collect', ($this->attr('valalign/not_collect') ? 0 : 1)) if ($this->{id} =~ m/EnglishT/);
  }

  sub RotateSlotRemove {
	$this->set_attr('valalign/slot_remove', ($this->attr('valalign/slot_remove') ? 0 : 1)) if ($this->{id} =~ m/EnglishT/);
  }


  sub get_frames_elements_pairs {
	  #Given a English or Czech node, return string of pairs of elements

	  my @frames_elements_pairs = ();

	  my $node=shift;
	  my ($enode, $cnode, $evf, $cvf) = GetEnCsVerbPairWithFrames($node);
	
	  return @frames_elements_pairs if !defined $evf || !defined $cvf;

	  my $framepair = get_existing_framepair($evf, $cvf);

	  return @frames_elements_pairs if !defined $framepair;

	  push @frames_elements_pairs, $evf->getAttribute('id');
	  push @frames_elements_pairs, $cvf->getAttribute('id');
	  push @frames_elements_pairs, $framepair->getAttribute('status');
	  my $ref_eftor_to_cftor = load_eftor_to_cftor($framepair);

	  return @frames_elements_pairs if !defined $ref_eftor_to_cftor;

	  my %eftor_to_cftor = %$ref_eftor_to_cftor;

	  foreach my $eftor (keys %eftor_to_cftor){
	  	push @frames_elements_pairs,  ($eftor =~ /^-/ ? "---" : $eftor) . "->" . $eftor_to_cftor{$eftor};	  
	  }

	  return @frames_elements_pairs;
  	
  	
  }

  # Draw blue arrows (automatic slot alignments) to complement red arrows
  # (manual slot alignments)
  my %covered = ();
  foreach my $eson (@esons) {
    print STDERR "Blue for: $eson->{t_lemma}, $eson->{id}\n" if $debug;
    # honour manual alignment (or no alignment)
    if (defined $eson->attr('valalign/manual/aligned')) {
      $covered{$eson} = 1; # ourselves
      my $ctrpartid = $eson->attr('valalign/manual/counterpart.rf');
      my $ctrpart = PML::GetNodeByID($ctrpartid);
      $covered{$ctrpart} = 1; # and the linked node
      next;
    }
    # ignore sons not represented in vallex
    if ($eson->attr('valalign/vallex/status') eq "not-in-frame") {
      $covered{$eson} = 1;
      next;
    }
    
	# find which cson points to us
    my $cson = undef;
    foreach my $cson1 (@csons) {
      print STDERR "  Considering: $cson1->{t_lemma}, $cson1->{id}\n" if $debug;
      # ignore sons marked manually as non-linked
      if (defined $cson1->attr('valalign/manual/aligned')
          && $cson1->attr('valalign/manual/aligned') == 0) {
        print STDERR "    manual no-align\n" if $debug;
        $covered{$cson1} = 1;
        next;
      }
      # ignore sons not represented in vallex
      if ($cson1->attr('valalign/vallex/status') eq "not-in-frame") {
        print STDERR "    vallex not-in-frame\n" if $debug;
        $covered{$cson1} = 1;
        next;
      }
      if ( defined $cson1->attr('alignment')
           && $cson1->attr('alignment')->[0]->{'counterpart.rf'}
               eq $eson->{id}) {
        # the cson is word-aligned to us, let's propose that
      	print STDERR "    wali:".$cson1->attr('id')."\n" if $debug;
        $cson = $cson1;
        last;
      }
    }

    if (defined $cson) {
      print STDERR "  Found: $cson->{t_lemma}, $cson->{id}\n" if $debug;
      # we found a candidate, link them
      $eson->set_attr('valalign/auto/aligned', 1);
      $eson->set_attr('valalign/auto/counterpart.rf', $cson->{id});
      $covered{$eson} = 1;
      $covered{$cson} = 1;
    }
	elsif (defined $eson->attr('alignment') and $eson->attr('alignment')->[0]->{'counterpart.rf'} ne ""){
			#automatic alignment
			$covered{$eson} = 1;
			my $ctrpartid = $eson->attr('alignment')->[0]->{'counterpart.rf'};
			my $ctrpart = PML::GetNodeByID($ctrpartid);
			$eson->set_attr('valalign/auto/aligned', 1);
			$eson->set_attr('valalign/auto/counterpart.rf', $ctrpartid);
			$covered{$ctrpart} = 1;
	}
  }

  # Mark all remaining in-frame sons treated as unaligned
  foreach my $son (@esons, @csons) {
    next if $covered{$son}; # this one is treated already
    $son->set_attr('valalign/auto/aligned', 0);
  }
}

sub get_existing_framepair {
  # find the czengvallex_counterpart_frame, the mapping between frames
  my ($evf, $cvf) = @_;

  my $evfid = $evf->getAttribute('id');
  my $cvfid = $cvf->getAttribute('id');
  print STDERR "Searching for $evfid and  $cvfid\n" if $debug;

  my $framepair = undef;
  
  my $frpas = frames_pairs_doc();
  
  if (defined $frpas){
	  $framepair = TrEd::FramesPairs::FramesPairsData->get_frame_pair_by_en_cs_ids($frpas->doc(), $evfid, $cvfid);
  }
 
  if (defined $framepair){
	  my $frp_id = $framepair->getAttribute("id");
	  print STDERR "Found framepair: $frp_id\n" if $debug;
  }
  else{
	  print STDERR "No framepair for $evfid and $cvfid \n" if $debug;
  }
  return $framepair;
}


sub AddAllArtificialSons {
  # Add artificial sons for all verbs with a frame

  my @zones = $root->{zones}->elements;
  foreach my $element (@zones){
	  my ($name, $value) = @$element;
	  next if $value->{language} ne "en";
      	foreach my $node ($value->{trees}->{'t_tree'}->descendants) {
	      AddArtificialSons($node);
    	}
  }
}

sub AddArtificialSons {
  # Add artificial sons for the node, if verb
  shift unless @_ and ref($_[0]);
  my $node = shift || $this;
  my %opts = @_;

  my ($enode, $cnode, $evf, $cvf) = GetEnCsVerbPairWithFrames($node);
  return if ! defined $enode || ! defined $cnode
    || ! defined $evf || ! defined $cvf;
  AddArtificialSonsForEnCsVerbs($enode, $cnode, $evf, $cvf);
}

sub AddArtificialSonsForEnCsVerbs {
  my ($enode, $cnode, $evf, $cvf) = @_;

  foreach my $pair ([$enode, $evf], [$cnode, $cvf]) {
    my ($nd, $vf) = @$pair;
    my %seen_ftor = map {
      HandleCoAps($_);
      ($_->attr('valalign/czengvallex_functor') || $_->attr('functor'), 1)
    } $nd->children();

 	my %echildren_for_need_ftors=();
 
 	foreach my $echild (GetEChildren($nd)){ 
 		my $eftor = $echild->attr('valalign/czengvallex_functor') || $echild->attr('functor'); 
 		next if $seen_ftor{$eftor};
 		push @{$echildren_for_need_ftors{$eftor}}, $echild->{id};
 	}
	
    # print STDERR "Seen ftors of ".$nd->attr('t_lemma').":   "
      # .join(", ", keys(%seen_ftor))."\n";

    my @slots = $vf->getElementsByTagName("element");
    # print STDERR "Needed ftors of ".$nd->attr('t_lemma').": "
                        # .join(", ", map { $_->getAttribute("functor") } @slots)
                        # ."\n";
    my @need_ftors = grep {! defined $seen_ftor{$_} && $_ ne "---" }
                        map { $_->getAttribute("functor") } @slots;
    # print STDERR "NODE ".$nd->attr('t_lemma')." NEEDS: @need_ftors\n";
    foreach my $ftor (@need_ftors) {
      $new_son = NewNode($nd);
      $new_son->set_attr('_tree_name', $nd->attr('_tree_name'));
      $new_son->set_attr('t_lemma', '#Slot');
      $new_son->set_attr('functor', $ftor);
 	  if (defined $echildren_for_need_ftors{$ftor}){
 	  	foreach (@{$echildren_for_need_ftors{$ftor}}){ 
 			AddValalignCoref($new_son, $_);
 			
 		}
 	  }
    }

    # XXX should also remove all unused artificial sons
  }
}

## Taken from PML_T that cannot be imported due to a strange conflict

sub NewNode{
  shift unless ref($_[0]);
  my ($node,$id)=@_;
  $node ||= $this;
  my $new = InitNode(NewSon($node),$node);
  $id||=NewID($new);
  $new->{id} = $id;
  weaken( GetNodeHash()->{$id} = $new );
  return $new;
}#NewNode

sub InitNode{
  shift unless ref($_[0]);
  my ($node,$obj)=@_;
  croak("InitNode: no node specified") unless ref($node);
  my $schema = Schema($obj);
  croak("InitNode: Couldn't derive PML schema") unless (ref($schema));
  $node->set_type_by_name($schema,'t-node.type');
  return $node;
}#InitNode

# modified for our purposes
sub NewID {
  shift unless ref($_[0]);
  my $top = ref($_[0]) ? $_[0]->root : $root;
  my $id = $top->{id}.'-t'.
    ((sort {$b<=>$a} map{$_->{id}=~/t([0-9]+)$/;$1}$top->descendants)[0]+1);
  return $id;
}#NewId

 sub _FilterEChildren { # node suff from
   my ($node,$suff,$from)=@_;
   my @sons;
   $node=$node->firstson;
   while ($node) {
 #    return @sons if $suff && @sons; #uncomment this line to get only first occurence
     unless ($node==$from){ # on the way up do not go back down again
     if(($suff&&$node->{is_member})
 	  	 ||(!$suff&&!$node->{is_member})){ # this we are looking for
 		 	push @sons,$node unless IsCoord($node);
 	      }
     push @sons,_FilterEChildren($node,1,0)
 	if (!$suff
 	    &&IsCoord($node)
 	    &&!$node->{is_member})
     or($suff
 	    &&IsCoord($node)
 	    &&$node->{is_member});
      } # unless node == from
      $node=$node->rbrother;
   }
   return @sons;
 } # _FilterEChildren
 
 sub GetEChildren { # node
   my $node=$_[0]||$this;
   return () if IsCoord($node);
   my @sons;
   my $init_node=$node;# for error message
   my $from;
   push @sons,_FilterEChildren($node,0,0);
   if($node->{is_member}){
    my @oldsons=@sons;
    while($node and $node->{nodetype}ne'root'
      and ($node->{is_member} || !IsCoord($node))){
      $from=$node;$node=$node->parent;
      push @sons,_FilterEChildren($node,0,$from) if $node;
    }
    if ($node->{nodetype}eq'root'){
      stderr("Error: Missing coordination head: $init_node->{id} $node->{id} ",ThisAddressNTRED($node),"\n");
 	 @sons=@oldsons;
    }
   }
   return @sons;
 } # GetEChildren
 
=item IsCoord($node?)

 Check if the given node is a coordination according to its TGTS
 functor (attribute C<functor>)

=cut
 
 sub IsCoord {
   my $node=$_[0] || $this;
   return 0 unless $node;
   return $node->{functor} =~ /ADVS|APPS|CONFR|CONJ|CONTRA|CSQ|DISJ|GRAD|OPER|REAS/;
 }
 
## Endof routines from PML_T


sub CollectAllValLinks {
  # Collect valency alignments of all nodes

  my @zones = $root->{zones}->elements;
  foreach my $element (@zones){
	  my ($name, $value) = @$element;
	  next if $value->{language} ne "en";
      foreach my $node ($value->{trees}->{'t_tree'}->descendants) {
	      CollectValLinks($node);
      }
  }
}


sub CollectValLinks {
  # Collect slot links to a frames_pairs file
  shift unless @_ and ref($_[0]);
  my $node = shift || $this;
  my %opts = @_;

  my ($enode, $cnode, $evf, $cvf) = GetEnCsVerbPairWithFrames($node);
  return if ! defined $enode || ! defined $cnode
    || ! defined $evf || ! defined $cvf;
  CollectValLinksForEnCsVerbs($enode, $cnode, $evf, $cvf);
}


sub CollectValLinksForEnCsVerbs {
  my ($enode, $cnode, $evf, $cvf) = @_;

  my @esons = $enode->children();
  my @csons = $cnode->children();

  print STDERR "Collecting links for " . $enode->{t_lemma} . " and " . $cnode->{t_lemma} . "\n " if ($debug);
  
  my $framepair = get_existing_framepair($evf, $cvf);
  
  if (defined $framepair and $framepair->getAttribute("status") eq "deleted"){
	
	my $eframe=$evf->getAttribute("id");
	my $cframe=$cvf->getAttribute("id");
  	my $answer = questionQuery("Deleted pair", 
		"Continue collecting deleted pair $eframe $cframe ($enode->{t_lemma} and $cnode->{t_lemma}?)", "Yes", "No");
	return 0 if ($answer eq "No")
  }
  
  foreach my $son (@esons){
	  my $sftor = $son->attr('valalign/czengvallex_functor') || $son->attr('functor');
  	if (!allowed_functor($sftor) and !$son->attr('valalign/not_collect')){
		questionQuery("Wrong functor", 
			"Cannot collect $enode->{t_lemma} and $cnode->{t_lemma}.\n Node $son->{t_lemma} ($son->{id}) has not allowed functor.", 
			"OK");
		return 0;
	}
  
	if ($sftor eq "RSTR" and !$son->attr('valalign/not_collect')){
	    my $answer=questionQuery("RSTR functor", "Node $son->{t_lemma} ($son->{id}) has RSTR functor. Still want to collect? ", "Yes", "No");
		return 0 if ($answer eq "No");
	}
}

  # clean original links
  foreach my $son (@esons, @csons) {
    $son->set_attr('valalign/vallex/status', undef);
    $son->set_attr('valalign/vallex/counterpart.rf', undef);
  }

  # Follow manual and automatic slot links and collect them
  my %eftor_to_cftor;
  foreach my $eson (@esons) {
	next if ($eson->attr('valalign/not_collect'));
    # for each son, we collect either our special ftor, or the regular one
    my $eftor = $eson->attr('valalign/czengvallex_functor') || $eson->attr('functor');
    my $cftor = undef;
	if ($eson->attr('valalign/slot_remove')){
		$cftor = "REMOVE";
	}
	else{
	    if (defined $eson->attr('valalign/manual/aligned')) {
    	  if ($eson->attr('valalign/manual/aligned') == 0) {
        	$cftor = "---";
	      } else {
    	    my $csonid = $eson->attr('valalign/manual/counterpart.rf');
        	my $cson = PML::GetNodeByID($csonid);
	        $cftor = $cson->attr('valalign/czengvallex_functor') || $cson->attr('functor');
			if (!allowed_functor($cftor)){
				questionQuery("Wrong functor", 
				"Cannot collect $enode->{t_lemma} and $cnode->{t_lemma}.\n Node $cson->{t_lemma} ($cson->{id}) has not allowed functor.", 
				"OK");
			return 0;	
			}
  			if ($cftor eq "RSTR"){
	    		my $answer=questionQuery("RSTR functor", "Node $cson->{t_lemma} ($cson->{id}) has RSTR functor. Still want to collect? ", "Yes", "No");
				return 0 if ($answer eq "No");
			}
    	  }
	    }
    	if (defined $eson->attr('valalign/auto/aligned')) {
	      if ($eson->attr('valalign/auto/aligned') == 0) {
    	    $cftor = "---";
	      } else {
    	    my $csonid = $eson->attr('valalign/auto/counterpart.rf');
        	my $cson = PML::GetNodeByID($csonid); 
	        $cftor = $cson->attr('valalign/czengvallex_functor') || $cson->attr('functor');
			if (!allowed_functor($cftor)){
				questionQuery("Wrong functor", 
				"Cannot collect $enode->{t_lemma} and $cnode->{t_lemma}.\n Node $cson->{t_lemma} ($cson->{id}) has not allowed functor.", 
				"OK");
				return 0;
			}
		  	if ($cftor eq "RSTR"){
			    my $answer=questionQuery("RSTR functor", "Node $cson->{t_lemma} ($cson->{id}) has RSTR functor. Still want to collect? ", "Yes", "No");
				return 0 if ($answer eq "No");
			}
    	  }
    	}
  	}
	
	$eftor_to_cftor{$eftor} = $cftor;
  }

  # Store alignments in framesPairs

  my $old_eftor_to_cftor; 
  $old_eftor_to_cftor = load_eftor_to_cftor($framepair)
    if (defined $framepair);

  # update the mapping
  foreach my $eftor (keys %eftor_to_cftor) {
    $old_eftor_to_cftor->{$eftor} = $eftor_to_cftor{$eftor};
  }

  my $frpas = frames_pairs_doc();
  if (!defined $framepair) {
    # need to create the a new framepair
	$framepair=TrEd::FramesPairs::FramesPairsData->addFramePair($frpas->doc(), $evf->getAttribute("id"), $cvf->getAttribute("id"));
  }

  # save the mapping to existing framepair
  save_eftor_to_cftor($frpas, $framepair, $old_eftor_to_cftor);
  $frpas->set_change_status(1);

  print STDERR "Finished collecting links at: "
    .$enode->{t_lemma}." and ".$cnode->{t_lemma}."\n" if $debug;

  RedrawValLinks($enode);
}

sub RemoveValLinks {
  # removes links from a frames_pairs file
  shift unless @_ and ref($_[0]);
  my $node = shift || $this;
  my %opts = @_;

  my ($enode, $cnode, $evf, $cvf) = GetEnCsVerbPairWithFrames($node);
  return if ! defined $enode || ! defined $cnode
    || ! defined $evf || ! defined $cvf;
  RemoveValLinksForEnCsVerbs($enode, $cnode, $evf, $cvf);
}


sub RemoveValLinksForEnCsVerbs {
  my ($enode, $cnode, $evf, $cvf) = @_;

  my $answer=questionQuery("Remove ValLinks", "Do you want to delete links for ".$enode->{t_lemma} . " and " . $cnode->{t_lemma} . "? ", "Yes", "No");
  return 0 if ($answer eq "No");
  
  print STDERR "Deleting links for " . $enode->{t_lemma} . " and " . $cnode->{t_lemma} . "\n " if ($debug);
  
  
  my @esons = $enode->children();
  my @csons = $cnode->children();

  # clean original links
  foreach my $son (@esons, @csons) {
    $son->set_attr('valalign/vallex/status', undef);
    $son->set_attr('valalign/vallex/counterpart.rf', undef);
  }

  # Store alignments in framesPairs
  my $framepair = get_existing_framepair($evf, $cvf);
  return 0 if (!defined $framepair);

  my $ref_eftor_to_cftor; 

  $ref_eftor_to_cftor = load_eftor_to_cftor($framepair);

  my %eftor_to_cftor = %$ref_eftor_to_cftor;

  # update the mapping
  foreach my $eftor (keys %eftor_to_cftor) {
    $eftor_to_cftor->{$eftor} = "REMOVE";
  }
  
  my $frpas = frames_pairs_doc();

  # save the mapping to existing framepair
  save_eftor_to_cftor($frpas, $framepair, $eftor_to_cftor);
  $frpas->set_change_status(1);

  print STDERR "Finished deleting links at: "
    .$enode->{t_lemma}." and ".$cnode->{t_lemma}."\n" if $debug;

  RedrawValLinks($enode);
}

sub load_eftor_to_cftor {
  my $framepair = shift;
  my %eftor_to_cftor;

  print STDERR "Loading for ".$framepair->getAttribute("id")."\n" if $debug;
  my ($slots) = $framepair->getElementsByTagName("slots");

  my $i=0;
  foreach my $slotpair ($slots->getElementsByTagName("slot")) {
    my $eftor = $slotpair->getAttribute("en_functor");
	if ($eftor eq "---"){
		if ($i<10){
			$eftor = "--".$i ;
		}else{
			$eftor = "-".$i;
		}
		$i++;
	}
    my $cftor = $slotpair->getAttribute("cs_functor");
	#print STDERR "Loaded: $eftor -> $cftor\n";
    $eftor_to_cftor{$eftor} = $cftor;
  }
  return \%eftor_to_cftor;
}

sub save_eftor_to_cftor {
  my ($frpas, $framepair, $orig_eftor_to_cftor) = @_;
  my %eftor_to_cftor = %$orig_eftor_to_cftor;

  my ($slots) = $framepair->getElementsByTagName("slots");

  foreach my $pair ($slots->getElementsByTagName("slot")) {
    my $eftor = $pair->getAttribute("en_functor");
    my $cftor = $pair->getAttribute("cs_functor");
    if (defined $eftor_to_cftor{$eftor}) {
	  if ($eftor_to_cftor{$eftor} eq "REMOVE"){
	    # remove slot
		$slots->removeChild($pair);
	  }	  
      elsif ($eftor_to_cftor{$eftor} eq $cftor) {
        # no need to save, already saved
      }
	  else {
        # update the attribute
        $pair->setAttribute("cs_functor", $eftor_to_cftor{$eftor});
      }
	  #	  $pair->setAttribute("status", "active");
      delete $eftor_to_cftor{$eftor}; # we handled this one
    } else {
      # more links saved than we talk about
      # keep them there
	  #	$pair->setAttribute("status", "deleted");

	  $slots->removeChild($pair);
    }
  }

  # save the remaining ones
  foreach my $eftor (keys %eftor_to_cftor) {
	next if ($eftor_to_cftor{$eftor} eq "REMOVE");
    my $pair = $frpas->doc()->createElement("slot");
    $slots->appendChild($pair);
	my $cftor = $eftor_to_cftor{$eftor};
	$eftor = "---" if ($eftor =~ /^-/);
    $pair->setAttribute("en_functor", $eftor);
    $pair->setAttribute("cs_functor", $cftor);
	#	$pair->setAttribute("status", "active");
  }

  $framepair->setAttribute("status", "reviewed");
  $frpas->set_change_status(1);
}
  

  # my @eslots = $evf->getElementsByTagName("czengvallex_counterpart_frame");
# 
  # foreach my $eslot (@eslots) {
    # my $eftor = $eslot->getAttribute("functor");
    # my $cftor = $eftor_to_cftor{$eftor};
    # if (defined $cftor) {
      # # store the corresponing choice in vallex
      # my ($c) = $eslot->getElementsByTagName("czengvallex_counterpart");
      # if (defined $c) {
        # $c->setAttribute("functor", $cftor);
      # } else {
        # # need to add child
        # $c = $vallex->doc->createElement("czengvallex_counterpart");
        # $c->setAttribute("functor", $cftor);
        # $eslot->appendChild($c);
      # }
      # $vallex->set_change_status(1);
    # }
  # }
# 
# }


sub node_release_hook {
  # add or remove an existing manual link
  my ($node, $tgtnode, $mod) = @_;

  my $enode; my $cnode;

  $enode = $node if $node->{id} =~ /EnglishT/;
  $enode = $tgtnode if $tgtnode->{id} =~ /EnglishT/;
  $cnode = $node if $node->{id} =~ /^T/;
  $cnode = $tgtnode if $tgtnode->{id} =~ /^T/;

  return "stop" if !defined $enode || !defined $cnode;

  my $was_linked = $enode->attr('valalign/manual/aligned')
      && $enode->attr('valalign/manual/counterpart.rf') eq $cnode->{id};

  # remove any existing links
  for my $n ($cnode, $enode,
      FindNodeThatManuallyLinksToUs($cnode->{id}),
      FindNodeThatManuallyLinksToUs($enode->{id})) {
    next if !defined $n;
    $n->set_attr('valalign/manual/counterpart.rf', undef);
    $n->set_attr('valalign/manual/aligned', undef);
  }

  if (!$was_linked) {
    # insert the link if it was not there
    $enode->set_attr('valalign/manual/counterpart.rf', $cnode->{id});
    $enode->set_attr('valalign/manual/aligned', 1);
  }

  Redraw_FSFile_Tree();
  $FileChanged=1;

  return "stop"; # avoid rehanging of nodes altogether
}

sub node_doubleclick_hook {
  # remove any manual links, toggle explicit no alignment with no annotation
  my ($node, $mod) = @_;

  if (! defined $node->attr("valalign/manual/aligned")) {
    # maybe someone links to us!
    # toggle both us and the counterpart to explicit no-alignment
    my $revnode = FindNodeThatManuallyLinksToUs($node->{id});
    if (defined $revnode) {
      $revnode->set_attr('valalign/manual/counterpart.rf', undef);
      $revnode->set_attr('valalign/manual/aligned', 0);
    }
    $node->set_attr('valalign/manual/aligned', 0);
  } elsif (0 == $node->attr("valalign/manual/aligned")) {
    # we were not aligned, drop even that annotation
    $node->set_attr('valalign/manual/aligned', undef);
    return;
  } else {
    # we were aligned and to a node; mark both as explicitly not aligned
    my $ctrpartid = $node->attr('valalign/manual/counterpart.rf');
    my $ctrpart = PML::GetNodeByID($ctrpartid);
    $ctrpart->set_attr('valalign/manual/aligned', 0);
    $node->set_attr('valalign/manual/counterpart.rf', undef);
    $node->set_attr('valalign/manual/aligned', 0);
  }

  Redraw_FSFile_Tree();
  $FileChanged=1;

  return "stop";
}


sub exit_hook {
	SaveFramesPairs();
}

my @languages;

sub toggle_display_all
{
	$czengvallex::display_all = $czengvallex::display_all ? 0 : 1;
	Redraw() if GUI();
}

sub toggle_display_all_arrows
{
	$czengvallex::display_all_arrows = $czengvallex::display_all_arrows ? 0 : 1;
	$czengvallex::current_draw=$this;
	Redraw() if GUI();
}

sub get_all_nodes_to_display {

    my $bundle = shift;

	my @p_trees;
	my @a_trees;
    my @t_trees;
	

    my @zones = $bundle->{zones}->elements;

	@languages=();
    foreach my $element ( @zones ) {

    	my ( $name, $zone ) = @$element;
	    my $language = $zone->{language};
		push @languages, "English" if $language eq "en";
		push @lanuages, "Czech" if $language eq "cs";

    	foreach my $tree_name (keys %{$zone->{trees}}) {

        	if ($tree_name =~ /^([a-z])/) {
            	my $layer = $1;
                my $tree = $zone->{trees}->{$tree_name};
                my $array_name = "s".lc($layer)."_trees";

				compute_ord($tree) if ($tree_name eq "p_tree");

                my @nodes;
                my $sort_attr_name;
                if (defined $tree->{deepord}) {
                	$sort_attr_name = "deepord";
                } elsif (defined $tree->{_ord}) {
                    $sort_attr_name = "_ord";
                } else {
                	$sort_attr_name = "ord";
                }

                my @nodes = sort {$a->{$sort_attr_name} <=> $b->{$sort_attr_name}} ($tree, $tree->descendants);
				
				eval "push \@$array_name, \\\@nodes" if ($czengvallex::display_all or $tree_name eq "t_tree");

				#                eval "push \@$array_name, \\\@nodes";
        	}
    	}
	}


    if ($czengvallex::display_all)
	{
		return (
    	    $bundle,
    	    _interleave(@sp_trees),
        	_interleave(@sa_trees),
	        _interleave(@st_trees),
	    );
	}
	else
	{
		return ($bundle, _interleave(@st_trees));
	}
}


sub get_nodelist_hook {
    my ($fsfile, $treeNo, $currentNode, $hidden)=@_;
    my $bundle = $fsfile->tree($treeNo); 
    my $ord = FS()->order;
    #  my @nodes = ($bundle, map {($_,$_->descendants)} map {$bundle->{trees}->{$_}} keys %{$bundle->{trees}});
    #  print @nodes;

    my @nodes = get_all_nodes_to_display($bundle);

    #  print "Ord uzlu:\n";
    #  print join " ",map{"o=$_->{ord}"} @nodes;
    #  print "\n";
    $currentNode=$nodes[0] unless first { $_==$currentNode } @nodes;
    return [\@nodes, $currentNode];
}


sub file_opened_hook {
	# Stop when a non-treex file has been opened
	#	return unless PML::SchemaName() eq 'tmt_document';
		return unless PML::SchemaName() eq 'treex_document';

    foreach my $bundle ($grp->{FSFile}->trees) {
		foreach my $element ($bundle->{zones}->elements){ 
			my ($name, $zone)=@$element;
        	foreach my $tree_name (keys %{$zone->{trees}}) { 
            	my $tree_root = $zone->{trees}->{$tree_name}; 
				$tree_name=~/(.)_tree/;
				my $layer=$1;
				my $lang; 
				$lang="English" if $zone->{language} eq "en";
				$lang="Czech" if $zone->{language} eq "cs";
	            foreach my $node ($tree_root, $tree_root->descendants) {
                	$node->{_tree_name} = "S".$lang.uc($layer);
                	$node->{_layer} = $layer;
            	}
        	}
		}
    }
}

sub file_reloaded_hook {
    file_opened_hook;
}



sub display_line ($$) {
    my ($node, $line) = @_;

    if (not $node->parent) {
        if ($line==1) {
            return "$node->{_tree_name}";
        }
    }

    else {
        if ($node->{_tree_name} eq "SEnglishP") {
            if ($line==1) {
                #	return "$node->{tag} $node->{phrase}";
                return ($node->{phrase} || $node->{form});
            } elsif ($line==2) {
                if ($node->{form}) {
                    return "$node->{form}";
                } elsif ($node->{is_head}) {
                    return "#{darkgrey}($node->{head_selection_rule})";
                }
            } elsif ($line==3) {
                if ($node->{form} and $node->{is_head}) {
                    return "#{darkgrey}($node->{head_selection_rule})";
                }
            }
        } elsif ($node->{_tree_name}=~/SCzechA$/) {
            if ($line==1) {
                return $node->attr('afun').($node->{is_member}?"_Co":"");
            } elsif ($line==2) {
                return $node->attr('form');
            }
        } elsif ($node->{_tree_name}=~/A$/ or $node->{_layer} eq "a") {
            if ($line==1) {
                return $node->attr('tag').($node->{is_member}?"_Co":"");
            } elsif ($line==2) {
                return $node->attr('form');
            } elsif ($line==3) {
                return $node->attr('afun');
            }
        } elsif ($node->{_tree_name}=~/M$/) {
            if ($line==1) {
                return "$node->{form}";
            } elsif ($line==2) {
                return "#{darkgreen}$node->{lemma}";
            } elsif ($line==3) {
                return "#{darkgreen}$node->{tag}";
            }
        } elsif ($node->{_tree_name}=~/(English|Czech)T/ or $node->{_layer} eq "t") {
            if ($line==1) {
                return "$node->{t_lemma}";
            } elsif ($line==2) {
                my $plainftortext = "$node->{functor}".($node->{is_member}?"_CO":"");
                if (defined $node->attr('valalign/czengvallex_functor')) {
                  return $node->attr('valalign/czengvallex_functor')
                    ." #{gray}($plainftortext)";
                } else {
                  return $plainftortext;
                }
            } elsif ($line==3) {
			#                return "#{red}$node->{formeme}"
			#} elsif ($line==4) {
				my $classtext = '';
				my @classes=ListV($node->{syn_class}->{class});
				my $first=1;
				foreach my $class (@classes){
					if ($first){
						$first = 0;
					}else{
						$classtext .= "\n";
					}
					$classtext .= $class->{'class.rf'} . " (" . $class->{rep}->{cs} . "/" . $class->{rep}->{en} . ")";
				}
				$classtext = "#{red}$classtext";
				my @roles=ListV($node->{syn_class}->{sem_rel});
				$roletext="";
				foreach my $role (@roles){
					if ($first){
						$first = 0;
					}else{
						$roletext .= "\n";
					}
					$roletext .= $role->{'semrole'};
					$roletext .= " (" . $role->{form} . ")" if ($role->{form} !~ /^ *$/);
					$roletext .= " [" . $role->{spec} . "]" if ($role->{spec} !~ /^ *$/);
					$roletext .= "/" . $role->{'from_class.rf'};
				}
				return "#{red}$classtext" . "#{forestgreen}$roletext";
			}
        } elsif ($node->{_tree_name}=~/SCzechN/) {
            if ($line==1) {
                return $node->attr('ne_type');
            } elsif ($line==2) {
                return $node->attr('normalized_name');
            }
        } else {
            return "???";
        }
    }
}

my %treename2nodecolor = (
    'SEnglishM' => 'grey',
    'SEnglishP' => 'blue',
    'SEnglishA' => '#10AA00',
	#    'SEnglishT' => '#FF5555',
	#    'SCzechT' => '#ff9999',
    'SCzechA' => '#10AA00',
    'TEnglishT' => '#FF0000',
    'TEnglishA' => '#10AA00',
);

my %layername2nodecolor = (
    'm' => 'grey',
    'p' => 'blue',
    'a' => '#10AA00',
	#    't' => 'grey',
);


sub get_root_style() {

    return "#{nodeXSkip:15} #{nodeYSkip:2} #{lineSpacing:0.7} #{BaseXPos:0} #{BaseYPos:10} #{BalanceTree:1} #{skipHiddenLevels:0}";

}

sub get_node_style($) {
    my ($node) = @_;

    # ---- node color
    my $node_color;
    $node_color;
    if ($node->{id}=~/TEnglishT/ and $node->{is_clause_head}) {
  	$node_color = 'yellow';
    } else {
  	$node_color = $treename2nodecolor{$node->{_tree_name}} || $layername2nodecolor{$node->{_layer}};
    }

    # ---- line color
    my $line_color;
    if ($node->{id}=~/^EnglishP/ and not $node->{is_head}) { # hrany k nehlavovym potomkum jsou svetlejsi
        $line_color = "#33ccff";
    } elsif ($node->{id}=~/^(|English)T/ and $node->attr('align/is_aligned_edge')) {
        $line_color="grey";
    } elsif ($node->{id}=~/^(a|EnglishA)/ and # hrany mezi uzly, ktere nebudou slouceny v jeden t-uzel, jsou svetlejsi
                 not ($node->{is_aux_to_parent} or $node->{parent_is_aux} or ($node->parent and $node->parent()->{is_aux_to_child}) or ($node->{edge_to_collapse}))) {
        $line_color = "#55FF55";
    } else {
        $line_color = $treename2nodecolor{$node->{_tree_name}} || $layername2nodecolor{$node->{_layer}};
    }
    ;

    # zmena barvy uzlu
    if ($node->{id}=~/(|English)T/ and $node->{nodetype} ne "complex") {
        $node_color = "grey";
    }



    # ---- line width # !!! tohle by chtelo napsat prehledneji
    my $line_width;
    my $id = $node->{id};
    if ($node->{id}=~/EnglishP/ and $node->{is_head}) { # hrany k hlavovym potomkum jsou tlustejsi
        $line_width = 5;
    } elsif ($node->{id}=~/^(a|EnglishA)/ and # hrany mezi uzly, ktere budou slouceny v jeden t-uzel, jsou tlustejsi
                 ($node->{is_aux_to_parent} or $node->{parent_is_aux} or ($node->parent and $node->parent()->{is_aux_to_child}) or ($node->{edge_to_collapse}))) {
        $line_width = 5;
    } elsif ($id=~/^(|English)T/ and $node->attr('align/is_aligned_edge')) { # paralelni zavislosti (spojujici stejne uzly) jsou zvyraznene
        $line_width = 5;
    } else {
        $line_width = 2;
    }
    ;

    # --- node size
    #  my $node_size;
    #  if ($node->{nodetype} eq "complex") {
    #    $node_size=" #{Node-height:8} #{Node-width:8} ";
    #  }

    #  my $node_level = $node->{id}=~/Czech/ ? 6 : 0;
    #style: <? if ($${_tree_name} =~ /^SCzech/ and !$this->parent){ "#{Node-level:7}" } elsif ( $${_tree_name} =~ /^SCzech/ and !$this->parent->parent) { "#{Node-rellevel:7}" } ?>

    my $style = "";
    if ($languages[0] eq "English") {
        if ($node->{_tree_name} =~ /^SCzech/ and !$node->parent) {
            $style .= "#{Node-level:7}";
        } elsif ($node->{_tree_name} =~ /^SCzech/ and !$node->parent->parent) {
            $style .= "#{Node-rellevel:7}";
        }
    }
    my ($x,$y)=($node->{'.xadj'}||0,$node->{'.yadj'}||0);
    $style .= "#{Node-xadj:$x}#{Node-yadj:$y}";

    #if ($this->{is_clause_head}) {
    #    $style .= "#{Node-width:20}#{Node-height:12}";
    #}
    #;
    my $node_width = 5;
    my $node_curwidth = 10;
    my $nodetype = "plain";
    if (defined $this->parent()
      && defined $this->parent()->attr('valalign/verb/counterpart.rf')) {
      # this node is a slot
      # check consistency of manual and vallex alignments
      # correct options are:
      #   - both aligned to the same ctrpart
      #   - both marked as not aligned
      # otherwise inconsistent:
      #   - not in frame
      #   - in frame but inconsistent
      my $aligned = $this->attr('valalign/manual/aligned');
      my $ctrpart = $this->attr('valalign/manual/counterpart.rf');
      if (!defined $aligned) {
        $aligned = $this->attr('valalign/auto/aligned');
        $ctrpart = $this->attr('valalign/auto/counterpart.rf');
      }
      if (
           $this->attr('valalign/vallex/status') eq "aligned"
        && $aligned == 1
        && $this->attr('valalign/vallex/counterpart.rf') eq $ctrpart
        || $this->attr('valalign/vallex/status') eq "unaligned"
        && defined $aligned
        && $aligned == 0
        ) {
          # consistent
          $nodetype = "slot-ok";
          $node_color = "green";
      } else {
        # inconsistent vallex and manual alignment
        if ($this->attr('valalign/vallex/status') eq "not-in-frame") {
          $nodetype = "not-in-frame";
          $node_color = "grey";
          $node_width = 30; 
		  #          $node_curwidth = 40;
        } else {
          $nodetype = "inconsistent";
          $node_color = "yellow";
        }
      }
    }

 	if (exists $czengvallex::show{$this->{id}}){
 		$node_width+=10;
 	}

    return "$style #{Line-width:$line_width}"
        ."#{Oval-fill:$node_color} #{Line-fill:$line_color}"
        ."#{Node-width:$node_width}#{CurrentNode-width:$node_curwidth}"
        ."#{Node-height:$node_width}#{CurrentNode-height:$node_curwidth}"
        ."#{Oval-width:1}#{CurrentOval-width:5}"
        ."#{CurrentOval-outline:red}";
}


sub jump_to_rightmost_tree_in_next_bundle {
    print STDERR "Jumping to the previous bundle: ". ($grp->{treeNo}+2)."\n";
    GotoTree($grp->{treeNo}+2);
    my @roots = grep {not $_->parent} get_all_nodes_to_display($root);
    $this = $roots[-1]

}

sub jump_to_rightmost_tree_in_prev_bundle {
    print STDERR "Jumping to the next bundle: ".($grp->{treeNo})."\n";
    GotoTree($grp->{treeNo});
    my @roots = grep {not $_->parent} get_all_nodes_to_display($root);
    $this = $roots[-1]

}



# ------------ pridano kvuli vykreslovani koreferenci -----------------

sub SearchForNodeById($) {
    my $id = shift;
	my $selected_node;
    
	my @zones = $root->{zones}->elements;
	foreach my $element (@zones)
	{
		my ($name, $value)= @$element;
		foreach my $tree (keys %{$value->{trees}}){
			foreach my $node ($value->{trees}->{$tree}->descendants)
			{
				return ($node, 16) if $node->{id} eq $id;
			}
		}
	}

	return;
}


sub ProcessedNode{
	my $node = shift;
	my $act_t_node;

	return 3 if ($czengvallex::display_all_arrows);

	my $this_node = defined $czengvallex::current_draw ? $czengvallex::current_draw : $this;
	
	if ($this_node->{id} =~ /EnglishT/){
		$act_t_node = $this_node;
	}
	elsif ($this_node->{id} =~ /^T/){

		my @nodes = ();
		push @nodes, ($node, $node->children);
		if (defined $node->parent){
			push @nodes, $node->parent;
			push @nodes, $node->parent->children;
		}

		my $found_counterpart = 0;
		foreach (@nodes){
		
			if ($_->attr('valalign/manual/counterpart.rf') eq $this_node->{id} || 
			   	(defined $_->attr('alignment') && $_->attr('alignment')->[0]->{'counterpart.rf'} eq $this_node->{id})){
					$act_t_node = $_;
					$found_counterpart = 1;
					last;
	   		}
		}

		return 0 if not $found_counterpart;
	}

	else {return 0};

	if (defined $act_t_node->attr('valalign/verb/counterpart.rf')){
		#zpracovavane uzly jsou vybrany uzel a jeho synove
		return 1 if ($node eq $act_t_node);															#sloveso
		return 2 if (defined $node->parent and $node->parent eq $act_t_node);						#slot
	}
	elsif (defined $act_t_node->parent and defined $act_t_node->parent->attr('valalign/verb/counterpart.rf')){
		#zpracovane uzly jsou rodic vybraneho uzlu a sourozenci vybraneho uzlu
		return 1 if ($node eq $act_t_node->parent);													#sloveso
		return 2 if (defined $node->parent and $node->parent eq $act_t_node->parent);				#slot
	}

	
	return 0;
}

# vykopirovano z PML_T.mak:

sub node_style_hook {
    my ($node,$styles)=@_;
    my %line = GetStyles($styles,'Line');
    my %my_line;

    #  if ($node->{'coref_gram.rf'}) {
    #    $node->{coref_special} = 'exoph';
    #  }


    # make sure we only alter the very first line
    my $lines = scalar(split /&/,$line{coords});
    if ($lines>1) {
        for (keys %my_line) {
            my @l = split /&/,$line{$_};
            shift @l;
            $line{$_}=join '&',$my_line{$_},@l;
        }
    } else {
        $line{$_}=$my_line{$_} for keys %my_line;
    }

    if ($node->{'coref_text.rf'} or $node->{'coref_gram.rf'} or $node->{'compl.rf'} or $node->{coref_special} or $node->{'valalign'}->{'coref.rf'}) {
        my @gram = grep {$_ ne "" } ListV($node->{'coref_gram.rf'});
        my @text = grep {$_ ne "" } ListV($node->{'coref_text.rf'});
        my @compl = grep {$_ ne "" } ListV($node->{'compl.rf'});
 		my @valalign_coref = grep {$_ ne ""} ListV($node->{'valalign'}->{'coref.rf'});
 		
 		#add color for valalign/coref.rf
 		CustomColor('arrow_valalign_coref', "magenta");
 
        DrawCorefArrows($node,$styles,\%line,
                        [@gram,@text,@compl,@valalign_coref],
                        [(map 'grammatical',@gram),
                         (map 'textual',@text),
                         (map 'compl',@compl), 
						 (map 'valalign_coref',@valalign_coref)
                     ]
                    );
    }

	my $processedNode =  ProcessedNode($node);

	return if !$processedNode;

    my @arrows;

 	#arrows for valalign/coref.rf
 	if ($node->{'valalign'}->{'coref.rf'}){
 		my @valalign_coref = grep {$_ ne ""} ListV($node->{'valalign'}->{'coref.rf'});
 		foreach my $coref (@valalign_coref){
 			push @arrows, {
 				"target" => $coref, 
 				"type" => "coref"
 			};
 		}
 	}

    # Draw alignment on the tectogramatical layer
    # There are three types of alignment arrows:
    # blue: aligns made both manually and automatically
    # red:  aligns made only manually
    # green: aligns made only automatically
    if ($node->attr('alignment') or $node->attr('align/manual_links')) {
        my %automatic;
        my $links_rf = $node->attr('alignment');
        for (my $i = 0; $i <= $#$links_rf; $i++) {
            $automatic{$links_rf->[$i]->{'counterpart.rf'}} = 1 if $links_rf->[$i]->{'conterpart.rf'} ne "";
        }
        my %manual;
        #my $manual_links_rf = $node->attr('align/manual_links');
        #for (my $i = 0; $i <= $#$manual_links_rf; $i++) {
        #    $manual{$manual_links_rf->[$i]->{'counterpart.rf'}} = 1;
        #}
        my @both;
        my @automatic_only;
        my @manual_only;
        my %seen;
        foreach my $n (keys %automatic, keys %manual) {
          next if $seen{$n};
          $seen{$n} = 1;
          push @arrows, {
            "target" => $n,
            "type" => "nodeali-"
              .($manual{$n} ? ( $automatic{$n} ? "both" : "manual" ) : "auto"),
          };
        }
    }

    ### Draw valency slot alignment arrows

    # First prepare the arrows
    if (defined $node->attr('valalign/verb/counterpart.rf')) {
      push @arrows, {
        "target" => $node->attr('valalign/verb/counterpart.rf'),
        "type" => "verb"
      }
    }
	if ($processedNode != 1){
	    if ($node->attr('valalign/vallex/status') eq "aligned") {
			if ($node->attr('valalign/slot_remove')){
			  push @arrows, {
    	    	"target" => $node->attr('valalign/vallex/counterpart.rf'),
	    	    "type" => "slot-vallex-del"
			  }
			}
			else{
	    	  push @arrows, {
    	    	"target" => $node->attr('valalign/vallex/counterpart.rf'),
	    	    "type" => "slot-vallex"
				}
		    }
	    } elsif ($node->attr('valalign/vallex/status') eq "unaligned") {
			if ($node->attr('valalign/slot_remove')){
			  push @arrows, {
    	    	"target" => undef,
	    	    "type" => "slot-vallex-del"
			  }
			}
			else{
	    	  push @arrows, {
    	    	"target" => undef,
	    	    "type" => "slot-vallex"
	    	  }
		  }
	    }
	
		if (!$node->attr('valalign/not_collect')){
		    if ($node->attr('valalign/auto/aligned') eq "1") {
    		  push @arrows, {
        		"target" => $node->attr('valalign/auto/counterpart.rf'),
	        	"type" => "slot-auto"
	    	  };
			  AddStyle($styles, "Node", -addwidth=>15, -addheight=>15);
		    }
    		if ($node->attr('valalign/auto/aligned') eq "0") {
		      push @arrows, {
    		    "target" => undef, # explicit no alignment
        		"type" => "slot-auto"
		      };
			  AddStyle($styles, "Node", -addwidth=>15, -addheight=>15);
    		}
	    	if ($node->attr('valalign/manual/aligned') eq "1") {
	    	  push @arrows, {
    	    	"target" => $node->attr('valalign/manual/counterpart.rf'),
	    	    "type" => "slot-manual"
	    	  };
			  AddStyle($styles, "Node", -addwidth=>15, -addheight=>15);
		    }
    		if ($node->attr('valalign/manual/aligned') eq "0") {
		      push @arrows, {
    		    "target" => undef, # explicit no alignment
        		"type" => "slot-manual"
		      };
			  AddStyle($styles, "Node", -addwidth=>15, -addheight=>15);
    		}
		}
	}

    # Styles:
    my $typestyle;
    $typestyle->{"slot-manual"}->{"color"} = "red";
    $typestyle->{"slot-manual"}->{"width"} = "5";
    $typestyle->{"slot-manual"}->{"dash"} = "2,3,5,3";

    $typestyle->{"slot-auto"}->{"color"} = "blue";
    $typestyle->{"slot-auto"}->{"width"} = "5";
    $typestyle->{"slot-auto"}->{"dash"} = "2,3,5,3";

    $typestyle->{"slot-vallex"}->{"color"} = "green";
    $typestyle->{"slot-vallex"}->{"width"} = "10";
    $typestyle->{"slot-vallex"}->{"dash"} = "1";

    $typestyle->{"slot-vallex-del"}->{"color"} = "magenta";
    $typestyle->{"slot-vallex-del"}->{"width"} = "10";
    $typestyle->{"slot-vallex-del"}->{"dash"} = "1";

    $typestyle->{"verb"}->{"color"} = "green";
    $typestyle->{"verb"}->{"width"} = "5";
    $typestyle->{"verb"}->{"dash"} = "5,10,5,10";

    $typestyle->{"nodeali-manual"}->{"color"} = "red";
    $typestyle->{"nodeali-manual"}->{"width"} = "1";
    $typestyle->{"nodeali-manual"}->{"dash"} = "1,3,1,3";

    $typestyle->{"nodeali-both"}->{"color"} = "blue";
    $typestyle->{"nodeali-both"}->{"width"} = "1";
    $typestyle->{"nodeali-both"}->{"dash"} = "1,3,1,3";

    $typestyle->{"nodeali-auto"}->{"color"} = "green";
    $typestyle->{"nodeali-auto"}->{"width"} = "1";
    $typestyle->{"nodeali-auto"}->{"dash"} = "1,3,1,3";

 	$typestyle->{"coref"}->{"color"} = "magenta";
 	$typestyle->{"coref"}->{"width"} = "1";
 	$typestyle->{"coref"}->{"dash"} = "1";
 
    # Then insert them to our style
    my $line = \%line; # the style of Lines
    my (@coords, @colors, @dash, @widths, @tags);
    foreach my $a (@arrows) {
      push @colors, $typestyle->{$a->{"type"}}->{"color"};
      push @dash, $typestyle->{$a->{"type"}}->{"dash"};
      push @widths, $typestyle->{$a->{"type"}}->{"width"};
      push @tags,"";
      my $rf = $a->{"target"};
      if (defined $rf) {
        my $T="[?\$node->{id} eq '$rf'?]";
        my $X="(x$T-xn)";
        my $Y="(y$T-yn)";
        my $D="sqrt($X**2+$Y**2)";

        my $c = <<COORDS;
&n,n,
(x$T+xn)/2 - $Y*(25/$D+0.12),
(y$T+yn)/2 + $X*(25/$D+0.12),
x$T,y$T
COORDS
        push @coords,$c;
      } else {
        # explicit no alignment
        push @coords,"\&n,n,n-30,n";
      }
    }

    # I have no idea what this is:
    $line->{-coords} ||= 'n,n,p,p';

    # I have no idea what this is:
    # make sure we don't alter any previous line
    my $lines = scalar($line->{-coords}=~/&/g)+1;
    for (qw(-arrow -dash -width -fill -smooth -arrowshape)) {
        $line->{$_}.='&'x($lines-scalar($line->{$_}=~/&/g)-1);
    }

    # Insert our lines
    if (@coords) {
      AddStyle($styles,'Line',
                   -coords => $line->{-coords}.join("",@coords),
                   -arrow => $line->{-arrow}.('&last' x @coords),
                   -arrowshape => $line->{-arrowshape}.('&16,18,3' x @coords),
                   -dash => $line->{-dash}.join('&','',@dash),
                   -width => $line->{-width}.join("&","",@widths),
                   -fill => $line->{-fill}.join("&","",@colors),
                   -tag => $line->{-tag}.join("&","",@tags),
                   -smooth => $line->{-smooth}.('&1' x @coords)
             );
    }

    1;
}

=item DrawCorefArrows()

Called from C<node_style_hook>. Draws coreference arrows using
following properties: textual arrows in CustomColor C<arrow_textual>,
grammatical in <arrow_grammatical> (and dashed in Full stylesheet),
complement arrow in C<arrow_compl> (and dot-dashed in Full
stylesheet), segment arrow in C<arrow_segm> and exophora arrow in
C<arrow_exoph>.

=cut

#$main::macroDebug=1;

sub DrawCorefArrows {
    my ($node,$styles,$line,$corefs,$cortypes)=@_;
	# WHAT IS COREFLEMMAS? I CAN NOT SEE WHAT IT IS USEFUL FOR...
	# delete $coreflemmas{$node->{id}};

    my (@coords,@colors,@dash,@tags);
    my ($rotate_prv_snt,$rotate_nxt_snt,$rotate_dfr_doc)=(0,0,0);
    my $ids={};
    #  my $nd = $root; while ($nd) { $ids->{$nd->{id}}=1 } continue { $nd=$nd->following };  # nahrazeno by ZZ nasledujicim radkem
    #  foreach my $node (get_all_nodes_to_display($root)) { $ids->{$node->{id}}=1; };        # by PP: rychlejsi a funkcni pri tisku pomoci example/print.btred
    foreach my $node (GetDisplayedNodes()) { $ids->{$node->{id}}=1 };
    foreach my $coref (@$corefs) {
        my $cortype=shift @$cortypes;

        #    print "Coref: $coref    cortype: $cortype\n";
        if ($ids->{$coref}) {   #index($coref,$id1)==0) {
            print STDERR "ref-arrows: Same sentence\n" if $main::macroDebug;
            # same sentence
            my $T="[?\$node->{id} eq '$coref'?]";
            my $X="(x$T-xn)";
            my $Y="(y$T-yn)";
            my $D="sqrt($X**2+$Y**2)";
            push @colors,CustomColor('arrow_'.$cortype);
            push @dash,GetPatternsByPrefix('full')?($cortype eq'compl'?'2,3,5,3':$cortype eq'grammatical'?'5,3':qw()):qw();


            my $c = <<COORDS;

&n,n,
(x$T+xn)/2 - $Y*(25/$D+0.12),
(y$T+yn)/2 + $X*(25/$D+0.12),
x$T,y$T


COORDS
            push @coords,$c;
            push @tags,$cortype;
        } else { # should be always the same document, if it exists at all
            my($refed,$treeNo)=SearchForNodeById($coref);
            my $orientation=$treeNo-CurrentTreeNumber()-1;
            $orientation=$orientation>0 ? 'right' : ($orientation<0 ? 'left':0);
    
			# WHAT IS COREFLEMMAS? I CAN NOT SEE WHAT IT IS USEFUL FOR...
			# $coreflemmas{$node->{id}}.=' '.$refed->{t_lemma};

            if ($orientation=~/left|right/) {
                if ($orientation eq'left') {
                    print STDERR "ref-arrows: Preceding sentence\n"if $main::macroDebug;
                    push @colors,CustomColor('arrow_'.$cortype);
                    push @dash,qw();
                    push @coords,"\&n,n,n-30,n+$rotate_prv_snt";
                    push @tags,$cortype;
                    $rotate_prv_snt+=10;
                } else {        #right
                    print STDERR "ref-arrows: Following sentence\n" if $main::macroDebug;
                    push @colors,CustomColor('arrow_'.$cortype);
                    push @dash,qw();
                    push @coords,"\&n,n,n+30,n+$rotate_nxt_snt";
                    push @tags,$cortype;
                    $rotate_nxt_snt+=10;
                }
            } else {
                print STDERR "ref-arrows: Not found!\n" if $main::macroDebug;
                push @colors,CustomColor('error');
                push @dash,qw();
                push @coords,"&n,n,n+$rotate_dfr_doc,n-25";
                push @tags,$cortype;
                $rotate_dfr_doc+=10;
            }
        }
    }
    if ($node->{coref_special}eq'segm') { # pointer to an unspecified segment of preceding sentences
        print STDERR "ref-arrows: Segment - unaimed arrow\n" if $main::macroDebug;
        push @colors,CustomColor('arrow_segment');
        push @dash,qw();
        push @coords,"&n,n,n-25,n+$rotate_prv_snt";
        push @tags,'segm';
        $rotate_prv_snt+=10;
    }
    if ($node->{coref_special}eq'exoph') {
        print STDERR "ref-arrows: Exophora\n" if $main::macroDebug;
        push @colors,CustomColor('arrow_exoph');
        push @dash,qw();
        push @coords,"&n,n,n+$rotate_dfr_doc,n-25";
        push @tags,'exoph';
        $rotate_dfr_doc+=10;
    }
    $line->{-coords} ||= 'n,n,p,p';

    # make sure we don't alter any previous line
    my $lines = scalar($line->{-coords}=~/&/g)+1;
    for (qw(-arrow -dash -width -fill -smooth -arrowshape)) {
        $line->{$_}.='&'x($lines-scalar($line->{$_}=~/&/g)-1);
    }
    if (@coords) {
        AddStyle($styles,'Line',
                 -coords => $line->{-coords}.join("",@coords),
                 -arrow => $line->{-arrow}.('&last' x @coords),
                 -arrowshape => $line->{-arrowshape}.('&16,18,3' x @coords),
                 -dash => $line->{-dash}.join('&','',@dash),
                 -width => $line->{-width}.('&1' x @coords),
                 -fill => $line->{-fill}.join("&","",@colors),
                 -tag => $line->{-tag}.join("&","",@tags),
                 -smooth => $line->{-smooth}.('&1' x @coords)
             );
    }
}

 sub RememberNode{
 	$czengvallex::remember=$this;
 	undef %czengvallex::show;
 	$czengvallex::show{$this->{id}}=1;
 	ChangingFile(0);
 }
 
 sub ForgetRemembered{
 	delete $czengvallex::show{$czengvallex::remember->{id}};
 	undef $czengvallex::remember;
 	ChangingFile(0);
 }
 
 sub AddValalignCoref{
 	my ($node, $target_id)=@_;
 
 	ChangingFile(0);
 	if (first{$target_id eq $_} ListV($node->{valalign}->{'coref.rf'})){
 		@{$node->{valalign}->{'coref.rf'}} = grep{$_ ne $target_id} ListV($node->{valalign}->{'coref.rf'});
 	}
 	else{
 		AddToList($node, 'valalign/coref.rf', $target_id);	
 	}
 
 	ChangingFile(1);
 	
 }
 
 sub ValalignCorefToRemembered{
 	AddValalignCoref($this, $czengvallex::remember->{id});
 }
1;

