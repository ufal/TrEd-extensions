## This is macro file for Tred                             -*-cperl-*-
## It should be used for analytical trees editing
## author: Petr Pajas
## $Id$

#encoding iso-8859-2

package Analytic_Correction;

BEGIN { import Analytic; }



#bind TR_Correction->analytical_tree to Ctrl+A menu Display analytical tree (in a TR file)
#bind TR_Correction->tectogrammatical_tree to Ctrl+R menu Display tectogrammatical tree (in a TR file)
#bind TR_Correction->tectogrammatical_tree_store_AR to Ctrl+B menu Save ordorig of AR tree and display tectogrammatical tree

#bind TR_Correction->rehang_right to Ctrl+Shift+Right menu Rehang to right brother
#bind TR_Correction->rehang_left to Ctrl+Shift+Left menu Rehang to left brother
#bind TR_Correction->rehang_down to Ctrl+Shift+Down menu Rehang to first son
#bind TR_Correction->rehang_up to Ctrl+Shift+Up menu Rehang to parent


*file_close_hook = \&TR_Correction::file_close_hook;
*file_save_hook = \&TR_Correction::file_save_hook;



#bind edit_lemma_tag to Ctrl+T menu oprava lemmatu a tagu
sub edit_lemma_tag {
  ChangingFile(0);
  my $form = QueryString('Form:','Form:',$this->{form});
  return unless defined($form);
  $form =~ s/\\/\\\\/g;
  $form =~ s/'/\\'/g;
  $form = Encode::encode('iso-8859-2',$form) if ($]>=5.008);
  print STDERR "exec: morph '$form'\n";
  open my $fh,"morph '$form' |";
  binmode($fh,":encoding(iso-8859-2)") if ($]>=5.008);
  my $morph = join("",<$fh>);
  close($fh);
  print STDERR "$morph\n";
  my $lemma;
  my @morph = split /(<.*?>)/,$morph;
  my @val;
  my @sel;
  shift @morph;
  while (@morph) {
    my $tag   = shift @morph;
    my $value = shift @morph;
    chomp $value;
    if ($tag =~ /^<MMl/) {
      print STDERR "lemma: $value\n";
      $lemma = $value;
    } elsif ($tag =~ /^<MMt/) {
      print STDERR "tag: $value $lemma\n";
      push @val, "$value $lemma";
    } else {
      print STDERR "ignoring: $tag $value\n";
    }
  }
  @sel=grep { $_ eq "$this->{tag} $this->{lemma}" } @val;
  ListQuery("Select tag for $this->{form}",
	    'browse',
	    \@val,
	    \@sel) || do { ChangingFile(0); return };
  if (@sel) {
    ($this->{tag},$this->{lemma})=split " ",$sel[0],2;
    $this->{err1} = 'LEMMA_TAG_CHANGED';
    ChangingFile(1);
    return 1;
  }
  ChangingFile(0);
  return 0;
}

# permitting all attributes modification
sub enable_attr_hook {
  return;
}

#bind insert_node_to_pos to Alt+I

sub insert_node_to_pos {
  # get nodes
  # ask for ordinal number
  # splice given node to that position
  # reorder nodes
  my $value=main::QueryString($grp->{framegroup},"Enter new ord","ord","");
  return unless defined $value;
  my @nodes=GetNodes();
  splice @nodes,Index(\@nodes,$this),1;
  SortByOrd(\@nodes);
  splice @nodes,$value,0,$this;
  NormalizeOrds(\@nodes);
}

#bind sentord_to_ord to Alt+O

sub sentord_to_ord {
  my @nodes=GetNodes();
  foreach (@nodes) {
    $_->{ord}=$_->{sentord};
  }
  SortByOrd(\@nodes);
  NormalizeOrds(\@nodes);
}



#bind gotoNextFound to Alt+n
sub gotoNextFound {
  my $node;
  $FileNotSaved=0;
  $node=$this->following();
  do {
    while ($node and $$node{"err2"} ne "Found") {
      $node=$node->following();
      # print STDERR $$node{"form"},"\n";
    }
    $this=$node,return if ($node);
  } while (NextTree() and $node=$root);
}

#bind skipNextAuxK to Alt+k
sub skipNextAuxK {
  my $node;
  $node=$root->firstson;
  $node=$node->rbrother while ($node and $node->{afun} ne 'AuxK');
  $node=$node->rbrother if ($node);
  $this=$node if ($node);
}

#bind splitAfterNextAuxK to Alt+\
sub splitAfterNextAuxK {
  UnsetFound();
  skipNextAuxK();
  InsertSubtreeAsNewTreeAfter();
}


sub LastNode {
  my $node=$root;
  while ($node and $node->firstson) {
    $node=$node->firstson;
    $node=$node->rbrother while ($node->rbrother);
  }
  return $node;
  $FileNotSaved=0;
}

#bind gotoPrevFound to Alt+p
sub gotoPrevFound {
  my $node;
  $node=$this->previous();
  do {
    while ($node and $$node{"err2"} ne "Found") {
      $node=$node->previous();
      # print STDERR $$node{"form"},"\n";
    }
      $this=$node,return if ($node);
  } while (PrevTree() and ($node=LastNode()));
  $FileNotSaved=0;
}

#bind UnsetFound to minus
sub UnsetFound { $this->{'err2'}=''; }
#bind SetFound to plus
#bind SetFound to plus
sub SetFound { $this->{'err2'}='Found'; }

#bind SwapNodes to Ctrl+9
sub SwapNodes {
## Swaps the current node with the one above

  return unless ($this);
  my $parent=$this->parent;
  return unless ($parent);
  my $oldParent=$parent->parent;
  return unless ($oldParent);
  Cut($this);
  PasteNode($this,$oldParent);
  Cut($parent);
  PasteNode($parent,$this);
  $this=$parent;
}

#bind SwapNodesValues to Ctrl+Prior menu Swap nodes (values only)
sub SwapNodesValues {
## Swaps the current node with the one above
## (actually swaps only attribute all values)

  return unless ($this);
  my $parent=$this->parent;
  return unless ($parent);
  my @atord = @{ FSFormat->list() };
  my @parentAttrs=@{$parent}{@atord};
  @{$parent}{@atord}=@{$this}{@atord};
  @{$this}{@atord}=@parentAttrs;  
  $this=$parent;
}

#bind SwapNodesValuesButAfun to Ctrl+Shift+Prior menu Swap nodes (values only but afun)
sub SwapNodesValuesButAfun {
## Swaps the current node with the one above
## (actually swaps only attribute all values but the one of afun)

  return unless ($this);
  my $parent=$this->parent;
  return unless ($parent);

  my $oldparentAfun=$parent->{'afun'};
  my @atord = @{ FSFormat->list() };
  my @parentAttrs=@{$parent}{@atord};
  @{$parent}{@atord}=@{$this}{@atord};
  @{$this}{@atord}=@parentAttrs;
  $this->{'afun'}=$parent->{'afun'};
  $parent->{'afun'}=$oldparentAfun;
  $this=$parent;
}

#bind InsertSubtreeAsNewTreeAfter to \ menu Split Analytical Tree Here
sub InsertSubtreeAsNewTreeAfter {
# Inserts a new tree after the current tree and moves
# current subtree under its root.

  my $currTree=$this;
  my $br = $currTree->rbrother;
  my @brothers=();
  while ($br) {
    CutNode($br);
    PasteNode($br,$currTree);
    push @brothers, $br;
    $br=$currTree->rbrother;
  }

  NewTreeAfter();
  _key_Ctrl_5();
  PrevTree();
  $this=$currTree;
  _key_Ctrl_3();
  foreach $br (@brothers) {
    CutNode($br);
    PasteNode($br,$root);
  }
}

#bind ReDord to Alt+R menu Reorder

sub ReDord {
  my @nodes=GetNodes();
  SortByOrd(\@nodes);
  NormalizeOrds(\@nodes);
}

#bind ReorderStructure to Alt+S menu Reorder structure

sub ReorderStructure {
  ReDord();
#    my $node=$root;
#    while ($node) {
#      ReorderChildren($node);
#      $node=Next($node);
#    }
}

sub ReorderChildren {
  my $top=shift;
  my @childs=();
  my ($node,$i);

  return unless $top;
  $node=$top->firstson;
  while ($node) {
    push @childs,$node;
    $node=$node->rbrother;
  }

  foreach $node (@childs) {
    CutNode($node);
    PasteNode($node,$top);
  }
}



#bind thisToParent to Alt+u menu Hang current node up one level
sub thisToParent {
  return unless $this->parent and $this->parent->parent;
  my $act=$this;
  my $p=$act->parent->parent;
  CutPaste($act,$p);
  $this=$act;
}

#bind thisToRBrother to Alt+r menu Hang current node to RBrother
sub thisToRBrother {
  return unless $this->rbrother;
  my $act=$this;
  my $p=$this->rbrother;
  CutPaste($act,$p);
  $this=$act;
}

#bind thisToLBrother to Alt+l menu Hang current node to LBrother
sub thisToLBrother {
  return unless $this->lbrother;
  my $act=$this;
  my $p=$this->lbrother;
  CutPaste($act,$p);
  $this=$act;
}


#################### EJ

#bind SetCase1 to 1 menu Nominativ
#bind SetCase2 to 2 menu Genitiv
#bind SetCase3 to 3 menu Dativ
#bind SetCase4 to 4 menu Akuzativ
#bind SetCase5 to 5 menu Vokativ
#bind SetCase6 to 6 menu Lokal
#bind SetCase7 to 7 menu Instrumental

sub SetCase { 
  my $case=shift;
  $this->{tag}=~s/^(....).(.*)$/$1$case$2/g;
}

sub SetCase1 { SetCase(1); }
sub SetCase2 { SetCase(2); }
sub SetCase3 { SetCase(3); }
sub SetCase4 { SetCase(4); }
sub SetCase5 { SetCase(5); }
sub SetCase6 { SetCase(6); }
sub SetCase7 { SetCase(7); }

#bind SetNumS to G menu Singular
sub SetNumS {
  $this->{tag}=~s/^(...).(.*)$/$1S$2/g;
}
#bind SetNumP to L menu Plural
sub SetNumP {
  $this->{tag}=~s/^(...).(.*)$/$1P$2/g;
}

###################


