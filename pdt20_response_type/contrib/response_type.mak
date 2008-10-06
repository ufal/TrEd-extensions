# -*- cperl -*-
package Response_Type;
#ifdef TRED
{

use strict;
BEGIN {
  import TredMacro;
}

#include <contrib/pedt/PML_En_T_Anot.mak>
#include <contrib/support/arrows.inc>

#binding-context Response_Type

#key-binding-adopt PML_En_T_Anot
#menu-binding-adopt PML_En_T_Anot

# init caches

sub get_value_line_hook {
  PML_T::get_value_line_hook(@_);
}

sub root_style_hook {
  my ($node,$styles)=@_;
  %PML_T::coreflemmas_hash=();
  DrawArrows_init();
  return;
}
# clear caches
sub after_redraw_hook {
  %PML_T::coreflemmas_hash=();
  DrawArrows_cleanup();
  return;
}

sub node_style_hook {
  my ($node,$styles)=@_;
  
  if  (
      $node->{'coref_text.rf'}
      or $node->{'coref_gram.rf'}
      or $node->{'compl.rf'}
      or $node->{coref_special}
      or $node->attr('response_type/wh_path')
      or $node->attr('response_type/bridging')
      or $node->attr('response_type/overrules')
      or $node->attr('response_type/other')
    ) {
    CustomColor('arrow_wh_path', 'red');
    CustomColor('arrow_bridging', 'green');
    CustomColor('arrow_overrules', 'darkgrey');
    CustomColor('arrow_other', 'orange');
    my @gram = grep {$_ ne "" } ListV($node->{'coref_gram.rf'});
    my @text = grep {$_ ne "" } ListV($node->{'coref_text.rf'});
    my @compl = grep {$_ ne "" } ListV($node->{'compl.rf'});
    my @wh_path = grep {$_ ne "" } ListV($node->attr('response_type/wh_path'));
    my @bridge = grep {$_ ne "" } ListV($node->attr('response_type/bridging'));
    my @over = grep {$_ ne "" } ListV($node->attr('response_type/overrules'));
    my @other = grep {$_ ne "" } ListV($node->attr('response_type/other'));
    DrawCorefArrows($node,$styles,undef,
		      [@gram,@text,@compl,@wh_path,@bridge,@over,@other],
		      [(map 'grammatical',@gram),
		       (map 'textual',@text),
		       (map 'compl',@compl),
               (map 'wh_path',@wh_path),
		       (map 'bridging',@bridge),
		       (map 'overrules',@over),
               (map 'other',@other)
		      ]
                     );
  }
  
  #~ if  ($node->{'coref_text.rf'} or $node->{'coref_gram.rf'} or $node->{'compl.rf'} or $node->{coref_special}) {
    #~ my @gram = grep {$_ ne "" } ListV($node->{'coref_gram.rf'});
    #~ my @text = grep {$_ ne "" } ListV($node->{'coref_text.rf'});
    #~ my @compl = grep {$_ ne "" } ListV($node->{'compl.rf'});
    #~ DrawCorefArrows($node,$styles,undef,
		      #~ [@gram,@text,@compl],
		      #~ [(map 'grammatical',@gram),
		       #~ (map 'textual',@text),
		       #~ (map 'compl',@compl)
		      #~ ],
                     #~ );
  #~ }
  
  return 1;
}

my %coreflemmas;
sub DrawCorefArrows {
  my ($node,$styles,$line,$corefs,$cortypes)=@_;
  delete $coreflemmas{$node->{id}};
  my (@coords,@colors,@dash,@tags);
  my ($rotate_prv_snt,$rotate_nxt_snt,$rotate_dfr_doc)=(0,0,0);
  
  my $ids={};
  my $nd = $node->root; # $root can't be used here - think TrEd::Print!
  while ($nd) { $ids->{$nd->{id}}=1 } continue { $nd=$nd->following };
  
  foreach my $coref (@$corefs) {
    my $cortype=shift @$cortypes;
    if ($node->{id} eq $coref) {
      print STDERR "ref-arrows: Same node!!\n" if $main::macroDebug;
      push @coords,'&n,n,n+25,n,n+25,n+25,n,n+25,n-25,n+25,n-25,n,n,n';
      push @tags,$cortype;
    } elsif ($ids->{$coref}) { #index($coref,$id1)==0) {
      print STDERR "ref-arrows: Same sentence\n" if $main::macroDebug;
      # same sentence
      my $T="[?\$node->{id} eq '$coref'?]";
      my $X="(x$T-xn)";
      my $Y="(y$T-yn)";
      my $D="sqrt($X**2+$Y**2)";
      push @colors,CustomColor('arrow_'.$cortype);
      push @dash,GetPatternsByPrefix('full')?($cortype eq'compl'?'2,3,5,3':$cortype eq'grammatical'?'5,3':1):'';
      my $c = <<COORDS;

&n,n,
(x$T+xn)/2 - $Y*(25/$D+0.12),
(y$T+yn)/2 + $X*(25/$D+0.12),
x$T,y$T


COORDS
      push @coords,$c;
      push @tags,$cortype;
    } else { # should be always the same document, if it exists at all
      my($refed,$treeNo)=PML::SearchForNodeById($coref);
      my $orientation=$treeNo-CurrentTreeNumber()-1;
      $orientation=$orientation>0 ? 'right' : ($orientation<0 ? 'left':0);
      $coreflemmas{$node->{id}}.=' '.$refed->{t_lemma};
      if($orientation=~/left|right/){
	if($orientation eq'left'){
	  print STDERR "ref-arrows: Preceding sentence\n"if $main::macroDebug;
	  push @colors,CustomColor('arrow_'.$cortype);
	  push @dash,'';
	  push @coords,"\&n,n,n-30,n+$rotate_prv_snt";
	  push @tags,$cortype;
	  $rotate_prv_snt+=10;
	}else{ #right
	  print STDERR "ref-arrows: Following sentence\n" if $main::macroDebug;
	  push @colors,CustomColor('arrow_'.$cortype);
	  push @dash,'';
	  push @coords,"\&n,n,n+30,n+$rotate_nxt_snt";
	  push @tags,$cortype;
	  $rotate_nxt_snt+=10;
	}
      }else{
	print STDERR "ref-arrows: Not found!\n" if $main::macroDebug;
	push @colors,CustomColor('error');
	push @dash,'';
	push @coords,"&n,n,n+$rotate_dfr_doc,n-25";
	push @tags,$cortype;
	$rotate_dfr_doc+=10;
      }
    }
  }
  if($node->{coref_special}eq'segm') { # pointer to an unspecified segment of preceeding sentences
    print STDERR "ref-arrows: Segment - unaimed arrow\n" if $main::macroDebug;
    push @colors,CustomColor('arrow_segment');
    push @dash,'';
    push @coords,"&n,n,n-25,n+$rotate_prv_snt";
    push @tags,'segm';
    $rotate_prv_snt+=10;
  }
  if($node->{coref_special}eq'exoph') {
    print STDERR "ref-arrows: Exophora\n" if $main::macroDebug;
    push @colors,CustomColor('arrow_exoph');
    push @dash,'';
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
	     -smooth => $line->{-smooth}.('&1' x @coords));
  }
}

