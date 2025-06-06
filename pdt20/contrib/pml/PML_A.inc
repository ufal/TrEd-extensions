# -*- cperl -*-

## Contains all code of PML package, suitable to be included.
## Should be included at the very beginning of a macro file.

#encoding iso-8859-2

BEGIN { import PML; }

sub detect {
  return (((SchemaName() // "") =~ /^a(?:edit)?data$/) ? 1 : 0);
}

sub allow_switch_context_hook {
  return 'stop' unless detect();
}

=pod

=head1 PML_A

PML_A.mak - Miscellaneous macros for the analytic layer of Prague
Dependency Treebank (PDT) 2.0.

=over 4

=cut


#ifdef TRED

=item TectogrammaticalTree()

This function is only available in TrEd (i.e. in GUI). After a
previous call to C<AnalyticalTree>, it switches current view back to
a tectogrammatical tree which refers to the current analytical tree.

=cut

sub TectogrammaticalTree {
  return unless SchemaName() =~ /^a(?:edit)?data$/;
  return unless SwitchToTFile();
  my $arf = $PML::arf;
  my $fsfile = $grp->{FSFile};
  my $id = $root->{id};
  my $this_id = $this->{id};
  if ($PML::desiredcontext=~/^PML_(?:.*_)?T_/){
    SwitchContext($PML::desiredcontext);
  }elsif (CurrentContext() eq 'PML_A_Edit') {
    SwitchContext('PML_T_Edit');
  } else {
    SwitchContext('PML_T_View');
  }
  undef $PML::desiredcontext;
  SetCurrentStylesheet($PML_T::laststylesheet || 'PML_T_Compact');
  undef $PML_T::laststylesheet;
  if(ref $arf){
    $this=$grp->{currentNode};
    my($node,$treeno)=SearchForNodeById($arf->{id});
    TredMacro::GotoTree($treeno);
    $this=$node;
  }else{
    #find current tree and new $this
    my $trees = $fsfile->treeList;
    # low-level stuff here
    my $treeNo = $fsfile->currentTreeNo+0;
  TREE: for (my $i=0;$i<=$#$trees;$i++) {
      foreach my $a_rf (PML_T::GetANodeIDs($trees->[$i])) {
        $a_rf =~ s/^.*\#//;
        if ($a_rf eq $id) {
          $treeNo = $i;
          last TREE;
        }
      }
    }
    TredMacro::GotoTree($treeNo+1); # changes $root
    my $node=$root;
    while ($node) {
      if (first { $_ eq $this_id } PML_T::GetANodeIDs($node)) {
        $this = $node;
        last;
      }
    } continue {
      $node = $node->following;
    };
  }
  ChangingFile(0);
  1;
}

sub SwitchToTFile {
  my $fsfile = $grp->{FSFile};
  return 0 unless $fsfile or SchemaName() !~ /^a(?:edit)?data$/;
  my $tr_fs = $fsfile->appData('tdata');
  return 0 unless ref($tr_fs);
  $grp->{FSFile} = $tr_fs;
  return 1;
}

# sub file_resumed_hook {
#   if (SchemaName() eq 'tdata') {
#     SetCurrentStylesheet(STYLESHEET_FROM_FILE());
#     if (CurrentContext() eq 'PML_A_Edit') {
#       SwitchContext('PML_T_Edit');
#     } else {
#       SwitchContext('PML_T_View');
#     }
#   } else {
#     &TredMacro::file_resumed_hook;
#   }
# }

#endif TRED

=item GetCoordMembers($node,$no_recurse)

If the given node is coordination or apposition (i.e. its C<afun> is C<Coord>
or C<Apos>) return a list of the corresponding coordination members
(nodes with C<is_member> flag set). Otherwise return the node itself.

Unless C<$no_recurse> is true, the function is recursively applied to
those members that are themselves C<Coord> or C<Apos>.

This function differs from L<ExpandCoord> in handling coordination
members below C<AuxP> and C<AuxC>. While this function returns the
nodes with the C<is_member> flag (i.e. the nodes below C<AuxP> and
C<AuxC>), L<ExpandCoord> returns the C<AuxP> and C<AuxC> nodes above
them.

=cut

sub GetCoordMembers {
  my ($node,$no_recurse)=@_;
  return unless $node;
  if ($node->{afun}=~/Coord|Apos/) {
    return map { $no_recurse ? $_ : GetCoordMembers($_) }
           map { GetMember($_) }
	     $node->children;
  } else {
    return ($node);
  }
}

=item GetMember($node)

This is a helper function used to identify and reach the actual
coordination or apposition members (carrying C<is_member> flag) from
child nodes of a C<Coord> or C<Apos>.

Given a node, return it if its C<is_member> attribute is 1.
If its C<afun> is C<AuxC> or C<AuxP>, recurse to the child nodes.
In all other cases return an empty list.

=cut

sub GetMember {
  my $node = shift;
  return unless $node;
  return ($node) if $node->{is_member};
  if ($node->{afun}=~/^Aux[CP]/) {
    return map { (GetMember($_)) } $node->children;
  }
  return;
}

=item ExpandCoord($node,$keep?)

If the given node is coordination or apposition (according to its
Analytical function - attribute C<afun>) expand it to a list of
coordinated nodes. Otherwise return the node itself. If the argument
C<keep> is true, include the coordination/apposition node in the list
as well.

This function differs from L<GetCoordMembers> in handling coordination
members below C<AuxP> and C<AuxC>. Unlike the latter, it returns the
C<AuxP> and C<AuxC> nodes above the actual coordination members.

=cut

sub ExpandCoord {
  my ($node,$keep)=@_;
  return unless $node;
  if ($node->{afun}=~/Coord|Apos/) {
    return (($keep ? $node : ()),
	    map { ExpandCoord($_,$keep) }
	    grep { IsMember($_) } $node->children);
  } else {
    return ($node);
  }
} #ExpandCoord

=item IsMember($node)

This is a helper function used to identify coordination or apposition
members among child nodes of a Coord or Apos. It returns 1 if the
given node has C<is_member>=1 or if it has C<afun>=C<AuxC> or C<AuxP>
and a child node for which IsMember (recursively called) returns 1. If
neither of these two conditions is met, the function returns 0.

=cut

sub IsMember {
  my $node = shift;
  return 
    ($node->{is_member} or
       $node->{afun}=~/^Aux[CP]/ and first { IsMember($_) } $node->children)
      ? 1 : 0;
}

=item GetSentenceString($tree?)

Return string representation of the given tree (suitable for
Analytical trees).

=cut

sub GetSentenceString {
  my $node = $_[0]||$this;
  $node=$node->root->following;
  my @sent=();
  while ($node) {
    push @sent,$node;
    $node=$node->following();
  }
  return join('',map{
    $_->attr('m/form').($_->attr('m/w/no_space_after')?'':' ')
  } sort { $a->{ord} <=> $b->{ord} } @sent);
}#GetSentenceString

=item DiveAuxCP($node)

You can use this function as a C<through> argument to GetEParents and
GetEChildren. It skips all the prepositions and conjunctions when
looking for nodes which is what you usually want.

=cut

sub DiveAuxCP ($){
  $_[0]->{afun}=~/^Aux[CP]/ ? 1 : 0;
}#DiveAuxCP

=item GetEParents($node,$through)

Return linguistic parent of a given node as appears in an analytic
tree. The argument C<$through> should supply a function accepting one
node as an argument and returning true if the node should be skipped
on the way to parent or 0 otherwise. The most common C<DiveAuxCP> is
provided in this package.

=cut

sub _ExpandCoordGetEParents { # node through
  my ($node,$through)=@_;
  my @toCheck = $node->children;
  my @checked;
  while (@toCheck) {
    @toCheck=map {
      if (&$through($_)) { $_->children() }
      elsif($_->{afun}=~/Coord|Apos/&&$_->{is_member}){ _ExpandCoordGetEParents($_,$through) }
      elsif($_->{is_member}){ push @checked,$_;() }
      else{()}
    }@toCheck;
  }
  return @checked;
}# _ExpandCoordGetEParents

sub GetEParents { # node through
  my ($node,$through)=@_;
  my $init_node = $node; # only used for reporting errors
  return() if !$node or $node->{afun}=~/^(?:Coord|Apos|Aux[SCP])$/;
  if ($node->{is_member}) { # go to coordination head
    while ($node->{afun}!~/Coord|Apos|AuxS/ or $node->{is_member}) {
      $node=$node->parent;
      if (!$node) {
	print STDERR
	  "GetEParents: Error - no coordination head $init_node->{AID}: ".ThisAddress($init_node)."\n";
        return();
      } elsif($node->{afun}eq'AuxS') {
	print STDERR
	  "GetEParents: Error - no coordination head $node->{AID}: ".ThisAddress($node)."\n";
        return();
      }
    }
  }
  if (&$through($node->parent)) { # skip 'through' nodes
    while ($node and &$through($node->parent)) {
      $node=$node->parent;
    }
  }
  return unless $node;
  $node=$node->parent;
  return unless $node;
  return $node if $node->{afun}!~/Coord|Apos/;
  _ExpandCoordGetEParents($node,$through);
} # GetEParents

=item GetEChildren($node,$dive)

Return a list of nodes linguistically dependant on a given
node. C<$dive> is a function which is called to test whether a given
node should be used as a terminal node (in which case it should return
false) or whether it should be skipped and its children processed
instead (in which case it should return true). Most usual treatment is
provided in C<DiveAuxCP>. If C<$dive> is skipped, a function returning 0
for all arguments is used.

=cut

sub _FilterEChildren{ # node dive suff from
  my ($node,$dive,$suff,$from)=@_;
  my @sons;
  $node=$node->firstson;
  while ($node) {
#    return @sons if $suff && @sons; # comment this line to get all members
    unless ($node==$from){ # on the way up do not go back down again
      if (!$suff&&$node->{afun}=~/Coord|Apos/&&!$node->{is_member}
	  or$suff&&$node->{afun}=~/Coord|Apos/&&$node->{is_member}) {
	push @sons,_FilterEChildren($node,$dive,1,0)
      } elsif (&$dive($node) and $node->firstson){
	push @sons,_FilterEChildren($node,$dive,$suff,0);
      } elsif(($suff&&$node->{is_member})
	      ||(!$suff&&!$node->{is_member})){ # this we are looking for
	push @sons,$node;
      }
    } # unless node == from
    $node=$node->rbrother;
  }
  @sons;
} # _FilterEChildren

sub GetEChildren{ # node dive
  my ($node,$dive)=@_;
  return() if !$node or $node->{afun}=~/^(?:Coord|Apos|Aux[SCP])$/;
  my @sons;
  my $from;
  $dive = sub { 0 } unless defined($dive);
  push @sons,_FilterEChildren($node,$dive,0,0);
  if($node->{is_member}){
    my @oldsons=@sons;
    while($node->{afun}!~/Coord|Apos|AuxS/ or $node->{is_member}){
      $from=$node;$node=$node->parent;
      push @sons,_FilterEChildren($node,$dive,0,$from);
    }
    if ($node->{afun}eq'AuxS'){
      print STDERR "Error: Missing Coord/Apos: $node->{id} ".ThisAddress($node)."\n";
      @sons=@oldsons;
    }
  }
  return@sons;
} # GetEChildren

=item ANodeToALexRf(a_node,t_node,t_file)

Adds given a-node's C<id> to C<a/lex.rf> of the given t-node and
adjusts C<t_lemma> of the t-node accordingly. The third argument
t_file specifies the C<Treex::PML::Document> object to which the given t-node
belongs.

=cut

sub ANodeToALexRf {
  my ($a_node,$t_node,$t_file)=@_;
  return unless ref($t_node) && ref($a_node) && ref($t_file);
  my $refid = $t_file->metaData('refnames')->{adata};
  $t_node->set_attr('a/lex.rf',$refid."#".$a_node->{id});
  $t_node->set_attr('a/aux.rf',List(grep{ $_ ne $refid."#".$a_node->{id} }
    uniq(ListV($t_node->attr('a/aux.rf')))));
  my$lemma=$a_node->attr('m/lemma');
  my%specialEntity;
  %specialEntity=('.' => 'Period',
                  ',' => 'Comma',
                  '&amp;' => 'Amp',
		  '&' => 'Amp',
		  '-' => 'Dash',
		  '/' => 'Slash',
		  '(' => 'Bracket',
		  ')' => 'Bracket',
		  ';' => 'Semicolon',
		  ':' => 'Colon',
		  '&ast;' => 'Ast',
		  '*' => 'Ast',
		  '&verbar;' => 'Verbar',
		  '|' => 'Verbar',
		  '&percnt;' => 'Percnt',
		  '%' => 'Percnt',
		 );
  if($lemma=~/^.*`([^0-9_-]+)/){
    $lemma=$1;
  }else{
    $lemma=~s/(.+?)[-_`].*$/$1/;
    if($lemma =~/^(?:(?:[ts]v|m)�j|j�|ty|jeho|se)$/){
      $lemma='#PersPron';
    }
    $lemma="#$specialEntity{$lemma}"if exists$specialEntity{$lemma};
  }
  $t_node->{'t_lemma'}=$lemma;
} #ANodeToALexRf

=item ANodeToAAuxRf(a_node,t_node,t_file)

Appends given a-node's C<id> to C<a/aux.rf> of the given t-node. The
third argument t_file specifies the C<Treex::PML::Document> object to which the
given t-node belongs.

=cut

sub ANodeToAAuxRf {
  my ($a_node,$t_node,$t_file)=@_;
  return unless $t_node && $a_node;
  return unless ref($t_file);
  my $refid = $t_file->metaData('refnames')->{adata};
  AddToListUniq($t_node,'a/aux.rf',$refid.'#'.$a_node->{id});
  delete $t_node->{a}{'lex.rf'}
    if $t_node->attr('a/lex.rf')eq$refid.'#'.$a_node->{id};
}#ANodeToAAuxRf



=item CreateStylesheets()

Creates default stylesheet for PML analytical files unless already
defined. Most of the colors it uses can be redefined in the tred
config file C<.tredrc> by adding a line of the form

  CustomColorsomething = ...

The stylesheet is named C<PML_A> and it has the following display
features:

=over 4

=item 1.

sentence is displayed in C<CustomColorsentence>. If the form was
changed (e.g. because of a typo), the original form is displayed in
C<CustomColorspell> with overstrike.

=item 2.

analytical function is displayed in C<CustomColorafun>. If the
node's C<is_member> is set to 1, the type of the structure is
indicated by C<Co> (coordination) or C<Ap> (apposition) in
C<CustomColorcoappa>. For C<is_parenthesis_root>, C<Pa> is displayed
in the same color.

=back

=cut

sub CreateStylesheets {
  unless(StylesheetExists('PML_A')){
    SetStylesheetPatterns(<<'EOF','PML_A',1);
context: PML.*_A.*
rootstyle: #{NodeLabel-skipempty:1}
text:<? $${m/w/token}eq$${m/form} ? 
  '#{'.CustomColor('sentence').'}${m/w/token}' : 
  '#{-over:1}#{'.CustomColor('spell').'}['.
     join(" ",map { $_->{token} } ListV($this->attr('m/w'))).
  ']#{-over:0}#{'.CustomColor('sentence').'}${m/form}' ?>

node:<? $${afun} eq "AuxS" ? '${id}' : '${m/form}' ?>

node:<?
(($${afun} eq q{}) or
($${afun}=~/^Apos|^Coord/ and PML_A::ExpandCoord($this)==0))
 ? '#{customerror}!!'
 : '#{customafun}'
?>${afun}<?
  if ($${is_member}) {
    my $p=$this->parent;
    $p=$p->parent while $p and $p->{afun}=~/^Aux[CP]$/;
    ($p and $p->{afun}=~/^(Ap)os|(Co)ord/ ? "_#{customcoappa}\${is_member=$1$2}" : "_#{customerror}\${is_member=ERR}")
  } else { "" }
?><? $${is_parenthesis_root} ? '#{customcoappa}_${is_parenthesis_root=Pa}' : '' ?>

hint: m/lemma: ${m/lemma}
m/tag: ${m/tag}<? 
  $${m/form_change} ? "\n".'m/form_change: ${m/form_change}' : '' ?>
EOF
  }
}

sub get_status_line_hook {
  # get_status_line_hook may either return a string
  # or a pair [ field-definitions, field-styles ]
  return unless $this;
  return [
	  # status line field definitions ( field-text => [ field-styles ] )
	  [
	   "     id: " => [qw(label)],
	   $this->{id} => [qw({id} value)],
           ($this->parent
            ?
            ("     m/lemma: " => [qw(label)],
             $this->attr('m/lemma') => [qw({m/lemma} value)],
             "     m/tag: " => [qw(label)],
             $this->attr('m/tag') => [qw({m/tag} value)])
            :()),
	  ],

	  # field styles
	  [
	   "label" => [-foreground => 'black' ],
	   "value" => [-underline => 1 ],
	  ]
	 ];
}

sub switch_context_hook {
  CreateStylesheets();
  my $cur_stylesheet = GetCurrentStylesheet();
  SetCurrentStylesheet('PML_A')
    if $cur_stylesheet eq STYLESHEET_FROM_FILE() or
       $cur_stylesheet =~ /^PML_(?:\w+_)?[^A](?:_|\b)/;
}


sub OpenValFrameList {
  shift unless @_ and ref($_[0]);
  my $node = shift || $this;
  my %opts = @_;

  local $ValLex::GUI::frameid_attr=undef;
  local $ValLex::GUI::lemma_attr=undef;
  local $ValLex::GUI::framere_attr=undef;
  local $ValLex::GUI::sempos_attr=undef;
  my $pos = substr($node->attr('m/tag'),0,1);
  return unless ($pos=~/[NVAD]/);

  my $lemma = $node->attr('m/lemma');

  # this is specific for czech
  $lemma =~ s/[_\`&].*$//;
  my $se = first { $_->{afun} eq 'AuxT' } GetEChildren($node,\&DiveAuxCP);
  if ($se) {
    $lemma .= $se->attr('m/tag')=~/^P7-X3/ ? '_si' : '_se';
  }

  ValLex::GUI::ChooseFrame({
    -lemma => $lemma,
    -pos => $pos,
    -assignfunc => sub{},
    %opts
   });
  ChangingFile(0);
}

=back

=cut

