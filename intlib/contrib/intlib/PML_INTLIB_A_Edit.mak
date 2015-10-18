# -*- cperl -*-

#ifndef PML_INTLIB_A_Edit
#define PML_INTLIB_A_Edit

#include <contrib/pml/PML_A.mak>

package PML_INTLIB_A_Edit;

#binding-context PML_INTLIB_A_Edit

#encoding iso-8859-2

BEGIN { import PML_A; }

=pod

=head1 PML_INTLIB_A_Edit

PML_ITNLIB_A_Edit.mak - Miscellaneous macros for editing the analytic
layer of INTLIB project.

=over 4

=cut

#bind cut_to_clipboard to CTRL+Insert menu Cut
sub cut_to_clipboard {
    return if ( !$this || !$this->parent );

    my $parent = $this->parent();
    FileUserData('spy_move_original_id', $parent->attr('id'));
    FileUserData('spy_move_original_form', $parent->attr('m/form'));
    
    $TredMacro::nodeClipboard = $this;
    $this = $this->rbrother ? $this->rbrother : $this->parent;
    CutNode($TredMacro::nodeClipboard);
    return;
}

#bind paste_from_clipboad to Shift+Insert menu Paste subtree
sub paste_from_clipboad {
    return unless ($this and $TredMacro::nodeClipboard);

    PasteNode($TredMacro::nodeClipboard, $this);
    $this = $TredMacro::nodeClipboard;
    $TredMacro::nodeClipboard = undef;

    my $id = FileUserData('spy_move_original_id');
    my $mform = FileUserData('spy_move_original_form');
    my $currentparent = $this->parent();

    $this->{spy_move} .= " ($id;$mform -> $currentparent->{id};" . $currentparent->attr('m/form') . ")";
}

unshift @TredMacro::AUTO_CONTEXT_GUESSING, sub {
    my ($hook)=@_;
    my $current = CurrentContext();

    if ((FileMetaData('schema-url') || '') =~ /intlib/) {
	return 'PML_INTLIB_A_Edit';
    }

    return;
};

sub intlib_file_detected {
    if (((PML::SchemaName() || '') eq 'adata') and
        ((PML::SchemaDescription() || '') =~ /\bINTLIB\b/)) {
	return 1;
    }

    return;
}

sub node_moved_hook {
    my ($node, $oldparent) = @_;
    my $currentparent = $node->parent();

    $node->{spy_move} .= " ($oldparent->{id};" . $oldparent->attr('m/form') . "-> $currentparent->{id};" . $currentparent->attr('m/form') . ")";
    print STDERR "MOVE($oldparent->{id};" . $oldparent->attr('m/form') . "-> $currentparent->{id};" . $currentparent->attr('m/form') . ")\n";
}

sub file_opened_hook {
    print STDERR "file_opened_hook(@_)\n";

    if (intlib_file_detected()) {
        SwitchContext('PML_INTLIB_A_Edit');
        return 1;
    }

    return 'stop';
}

## Zapamatam si povodnu hodnotu afun...
sub do_edit_node_hook {
    my ($node) = @_;

    FileUserData('original_afun', $node->{afun});
}

## Ak sa afun zmenila, zapisem si to...
sub after_edit_node_hook {
    my ($node, $result) = @_;

    if (!$result) {
	return 1;
    }

    my $original_afun = FileUserData('original_afun') ? FileUserData('original_afun') : "";
    if ($original_afun ne $node->{afun}) {
	$node->{spy_afun} .= " ($original_afun -> $node->{afun})";
    }

    return 1;
}

sub allow_switch_context_hook {
    if (intlib_file_detected()) {
	return 1;
    }

    return 'stop';
}

sub get_status_line_hook {
  my $statusline=&PML_A::get_status_line_hook;
  push @{$statusline->[0]},
    ($PML::arf ?
           ('   Changing a.lex of: ' => [qw(label)],
            $PML::arf->{t_lemma} || $PML::arf->{id}=> [qw(status)]
           ):()
    );
  push @{$statusline->[1]},("status" => [ -foreground => CustomColor('status')]);
  return $statusline;
}#get_status_line_hook

