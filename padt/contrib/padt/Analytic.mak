# ########################################################################## Otakar Smrz, 2004/03/05
#
# Analytic Context for the TrEd Environment ########################################################

# $Id$

package Analytic;

use 5.008;

use strict;

use List::Util 'reduce';

use File::Spec;
use File::Copy;

use File::Basename;

our $VERSION = join '.', '1.1', q $Revision$ =~ /(\d+)/;

# ##################################################################################################
#
# ##################################################################################################

#binding-context Analytic

BEGIN { import TredMacro; }

our ($this, $root, $grp);

our ($Redraw);

our ($hooks_request_mode, $fill) = (0, ' ' x 4);

# ##################################################################################################
#
# ##################################################################################################

sub AfunAssign {

    my $fullafun = $_[0];
    my ($afun, $parallel, $paren) = ($fullafun =~ /^([^_]*)(?:_(Ap|Co))?(?:_(Pa))?/);

    if ($this->{'afun'} eq 'AuxS' or
        $this->{'afun'} eq $afun and $this->{'parallel'} eq $parallel and $this->{'paren'} eq $paren) {

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

#bind afun_ExD to x menu Arabic: Assign afun ExD
sub afun_ExD { AfunAssign('ExD') }
#bind afun_ExD_Co to Ctrl+x
sub afun_ExD_Co { AfunAssign('ExD_Co') }
#bind afun_ExD_Ap to X
sub afun_ExD_Ap { AfunAssign('ExD_Ap') }
#bind afun_ExD_Pa to Ctrl+X
sub afun_ExD_Pa { AfunAssign('ExD_Pa') }

#bind afun_AuxE to e menu Arabic: Assign afun AuxE
sub afun_AuxE { AfunAssign('AuxE') }
#bind afun_AuxE_Co to Ctrl+e
sub afun_AuxE_Co { AfunAssign('AuxE_Co') }
#bind afun_AuxE_Ap to E
sub afun_AuxE_Ap { AfunAssign('AuxE_Ap') }
#bind afun_AuxE_Pa to Ctrl+E
sub afun_AuxE_Pa { AfunAssign('AuxE_Pa') }

#bind afun_AuxM to m menu Arabic: Assign afun AuxM
sub afun_AuxM { AfunAssign('AuxM') }
#bind afun_AuxM_Co to Ctrl+m
sub afun_AuxM_Co { AfunAssign('AuxM_Co') }
#bind afun_AuxM_Ap to M
sub afun_AuxM_Ap { AfunAssign('AuxM_Ap') }
#bind afun_AuxM_Pa to Ctrl+M
sub afun_AuxM_Pa { AfunAssign('AuxM_Pa') }

#bind afun_Ante to t menu Arabic: Assign afun Ante
sub afun_Ante { AfunAssign('Ante') }
#bind afun_Ante_Co to Ctrl+t
sub afun_Ante_Co { AfunAssign('Ante_Co') }
#bind afun_Ante_Ap to T
sub afun_Ante_Ap { AfunAssign('Ante_Ap') }
#bind afun_Ante_Pa to Ctrl+T
sub afun_Ante_Pa { AfunAssign('Ante_Pa') }

#bind assign_parallel to key 1 menu Arabic: Suffix Parallel
sub assign_parallel {
  $this->{parallel}||='';
  EditAttribute($this,'parallel');
}

#bind assign_paren to key 2 menu Arabic: Suffix Paren
sub assign_paren {
  $this->{paren}||='';
  EditAttribute($this,'paren');
}

#bind assign_arabfa to key 3 menu Arabic: Suffix ArabFa
sub assign_arabfa {
  $this->{arabfa}||='';
  EditAttribute($this,'arabfa');
}

#bind assign_arabspec to key 4 menu Arabic: Suffix ArabSpec
sub assign_arabspec {
  $this->{arabspec}||='';
  EditAttribute($this,'coref');
}

#bind assign_arabclause to key 5 menu Arabic: Suffix ArabClause
sub assign_arabclause {
  $this->{arabclause}||='';
  EditAttribute($this,'clause');
}

# ##################################################################################################
#
# ##################################################################################################

#bind thisToParent to Alt+Up menu Annotate: Current node up one level to grandparent
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

#bind thisToRBrother to Alt+Left menu Annotate: Current node to brother on the left
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

#bind thisToLBrother to Alt+Right menu Annotate: Current node to brother on the right
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

#bind thisToParentRBrother to Alt+Shift+Left menu Annotate: Current node to uncle on the left
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

#bind thisToParentLBrother to Alt+Shift+Right menu Annotate: Current node to uncle on the right
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

#bind thisToEitherBrother to Alt+Down menu Annotate: Current node to either side brother if unique
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

#bind SwapNodesUp to Alt+Shift+Down menu Annotate: Current node exchanged with parent
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

##bind SwapNodesDown to Alt+Shift+Down menu Annotate: Current node exchanged with son if unique
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

#bind thisToRoot to Alt+Shift+Up menu Annotate: Current node to the root
sub thisToRoot {

    $Redraw = 'none';
    ChangingFile(0);

    return unless $this and $this->parent();

    return unless $root;

    CutPaste($this, $root);

    $Redraw = 'tree';
    ChangingFile(1);
}

#bind thisToLeftClauseHead to Ctrl+Alt+Right menu Annotate: Current node to preceeding clause head
sub thisToLeftClauseHead {

    $Redraw = 'none';
    ChangingFile(0);

    return unless $this and $this->parent();

    $main::treeViewOpts->{reverseNodeOrder} && ! InVerticalMode() ?
        thisToPrevClauseHead() :
        thisToNextClauseHead();
}

#bind thisToRightClauseHead to Ctrl+Alt+Left menu Annotate: Current node to following clause head
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

#bind thisToSuperClauseHead to Ctrl+Alt+Up menu Annotate: Current node to superior clause head
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

#bind thisToInferClauseHead to Ctrl+Alt+Down menu Annotate: Current node to inferior clause head
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

style:<? Analytic::isClauseHead() ? '#{Line-fill:gold}' : '' ?>

node:<? exists $this->{'morpho'}{'Token'} ? '${morpho/Token/form}' :
        exists $this->{'morpho'}{'Word'} ? '#{custom6}${morpho/Word/form}' :
        '#{custom2}${form} ' . Analytic::idx($this) ?>

node:<? join '_', ( $this->{'afun'} eq '???' && exists $this->{'score'} && @{$this->{'score'}}
                        ? '#{custom3}' . join " ", map { $_->{'#content'} } @{$this->{'score'}}
                        : '#{custom1}${afun}' ),
                    map { '#{custom1}${' . $_ . '}' } grep { $this->attr($_) ne '' }
                        qw 'parallel paren arabfa coref clause' ?>

node:<? exists $this->{'morpho'}{'Token'} ? (
        exists $this->{'morpho'}{'Token'}{'note'} &&
               $this->{'morpho'}{'Token'}{'note'} ne '' ? '#{custom6}${morpho/Token/note} << ' : ''
        ) . '#{custom2}${morpho/Token/tag}' : '' ?>

hint:<? exists $this->{'morpho'}{'Token'} ? join "\n", 'tag: ${morpho/Token/tag}',
                                                       'lemma: ${morpho/Lexeme/form}',
                                                       'morphs: ${morpho/Token/morphs}',
                                                       'gloss: ${morpho/Token/gloss}',
                                                       'note: ${morpho/Token/note}' : '' ?>
>>
}

sub idx {

    my $node = $_[0] || $this;

    my @idx = grep { $_ ne '' } split /[^0-9]+/, $node->{'id'};

    return wantarray ? @idx : ( "#" . join "/", @idx );
}

sub morpho_structure {

    my $node = $this->root();

    unless (exists $node->{'form'} or not exists $node->{'m'}{'tag'}) {

        $node->{'form'} = $node->{'m'}{'tag'};

        delete $node->{'m'};
    }

    while ($node = $node->following()) {

        next if exists $node->{'morpho'} or not exists $node->{'m'};

        $node->{'morpho'} = new Fslib::Struct;

        if (exists $node->{'m'}{'input'} and $node->{'m'}{'input'} ne '') {

            $node->{'morpho'}{'Word'} = new Fslib::Struct;

            $node->{'morpho'}{'Word'}{'form'} = $node->{'m'}{'input'};
        }

        if (exists $node->{'m'}{'lemma'} and $node->{'m'}{'lemma'} ne '') {

            $node->{'morpho'}{'Lexeme'} = new Fslib::Struct;

            $node->{'morpho'}{'Lexeme'}{'form'} = $node->{'m'}{'lemma'};
        }

        if (exists $node->{'m'}{'form'} and $node->{'m'}{'form'} ne '') {

            $node->{'morpho'}{'Token'} = new Fslib::Struct;

            $node->{'morpho'}{'Token'}{'form'} = $node->{'m'}{'form'};

            if (exists $node->{'m'}{'morph'} and $node->{'m'}{'morph'} ne '') {

                $node->{'morpho'}{'Token'}{'morphs'} = $node->{'m'}{'morph'};
            }

            if (exists $node->{'m'}{'tag'} and $node->{'m'}{'tag'} ne '') {

                $node->{'morpho'}{'Token'}{'tag'} = $node->{'m'}{'tag'};
            }

            if (exists $node->{'m'}{'gloss'} and $node->{'m'}{'gloss'} ne '') {

                $node->{'morpho'}{'Token'}{'gloss'} = $node->{'m'}{'gloss'};
            }
        }

        if (exists $node->{'m'}{'note'} and $node->{'m'}{'note'} ne '') {

            if (exists $node->{'morpho'}{'Token'}) {

                $node->{'morpho'}{'Token'}{'note'} = $node->{'m'}{'note'};
            }
            elsif (exists $node->{'morpho'}{'Word'}) {

                $node->{'morpho'}{'Word'}{'note'} = $node->{'m'}{'note'};
            }
            else {

                warn "Problems with " . ThisAddress($node) . "\n" and next;
            }
        }

        delete $node->{'m'};
    }
}

sub switch_context_hook {

    &PADT::switch_context_hook;
}

sub pre_switch_context_hook {

    &PADT::pre_switch_context_hook;
}

sub get_auto_afun {

    require Assign_arab_afun;

    my ($ra, $rb, $rc) = Assign_arab_afun::afun($_[0]);

    print STDERR "$this->{lemma} ($ra,$rb,$rc)\n";

    return $ra =~ /^\s*$/ ? '' : $ra;
}

#bind request_auto_afun_node Ctrl+Shift+F9 menu Arabic: Request auto afun for current node
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

#bind request_auto_afun_subtree to Ctrl+Shift+F10 menu Arabic: Request auto afun for current subtree
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

#bind hooks_request_mode Ctrl+Shift+F8 menu Arabic: Toggle request mode for auto afuns
sub hooks_request_mode {

    $hooks_request_mode = not $hooks_request_mode;

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

                   show_value_line_node($views, $_, exists $_->{'morpho'}{'Word'} ? 'morpho/Word/form' : '',
                                                    not exists $_->{'morpho'}{'Token'})

               } @{$nodes}[1 .. $#{$nodes}] ];

    @{$words} = reverse @{$words} if $main::treeViewOpts->{reverseNodeOrder};

    return $words;
}

sub show_value_line_node {

    my ($view, $node, $text, $warn) = @_;

    if (HiddenVisible()) {

        return  unless exists $node->{'morpho'}{'Word'} and exists $node->{'morpho'}{'Word'}{'form'} and
                                                                   $node->{'morpho'}{'Word'}{'form'} ne '';

        return  [ $node->attr($text), $node, exists $view->{$node->{'ord'}} ? $warn ? '-foreground => red' : ()
                                                                                    : '-foreground => gray' ],
                [ " " ];
    }
    else {

        return  [ '.....', $view->{$node->{'ord'} - 1}, '-foreground => magenta' ],
                [ " " ]
                        if not exists $view->{$node->{'ord'}} and exists $view->{$node->{'ord'} - 1};

        return  unless exists $view->{$node->{'ord'}} and exists $node->{'morpho'}{'Word'} and exists $node->{'morpho'}{'Word'}{'form'} and
                                                                                                      $node->{'morpho'}{'Word'}{'form'} ne '';

        return  [ $node->attr($text), $node, $warn ? '-foreground => red' : () ],
                [ " " ];
    }
}

sub highlight_value_line_tag_hook {

    my $node = $grp->{currentNode};

    $node = PrevNodeLinear($node, 'ord') until !$node or exists $node->{'morpho'}{'Word'} and exists $node->{'morpho'}{'Word'}{'form'} and
                                                                                                     $node->{'morpho'}{'Word'}{'form'} ne '';

    return $node;
}

sub node_release_hook {

    my ($node, $done) = @_;
    my (@line);

    return unless $done;

    return unless $hooks_request_mode;

    until ($done->{'afun'} ne '???' or exists $done->{'score'} and @{$done->{'score'}} > 0) {

        unshift @line, $done;

        $done = $done->parent();
    }

    request_auto_afun_node($_) foreach @line, $node;
}

sub node_moved_hook {

    return unless $hooks_request_mode;

    my (undef, $done) = @_;

    my @line;

    until ($done->{'afun'} ne '???' or exists $done->{'score'} and @{$done->{'score'}} > 0) {

        unshift @line, $done;

        $done = $done->parent();
    }

    request_auto_afun_node($_) foreach @line;
}

# bind padt_auto_parse_tree to Ctrl+Shift+F2 menu Arabic: Parse the current sentence and build a tree
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
    return Analytic::referring_Ref($this);
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
    return Analytic::referring_Msd($this);
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

    return $this->{'clause'} ne "" || exists $this->{'morpho'}{'Token'} &&
                                             $this->{'morpho'}{'Token'}{'tag'} =~ /^V/ &&
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

            return $_[0] if $_[0]->{'afun'} eq 'Atr' and exists $_[0]->{'morpho'}{'Token'} and
                                                                $_[0]->{'morpho'}{'Token'}{'tag'} =~ /^A/
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

    $head = $head->parent() until not $head or exists $head->{'morpho'}{'Token'} and
                                                      $head->{'morpho'}{'Token'}{'tag'} =~ /^[VNA]/;    # the verb, governing masdar or participle

    return $head;
}

