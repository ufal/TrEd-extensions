# ########################################################################## Otakar Smrz, 2004/03/05
#
# MorphoTrees Context for the TrEd Environment #####################################################

# $Id$

package MorphoTrees;

use 5.008;

use strict;

use ElixirFM;

use Exec::ElixirFM;

use Encode::Arabic ':modes';

use File::Spec;
use File::Copy;

our $VERSION = join '.', '1.1', q $Revision$ =~ /(\d+)/;

# ##################################################################################################
#
# ##################################################################################################

#binding-context MorphoTrees

BEGIN { import TredMacro; }

our ($this, $root, $grp);

our ($Redraw);

our ($paragraph_hide_mode, $entity_hide_mode, $level_guide_mode) = ('', '', 0);

our ($dims, $fill) = (10, ' ' x 4);

# ##################################################################################################
#
# ##################################################################################################

sub CreateStylesheets {

    return << '>>';

style:<? $this->{apply} > 0 ? '#{Line-fill:red}' :
             $this->{score} > 0 ? '#{Line-fill:orange}' :
                 defined $this->{apply} ? '#{Line-fill:black}' : '' ?>

node:<? '#{magenta}${comment} << ' if $this->{'#name'} !~ /^(?:Token|Paragraph)$/
                                      and $this->{comment} ne ''
   ?><? $this->{'#name'} eq 'Token'
            ? ( ElixirFM::orph($this->{'form'}, "\n") )
            : (
            $this->{'#name'} eq 'Lexeme'
                ? ( ( $root->{'#name'} eq 'Element'
                        ? '#{purple}' . ( join ", ", exists $this->{'core'}{'reflex'} ?
                                                            @{$this->{'core'}{'reflex'}} : () ) . ' '
                        : '' ) .
                    '#{gray}${idx} #{darkmagenta}' .
                    ( $this->{'form'} eq '[DEFAULT]' ? $this->{'form'} : ElixirFM::phor($this->{'form'}) ) )
                : (
                $this->{'#name'} =~ /^(?:Component|Partition)$/
                    ? $this->{'form'}
                    : (
                    $this->{'#name'} =~ /^(?:Element|Paragraph)$/
                        ? ( $this->{apply} > 0
                            ? '#{black}${idx} #{gray}${lookup} #{red}${input}'
                            : '#{black}${idx} #{gray}${lookup} #{black}${input}'
                        )
                        : ( $this->{apply} > 0
                            ? '  #{red}${input}'
                            : '  #{black}${input}'
                        ) ) ) ) ?>

node:<? '#{goldenrod}${comment} << ' if $this->{'#name'} eq 'Token'
                                        and $this->{comment} ne ''
   ?>#{darkred}${tag}<? $this->{inherit} eq '' ? '#{red}' : '#{orange}'
   ?>${restrict}

hint:<? '${gloss}' if $this->{'#name'} eq 'Token' ?>
>>
}

sub switch_context_hook {

    &PADT::switch_context_hook;
}

sub pre_switch_context_hook {

    &PADT::pre_switch_context_hook;
}

sub node_release_hook {

    return 'stop' if defined $_[0]->{'#name'};
}

sub get_nodelist_hook {

    my ($fsfile, $index, $recent, $show_hidden) = @_;
    my ($nodes, $current);

    my $tree = $fsfile->tree($index);

    if ($tree->{'#name'} eq 'Paragraph') {

        $tree->{'hide'} = '' unless defined $tree->{'hide'};

        if ($tree->{'hide'} ne $paragraph_hide_mode) {

            $tree->{'hide'} = $paragraph_hide_mode;
            $current = $tree;

            if ($paragraph_hide_mode eq 'hidden') {

                while ($current = $current->following()) {

                    $current->{'hide'} = $current->{'apply'} > 0 ? 'hide' : '';
                }
            }
            else {

                while ($current = $current->following()) {

                    $current->{'hide'} = '';
                }
            }
        }
    }
    else {

        $tree->{'hide'} = '' unless defined $tree->{'hide'};

        if ($tree->{'hide'} ne $entity_hide_mode) {

            $tree->{'hide'} = $entity_hide_mode;
            $current = $tree;

            if ($entity_hide_mode eq 'hidden') {

                while ($current = $current->following()) {

                    $current->{'hide'} = 'hide' if defined $current->{'tips'} and $current->{'tips'} == 0;
                }
            }
            else {

                while ($current = $current->following()) {

                    $current->{'hide'} = '' if defined $current->{'tips'} and $current->{'tips'} == 0;
                }
            }
        }
    }

    ($nodes, $current) = $fsfile->nodes($index, $recent, $show_hidden);

    @{$nodes} = reverse @{$nodes} if $main::treeViewOpts->{reverseNodeOrder};

    return [[@{$nodes}], $current];
}