sub status_line_doubleclick_hook {
  # status-line field double clicked

  # @_ contains a list of style names associated with the clicked
  # field. Style names may obey arbitrary user-defined convention.

  foreach (@_) {
    if (/^\{(.*)}$/) {
      if (EditAttribute($this,$1)) {
        ChangingFile(1);
        Redraw_FSFile();
      }
      last;
    }
  }
}

#bind remember_actual_node to space menu Remember the actual node
sub remember_actual_node {
    FileUserData('remembered_node.rf', $this->{id});
    FileUserData('remembered_node.lemma', $this->attr('m/lemma'));
    FileUserData('remembered_node.tree', CurrentTreeNumber());
    
    print "LEMMA: " . $this->attr('m/lemma') . "\n";
}

#bind put_remembered_node to Ctrl+space menu Use remembered node
sub put_remembered_node {
    $this->{'co_parent.rf'} = FileUserData('remembered_node.rf');
    $this->{'co_parent.lemma'} = FileUserData('remembered_node.lemma');
    $this->{'co_parent.tree'} = FileUserData('remembered_node.tree');
}

#bind clean_co_parent_node to Shift+space menu Use remembered node
sub clean_co_parent_node {
    $this->{'co_parent.rf'} = '';
    $this->{'co_parent.lemma'} = '';
    $this->{'co_parent.tree'} = '';
}

#bind show_co_parent_tree to Ctrl+m menu Show Tree With COParent Node
sub show_co_parent_tree {
    ## Ak nemame cislo stromu, nic nerobit...
    if ($this->{'co_parent.tree'} !~ /^\d+$/) {
	return "";
    }

    ## Zapamatam si moje aktualne okno, do neho sa musim vratit 
    my $CurrentWindow = CurrentWindow();
    FileUserData('remembered_window', $CurrentWindow);

    ## Splitnem a focusnem nove okno.
    ## Nahrajem don pozadovany strom
    my $Window = SplitWindowVertically();
    SetCurrentWindow($Window);
    TredMacro::GotoTree($this->{'co_parent.tree'} + 1);
    FileUserData('remembered_co_parent_window', $Window);
}

#bind close_co_parent_tree to Ctrl+g menu Close Tree With COParent Node
sub close_co_parent_tree {
    my $WindowToClose = FileUserData('remembered_co_parent_window');
    SetCurrentWindow(FileUserData('remembered_window'));
    CloseWindow($WindowToClose);
}

=item CreateStylesheets()

Creates default stylesheet for PML analytical files unless already
defined. Most of the colors it uses can be redefined in the tred
config file C<.tredrc> by adding a line of the form

  CustomColorsomething = ...

The stylesheet is named C<PML_A> and it has the following display
features:

=over 4

=item 1.

If the node's C<is_member> is set to 1, the type of the structure is
indicated by C<Co> (coordination) or C<Ap> (apposition) in
C<CustomColorcoappa>. For C<is_parenthesis_root>, C<Pa> is displayed
in the same color.

=back

=cut

sub CreateStylesheets {
#    if (StylesheetExists('PML_INTLIB_A')) {
#	return;
#    }
    
    SetStylesheetPatterns(<<'EOF','PML_INTLIB_A',1);
context: PML.*_A.*
rootstyle: #{NodeLabel-skipempty:1}
style:<? if ($this->{'co_parent.rf'}) {
	    '#{Oval-fill:#AA00FF}'
	}
?>
text:<? ($${m/w/token} eq $${m/form}) ? '#{' . CustomColor('sentence') . '}${m/w/token}' : '#{-over:1}#{' . CustomColor('spell') . '}[' . join(" ", map{ $_->{token}} ListV($this->attr('m/w'))). ']#{-over:0}#{' . CustomColor('sentence') . '}${m/form}' ?>
node:<? $${afun} eq "AuxS" ? '${id}' : '${m/form}' ?>
node:<? (($${afun} eq q{}) or ($${afun}=~/^Apos|^Coord/ and PML_A::ExpandCoord($this) == 0)) ? '#{customerror}!!' : '#{customafun}' ?>${afun}<?
  if ($${is_member}) {
    my $p = $this->parent;
    $p = $p->parent while ($p and $p->{afun}=~/^Aux[CP]$/);
    if ($p and $p->{afun} =~ /^(Ap)os|(Co)ord/) {
	"_#{customcoappa}\${is_member=$1$2}"
    }
    else {
	if ($this->{'co_parent.rf'}) {
	    "_#{customcoappa}\${is_member=Co}"
        }
        else {
	    "_#{customerror}\${is_member=Err}"
        }
    }
  }
  else {
    ""
  }
?><? $${is_parenthesis_root} ? '#{customcoappa}_${is_parenthesis_root=Pa}' : '' ?>
node:<? ($this->{'co_parent.lemma'} ? "#{customerror}Co_Parent: " . $this->{'co_parent.lemma'} : "") ?>
hint: m/lemma: ${m/lemma}
m/tag: ${m/tag}<? $${m/form_change} ? "\n".'m/form_change: ${m/form_change}' : '' ?>
EOF
}

