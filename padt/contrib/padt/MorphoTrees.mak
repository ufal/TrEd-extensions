# ########################################################################## Otakar Smrz, 2004/03/05
#
# MorphoTrees Context for the TrEd Environment #####################################################

# $Id$

package MorphoTrees;

use 5.008;

use strict;

use ElixirFM;

use Exec::ElixirFM ();

use Encode::Arabic ':modes';

use Algorithm::Diff;

use List::Util 'reduce';

use File::Spec;
use File::Copy;

use File::Basename;

use Storable;

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

our ($elixir, $review) = ({}, {});

# ##################################################################################################
#
# ##################################################################################################

sub CreateStylesheets {

    return << '>>';

style:<? exists $this->{'apply'} && $this->{'apply'} > 0 ? '#{Line-fill:red}' :
         exists $this->{'score'} && $this->{'score'}[0]{'#content'} > 0.95 ? '#{Line-fill:magenta}' :
         exists $this->{'score'} && $this->{'score'}[0]{'#content'} > 0.85 ? '#{Line-fill:orange}' : '' ?>

node:<? '#{magenta}${note} << ' if $this->{'note'} ne '' and not $this->{'#name'} ~~ ['Token', 'Unit', 'Paragraph']
   ?><? $this->{'#name'} eq 'Token'
            ? ( ElixirFM::orph($this->{'form'}, "\n") )
            : (
            $this->{'#name'} eq 'Lexeme'
                ? ( ( $MorphoTrees::review->{$grp}{'zoom'}
                        ? '#{purple}' . ( join ", ", exists $this->{'core'}{'reflex'} ?
                                                            @{$this->{'core'}{'reflex'}} : () ) . ' '
                        : '' ) .
                    '#{darkmagenta}' .
                    ( $this->{'form'} eq '[DEFAULT]'
                        ? $this->{'form'}
                        : $this->{'form'} =~ /^\([0-9]+,[0-9]+\)$/
                            ? ElixirFM::phor(ElixirFM::merge($this->{'root'}, $this->{'core'}{'morphs'}))
                            : ElixirFM::phor($this->{'form'}) ) )
                : (
                $this->{'#name'} ~~ ['Component', 'Partition']
                    ? $this->{'form'}
                    : (
                    $this->{'#name'} ~~ ['Element', 'Unit', 'Paragraph']
                        ? '#{black}' . MorphoTrees::idx($this)
                        : ' ' ) .
                      ( $this->{apply} > 0
                            ? ' #{red}${form}'
                            : ' #{black}${form}' ) ) ) ?>

node:<? '#{goldenrod}${note} << ' if $this->{'note'} ne '' and $this->{'#name'} eq 'Token'
   ?>#{darkred}${tag}<? $this->{'inherit'} eq '' ? '#{red}' : '#{orange}'
   ?>${restrict}

hint:<? '${gloss}' if $this->{'#name'} eq 'Token' ?>
>>
}

sub idx {

    my $node = $_[0] || $this;

    return unless exists $node->{'id'};

    my @idx = grep { $_ ne '' } split /[^0-9]+/, $node->{'id'};

    return wantarray ? @idx : ( "#" . join "/", @idx );
}

sub normalize {

    my $text = $_[0];

    $text =~ tr[\x{0640}\x{0652}][]d;

    $text =~ s/([\x{064B}-\x{0650}\x{0652}\x{0670}])\x{0651}/\x{0651}$1/g;
    $text =~ s/([\x{0627}\x{0649}])\x{064B}/\x{064B}$1/g;

    return $text;
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

    my ($fsfile, $index, $focus, $hidding) = @_;
    my ($nodes);

    if ($review->{$grp}{'zoom'}) {

        update_zoom_tree() unless $review->{$grp}{'tree'};

        $nodes = [$review->{$grp}{'tree'}, $review->{$grp}{'tree'}->descendants()];

        $focus = $review->{$grp}{'tree'} unless grep { $focus == $_ } @{$nodes};
    }
    else {

        ($nodes, $focus) = $fsfile->nodes($index, $focus, $hidding);
    }

    @{$nodes} = reverse @{$nodes} if $main::treeViewOpts->{reverseNodeOrder};

    return [[@{$nodes}], $focus];
}

