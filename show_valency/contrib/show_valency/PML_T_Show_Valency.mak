# -*- cperl -*-

#ifndef PML_T_Show_Valency
#define PML_T_Show_Valency

package PML_T_Show_Valency;

#binding-context PML_T_Show_Valency
#key-binding-adopt PML_T_View
#menu-binding-adopt PML_T_View

BEGIN { import PML_T; }
sub first (&@);
use vars qw(@modes $mode);
BEGIN {
   @modes = qw(
    SHOW_ALL
    SHOW_OBLIG
    SHOW_OBLIG_NON_ACTANTS
    SHOW_OBLIG_ADVERBIAL
    SHOW_ALL_ADVERBIAL
   );
}
use constant {
  OBLIG=>1,
  NON_OBLIG=>2,
  map { $modes[$_] => $_ } 0..$#modes
};

$mode=SHOW_ALL;

#bind cycle_mode to c menu Cycle through highlighting modes
sub cycle_mode {
  $mode=($mode+1) % scalar(@modes);
  ChangingFile(0);
}

sub allow_switch_context_hook { 1 }

sub FindVallex {
  if (FileMetaData('refnames')) {
    return PML_T::FindVallex();
  } else {
    return ('v',FindInResources('vallex.xml'));
  }
}

sub switch_context_hook {
  PML_T_Anot::CreateStylesheets();
  my $cur_stylesheet = GetCurrentStylesheet();
  SetCurrentStylesheet('PML_T_Anot'),Redraw();
  undef$PML::arf;
  my ($prefix,$file)=FindVallex();
  ValLex::GUI::Init({-vallex_file => $file});
}

sub get_status_line_hook {
  return unless $this;
  my$statusline= [
	  # status line field definitions ( field-text => [ field-styles ] )
	  [
	    "     a:" => [qw(label)]
          ],
	  # field styles
	  [
           "ref" => [-underline => 1, -foreground => 'blue'],
	   "label" => [-foreground => 'black' ],
	   "value" => [-underline => 1 ],
	   "bg_white" => [ -background => 'white' ],
           "status" => [ -foreground => CustomColor('status')]
	  ]
	 ];
  my$sep=" ";
  foreach my $ref (
                   $this->{nodetype}eq'root'
		     ?
                   $this->{'atree.rf'}
                   :
                   ($this->attr('a/lex.rf'),ListV($this->attr('a/aux.rf')))){
    if($ref){
      push @{$statusline->[0]},
#        ($sep => [qw(label)],"$ref" => [ '{REF}','ref',$ref ]);
        ($sep => [qw(label)],GetANodeByID($ref)->attr('m/form') => [ '{REF}','ref',$ref ]);
    $sep=", ";
    }
  }
  unshift @{$statusline->[0]},
    ($this->{'val_frame.rf'} ?
     ("     frame: " => [qw(label)],
      join(",",map{_get_frame($_)}AltV($this->{'val_frame.rf'})) => [qw({FRAME} value)]
     ) : ());
  push @{$statusline->[0]},
    ($PML_T_Edit::remember ?
     ('   Remembered: ' => [qw(label)],
      $PML_T_Edit::remember->{t_lemma} || $PML_T_Edit::remember->{id}=> [qw(status)]
     ):'');
  unshift @{$statusline->[0]},('mode: '.$modes[$mode].' ' => ['label']);
  return $statusline;
}#get_status_line_hook

sub _get_frame {
  my$rf=shift;
  my ($prefix,$file)=FindVallex();
  $rf=~s/^\Q$prefix\E\#//;
  my $frame = $ValLex::GUI::ValencyLexicon->by_id($rf);
  return $ValLex::GUI::ValencyLexicon->serialize_frame($frame) if $frame;
  'NOT FOUND!';
}#_get_frame

sub get_value_line_hook {
  unless (FileMetaData('refnames')) {
    return [[$root->{sentence}]];
  }
  my $out = &PML_T_View::get_value_line_hook;
  my %cached;
  for my $item (@$out) {
    next unless ref $item;
    for my $n (grep { ref($_) eq 'FSNode' } @$item) {
      my $belongs = $cached{$n} ||= BelongsToValencyFrame($n);
      if ($belongs) {
	push @$item, '-background=>'.($belongs==OBLIG ? '#FFDFA7' : 'lightblue');
      }
    }
  }
  return $out;
}

sub node_style_hook {
  my ($node,$styles) = @_;
  my $belongs = BelongsToValencyFrame($node);
  if ($belongs) {
    AddStyle($styles,'Oval',
	     -fill => ($belongs==OBLIG ? 'orange' : 'blue'),
	    );
    AddStyle($styles,'Node',
	     -addwidth=>5,
	     -addheight=>5
	    );
  }
}


sub BelongsToValencyFrame {
 shift if defined($_[0]) and !ref($_[0]);
 my $node=$_[0]||$this;
 my @F = uniq(map AltV($_->{'val_frame.rf'}),
	      grep $_->attr('gram/sempos') eq 'v', PML_T::GetEParents($node));
 my $functor = $node->{functor};
 my $ret;
 if (@F) {
   my ($prefix,$file)=FindVallex();
   my $V=$ValLex::GUI::ValencyLexicon;
   for my $rf (@F) {
     $rf=~s/^\Q$prefix\E\#//;
     my $element = first { $V->func($_) eq $functor } map { $V->all_elements($_) } $V->by_id($rf);
     if ($element) {
       my $oblig=$V->isOblig($element);
       my $is_adv = first { $_->attr('m/tag') =~ /^D/ } grep defined, GetALexNode($node);
       if ($mode==SHOW_ALL
	   or $mode==SHOW_OBLIG and $oblig
	   or $mode==SHOW_OBLIG_NON_ACTANTS and $oblig and $functor!~/^(ACT|PAT|ADDR|ORIG|EFF)$/
	   or $mode==SHOW_OBLIG_ADVERBIAL and $oblig and $is_adv,
	   or $mode==SHOW_ALL_ADVERBIAL and $is_adv) {
	 return $oblig ? OBLIG : NON_OBLIG;
       }
     }
   }
 }
 return;
}

#endif PML_T_Show_Valency