sub switch_context_hook {
  CreateStylesheets();
  my $cur_stylesheet = GetCurrentStylesheet();
  SetCurrentStylesheet('PML_INTLIB_A');
    #if $cur_stylesheet eq STYLESHEET_FROM_FILE() or
    #   $cur_stylesheet =~ /^PML_(?:\w+_)?[^A](?:_|\b)/;
}

=item AddThisToALexRf()

If called from analytical tree entered through
C<PML_T_Edit::MarkForARf>, adds this node's C<id> to C<a/lex.rf> list
of the marked tectogrammatical node.

=cut

#bind AddThisToALexRf to Ctrl+plus menu Add This to a/lex.rf of Marked Node
#bind AddThisToALexRf to Ctrl+KP_Add
sub AddThisToALexRf {
  ChangingFile(0);
  my $tr_fs = $grp->{FSFile}->appData('tdata');
  ANodeToALexRf($this,$PML::arf,$tr_fs);
  $tr_fs->notSaved(1);
}#AddThisToALexRf

=item AddThisToAAuxRf()

If called from analytical tree entered through
C<PML_T_Edit::MarkForARf>, adds this node's C<id> to C<a/aux.rf> list
of the marked tectogrammatical node.

=cut

#bind AddThisToAAuxRf to + menu Add This to a/aux.rf of Marked Node
sub AddThisToAAuxRf {
  ChangingFile(0);
  my $tr_fs = $grp->{FSFile}->appData('tdata');
  ANodeToAAuxRf($this,$PML::arf,$tr_fs);
  $tr_fs->notSaved(1);
}#AddThisToAAuxRf

=item RemoveThisFromARf()

If called from analytical tree entered through
C<PML_T_Edit::MarkForARf>, remove this node's C<id> from C<a/lex.rf>
and C<a/aux.rf> of the marked tectogrammatical node.

=cut

#bind RemoveThisFromARf to minus menu Remove This from a/*.rf of Marked Node
#bind RemoveThisFromARf to KP_Subtract
sub RemoveThisFromARf {
  ChangingFile(0);
  return unless $PML::arf;
  my $tr_fs = $grp->{FSFile}->appData('tdata');
  return 0 unless ref($tr_fs);
  my $refid = $tr_fs->metaData('refnames')->{adata};
  if($PML::arf->attr('a/lex.rf')eq$refid.'#'.$this->{id}){
    delete $PML::arf->{a}{'lex.rf'};
  }
  @{$PML::arf->{a}{'aux.rf'}}
    =uniq(ListSubtract($PML::arf->{a}{'aux.rf'},List($refid.'#'.$this->{id})));
  $tr_fs->notSaved(1);
}#RemoveThisFromARf

# #bind EditMLemma to L menu Edit morphological lemma
# sub EditMLemma{
  # ChangingFile(EditAttribute($this,'m/lemma'));
# }#EditMlemma

# #bind EditMTag to T menu Edit morphological tag
# sub EditMTag{
  # ChangingFile(EditAttribute($this,'m/tag'));
# }#EditMtag

# #bind EditAfun to a menu Edit afun
# sub EditAfun{
  # ChangingFile(EditAttribute($this,'afun'));
# }#EditAfun

# #bind RotateMember to m menu Change is_member
# sub RotateMember{
  # $this->{is_member}=!$this->{is_member};
# }#RotateMember

# #bind RotateParenthesisRoot to p menu Change is_parenthesis_root
# sub RotateParenthesisRoot{
  # $this->{is_parenthesis_root}=!$this->{is_parenthesis_root};
# }#RotateParenthesisRoot