sub get_value_line_hook {

    my ($fsfile, $index) = @_;
    my ($nodes, $words);

    my $tree = $fsfile->tree($index);

    if ($review->{$grp}{'zoom'}) {

        ($nodes, undef) = $fsfile->nodes($index, $review->{$grp}{'zoom'}, 1);

        $words = [ [ idx($tree) . " " . $tree->{'form'}, $tree, '-foreground => purple' ],

                   [ " " ],

                   map {
                            [ $_->{'form'}, $_, $_->{'id'}, $_ == $review->{$grp}{'zoom'} ? ( '-underline => 1' ) : () ],

                            [ " " ],

                        } grep { $_->{'#name'} eq 'Word' } @{$nodes} ];
    }
    else {

        ($nodes, undef) = $fsfile->nodes($index, $grp->{'currentNode'}, 1);

        $words = [ [ idx($tree) . " " . $tree->{'form'}, $tree, '-foreground => darkmagenta' ],

                   [ " " ],

                   map {
                            [ $_->{'form'}, $_, (

                                $paragraph_hide_mode eq 'hidden'

                                      ? ( $_->{'apply'} > 0
                                            ? '-foreground => gray'
                                            : '-foreground => black' )
                                      : ( $_->{'apply'} > 0
                                            ? '-foreground => red'
                                            : '-foreground => black' )
                                ) ],

                            [ " " ],

                        } grep { $_->{'#name'} eq 'Word' } @{$nodes} ];
    }

    @{$words} = reverse @{$words} if $main::treeViewOpts->{reverseNodeOrder};

    return $words;
}

sub highlight_value_line_tag_hook {

    return $review->{$grp}{'zoom'} if $review->{$grp}{'zoom'};

    my $node = $grp->{'currentNode'};

    $node = $node->parent() while $node and not $node->{'#name'} ~~ ['Word', 'Unit'];

    return $node;
}

sub value_line_doubleclick_hook {

    return unless $review->{$grp}{'zoom'};

    my $id = $_[-2];            # reversed compared to get_value_line_hook

    return 'stop' unless $id;

    $review->{$grp}{'zoom'} = PML::GetNodeByID($id);

    update_zoom_tree();

    $this = $review->{$grp}{'tree'};

    Redraw();

    return 'stop';
}

sub node_doubleclick_hook {

    $grp->{'currentNode'} = $_[0];

    if ($_[1] eq 'Shift') {

        main::doEvalMacro($grp, __PACKAGE__ . '->switch_either_context');
    }
    else {

        main::doEvalMacro($grp, __PACKAGE__ . '->annotate_morphology');
    }

    return 'stop';
}

