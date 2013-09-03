# ########################################################################## Otakar Smrz, 2004/03/05
#
# PADT Syntax Context for the TrEd Environment #####################################################

# $Id$

package PADT::Syntax;

use 5.008;

use strict;

use Encode::Arabic ':modes';

use List::Util 'reduce';

use File::Spec;
use File::Copy;

use File::Basename;

our $VERSION = join '.', '1.1', q $Revision$ =~ /(\d+)/;

# ##################################################################################################
#
# ##################################################################################################

#binding-context PADT::Syntax

BEGIN {

    import PADT 'switch_context_hook', 'pre_switch_context_hook', 'idx';

    import TredMacro;
}

our ($this, $root, $grp);

our ($Redraw);

our ($option, $fill) = ({}, ' ' x 4);

# ##################################################################################################
#
# ##################################################################################################

sub AfunAssign {

    my $fullafun = $_[0];
    my ($afun, $parallel, $paren) = ($fullafun =~ /^([^_]*)(?:_(Ap|Co))?(?:_(Pa))?/);

    if ($this == $root or
        $this->{'afun'} eq $afun and
        $this->{'parallel'} eq $parallel and $this->{'paren'} eq $paren) {

        $Redraw = 'none';
        ChangingFile(0);
    }
    else {

        $this->{'afun'} = $afun;
        $this->{'parallel'} = $parallel;
        $this->{'paren'} = $paren;

        $this = $this->following();

        $Redraw = 'tree';
    }
}

#bind afun_Pred q menu Assign Pred
sub afun_Pred { AfunAssign("Pred") }
#bind afun_Pred_Co Ctrl+q menu Assign Pred_Co
sub afun_Pred_Co { AfunAssign("Pred_Co") }

#bind afun_Pnom n menu Assign Pnom
sub afun_Pnom { AfunAssign("Pnom") }
#bind afun_Pnom_Co Ctrl+n menu Assign Pnom_Co
sub afun_Pnom_Co { AfunAssign("Pnom_Co") }

#bind afun_Pred Q menu Assign _Pred
sub afun_Pred {
    return if $this == $root;
    $this->{'clause'} = $this->{'clause'} eq 'Pred' ? '' : 'Pred';
}

#bind afun_Pnom N menu Assign _Pnom
sub afun_Pnom {
    return if $this == $root;
    $this->{'clause'} = $this->{'clause'} eq 'Pnom' ? '' : 'Pnom';
}

#bind afun_PredE E menu Assign PredE
sub afun_PredE {
    return if $this == $root;
    if ($this->{'afun'} eq '???') {
        $this->{'afun'} = 'PredE';
    }
    else {
        $this->{'clause'} = $this->{'clause'} eq 'PredE' ? '' : 'PredE';
    }
}
#bind afun_PredE_Co Ctrl+E menu Assign PredE_Co
sub afun_PredE_Co { AfunAssign("PredE_Co") }

#bind afun_PredC C menu Assign PredC
sub afun_PredC {
    return if $this == $root;
    if ($this->{'afun'} eq '???') {
        $this->{'afun'} = 'PredC';
    }
    else {
        $this->{'clause'} = $this->{'clause'} eq 'PredC' ? '' : 'PredC';
    }
}
#bind afun_PredC_Co Ctrl+C menu Assign PredC_Co
sub afun_PredC_Co { AfunAssign("PredC_Co") }

#bind afun_PredM M menu Assign PredM
sub afun_PredM {
    return if $this == $root;
    if ($this->{'afun'} eq '???') {
        $this->{'afun'} = 'PredM';
    }
    else {
        $this->{'clause'} = $this->{'clause'} eq 'PredM' ? '' : 'PredM';
    }
}
#bind afun_PredM_Co Ctrl+M menu Assign PredM_Co
sub afun_PredM_Co { AfunAssign("PredM_Co") }

#bind afun_PredP P menu Assign PredP
sub afun_PredP {
    return if $this == $root;
    if ($this->{'afun'} eq '???') {
        $this->{'afun'} = 'PredP';
    }
    else {
        $this->{'clause'} = $this->{'clause'} eq 'PredP' ? '' : 'PredP';
    }
}
#bind afun_PredP_Co Ctrl+P menu Assign PredP_Co
sub afun_PredP_Co { AfunAssign("PredP_Co") }

#bind afun_Sb s menu Assign Sb
sub afun_Sb { AfunAssign("Sb") }
#bind afun_Sb_Co Ctrl+s menu Assign Sb_Co
sub afun_Sb_Co { AfunAssign("Sb_Co") }

#bind afun_Obj o menu Assign Obj
sub afun_Obj { AfunAssign("Obj") }
#bind afun_Obj_Co Ctrl+o menu Assign Obj_Co
sub afun_Obj_Co { AfunAssign("Obj_Co") }

#bind afun_Adv d menu Assign Adv
sub afun_Adv { AfunAssign("Adv") }
#bind afun_Adv_Co Ctrl+d menu Assign Adv_Co
sub afun_Adv_Co { AfunAssign("Adv_Co") }

#bind afun_Atr a menu Assign Atr
sub afun_Atr { AfunAssign("Atr") }
#bind afun_Atr_Co Ctrl+a menu Assign Atr_Co
sub afun_Atr_Co { AfunAssign("Atr_Co") }

#bind afun_Atv v menu Assign Atv
sub afun_Atv { AfunAssign("Atv") }
#bind afun_Atv_Co Ctrl+v menu Assign Atv_Co
sub afun_Atv_Co { AfunAssign("Atv_Co") }

#bind afun_ExD x menu Assign ExD
sub afun_ExD { AfunAssign("ExD") }
#bind afun_ExD_Co Ctrl+x menu Assign ExD_Co
sub afun_ExD_Co { AfunAssign("ExD_Co") }

#bind afun_Coord w menu Assign Coord
sub afun_Coord { AfunAssign("Coord") }
#bind afun_Coord_Co Ctrl+w menu Assign Coord_Co
sub afun_Coord_Co { AfunAssign("Coord_Co") }

#bind afun_Apos u menu Assign Apos
sub afun_Apos { AfunAssign("Apos") }
#bind afun_Apos_Co Ctrl+u menu Assign Apos_Co
sub afun_Apos_Co { AfunAssign("Apos_Co") }