sub AddResponseType{
  my($node,$target,$type)=@_;
  if (first{$target->{id}eq$_}ListV($node->{'response_type'}->{$type})){
    @{$node->{'response_type'}->{$type}}
      =grep{$_ ne$target->{id}}ListV($node->{'response_type'}->{$type});
  }else{
    AddToList($node,'response_type/' . $type,$target->{id});
  }
}#AddCoref

sub GramArowToRemembered{
  ChangingFile(0);
  if($PML_T_Edit::remember and $PML_T_Edit::remember->parent and $this->parent){
    PML_T_Edit::AddCoref($this,$PML_T_Edit::remember,'coref_gram.rf');
    ChangingFile(1);
  }
}#GramArowToRemembered

sub GeneralArrow{
  my $type = shift;
  ChangingFile(0);
  if($PML_T_Edit::remember and $PML_T_Edit::remember->parent and $this->parent){
    AddResponseType($this,$PML_T_Edit::remember,$type);
    ChangingFile(1);
  }
}#GeneralArrow

sub WhPathArrow {
  GeneralArrow('wh_path');
}

sub BridgingArrow {
  GeneralArrow('bridging');
}

sub OverrulesArrow {
  GeneralArrow('overrules');
}

sub OtherArrow {
  GeneralArrow('other');
}

#bind PML_T_Edit->RememberNode to space menu Remember Node
#bind PML_T_Edit->TextArowToRemembered to Ctrl+space menu Make Textual Coreference Arrow to Remembered Node
#bind PML_T_Edit->ForgetRemembered to Shift+space menu Forget Remembered Node

#bind GramArowToRemembered to Alt+space menu Make Grammatical Coreference Arrow to Remembered Node
#bind WhPathArrow to Alt+1 menu Make Wh-path Response Type Reference to Remembered Node
#bind BridgingArrow to Alt+2 menu Make Bridging Response Type Reference to Remembered Node
#bind OverrulesArrow to Alt+3 menu Make Overrules Response Type Reference to Remembered Node
#bind OtherArrow to Alt+4 menu Make Other Response Type Reference to Remembered Node

}

#endif TRED