sub AfunAssign {
    if ($this == $root) {
	return 1;
    }

    ## NEW: Log into spy_afun
    $this->{spy_afun} .= " ($this->{afun} -> $_[0])";

    ## Change afun and move to next node
    $this->{afun} = $_[0];
    $this = $this->following;
}

## 2013-07-08 (VK)
## Pridavam makro na editaciu komentara
#bind EditComment to Alt+c menu Edit comment
sub EditComment {
    EditAttribute($this, "comment");
}

# #bind AssignPred to P menu AssignPred
# sub AssignPred{
    # AfunAssign('Pred')
# }
#
########################################################################

#bind AssignPred to q menu AssignPred
sub AssignPred {
  AfunAssign('Pred');
}
#bind AssignPnom to n menu AssignPnom
sub AssignPnom {
  AfunAssign('Pnom');
}
#bind AssignAuxV to v menu AssignAuxV
sub AssignAuxV {
  AfunAssign('AuxV');
}
#bind AssignSb to s menu AssignSb
sub AssignSb {
  AfunAssign('Sb');
}
#bind AssignObj to b menu AssignObj
sub AssignObj {
  AfunAssign('Obj');
}
#bind AssignAtr to a menu AssignAtr
sub AssignAtr {
  AfunAssign('Atr')
}
#bind AssignAdv to d menu AssignAdv
sub AssignAdv {
  AfunAssign('Adv');
}
#bind AssignCoord to i menu AssignCoord
sub AssignCoord {
  AfunAssign('Coord');
}
#bind AssignAuxT to t menu AssignAuxT
sub AssignAuxT {
  AfunAssign('AuxT');
}
#bind AssignAuxR to r menu AssignAuxR
sub AssignAuxR {
  AfunAssign('AuxR');
}
#bind AssignAuxP to p menu AssignAuxP
sub AssignAuxP {
  AfunAssign('AuxP');
}
#bind AssignApos to u menu AssignApos
sub AssignApos {
  AfunAssign('Apos');
}
#bind AssignAuxC to c menu AssignAuxC
sub AssignAuxC {
  AfunAssign('AuxC');
}
#bind AssignAuxO to o menu AssignAuxO
sub AssignAuxO {
  AfunAssign('AuxO');
}
#bind AssignAtv to h menu AssignAtv
sub AssignAtv {
  AfunAssign('Atv');
}
#bind AssignAtvV to j menu AssignAtvV
sub AssignAtvV {
  AfunAssign('AtvV');
}
#bind AssignAuxZ to z menu AssignAuxZ
sub AssignAuxZ {
  AfunAssign('AuxZ');
}
#bind AssignAuxY to y menu AssignAuxY
sub AssignAuxY {
  AfunAssign('AuxY');
}
#bind AssignAuxG to g menu AssignAuxG
sub AssignAuxG {
  AfunAssign('AuxG');
}
#bind AssignAuxK to k menu AssignAuxK
sub AssignAuxK {
  AfunAssign('AuxK');
}
#bind AssignAuxX to x menu AssignAuxX
sub AssignAuxX {
  AfunAssign('AuxX');
}
#bind AssignExD to e menu AssignExD
sub AssignExD {
  AfunAssign('ExD');
}
# #bind AssignPred_Co to Ctrl+q menu AssignPred_Co
# sub AssignPred_Co {
#   AfunAssign('Pred_Co');
# }
# #bind AssignPnom_Co to Ctrl+n menu AssignPnom_Co
# sub AssignPnom_Co {
#   AfunAssign('Pnom_Co');
# }
# #bind AssignAuxV_Co to Ctrl+v menu AssignAuxV_Co
# sub AssignAuxV_Co {
#   AfunAssign('AuxV_Co');
# }
# #bind AssignSb_Co to Ctrl+s menu AssignSb_Co
# sub AssignSb_Co {
#   AfunAssign('Sb_Co');
# }
# #bind AssignObj_Co to Ctrl+b menu AssignObj_Co
# sub AssignObj_Co {
#   AfunAssign('Obj_Co');
# }
# #bind AssignAtr_Co to Ctrl+a menu AssignAtr_Co
# sub AssignAtr_Co {
#   AfunAssign('Atr_Co');
# }
# #bind AssignAdv_Co to Ctrl+d menu AssignAdv_Co
# sub AssignAdv_Co {
#   AfunAssign('Adv_Co');
# }
# #bind AssignCoord_Co to Ctrl+i menu AssignCoord_Co
# sub AssignCoord_Co {
#   DepSuffix('Coord_Co');
# }
# #bind AssignAuxT_Co to Ctrl+t menu AssignAuxT_Co
# sub AssignAuxT_Co {
#   AfunAssign('AuxT_Co');
# }
# #bind AssignAuxR_Co to Ctrl+r menu AssignAuxR_Co
# sub AssignAuxR_Co {
#   AfunAssign('AuxR_Co');
# }
# #bind AssignAuxP_Co to Ctrl+p menu AssignAuxP_Co
# sub AssignAuxP_Co {
#   AfunAssign('AuxP_Co');
# }
# #bind AssignApos_Co to Ctrl+u menu AssignApos_Co
# sub AssignApos_Co {
#   DepSuffix('Apos_Co');
# }
# #bind AssignAuxC_Co to Ctrl+c menu AssignAuxC_Co
# sub AssignAuxC_Co {
#   AfunAssign('AuxC_Co');
# }
# #bind AssignAuxO_Co to Ctrl+o menu AssignAuxO_Co
# sub AssignAuxO_Co {
#   AfunAssign('AuxO_Co');
# }
# #bind AssignAtv_Co to Ctrl+h menu AssignAtv_Co
# sub AssignAtv_Co {
#   AfunAssign('Atv_Co');
# }
# #bind AssignAtvV_Co to Ctrl+j menu AssignAtvV_Co
# sub AssignAtvV_Co {
#   AfunAssign('AtvV_Co');
# }
# #bind AssignAuxZ_Co to Ctrl+z menu AssignAuxZ_Co
# sub AssignAuxZ_Co {
#   AfunAssign('AuxZ_Co');
# }
# #bind AssignAuxY_Co to Ctrl+y menu AssignAuxY_Co
# sub AssignAuxY_Co {
#   AfunAssign('AuxY_Co');
# }
# #bind AssignAuxG_Co to Ctrl+g menu AssignAuxG_Co
# sub AssignAuxG_Co {
#   AfunAssign('AuxG_Co');
# }
# #bind AssignAuxK_Co to Ctrl+k menu AssignAuxK_Co
# sub AssignAuxK_Co {
#   AfunAssign('AuxK_Co');
# }
# #bind AssignAuxX_Co to Ctrl+x menu AssignAuxX_Co
# sub AssignAuxX_Co {
#   AfunAssign('AuxX_Co');
# }
# #bind AssignExD_Co to Ctrl+e menu AssignExD_Co
# sub AssignExD_Co {
#   AfunAssign('ExD_Co');
# }
# #bind AssignPred_Ap to Q menu AssignPred_Ap
# sub AssignPred_Ap {
#   AfunAssign('Pred_Ap');
# }
# #bind AssignPnom_Ap to N menu AssignPnom_Ap
# sub AssignPnom_Ap {
#   AfunAssign('Pnom_Ap');
# }
# #bind AssignAuxV_Ap to V menu AssignAuxV_Ap
# sub AssignAuxV_Ap {
#   AfunAssign('AuxV_Ap');
# }
# #bind AssignSb_Ap to S menu AssignSb_Ap
# sub AssignSb_Ap {
#   AfunAssign('Sb_Ap');
# }
# #bind AssignObj_Ap to B menu AssignObj_Ap
# sub AssignObj_Ap {
#   AfunAssign('Obj_Ap');
# }
# #bind AssignAtr_Ap to A menu AssignAtr_Ap
# sub AssignAtr_Ap {
#   AfunAssign('Atr_Ap');
# }
# #bind AssignAdv_Ap to D menu AssignAdv_Ap
# sub AssignAdv_Ap {
#   AfunAssign('Adv_Ap');
# }
# #bind AssignCoord_Ap to I menu AssignCoord_Ap
# sub AssignCoord_Ap {
#   DepSuffix('Coord_Ap');
# }
# #bind AssignAuxT_Ap to T menu AssignAuxT_Ap
# sub AssignAuxT_Ap {
#   AfunAssign('AuxT_Ap');
# }
# #bind AssignAuxR_Ap to R menu AssignAuxR_Ap
# sub AssignAuxR_Ap {
#   AfunAssign('AuxR_Ap');
# }
# #bind AssignAuxP_Ap to P menu AssignAuxP_Ap
# sub AssignAuxP_Ap {
#   AfunAssign('AuxP_Ap');
# }
# #bind AssignApos_Ap to U menu AssignApos_Ap
# sub AssignApos_Ap {
#   DepSuffix('Apos_Ap');
# }
# #bind AssignAuxC_Ap to C menu AssignAuxC_Ap
# sub AssignAuxC_Ap {
#   AfunAssign('AuxC_Ap');
# }
# #bind AssignAuxO_Ap to O menu AssignAuxO_Ap
# sub AssignAuxO_Ap {
#   AfunAssign('AuxO_Ap');
# }
# #bind AssignAtv_Ap to H menu AssignAtv_Ap
# sub AssignAtv_Ap {
#   AfunAssign('Atv_Ap');
# }
# #bind AssignAtvV_Ap to J menu AssignAtvV_Ap
# sub AssignAtvV_Ap {
#   AfunAssign('AtvV_Ap');
# }
# #bind AssignAuxZ_Ap to Z menu AssignAuxZ_Ap
# sub AssignAuxZ_Ap {
#   AfunAssign('AuxZ_Ap');
# }
# #bind AssignAuxY_Ap to Y menu AssignAuxY_Ap
# sub AssignAuxY_Ap {
#   AfunAssign('AuxY_Ap');
# }
# #bind AssignAuxG_Ap to G menu AssignAuxG_Ap
# sub AssignAuxG_Ap {
#   AfunAssign('AuxG_Ap');
# }
# #bind AssignAuxK_Ap to K menu AssignAuxK_Ap
# sub AssignAuxK_Ap {
#   AfunAssign('AuxK_Ap');
# }
# #bind AssignAuxX_Ap to X menu AssignAuxX_Ap
# sub AssignAuxX_Ap {
#   AfunAssign('AuxX_Ap');
# }
# #bind AssignExD_Ap to E menu AssignExD_Ap
# sub AssignExD_Ap {
#   AfunAssign('ExD_Ap');
# }
# #bind AssignPred_Pa to Ctrl+Q menu AssignPred_Pa
# sub AssignPred_Pa {
#   AfunAssign('Pred_Pa');
# }
# #bind AssignPnom_Pa to Ctrl+N menu AssignPnom_Pa
# sub AssignPnom_Pa {
#   AfunAssign('Pnom_Pa');
# }
# #bind AssignAuxV_Pa to Ctrl+V menu AssignAuxV_Pa
# sub AssignAuxV_Pa {
#   AfunAssign('AuxV_Pa');
# }
# #bind AssignSb_Pa to Ctrl+S menu AssignSb_Pa
# sub AssignSb_Pa {
#   AfunAssign('Sb_Pa');
# }
# #bind AssignObj_Pa to Ctrl+B menu AssignObj_Pa
# sub AssignObj_Pa {
#   AfunAssign('Obj_Pa');
# }
# #bind AssignAtr_Pa to Ctrl+A menu AssignAtr_Pa
# sub AssignAtr_Pa {
#   AfunAssign('Atr_Pa');
# }
# #bind AssignAdv_Pa to Ctrl+D menu AssignAdv_Pa
# sub AssignAdv_Pa {
#   AfunAssign('Adv_Pa');
# }
# #bind AssignCoord_Pa to Ctrl+I menu AssignCoord_Pa
# sub AssignCoord_Pa {
#   DepSuffix('Coord_Pa');
# }
# #bind AssignAuxT_Pa to Ctrl+T menu AssignAuxT_Pa
# sub AssignAuxT_Pa {
#   AfunAssign('AuxT_Pa');
# }
# #bind AssignAuxR_Pa to Ctrl+R menu AssignAuxR_Pa
# sub AssignAuxR_Pa {
#   AfunAssign('AuxR_Pa');
# }
# #bind AssignAuxP_Pa to Ctrl+P menu AssignAuxP_Pa
# sub AssignAuxP_Pa {
#   AfunAssign('AuxP_Pa');
# }
# #bind AssignApos_Pa to Ctrl+U menu AssignApos_Pa
# sub AssignApos_Pa {
#   DepSuffix('Apos_Pa');
# }
# #bind AssignAuxC_Pa to Ctrl+C menu AssignAuxC_Pa
# sub AssignAuxC_Pa {
#   AfunAssign('AuxC_Pa');
# }
# #bind AssignAuxO_Pa to Ctrl+O menu AssignAuxO_Pa
# sub AssignAuxO_Pa {
#   AfunAssign('AuxO_Pa');
# }
# #bind AssignAtv_Pa to Ctrl+H menu AssignAtv_Pa
# sub AssignAtv_Pa {
#   AfunAssign('Atv_Pa');
# }
# #bind AssignAtvV_Pa to Ctrl+J menu AssignAtvV_Pa
# sub AssignAtvV_Pa {
#   AfunAssign('AtvV_Pa');
# }
# #bind AssignAuxZ_Pa to Ctrl+Z menu AssignAuxZ_Pa
# sub AssignAuxZ_Pa {
#   AfunAssign('AuxZ_Pa');
# }
# #bind AssignAuxY_Pa to Ctrl+Y menu AssignAuxY_Pa
# sub AssignAuxY_Pa {
#   AfunAssign('AuxY_Pa');
# }
# #bind AssignAuxG_Pa to Ctrl+G menu AssignAuxG_Pa
# sub AssignAuxG_Pa {
#   AfunAssign('AuxG_Pa');
# }
# #bind AssignAuxK_Pa to Ctrl+K menu AssignAuxK_Pa
# sub AssignAuxK_Pa {
#   AfunAssign('AuxK_Pa');
# }
# #bind AssignAuxX_Pa to Ctrl+X menu AssignAuxX_Pa
# sub AssignAuxX_Pa {
#   AfunAssign('AuxX_Pa');
# }
# #bind AssignExD_Pa to Ctrl+E menu AssignExD_Pa
# sub AssignExD_Pa {
#   AfunAssign('ExD_Pa');
# }