sub get_value_line_hook {

    my ($fsfile, $index) = @_;
    my ($nodes, $words);

    my $tree = $fsfile->tree($index);

    if ($tree->{'#name'} eq 'Paragraph') {

        ($nodes, undef) = $fsfile->nodes($index, $this, 1);

        $words = [ [ $tree->{'idx'} . " " . $tree->{'input'}, $tree, '-foreground => darkmagenta' ],
                   map {
                            [ " " ],
                            [ $_->{'input'}, (

                                $paragraph_hide_mode eq 'hidden'

                                      ? ( $_->{'apply'} > 0
                                            ? ( $fsfile->tree($_->{'ref'} - 1), '-foreground => gray' )
                                            : ( $_, '-foreground => black' ) )
                                      : ( $_->{'apply'} > 0
                                            ? ( $_, '-foreground => red' )
                                            : ( $_, '-foreground => black' ) )
                                ) ]

                        } grep { $_->{'#name'} eq 'Word' } @{$nodes} ];
    }
    else {

        my $para = $fsfile->tree($tree->{'ref'} - 1);

        my $last = (split /[^0-9]+/, $para->{'par'})[1];
        my $next = 1;

        $nodes = [ map { $fsfile->tree($_) } $tree->{'ref'} .. ( $tree->{'ref'} == $last ? $grp->{FSFile}->lastTreeNo : $last - 2 ) ];

        $words = [ [ $para->{'idx'} . " " . $para->{'input'}, '#' . $tree->{'ref'}, '-foreground => purple' ],
                   map {
                            [ " " ],
                            [ $_->{'input'}, '#' . ( $tree->{'ref'} + $next++ ), $_ == $tree ? ( $_, '-underline => 1' ) : () ],

                        } grep { $_->{'#name'} eq 'Element' } @{$nodes} ];
    }

    @{$words} = reverse @{$words} if $main::treeViewOpts->{reverseNodeOrder};

    return $words;
}

sub highlight_value_line_tag_hook {

    return $grp->{root} if $grp->{root}->{'#name'} eq 'Element';

    my $node = $grp->{currentNode};

    $node = $node->parent() until !$node or $node->{'#name'} eq 'Word' or $node->{'#name'} eq 'Paragraph';

    return $node;
}