#bind afun_Ante t menu Assign Ante
sub afun_Ante { AfunAssign("Ante") }
#bind afun_Ante_Co Ctrl+t menu Assign Ante_Co
sub afun_Ante_Co { AfunAssign("Ante_Co") }

#bind afun_AuxC c menu Assign AuxC
sub afun_AuxC { AfunAssign("AuxC") }
#bind afun_AuxC_Co Ctrl+c menu Assign AuxC_Co
sub afun_AuxC_Co { AfunAssign("AuxC_Co") }

#bind afun_AuxP p menu Assign AuxP
sub afun_AuxP { AfunAssign("AuxP") }
#bind afun_AuxP_Co Ctrl+p menu Assign AuxP_Co
sub afun_AuxP_Co { AfunAssign("AuxP_Co") }

#bind afun_AuxE e menu Assign AuxE
sub afun_AuxE { AfunAssign("AuxE") }
#bind afun_AuxE_Co Ctrl+e menu Assign AuxE_Co
sub afun_AuxE_Co { AfunAssign("AuxE_Co") }

#bind afun_AuxM m menu Assign AuxM
sub afun_AuxM { AfunAssign("AuxM") }
#bind afun_AuxM_Co Ctrl+m menu Assign AuxM_Co
sub afun_AuxM_Co { AfunAssign("AuxM_Co") }

#bind afun_AuxY y menu Assign AuxY
sub afun_AuxY { AfunAssign("AuxY") }
#bind afun_AuxY_Co Ctrl+y menu Assign AuxY_Co
sub afun_AuxY_Co { AfunAssign("AuxY_Co") }

#bind afun_AuxG g menu Assign AuxG
sub afun_AuxG { AfunAssign("AuxG") }
#bind afun_AuxG_Co Ctrl+g menu Assign AuxG_Co
sub afun_AuxG_Co { AfunAssign("AuxG") }

#bind afun_AuxK k menu Assign AuxK
sub afun_AuxK { AfunAssign("AuxK") }
#bind afun_AuxK_Co Ctrl+k menu Assign AuxK_Co
sub afun_AuxK_Co { AfunAssign("AuxK") }

#bind assign_parallel 1 menu Assign Suffix Parallel
sub assign_parallel {
    EditAttribute($this, 'parallel');
}

#bind assign_paren 2 menu Assign Suffix Paren
sub assign_paren {
    EditAttribute($this, 'paren');
}

#bind assign_coref 3 menu Assign Suffix Coref
sub assign_coref {
    EditAttribute($this, 'coref');
}

#bind assign_clause 4 menu Assign Suffix Clause
sub assign_clause {
    EditAttribute($this,'clause');
}

# ##################################################################################################
#
# ##################################################################################################

#bind thisToParent Alt+Up menu Annotate: Current node up one level to grandparent
sub thisToParent {

    $Redraw = 'none';
    ChangingFile(0);

    return unless $this->parent() and $this->parent()->parent();

    my $act = $this;
    my $p = $act->parent()->parent();

    CutPaste($act, $p);
    $this = $act;

    $Redraw = 'tree';
    ChangingFile(1);
}

#bind thisToRBrother Alt+Left menu Annotate: Current node to brother on the left
sub thisToRBrother {

    $Redraw = 'none';
    ChangingFile(0);

    my $p = $main::treeViewOpts->{reverseNodeOrder} && ! InVerticalMode()
            ? $this->rbrother() : $this->lbrother();

    return unless $p;

    my $c = $this;

    CutPaste($c, $p);
    $this = $c;

    $Redraw = 'tree';
    ChangingFile(1);
}

#bind thisToLBrother Alt+Right menu Annotate: Current node to brother on the right
sub thisToLBrother {

    $Redraw = 'none';
    ChangingFile(0);

    my $p = $main::treeViewOpts->{reverseNodeOrder} && ! InVerticalMode()
            ? $this->lbrother() : $this->rbrother();

    return unless $p;

    my $c = $this;

    CutPaste($c, $p);
    $this = $c;

    $Redraw = 'tree';
    ChangingFile(1);
}

#bind thisToParentRBrother Alt+Shift+Left menu Annotate: Current node to uncle on the left
sub thisToParentRBrother {

    $Redraw = 'none';
    ChangingFile(0);

    return unless $this->parent();

    my $p = $main::treeViewOpts->{reverseNodeOrder} && ! InVerticalMode()
            ? $this->parent()->rbrother() : $this->parent()->lbrother();

    return unless $p;

    my $c = $this;

    CutPaste($c, $p);
    $this = $c;

    $Redraw = 'tree';
    ChangingFile(1);
}

#bind thisToParentLBrother Alt+Shift+Right menu Annotate: Current node to uncle on the right
sub thisToParentLBrother {

    $Redraw = 'none';
    ChangingFile(0);

    return unless $this->parent();

    my $p = $main::treeViewOpts->{reverseNodeOrder} && ! InVerticalMode()
            ? $this->parent()->lbrother() : $this->parent()->rbrother();

    return unless $p;

    my $c = $this;

    CutPaste($c, $p);
    $this = $c;

    $Redraw = 'tree';
    ChangingFile(1);
}

#bind thisToEitherBrother Alt+Down menu Annotate: Current node to either side brother if unique
sub thisToEitherBrother {

    $Redraw = 'none';
    ChangingFile(0);

    my $lb = $this->lbrother();
    my $rb = $this->rbrother();

    return unless $lb xor $rb;

    my $c = $this;
    my $p = $lb || $rb;

    CutPaste($c, $p);
    $this = $c;

    $Redraw = 'tree';
    ChangingFile(1);
}

#bind SwapNodesUp Alt+Shift+Down menu Annotate: Current node exchanged with parent
sub SwapNodesUp {

    $Redraw = 'none';
    ChangingFile(0);

    return unless $this;

    my $parent = $this->parent();

    return unless $parent;

    my $grandParent = $parent->parent();

    return unless $grandParent;

    CutPaste($this, $grandParent);
    CutPaste($parent, $this);
    $this = $parent;

    $Redraw = 'tree';
    ChangingFile(1);
}

##bind SwapNodesDown Alt+Shift+Down menu Annotate: Current node exchanged with son if unique
sub SwapNodesDown {

    $Redraw = 'none';
    ChangingFile(0);

    return unless $this;

    my @childs = $this->children();
    my $parent = $this->parent();

    return unless @childs == 1 and $parent;

    CutPaste($childs[0], $parent);
    CutPaste($this, $childs[0]);
    $this = $childs[0];

    $Redraw = 'tree';
    ChangingFile(1);
}