sub node_click_hook {

    $grp->{'currentNode'} = $_[0];

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

#bind switch_review_mode Ctrl+M menu Switch Trees/Lists Mode
sub switch_review_mode {

    $review->{$grp}{'mode'} = not $review->{$grp}{'mode'};
}

sub update_zoom_tree {

    return unless $review->{$grp}{'zoom'};

    my $id = join 'e', split 'w', $review->{$grp}{'zoom'}->{'id'};

    unless ($review->{$grp}{'tree'} and $review->{$grp}{'tree'}->{'id'} eq $id) {

        my ($data) = resolve($review->{$grp}{'zoom'}->{'form'});

        my $tree = new FSNode;

        $tree->set_type_by_name($grp->{'FSFile'}->metaData('schema'), 'Element.type');

        $tree->{'#name'} = 'Element';

        $tree->{'id'} = $id;

        $tree = $review->{$grp}{'mode'} ? morpholists($data, $tree) : morphotrees($data, $tree);

        $review->{$grp}{'tree'} = $tree;

        score_nodes();
    }
}

sub score_nodes {

    return unless $review->{$grp}{'tree'} and $review->{$grp}{'zoom'};

    my $tree = $review->{$grp}{'tree'};
    my $zoom = $review->{$grp}{'zoom'};

    my @done = map { $_->children() } $zoom->children();

    return unless @done;

    foreach my $part ($tree->children()) {

        my @comp = $part->children();

        next unless @comp == @done;

        for (my $i = 0; $i < @comp; $i++) {

            foreach my $node (map { $_->children() } map { $_->children() } $comp[$i]) {

                $node->{'score'} = new Fslib::Alt map { new Fslib::Container $_->[1], {'src' => $_->[0]} } compute_score($node, $done[$i]);
            }
        }
    }
}

sub compute_score {

    my ($node, $done) = @_;

    my (@node, @done, @diff);

    my %score = ();

    @node = split //, $node->{'tag'};
    @done = split //, $done->{'tag'};

    for (my $i = 0; $i < @done; $i++) {

        $score{'tag'} += $node[$i] eq $done[$i] ? 1 : $node[$i] eq '-' || $done[$i] eq '-' ? 0 : -1;
    }

    $score{'tag'} /= @done || $dims;

    @node = split //, $node->{'form'} =~ /\p{InArabic}/ ? normalize $node->{'form'} : ElixirFM::orth($node->{'form'});
    @done = split //, $done->{'form'} =~ /\p{InArabic}/ ? normalize $done->{'form'} : ElixirFM::orth($done->{'form'});

    @diff = Algorithm::Diff::LCS([@node], [@done]);

    $score{'form'} = @node + @done == 0 ? 1 : 2 * @diff / (@node + @done);

    @node = exists $node->parent()->{'core'} && exists $node->parent()->{'core'}{'reflex'} ? sort @{$node->parent()->{'core'}{'reflex'}} : ();
    @done = exists $done->parent()->{'core'} && exists $done->parent()->{'core'}{'reflex'} ? sort @{$done->parent()->{'core'}{'reflex'}} : ();

    @diff = Algorithm::Diff::LCS([@node], [@done]);

    $score{'reflex'} = @node + @done == 0 ? 1 : 2 * @diff / (@node + @done);

    my $total = reduce { $a + $b } map { $score{$_} == 0 ? 100 : (1 / $score{$_}) } keys %score;

    $total = $total == 0 ? 1 : ((keys %score) / $total);

    return [ 'total' => $total ], map { [ $_ => $score{$_} ] } keys %score;
}

#bind switch_either_context Shift+space menu Switch Either Context
sub switch_either_context {

    $Redraw = 'win' unless $Redraw eq 'file' or $Redraw eq 'tree';

    ChangingFile(0);

    if ($review->{$grp}{'zoom'}) {

        $this = $review->{$grp}{'zoom'};

        $review->{$grp}{'zoom'} = undef;
    }
    else {

        my $level = $this->level();

        return if $level == 0;

        $this = $this->parent() for 1 .. $level - 1;

        $review->{$grp}{'zoom'} = $this;

        update_zoom_tree();
    }
}


my %binding = map { $_ => OverrideBuiltinBinding('*', $_) } "Prior", "Next";

OverrideBuiltinBinding(__PACKAGE__, "Prior", [ sub {

        $grp = $_[1]->{'focusedWindow'};

        if ($review->{$grp}{'zoom'}) {

            my $node = $review->{$grp}{'zoom'}->lbrother();

            if ($node) {

                $review->{$grp}{'zoom'} = $node;

                update_zoom_tree();

                $this = $review->{$grp}{'tree'};

                Redraw();
            }

            Tk->break;
        }
        else {

            $binding{"Prior"}->[0](@_);
        }

    }, 'Display Previous Tree / Word' ]);

OverrideBuiltinBinding(__PACKAGE__, "Next", [ sub {

        $grp = $_[1]->{'focusedWindow'};

        if ($review->{$grp}{'zoom'}) {

            my $node = $review->{$grp}{'zoom'}->rbrother();

            if ($node) {

                $review->{$grp}{'zoom'} = $node;

                update_zoom_tree();

                $this = $review->{$grp}{'tree'};

                Redraw();
            }

            Tk->break;
        }
        else {

            $binding{"Next"}->[0](@_);
        }

    }, 'Display Next Tree / Word' ]);


#bind move_to_prev_paragraph Shift+Prior menu Move to Prev Paragraph
sub move_to_prev_paragraph {

    PrevTree();

    move_word_end();

    $review->{$grp}{'zoom'} = $this;

    update_zoom_tree();

    ChangingFile(0);
}

#bind move_to_next_paragraph Shift+Next menu Move to Next Paragraph
sub move_to_next_paragraph {

    NextTree() if $review->{$grp}{'zoom'};

    move_word_home();

    $review->{$grp}{'zoom'} = $this;

    update_zoom_tree();

    ChangingFile(0);
}

#bind move_word_home Home menu Move to First Word
sub move_word_home {

    $this = ($root->children())[0];

    if ($review->{$grp}{'zoom'}) {

        $review->{$grp}{'zoom'} = $this;

        update_zoom_tree();
    }

    ChangingFile(0);
}

#bind move_word_end End menu Move to Last Word
sub move_word_end {

    $this = ($root->children())[-1];

    if ($review->{$grp}{'zoom'}) {

        $review->{$grp}{'zoom'} = $this;

        update_zoom_tree();
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

    $review->{$grp}{'zoom'} = undef;

    $Redraw = 'win';
    ChangingFile(0);
}

#bind move_par_end Shift+End menu Move to Last Paragraph
sub move_par_end {

    GotoTree($grp->{'FSFile'}->lastTreeNo() + 1);

    $review->{$grp}{'zoom'} = undef;

    $Redraw = 'win';
    ChangingFile(0);
}

#bind tree_hide_mode Ctrl+equal menu Toggle Tree Hide Mode
sub tree_hide_mode {

    if ($review->{$grp}{'zoom'}) {

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

    $this = $review->{$grp}{'zoom'} ? $review->{$grp}{'tree'} : $root;

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

#bind edit_note to exclam menu Edit Annotation Note
sub edit_note {

    $Redraw = 'none';
    ChangingFile(0);

    my $note = $grp->{'FSFile'}->FS()->exists('note') ? 'note' : undef;

    unless (defined $note) {

        ToplevelFrame()->messageBox (
            -icon => 'warning',
            -message => "There is no 'note' attribute in this file's format!$fill",
            -title => 'Error',
            -type => 'OK',
        );

        return;
    }

    my $switch = $this->{'#name'} eq 'Token' || $this->{'#name'} eq 'Lexeme';

    if ($switch and not $this->{'apply'} > 0) {

        ToplevelFrame()->messageBox (
            -icon => 'warning',
            -message => "This node must be annotated in order to receive notes!$fill",
            -title => 'Error',
            -type => 'OK',
        );

        return;
    }

    switch_either_context() if $switch;

    my $value = $this->{$note};

    $value = main::QueryString($grp->{framegroup}, "Enter the note", $note, $value);

    if (defined $value) {

        $this->{$note} = $value;

        $Redraw = 'tree';
        ChangingFile(1);
    }

    switch_either_context() if $switch;

    $this->{$note} = $value if defined $value;
}

# ##################################################################################################
#
# ##################################################################################################

#bind elixir_lexicon to Ctrl+L menu ElixirFM Lexicon

sub elixir_lexicon {

    import Exec::ElixirFM;

    my $file = CallerDir('../../data/elixir-lexicon.pls');

    my $data = {};

    if (-f $file) {

        $data = Storable::retrieve $file or warn $! and return;
    }

    my ($version) = reverse split /\n/, Exec::ElixirFM::elixir 'version';

    unless (not defined $version or exists $data->{'version'} and $data->{'version'} ge $version) {

        my $text = Exec::ElixirFM::elixir 'lexicon';

        $text =~ s/(?<=<derive>)True(?=<\/derive>)/------F---/g;
        $text =~ s/(?<=<tense>)I(?=<\/tense>)/Imperfect/g;
        $text =~ s/(?<=<voice>)P(?=<\/voice>)/Passive/g;

        my $pml = PMLInstance->load({ 'string' => $text });

        my $lexicon = [];

        my $nest_idx = -1;

        foreach my $nest (map { $_->children() } @{$pml->get_trees()}) {

            $nest_idx++;

            my $entry_idx = -1;

            foreach my $entry ($nest->children()) {

                $entry_idx++;

                my $lexeme = new Fslib::Struct;

                $lexeme->{'root'} = $nest->{'root'};
                $lexeme->{'core'} = new Fslib::Struct;

                foreach my $key (grep { not /^[_#]/ } keys %$entry) {

                    $lexeme->{'core'}{$key} = $entry->{$key};
                }

                $lexicon->[$nest_idx][$entry_idx] = $lexeme;
            }
        }

        $data = { 'version' => $version, 'lexicon' => $lexicon };

        Storable::nstore $data, $file or warn $! and return;
    }

    $elixir->{'version'} = $data->{'version'};
    $elixir->{'lexicon'} = $data->{'lexicon'};

    print "'" . @{$elixir->{'lexicon'}} . "'\n";
}

sub lexicon {

    elixir_lexicon() unless exists $elixir->{'lexicon'};

    my ($n, $e) = map { /([+-]?[0-9]+)/g } @_;

    return unless defined $n and defined $e;

    return if $n == 0 or $e == 0;

    return if @{$elixir->{'lexicon'}} < abs $n;

    $n-- if $n > 0;

    return if @{$elixir->{'lexicon'}[$n]} < abs $e;

    $e-- if $e > 0;

    return $elixir->{'lexicon'}[$n][$e];
}

sub resolve {

    import Exec::ElixirFM unless exists $elixir->{'resolve'};

    my @word = map { split " " } @_;

    my @news = grep { not exists $elixir->{'resolve'}{$_} } @word;

    my $news = join " ", @news;

    my $data = Exec::ElixirFM::elixir 'resolve', ['--lists'], $news;

    my @data = ElixirFM::unpretty $data;

    warn "MorphoTrees::resolve:\t" . "resolving " . @news . " of " . @word . " words\n" if @word > 1;

    warn "MorphoTrees::resolve:\t" . '@news ' . @news . " <> " . '@data ' . @data . "\n" unless @news == @data;

    $elixir->{'resolve'}{$news[$_]} = $data[$_] for 0 .. @data - 1;

    return map { exists $elixir->{'resolve'}{$_} ? $elixir->{'resolve'}{$_} : [[$_]] } @word;
}

#bind elixir_resolve to Ctrl+R menu ElixirFM Resolve

sub elixir_resolve {

    resolve map { $_->{'form'} } $root->children() if $root->{'#name'} eq 'Unit';

    print encode "buckwalter", $this->{'form'} . "\n";
}

sub morpholists {

    my ($resolve, $done) = @_;

    my ($form, @data) = @{$resolve};

    $done->{'form'} = $form->[0];

    foreach (reverse @data) {

        my $node = NewSon($done);

        DetermineNodeType($node);

        my $done = $node;

        my (undef, @data) = @{$_};

        foreach (reverse @data) {

            my $node = NewSon($done);

            DetermineNodeType($node);

            my $done = $node;

            my (undef, @data) = @{$_};

            foreach (reverse @data) {

                my $node = NewSon($done);

                DetermineNodeType($node);

                $node->{'form'} = substr $_->[0][0], 1, -1;

                my $done = $node;

                my (undef, @data) = @{$_};

                foreach (reverse @data) {

                    my $node = NewSon($done);

                    DetermineNodeType($node);

                    $node->{'tag'} = $_->[0];
                    $node->{'form'} = $_->[1];
                    $node->{'morphs'} = $_->[3];
                }
            }

            demode "arabtex", "noneplus";

            $node->{'form'} = join "  ", ElixirFM::nub { $_[0] } map { join " ", map {

                                                decode "arabtex", $_->{'form'}

                                            } $_->children() } $node->children();

            demode "arabtex", "default";
        }

        $node->{'form'} = join "    ", ElixirFM::nub { $_[0] } map { $_->{'form'} } $node->children();
    }

    return $done;
}

sub morphotrees {

    my ($resolve, $done) = @_;

    my $tree = {};

    # my $element;

    my ($form, @data) = @{$resolve};

    $done->{'form'} = $form->[0];

    foreach (@data) {

        # my $partition;

        my (undef, @data) = @{$_};

        foreach (@data) {

            # my $group;

            my ($node, @data) = @{$_};

            foreach (@data) {

                # my $reading;

                my (undef, @data) = @{$_};

                my @form = map { $_->[1] } @data;

                my @path;

                demode "arabtex", "noneplus";

                $path[0] = decode "arabtex", join " ", @form;

                demode "arabtex", "default";

                for (0 .. @data - 1) {

                    # my $token;

                    $path[1] = $_;

                    $path[2] = $node->[$_][0];

                    $path[3] = join " ", @{$data[$_]}[3, 0];

                    $tree->{$path[0]}[$path[1]]{$path[2]}{$path[3]} = $data[$_];
                }
            }
        }
    }

    foreach my $p (sort { $b =~ tr/ / / <=> $a =~ tr/ / / or $b cmp $a } keys %{$tree}) {

        my $node = NewSon($done);

        DetermineNodeType($node);

        $node->{'form'} = $p;

        my $done = $node;

        foreach my $c (reverse 0 .. @{$tree->{$p}} - 1) {

            my $node = NewSon($done);

            DetermineNodeType($node);

            my $component = $node;

            my $done = $node;

            foreach my $l (reverse sort keys %{$tree->{$p}[$c]}) {

                my $node = NewSon($done);

                DetermineNodeType($node);

                $node->{'form'} = $l;

                my $lexeme = lexicon($l);

                $node->{'root'} = $lexeme->{'root'};
                $node->{'core'} = $lexeme->{'core'};

                my $done = $node;

                foreach my $t (sort keys %{$tree->{$p}[$c]{$l}}) {

                    my $node = NewSon($done);

                    DetermineNodeType($node);

                    my $token = $tree->{$p}[$c]{$l}{$t};

                    $node->{'tag'} = $token->[0];
                    $node->{'form'} = $token->[1];
                    $node->{'morphs'} = $token->[3];

                    unless (exists $component->{'form'}) {

                        demode "arabtex", "noneplus";

                        $component->{'form'} = decode "arabtex", $node->{'form'};

                        demode "arabtex", "default";
                    }
                }
            }
        }
    }

    return $done;
}

# ##################################################################################################
#
# ##################################################################################################

#bind annotate_morphology to space menu Annotate Morphology
sub annotate_morphology {

    $Redraw = 'win' unless $Redraw eq 'file' or $Redraw eq 'tree';

    ChangingFile(0);

    unless ($review->{$grp}{'zoom'}) {

        switch_either_context();

        return;
    }

    # indicated below when the file or the redraw mode actually change

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

                $word = reflect_choice($done);

                unless ($node) {  # ~~ # $root->parent(), $this->following() etc. are defined # ~~ #

                    $word->{'apply'} = $review->{$grp}{'tree'}->{'apply'};

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

    my ($leaf, $twig) = ($_[0], $_[0]->parent());

    my $hash = PML::GetNodeHash();

    if (exists $leaf->{'id'} and $leaf->{'id'} ne '') {

        delete $hash->{$leaf->{'id'}};
        delete $hash->{$twig->{'id'}};

        delete $leaf->{'id'};
        delete $twig->{'id'};
    }

    my $zoom = $review->{$grp}{'zoom'};

    my $word = CopyNode($zoom);

    $hash->{$zoom->{'id'}} = $word;

    PasteNodeBefore($word, $zoom);

    CutNode($zoom);

    $review->{$grp}{'zoom'} = $word;

    my $tree = $review->{$grp}{'tree'};

    my @lexeme = grep { $_->{'apply'} > 0 } map { $_->children() }
                 grep { $_->{'apply'} > 0 } map { $_->children() } $tree->children();

    for (my $i = @lexeme; $i > 0; $i--) {

        $lexeme[$i - 1]->{'id'} = $tree->{'id'} . 'l' . $i;

        $hash->{$lexeme[$i - 1]->{'id'}} = $lexeme[$i - 1];

        my $node = CopyNode($lexeme[$i - 1]);

        delete $node->{'restrict'};
        delete $node->{'inherit'};
        delete $node->{'hide'};
        delete $node->{'tips'};

        $node->{'id'} = $word->{'id'} . 'l' . $i;

        $hash->{$node->{'id'}} = $node;

        PasteNode($node, $word);

        my @token = grep { $_->{'apply'} > 0 } $lexeme[$i - 1]->children();

        for (my $j = @token; $j > 0; $j--) {

            $token[$j - 1]->{'id'} = $lexeme[$i - 1]->{'id'} . 't' . $j;

            $hash->{$token[$j - 1]->{'id'}} = $token[$j - 1];

            my $done = CopyNode($token[$j - 1]);

            delete $done->{'restrict'};
            delete $done->{'inherit'};
            delete $done->{'hide'};

            $done->{'id'} = $node->{'id'} . 't' . $j;

            $hash->{$done->{'id'}} = $done;

            PasteNode($done, $node);
        }
    }

    return $word;
}


sub restrict {

    my @restrict = split //, length $_[0] == $dims ? $_[0] : '-' x $dims;
    my @inherit = split //, $_[1];

    return join '', map { $restrict[$_] eq '-' && defined $inherit[$_] ? $inherit[$_] : $restrict[$_] } 0 .. $#restrict;
}


sub restrict_hide {

    ChangingFile(0);

    return unless $review->{$grp}{'zoom'};

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

        last if $node == $review->{$grp}{'tree'};   # ~~ # $root->parent(), $this->following() etc. are defined # ~~ # never hide the root

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

#bind restrict_verb v menu Restrict Verb
sub restrict_verb {
    restrict_hide('V---------');
}

#bind restrict_noun n menu Restrict Noun
sub restrict_noun {
    restrict_hide('N---------');
}

#bind restrict_adj a menu Restrict Adjective
sub restrict_adj {
    restrict_hide('A---------');
}

#bind restrict_pron s menu Restrict Pronoun
sub restrict_pron {
    restrict_hide('S---------');
}

#bind restrict_num q menu Restrict Numeral
sub restrict_num {
    restrict_hide('Q---------');
}

#bind restrict_adv D menu Restrict Adverb
sub restrict_adv {
    restrict_hide('D---------');
}

#bind restrict_prep p menu Restrict Preposition
sub restrict_prep {
    restrict_hide('P---------');
}

#bind restrict_conj c menu Restrict Conjunction
sub restrict_conj {
    restrict_hide('C---------');
}

#bind restrict_part f menu Restrict Particle
sub restrict_part {
    restrict_hide('F---------');
}

#bind restrict_intj j menu Restrict Interjection
sub restrict_intj {
    restrict_hide('I---------');
}

#bind restrict_xtra x menu Restrict Xtra
sub restrict_xtra {
    restrict_hide('X---------');
}

#bind restrict_ynit y menu Restrict Ynit
sub restrict_ynit {
    restrict_hide('Y---------');
}

#bind restrict_zero z menu Restrict Zero
sub restrict_zero {
    restrict_hide('Z---------');
}

#bind restrict_grph g menu Restrict Grph
sub restrict_grph {
    restrict_hide('G---------');
}

#bind restrict_perfect P menu Restrict Verb Perfect
sub restrict_perfect {
    restrict_hide('-P--------');
}

#bind restrict_imperfect Ctrl+i menu Restrict Verb Imperfect
sub restrict_imperfect {
    restrict_hide('-I--------');
}

#bind restrict_imperative Ctrl+c menu Restrict Verb Imperative
sub restrict_imperative {
    restrict_hide('-C--------');
}

#bind restrict_three V menu Restrict Numeral Three
sub restrict_three {
    restrict_hide('-V--------');
}

#bind restrict_ten X menu Restrict Numeral Ten
sub restrict_ten {
    restrict_hide('-X--------');
}

#bind restrict_teen Y menu Restrict Numeral Teen
sub restrict_teen {
    restrict_hide('-Y--------');
}

#bind restrict_twenty l menu Restrict Numeral Twenty
sub restrict_twenty {
    restrict_hide('-L--------');
}

#bind restrict_thousand m menu Restrict Numeral Thousand
sub restrict_thousand {
    restrict_hide('-M--------');
}

#bind restrict_demo M menu Restrict Pronoun Demonstrative
sub restrict_demo {
    restrict_hide('-D--------');
}

#bind restrict_relative R menu Restrict Pronoun Relative
sub restrict_relative {
    restrict_hide('-R--------');
}

#bind restrict_indicative I menu Restrict Mood Indicative
sub restrict_indicative {
    restrict_hide('--I-------');
}

#bind restrict_subjunctive S menu Restrict Mood Subjunctive
sub restrict_subjunctive {
    restrict_hide('--S-------');
}

#bind restrict_jussive J menu Restrict Mood Jussive
sub restrict_jussive {
    restrict_hide('--J-------');
}

#bind restrict_energetic E menu Restrict Mood Energetic
sub restrict_energetic {
    restrict_hide('--E-------');
}

#bind restrict_active Ctrl+a menu Restrict Voice Active
sub restrict_active {
    restrict_hide('---A------');
}

#bind restrict_passive Ctrl+v menu Restrict Voice Passive
sub restrict_passive {
    restrict_hide('---P------');
}

#bind restrict_first Ctrl+1 menu Restrict Person First
sub restrict_first {
    restrict_hide('-----1----');
}

#bind restrict_second Ctrl+2 menu Restrict Person Second
sub restrict_second {
    restrict_hide('-----2----');
}

#bind restrict_third Ctrl+3 menu Restrict Person Third
sub restrict_third {
    restrict_hide('-----3----');
}

#bind restrict_third_prime 3 menu Restrict Person Third ;)
sub restrict_third_prime {
    restrict_hide('-----3----');
}

#bind restrict_masculine Ctrl+m menu Restrict Gender Masculine
sub restrict_masculine {
    restrict_hide('------M---');
}

#bind restrict_feminine Ctrl+f menu Restrict Gender Feminine
sub restrict_feminine {
    restrict_hide('------F---');
}

#bind restrict_singular Ctrl+s menu Restrict Number Singular
sub restrict_singular {
    restrict_hide('-------S--');
}

#bind restrict_dual Ctrl+d menu Restrict Number Dual
sub restrict_dual {
    restrict_hide('-------D--');
}

#bind restrict_plural Ctrl+p menu Restrict Number Plural
sub restrict_plural {
    restrict_hide('-------P--');
}

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

    ($name, $path, undef) = fileparse($thisfile, '.morpho.xml');

    $file[0] = path $path, $name . '.morpho.xml';
    $file[1] = path $path, $name . ".$level.xml";

    $file[2] = $level eq 'corpus' ? ( path $path, $name . '.morpho.xml' )
                                  : ( path $path, $name . ".$level.xml" );

    $file[3] = path $path, $name . '.morpho.xml.anno.xml';

    unless ($file[0] eq $thisfile) {

        ToplevelFrame()->messageBox (
            -icon => 'warning',
            -message => "This file's name does not fit the directory structure!$fill\n" .
                        "Relocate it to " . $name . '.morpho.xml'. ".$fill",
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

    open_level_syntax();

    Analytic::synchronize_file();
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

        move $file[2], $file[1];
    }

    switch_the_levels($file[1]);
}

#bind open_level_morpho to Ctrl+Alt+1 menu Action: Edit MorphoTrees File
sub open_level_morpho {

    ChangingFile(0);
}

#bind open_level_syntax to Ctrl+Alt+2 menu Action: Edit Analytic File
sub open_level_syntax {

    ChangingFile(0);

    my ($level, $name, $path, @file) = inter_with_level 'syntax';

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

        system 'btred -QI ' . ( escape CallerDir('../../exec/morpho_syntax.ntred') ) .
                        ' ' . ( espace $file[0] );

        move $file[2], $file[1];
    }

    switch_the_levels($file[1]);
}

#bind open_level_tecto to Ctrl+Alt+3 menu Action: Edit DeepLevels File
sub open_level_tecto {

    ChangingFile(0);

    my ($level, $name, $path, @file) = inter_with_level 'deeper';

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

    switch_the_levels($file[1]);
}

sub switch_the_levels {

    my $file = $_[0];

    switch_either_context() if $review->{$grp}{'zoom'};

    my ($tree, $id) = (idx($root), join 's-', split 'm-', $this->{'id'});

    if (Open($file)) {

        GotoTree($tree);

        $this = PML::GetNodeByID($id) ||
                PML::GetNodeByID($id . 't1') ||
                PML::GetNodeByID($id . 'l1t1') || $root;
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
