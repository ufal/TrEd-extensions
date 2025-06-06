# -*- cperl -*-

## Contains all code of PML package, suitable to be included.
## Should be included at the very beginning of a macro file.

#encoding iso-8859-2

BEGIN { import PML_T; }

=pod

=head1 PML_T_Edit

PML_T_Edit.mak - Miscellaneous macros for editing the tectogrammatic layer
of Prague Dependency Treebank (PDT) 2.0.

=over 4

=cut

=item AddCoref(node,target,coref)

If the node does not refer to target by the coref of type C<$coref>,
make the reference, else delete the reference.

=cut

sub AddCoref {
    my ($node, $target, $coref) = @_;
    my $attr = 'coref_text' eq $coref
             ? sub { $_[0]->{'target_node.rf'} }
             : sub { $_[0] };
    if (first { $target->{id} eq $attr->($_) } ListV($node->{$coref})) {
        @{$node->{$coref}}
            = grep { $attr->($_) ne $target->{id} } ListV($node->{$coref});
    } elsif ('coref_text' eq $coref) {
        AddToList($node, $coref, {'target_node.rf' => $target->{id},
                                  type => 'SPEC'});
    } else {
        AddToList($node, $coref, $target->{id});
    }
} # AddCoref

sub value_line_click_hook {
  MouseEditLinks(1,@_);
} # value_line_click_hook

=item MouseEditLinks(ask,@_ of value_line_click_hook)

Enables changes of C<a/aur.rf> and C<a/lex.rf> by clicking on the
words of the sentence (value line).
  1. Alt + left click: makes the word the C<a/lex.rf> of the current node.
  2. Ctrl + left click: creates new son of the current node from the word.
  3. Shift + left click: adds the word to C<a/aux.rf> or removes it from linked a-nodes.

If ask is set to 1, asks for attributes for a new node.

=cut

sub MouseEditLinks {
  my ($ask,$button,$mod,$rest) = @_;
  if($button eq '1' and $mod){
    SaveUndo('Change links to a-layer');
    my ($aid) = grep /^anode:/,@$rest;
    $aid =~ s/^anode://;
    my $refid = CurrentFile()->metaData('refnames')->{adata};
    my $anode = GetANodeByID($aid);
    if($mod eq 'Alt'){
      PML_A::ANodeToALexRf($anode,$this,CurrentFile());
    }elsif($mod eq 'Control'){
      $this = NewNode($this);
      PML_A::ANodeToALexRf($anode,$this,CurrentFile());
      if($ask){
        EditFunctor() or DeleteNode() && return;
        EditNodetype() or DeleteNode() && return;
        EditAttribute($this,'is_generated') || DeleteNode() && return;
      }else{
        $this->{functor} = '---';
        $this->{nodetype} = 'complex';
        $this->{is_generated} = 1;
      }
    }elsif($mod eq 'Shift'){
      if(grep $_ eq 'current',@$rest){
        if($this->attr('a/lex.rf') eq $refid.'#'.$aid){
          delete $this->{a}{'lex.rf'};
          if($ask){
            EditTLemma() or $this->{t_lemma} = '#Gen';
          }else{
            $this->{t_lemma} = '#NewNode';
          }
        }else{ # delete from aux
          @{$this->{a}{'aux.rf'}} =
            uniq(ListSubtract($this->attr('a/aux.rf'),
                              List($refid.'#'.$aid)));
        }
      }else{ # not current
        my $before = GetAAuxNodes();
        PML_A::ANodeToAAuxRf($anode,$this,CurrentFile());
        if($before == GetAAuxNodes()) { # the number of auxes did not change, it was already here, delete it
          @{$this->{a}{'aux.rf'}} =
            uniq(ListSubtract($this->attr('a/aux.rf'),
                              List($refid.'#'.$aid)));
        }
      }
    }
    ChangingFile(1);
    Redraw();
  }
} # MouseEditLinks

sub node_release_hook {
  my ($node,$target,$mod)=@_;
  return unless $target and $mod;
  return 'stop' unless $node->parent;
  my%cortypes=(grammatical=>'coref_gram.rf',
              textual=>'coref_text',
              compl=>'compl.rf',
              );
  my $type;
  if ($mod eq 'Shift') {
    $type='grammatical';
  } elsif ($mod eq 'Control') {
    $type='textual';
  } elsif ($mod eq 'Alt') {
    $type='compl';
  }else{
    return;
  }
  return 'stop' unless $target->parent;
  AddCoref($node,$target,$cortypes{$type});
  TredMacro::Redraw_FSFile_Tree();
  $FileChanged=1;
}#node_release_hook

