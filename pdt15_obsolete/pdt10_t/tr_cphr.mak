# -*- cperl -*-
#encoding iso-8859-2

package TR_CPHR;

BEGIN {
  import TredMacro; 
  import Tectogrammatic;
  import Coref;
  import TR_FrameValidation;
  import TR_FrameValidation qw(@fv_trans_rules_V);
}

sub first (&@);
sub with_AR (&);
sub uniq { my %a; @a{@_}=@_; values %a }


#bind validate_assigned_frames to Ctrl+M menu Validate against assigned frame


#bind find_and_assing_CPHR_and_frame to C menu Find possible CPHR, assign func=CPHR and display frame selection dialog
sub find_and_assing_CPHR_and_frame {
  my ($c,$func) = discover_cphr_dphr($this);
  if ($func eq 'CPHR') {
    my $node = $this;
    $this = $c; 
    assign_CPHR_and_add_QCor();
    $this = $node;
    choose_frame_match_CPHR();
  } else {
    print "Different functor: $func\n";
  }
}

#bind assign_CPHR to c menu Assign CPHR
sub assign_CPHR {
  print "Assigning CPHR to $this $this->{trlemma}\n";
  return unless $this;
  $this->{func} = 'CPHR';
  print "done\n";
}

#bind assign_CPHR_and_add_QCor to q menu Assign CPHR and add QCor
sub assign_CPHR_and_add_QCor {
  unless ($this and $this->{func} ne 'PRED' and $this->{tag}!~/^V/) {
    ChangingFile(0);
    return;
  }
  assign_CPHR();
  unless (first { $_->{func} eq 'ACT' } $this->children) {
    add_Gen_ACT();
    my $qcor = first { $_->{func} eq 'ACT' } $this->children;
    unless ($qcor) {
      print "Why can't I find &Gen;.ACT I just created\n";
      return;
    }
    $qcor->{trlemma} = '&QCor;';
    foreach my $p (PDT::GetFather_TR($this)) {
      if ($p->{trlemma} eq 'm�t') {
	print "ADDING coref\n";
	foreach my $act (uniq map { _highest_coord($_) } 
			 grep { $_->{func} eq 'ACT' } PDT::GetChildren_TR($p)) {
	  my $coref = $act->{AID}.$act->{TID};
	  print "ADDING coref to $coref\n";
	  Coref::assign_coref($qcor,$coref,'grammatical');
	}
      }
    }
  }
}

#bind choose_frame_match_CPHR to Ctrl+Return menu Select frame from valency lexicon
#bind choose_frame_match_CPHR to F1 menu Select frame from valency lexicon

sub choose_frame_match_CPHR {
  init_vallex();
  return unless ($this->{tag}=~/^[VNA]/);
  my @match = filter_possible_cphr_frames($this);
  if (@match) {
    $this->{frameid} = join '|',map { $_->getAttribute('id') } @match;
  }
  choose_frame(\&TR_FrameValidation::frame_chosen);
}



sub filter_possible_cphr_frames {
  my $node = $_[0] || $this;
  return unless $node;
  my $c = first { $_->{func} eq 'CPHR' } PDT::GetChildren_TR($node);
  init_vallex();
  my $V = $TR_FrameValidation::V;
  my $aids = hash_AIDs();
  my $func = get_func($node);
  return() if $node->{tag}!~/^V/ or $func =~ /[DF]PHR/ or
    ($func eq 'APPS'and $node->{trlemma} eq 'tzn');

  my $lemma = $node->{trlemma};
  $lemma =~ s/_/ /g;
  my $word = $V->word($lemma,'V');
  if ($word) {
    # frame not resolved
    my @frames = grep {
      first { $V->func($_) eq 'CPHR' }
	$V->all_elements($_)
      } $V->valid_frames($word);
    my @result;
    foreach my $frame (@frames) {
      my @transformed = do_transform_frame($V,\@fv_trans_rules_V,$node,$frame,$aids,0);
      foreach my $tframe (@transformed) {
	foreach my $e (grep { $V->func($_) eq 'CPHR' } $V->all_elements($tframe)) {
	  my @forms = $V->forms($e);
	  my $func = $V->func($e);
	  next unless (@forms);
	  if (first { match_form($c,$_,$aids,{}) } @forms) {
	  push @result, $frame;
	}
	}
      }
    }
    return @result;
  }
  return ();
}



my %cache;
sub discover_cphr_dphr {
  my $node = shift || $this;
  return unless $node;
  init_vallex();
  my $V = $TR_FrameValidation::V;
  my $aids = hash_AIDs();
  my $func = get_func($node);
  # TODO: N, A
  return() if $node->{tag}!~/^V/ or $func =~ /[DF]PHR/
    or ($func eq 'APPS'and $node->{trlemma} eq 'tzn');
  my $lemma = $node->{trlemma};
  $lemma =~ s/_/ /g;
  $cache{$lemma} = $V->word($lemma,'V') unless exists($cache{$lemma});
  if ($cache{$lemma}) {
    # frame not resolved
    my @c = grep { $_->{AID} ne "" or $_->{AIDREFS} ne "" } PDT::GetChildren_TR($node);
    print "@c\n";
    return () unless @c;
    $cache{"FRAMES:".$lemma} = [
				grep {
				first { $V->func($_) =~ /^[CD]PHR$/ }
				  $V->all_elements($_)
				} $V->valid_frames($cache{$lemma})]
      unless exists($cache{"FRAMES:".$lemma});
    foreach my $frame (@{$cache{"FRAMES:".$lemma}}) {
      print "$lemma $frame\n";
      my @transformed = do_transform_frame($V,\@fv_trans_rules_V,$node,$frame,$aids,0);
      foreach my $tframe (@transformed) {
	print "tframe $tframe\n";
	foreach my $e (grep { $V->func($_) =~ /^[DC]PHR$/ } $V->all_elements($tframe)) {
	  my @forms = $V->forms($e);
	  my $func = $V->func($e);
	  print "func $func\n";
	  
	  next unless (@forms);
	  foreach my $c (@c) {
	    next if $c->{func} eq $func;
	    if (first { match_form($c,$_,$aids,{}) } @forms) {
	      print "MATCH: ",
		$V->frame_id($frame),"\t", $V->serialize_frame($tframe),"\n";
	      return ($c,$func);
	    }
	  }
	}
      }
    }
  }
  return ();
}