#bind thisToRoot Alt+Shift+Up menu Annotate: Current node to the root
sub thisToRoot {

    $Redraw = 'none';
    ChangingFile(0);

    return unless $this and $this->parent();

    return unless $root;

    CutPaste($this, $root);

    $Redraw = 'tree';
    ChangingFile(1);
}

#bind thisToLeftClauseHead Ctrl+Alt+Right menu Annotate: Current node to preceeding clause head
sub thisToLeftClauseHead {

    $Redraw = 'none';
    ChangingFile(0);

    return unless $this and $this->parent();

    $main::treeViewOpts->{reverseNodeOrder} && ! InVerticalMode() ?
        thisToPrevClauseHead() :
        thisToNextClauseHead();
}

#bind thisToRightClauseHead Ctrl+Alt+Left menu Annotate: Current node to following clause head
sub thisToRightClauseHead {

    $Redraw = 'none';
    ChangingFile(0);

    return unless $this and $this->parent();

    $main::treeViewOpts->{reverseNodeOrder} && ! InVerticalMode() ?
        thisToNextClauseHead() :
        thisToPrevClauseHead();
}

sub thisToPrevClauseHead {

    my $node = $this->parent();

    do { $node = $node->previous() } while $node and not isClauseHead($node);

    return unless $node;

    CutPaste($this, $node);

    $Redraw = 'tree';
    ChangingFile(1);
}

sub thisToNextClauseHead {

    my $node = $this->parent();

    do { $node = $node->following() } until $node == $this or isClauseHead($node);

    unless ($node == $this) {

        CutPaste($this, $node);
    }
    else {

        $node = $this->rightmost_descendant();

        do { $node = $node->following() } while $node and not isClauseHead($node);

        return unless $node;

        CutPaste($this, $node);
    }

    $Redraw = 'tree';
    ChangingFile(1);
}

#bind thisToSuperClauseHead Ctrl+Alt+Up menu Annotate: Current node to superior clause head
sub thisToSuperClauseHead {

    $Redraw = 'none';
    ChangingFile(0);

    return unless $this and $this->parent();

    my $node = $this->parent();

    do { $node = $node->parent() } while $node and not isClauseHead($node);

    return unless $node;

    CutPaste($this, $node);

    $Redraw = 'tree';
    ChangingFile(1);
}

#bind thisToInferClauseHead Ctrl+Alt+Down menu Annotate: Current node to inferior clause head
sub thisToInferClauseHead {

    $Redraw = 'none';
    ChangingFile(0);

    return unless $this and $this->parent();

    my $node = $this;

    do { $node = $node->following($this) } while $node and not isClauseHead($node);

    return unless $node;

    CutPaste($node, $this->parent());
    CutPaste($this, $node);

    $Redraw = 'tree';
    ChangingFile(1);
}

# ##################################################################################################
#
# ##################################################################################################

sub CreateStylesheets {

    return << '>>';

style:<? PADT::Syntax::isClauseHead() ? '#{Line-fill:gold}' : '' ?>

node:<? $this->{'#name'} eq 'Tree' ? '#{darkmagenta}${form} ' . PADT::Syntax::idx($this) :
        exists $this->{'m'}
            ? ( $this->{'m'}{'form'} =~ /\p{InArabic}/
                ? $this->{'m'}{'form'}
                : ElixirFM::orth($this->{'m'}{'form'}) )
            : '#{red}${w/form}' ?>

node:<? $this->{'#name'} eq 'Tree' ? '' :
        exists $this->{'m'}
            ? '#{orange}' . ( $this->{'m'}{'form'} =~ /\p{InArabic}/
                ? PADT::Syntax::encode("buckwalter", $this->{'m'}{'form'})
                : ElixirFM::phon($this->{'m'}{'form'}) )
            : '#{orange}' . PADT::Syntax::encode("buckwalter", $this->{'w'}{'form'}) ?>

node:<? exists $this->{'m'} ? (
        exists $this->{'m'}{'note'} &&
               $this->{'m'}{'note'} ne '' ? '#{goldenrod}${m/note} ' : ''
        ) . '#{darkred}${m/tag}' : '' ?>

node:<? ( $this->{'note'} ne '' ? '#{magenta}${note} ' : '' ) .
        ( join '_', '#{darkviolet}${afun}',
                    map { '#{darkviolet}${' . $_ . '}' }
                    grep { $this->attr($_) ne '' } qw 'parallel paren coref clause' ) ?>

hint:<? join "\n", (exists $this->{'m'}{'sense'} ? '"' . $this->{'m'}{'sense'} . '"' : ()),
                   (exists $this->{'m'}{'cite'}{'reflex'} ?
                         @{$this->{'m'}{'cite'}{'reflex'}} : ()) if exists $this->{'m'} ?>
>>
}

#bind ChangeStylesheet F8 menu Change Stylesheet
sub ChangeStylesheet {

    return unless $grp->{FSFile};

    my ($type, $pattern) = ('node:', '#{custom2}${m/tag}');

    my $code = q {<? exists $this->{'m'} ? (
        exists $this->{'m'}{'note'} &&
               $this->{'m'}{'note'} ne '' ? '#{goldenrod}${m/note} ' : ''
        ) . '#{darkred}${m/tag}' : '' ?>};

    my $role = q {<? ( $this->{'note'} ne '' ? '#{magenta}${note} ' : '' ) .
        ( join '_', '#{darkviolet}${afun}',
                    map { '#{darkviolet}${' . $_ . '}' }
                    grep { $this->attr($_) ne '' } qw 'parallel paren coref clause' ) ?>};

    my ($hint, $cntxt, $style) = GetStylesheetPatterns();

    my @filter = grep { $_ !~ /^(?:\Q${type}\E\s*)?(?:\Q${code}\E|\Q${pattern}\E|\Q${role}\E)$/ } @{$style};

    SetStylesheetPatterns([ $hint, $cntxt, [ @filter, ( @{$style} == 1 + @filter ? $type . ' ' . $code : () ), $type . ' ' . $role ] ]);

    ChangingFile(0);
}