sub get_status_line_hook {
  my $statusline = &PML_T::get_status_line_hook;
  push @{$statusline->[0]},
    ($PML_T_Edit::remember ?
     ('   Remembered: ' => [qw(label)],
      $PML_T_Edit::remember->{t_lemma} || $PML_T_Edit::remember->{id}=> [qw(status)]
     ):'');
  push @{$statusline->[1]},("status" => [ -foreground => CustomColor('status')]);
  return $statusline;
}#get_status_line_hook

sub ChooseValFrame {
  shift unless @_ and ref($_[0]);
  my $node = shift || $this;
  my %opts = @_;
  my $refid = FileMetaData('refnames')->{vallex};

  my $fsfile = $grp->{FSFile};
  PML_T::OpenValFrameList(
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

sub AssignValencyFrames {
  my ($node,@frames)=@_;
  my $refid = FileMetaData('refnames')->{vallex};
  $node->{'val_frame.rf'} = undef;
  AddToAlt($node,'val_frame.rf',map { $refid."#".$_} @frames);
}

sub status_line_doubleclick_hook {
  status_line_doubleclick(sub{ ChooseValFrame($_[0]) },@_);
} # status_line_doubleclick_hook

=item RememberNode()

Remembers current node to be used later, e.g. with
C<text_arrow_to_remembered>.

=cut

sub RememberNode{
  $PML_T_Edit::remember=$this;
  undef %PML_T::show;
  $PML_T::show{$this->{id}}=1;
  ChangingFile(0);
}#RememberNode

sub TextArowToRemembered{
  ChangingFile(0);
  if($PML_T_Edit::remember and $PML_T_Edit::remember->parent and $this->parent){
    AddCoref($this,$PML_T_Edit::remember,'coref_text');
    ChangingFile(1);
  }
}#TextArowToRemembered

sub ForgetRemembered {
  delete $PML_T::show{$PML_T_Edit::remember->{id}};
  undef $PML_T_Edit::remember;
  ChangingFile(0);
}#ForgetRemembered

=item MarkForARf()

Enter analytical layer with current node remembered. By calling
C<PML_A_Edit::AddThisToA...> you can make links between the layers.

=cut

sub MarkForARf {
  $PML::arf=$this;
  ChangingFile(0);
  AnalyticalTree();
}#MarkForARf

sub RotateGenerated{
  $this->{is_generated}=!$this->{is_generated};
}#RotateGenerated

sub RotateMember{
  $this->{is_member}=!$this->{is_member};
}#RotateMember

sub RotateParenthesis{
  $this->{is_parenthesis}=!$this->{is_parenthesis};
}#RotateParenthesis

sub RotatePersonName {
  $this->{is_name_of_person} = ! $this->{is_name_of_person};
} # RotatePersonName

sub EditFunctor{
  ChangingFile(EditAttribute($this,'functor'));
}#EditFunctor

sub EditTfa{
  ChangingFile(EditAttribute($this,'tfa'));
}#EditTfa

sub EditTLemma{
  ChangingFile(EditAttribute($this,'t_lemma'));
}#EditTLemma

sub EditNodetype{
  ChangingFile(EditAttribute($this,'nodetype'));
}#EditNodetype

sub EditGram{
  ChangingFile(EditAttribute($this,'gram'));
}#EditGram

sub AnnotateSegm{
  if($this->{coref_special}eq'segm'){
    $this->{coref_special}='';
  }else{
    $this->{coref_special}='segm';
  }
}#AnnotateSegm

sub AnnotateExoph{
  if($this->{coref_special}eq'exoph'){
    $this->{coref_special}='';
  }else{
    $this->{coref_special}='exoph';
  }
}#AnnotateExoph

sub AddNode {
  ChangingFile(0);
  _AddNode(0);
}#AddNode

sub AddAnalyticNode {
  my $autotype=shift;
  $this=NewNode($this);
  $this->{t_lemma}='#NewNode';
  $this->{functor}='---';
  $this->{nodetype}='complex';
  $this->{is_generated}=1;
#  EditFunctor() || (DeleteNode() && return );
  unless ($autotype){
    EditNodetype()|| (DeleteNode() && return );
  }
#  EditAttribute($this,'is_generated')|| (DeleteNode() && return );
  ChangingFile(1);
  $PML::desiredcontext='PML_A_Edit';
  MarkForARf();
}#AddAnalyticNode

sub AddEntityNode {
  my $autotype=shift;
  my$dialog=[];
  my%lemmas=qw/AsMuch qcomplex
               Benef qcomplex
               Colon coap
               Comma coap
               Cor qcomplex
               Dash coap
               EmpNoun complex
               EmpVerb qcomplex
               Equal qcomplex
               Forn list
               Gen qcomplex
               Idph list
               Neg atom
               Oblfm qcomplex
               Percnt qcomplex
               Period fphr
               Period3 qcomplex
               PersPron complex
               QCor qcomplex
               Rcp qcomplex
               Separ coap
               Some qcomplex
               Total qcomplex
               Unsp qcomplex
               /;
  $lemmas{NewNode}='qcomplex'if$autotype;
  ListQuery('T-lemma',
            'browse',
            [sort keys%lemmas],
            $dialog) or return;
  $this=NewNode($this);
  $this->{functor}='PAR';
  $this->{t_lemma}='#'.$dialog->[0];
  $this->{nodetype}=$lemmas{$dialog->[0]};
  $this->{is_generated}=1;
#  EditFunctor()|| (DeleteNode() && return );
  unless ($autotype){
    EditNodetype()|| (DeleteNode() && return );
  }
  ChangingFile(1);
}#AddEntityNode

sub _AddNode {
  my $autotype=shift;
  my $type=questionQuery('New node',
                         'Type of the new node:',
                         ('Analytic','#-entity','Cancel'));
  return if$type eq'Cancel';
  if($type eq'Analytic'){
    AddAnalyticNode($autotype);
  }else{
    AddEntityNode($autotype);
  }
  ChangingFile(1);
} #_AddNode

sub MoveNodeLeft {
  return unless (GetOrd($this)>1);
  ShiftNodeLeft($this);
}

sub MoveNodeRight {
  return unless ($this->parent);
  ShiftNodeRight($this);
}

sub MoveSTLeft {
# moves the subtree of a given node one node left (with respect to all other nodes)
# (if the subtree is not contiguous, the user is asked how to proceed)
  my $top=$this;
  my @subtree=GetNodes($top);
  SortByOrd(\@subtree);
  if ( (GetOrd($subtree[-1])-GetOrd($subtree[0])) != $#subtree ) {
    return if ("No" eq questionQuery('Non-contiguous subtree',
				     'The subtree you want to move is non-contiguous. Proceed anyway?',
				     ('Yes','No')));

  };
  my $all=GetNodesExceptSubtree([$top]);
  SortByOrd($all);
  my $i=Index($all,$top);  # locate the given node in the array @all
  if ($i>1) {  # check if there is place where to move (the root is always number zero)
    splice @$all,$i,1;  # cut out the given node
    splice @$all,$i-1,0, @subtree;  # splice the projectivized subtree at the right (ie left ;-) place
  }
  else {
    splice @$all,$i,1, @subtree;  # if there is no room where to move, just splice the proj. subtree
                                 # instead of the given node - thus the subtree gets projectivized
  }
  NormalizeOrds($all);  # the ordering attributes are modified accordingly
}

sub MoveSTRight {
# moves the subtree of a given node one node right (with respect to all other nodes)
# (if the subtree is not contiguous, the user is asked how to proceed)
  my $top=$this;
  my @subtree=GetNodes($top);
  SortByOrd(\@subtree);
  if ( (GetOrd($subtree[-1])-GetOrd($subtree[0])) != $#subtree ) {
    return if ("No" eq questionQuery('Non-contiguous subtree',
				     'The subtree you want to move is non-contiguous. Proceed anyway?',
				     ('Yes','No')));

  };
  my $all=GetNodesExceptSubtree([$top]);
  SortByOrd($all);
  my $i=Index($all,$top);  # locate the given node in the array @all
  if ($i<$#$all) {  # check if there is place where to move
    splice @$all,$i,1;  # cut out the given node
    splice @$all,$i+1,0, @subtree;  # splice the projectivized subtree at the right (ie left ;-) place
  }
  else {
    splice @$all,$i,1, @subtree;  # if there is no room where to move, just splice the proj. subtree
                                 # instead of the given node - thus the subtree gets projectivized
  }
  NormalizeOrds($all);  # the ordering attributes are modified accordingly
}

=back

=cut