# ##################################################################################################
#
# ##################################################################################################

sub enable_attr_hook {

    return 'stop' if $_[0] =~ /^morpho(?!\w)/;
}

#bind edit_note to exclam menu Annotate: Edit Annotation Note
sub edit_note {

    $Redraw = 'none';
    ChangingFile(0);

    my $note = $grp->{FSFile}->FS->exists('note') ? 'note' : undef;

    unless (defined $note) {

        ToplevelFrame()->messageBox (
            -icon => 'warning',
            -message => "No attribute for annotator's note in this file",
            -title => 'Sorry',
            -type => 'OK',
        );

        return;
    }

    my $value = $this->{$note};

    $value = main::QueryString($grp->{framegroup}, "Enter note", $note, $value);

    if (defined $value) {

        $this->{$note} = $value;

        $Redraw = 'tree';
        ChangingFile(1);
    }
}

#bind default_ar_attrs to F8 menu Display: Show / hide morphological tags
sub default_ar_attrs {

    return unless $grp->{FSFile};

    my ($type, $pattern) = ('node:', '#{custom2}${morpho/Token/tag}');

    my $code = q {<? exists $this->{'morpho'}{'Token'} ? (
        exists $this->{'morpho'}{'Token'}{'note'} &&
               $this->{'morpho'}{'Token'}{'note'} ne '' ? '#{custom6}${morpho/Token/note} << ' : ''
        ) . '#{custom2}${morpho/Token/tag}' : '' ?>};

    my ($hint, $cntxt, $style) = GetStylesheetPatterns();

    my @filter = grep { $_ !~ /^(?:\Q${type}\E\s*)?(?:\Q${code}\E|\Q${pattern}\E)$/ } @{$style};

    SetStylesheetPatterns([ $hint, $cntxt, [ @filter, @{$style} == @filter ? $type . ' ' . $code : () ] ]);

    ChangingFile(0);
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

#bind accept_auto_afun Ctrl+space menu Arabic: Accept auto-assigned annotation
sub accept_auto_afun {

    my $node = $this;

    if ($this->{'afun'} ne '???' or exists $this->{'score'} and @{$this->{'score'}} > 0) {

        $Redraw = 'none';
        ChangingFile(0);
    }
    else {

        $this->{'afun'} = $this->{'score'}[0]{'#content'};
        shift @{$this->{'score'}};

        $Redraw = 'tree';
    }
}

#bind unset_afun to question menu Arabic: Unset afun to ???
sub unset_afun {

    if ($this->{'afun'} eq 'AuxS' or $this->{'afun'} eq '???') {

        $Redraw = 'none';
        ChangingFile(0);
    }
    else {

        $this->{'afun'} = '???';
        shift @{$this->{'score'}};

        $Redraw = 'tree';
    }
}

#bind unset_request_afun to Ctrl+question menu Arabic: Unset and request auto afun
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

#bind move_deep_home Ctrl+Home menu Move to Rightmost Descendant
sub move_deep_home {

    $this = $this->leftmost_descendant();

    $this = PrevVisibleNode($this) if IsHidden($this);

    $Redraw = 'none';
    ChangingFile(0);
}

#bind move_deep_end Ctrl+End menu Move to Leftmost Descendant
sub move_deep_end {

    $this = $this->rightmost_descendant();

    $this = NextVisibleNode($this) || PrevVisibleNode($this) if IsHidden($this);

    $Redraw = 'none';
    ChangingFile(0);
}

#bind move_par_home Shift+Home menu Move to First Paragraph
sub move_par_home {

    GotoTree(1);

    $Redraw = 'win';
    ChangingFile(0);
}

#bind move_par_end Shift+End menu Move to Last Paragraph
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

    my $level = $_[0];

    my (@file, $path, $name);

    my $thisfile = File::Spec->canonpath(FileName());

    ($name, $path, undef) = fileparse($thisfile, '.syntax.xml');

    $file[0] = path $path, $name . '.syntax.xml';
    $file[1] = path $path, $name . ".$level.xml";

    $file[2] = $level eq 'morpho' ? ( path $path, $name . '.syntax.xml' )
                                  : ( path $path, $name . ".$level.xml" );

    $file[3] = path $path, $name . '.syntax.xml.anno.xml';

    $file[4] = $level eq 'morpho' ? ( path $path, $name . '.syntax.fs' )
                                  : ( undef );

    unless ($file[0] eq $thisfile) {

        ToplevelFrame()->messageBox (
            -icon => 'warning',
            -message => "This file's name does not fit the directory structure!$fill\n" .
                        "Relocate it to " . $name . '.syntax.xml' . ".$fill",
            -title => 'Error',
            -type => 'OK',
        );

        return;
    }

    return $level, $name, $path, @file;
}