sub get_auto_afun {

    require Assign_arab_afun;

    my ($ra, $rb, $rc) = Assign_arab_afun::afun($_[0]);

    print STDERR "$this->{cite}{form} ($ra,$rb,$rc)\n";

    return $ra =~ /^\s*$/ ? '' : $ra;
}

# #bind request_auto_afun_node Ctrl+Shift+F9 menu Arabic: Request auto afun for current node
sub request_auto_afun_node {

    my $node = $_[0] eq __PACKAGE__ ? $this : $_[0];

    unless ($node and $node->parent() and ($node->{'afun'} eq '???' or $node->{'afun'} eq '')) {

        $Redraw = 'none';
        ChangingFile(0);
    }
    else {

        $node->{'afun'} = '???';    # it might have been empty
        $node->{'score'} = get_auto_afun($node);

        $Redraw = 'tree';
    }
}

# #bind request_auto_afun_subtree Ctrl+Shift+F10 menu Arabic: Request auto afun for current subtree
sub request_auto_afun_subtree {

    my $node = $this;

    request_auto_afun_node($node);      # more strict checks

    while ($node = $node->following($this)) {

        if ($node->{'afun'} eq '???' or $node->{'afun'} eq '') {

            $node->{'afun'} = '???';    # it might have been empty
            $node->{'score'} = get_auto_afun($node);
        }
    }

    $Redraw = 'tree';
}

# #bind hooks_request_mode Ctrl+Shift+F8 menu Arabic: Toggle request mode for auto afuns
sub hooks_request_mode {

    $option->{$grp}{'hook'} = not $option->{$grp}{'hook'};

    $Redraw = 'none';
    ChangingFile(0);
}

