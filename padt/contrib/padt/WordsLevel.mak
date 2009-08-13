# ########################################################################## Otakar Smrz, 2009/08/12
#
# WordsLevel Context for the TrEd Environment ######################################################

# $Id$

package WordsLevel;

use 5.008;

use strict;

use File::Spec;
use File::Copy;

use File::Basename;

our $VERSION = join '.', '1.1', q $Revision$ =~ /(\d+)/;

# ##################################################################################################
#
# ##################################################################################################

#binding-context WordsLevel

BEGIN { import TredMacro; }

our ($this, $root, $grp);

our ($Redraw);

our ($dims, $fill) = (10, ' ' x 4);

our $hiding_level = 0;

our $regexQ = qr/[0-9]+(?:[\.\,\x{060C}\x{066B}\x{066C}][0-9]+)? |
                 [\x{0660}-\x{0669}]+(?:[\.\,\x{060C}\x{066B}\x{066C}][\x{0660}-\x{0669}]+)?/x;

our $regexG = qr/[\.\,\;\:\!\?\`\"\'\(\)\[\]\{\}\<\>\\\|\/\~\@\#\$\%\^\&\*\_\=\+\-\x{00AB}\x{00BB}\x{060C}\x{061B}\x{061F}]/;

sub words {

    my $text = $_[0];

    my @words = $text =~ /(?: \G \P{IsGraph}* ( (?: \p{Arabic} | [\x{064B}-\x{0652}\x{0670}\x{0657}\x{0656}\x{0640}] |
                                                 # \p{InArabic} |   # too general
                                                \p{InArabicPresentationFormsA} | \p{InArabicPresentationFormsB} )+ |
                                                \p{Latin}+ |
                                                $regexQ |
                                                $regexG |
                                                \p{IsGraph} ) )/ogx;

    return @words;
}

# ##################################################################################################
#
# ##################################################################################################

#bind update_words Ctrl+w menu Update Words
sub update_words {

    my $level = $this->level();

    my $node;

    if ($level == 0) {

        create_words($_) foreach $this->children();
    }
    else {

        $this = $this->parent() foreach 1 .. $level - 1;

        create_words($this);
    }
}

sub create_words {

    my $unit = $_[0];

    DeleteSubtree($_) foreach $unit->children();

    my @words = words $unit->{'form'};

    for (my $i = @words; $i > 0; $i--) {

        my $node = NewSon($unit);

        DetermineNodeType($node);

        $node->{'form'} = $words[$i - 1];

        $node->{'id'} = $unit->{'id'} . 'w' . $i;
    }
}

#bind delete_subtree Ctrl+d menu Edit: Delete Subtree
sub delete_subtree {

    my $node = $this->rbrother() || $this->lbrother() || $this->parent();

    DeleteSubtree($this);

    $this = $node;
}

#bind cut_subtree Ctrl+x menu Edit: Cut Subtree
sub cut_subtree {

    TredMacro::CutToClipboard($this);
}

#bind paste_subtree Ctrl+v menu Edit: Paste Subtree
sub paste_subtree {

    ChangingFile(0);

    return unless defined $TredMacro::nodeClipboard;

    if (not $this->test_child_type($TredMacro::nodeClipboard) and
        $this->parent() and
        $this->parent()->test_child_type($TredMacro::nodeClipboard)) {

        PasteNodeAfter($TredMacro::nodeClipboard, $this);

        $this = $TredMacro::nodeClipboard;

        $TredMacro::nodeClipboard = undef;
    }
    else {

        TredMacro::PasteFromClipboard();
    }

    ChangingFile(1);
}

#bind copy_subtree Ctrl+c menu Edit: Copy Subtree
sub copy_subtree {

    $TredMacro::nodeClipboard = CloneSubtree($this);
}

# ##################################################################################################
#
# ##################################################################################################

sub CreateStylesheets {

    return << '>>';

style:<? $this->{'apply'} > 0 ? '#{Line-fill:red}' :
             exists $this->{'score'} && @{$this->{'score'}} ? '#{Line-fill:orange}' :
                 defined $this->{'apply'} ? '#{Line-fill:black}' : '' ?>

node:<? '#{magenta}${note} << ' if $this->{'#name'} !~ /^(?:Token|Paragraph)$/ and $this->{'note'} ne ''
   ?><? $this->{'#name'} eq 'Token'
            ? ( ElixirFM::orph($this->{'form'}, "\n") )
            : (
            $this->{'#name'} eq 'Lexeme'
                ? ( ( $root->{'#name'} eq 'Element'
                        ? '#{purple}' . ( join ", ", exists $this->{'core'}{'reflex'} ?
                                                            @{$this->{'core'}{'reflex'}} : () ) . ' '
                        : '' ) .
                    '#{darkmagenta}' .
                    ( $this->{'form'} eq '[DEFAULT]' ? $this->{'form'} : ElixirFM::phor($this->{'form'}) ) )
                : (
                $this->{'#name'} =~ /^(?:Component|Partition)$/
                    ? $this->{'form'}
                    : (
                    $this->{'#name'} =~ /^(?:Element|Paragraph)$/
                        ? '#{black}' . WordsLevel::idx($this)
                        : ' ' ) .
                      ( $this->{apply} > 0
                            ? ' #{red}${form}'
                            : ' #{black}${form}' ) ) ) ?>

node:<? '#{goldenrod}${note} << ' if $this->{'#name'} eq 'Token' and $this->{'note'} ne ''
   ?>#{darkred}${tag}<? $this->{'inherit'} eq '' ? '#{red}' : '#{orange}'
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

    my ($node, $done, $mode) = @_;

    return unless $done;

    my $diff = $node->level() - $done->level();

    if ($diff == 1) {

        return;
    }
    else {

        if ($diff == 0) {

            shuffle_node($node, $done);

            Redraw_FSFile_Tree();
            main::centerTo($grp, $grp->{currentNode});
            ChangingFile(1);
        }

        return 'stop';
    }
}

sub shuffle_node ($$) {

    my ($node, $done) = @_;

    my ($fore) = grep { $_ == $node or $_ == $done } GetNodes();

    if ($node == $fore) {

        CutPasteAfter($node, $done);
    }
    else {

        CutPasteBefore($node, $done);
    }
}

sub get_nodelist_hook {

    my ($fsfile, $index, $recent, $show_hidden) = @_;
    my ($nodes, $current);

    ($nodes, $current) = $fsfile->nodes($index, $recent, $show_hidden);

    ($current) = $current->children() if $current->level() == 0 and not $show_hidden;

    @{$nodes} = reverse @{$nodes} if $main::treeViewOpts->{reverseNodeOrder};

    return [[@{$nodes}], $current];
}

sub get_value_line_hook {

    my ($fsfile, $index) = @_;

    return [];
}

sub highlight_value_line_tag_hook {

}

sub value_line_doubleclick_hook {

    return 'stop';
}

sub node_doubleclick_hook {

    return 'stop';
}

sub node_click_hook {

    return 'stop';
}

#bind move_word_home Home menu Move to First Nest
sub move_word_home {

    $this = ($root->children())[0];

    $Redraw = 'none';
    ChangingFile(0);
}

#bind move_word_end End menu Move to Last Nest
sub move_word_end {

    $this = ($root->children())[-1];

    $Redraw = 'none';
    ChangingFile(0);
}

#bind move_next_home Ctrl+Home menu Move to First Entry
sub move_next_home {

    my $node = $this;
    my $level = $node->level();

    my $done;
    my $roof = $level > 1 ? $this->parent() : $this;

    my @children = grep { not IsHidden($_) } $this->children();

    do {

        $done = $node if $level == $node->level();

        $node = PrevVisibleNode($node, $roof);
    }
    while $node and not $node == $roof;     # unexpected extra check ...

    if ($done == $this and @children) {

        $this = $children[0];
    }
    else {

        $this = $done;
    }

    $Redraw = 'none';
    ChangingFile(0);
}

#bind move_next_end Ctrl+End menu Move to Last Entry
sub move_next_end {

    my $node = $this;
    my $level = $node->level();

    my $done;
    my $roof = $level > 1 ? $this->parent() : $this;

    my @children = grep { not IsHidden($_) } $this->children();

    do {

        $done = $node if $level == $node->level();

        $node = NextVisibleNode($node, $roof);
    }
    while $node;

    if ($done == $this and @children) {

        $this = $children[-1];
    }
    else {

        $this = $done;
    }

    $Redraw = 'none';
    ChangingFile(0);
}

#bind move_par_home Shift+Home menu Move to First Cluster
sub move_par_home {

    GotoTree(1);

    $Redraw = 'win';
    ChangingFile(0);
}

#bind move_par_end Shift+End menu Move to Last Cluster
sub move_par_end {

    GotoTree($grp->{FSFile}->lastTreeNo + 1);

    $Redraw = 'win';
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

#bind invoke_undo BackSpace menu Undo Action
sub invoke_undo {

    warn 'Undoooooing ;)';

    main::undo($grp);
    $this = $grp->{currentNode};

    ChangingFile(0);
}

#bind invoke_redo Shift+BackSpace menu Redo Action
sub invoke_redo {

    warn 'Redoooooing ;)';

    main::re_do($grp);
    $this = $grp->{currentNode};

    ChangingFile(0);
}

#bind hiding_level_deeper Ctrl+plus menu Hiding Level Deeper
sub hiding_level_deeper {

    $hiding_level++;

    $hiding_level %= 6;

    ChangingFile(0);
}

#bind hiding_level_higher Ctrl+minus menu Hiding Level Higher
sub hiding_level_higher {

    $hiding_level--;

    $hiding_level %= 6;

    ChangingFile(0);
}

#bind hiding_level_reset Ctrl+equal menu Hiding Level Reset
sub hiding_level_reset {

    $hiding_level = $hiding_level ? 0 : 2;

    ChangingFile(0);
}

# ##################################################################################################
#
# ##################################################################################################

sub path (@) {

    return File::Spec->join(@_);
}

sub inter_with_level ($) {

    my $level = $_[0];

    my (@file, $path, $name);

    my $thisfile = File::Spec->canonpath(FileName());

    ($name, $path, undef) = fileparse($thisfile, '.xml');
    (undef, $path, undef) = fileparse((substr $path, 0, -1), '');

    return $level, $name, $path, @file;
}

#bind open_level_first to Ctrl+Alt+1 menu Action: Edit MorphoTrees File
sub open_level_first {

    ChangingFile(0);

    my ($level, $name, $path, @file) = inter_with_level 'morpho';
}

#bind open_level_second to Ctrl+Alt+2 menu Action: Edit Analytic File
sub open_level_second {

    ChangingFile(0);

    my ($level, $name, $path, @file) = inter_with_level 'syntax';
}

#bind open_level_third to Ctrl+Alt+3 menu Action: Edit DeepLevels File
sub open_level_third {

    ChangingFile(0);

    my ($level, $name, $path, @file) = inter_with_level 'deeper';
}

sub switch_the_levels {

    ChangingFile(0);
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

WordsLevel - Context for Accessing the Words Level in the TrEd Environment


=head1 REVISION

    $Revision$       $Date$


=head1 DESCRIPTION

WordsLevel ...


=head1 SEE ALSO

TrEd Tree Editor L<http://ufal.mff.cuni.cz/~pajas/tred/>

Prague Arabic Dependency Treebank L<http://ufal.mff.cuni.cz/padt/online/>


=head1 AUTHOR

Otakar Smrz, L<http://ufal.mff.cuni.cz/~smrz/>

    eval { 'E<lt>' . ( join '.', qw 'otakar smrz' ) . "\x40" . ( join '.', qw 'mff cuni cz' ) . 'E<gt>' }

Perl is also designed to make the easy jobs not that easy ;)


=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 by Otakar Smrz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