# #bind EditAfun to l menu Edit afun
# sub EditAfun{
  # ChangingFile(EditAttribute($this,'afun'));
# }

#bind RotateMember to 1 menu Change is_member
sub RotateMember{
  $this->{is_member}=!$this->{is_member};
}

#bind RotateParenthesisRoot to 2 menu Change is_parenthesis_root
sub RotateParenthesisRoot{
  $this->{is_parenthesis_root}=!$this->{is_parenthesis_root};
}

## 2013-07-16 (VK)
## Vyznacime farebnymi oblacikmi anotacie od Sysnetu ;-)
sub after_redraw_hook {
    ## TODO - Mohol by som sem skopirovat farby podla
    ## farieb, ktore pouzivali anotatori v Brate. Myslim ale,
    ## ze je to zbytocne, namiesto toho sem vlozim mnozinu
    ## farieb a budem z nej nahodne vyberat
    my @colors = (
	'maroon',
	'olive drab',
	'hot pink',
	'Turquoise1',
	'plum',
	'light slate blue',
	'lime green',
	'#8aa3ff',
	'#8a535c',
	'orange1',
    );

    ## Prejdem vsetky uzly v subore a zaradim ich do skupin, ak maju nejaku
    ## anotaciu
    my %groups = ();
    foreach my $node (GetNodes()) {
	if (defined($node->attr('m/intlib_annotations'))) {
	    foreach my $annotation (split(/\s*,\s*/, $node->attr('m/intlib_annotations'))) {
		$annotation =~ /^(.*):(.*)$/;
		my $annotation_id = $1;
		$annotation_id =~ s/-\d+$//;
		$groups{$annotation_id}{$node->attr('id')} = 1;
	    }
    	}
    }

    ## Vysrafujem vsetky skupiny :-)
    foreach my $group (keys %groups) {
	my @nodes = map {PML_A::GetNodeByID($_);} keys %{$groups{$group}};
	my $farba = int(rand(scalar(@colors)));
	TrEd::NodeGroups::draw_groups($grp, [[@nodes]], {
		colors   => [ $colors[$farba] ],
		stipples => [ "dense1" ]
	    }
	);
    }
}


########################################################################

#bind TectogrammaticalTree to Ctrl+R menu Display tectogrammatical tree

#bind OpenValFrameList to Ctrl+Return menu Browse valency lexicon

1;

=back

=cut

#endif PML_INTLIB_A_Edit