sub get_value_line_hook {

    my ($fsfile, $index) = @_;
    my ($nodes, $words, $views);

    ($nodes, undef) = $fsfile->nodes($index, $this, 1);

    $views->{$_->{'ord'}} = $_ foreach GetVisibleNodes($root);

    $words = [ [ $nodes->[0]->{'form'} . " " . idx($nodes->[0]), $nodes->[0], '-foreground => darkmagenta' ],
               [ " " ],

               map {

                   show_value_line_node($views, $_, $_->{'w'}{'form'}, not exists $_->{'m'})

               } @{$nodes}[1 .. $#{$nodes}] ];

    @{$words} = reverse @{$words} if $main::treeViewOpts->{reverseNodeOrder};

    return $words;
}

sub show_value_line_node {

    my ($view, $node, $text, $warn) = @_;

    if (HiddenVisible()) {

        return if exists $node->{'m'} and $node->{'m'}{'id'} !~ /t1(?:-[0-9]+)?$/;

        return [ $text, $node, exists $view->{$node->{'ord'}} ? $warn ? '-foreground => red' : ()
                                                                      : '-foreground => gray' ],
               [ " " ];
    }
    else {

        return [ '.....', $view->{$node->{'ord'} - 1}, '-foreground => magenta' ],
               [ " " ]
                       if not exists $view->{$node->{'ord'}} and exists $view->{$node->{'ord'} - 1};

        return if not exists $view->{$node->{'ord'}};

        return if exists $node->{'m'} and $node->{'m'}{'id'} !~ /t1(?:-[0-9]+)?$/;

        return  [ $text, $node, $warn ? '-foreground => red' : () ],
                [ " " ];
    }
}

sub highlight_value_line_tag_hook {

    my $node = $grp->{currentNode};

    $node = PrevNodeLinear($node, 'ord') until !$node or exists $node->{'w'} and exists $node->{'w'}{'form'} and $node->{'w'}{'form'} ne '';

    return $node;
}

sub node_release_hook {

    my ($node, $done) = @_;
    my (@line);

    return unless $done;

    return unless $option->{$grp}{'hook'};

    until ($done->{'afun'} ne '???' or exists $done->{'score'} and @{$done->{'score'}} > 0) {

        unshift @line, $done;

        $done = $done->parent();
    }

    request_auto_afun_node($_) foreach @line, $node;
}

sub node_moved_hook {

    return unless $option->{$grp}{'hook'};

    my (undef, $done) = @_;

    my @line;

    until ($done->{'afun'} ne '???' or exists $done->{'score'} and @{$done->{'score'}} > 0) {

        unshift @line, $done;

        $done = $done->parent();
    }

    request_auto_afun_node($_) foreach @line;
}

# # bind padt_auto_parse_tree Ctrl+Shift+F2 menu Arabic: Parse the current sentence and build a tree
sub padt_auto_parse_tree {

    require Arab_parser;

    Arab_parser::parse_sentence($grp,$root);
}

sub root_style_hook {

}

sub node_style_hook {

    my ($node, $styles) = @_;

    if ($node->{'coref'} eq 'Ref') {

        my $T = << 'TARGET';
[!
    return PADT::Syntax::referring_Ref($this);
!]
TARGET

        my $C = << "COORDS";
n,n,
(n + x$T) / 2 + (abs(xn - x$T) > abs(yn - y$T) ? 0 : -40),
(n + y$T) / 2 + (abs(yn - y$T) > abs(xn - x$T) ? 0 :  40),
x$T,y$T
COORDS

    AddStyle($styles,   'Line',
             -coords => 'n,n,p,p&'. # coords for the default edge to parent
                        $C,         # coords for our line
             -arrow =>  '&last',
             -dash =>   '&_',
             -width =>  '&1',
             -fill =>   '&#C000D0', # color
             -smooth => '&1'        # approximate our line with a smooth curve
            );
    }


    if ($node->{arabspec} eq 'Msd') {

        my $T = << 'TARGET';
[!
    return PADT::Syntax::referring_Msd($this);
!]
TARGET

        my $C = << "COORDS";
n,n,
(n + x$T) / 2 + (abs(xn - x$T) > abs(yn - y$T) ? 0 : -40),
(n + y$T) / 2 + (abs(yn - y$T) > abs(xn - x$T) ? 0 :  40),
x$T,y$T
COORDS

    AddStyle($styles,   'Line',
             -coords => 'n,n,p,p&'. # coords for the default edge to parent
                        $C,         # coords for our line
             -arrow =>  '&last',
             -dash =>   '&_',
             -width =>  '&1',
             -fill =>   '&#FFA000', # color
             -smooth => '&1'        # approximate our line with a smooth curve
            );
    }
}

# ##################################################################################################
#
# ##################################################################################################

sub isPredicate {

    my $this = defined $_[0] ? $_[0] : $this;

    return $this->{'clause'} ne "" || exists $this->{'m'} &&
                                             $this->{'m'}{'tag'} =~ /^V/ &&
                                             $this->{'afun'} !~ /^Aux/
                                   || $this->{'afun'} =~ /^Pred[ECMP]?$/;
}

sub theClauseHead ($;&) {

    my $this = defined $_[0] ? $_[0] : $this;

    my $code = defined $_[1] ? $_[1] : sub { return undef };

    my ($return, $effect, @children, $main);

    my $head = $this;

    while ($head) {

        $effect = $head->{'afun'};

        if ($head->{'afun'} =~ /^(?:Coord|Apos)$/) {

            @children = grep { $_->{'parallel'} =~ /^(?:Co|Ap)$/ } $head->children();

            if (grep { $_->{'afun'} eq 'Atv' } @children) {

                $effect = 'Atv';
            }
            elsif (grep { isPredicate($_) } @children) {

                $effect = 'Pred';
            }
            elsif (grep { $_->{'afun'} eq 'Pnom'} @children) {

                $effect = 'Pnom';
            }
        }

        if ($head->{'afun'} =~ /^(?:Pnom|Atv)$/ or $effect =~ /^(?:Pnom|Atv)$/) {

            $main = $head;                      # {Pred} <- [Pnom] = [Pnom] and there exist [Verb] <- [Verb]

            if ($main->{'parallel'} =~ /^(?:Co|Ap)$/) {

                do {

                    $main = $main->parent();
                }
                while $main and $main->{'parallel'} =~ /^(?:Co|Ap)$/ and $main->{'afun'} =~ /^(?:Coord|Apos)$/;

                $main = $head unless $main and $main->{'afun'} =~ /^(?:Coord|Apos)$/;
            }

            if ($main->parent() and isPredicate($main->parent())) {

                return $main->parent();
            }
            elsif ($head->{'afun'} eq 'Pnom') {

                return $head;
            }
        }

        last if isPredicate($head) or $effect =~ /^(?:Pred|Pnom)$/;

        if ($return = $code->($head)) {

            return $return;
        }

        $head = $head->parent();
    }

    return $head;
}

sub isClauseHead {

    my $this = defined $_[0] ? $_[0] : $this;

    my $head = theClauseHead($this, sub { return 'stop' } );

    return $this == $head;
}

sub referring_Ref {

    my $this = defined $_[0] ? $_[0] : $this;

    my $head = $this->parent();

    $head = theClauseHead($head, sub {                  # attributive pseudo-clause .. approximation only

            return $_[0] if $_[0]->{'afun'} eq 'Atr' and exists $_[0]->{'m'} and
                                                                $_[0]->{'m'}{'tag'} =~ /^A/
                            and $this->level() > $_[0]->level() + 1;
            return undef;

        } );

    if ($head) {

        my $ante = $head;

        $ante = $ante->following($head) while $ante and $ante->{'afun'} ne 'Ante' and $ante != $this;

        unless ($ante) {

            $head = $head->parent() while $head->{'parallel'} =~ /^(?:Co|Ap)$/;

            $ante = $head;

            $ante = $ante->following($head) while $ante and $ante->{'afun'} ne 'Ante' and $ante != $this;
        }

        $ante = $ante->parent() while $ante and $ante->{'parallel'} =~ /^(?:Co|Ap)$/;

        if ($ante) {

            $this = $this->parent() while $this and $this != $ante;

            return $ante if $this != $ante;
        }

        $head = $head->parent() while $head->{'parallel'} =~ /^(?:Co|Ap)$/;

        $head = $head->parent();

        return $head;
    }
    else {

        return undef;
    }
}

sub referring_Msd {

    my $this = defined $_[0] ? $_[0] : $this;

    my $head = $this->parent();                                                         # the token itself might feature the critical tags

    $head = $head->parent() if $this->{'afun'} eq 'Atr';                                # constructs like <_hAfa 'a^sadda _hawfiN>

    $head = $head->parent() until not $head or exists $head->{'m'} and
                                                      $head->{'m'}{'tag'} =~ /^[VNA]/;  # the verb, governing masdar or participle

    return $head;
}

# ##################################################################################################
#
# ##################################################################################################

sub enable_attr_hook {

    return 'stop' if $_[0] =~ /^morpho(?!\w)/;
}

#bind edit_note exclam menu Annotate: Edit Annotation Note
sub edit_note {

    if (exists $this->{'note'} and $this->{'note'} ne "") {

        delete $this->{'note'};
    }
    else {

        my $note = main::QueryString($grp->{framegroup}, "Enter the note", 'note');

        $this->{'note'} = $note if defined $note;
    }
}

#bind invoke_undo BackSpace menu Annotate: Undo recent annotation action
sub invoke_undo {

    warn 'Undoooooing ;)';

    main::undo($grp);
    $this = $grp->{currentNode};

    ChangingFile(0);
}

#bind annotate_following space menu Annotate: Move to following ???
sub annotate_following {

    my $node = $this;

    do { $this = $this->following() } while $this and $this->{'afun'} ne '???';

    $this = $node unless $this and $this->{'afun'} eq '???';

    $Redraw = 'none';
    ChangingFile(0);
}

#bind annotate_previous Shift+space menu Annotate: Move to previous ???
sub annotate_previous {

    my $node = $this;

    do { $this = $this->previous() } while $this and $this->{'afun'} ne '???';

    $this = $node unless $this and $this->{'afun'} eq '???';

    $Redraw = 'none';
    ChangingFile(0);
}

# #bind accept_auto_afun Ctrl+space menu Arabic: Accept auto-assigned annotation
sub accept_auto_afun {

    my $node = $this;

    if ($this->{'afun'} ne '???' or exists $this->{'score'}) {

        $Redraw = 'none';
        ChangingFile(0);
    }
    else {

        $this->{'afun'} = $this->{'score'};
        delete $this->{'score'};

        $Redraw = 'tree';
    }
}

#bind unset_afun question menu Assign ???
sub unset_afun {

    if ($this->{'afun'} eq 'AuxS' or $this->{'afun'} eq '???') {

        $Redraw = 'none';
        ChangingFile(0);
    }
    else {

        $this->{'afun'} = '???';
        delete $this->{'score'};

        $Redraw = 'tree';
    }
}

# #bind unset_request_afun Ctrl+question menu Arabic: Unset and request auto afun
sub unset_request_afun {

    if ($this->{'afun'} eq 'AuxS') {

        $Redraw = 'none';
        ChangingFile(0);
    }
    else {

        $this->{'afun'} = '???';
        $this->{'score'} = get_auto_afun($this);

        $Redraw = 'tree';
    }
}

# ##################################################################################################
#
# ##################################################################################################

#bind move_word_home Home menu Move to First Word
sub move_word_home {

    $this = reduce { $a->{'ord'} < $b->{'ord'} ? $a : $b } GetVisibleNodes($root);

    $Redraw = 'none';
    ChangingFile(0);
}

#bind move_word_end End menu Move to Last Word
sub move_word_end {

    $this = reduce { $a->{'ord'} > $b->{'ord'} ? $a : $b } GetVisibleNodes($root);

    $Redraw = 'none';
    ChangingFile(0);
}

OverrideBuiltinBinding(__PACKAGE__, "Shift+Home", [ MacroCallback('move_deep_home'), 'Move to Rightmost Descendant' ]);

#bind move_deep_home Shift+Home menu Move to Rightmost Descendant
sub move_deep_home {

    $this = $this->leftmost_descendant();

    $this = PrevVisibleNode($this) if IsHidden($this);

    $Redraw = 'none';
    ChangingFile(0);
}

OverrideBuiltinBinding(__PACKAGE__, "Shift+End", [ MacroCallback('move_deep_end'), 'Move to Leftmost Descendant' ]);

#bind move_deep_end Shift+End menu Move to Leftmost Descendant
sub move_deep_end {

    $this = $this->rightmost_descendant();

    $this = NextVisibleNode($this) || PrevVisibleNode($this) if IsHidden($this);

    $Redraw = 'none';
    ChangingFile(0);
}

#bind move_par_home Ctrl+Home menu Move to First Paragraph
sub move_par_home {

    GotoTree(1);

    $Redraw = 'win';
    ChangingFile(0);
}

#bind move_par_end Ctrl+End menu Move to Last Paragraph
sub move_par_end {

    GotoTree($grp->{FSFile}->lastTreeNo + 1);

    $Redraw = 'win';
    ChangingFile(0);
}

#bind move_to_next_paragraph Shift+Next menu Move to Next Paragraph
sub move_to_next_paragraph {

    NextTree();

    $Redraw = 'win';
    ChangingFile(0);
}

#bind move_to_prev_paragraph Shift+Prior menu Move to Prev Paragraph
sub move_to_prev_paragraph {

    PrevTree();

    $Redraw = 'win';
    ChangingFile(0);
}

#bind tree_hide_mode Ctrl+equal menu Toggle Children Hiding
sub tree_hide_mode {

    foreach my $node ($this->children()) {

        $node->{'hide'} = $node->{'hide'} ? '' : 'hide';
    }

    ChangingFile(0);
}

#bind unhide_subtree Ctrl+plus menu Unhide Children Recursively
sub unhide_subtree {

    my $this = ref $_[0] ? $_[0] : $this;

    $this->{'hide'} = '';

    foreach my $node ($this->children()) {

        unhide_subtree($node);
    }

    ChangingFile(0);
}

#bind hide_children Ctrl+minus menu Hide Children Subtrees
sub hide_children {

    foreach my $node ($this->children()) {

        $node->{'hide'} = 'hide';
    }

    ChangingFile(0);
}

#bind hide_this Ctrl+underscore menu Hide This Subtree
sub hide_this {

    $this->{'hide'} = $this->{'hide'} ? '' : 'hide';

    ChangingFile(0);
}

#bind move_to_root Ctrl+Shift+Up menu Move Up to Root
sub move_to_root {

    $this = $root unless $root == $this;

    $Redraw = 'none';
    ChangingFile(0);
}

#bind move_to_fork Ctrl+Shift+Down menu Move Down to Fork
sub move_to_fork {

    my $node = $this;
    my (@children);

    while (@children = $node->children()) {

        @children = grep { $_->{'hide'} ne 'hide' } @children;

        last unless @children == 1;

        $node = $children[0];
    }

    $this = $node unless $node == $this;

    $Redraw = 'none';
    ChangingFile(0);
}

#bind prev_clause_head Ctrl+Right menu Move to the Preceeding Clause Head
sub prev_clause_head {

    my $node = $this;

    if ($main::treeViewOpts->{reverseNodeOrder} && ! InVerticalMode()) {

        do { $this = $this->previous() } while $this and not isClauseHead($this);
    }
    else {

        do { $this = $this->following() } while $this and not isClauseHead($this);
    }

    $this = $node unless $this;

    $Redraw = 'none';
    ChangingFile(0);
}

#bind next_clause_head Ctrl+Left menu Move to the Following Clause Head
sub next_clause_head {

    my $node = $this;

    if ($main::treeViewOpts->{reverseNodeOrder} && ! InVerticalMode()) {

        do { $this = $this->following() } while $this and not isClauseHead($this);
    }
    else {

        do { $this = $this->previous() } while $this and not isClauseHead($this);
    }

    $this = $node unless $this;

    $Redraw = 'none';
    ChangingFile(0);
}

#bind super_clause_head Ctrl+Up menu Move to the Superior Clause Head
sub super_clause_head {

    my $node = $this;

    do { $this = $this->parent() } while $this and not isClauseHead($this);

    $this = $node unless $this;

    $Redraw = 'none';
    ChangingFile(0);
}

#bind infer_clause_head Ctrl+Down menu Move to the Inferior Clause Head
sub infer_clause_head {

    my $node = $this;

    do { $this = $this->following($node) } while $this and not isClauseHead($this);

    $this = $node unless $this;

    $Redraw = 'none';
    ChangingFile(0);
}

# ##################################################################################################
#
# ##################################################################################################

sub path (@) {

    return File::Spec->join(@_);
}

sub escape ($) {

    return $^O eq 'MSWin32' ? '"' . $_[0] . '"' : "'" . $_[0] . "'";
}

sub espace ($) {

    my $name = $_[0];

    $name =~ s/\\/\//g if $^O eq 'MSWin32' and $name =~ / /;

    return escape $name;
}

sub inter_with_level ($) {

    my ($inter, $level) = ('syntax', $_[0]);

    my (@file, $path, $name, $exts);

    my $file = File::Spec->canonpath(FileName());

    ($name, $path, $exts) = fileparse($file, '.exclude.pml', '.pml');

    ($name, undef, undef) = fileparse($name, ".$inter");

    $file[0] = path $path, $name . ".$inter" . $exts;

    $file[1] = $level eq 'elixir' ? ( path $path, $name . ".$level" . (substr $exts, 0, -3) . "dat" )
                                  : ( path $path, $name . ".$level" . $exts );

    $file[2] = $level eq 'morpho' ? ( path $path, $name . ".$inter" . $exts )
                                  : ( path $path, $name . ".$level" . $exts );

    $file[3] = path $path, $name . ".$inter.pml.anno.pml";

    unless ($file[0] eq $file) {

        ToplevelFrame()->messageBox (
            -icon => 'warning',
            -message => "This file's name does not fit the directory structure!$fill\n" .
                        "Relocate it to " . $name . ".$inter" . $exts . ".$fill",
            -title => 'Error',
            -type => 'OK',
        );

        return;
    }

    return $level, $name, $path, @file;
}

# #bind synchronize_file Ctrl+Alt+equal menu Action: Synchronize Annotations
sub synchronize_file {

    ChangingFile(0);

    my $reply = GUI() ? main::userQuery($grp, "\nDo you wish to synchronize this file's annotations?$fill",
            -bitmap=> 'question',
            -title => "Synchronizing",
            -buttons => ['Yes', 'No']) : 'Yes';

    return unless $reply eq 'Yes';

    warn "Synchronizing ...\n";

    my ($level, $name, $path, @file) = inter_with_level 'morpho';

    return unless defined $level;

    unless (-f $file[1]) {

        if (GUI()) {

            ToplevelFrame()->messageBox (
                -icon => 'warning',
                -message => "There is no " . $name . ".$level.pml" . " file.$fill\n" .
                            "Make sure you are working with complete data!$fill",
                -title => 'Error',
                -type => 'OK',
            );
        }
        else {

            warn "There is no " . $name . ".$level.pml" . " file!\n";
        }

        return;
    }

    if (-f $file[2]) {

        if (GUI()) {

            ToplevelFrame()->messageBox (
                -icon => 'warning',
                -message => "Cannot create " . ( path '..', 'syntax', $name . '.syntax.pml' ) . "!$fill\n" .
                            "Please remove " . ( path '..', "$level", $name . '.syntax.pml' ) . ".$fill",
                -title => 'Error',
                -type => 'OK',
            );
        }
        else {

            warn "Cannot create " . $name . '.syntax.pml' . "!\n";
        }

        return;
    }

    if (GetFileSaveStatus()) {

        if (GUI()) {

            ToplevelFrame()->messageBox (
                -icon => 'warning',
                -message => "The current file has been modified. Either save it, or reload it discarding the changes.$fill",
                -title => 'Error',
                -type => 'OK',
            );
        }
        else {

            warn "The current file has been modified. Either save it, or reload it discarding the changes.\n";
        }

        return;
    }

    my ($tree, $node);

    $tree = CurrentTreeNumber() + 1;
    $node = $this->{'ord'};

    move $file[0], $file[3];

    system 'btred -QI ' . ( escape CallerDir('../../exec/morpho_syntax.ntred') ) .
                    ' ' . ( espace $file[1] );

    move $file[2], $file[0];

    system 'btred -QI ' . ( escape CallerDir('../../exec/migrate_annotation_syntax.ntred') ) .
                    ' ' . ( espace $file[0] );

    warn "... succeeded.\n";

    if (GUI()) {

        main::reloadFile($grp);

        GotoTree($tree);

        $this = $this->following() until $this->{'ord'} == $node;
    }
}

#bind open_level_words_prime Alt+0
sub open_level_words_prime {

    open_level_words();
}

#bind open_level_morpho_prime Alt+1
sub open_level_morpho_prime {

    open_level_morpho();
}

#bind open_level_syntax_prime Alt+2
sub open_level_syntax_prime {

    open_level_syntax();
}

#bind open_level_tecto_prime Alt+3
sub open_level_tecto_prime {

    open_level_tecto();
}

#bind open_level_words Ctrl+Alt+0 menu Action: Edit Syntax File
sub open_level_words {

    ChangingFile(0);

    my ($level, $name, $path, @file) = inter_with_level 'words';

    return unless defined $level;

    unless (-f $file[1]) {

        ToplevelFrame()->messageBox (
            -icon => 'warning',
            -message => "There is no " . $name . ".$level.pml" . " file!$fill",
            -title => 'Error',
            -type => 'OK',
        );

        return;
    }

    my @id = idx($root);

    my $id = join 'w-', split 's-', $this->{'id'};

    if (Open($file[1])) {

        GotoTree($id[0]);

        $this = PML::GetNodeByID($id);
    }
    else {

        SwitchContext('PADT::Syntax');
    }
}

#bind open_level_morpho Ctrl+Alt+1 menu Action: Edit MorphoTrees File
sub open_level_morpho {

    ChangingFile(0);

    my ($level, $name, $path, @file) = inter_with_level 'morpho';

    return unless defined $level;

    unless (-f $file[1]) {

        ToplevelFrame()->messageBox (
            -icon => 'warning',
            -message => "There is no " . $file[1] . " file!$fill",
            -title => 'Error',
            -type => 'OK',
        );

        return;
    }

    my ($tree, %id) = (idx($root));

    $id{$_} = exists $this->{$_} && exists $this->{$_}{'id'} ? $this->{$_}{'id'} : '' foreach 'm', 'w';

    if (Open($file[1])) {

        GotoTree($tree);

        $this = PML::GetNodeByID($id{'m'}) || PML::GetNodeByID($id{'w'}) || $root;
    }
    else {

        SwitchContext('PADT::Syntax');
    }
}

#bind open_level_syntax Ctrl+Alt+2 menu Action: Edit Syntax File
sub open_level_syntax {

    ChangingFile(0);
}

#bind open_level_tecto Ctrl+Alt+3 menu Action: Edit DeepLevels File
sub open_level_tecto {

    ChangingFile(0);

    my ($level, $name, $path, @file) = inter_with_level 'deeper';

    return unless defined $level;

    unless (-f $file[1]) {

        my $reply = main::userQuery($grp,
                        "\nThere is no " . $file[1] . " file.$fill" .
                        "\nReally create a new one?$fill",
                        -bitmap=> 'question',
                        -title => "Creating",
                        -buttons => ['Yes', 'No']);

        return unless $reply eq 'Yes';

        if (-f $file[2]) {

            ToplevelFrame()->messageBox (
                -icon => 'warning',
                -message => "Cannot create " . ( path '..', "$level", $name . ".$level.pml" ) . "!$fill\n" .
                            "Please remove " . ( path '..', 'syntax', $name . ".$level.pml" ) . ".$fill",
                -title => 'Error',
                -type => 'OK',
            );

            return;
        }

        if (GetFileSaveStatus()) {

            ToplevelFrame()->messageBox (
                -icon => 'warning',
                -message => "The current file has been modified. Either save it, or reload it discarding the changes.$fill",
                -title => 'Error',
                -type => 'OK',
            );

            return;
        }

        system 'btred -QI ' . ( escape CallerDir('../../exec/syntax_deeper.ntred') ) .
                        ' ' . ( espace $file[0] );

        mkdir path $path, "$level" unless -d path $path, "$level";

        move $file[2], $file[1];
    }

    my ($tree, $node) = idx($this);

    if (Open($file[1])) {

        GotoTree($tree);

        $this = $this->following() until $this->{'y_ord'} eq $node;
    }
    else {

        SwitchContext('PADT::Syntax');
    }
}

#bind ThisAddressClipBoard Ctrl+Return menu ThisAddress() to Clipboard
sub ThisAddressClipBoard {

    my $reply = main::userQuery($grp,
                        "\nCopy this node's address to clipboard?$fill",
                        -bitmap=> 'question',
                        -title => "Clipboard",
                        -buttons => ['Yes', 'No']);

    return unless $reply eq 'Yes';

    my $widget = ToplevelFrame();

    $widget->clipboardClear();
    $widget->clipboardAppend(ThisAddress());

    $Redraw = 'none';
    ChangingFile(0);
}

#bind synchronize Ctrl+Alt+equal menu Synchronize with Morpho
sub synchronize {

    my $name = $grp->{'FSFile'}->referenceNameHash()->{'morpho'};
    my $file = $grp->{'FSFile'}->referenceObjectHash()->{$name}->convert_to_fsfile();
    
    return unless defined $file;

    my $m = [ map { $_, map {
        
                    my @group = grep { exists $_->{"form"} and $_->{"form"} ne "" } $_->children();
                    
                    @group == 1 ? $group[0]->children() : $_
            
                    } $_->children() } $file->trees() ];
    
    my $s = [ map { sort { $a->{'ord'} <=> $b->{'ord'} } GetNodes($_) } GetTrees() ];

    print "Synchronizing ... " . (scalar @{$m}) . " " . (scalar @{$s}) . "\n";

    Algorithm::Diff::traverse_balanced($m, $s, {

        'MATCH' => sub {

            if ($m->[$_[0]]->{'#name'} eq 'Word') {

                if (exists $s->[$_[1]]->{'m'} and exists $s->[$_[1]]->{'m'}{'id'}) {

                    warn "W" . "\t" . ThisAddress($m->[$_[0]], $file) . "\t" . $m->[$_[0]]->{'id'} . "\n";
                    warn "N" . "\t" . ThisAddress($s->[$_[1]]) . "\t" . $s->[$_[1]]->{'id'} . "\n";
                }
            }
            if ($m->[$_[0]]->{'#name'} eq 'Token') {

                $s->[$_[1]]->{'m'} = Treex::PML::Factory->createStructure() unless exists $s->[$_[1]]->{'m'};

                if (exists $s->[$_[1]]->{'m'}{'id'} and $s->[$_[1]]->{'m'}{'id'} ne $m->[$_[0]]->{'id'}) {

                    warn "T" . "\t" . ThisAddress($m->[$_[0]], $file) . "\t" . $m->[$_[0]]->{'id'} . "\n";
                    warn "N" . "\t" . ThisAddress($s->[$_[1]]) . "\t" . $s->[$_[1]]->{'id'} . "\n";
                }
                else {

                    $s->[$_[1]]->{'m'}{'id'} = 'm#' . $m->[$_[0]]->{'id'};
                }
            }
        },

        'CHANGE' => sub {

            # $m->[$_[1]]->{'w.rf'} = 'w#' . $w->[$_[0]]->{'id'};

            warn "--" . "\t" . ThisAddress($m->[$_[0]], $file) . "\t" . $m->[$_[0]]->{'id'} . "\n";
            warn "++" . "\t" . ThisAddress($s->[$_[1]]) . "\t" . $s->[$_[1]]->{'id'} . "\n";
        },

        'DISCARD_A' => sub {

            if ($m->[$_[0]]->{'#name'} eq 'Word') {

                # create a new node pointing to word
            }
            else {

                # create new nodes pointing to tokens
            }

            warn "--" . "\t" . ThisAddress($m->[$_[0]], $file) . "\t" . $m->[$_[0]]->{'id'} . "\n";
        },

        'DISCARD_B' => sub {

            if ($m->[$_[0]]->{'#name'} eq 'Word') {

            }
            else {

                # discard from syntax
            }

            warn "++" . "\t" . ThisAddress($s->[$_[1]]) . "\t" . $s->[$_[1]]->{'id'} . "\n";
        },

    }, sub { $_[0]->{'#name'} eq 'Unit' ? $_[0]->{'id'}
             : $_[0]->{'#name'} eq 'Word' ? $_[0]->{'id'}
             : $_[0]->{'#name'} eq 'Token' ? $_[0]->parent()->parent()->{'id'}
             : exists $_[0]->{'w'} ? exists $_[0]->{'w'}{'id'} ? $_[0]->{'w'}{'id'} : ''
             : '' });

    ChangingFile(1);
}

# ##################################################################################################
#
# ##################################################################################################

no strict;

1;


=head1 NAME

PADT::Syntax - Context for Annotation of Analytical Syntax in the TrEd Environment


=head1 DESCRIPTION

Prague Arabic Dependency Treebank L<http://ufal.mff.cuni.cz/padt/online/>

TrEd Tree Editor L<http://ufal.mff.cuni.cz/tred/>


=head1 AUTHOR

Otakar Smrz C<< <otakar-smrz users.sf.net> >>, L<http://otakar-smrz.users.sf.net/>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2013 Otakar Smrz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