{
# Automatically converted from Graph macros by graph2tred to Perl.
# =======================================================
my $iPrevAfunAssigned;		# used as type "string"
my $pPar1;			# used as type "pointer"
my $pPar2;			# used as type "pointer"
my $pPar3;			# used as type "pointer"
my $pReturn;			# used as type "pointer"
my $sPar1;			# used as type "string"
my $sPar2;			# used as type "string"
my $sPar3;			# used as type "string"
my $sReturn;			# used as type "string"
my $lPar1;			# used as type "list"
my $lPar2;			# used as type "list"
my $lPar3;			# used as type "list"
my $lReturn;			# used as type "list"
my $_pDummy;			# used as type "pointer"
# =======================================================

#bind _key_Shift_F6 to Shift+F6
sub _key_Shift_F6 {
  my $pAct;			# used as type "pointer"
  my $pNext;			# used as type "pointer"
  my $pParent;			# used as type "pointer"
  my $sT;			# used as type "string"
  my $fFound;			# used as type "string"
  my $pActG1;			# used as type "pointer"
  my $pActG2;			# used as type "pointer"
  my $pActG3;			# used as type "pointer"
  my $pActG4;			# used as type "pointer"

  $fFound = "0";

  $pParent = $this;

  $pAct = $pParent;

  if (!($pAct)) {

    return;
  }
 F6ContLoop1:
  $pAct->{'gap2'} = 'I was here.';

  if (Interjection($pAct->{'afun'},'Atr') eq 'Atr') {

    $pAct->{'gap2'} = 'I was here and I am Atr.';

    $pActG1 = $pAct->parent;

    if (!($pActG1)) {

      goto F6NF;
    }

    if (Interjection($pActG1->{'afun'},'AuxP') eq 'AuxP') {

      $pActG1->{'gap2'} = 'I was here and I am AuxP and down there is an Atr.';

      $pActG2 = $pActG1->parent;

      if (!($pActG2)) {

	goto F6NF;
      }

      $pActG3 = $pActG2->parent;

      if (!($pActG3)) {

	goto F6NF;
      }

      $sT = substr(ValNo(0,$pActG3->{'tag'}),0,1);

      $pActG3->{'gap1'} = $sT;

      if ($sT eq 'V') {

	$pAct->{'gap3'} = $sT;

	$pActG2->{'err1'} = 'HERE!';

	$fFound = "1";
      }
    }
  }
 F6NF:
  $pNext = $pAct->firstson;

  if (!($pNext)) {

    $pNext = $pAct->rbrother;
  }
 F6ContLoop2:
  if ($pNext) {

    goto F6ExitLoop2;
  }

  $pAct = $pAct->parent;

  if (ValNo(0,$pAct->{'ord'})==ValNo(0,$pParent->{'ord'})) {

    goto F6ExitLoop1;
  }

  $pNext = $pAct->rbrother;

  goto F6ContLoop2;
 F6ExitLoop2:
  $pAct = $pNext;

  goto F6ContLoop1;
 F6ExitLoop1:
  return;

}


#bind _key_Ctrl_Shift_F7 to Ctrl+Shift+F7
sub _key_Ctrl_Shift_F7 {
  my $pAct;			# used as type "pointer"
  my $pParent;			# used as type "pointer"

  $pAct = $this;

  if (!($pAct)) {

    return;
  }
 CSF10ContLoop:
  $pParent = $pAct->parent;

  if (!($pParent)) {

    if (Interjection($pAct->{'err2'},'defective') eq 'defective') {

      $pAct->{'err2'} = '';
    }

    $pAct->{'afun'} = '---';

    return;
  } else {

    $pAct = $pParent;

    goto CSF10ContLoop;
  }


}


sub GoNext {
  my $pAct;			# used as type "pointer"

  $pAct = $pPar1;

  if ($pAct->firstson) {

    $pReturn = $pAct->firstson;

    return;
  }
 loopGoNext:
  if ($pAct eq $pPar2 ||
      !($pAct->parent)) {

    $pReturn = undef;

    return;
  }

  if ($pAct->rbrother) {

    $pReturn = $pAct->rbrother;

    return;
  }

  $pAct = $pAct->parent;

  goto loopGoNext;

}


sub GoPrev {
  my $pAct;			# used as type "pointer"

  $pAct = $pPar1;

  if ($pAct->lbrother) {

    $pAct = $pAct->lbrother;

    if ($pAct->firstson) {
    loopDigDown:
      $pAct = $pAct->firstson;
    loopLastBrother:
      if ($pAct->rbrother) {

	$pAct = $pAct->rbrother;

	goto loopLastBrother;
      }

      if ($pAct->firstson) {

	goto loopDigDown;
      }

      $pReturn = $pAct;

      return;
    }

    $pReturn = $pAct;

    return;
  }

  if ($pAct eq $pPar2 ||
      !($pAct->parent)) {

    $pReturn = undef;

    return;
  }

  $pReturn = $pAct->parent;

  return;

}


#bind _key_Shift_Tab to Shift+Tab
sub _key_Shift_Tab {

  $pPar1 = $this;

  $pPar2 = undef;

  GoPrev();

  $this = $pReturn;

}


#bind _key_Tab to Tab
sub _key_Tab {

  $pPar1 = $this;

  $pPar2 = undef;

  GoNext();

  $this = $pReturn;

}


sub SearchSonsErr1 {
  my $pToSearch;		# used as type "pointer"

  $pToSearch = $pPar1->firstson;
 loopSSErr1:
  if ($pToSearch &&
      Interjection($pToSearch->{'err1'},$sPar1) ne $sPar1) {

    $pToSearch = $pToSearch->rbrother;

    goto loopSSErr1;
  }

  $pReturn = $pToSearch;

}


#  #xxxbind _key_Ctrl_9 to Ctrl+9
#  sub _key_Ctrl_9 {
#    my $pAct;			# used as type "pointer"
#    my $pParent;			# used as type "pointer"
#    my $pOldParent;		# used as type "pointer"
#    my $sActErr;			# used as type "string"

#    $pAct = $this;

#    if (!($pAct)) {

#      return;
#    }

#    $pParent = $pAct->parent;

#    if (!($pParent)) {

#      return;
#    }

#    $pOldParent = $pParent->parent;

#    if (!($pOldParent)) {

#      return;
#    }

#    $sActErr = ValNo(0,$pAct->{'err1'});

#    $pAct->{'err1'} = 'Go_Here';

#    $NodeClipboard=CutNode($pAct);

#    $_pDummy = PasteNode($NodeClipboard,$pOldParent);

#    $NodeClipboard=CutNode($pParent);

#    $sPar1 = 'Go_Here';

#    $pPar1 = $pOldParent;

#    SearchSonsErr1();

#    $pAct = $pReturn;

#    $_pDummy = PasteNode($NodeClipboard,$pAct);

#    $pAct->{'err1'} = $sActErr;

#  }


sub RSearchB {
  my $pAct;			# used as type "pointer"
  my $pTop;			# used as type "pointer"
  my $funcToRun=shift;

  $pAct = $pPar1;

  $pTop = $pPar2;
 loopRSB:
  $pPar1 = $pAct;

  &$funcToRun();                # function to run: Added after conversion

  $pPar1 = $pAct;

  $pPar2 = $pTop;

  GoNext();

  $pAct = $pReturn;

  if ($pAct) {

    goto loopRSB;
  }

}


sub BatchSearch {
  my $pStart;			# used as type "pointer"
  my $funcToRun=shift;          # function to run: Added after conversion
 loopBSearch:
  $pPar1 = $this;

  $pPar2 = $this;

  RSearchB($funcToRun);         # parametr added after conversion

  NextTree();

  if ($_NoSuchTree ne "1") {

    goto loopBSearch;
  }

}


sub SearchErr1 {
  my $pAct;			# used as type "pointer"

  $pAct = $pPar1;
 loopRSErr:
  if (Interjection($pAct->{'err1'},$sPar1) eq $sPar1) {

    $pReturn = $pAct;

    return;
  }

  $pPar1 = $pAct;

  GoNext();

  $pAct = $pReturn;

  if ($pAct) {

    goto loopRSErr;
  }

}


sub TestFileNames {
  my $FILE;			# used as type "string"

  ThisRoot();

  $this = $pReturn;

  if ($FILE eq '') {

    $FILE = ValNo(0,$this->{'mstag'});
  }
 loopTFN:
  if (Interjection($this->{'mstag'},$FILE) ne $FILE) {

    $this->{'err1'} = 'File-name-does-not-match';
  } else {

    $this->{'err1'} = '';
  }


  NextTree();

  if ($_NoSuchTree eq "1") {

    return;
  }

  goto loopTFN;

}


sub TestRoot {
 loopTestRoot:
  ThisRoot();

  $this = $pReturn;

  if (Interjection($this->{'lemma'},'#') ne '#' ||
      ( Interjection($this->{'afun'},'---') ne '---' &&
	Interjection($this->{'afun'},'AuxS') ne 'AuxS' )) {

    $this->{'err1'} = 'Root-not-AuxS';
  } else {

    $this->{'err1'} = '';
  }


  NextTree();

  if ($_NoSuchTree eq "1") {

    return;
  }

  goto loopTestRoot;

}


sub MakeRootsAuxS {
 loopTestRoot:
  ThisRoot();

  $this = $pReturn;

  if (Interjection($this->{'lemma'},'#') ne '#' ||
      ( Interjection($this->{'afun'},'---') eq '---' &&
	$this->firstson ) ||
      ( Interjection($this->{'afun'},'---') ne '---' &&
	Interjection($this->{'afun'},'AuxS') ne 'AuxS' )) {

    $this->{'err2'} = 'Found';
  } else {

    $this->{'afun'} = 'AuxS';
  }


  NextTree();

  if ($_NoSuchTree eq "1") {

    return;
  }

  goto loopTestRoot;

}


sub RootsToHajic {
  my $aux;			# used as type "string"

  ThisRoot();

  $this = $pReturn;
 loop:
  if (substr(ValNo(0,$this->{'form'}),2,1) eq ' ') {

    $this->{'form'} =
      (ValNo(0,substr(ValNo(0,$this->{'form'}),0,2)).
       ValNo(0,substr(ValNo(0,$this->{'form'}),3,2)));
  }

  $sPar1 = ValNo(0,$this->{'lemid'});

  $sPar2 = ' ';

  StrPos();

  if ($sReturn!="-1") {

    $aux = $sReturn+"1";

    $this->{'lemid'} = 
      (ValNo(0,substr(ValNo(0,$this->{'lemid'}),0,$sReturn)).
       ValNo(0,substr(ValNo(0,$this->{'lemid'}),$aux,2)));
  }

  NextTree();

  if ($_NoSuchTree eq "1") {

    return;
  }

  goto loop;

}


sub MaxOrd {
  my $pAct;			# used as type "pointer"

  $sReturn = "0";

  $pAct = $pPar1;

  $pPar2 = $pPar1;
 loop:
  if ($sReturn<ValNo(0,$pAct->{'ord'})) {

    $sReturn = ValNo(0,$pAct->{'ord'});
  }

  $pPar1 = $pAct;

  GoNext();

  $pAct = $pReturn;

  if ($pAct) {

    goto loop;
  }

}


sub MinOrd {
  my $pAct;			# used as type "pointer"

  $pAct = $pPar1;

  $pPar2 = $pPar1;

  $sReturn = ValNo(0,$pAct->{'ord'});
 loop:
  if ($sReturn>ValNo(0,$pAct->{'ord'})) {

    $sReturn = ValNo(0,$pAct->{'ord'});
  }

  $pPar1 = $pAct;

  GoNext();

  $pAct = $pReturn;

  if ($pAct) {

    goto loop;
  }

}


sub AdvanceOrd {
  my $pAct;			# used as type "pointer"

  $pAct = $pPar1;

  $pPar2 = $pPar1;
 loop:
  $pAct->{'ord'} = ValNo(0,$pAct->{'ord'})+$sPar1;

  $pPar1 = $pAct;

  GoNext();

  $pAct = $pReturn;

  if ($pAct) {

    goto loop;
  }

}


sub MoveTree {
  my $pAct;			# used as type "pointer"
 loopMoveTree:
  ThisRoot();

  $pAct = $pReturn;

  if ($pAct->firstson) {

    $NodeClipboard=CutNode($pAct->firstson);

    PrevTree();

    ThisRoot();

    $_pDummy = PasteNode($NodeClipboard,$pReturn);

    NextTree();

    goto loopMoveTree;
  }

  $pAct->{'ord'} = "0";

  return;

}


#bind _key_Ctrl_4 to Ctrl+4
sub _key_Ctrl_4 {
  my $Ord;			# used as type "string"
  my $pThere;			# used as type "pointer"

  ThisRoot();

  $pPar1 = $pReturn;

  MaxOrd();

  $Ord = $sReturn;

  NextTree();

  if ($_NoSuchTree eq "1") {

    return;
  }

  $sPar1 = $Ord;

  $pPar1 = $this;

  AdvanceOrd();

  MoveTree();

  PrevTree();

}


#bind _key_Ctrl_2 to Ctrl+2
sub _key_Ctrl_2 {
  my $OrdMin;			# used as type "string"
  my $OrdMax;			# used as type "string"
  my $pAct;			# used as type "pointer"

  if (!($this->parent)) {

    PrevTree();

    _key_Ctrl_4();

    return;
  }

  $this->{'err1'} = 'NewHere';

  $pPar1 = $this;

  MaxOrd();

  $OrdMax = $sReturn;

  $NodeClipboard=CutNode($this);

  ThisRoot();

  $pReturn->{'ord'} = $OrdMax;

  $pPar1 = $pReturn;

  $sPar1 = "0"-$OrdMax;

  AdvanceOrd();

  PrevTree();

  $pPar1 = $this;

  MaxOrd();

  $OrdMax = $sReturn;

  $_pDummy = PasteNode($NodeClipboard,$this);

  ThisRoot();

  $pPar1 = $pReturn;

  $sPar1 = 'NewHere';

  SearchSonsErr1();

  $pAct = $pReturn;

  $pAct->{'err1'} = '';

  $pPar1 = $pAct;

  $sPar1 = $OrdMax;

  AdvanceOrd();

  $NodeClipboard=CutNode($pAct);

  ThisRoot();

  $_pDummy = PasteNode($NodeClipboard,$pReturn);

}


#bind _key_Ctrl_3 to Ctrl+3
sub _key_Ctrl_3 {
  my $OrdMax;			# used as type "string"
  my $OrdMin;			# used as type "string"

  if (!($this->parent)) {

    _key_Ctrl_4();

    return;
  }

  $pPar1 = $this;

  MinOrd();

  $OrdMin = $sReturn;

  $pPar1 = $this;

  $sPar1 = "1"-$OrdMin;

  AdvanceOrd();

  $pPar1 = $this;

  MaxOrd();

  $OrdMax = $sReturn;

  $NodeClipboard=CutNode($this);

  NextTree();

  $pPar1 = $this;

  $sPar1 = $OrdMax;

  AdvanceOrd();

  $this->{'ord'} = "0";

  $_pDummy = PasteNode($NodeClipboard,$this);

}


sub TestTreeOrder {
  my $i;			# used as type "string"
  my $j;			# used as type "string"
  my $suf;			# used as type "string"
  my $Alph;			# used as type "string"
  my $num;			# used as type "string"

  $Alph = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  $i = "0";

  $j = "0";

  $suf = '';

  ThisRoot();

  $this = $pReturn;
 loopTTOrder:
  if (substr(ValNo(0,$this->{'form'}),0,1) ne '#') {

    goto writeerr;
  }

  $this->{'err1'} = '';

  if (substr(ValNo(0,$this->{'form'}),2,1) eq ' ') {

    $num = substr(ValNo(0,$this->{'form'}),1,2);

    $suf = substr(ValNo(0,$this->{'form'}),3,2);
  } else {

    $num = substr(ValNo(0,$this->{'form'}),1,2);

    $suf = substr(ValNo(0,$this->{'form'}),2,1);

    if ($suf eq "0" ||
	$suf eq "1" ||
	$suf eq "2" ||
	$suf eq "3" ||
	$suf eq "4" ||
	$suf eq "5" ||
	$suf eq "6" ||
	$suf eq "7" ||
	$suf eq "8" ||
	$suf eq "9") {

      $suf = substr(ValNo(0,$this->{'form'}),3,2);
    }
  }


  if ($j!="1" &&
      $suf eq '' &&
      $num==$i+"1") {

    $i = $i+"1";

    $j = "0";

    goto cont;
  }

  if ($j!="1" &&
      $suf eq 'A' &&
      $num==$i+"1") {

    $i = $i+"1";

    $j = "1";

    goto cont;
  }

  if ($j!="0" &&
      $suf eq substr($Alph,$j,1) &&
      $num==$i) {

    $j = $j+"1";

    goto cont;
  }
 writeerr:
  $this->{'err1'} = 'Root-number-doesnot-match';

  if (substr(ValNo(0,$this->{'form'}),0,1) eq '#') {

    $j = "0";

    $i = substr(ValNo(0,$this->{'form'}),1,2);
  }
 cont:
  NextTree();

  if ($_NoSuchTree eq "0") {

    goto loopTTOrder;
  }

}


sub ClearUselessAttributes {

  $pPar1->{'origap'} = '';

  $pPar1->{'gap1'} = '';

  $pPar1->{'gap2'} = '';

  $pPar1->{'gap3'} = '';

  $pPar1->{'afunman'} = '';

  $pPar1->{'afunprev'} = '';

  $pPar1->{'tagall'} = '';

  $pPar1->{'lemmaall'} = '';

  $pPar1->{'warning'} = '';

  $pPar1->{'err1'} = '';

  $pPar1->{'err2'} = '';

  $pPar1->{'reserve1'} = '';

  $pPar1->{'reserve2'} = '';

  $pPar1->{'reserve3'} = '';

  $pPar1->{'reserve4'} = '';

  $pPar1->{'reserve5'} = '';

}


#bind _key_Ctrl_5 to Ctrl+5
sub _key_Ctrl_5 {
  my $oform;			# used as type "string"
  my $olemid;			# used as type "string"
  my $omstag;			# used as type "string"
  my $oorigf;			# used as type "string"
  my $aux;			# used as type "string"

  PrevTree();

  if ($_NoSuchTree eq "1") {

    return;
  }

  $oform = ValNo(0,$this->{'form'});

  $olemid = ValNo(0,$this->{'lemid'});

  $omstag = ValNo(0,$this->{'mstag'});

  $oorigf = ValNo(0,$this->{'origf'});

  NextTree();

  $pPar1 = $this;

  ClearUselessAttributes();

  $this->{'lemma'} = '#';

  $this->{'tag'} = 'ZSB';

  $this->{'afun'} = 'AuxS';

  $this->{'ord'} = "0";

  my $letter='A';
  $letter=$1 if ($oform =~ /([A-Z])/);
  $letter++;
  if (substr($oform,2,1) eq '') {

    $this->{'form'} = ($oform." $letter");
  } else {

    $this->{'form'} = (substr($oform,0,3).$letter);
  }


  $this->{'lemid'} = $olemid;

  $this->{'mstag'} = $omstag;

  $this->{'origf'} = $oorigf;

}


#bind _key_Ctrl_6 to Ctrl+6
sub _key_Ctrl_6 {

  if (Interjection($this->{'lemma'},'#') eq '#') {

    $this->{'origap'} = '';
  } else {

    $this->{'mstag'} = '-';
  }


  $this->{'err2'} = '';

  $this->{'err1'} = '';

}


sub ShiftRootSign {
  my $aux;			# used as type "string"
 loopShiftRootSign:
  $aux = substr(ValNo(0,$this->{'form'}),2,1);

  if ($aux eq 'B' ||
      $aux eq 'C' ||
      $aux eq 'D' ||
      $aux eq 'E' ||
      $aux eq 'F') {

    $aux = (ValNo(0,' ').ValNo(0,$aux));

    $this->{'form'} = (ValNo(0,substr(ValNo(0,$this->{'form'}),0,2)).ValNo(0,$aux));
  }

  NextTree();

  if ($_NoSuchTree ne "1") {

    goto loopShiftRootSign;
  }

}


sub RepairRootNumbers {
  my $aux;			# used as type "string"
  my $test;			# used as type "string"

  $test = "0";
 loopRRNum:
  if (substr(ValNo(0,$this->{'form'}),3,1) eq 'A') {

    $test = "1";
  }

  if (substr(ValNo(0,$this->{'form'}),3,1) eq 'B' &&
      $test eq "0") {

    PrevTree();

    if (substr(ValNo(0,$this->{'form'}),2,1) eq '') {

      $this->{'form'} = (ValNo(0,$this->{'form'}).' A');

      $this->{'lemid'} = (ValNo(0,$this->{'lemid'}).' A');
    } else {

      if (substr(ValNo(0,$this->{'form'}),2,1) ne 'A' &&
	  substr(ValNo(0,$this->{'form'}),3,1) ne 'A') {

	$this->{'form'} = (ValNo(0,$this->{'form'}).'A');

	$this->{'lemid'} = (ValNo(0,$this->{'lemid'}).' A');
      }
    }


    NextTree();
  }

  $aux = substr(ValNo(0,$this->{'form'}),3,1);

  if ($aux eq 'B' ||
      $aux eq 'C' ||
      $aux eq 'D' ||
      $aux eq 'E' ||
      $aux eq 'F' ||
      $aux eq 'G' ||
      $aux eq 'H' ||
      $aux eq 'I' ||
      $aux eq 'J' ||
      $aux eq 'K' ||
      $aux eq 'L') {

    if ($test eq "0") {

      $aux = (ValNo(0,' ').ValNo(0,$aux));

      $this->{'lemid'} = (ValNo(0,$this->{'lemid'}).$aux);
    }
  } else {

    if (substr(ValNo(0,$this->{'form'}),3,1) ne 'A') {

      $test = "0";
    }
  }


  NextTree();

  if ($_NoSuchTree ne "1") {

    goto loopRRNum;
  }

}


sub TestOrdConsistance {
  my $Max;			# used as type "string"
  my $i;			# used as type "string"
  my $j;			# used as type "string"
  my $pAct;			# used as type "pointer"
  my $pRoot;			# used as type "pointer"
 ForAllTrees:
  $pRoot = $this;

  $pPar1 = $this;

  MaxOrd();

  $Max = $sReturn;

  $i = "0";
 ForAllOrds:
  $j = "0";

  $pAct = $pRoot;
 ForAllNodes:
  if (Interjection($pAct->{'ord'},$i) eq $i) {

    $j = $j+"1";
  }

  if ($j>"1") {

    $pRoot->{'err1'} = 'Ord-Inconsistance';

    $pRoot->{'warning'} = (ValNo(0,$pRoot->{'warning'}).'+');

    $pRoot->{'warning'} = (ValNo(0,$pRoot->{'warning'}).$i);

    $pRoot->{'warning'} = (ValNo(0,$pRoot->{'warning'}).'  ');
  } else {

    $pPar1 = $pAct;

    $pPar2 = undef;

    GoNext();

    $pAct = $pReturn;

    if ($pAct) {

      goto ForAllNodes;
    }

    if ($j=="0") {

      $pRoot->{'err1'} = 'Ord-Inconsistance';

      $pRoot->{'warning'} = (ValNo(0,$pRoot->{'warning'}).'-');

      $pRoot->{'warning'} = (ValNo(0,$pRoot->{'warning'}).$i);

      $pRoot->{'warning'} = (ValNo(0,$pRoot->{'warning'}).'  ');
    }
  }


  if ($i<$Max) {

    $i = $i+"1";

    goto ForAllOrds;
  }

  NextTree();

  if ($_NoSuchTree ne "1") {

    goto ForAllTrees;
  }

}


sub RepairRootZeros {
 loopRRZero:
  if (Interjection($this->{'ord'},"0") ne "0" &&
      !($this->firstson)) {

    $this->{'err1'} = '';

    $this->{'warning'} = '';
  }

  NextTree();

  if ($_NoSuchTree ne "1") {

    goto loopRRZero;
  }

}


sub TestAuxKLast {
  my $pAct;			# used as type "pointer"
  my $AuxKFound;		# used as type "string"
 loopTree:
  $pAct = $this;

  $AuxKFound = "0";
 loopNode:
  if (Interjection($pAct->{'afun'},'AuxK') eq 'AuxK') {

    $AuxKFound = "1";
  } else {

    if ($AuxKFound eq "1") {

      $pAct->{'err2'} = 'Found';

      $AuxKFound = "0";
    }
  }


  $pPar1 = $pAct;

  $pPar2 = undef;

  GoNext();

  $pAct = $pReturn;

  if ($pAct) {

    goto loopNode;
  }

  NextTree();

  if ($_NoSuchTree ne "1") {

    goto loopTree;
  }

}


sub ShiftOrds {
  my $pAct;			# used as type "pointer"

  ThisRoot();

  $pAct = $pReturn;

  $pPar2 = undef;
 loopShiftOrd:
  if (ValNo(0,$pAct->{'ord'})>$sPar1) {

    $pAct->{'ord'} = ValNo(0,$pAct->{'ord'})+$sPar2;
  }

  $pPar1 = $pAct;

  GoNext();

  $pAct = $pReturn;

  if ($pAct) {

    goto loopShiftOrd;
  }

}


sub CreateNode {
  my $pAct;			# used as type "pointer"
  my $pNew;			# used as type "pointer"

  $pAct = $pPar1;

  $sPar1 = ValNo(0,$pAct->{'ord'});

  $sPar2 = "1";

  ShiftOrds();

  $pNew =   PlainNewSon($pAct);

  $pNew->{'ord'} = ValNo(0,$pAct->{'ord'})+"1";

  $NodeClipboard=CutNode($pNew);

  $pPar1 = PasteNode($NodeClipboard,$pAct);

  ClearUselessAttributes();

  $pReturn = $pPar1;

}


#bind _key_Ctrl_Shift_9 to Ctrl+parenleft menu Create an identical copy of the current node
sub _key_Ctrl_Shift_9 {
  my $pAct;			# used as type "pointer"
  my $pNew;			# used as type "pointer"

  $pPar1 = $this;

  $pAct = $this;

  CreateNode();

  $pNew = $pReturn;

  $pNew->{'lemma'} = $pAct->{'lemma'};

  $pNew->{'tag'} = $pAct->{'tag'};

  $pNew->{'form'} = $pAct->{'form'};

  $pNew->{'afun'} = $pAct->{'afun'};

  $pNew->{'lemid'} = $pAct->{'lemid'};

  $pNew->{'mstag'} = $pAct->{'mstag'};

  $pNew->{'origf'} = $pAct->{'origf'};

  $pNew->{'origap'} = $pAct->{'origap'};

  $pNew->{'reserve1'} = (ValNo(0,$pNew->{'reserve1'}).'A;');

  $pAct->{'reserve1'} = (ValNo(0,$pAct->{'reserve1'}).'S;');

  $this = $pNew;

}


#bind _key_Ctrl_Shift_Space to Ctrl+Shift+Space menu Split current node on a dot
sub _key_Ctrl_Shift_Space {
  my $pAct;			# used as type "pointer"
  my $pNum;			# used as type "pointer"
  my $pDot;			# used as type "pointer"
  my $sPos;			# used as type "string"
  my $sLen;			# used as type "string"

  $pAct = $this;

  $sPar2 = '.';

  $sPar1 = ValNo(0,$pAct->{'form'});

  StrPos();

  if ($sReturn=="-1") {

    return;
  }

  $sPos = $sReturn;

  $sPar1 = ValNo(0,$pAct->{'form'});

  StrLen();

  $sLen = $sReturn;

  $pPar1 = $pAct;

  CreateNode();

  $pNum = $pReturn;

  $pNum->{'lemma'} = substr(ValNo(0,$pAct->{'form'}),$sPos+1,$sLen-$sPos-1);

  $pAct->{'lemma'} = substr(ValNo(0,$pAct->{'form'}),0,$sPos);

  $pNum->{'tag'} = $pAct->{'tag'};

  $pNum->{'form'} = $pNum->{'lemma'};

  $pAct->{'form'} = $pAct->{'lemma'};

  $pNum->{'afun'} = 'Atr';

  $pNum->{'lemid'} = '-';

  $pNum->{'mstag'} = '-';

  $pNum->{'origf'} = $pAct->{'origf'};

  $pNum->{'origap'} = '-';

  $pNum->{'reserve1'} = (ValNo(0,$pNum->{'reserve1'}).'A;');

  $pAct->{'reserve1'} = (ValNo(0,$pAct->{'reserve1'}).'S;');

  $pPar1 = $pAct;

  CreateNode();

  $pDot = $pReturn;

  $pDot->{'lemma'} = '.';

  $pDot->{'tag'} = 'ZIP';

  $pDot->{'form'} = '.';

  $pDot->{'lemid'} = '-';

  $pDot->{'mstag'} = '-';

  $pDot->{'afun'} = 'AuxG';

  $pDot->{'origf'} = $pAct->{'origf'};

  $pDot->{'origap'} = '';

  $pDot->{'reserve1'} = (ValNo(0,$pNum->{'reserve1'}).'A;');

  $pAct->{'reserve1'} = (ValNo(0,$pAct->{'reserve1'}).'S;');

}


#bind _key_Ctrl_Shift_8 to Ctrl+asterisk
sub _key_Ctrl_Shift_8 {
  my $pAct;			# used as type "pointer"
  my $pParent;			# used as type "pointer"

  $pAct = $this;

  $pParent = $this->parent;

  if (!($pParent)) {

    return;
  }

  if (ValNo(0,$pAct->{'ord'})!=ValNo(0,$pParent->{'ord'})+"1") {

    return;
  }

  $pParent->{'form'} = (ValNo(0,$pParent->{'form'}).ValNo(0,$pAct->{'form'}));

  $pParent->{'reserve1'} = (ValNo(0,$pParent->{'reserve1'}).'J;');
 moveSubTrees:
  if ($pAct->firstson) {

    $NodeClipboard=CutNode($pAct->firstson);

    $_pDummy = PasteNode($NodeClipboard,$pParent);

    goto moveSubTrees;
  }

  $sPar1 = ValNo(0,$pAct->{'ord'});

  $NodeClipboard=CutNode($pAct);

  $sPar2 = "-1";

  ShiftOrds();

}


#bind _key_Ctrl_Shift_7 to Ctrl+ampersand
sub _key_Ctrl_Shift_7 {

  $this->{'afun'} = '---';

  $this->{'err1'} = 'vyhodit';

}


#bind _key_Ctrl_Shift_6 to Ctrl+asciicircum menu Generate a new comma node
sub _key_Ctrl_Shift_6 {
  my $pNew;			# used as type "pointer"

  $pPar1 = $this;

  CreateNode();

  $pNew = $pReturn;

  $pNew->{'lemma'} = ',';

  $pNew->{'tag'} = 'ZIP';

  $pNew->{'form'} = ',';

  $pNew->{'afun'} = 'AuxX';

  $pNew->{'lemid'} = '-';

  $pNew->{'mstag'} = '-';

  $pNew->{'origf'} = '';

  $pNew->{'origap'} = '';

  $pNew->{'reserve1'} = 'N;';

  $pNew->{'gap1'} = '<D>&nl;<d>';

  $this = $pNew;

}


#bind _key_Ctrl_Shift_5 to Ctrl+percent
sub _key_Ctrl_Shift_5 {
  my $i;			# used as type "string"
  my $j;			# used as type "string"
  my $aux;			# used as type "string"

  if (substr(ValNo(0,$this->{'form'}),0,1) eq 'l') {

    $this->{'form'} = (ValNo(0,"1").ValNo(0,substr(ValNo(0,$this->{'form'}),1,30)));

    $this->{'lemma'} = $this->{'form'};
  }

  $i = "0";
 loopCS5:
  if (substr(ValNo(0,$this->{'form'}),$i,1) ne '') {

    if (substr(ValNo(0,$this->{'form'}),$i,1) eq 'O') {

      $aux = (ValNo(0,substr(ValNo(0,$this->{'form'}),0,$i)).ValNo(0,"0"));

      $i = $i+"1";

      $this->{'form'} = (ValNo(0,$aux).ValNo(0,substr(ValNo(0,$this->{'form'}),$i,30)));
    } else {

      $i = $i+"1";
    }


    goto loopCS5;
  }

  $this->{'tag'} = 'ZNUM';

  $this->{'origap'} = '';

  $this->{'gap1'} = '<f num>';

}


#bind _key_Ctrl_Shift_4 to Ctrl+dollar
sub _key_Ctrl_Shift_4 {
  my $pAct;			# used as type "pointer"
  my $pParent;			# used as type "pointer"

  $pAct = $this;

  $pParent = $this->parent;

  if (!($pParent)) {

    return;
  }
 moveSubTrees:
  if ($pAct->firstson) {

    $NodeClipboard=CutNode($pAct->firstson);

    $_pDummy = PasteNode($NodeClipboard,$pParent);

    goto moveSubTrees;
  }

  $sPar1 = ValNo(0,$pAct->{'ord'});

  $NodeClipboard=CutNode($pAct);

  $sPar2 = "-1";

  ShiftOrds();

}


sub MarkAtv {
  my $i;			# used as type "string"
  my $test;			# used as type "string"
  my $tagnum;			# used as type "string"
  my $tags;			# used as type "list"

  $pPar1->{'err2'} = '';

  if (Interjection($pPar1->{'afun'},'Atv') eq 'Atv') {

    $tags = $pPar1->parent->{'tag'};

    $tagnum = do{{ my @split = split /\|/,$tags; 0+@split }};

    $i = "0";
  forallATVtags:
    if (substr( ValNo($i,$tags) ,0,1) eq 'V') {

      $pPar1->{'err2'} = 'Found';
    } else {

      $i = $i+"1";

      if ($i<$tagnum) {

	goto forallATVtags;
      }
    }

  } else {

    if (Interjection($pPar1->{'afun'},'AtvV') eq 'AtvV') {

      $tags = $pPar1->parent->{'tag'};

      $tagnum = do{{ my @split=split /\|/,$tags; 0+@split }};

      $i = "0";
    forallATVVtags:
      if (substr( ValNo($i,$tags) ,0,1) ne 'V') {

	$i = $i+"1";

	if ($i<$tagnum) {

	  goto forallATVVtags;
	}
      }

      if ($i>=$tagnum) {

	$pPar1->{'err2'} = 'Found';
      }
    }
  }


}


#bind _key_Ctrl_Shift_3 to Ctrl+numbersign
sub _key_Ctrl_Shift_3 {
  my $pAct;			# used as type "pointer"
  my $pThis;			# used as type "pointer"

  if (!($this->parent)) {
  forallrootsons:
    $pAct = $this->firstson;

    if ($pAct) {

      $NodeClipboard=CutNode($pAct);

      goto forallrootsons;
    }

    $this->{'reserve1'} = (ValNo(0,$this->{'reserve1'}).'R;');
  } else {

    $pThis = $this;
  forallthissons:
    $pAct = $pThis->firstson;

    if ($pAct) {
    moveSubTrees:
      if ($pAct->firstson) {

	$NodeClipboard=CutNode($pAct->firstson);

	$_pDummy = PasteNode($NodeClipboard,$pThis);

	goto moveSubTrees;
      }

      $sPar1 = ValNo(0,$pAct->{'ord'});

      $NodeClipboard=CutNode($pAct);

      $sPar2 = "-1";

      ShiftOrds();

      goto forallthissons;
    }

    $pThis->parent->{'reserve1'} = (ValNo(0,$pThis->parent->{'reserve1'}).'R;');

    $sPar1 = ValNo(0,$pThis->{'ord'});

    $NodeClipboard=CutNode($pThis);

    $sPar2 = "-1";

    ShiftOrds();
  }


}


sub MarkPnomObj {
  my $i;			# used as type "string"
  my $test;			# used as type "string"
  my $lemnum;			# used as type "string"
  my $lemmas;			# used as type "list"

  $pPar1->{'err2'} = '';

  if (Interjection($pPar1->{'afun'},'Obj') eq 'Obj') {

    $lemmas = $pPar1->parent->{'lemma'};

    $lemnum = do {{ my @split = split /\|/,$lemmas; 0+@split }};

    $i = "0";
  forallLemmas:
    if ( ValNo($i,$lemmas)  eq 'b�t') {

      $pPar1->{'err2'} = 'Found';
    } else {

      $i = $i+"1";

      if ($i<$lemnum) {

	goto forallLemmas;
      }
    }

  } else {

    if (Interjection($pPar1->{'afun'},'Pnom') eq 'Pnom') {

      $lemmas = $pPar1->parent->{'lemma'};

      $lemnum = do{{ my @split = split /\|/,$lemmas; 0+@split }};

      $i = "0";
    everyLemma:
      if ( ValNo($i,$lemmas)  ne 'b�t') {

	$i = $i+"1";

	if ($i<$lemnum) {

	  goto everyLemma;
	}
      }

      if ($i>=$lemnum) {

	$pPar1->{'err2'} = 'Found';
      }
    }
  }


}


sub StrLen {
  my $i;			# used as type "string"

  $i = "0";
 trysizeofi:
  if ($sPar1 ne substr($sPar1,0,$i)) {

    $i = $i+"1";

    goto trysizeofi;
  }

  $sReturn = $i;

}


sub StrPos {
  my $i;			# used as type "string"
  my $s;			# used as type "string"
  my $len;			# used as type "string"

  $i = "0";

  $s = $sPar1;

  $sPar1 = $sPar2;

  StrLen();

  $len = $sReturn;
 forallpos:
  if (substr($s,$i,$len) ne $sPar2 &&
      substr($s,$i,$len) ne '') {

    $i = $i+"1";

    goto forallpos;
  }

  if (substr($s,$i,$len) ne $sPar2) {

    $sReturn = "-1";
  } else {

    $sReturn = $i;
  }


}


sub MarkWrongAfunPosition {
  my $pAct;			# used as type "pointer"
  my $pOld;			# used as type "pointer"
  my $Afun;			# used as type "string"

  $pPar1->{'err2'} = '';

  if (Interjection($pPar1->{'lemma'},'#') eq '#') {

    $pAct = $pPar1->firstson;
  forallsons:
    if ($pAct) {

      if (Interjection($pAct->{'afun'},'Pred') ne 'Pred' &&
	  Interjection($pAct->{'afun'},'Coord') ne 'Coord' &&
	  Interjection($pAct->{'afun'},'Apos') ne 'Apos' &&
	  Interjection($pAct->{'afun'},'AuxC') ne 'AuxC' &&
	  Interjection($pAct->{'afun'},'AuxK') ne 'AuxK' &&
	  Interjection($pAct->{'afun'},'AuxG') ne 'AuxG' &&
	  Interjection($pAct->{'afun'},'ExD') ne 'ExD') {

	$pPar1->{'err2'} = 'Found';
      } else {

	$pAct->{'err2'} = '';
      }


      $pAct = $pAct->rbrother;

      goto forallsons;
    }
  } else {

    if (substr(ValNo(0,$pPar1->{'afun'}),0,4) eq 'AuxZ') {

      $pAct = $pPar1->firstson;
    forallAuxZsons:
      if ($pAct) {

	if (substr(ValNo(0,$pAct->{'afun'}),0,4) ne 'AuxZ') {

	  $pPar1->{'err2'} = 'Found';
	} else {

	  $pAct->{'err2'} = '';
	}


	$pAct = $pAct->rbrother;

	goto forallAuxZsons;
      }
    } else {

      $Afun = substr(ValNo(0,$pPar1->{'afun'}),0,4);

      $pPar1->{'err2'} = '';

      if ($pPar1->firstson &&
	  ( $Afun eq 'AuxV' ||
	    $Afun eq 'AuxG' ||
	    $Afun eq 'AuxR' ||
	    $Afun eq 'AuxT' ||
	    $Afun eq 'AuxY' ||
	    $Afun eq 'AuxK' ||
	    $Afun eq 'AuxO' ||
	    $Afun eq 'AuxX' )) {

	$pPar1->{'err2'} = 'Found';
      } else {

	if (Interjection($pPar1->{'afun'},'Pred') eq 'Pred' &&
	    Interjection($pPar1->parent->{'lemma'},'#') ne '#') {

	  $pPar1->{'err2'} = 'Found';
	} else {

	  $sPar1 = ValNo(0,$pPar1->{'afun'});

	  $sPar2 = '_Co';

	  StrPos();

	  $pAct = $pPar1->parent;

	  if ($sReturn>"-1") {

	    if (substr(ValNo(0,$pAct->{'afun'}),0,5) ne 'Coord') {

	      if ($pAct->parent) {

		if (( Interjection($pAct->{'afun'},'AuxP') ne 'AuxP' &&
		      Interjection($pAct->{'afun'},'AuxC') ne 'AuxC' ) ||
		    ( substr(ValNo(0,$pAct->parent->{'afun'}),0,5) ne 'Coord' )) {

		  $pPar1->{'err2'} = 'Found';
		}
	      } else {

		$pPar1->{'err2'} = 'Found';
	      }

	    }
	  } else {

	    $sPar1 = ValNo(0,$pPar1->{'afun'});

	    $sPar2 = '_Ap';

	    StrPos();

	    $pAct = $pPar1->parent;

	    if ($sReturn>"-1") {

	      if (substr(ValNo(0,$pAct->{'afun'}),0,4) ne 'Apos') {

		if ($pAct->parent) {

		  if (( Interjection($pAct->{'afun'},'AuxP') ne 'AuxP' &&
			Interjection($pAct->{'afun'},'AuxC') ne 'AuxC' ) ||
		      ( substr(ValNo(0,$pAct->parent->{'afun'}),0,4) ne 'Apos' )) {

		    $pPar1->{'err2'} = 'Found';
		  }
		} else {

		  $pPar1->{'err2'} = 'Found';
		}

	      }
	    }
	  }

	}

      }

    }

  }


}


sub MarkWrongSbCase {
  my $tags;			# used as type "list"
  my $tagnum;			# used as type "string"
  my ($i, $j);			# used as type "string"

  $pPar1->{'err2'} = '';

  if (Interjection($pPar1->{'afun'},'Sb') eq 'Sb') {

    $tags = $pPar1->{'tag'};

    $tagnum = do{{ my @split = split /\|/,$tags; 0+@split }};

    $i = "0";

    $j = "0";
  foralltags:
    if ($i<$tagnum) {

      if (substr( ValNo($i,$tags) ,0,1) eq 'N' &&
	  substr( ValNo($i,$tags) ,1,1) ne 'O') {

	$j = $j+"1";
      }

      if ($j>"0" &&
	  substr( ValNo($i,$tags) ,3,1) eq "1") {

	return;
      }

      $i = $i+"1";

      goto foralltags;
    }

    if ($j>"0") {

      $pPar1->{'err2'} = 'Found';
    }
  }

}


sub MarkWrongCoord {

  $pPar1->{'err2'} = '';

  if (( Interjection($pPar1->{'lemma'},'a') eq 'a' ||
	Interjection($pPar1->{'lemma'},'v�ak') eq 'v�ak' ) &&
      ( substr(ValNo(0,$pPar1->{'afun'}),0,5) ne 'Coord' &&
	substr(ValNo(0,$pPar1->{'afun'}),0,4) ne 'AuxY' )) {

    $pPar1->{'err2'} = 'Found';
  } else {

    if (( Interjection($pPar1->{'lemma'},'ale') eq 'ale' ||
	  Interjection($pPar1->{'lemma'},'av�ak') eq 'av�ak' ||
	  Interjection($pPar1->{'lemma'},'nebo') eq 'nebo' ) &&
	substr(ValNo(0,$pPar1->{'afun'}),0,5) ne 'Coord') {

      $pPar1->{'err2'} = 'Found';
    } else {

      if (Interjection($pPar1->{'lemma'},',') eq ',') {

	if (( Interjection($pPar1->{'afun'},'AuxX') eq 'AuxX' &&
	      $pPar1->firstson ) ||
	    ( ( substr(ValNo(0,$pPar1->{'afun'}),0,5) eq 'Coord' ||
		substr(ValNo(0,$pPar1->{'afun'}),0,4) eq 'Apos' ) &&
	      !($pPar1->firstson) ) ||
	    ( substr(ValNo(0,$pPar1->{'afun'}),0,5) ne 'Coord' &&
	      substr(ValNo(0,$pPar1->{'afun'}),0,4) ne 'Apos' &&
	      Interjection($pPar1->{'afun'},'AuxX') ne 'AuxX' &&
	      substr(ValNo(0,$pPar1->{'afun'}),0,3) ne 'ExD' )) {

	  $pPar1->{'err2'} = 'Found';
	}
      }
    }

  }


}


sub MarkWrongCoz {

  $pPar1->{'err2'} = '';

  if (Interjection($pPar1->{'lemma'},'co�-1') eq 'co�-1' &&
      Interjection($pPar1->{'afun'},'Sb') ne 'Sb' &&
      Interjection($pPar1->{'afun'},'Obj') ne 'Obj') {

    $pPar1->{'err2'} = 'Found';

    return;
  }

  if (Interjection($pPar1->{'lemma'},'p�i�em�') eq 'p�i�em�' &&
      Interjection($pPar1->{'afun'},'Adv') ne 'Adv') {

    $pPar1->{'err2'} = 'Found';
  }

}


sub CorrectUv {

  if (Interjection($pPar1->{'form'},')') eq ')' &&
      Interjection($pPar1->{'afun'},'AuxK') eq 'AuxK') {

    $pPar1->{'afun'} = 'AuxG';
  }

}


#bind _key_Shift_F2 to Shift+F2
sub _key_Shift_F2 {

  if ($this->parent) {

    $this->{'mstag'} = $this->{'origap'};

    $this->{'origap'} = '';

    $this->{'err2'} = '';
  }

}


sub VerbsWithSe {
  my $i;			# used as type "string"
  my $some;			# used as type "string"
  my $test;			# used as type "string"
  my $afunnum;			# used as type "string"
  my $afuns;			# used as type "list"
  my $LogFile;			# used as type "string"

  if (Interjection($pPar1->{'form'},'se') eq 'se' ||
      Interjection($pPar1->{'form'},'Se') eq 'Se' ||
      Interjection($pPar1->{'form'},'SE') eq 'SE') {

    $afuns = $pPar1->{'afun'};

    $afunnum = do{{ my @split = split /\|/,$afuns; 0+@split }};

    $i = "0";

    $some = "0";
  forallAfuns:
    if (substr( ValNo($i,$afuns) ,0,4) eq 'AuxT' ||
	substr( ValNo($i,$afuns) ,0,4) eq 'AuxR' ||
	substr( ValNo($i,$afuns) ,0,3) eq 'Obj' ||
	substr( ValNo($i,$afuns) ,0,3) eq 'Adv') {

      if ($some=="0") {

	$sPar1 = ValNo(0,$pPar1->parent->{'lemma'});

	$sPar2 = '_';

	StrPos();

	if ($sReturn>"0") {

	  PrintToFile($LogFile, map { ValNo(0,$_) } (substr(ValNo(0,$pPar1->parent->{'lemma'}),0,$sReturn)));
	} else {

	  PrintToFile($LogFile, map { ValNo(0,$_) } (ValNo(0,$pPar1->parent->{'lemma'})));
	}


	$some = "1";
      }

      if (substr( ValNo($i,$afuns) ,0,4) eq 'AuxT' ||
	  substr( ValNo($i,$afuns) ,0,4) eq 'AuxR') {

	PrintToFile($LogFile, map { ValNo(0,$_) } ('\|', substr( ValNo($i,$afuns) ,0,4)));
      } else {

	PrintToFile($LogFile, map { ValNo(0,$_) } ('\|', substr( ValNo($i,$afuns) ,0,3)));
      }

    }

    $i = $i+"1";

    if ($i<$afunnum) {

      goto forallAfuns;
    }

    if ($some=="1") {

      PrintToFile($LogFile, map { ValNo(0,$_) } ('\n'));
    }
  }

}


sub IsOfZUQA {

  $sReturn = "0";

  if (Interjection($pPar1->{'form'},'a') eq 'a' ||
      Interjection($pPar1->{'form'},'ale') eq 'ale' ||
      Interjection($pPar1->{'form'},'av�ak') eq 'av�ak') {

    $sReturn = "1";
  }

}


sub ListZUQ1 {
  my $QLogFile;			# used as type "string"
  my $pA1;			# used as type "pointer"
  my $pA2;			# used as type "pointer"

  $pA1 = $pPar1;

  $pA2 = $pPar1->parent;

  if ($pA2 &&
      Interjection($pA1->{'afun'},'AuxY') eq 'AuxY') {

    IsOfZUQA();

    if ($sReturn=="1") {

      goto raport;
    }

    $pPar1 = $pA2;

    IsOfZUQA();

    if ($sReturn=="1") {

      goto raport;
    }
  }

  return;
 raport:
  PrintToFile($QLogFile, map { ValNo(0,$_) } (ValNo(0,$pA2->{'form'}), ' [', ValNo(0,$pA2->{'afun'}), '] >> ', ValNo(0,$pA1->{'form'}), ' [AuxY]\n'));

}


sub RSearchQ {
  my $pAct;			# used as type "pointer"

  $pPar2 = undef;

  $pAct = $pPar1;
 loopRSQ:
  if (Interjection($pAct->{'err2'},'Found') eq 'Found') {

    $pReturn = $pAct;

    return;
  }

  $pPar1 = $pAct;

  GoNext();

  if ($pReturn) {

    $pAct = $pReturn;

    goto loopRSQ;
  }

}


sub TreeSearchQ {
 loopTSQ:
  if ($pPar1) {

    RSearchQ();

    if ($pReturn) {

      $this = $pReturn;

      return;
    }
  }

  NextTree();

  if ($_NoSuchTree ne "1") {

    $pPar1 = $this;

    goto loopTSQ;
  }

}


#bind _key_Ctrl_8 to Ctrl+8
sub _key_Ctrl_8 {

  ThisRoot();

  $pPar1 = $pReturn;

  TreeSearchQ();

}


#bind _key_Ctrl_7 to Ctrl+7
sub _key_Ctrl_7 {

  ThisRoot();

  $pPar2 = $pReturn;

  $pPar1 = $this;

  GoNext();

  $pPar1 = $pReturn;

  TreeSearchQ();

}


sub AuxZAuxZ {
  my $parent;			# used as type "pointer"

  if (!($pPar1->parent)) {

    return;
  }

  $parent = $pPar1->parent;

  if (Interjection($pPar1->{'afun'},'AuxZ') eq 'AuxZ' &&
      Interjection($parent->{'afun'},'AuxZ') eq 'AuxZ') {
    PrintToFile('auxzauxz.lst', map { ValNo(0,$_) } (ValNo(0,$parent->{'form'}), ' >> ', ValNo(0,$pPar1->{'form'}), '\n'));
  }

}


sub PrintTreeNumber {

  ThisRoot();

  PrintToFile($sPar1, map { ValNo(0,$_) } (ValNo(0,$pReturn->{'mstag'}), ' ', ValNo(0,$pReturn->{'form'}), '\n'));

}


sub ListTree {
  my $pAct;			# used as type "pointer"

  ThisRoot();

  $pAct = $pReturn;
 loopNode:
  $pPar1 = $pAct;

  GoNext();

  $pAct = $pReturn;

  if ($pAct) {

    PrintToFile($sPar1, map { ValNo(0,$_) } (' ', ValNo(0,$pAct->{'ord'}), ' ', ValNo(0,$pAct->{'form'}), '\n'));

    goto loopNode;
  }

}


sub IsVerb {
  my $i;			# used as type "string"
  my $tagnum;			# used as type "string"
  my $tags;			# used as type "list"

  $tags = $pPar1->{'tag'};

  $tagnum = do{{ my @split = split /\|/,$tags; 0+@split }};

  $i = "0";
 loopTags:
  if (substr( ValNo($i,$tags) ,0,1) eq 'V') {

    $sReturn = "1";

    return;
  } else {

    $i = $i+"1";

    if ($i<$tagnum) {

      goto loopTags;
    }
  }


  $sReturn = "0";

  return;

}


sub PrintJako {
  my $pAct;			# used as type "pointer"
  my $pSon;			# used as type "pointer"
 loopTrees:
  $pAct = $this;
 loopNodes:
  if (Interjection($pAct->{'form'},'jako') eq 'jako' ||
      Interjection($pAct->{'form'},'JAKO') eq 'JAKO' ||
      Interjection($pAct->{'form'},'Jako') eq 'Jako') {

    $pSon = $pAct->firstson;
  loopSons:
    if ($pSon) {

      $pPar1 = $pSon;

      IsVerb();

      if ($sReturn eq "1") {

	$sPar1 = 'c:\\jako.lst';

	PrintToFile($sPar1, map { ValNo(0,$_) } ('\n'));

	PrintTreeNumber();

	ListTree();

	goto contTrees;
      }

      $pSon = $pSon->rbrother;

      goto loopSons;
    }
  }

  $pPar1 = $pAct;

  GoNext();

  $pAct = $pReturn;

  if ($pAct) {

    goto loopNodes;
  }
 contTrees:
  NextTree();

  if ($_NoSuchTree ne "1") {

    goto loopTrees;
  }

}


sub PrintAll {
  my $FNAME="printall.list";			# used as type "string"

  ThisRoot();
 loopTrees:
  $sPar1 = $FNAME;

  PrintToFile($sPar1, map { ValNo(0,$_) } ('\n'));

  PrintTreeNumber();

  ListTree();

  NextTree();

  if ($_NoSuchTree ne "1") {

    goto loopTrees;
  }

}


sub ToLine {
  my $pKing;			# used as type "pointer"
  my $pPrince;			# used as type "pointer"
  my $pInLaw;			# used as type "pointer"

  if ($this->parent) {

    $pKing = $this->parent;

    $pPrince = $this;
  } else {

    $pKing = $this;

    $pPrince = $pKing->firstson;

    goto whileHasBrothers;
  }

 start:
  $pReturn = $pPrince;

  $pInLaw = $pPrince;
 minOrd:
  $pPar1 = $pReturn;

  $pPar2 = $pPrince;

  GoNext();

  if (!($pReturn)) {

    goto changeOrder;
  }

  if (ValNo(0,$pReturn->{'ord'})<ValNo(0,$pInLaw->{'ord'})) {

    $pInLaw = $pReturn;
  }

  goto minOrd;
 changeOrder:
  if ($pInLaw ne $pPrince) {

    $pInLaw->{'warning'} = 'InLaw';

    $NodeClipboard=CutNode($pInLaw);

    $_pDummy = PasteNode($NodeClipboard,$pKing);

    $pInLaw = $pKing->firstson;
  whileNotInLaw:
    if (Interjection($pInLaw->{'warning'},'InLaw') ne 'InLaw') {

      $pInLaw = $pInLaw->rbrother;

      goto whileNotInLaw;
    }

    $pInLaw->{'warning'} = '';

    $NodeClipboard=CutNode($pPrince);

    $_pDummy = PasteNode($NodeClipboard,$pInLaw);

    $pPrince = $pInLaw;
  }

  $pKing = $pPrince;

  if (!($pKing->firstson)) {

    return;
  }

  $pPrince = $pKing->firstson;
 whileHasBrothers:
  if ($pPrince->rbrother) {

    $NodeClipboard=CutNode($pPrince->rbrother);

    $_pDummy = PasteNode($NodeClipboard,$pPrince);

    goto whileHasBrothers;
  }

  goto start;

}


#bind _key_2 to at
sub _key_2 {

  ToLine();

}


#bind _key_3 to numbersign
sub _key_3 {
  my $pNewPapa;			# used as type "pointer"
  my $pParent;			# used as type "pointer"
  my $pAct;			# used as type "pointer"

  $pAct = $this;

  if (!($pAct->parent)) {

    return;
  }

  if ($pAct->parent->parent) {

    $pNewPapa = $pAct->parent->parent;
  } else {

    if ($pAct->lbrother) {

      $pNewPapa = $pAct->lbrother;
    } else {

      return;
    }

  }


  $NodeClipboard=CutNode($pAct);

  $pAct = PasteNode($NodeClipboard,$pNewPapa);

  $this = $pAct;

}


sub MarkCoordNotCo {
  my $pAct;			# used as type "pointer"
  my $pAux;			# used as type "pointer"
  my $test;			# used as type "string"
  my $sfx;			# used as type "string"

  if (!($pPar1)) {

    return;
  }

  $pPar1->{'err2'} = '';

  if (substr(ValNo(0,$pPar1->{'afun'}),0,5) eq 'Coord') {

    $sfx = '_Co';
  } else {

    if (substr(ValNo(0,$pPar1->{'afun'}),0,4) eq 'Apos') {

      $sfx = '_Ap';
    } else {

      return;
    }

  }


  $pAct = $pPar1;

  $test = "0";

  $pPar1 = $pAct->firstson;
 loop:
  $pPar2 = $pAct;

  if ($pPar1) {

    $sPar2 = $sfx;

    $sPar1 = ValNo(0,$pPar1->{'afun'});

    StrPos();

    if ($sReturn!="-1") {

      $pAux = $pPar1;
    parent:
      $pAux = $pAux->parent;

      if ($pAux eq $pAct) {

	$test = "1";
      } else {

	if (substr(ValNo(0,$pAux->{'afun'}),0,4) eq 'AuxP' ||
	    substr(ValNo(0,$pAux->{'afun'}),0,4) eq 'AuxC') {

	  goto parent;
	}
      }

    }

    if ($test=="0") {

      $pPar2 = $pAct;

      GoNext();

      $pPar1 = $pReturn;

      goto loop;
    }
  }

  if ($test=="0") {

    $pAct->{'err2'} = 'Found';

    return;
  }

}


sub MiscWordsTest {

  $pPar1->{'err2'} = '';

  if (substr(ValNo(0,$pPar1->{'lemma'}),0,6) eq 'p�itom' &&
      substr(ValNo(0,$pPar1->{'afun'}),0,3) ne 'Adv') {

    $pPar1->{'err2'} = 'Found';

    return;
  }

  if (substr(ValNo(0,$pPar1->{'lemma'}),0,7) eq 'zat�mco' &&
      substr(ValNo(0,$pPar1->{'afun'}),0,4) ne 'AuxC') {

    $pPar1->{'err2'} = 'Found';

    return;
  }

  if (substr(ValNo(0,$pPar1->{'lemma'}),0,6) eq 'jakoby') {

    IsVerb();

    if ($sReturn=="1") {

      if (substr(ValNo(0,$pPar1->{'afun'}),0,4) ne 'AuxY') {

	$pPar1->{'err2'} = 'Found';

	return;
      }
    } else {

      if (substr(ValNo(0,$pPar1->{'afun'}),0,4) ne 'AuxZ') {

	$pPar1->{'err2'} = 'Found';

	return;
      }
    }

  }

}


sub HasSubItem {
  my $i;			# used as type "string"
  my $tagnum;			# used as type "string"
  my $tags;			# used as type "list"

  $tags = $lPar1;

  $tagnum = do{{ my @split = split /\|/,$tags; 0+@split }};

  $i = "0";
 loopTags:
  if (substr( ValNo($i,$tags) ,0,$sPar2) eq $sPar1) {

    $sReturn = "1";

    return;
  } else {

    $i = $i+"1";

    if ($i<$tagnum) {

      goto loopTags;
    }
  }


  $sReturn = "0";

  return;

}


sub FindParent {

  $pReturn = $pPar1->parent;
 loop:
  if (!($pReturn) ||
      ( substr(ValNo(0,$pReturn->{'afun'}),0,5) ne 'Coord' &&
	substr(ValNo(0,$pReturn->{'afun'}),0,4) ne 'Apos' )) {

    return;
  }

  $pReturn = $pReturn->parent;

  goto loop;

}


sub TestInfinitives {
  my $pAct;			# used as type "pointer"
  my $pParent;			# used as type "pointer"

  $pAct = $pPar1;

  if (!($pAct->firstson) &&
      Interjection($pAct->{'afun'},'AuxV') ne 'AuxV') {

    $sPar1 = 'VU';

    $sPar2 = "2";

    $lPar1 = $pAct->{'tag'};

    HasSubItem();

    if ($sReturn=="1") {

      $pAct->{'err2'} = 'Found';

      return;
    }
  }

  $sPar1 = 'VF';

  $sPar2 = "2";

  $lPar1 = $pAct->{'tag'};

  HasSubItem();

  if ($sReturn=="1") {

    $pPar1 = $pAct;

    FindParent();

    $pParent = $pReturn;

    if (!($pParent)) {

      if (substr(ValNo(0,$pAct->{'afun'}),0,3) ne 'ExD') {

	$pAct->{'err2'} = 'Found';
      }

      return;
    }

    $sPar1 = 'VU';

    $sPar2 = "2";

    $lPar1 = $pParent->{'tag'};

    HasSubItem();

    if ($sReturn=="1") {

      $pAct->{'err2'} = 'Found';

      return;
    }

    if (substr(ValNo(0,$pParent->{'lemma'}),0,4) eq 'moci' &&
	substr(ValNo(0,$pAct->{'afun'}),0,3) ne 'Obj') {

      $pAct->{'err2'} = 'Found';

      return;
    }

    if (( Interjection($pParent->{'form'},'d�') eq 'd�' ||
	  Interjection($pParent->{'form'},'D�') eq 'D�' ||
	  Interjection($pParent->{'form'},'D�') eq 'D�' ) &&
	( substr(ValNo(0,$pAct->{'afun'}),0,3) ne 'Obj' )) {

      $pAct->{'err2'} = 'Found';

      return;
    }

    if (substr(ValNo(0,$pParent->{'lemma'}),0,3) eq 'lze' &&
	substr(ValNo(0,$pAct->{'afun'}),0,2) ne 'Sb') {

      $pAct->{'err2'} = 'Found';

      return;
    }
  }

  $pAct->{'err2'} = '';

}


sub TestAuxV {
  my $pAct;			# used as type "pointer"

  $pAct = $pPar1;

  if (Interjection($pAct->{'afun'},'AuxV') eq 'AuxV') {

    $sPar1 = 'b�t';

    $sPar2 = "3";

    $lPar1 = $pAct->{'lemma'};

    HasSubItem();

    if (( $sReturn!="1" &&
	  Interjection($pAct->{'lemma'},'by') ne 'by' ) ||
	$pAct->firstson) {

      $pAct->{'err2'} = 'Found';

      return;
    }
  } else {

    if (!($pAct->firstson)) {

      $sPar1 = 'b�t';

      $sPar2 = "3";

      $lPar1 = $pAct->{'lemma'};

      HasSubItem();

      if ($sReturn=="1" &&
	  ( ( Interjection($pAct->{'form'},'je') ne 'je' &&
	      Interjection($pAct->{'form'},'Je') ne 'Je' ) ||
	    substr(ValNo(0,$pAct->{'afun'}),0,3) ne 'Obj' ) &&
	  ( ( Interjection($pAct->{'form'},'bu�') ne 'bu�' &&
	      Interjection($pAct->{'form'},'Bu�') ne 'Bu�' ) ||
	    substr(ValNo(0,$pAct->{'afun'}),0,4) ne 'AuxY' )) {

	$pAct->{'err2'} = 'Found';

	return;
      }
    }
  }


  $pAct->{'err2'} = '';

}


sub TestVsakAle {

  if (Interjection($pPar1->{'lemma'},'v�ak') eq 'v�ak' ||
      Interjection($pPar1->{'lemma'},'ale') eq 'ale') {

    if (substr(ValNo(0,$pPar1->{'afun'}),0,5) ne 'Coord' ||
	!($pPar1->firstson)) {

      $pPar1->{'err2'} = 'Found';

      return;
    }
  }

  $pPar1->{'err2'} = '';

}


sub CountSe {

  $pPar1->{'err2'} = '';

  if (Interjection($pPar1->{'form'},'se') eq 'se' ||
      Interjection($pPar1->{'form'},'Se') eq 'Se' ||
      Interjection($pPar1->{'form'},'SE') eq 'SE' ||
      Interjection($pPar1->{'form'},'si') eq 'si' ||
      Interjection($pPar1->{'form'},'Si') eq 'Si' ||
      Interjection($pPar1->{'form'},'SI') eq 'SI') {

    if (Interjection($pPar1->{'reserve5'},'') eq '') {

      $pPar1->{'err2'} = 'Found';
    }
  }

}


sub OneSb {
  my $pBrother;			# used as type "pointer"
  my $afun;			# used as type "string"

  if (substr(ValNo(0,$pPar1->{'afun'}),0,2) eq 'Sb') {

    $pBrother = $pPar1->rbrother;
  rb:
    if ($pBrother) {

      if (substr(ValNo(0,$pBrother->{'afun'}),0,2) eq 'Sb') {

	if (Interjection($pPar1->{'afun'},'Sb') eq 'Sb' ||
	    Interjection($pBrother->{'afun'},'Sb') eq 'Sb' ||
	    ( substr(ValNo(0,$pPar1->{'afun'}),2,3) eq '_Co' &&
	      substr(ValNo(0,$pBrother->{'afun'}),2,3) ne '_Co' ) ||
	    ( substr(ValNo(0,$pPar1->{'afun'}),2,3) ne '_Co' &&
	      substr(ValNo(0,$pBrother->{'afun'}),2,3) eq '_Co' ) ||
	    ( substr(ValNo(0,$pPar1->{'afun'}),2,3) eq '_Ap' &&
	      substr(ValNo(0,$pBrother->{'afun'}),2,3) ne '_Ap' ) ||
	    ( substr(ValNo(0,$pPar1->{'afun'}),2,3) ne '_Ap' &&
	      substr(ValNo(0,$pBrother->{'afun'}),2,3) eq '_Ap' )) {

	  $pPar1->{'err2'} = 'Found';

	  $pBrother->{'err2'} = 'Found';
	} else {

	  $pPar1->{'err2'} = '';
	}

      } else {

	$pBrother = $pBrother->rbrother;

	goto rb;
      }

    }
  } else {

    $pPar1->{'err2'} = '';
  }


}


sub ClearErr2 {

  $pPar1->{'err2'} = '';

}


sub ProtoCoord {

  $pPar1->{'err2'} = '';

  if (Interjection($pPar1->{'lemma'},'proto') eq 'proto') {

    if (( substr(ValNo(0,$pPar1->{'afun'}),0,3) ne 'Adv' ||
	  $pPar1->firstson ) &&
	( substr(ValNo(0,$pPar1->{'afun'}),0,4) ne 'AuxY' ||
	  substr(ValNo(0,$pPar1->parent->{'afun'}),0,5) ne 'Coord' ) &&
	substr(ValNo(0,$pPar1->{'afun'}),0,5) ne 'Coord' &&
	substr(ValNo(0,$pPar1->{'afun'}),0,3) ne 'ExD') {

      $pPar1->{'err2'} = 'Found';
    }
  }

}


sub HasSubItemX {
  my $i;			# used as type "string"
  my $j;			# used as type "string"
  my $tagnum;			# used as type "string"
  my $c;			# used as type "string"
  my $tags;			# used as type "list"

  $tags = $lPar1;

  $tagnum = do{{ my @split = split /\|/,$tags; 0+@split }};

  $i = "0";
 loopTags:
  $j = "0";
 loopChars:
  $c = substr($sPar1,$j,1);

  if ($c eq '') {

    $sReturn = "1";

    return;
  }

  if (( $c eq '.' &&
	substr( ValNo($i,$tags) ,$j,1) ne '' ) ||
      substr( ValNo($i,$tags) ,$j,1) eq $c) {

    $j = $j+"1";

    goto loopChars;
  } else {

    $i = $i+"1";

    if ($i<$tagnum) {

      goto loopTags;
    }
  }


  $sReturn = "0";

  return;

}


sub TestAccomp {
  my $pParent;			# used as type "pointer"

  $pPar1->{'err2'} = '';

  if (substr(ValNo(0,$pPar1->{'afun'}),0,2) eq 'Sb') {

    $lPar1 = $pPar1->{'tag'};

    $sPar1 = 'N.S1';

    HasSubItemX();

    if ($sReturn eq "0") {

      return;
    }

    $lPar1 = $pPar1->{'tag'};

    $sPar1 = 'N.P1';

    HasSubItemX();

    if ($sReturn eq "1") {

      return;
    }

    $pParent = $pPar1->parent;
  lp:
    if (!($pParent)) {

      $pPar1->{'err2'} = 'Found';

      return;
    }

    if (substr(ValNo(0,$pParent->{'afun'}),0,5) eq 'Coord' ||
	substr(ValNo(0,$pParent->{'afun'}),0,4) eq 'Apos') {

      $pParent = $pParent->parent;

      goto lp;
    }

    $lPar1 = $pParent->{'tag'};

    $sPar1 = 'V.P';

    HasSubItemX();

    if ($sReturn eq "0") {

      return;
    }

    $lPar1 = $pParent->{'tag'};

    $sPar1 = 'V.S';

    HasSubItemX();

    if ($sReturn eq "1") {

      return;
    }

    if (Interjection($pPar1->{'afun'},'Sb_Co') eq 'Sb_Co') {

      return;
    }

    $pPar1->{'err2'} = 'Found';
  }

}


sub TestAccomp2 {
  my $pParent;			# used as type "pointer"

  $pPar1->{'err2'} = '';

  if (substr(ValNo(0,$pPar1->{'afun'}),0,2) eq 'Sb') {

    $lPar1 = $pPar1->{'tag'};

    $sPar1 = 'N.P1';

    HasSubItemX();

    if ($sReturn eq "0") {

      return;
    }

    $lPar1 = $pPar1->{'tag'};

    $sPar1 = 'N.S1';

    HasSubItemX();

    if ($sReturn eq "1") {

      return;
    }

    $pParent = $pPar1->parent;
  lp:
    if (!($pParent)) {

      $pPar1->{'err2'} = 'Found';

      return;
    }

    if (substr(ValNo(0,$pParent->{'afun'}),0,5) eq 'Coord' ||
	substr(ValNo(0,$pParent->{'afun'}),0,4) eq 'Apos') {

      $pParent = $pParent->parent;

      goto lp;
    }

    $lPar1 = $pParent->{'tag'};

    $sPar1 = 'V.S';

    HasSubItemX();

    if ($sReturn eq "0") {

      return;
    }

    $lPar1 = $pParent->{'tag'};

    $sPar1 = 'V.P';

    HasSubItemX();

    if ($sReturn eq "1") {

      return;
    }

    if (Interjection($pPar1->{'afun'},'Sb_Co') eq 'Sb_Co') {

      return;
    }

    $pPar1->{'err2'} = 'Found';
  }

}


sub TestAuxZList {

  $pPar1->{'err2'} = '';

  if (Interjection($pPar1->{'afun'},'AuxZ') ne 'AuxZ') {

    return;
  }

  if (Interjection($pPar1->{'form'},'akor�t') eq 'akor�t' ||
      Interjection($pPar1->{'form'},'alespo�') eq 'alespo�' ||
      Interjection($pPar1->{'form'},'ani') eq 'ani' ||
      Interjection($pPar1->{'form'},'asi') eq 'asi' ||
      Interjection($pPar1->{'form'},'aspo�') eq 'aspo�' ||
      Interjection($pPar1->{'form'},'a�') eq 'a�' ||
      Interjection($pPar1->{'form'},'celkem') eq 'celkem' ||
      Interjection($pPar1->{'form'},'dohromady') eq 'dohromady' ||
      Interjection($pPar1->{'form'},'dokonce') eq 'dokonce' ||
      Interjection($pPar1->{'form'},'hlavn�') eq 'hlavn�' ||
      Interjection($pPar1->{'form'},'hned') eq 'hned' ||
      Interjection($pPar1->{'form'},'i') eq 'i' ||
      Interjection($pPar1->{'form'},'jakoby') eq 'jakoby' ||
      Interjection($pPar1->{'form'},'jedin�') eq 'jedin�' ||
      Interjection($pPar1->{'form'},'jen') eq 'jen' ||
      Interjection($pPar1->{'form'},'jenom') eq 'jenom' ||
      Interjection($pPar1->{'form'},'je�t�') eq 'je�t�' ||
      Interjection($pPar1->{'form'},'ji�') eq 'ji�' ||
      Interjection($pPar1->{'form'},'jmenovit�') eq 'jmenovit�' ||
      Interjection($pPar1->{'form'},'leda') eq 'leda' ||
      Interjection($pPar1->{'form'},'m�lem') eq 'm�lem' ||
      Interjection($pPar1->{'form'},'maxim�ln�') eq 'maxim�ln�' ||
      Interjection($pPar1->{'form'},'minim�ln�') eq 'minim�ln�' ||
      Interjection($pPar1->{'form'},'nanejv��') eq 'nanejv��' ||
      Interjection($pPar1->{'form'},'nap��klad') eq 'nap��klad' ||
      Interjection($pPar1->{'form'},'nap�') eq 'nap�' ||
      Interjection($pPar1->{'form'},'nap�.') eq 'nap�.' ||
      Interjection($pPar1->{'form'},'ne') eq 'ne' ||
      Interjection($pPar1->{'form'},'nejen') eq 'nejen' ||
      Interjection($pPar1->{'form'},'nejen�e') eq 'nejen�e' ||
      Interjection($pPar1->{'form'},'nejm�n�') eq 'nejm�n�' ||
      Interjection($pPar1->{'form'},'nejv�ce') eq 'nejv�ce' ||
      Interjection($pPar1->{'form'},'nikoliv') eq 'nikoliv' ||
      Interjection($pPar1->{'form'},'nikoli') eq 'nikoli' ||
      Interjection($pPar1->{'form'},'pak') eq 'pak' ||
      Interjection($pPar1->{'form'},'pouze') eq 'pouze' ||
      Interjection($pPar1->{'form'},'pr�v�') eq 'pr�v�' ||
      Interjection($pPar1->{'form'},'prost�') eq 'prost�' ||
      Interjection($pPar1->{'form'},'p�edev��m') eq 'p�edev��m' ||
      Interjection($pPar1->{'form'},'p�esn�') eq 'p�esn�' ||
      Interjection($pPar1->{'form'},'p��mo') eq 'p��mo' ||
      Interjection($pPar1->{'form'},'p�inejmen��m') eq 'p�inejmen��m' ||
      Interjection($pPar1->{'form'},'rovn�') eq 'rovn�' ||
      Interjection($pPar1->{'form'},'rovnou') eq 'rovnou' ||
      Interjection($pPar1->{'form'},'skoro') eq 'skoro' ||
      Interjection($pPar1->{'form'},'sotva') eq 'sotva' ||
      Interjection($pPar1->{'form'},'taky') eq 'taky' ||
      Interjection($pPar1->{'form'},'tak�') eq 'tak�' ||
      Interjection($pPar1->{'form'},'t�m��') eq 't�m��' ||
      Interjection($pPar1->{'form'},'teprve') eq 'teprve' ||
      Interjection($pPar1->{'form'},'toliko') eq 'toliko' ||
      Interjection($pPar1->{'form'},'t�eba') eq 't�eba' ||
      Interjection($pPar1->{'form'},'u�') eq 'u�' ||
      Interjection($pPar1->{'form'},'v�bec') eq 'v�bec' ||
      Interjection($pPar1->{'form'},'zase') eq 'zase' ||
      Interjection($pPar1->{'form'},'zejm�na') eq 'zejm�na' ||
      Interjection($pPar1->{'form'},'zhruba') eq 'zhruba' ||
      Interjection($pPar1->{'form'},'zrovna') eq 'zrovna' ||
      Interjection($pPar1->{'form'},'z�ejm�') eq 'z�ejm�' ||
      Interjection($pPar1->{'form'},'zvlṻ') eq 'zvlṻ' ||
      Interjection($pPar1->{'form'},'zvl�t�') eq 'zvl�t�' ||
      Interjection($pPar1->{'form'},'AKOR�T') eq 'AKOR�T' ||
      Interjection($pPar1->{'form'},'ALESPO�') eq 'ALESPO�' ||
      Interjection($pPar1->{'form'},'ANI') eq 'ANI' ||
      Interjection($pPar1->{'form'},'ASI') eq 'ASI' ||
      Interjection($pPar1->{'form'},'ASPO�') eq 'ASPO�' ||
      Interjection($pPar1->{'form'},'A�') eq 'A�' ||
      Interjection($pPar1->{'form'},'CELKEM') eq 'CELKEM' ||
      Interjection($pPar1->{'form'},'DOHROMADY') eq 'DOHROMADY' ||
      Interjection($pPar1->{'form'},'DOKONCE') eq 'DOKONCE' ||
      Interjection($pPar1->{'form'},'HLAVN�') eq 'HLAVN�' ||
      Interjection($pPar1->{'form'},'HNED') eq 'HNED' ||
      Interjection($pPar1->{'form'},'I') eq 'I' ||
      Interjection($pPar1->{'form'},'JAKOBY') eq 'JAKOBY' ||
      Interjection($pPar1->{'form'},'JEDIN�') eq 'JEDIN�' ||
      Interjection($pPar1->{'form'},'JEN') eq 'JEN' ||
      Interjection($pPar1->{'form'},'JENOM') eq 'JENOM' ||
      Interjection($pPar1->{'form'},'JE�T�') eq 'JE�T�' ||
      Interjection($pPar1->{'form'},'JI�') eq 'JI�' ||
      Interjection($pPar1->{'form'},'JMENOVIT�') eq 'JMENOVIT�' ||
      Interjection($pPar1->{'form'},'LEDA') eq 'LEDA' ||
      Interjection($pPar1->{'form'},'M�LEM') eq 'M�LEM' ||
      Interjection($pPar1->{'form'},'MAXIM�LN�') eq 'MAXIM�LN�' ||
      Interjection($pPar1->{'form'},'MINIM�LN�') eq 'MINIM�LN�' ||
      Interjection($pPar1->{'form'},'NANEJVݩ') eq 'NANEJVݩ' ||
      Interjection($pPar1->{'form'},'NAP��KLAD') eq 'NAP��KLAD' ||
      Interjection($pPar1->{'form'},'NAP�') eq 'NAP�' ||
      Interjection($pPar1->{'form'},'NAP�.') eq 'NAP�.' ||
      Interjection($pPar1->{'form'},'NE') eq 'NE' ||
      Interjection($pPar1->{'form'},'NEJEN') eq 'NEJEN' ||
      Interjection($pPar1->{'form'},'NEJEN�E') eq 'NEJEN�E' ||
      Interjection($pPar1->{'form'},'NEJM�N�') eq 'NEJM�N�' ||
      Interjection($pPar1->{'form'},'NEJV�CE') eq 'NEJV�CE' ||
      Interjection($pPar1->{'form'},'NIKOLIV') eq 'NIKOLIV' ||
      Interjection($pPar1->{'form'},'NIKOLI') eq 'NIKOLI' ||
      Interjection($pPar1->{'form'},'PAK') eq 'PAK' ||
      Interjection($pPar1->{'form'},'POUZE') eq 'POUZE' ||
      Interjection($pPar1->{'form'},'PR�V�') eq 'PR�V�' ||
      Interjection($pPar1->{'form'},'PROST�') eq 'PROST�' ||
      Interjection($pPar1->{'form'},'P�EDEV��M') eq 'P�EDEV��M' ||
      Interjection($pPar1->{'form'},'P�ESN�') eq 'P�ESN�' ||
      Interjection($pPar1->{'form'},'P��MO') eq 'P��MO' ||
      Interjection($pPar1->{'form'},'P�INEJMEN��M') eq 'P�INEJMEN��M' ||
      Interjection($pPar1->{'form'},'ROVN̮') eq 'ROVN̮' ||
      Interjection($pPar1->{'form'},'ROVNOU') eq 'ROVNOU' ||
      Interjection($pPar1->{'form'},'SKORO') eq 'SKORO' ||
      Interjection($pPar1->{'form'},'SOTVA') eq 'SOTVA' ||
      Interjection($pPar1->{'form'},'TAKY') eq 'TAKY' ||
      Interjection($pPar1->{'form'},'TAK�') eq 'TAK�' ||
      Interjection($pPar1->{'form'},'T�M��') eq 'T�M��' ||
      Interjection($pPar1->{'form'},'TEPRVE') eq 'TEPRVE' ||
      Interjection($pPar1->{'form'},'TOLIKO') eq 'TOLIKO' ||
      Interjection($pPar1->{'form'},'T�EBA') eq 'T�EBA' ||
      Interjection($pPar1->{'form'},'U�') eq 'U�' ||
      Interjection($pPar1->{'form'},'V�BEC') eq 'V�BEC' ||
      Interjection($pPar1->{'form'},'ZASE') eq 'ZASE' ||
      Interjection($pPar1->{'form'},'ZEJM�NA') eq 'ZEJM�NA' ||
      Interjection($pPar1->{'form'},'ZHRUBA') eq 'ZHRUBA' ||
      Interjection($pPar1->{'form'},'ZROVNA') eq 'ZROVNA' ||
      Interjection($pPar1->{'form'},'Z�EJM�') eq 'Z�EJM�' ||
      Interjection($pPar1->{'form'},'ZVL��T�') eq 'ZVL��T�' ||
      Interjection($pPar1->{'form'},'Akor�t') eq 'Akor�t' ||
      Interjection($pPar1->{'form'},'Alespo�') eq 'Alespo�' ||
      Interjection($pPar1->{'form'},'Ani') eq 'Ani' ||
      Interjection($pPar1->{'form'},'Asi') eq 'Asi' ||
      Interjection($pPar1->{'form'},'Aspo�') eq 'Aspo�' ||
      Interjection($pPar1->{'form'},'A�') eq 'A�' ||
      Interjection($pPar1->{'form'},'Celkem') eq 'Celkem' ||
      Interjection($pPar1->{'form'},'Dohromady') eq 'Dohromady' ||
      Interjection($pPar1->{'form'},'Dokonce') eq 'Dokonce' ||
      Interjection($pPar1->{'form'},'Hlavn�') eq 'Hlavn�' ||
      Interjection($pPar1->{'form'},'Hned') eq 'Hned' ||
      Interjection($pPar1->{'form'},'I') eq 'I' ||
      Interjection($pPar1->{'form'},'Jakoby') eq 'Jakoby' ||
      Interjection($pPar1->{'form'},'Jedin�') eq 'Jedin�' ||
      Interjection($pPar1->{'form'},'Jen') eq 'Jen' ||
      Interjection($pPar1->{'form'},'Jenom') eq 'Jenom' ||
      Interjection($pPar1->{'form'},'Je�t�') eq 'Je�t�' ||
      Interjection($pPar1->{'form'},'Ji�') eq 'Ji�' ||
      Interjection($pPar1->{'form'},'Jmenovit�') eq 'Jmenovit�' ||
      Interjection($pPar1->{'form'},'Leda') eq 'Leda' ||
      Interjection($pPar1->{'form'},'M�lem') eq 'M�lem' ||
      Interjection($pPar1->{'form'},'Maxim�ln�') eq 'Maxim�ln�' ||
      Interjection($pPar1->{'form'},'Minim�ln�') eq 'Minim�ln�' ||
      Interjection($pPar1->{'form'},'Nanejv��') eq 'Nanejv��' ||
      Interjection($pPar1->{'form'},'Nap��klad') eq 'Nap��klad' ||
      Interjection($pPar1->{'form'},'Nap�') eq 'Nap�' ||
      Interjection($pPar1->{'form'},'Nap�.') eq 'Nap�.' ||
      Interjection($pPar1->{'form'},'Ne') eq 'Ne' ||
      Interjection($pPar1->{'form'},'Nejen') eq 'Nejen' ||
      Interjection($pPar1->{'form'},'Nejen�e') eq 'Nejen�e' ||
      Interjection($pPar1->{'form'},'Nejm�n�') eq 'Nejm�n�' ||
      Interjection($pPar1->{'form'},'Nejv�ce') eq 'Nejv�ce' ||
      Interjection($pPar1->{'form'},'Nikoliv') eq 'Nikoliv' ||
      Interjection($pPar1->{'form'},'Nikoli') eq 'Nikoli' ||
      Interjection($pPar1->{'form'},'Pak') eq 'Pak' ||
      Interjection($pPar1->{'form'},'Pouze') eq 'Pouze' ||
      Interjection($pPar1->{'form'},'Pr�v�') eq 'Pr�v�' ||
      Interjection($pPar1->{'form'},'Prost�') eq 'Prost�' ||
      Interjection($pPar1->{'form'},'P�edev��m') eq 'P�edev��m' ||
      Interjection($pPar1->{'form'},'P�esn�') eq 'P�esn�' ||
      Interjection($pPar1->{'form'},'P��mo') eq 'P��mo' ||
      Interjection($pPar1->{'form'},'P�inejmen��m') eq 'P�inejmen��m' ||
      Interjection($pPar1->{'form'},'Rovn�') eq 'Rovn�' ||
      Interjection($pPar1->{'form'},'Rovnou') eq 'Rovnou' ||
      Interjection($pPar1->{'form'},'Skoro') eq 'Skoro' ||
      Interjection($pPar1->{'form'},'Sotva') eq 'Sotva' ||
      Interjection($pPar1->{'form'},'Taky') eq 'Taky' ||
      Interjection($pPar1->{'form'},'T�m��') eq 'T�m��' ||
      Interjection($pPar1->{'form'},'Teprve') eq 'Teprve' ||
      Interjection($pPar1->{'form'},'Toliko') eq 'Toliko' ||
      Interjection($pPar1->{'form'},'T�eba') eq 'T�eba' ||
      Interjection($pPar1->{'form'},'U�') eq 'U�' ||
      Interjection($pPar1->{'form'},'V�bec') eq 'V�bec' ||
      Interjection($pPar1->{'form'},'Zase') eq 'Zase' ||
      Interjection($pPar1->{'form'},'Zejm�na') eq 'Zejm�na' ||
      Interjection($pPar1->{'form'},'Zhruba') eq 'Zhruba' ||
      Interjection($pPar1->{'form'},'Zrovna') eq 'Zrovna' ||
      Interjection($pPar1->{'form'},'Z�ejm�') eq 'Z�ejm�' ||
      Interjection($pPar1->{'form'},'Tak�') eq 'Tak�' ||
      Interjection($pPar1->{'form'},'Zvl�t�') eq 'Zvl�t�') {

    return;
  }

  $pPar1->{'err2'} = 'Found';

}

sub MaxDord {
  my $pAct; # used as type "pointer"

  $sReturn = "0";

  $pAct = $pPar1;

  $pPar2 = $pPar1;
loop:
  if ($sReturn<ValNo(0,$pAct->{'dord'})) {

  $sReturn = ValNo(0,$pAct->{'dord'});
  }

  $pPar1 = $pAct;

  GoNext();

  $pAct = $pReturn;

  if ($pAct) {

  goto loop;
  }

}

}