#bind synchronize_file to Ctrl+Alt+equal menu Action: Synchronize Annotations
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
                -message => "There is no " . $name . ".$level.xml" . " file.$fill\n" .
                            "Make sure you are working with complete data!$fill",
                -title => 'Error',
                -type => 'OK',
            );
        }
        else {

            warn "There is no " . $name . ".$level.xml" . " file!\n";
        }

        return;
    }

    if (-f $file[2]) {

        if (GUI()) {

            ToplevelFrame()->messageBox (
                -icon => 'warning',
                -message => "Cannot create " . ( path '..', 'syntax', $name . '.syntax.xml' ) . "!$fill\n" .
                            "Please remove " . ( path '..', "$level", $name . '.syntax.xml' ) . ".$fill",
                -title => 'Error',
                -type => 'OK',
            );
        }
        else {

            warn "Cannot create " . $name . '.syntax.xml' . "!\n";
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

#bind open_level_words_prime to Alt+0
sub open_level_words_prime {

    open_level_words();
}

#bind open_level_morpho_prime to Alt+1
sub open_level_morpho_prime {

    open_level_morpho();
}

#bind open_level_syntax_prime to Alt+2
sub open_level_syntax_prime {

    open_level_syntax();
}

#bind open_level_tecto_prime to Alt+3
sub open_level_tecto_prime {

    open_level_tecto();
}

#bind open_level_words to Ctrl+Alt+0 menu Action: Edit Analytic File
sub open_level_words {

    ChangingFile(0);

    my ($level, $name, $path, @file) = inter_with_level 'words';

    return unless defined $level;

    unless (-f $file[1]) {

        ToplevelFrame()->messageBox (
            -icon => 'warning',
            -message => "There is no " . $name . ".$level.xml" . " file!$fill",
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

        SwitchContext('Analytic');
    }
}

#bind open_level_morpho to Ctrl+Alt+1 menu Action: Edit MorphoTrees File
sub open_level_morpho {

    ChangingFile(0);

    my ($level, $name, $path, @file) = inter_with_level 'morpho';

    return unless defined $level;

    unless (-f $file[1]) {

        ToplevelFrame()->messageBox (
            -icon => 'warning',
            -message => "There is no " . $name . ".$level.xml" . " file!$fill",
            -title => 'Error',
            -type => 'OK',
        );

        return;
    }

    my ($tree, $id) = (idx($root), join 'm-', split 's-', $this->{'id'});

    if (Open($file[1])) {

        GotoTree($tree);

        $this = PML::GetNodeByID($id);
    }
    else {

        SwitchContext('Analytic');
    }
}

#bind open_level_syntax to Ctrl+Alt+2 menu Action: Edit Analytic File
sub open_level_syntax {

    ChangingFile(0);
}

#bind open_level_tecto to Ctrl+Alt+3 menu Action: Edit DeepLevels File
sub open_level_tecto {

    ChangingFile(0);

    my ($level, $name, $path, @file) = inter_with_level 'deeper';

    return unless defined $level;

    unless (-f $file[1]) {

        my $reply = main::userQuery($grp,
                        "\nThere is no " . $name . ".$level.xml" . " file.$fill" .
                        "\nReally create a new one?$fill",
                        -bitmap=> 'question',
                        -title => "Creating",
                        -buttons => ['Yes', 'No']);

        return unless $reply eq 'Yes';

        if (-f $file[2]) {

            ToplevelFrame()->messageBox (
                -icon => 'warning',
                -message => "Cannot create " . ( path '..', "$level", $name . ".$level.xml" ) . "!$fill\n" .
                            "Please remove " . ( path '..', 'syntax', $name . ".$level.xml" ) . ".$fill",
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

        SwitchContext('Analytic');
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

# ##################################################################################################
#
# ##################################################################################################

no strict;

1;


=head1 NAME

Analytic - Context for Annotation of Analytical Syntax in the TrEd Environment


=head1 REVISION

    $Revision$       $Date$


=head1 DESCRIPTION

For reference, see the list of Analytic macros and key-bindings in the User-defined menu item in TrEd.


=head1 SEE ALSO

TrEd Tree Editor L<http://ufal.mff.cuni.cz/~pajas/tred/>

Prague Arabic Dependency Treebank L<http://ufal.mff.cuni.cz/padt/online/>


=head1 AUTHOR

Otakar Smrz, L<http://ufal.mff.cuni.cz/~smrz/>

    eval { 'E<lt>' . ( join '.', qw 'otakar smrz' ) . "\x40" . ( join '.', qw 'mff cuni cz' ) . 'E<gt>' }

Perl is also designed to make the easy jobs not that easy ;)


=head1 COPYRIGHT AND LICENSE

Copyright 2004-2009 by Otakar Smrz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