sub value_line_doubleclick_hook {

    return if $grp->{root}->{'#name'} eq 'Paragraph';

    my ($index) = map { $_ =~ /^#([0-9]+)/ ? $1 : () } @_;

    return 'stop' unless defined $index;

    GotoTree($index);
    Redraw();
    main::centerTo($grp, $grp->{currentNode});

    return 'stop';
}

sub node_doubleclick_hook {

    $grp->{currentNode} = $_[0];

    if ($_[1] eq 'Shift') {

        main::doEvalMacro($grp, __PACKAGE__ . '->switch_either_context');
    }
    else {

        main::doEvalMacro($grp, __PACKAGE__ . '->annotate_morphology');
    }

    return 'stop';
}

sub node_click_hook {

    $grp->{currentNode} = $_[0];

    if ($_[1] eq 'Shift') {

        main::doEvalMacro($grp, __PACKAGE__ . '->switch_either_context');
    }
    else {

        main::doEvalMacro($grp, __PACKAGE__ . '->annotate_morphology_click');
    }

    return 'stop';
}

#bind annotate_morphology_click to Ctrl+space menu Annotate as if by Clicking
sub annotate_morphology_click {

    annotate_morphology('click');
}

#bind switch_either_context Shift+space menu Switch Either Context
sub switch_either_context {

    $Redraw = 'win' unless $Redraw eq 'file' or $Redraw eq 'tree';

    ChangingFile(0);

    my $quick = $_[0];

    my $node = $this;

    if ($root->{'#name'} eq 'Paragraph') {

        if ($this->{'#name'} eq 'Paragraph') {

            GotoTree((split /[^0-9]+/, $root->{'par'})[0]);
        }
        elsif ($this->{'#name'} eq 'Word') {

            GotoTree($this->{'ref'});
        }
        else {

            if ($this->{'#name'} eq 'Lexeme') {

                GotoTree($this->parent()->{'ref'});
            }
            else {

                GotoTree($this->parent()->parent()->{'ref'});
            }

            ($node) = grep { $_->{'id'} eq $node->{'ref'} } map { $_, $_->children() }
                      grep { $_->{'apply'} > 0 } map { $_->children() }
                      grep { $_->{'apply'} > 0 } map { $_->children() } $root->children();

            $this = $node if defined $node;
        }
    }
    else {

        my ($refs) = $root->{'id'} =~ /([0-9]+)$/;

        GotoTree($root->{'ref'});

        $this = ($root->children())[$refs - 1];

        if ($quick ne 'quick' and $node->{'#name'} =~ /^(?:Lexeme|Token)$/) {

            ($node) = grep { $_->{'ref'} eq $node->{'id'} } $this->descendants();

            $this = $node if defined $node;
        }
    }
}

#bind move_to_prev_paragraph Shift+Prior menu Move to Prev Paragraph
sub move_to_prev_paragraph {

    unless ($root->{'#name'} eq 'Paragraph') {

        GotoTree($root->{'ref'});
    }

    GotoTree((split /[^0-9]+/, $root->{'par'})[0]);

    $Redraw = 'win';
    ChangingFile(0);
}

#bind move_to_next_paragraph Shift+Next menu Move to Next Paragraph
sub move_to_next_paragraph {

    unless ($root->{'#name'} eq 'Paragraph') {

        GotoTree($root->{'ref'});
    }

    GotoTree((split /[^0-9]+/, $root->{'par'})[1]);

    $Redraw = 'win';
    ChangingFile(0);
}

#bind move_word_home Home menu Move to First Word
sub move_word_home {

    if ($root->{'#name'} eq 'Paragraph') {

        $this = (grep { $_->{'hide'} ne 'hide' } $root->children())[0];

        $Redraw = 'none';
    }
    else {

        switch_either_context('quick');
        $this = ($root->children())[0];
        switch_either_context();

        $Redraw = 'win';
    }

    ChangingFile(0);
}

#bind move_word_end End menu Move to Last Word
sub move_word_end {

    if ($root->{'#name'} eq 'Paragraph') {

        $this = (grep { $_->{'hide'} ne 'hide' } $root->children())[-1];

        $Redraw = 'none';
    }
    else {

        switch_either_context('quick');
        $this = ($root->children())[-1];
        switch_either_context();

        $Redraw = 'win';
    }

    ChangingFile(0);
}

#bind move_next_home Ctrl+Home menu Move to First on Level
sub move_next_home {

    my $node = $this;
    my $level = $node->level();

    my ($done, @children);

    do {

        $done = $node if $level == $node->level();

        $node = PrevVisibleNode($node);
    }
    while $node;

    if ($done == $this and @children = grep { $_->{'hide'} ne 'hide' } $this->children()) {

        $this = $children[0];
    }
    else {

        $this = $done;
    }

    $Redraw = 'none';
    ChangingFile(0);
}

#bind move_next_end Ctrl+End menu Move to Last on Level
sub move_next_end {

    my $node = $this;
    my $level = $node->level();

    my ($done, @children);

    do {

        $done = $node if $level == $node->level();

        $node = NextVisibleNode($node);
    }
    while $node;

    if ($done == $this and @children = grep { $_->{'hide'} ne 'hide' } $this->children()) {

        $this = $children[-1];
    }
    else {

        $this = $done;
    }

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
    switch_either_context('quick');
    $this = $root;

    $Redraw = 'win';
    ChangingFile(0);
}

#bind tree_hide_mode Ctrl+equal menu Toggle Tree Hide Mode
sub tree_hide_mode {

    if ($root->{'#name'} eq 'Paragraph') {

        $paragraph_hide_mode = $paragraph_hide_mode eq 'hidden' ? '' : 'hidden';
    }
    else {

        $entity_hide_mode = $entity_hide_mode eq 'hidden' ? '' : 'hidden';
    }

    ChangingFile(0);
}

#bind level_guide_mode_none Ctrl+F1 menu Level Guide Mode Normal
sub level_guide_mode_none {

    $level_guide_mode = 0;

    ChangingFile(0);
}

#bind level_guide_mode_fine Ctrl+F2 menu Level Guide Mode Strict
sub level_guide_mode_fine {

    $level_guide_mode = 1;

    ChangingFile(0);
}

#bind level_guide_mode_high Ctrl+F3 menu Level Guide Mode Xtreme
sub level_guide_mode_high {

    $level_guide_mode = 2;

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

#bind follow_apply_up Ctrl+Up menu Follow Annotation Up
sub follow_apply_up {

    $Redraw = 'none';
    ChangingFile(0);

    my $node = $this->parent();

    return unless $node;

    if ($node->{'apply'} > 0) {

        $this = $node;

        return;
    }

    my $level = $node->level();

    my $done = $node;

    { do {

        $node = NextVisibleNode($node) until not $node or $node->level() == $level;
        $done = PrevVisibleNode($done) until not $done or $done->level() == $level;

        if ($node) {

            if ($node->{'apply'} > 0) {

                $this = $node;
                last;
            }

            $node = NextVisibleNode($node);
        }

        if ($done) {

            if ($done->{'apply'} > 0) {

                $this = $done;
                last;
            }

            $done = PrevVisibleNode($done);
        }
    }
    while $node or $done; }
}

#bind follow_apply_down Ctrl+Down menu Follow Annotation Down
sub follow_apply_down {

    my $node = $this;
    my (@children);

    while (@children = $node->children()) {

        @children = grep { $_->{'hide'} ne 'hide' and $_->{'apply'} > 0 } @children;

        last unless @children == 1;

        $node = $children[0];
    }

    $node = $children[0] if @children;

    $this = $node unless $node == $this;

    $Redraw = 'none';
    ChangingFile(0);
}

#bind follow_apply_right Ctrl+Right menu Follow Annotation Right
sub follow_apply_right {

    $main::treeViewOpts->{reverseNodeOrder} && ! InVerticalMode() ?
        ctrl_currentLeftWholeLevel() :
        ctrl_currentRightWholeLevel();

    $Redraw = 'none';
    ChangingFile(0);
}

#bind follow_apply_left Ctrl+Left menu Follow Annotation Left
sub follow_apply_left {

    $main::treeViewOpts->{reverseNodeOrder} && ! InVerticalMode() ?
        ctrl_currentRightWholeLevel() :
        ctrl_currentLeftWholeLevel();

    $Redraw = 'none';
    ChangingFile(0);
}

sub ctrl_currentRightWholeLevel {    # modified copy of main::currentRightWholeLevel

    my $node = $this;
    my $level = $node->level();

    do {

        $node = NextVisibleNode($node);
    }
    until not $node or $level == $node->level() and $node->{'apply'} > 0;

    $this = $node if $node;

    ChangingFile(0);
}

sub ctrl_currentLeftWholeLevel {     # modified copy of main::currentLeftWholeLevel

    my $node = $this;
    my $level = $node->level();

    do {

        $node = PrevVisibleNode($node);
    }
    until not $node or $level == $node->level() and $node->{'apply'} > 0;

    $this = $node if $node;

    ChangingFile(0);
}

#bind invoke_undo BackSpace menu Undo Annotate / Restrict
sub invoke_undo {

    warn 'Undoooooing ;)';

    main::undo($grp);
    $this = $grp->{currentNode};

    ChangingFile(0);
}

#bind invoke_redo Shift+BackSpace menu Redo Annotate / Restrict
sub invoke_redo {

    warn 'Redoooooing ;)';

    main::re_do($grp);
    $this = $grp->{currentNode};

    ChangingFile(0);
}

#bind edit_comment to exclam menu Edit Annotation Comment
sub edit_comment {

    $Redraw = 'none';
    ChangingFile(0);

    my $comment = $grp->{FSFile}->FS->exists('comment') ? 'comment' : undef;

    unless (defined $comment) {

        ToplevelFrame()->messageBox (
            -icon => 'warning',
            -message => "There is no 'comment' attribute in this file's format!$fill",
            -title => 'Error',
            -type => 'OK',
        );

        return;
    }

    my $switch = $this->{'#name'} eq 'Token' || $this->{'#name'} eq 'Lexeme';

    if ($switch and not $this->{'apply'} > 0) {

        ToplevelFrame()->messageBox (
            -icon => 'warning',
            -message => "This node must be annotated in order to receive comments!$fill",
            -title => 'Error',
            -type => 'OK',
        );

        return;
    }

    switch_either_context() if $switch;

    my $value = $this->{$comment};

    $value = main::QueryString($grp->{framegroup}, "Enter the comment", $comment, $value);

    if (defined $value) {

        $this->{$comment} = $value;

        $Redraw = 'tree';
        ChangingFile(1);
    }

    switch_either_context() if $switch;

    $this->{$comment} = $value if defined $value;
}

# ##################################################################################################
#
# ##################################################################################################

#bind elixir_resolve to Ctrl+r menu ElixirFM Resolve

sub elixir_resolve {

    if ($root->{'#name'} eq 'Paragraph') {

        my $reply = Exec::ElixirFM::elixir 'resolve', join " ", map { $_->{'input'} } $root->children();

        foreach (ElixirFM::unpretty $reply) {

            NextTree();

            morphotrees($root, $_);
        }
    }
    else {

        my $reply = Exec::ElixirFM::elixir 'resolve', $root->{'input'};

        foreach (ElixirFM::unpretty $reply) {

            morphotrees($root, $_);
        }
    }
}

sub morphotrees {

    my ($done, $data) = @_;

    foreach (reverse @{$data->{'node'}}) {

        my $node = NewSon($done);

        DetermineNodeType($node);

        my $done = $node;

        foreach (reverse @{$_->{'node'}}) {

            my $node = NewSon($done);

            DetermineNodeType($node);

            my @form = ();

            my $done = $node;

            foreach (reverse @{$_->{'node'}}) {

                my $node = NewSon($done);

                DetermineNodeType($node);

                $node->{'root'} = substr $_->{'data'}{'info'}[5], 1, -1;

                $node->{'core'} = new Fslib::Struct;

                $node->{'core'}{'morphs'} = $_->{'data'}{'info'}[6];

                $node->{'core'}{'reflex'} = new Fslib::List @{eval $_->{'data'}{'info'}[2]};

                my $data = ElixirFM::parse($_->{'data'}{'info'}[1]);

                foreach ('plural', 'femini', 'form', 'pfirst', 'imperf', 'second', 'masdar') {

                    next unless exists $data->[1]{$_};

                    $data->[1]{$_} = [ ref $data->[1]{$_} ? map { $_->[-1] } @{$data->[1]{$_}} : $data->[1]{$_} ];
                }

                $node->{'core'}{'entity'} = new Fslib::Seq [new Fslib::Seq::Element ($data->[0], new Fslib::Struct ($data->[1]))];

                $node->{'form'} = $_->{'data'}{'info'}[4];

                my $done = $node;

                foreach (reverse @{$_->{'node'}}) {

                    my $node = NewSon($done);

                    DetermineNodeType($node);

                    $node->{'tag'} = $_->{'data'}{'info'}[0];

                    $node->{'form'} = $_->{'data'}{'info'}[1];

                    $node->{'morphs'} = $_->{'data'}{'info'}[3];

                    unshift @form, $node->{'form'};
                }
            }

            demode "arabtex", "noneplus";

            $node->{'form'} = join " ", ElixirFM::nub { $_[0] } sort map { decode "arabtex", $_ } @form;

            demode "arabtex", "default";
        }

        $node->{'form'} = join "    ", map { $_->{'form'} } $node->children();
    }
}

# ##################################################################################################
#
# ##################################################################################################

#bind annotate_morphology to space menu Annotate Morphology
sub annotate_morphology {

    $Redraw = 'win' unless $Redraw eq 'file' or $Redraw eq 'tree';

    ChangingFile(0);

    # indicated below when the file or the redraw mode actually change

    if ($root->{'#name'} eq 'Paragraph') {

        if ($this->{'#name'} eq 'Paragraph') {

            GotoTree((split /[^0-9]+/, $this->{'par'})[1]);
        }
        else {

            switch_either_context();
        }

        $Redraw = 'win';

        return;
    }

    my ($quick, @tips) = @_;

    my (@children, $diff, $done, $word);

    my $node = $this;

    while (@children = $node->children()) {

        @children = grep { $_->{'hide'} ne 'hide' and ( not defined $_->{'tips'} or $_->{'tips'} > 0 ) } @children;

        last unless @children == 1;

        $node = $children[0];
    }

    unless (@children) {

        if ($node->{'#name'} eq 'Token') {

            $diff = $node->{'apply'} == 0 ? 1 : $node == $this ? -1 : 0;

            $done = $node;

            $node->{'apply'} += $diff;

            while ($node = $node->parent()) {

                if ($node->{'#name'} eq 'Partition') {

                    @children = grep { $_->{'apply'} < 1 } $node->children();

                    if ($diff == -1) {

                        last if not @children or not $node->{'apply'} == 1;
                    }
                    else {

                        last if @children or $node->{'apply'} == 1;
                    }
                }

                $node->{'apply'} += $diff;
            }

            unless ($diff == 0) {

                $word = reflect_choice($done, $diff);

                unless ($node) {  # ~~ # $root->parent(), $this->following() etc. are defined # ~~ #

                    $word->{'apply'} = $root->{'apply'};

                    $word->{'hide'} = $paragraph_hide_mode eq 'hidden' && $word->{'apply'} > 0 ? 'hide' : '';
                }

                $Redraw = 'file';

                ChangingFile(1);
            }

            unless ($diff == -1) {

                if (@children) {

                    $this = defined $tips[0] && ( grep { $tips[0] == $_ } @children ) ? $tips[0] : $children[0];

                    remove_inherited_restrict() if defined $this->{'tips'} and $this->{'tips'} == 0;

                    annotate_morphology($quick eq 'click' ? $quick : undef);
                }
                else {

                    NextTree() unless defined $quick and $quick eq 'click';
                }
            }
        }
    }
    elsif ($level_guide_mode > 0) {

        if ($level_guide_mode > 1) {

            $this = defined $tips[0] && ( grep { $tips[0] == $_ } @children )
                        ? $tips[0]
                        : $children[0]->{'#name'} eq 'Lexeme' ||
                          $children[0]->{'#name'} eq 'Partition' && @children > 1
                            ? $node
                            : $children[0];
        }
        else {

            $this = defined $tips[0] && ( grep { $tips[0] == $_ } @children )
                        ? $tips[0]
                        : $children[0]->{'#name'} eq 'Lexeme'
                            ? $node
                            : $children[0];
        }
    }
    else {

        $this = defined $tips[0] && ( grep { $tips[0] == $_ } @children ) ? $tips[0] : $children[0];
    }
}


sub reflect_choice {

    my ($leaf, $diff) = @_;
    my ($roox, $thix) = ($root, $this);

    my $twig = $leaf->parent();

    $leaf->{'id'} = '';
    $twig->{'id'} = '';

    switch_either_context('quick');

    # main::save_undo($grp, main::prepare_undo($grp)) if TredMacro::GUI();

    my $clip = $this;

    my $word = CopyNode($clip);

    PasteNodeBefore($word, $clip);

    CutNode($clip);

    $this = $word;

    my @lexeme = grep { $_->{'apply'} > 0 } map { $_->children() }
                 grep { $_->{'apply'} > 0 } map { $_->children() } $roox->children();

    for (my $i = @lexeme; $i > 0; $i--) {

        $lexeme[$i - 1]->{'id'} = $roox->{'id'} . 'l' . $i;

        my $node = CopyNode($lexeme[$i - 1]);

        PasteNode($node, $word);

        $node->{'id'} = $word->{'id'} . 'l' . $i;
        $node->{'ref'} = $lexeme[$i - 1]->{'id'};

        my @token = grep { $_->{'apply'} > 0 } $lexeme[$i - 1]->children();

        for (my $j = @token; $j > 0; $j--) {

            $token[$j - 1]->{'id'} = $lexeme[$i - 1]->{'id'} . 't' . $j;

            my $done = CopyNode($token[$j - 1]);

            PasteNode($done, $node);

            $done->{'id'} = $node->{'id'} . 't' . $j;
            $done->{'ref'} = $token[$j - 1]->{'id'};
        }
    }

    switch_either_context();

    ($root, $this) = ($roox, $thix);

    return $word;
}


sub restrict {

    my @restrict = split //, length $_[0] == $dims ? $_[0] : '-' x $dims;
    my @inherit = split //, $_[1];

    return join '', map { $restrict[$_] eq '-' && defined $inherit[$_] ? $inherit[$_] : $restrict[$_] } 0 .. $#restrict;
}


sub restrict_hide {

    ChangingFile(0);

    return unless $root->{'#name'} eq 'Element';

    $Redraw = 'tree' unless $Redraw eq 'file';

    ChangingFile(1);

    my ($restrict, $context) = @_;

    my $node = $this->{'#name'} eq 'Token' ? $this->parent() : $this;
    my $roof = $node;

    my (@tips, %tips, $orig, $diff);

    if (defined $context) {

        if ($context eq 'remove inherited') {

            $node->{'inherit'} = '';
        }
        elsif ($context eq 'remove induced') {

            if ($node->{'restrict'} eq '') {

                $context = 'remove induced clear';
            }
            else {

                $node->{'restrict'} = '';

                if ($node->parent()) {

                    $node->{'inherit'} = restrict($node->parent()->{'restrict'}, $node->parent()->{'inherit'});
                    $node->{'inherit'} = '' if $node->{'inherit'} eq '-' x $dims;
                }
                else {

                    $node->{'inherit'} = '';
                }
            }
        }
    }

    $node->{'restrict'} = restrict($restrict, $node->{'restrict'}) unless $restrict eq '';

    while ($node = $node->following($roof)) {

        if ($context eq 'remove induced clear') {

            $node->{'restrict'} = '';
            $node->{'inherit'} = $node->parent()->{'inherit'};
        }
        else {

            $node->{'inherit'} = restrict($node->parent()->{'restrict'}, $node->parent()->{'inherit'});
            $node->{'inherit'} = '' if $node->{'inherit'} eq '-' x $dims;
        }

        if ($node->{'#name'} eq 'Token') {

            if (restrict($node->{'inherit'}, $node->{'tag'}) ne $node->{'tag'}) {

                $node->{'hide'} = 'hide';
            }
            else {

                $node->{'hide'} = '';
                unshift @tips, $node;
            }
        }
        else {

            $node->{'hide'} = $entity_hide_mode eq 'hidden' ? 'hide' : '';
            $node->{'tips'} = 0;
        }
    }

    $orig = defined $roof->{'tips'} && $roof->{'tips'} == 0 ? 0 : 1;
    $roof->{'tips'} = 0;

    while ($node = shift @tips) {

        next if $node == $roof;

        $node->{'hide'} = '';

        $node->parent()->{'tips'}++ unless $node->{'hide'} eq 'hide' or defined $node->{'tips'} and $node->{'tips'} == 0;
        $tips{$node->parent()} = $node->parent();

        unless (@tips) {

            @tips = values %tips;
            %tips = ();
        }
    }

    $node = $roof;

    { do {

        last if $node == $root;     # ~~ # $root->parent(), $this->following() etc. are defined # ~~ # never hide the root

        $node->{'hide'} = $entity_hide_mode eq 'hidden' && $node->{'tips'} == 0 ? 'hide' : '';

        if (defined $node->parent()->{'tips'}) {    # optimizing, if this is necessary ^^

            $diff = ( $node->{'tips'} > 0 ? 1 : 0 ) - $orig;
            $orig = $node->parent()->{'tips'} > 0 ? 1 : 0;
            $node->parent()->{'tips'} += $diff;
        }
        else {

            $orig = 1;
            $node->parent()->{'tips'} = grep { not defined $_->{'tips'} or $_->{'tips'} > 0 } $node->parent()->children();
        }
    }
    while $node = $node->parent(); }

    ($this, @tips) = ($roof, $this);

    annotate_morphology(undef, @tips) if $this->{'tips'} > 0 and not defined $context;
}


#bind remove_induced_restrict Escape menu Remove Induced Restrict
sub remove_induced_restrict {

    restrict_hide('', 'remove induced');
}


#bind remove_inherited_restrict Shift+Escape menu Remove Inherited Restrict
sub remove_inherited_restrict {

    restrict_hide('-' x $dims, 'remove inherited');
}


# ##################################################################################################
#
# ##################################################################################################

#bind restrict_case_nom 1 menu Restrict Case Nominative
sub restrict_case_nom {
    restrict_hide('--------1-');
}

#bind restrict_case_gen 2 menu Restrict Case Genitive
sub restrict_case_gen {
    restrict_hide('--------2-');
}

#bind restrict_case_acc 4 menu Restrict Case Accusative
sub restrict_case_acc {
    restrict_hide('--------4-');
}

#bind restrict_state_i i menu Restrict State Indefinite
sub restrict_state_i {
    restrict_hide('---------I');
}

#bind restrict_state_d d menu Restrict State Definite
sub restrict_state_d {
    restrict_hide('---------D');
}

#bind restrict_state_a A menu Restrict State Absolute
sub restrict_state_a {
    restrict_hide('---------A');
}

#bind restrict_state_r r menu Restrict State Reduced
sub restrict_state_r {
    restrict_hide('---------R');
}

#bind restrict_state_c C menu Restrict State Complex
sub restrict_state_c {
    restrict_hide('---------C');
}

#bind restrict_state_l L menu Restrict State Lifted
sub restrict_state_l {
    restrict_hide('---------L');
}

#bind restrict_noun n menu Restrict Noun
sub restrict_noun {
    restrict_hide('N---------');
}

#bind restrict_adjective a menu Restrict Adjective
sub restrict_adjective {
    restrict_hide('A---------');
}

#bind restrict_verb v menu Restrict Verb
sub restrict_verb {
    restrict_hide('V---------');
}

#bind restrict_proper z menu Restrict Proper Name
sub restrict_proper {
    restrict_hide('Z---------');
}

#bind restrict_adverb D menu Restrict Adverb
sub restrict_adverb {
    restrict_hide('D---------');
}

#bind restrict_preposition p menu Restrict Preposition
sub restrict_preposition {
    restrict_hide('P---------');
}

#bind restrict_pronoun s menu Restrict Pronoun
sub restrict_pronoun {
    restrict_hide('S---------');
}

#bind restrict_particle f menu Restrict Particle
sub restrict_particle {
    restrict_hide('F---------');
}

#bind restrict_conjunction c menu Restrict Conjunction
sub restrict_conjunction {
    restrict_hide('C---------');
}

#bind restrict_third 3 menu Restrict Person Third ;)
#bind restrict_third Ctrl+3 menu Restrict Person Third
sub restrict_third {
    restrict_hide('-----3----');
}

#bind restrict_second Ctrl+2 menu Restrict Person Second
sub restrict_second {
    restrict_hide('-----2----');
}

#bind restrict_first Ctrl+1 menu Restrict Person First
sub restrict_first {
    restrict_hide('-----1----');
}

#bind restrict_perfect P menu Restrict Verb Perfect
sub restrict_perfect {
    restrict_hide('-P--------');
}

#bind restrict_indicative I menu Restrict Verb Indicative
sub restrict_indicative {
    restrict_hide('--I-------');
}

#bind restrict_subjunctive S menu Restrict Verb Subjunctive
sub restrict_subjunctive {
    restrict_hide('--S-------');
}

#bind restrict_jussive J menu Restrict Verb Jussive
sub restrict_jussive {
    restrict_hide('--J-------');
}

#bind restrict_active Ctrl+c menu Restrict Voice Active
sub restrict_active {
    restrict_hide('---A------');
}

#bind restrict_passive Ctrl+t menu Restrict Voice Passive
sub restrict_passive {
    restrict_hide('---P------');
}

#bind restrict_plural Ctrl+p menu Restrict Illusory Plural
sub restrict_plural {
    restrict_hide('-------P--');
}

#bind restrict_dual Ctrl+d menu Restrict Illusory Dual
sub restrict_dual {
    restrict_hide('-------D--');
}

#bind restrict_singular Ctrl+s menu Restrict Illusory Singular
sub restrict_singular {
    restrict_hide('-------S--');
}

#bind restrict_masculine Ctrl+m menu Restrict Illusory Masculine
sub restrict_masculine {
    restrict_hide('------M---');
}

#bind restrict_feminine Ctrl+f menu Restrict Illusory Feminine
sub restrict_feminine {
    restrict_hide('------F---');
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

sub expace ($) {

    return '"' . "'" . $_[0] . "'" . '"'  if $^O eq 'MSWin32' and $_[0] =~ / /;

    return escape $_[0];
}

sub inter_with_level ($) {

    require File::Basename;

    my $level = $_[0];

    my (@file, $path, $name);

    my $thisfile = File::Spec->canonpath(FileName());

    ($name, $path, undef) = File::Basename::fileparse($thisfile, '.morpho.xml');
    (undef, $path, undef) = File::Basename::fileparse((substr $path, 0, -1), '');

    $file[0] = path $path . 'morpho', $name . '.morpho.xml';
    $file[1] = path $path . "$level", $name . ".$level.xml";

    $file[2] = $level eq 'corpus' ? ( path $path . "$level", $name . '.morpho.xml' )
                                  : ( path $path . 'morpho', $name . ".$level.xml" );

    $file[3] = path $path . 'morpho', $name . '.morpho.xml.anno.xml';

    unless ($file[0] eq $thisfile) {

        ToplevelFrame()->messageBox (
            -icon => 'warning',
            -message => "This file's name does not fit the directory structure!$fill\n" .
                        "Relocate it to " . ( path '..', 'morpho', $name . '.morpho.xml' ) . ".$fill",
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

    open_level_second();

    Analytic::synchronize_file();
}

#bind open_level_first to Ctrl+Alt+1 menu Action: Edit MorphoTrees File
sub open_level_first {

    ChangingFile(0);
}

#bind open_level_second to Ctrl+Alt+2 menu Action: Edit Analytic File
sub open_level_second {

    ChangingFile(0);

    my ($level, $name, $path, @file) = inter_with_level 'syntax';

    return unless defined $level;

    unless (-f $file[1]) {

        my $reply = main::userQuery($grp,
                        "\nThere is no " . ( path '..', "$level", $name . ".$level.xml" ) . " file.$fill" .
                        "\nReally create a new one?$fill",
                        -bitmap=> 'question',
                        -title => "Creating",
                        -buttons => ['Yes', 'No']);

        return unless $reply eq 'Yes';

        if (-f $file[2]) {

            ToplevelFrame()->messageBox (
                -icon => 'warning',
                -message => "Cannot create " . ( path '..', "$level", $name . ".$level.xml" ) . "!$fill\n" .
                            "Please remove " . ( path '..', 'morpho', $name . ".$level.xml" ) . ".$fill",
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

        system 'perl -X ' . ( escape CallerDir('exec') . '/SyntaxFS.pl' ) .
                      ' ' . ( expace $file[0] );

        mkdir path $path, "$level" unless -d path $path, "$level";

        move $file[2], $file[1];
    }

    switch_the_levels($file[1]);
}

#bind open_level_third to Ctrl+Alt+3 menu Action: Edit DeepLevels File
sub open_level_third {

    ChangingFile(0);

    my ($level, $name, $path, @file) = inter_with_level 'deeper';

    return unless defined $level;

    unless (-f $file[1]) {

        ToplevelFrame()->messageBox (
            -icon => 'warning',
            -message => "There is no " . ( path '..', "$level", $name . ".$level.xml" ) . " file!$fill",
            -title => 'Error',
            -type => 'OK',
        );

        return;
    }

    switch_the_levels($file[1]);
}

sub switch_the_levels {

    my $file = $_[0];

    my ($tree, $node, @child, $hits);

    switch_either_context() unless $root->{'#name'} eq 'Paragraph';

    $tree = substr $root->{'idx'}, 1;
    $node = 0;

    unless ($this == $root) {

        $this = $this->parent() until $this->{'#name'} eq 'Word';

        @child = $root->children();

        foreach $hits (@child) {

            last if $hits == $this;
            $node++;
        }

        if ($node == @child) {

            $node = 0;
        }
        else {

            $node++;
        }
    }

    if (Open($file)) {

        GotoTree($tree);

        unless ($node == 0) {

            do {

                $this = $this->following();

                ($hits) = $this->{'m'}{'ref'} =~ /^\#[0-9]+\/([0-9]+)(:?\_[0-9]+)?$/;
            }
            until $hits == $node;
        }
    }
    else {

        SwitchContext('MorphoTrees');
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

MorphoTrees - Context for Annotation of Morphology in the TrEd Environment


=head1 REVISION

    $Revision$       $Date$


=head1 DESCRIPTION

MorphoTrees were first introduced in L<http://ufal.mff.cuni.cz/padt/docs/2004-nemlar-tred.pdf>.
They have re-appeared in various papers and talks, esp. in the video-recorded lecture on the Prague
Arabic Dependency Treebank, L<http://ufal.mff.cuni.cz/padt/online/2007/01/prague-treebanking-for-everyone-video.html>.

Examples of MorphoTrees include L<http://ufal.mff.cuni.cz/padt/docs/morpho_fhm.gif>,
L<http://ufal.mff.cuni.cz/padt/docs/morpho_AfrAd.gif>, or
L<http://ufal.mff.cuni.cz/padt/docs/morpho_AmA.gif>.

Paragraph annotation trees look like L<http://ufal.mff.cuni.cz/padt/docs/morpho_view.gif>.

For further reference, see the list of MorphoTrees macros and key-bindings in the User-defined menu item in TrEd.

MorphoTrees are closely related to the ElixirFM project, cf. <http://sf.net/projects/elixir-fm/> and
<http://ufal.mff.cuni.cz/~smrz/elixir-thesis.pdf>.


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
