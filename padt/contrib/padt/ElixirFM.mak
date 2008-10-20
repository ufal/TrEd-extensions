# ########################################################################## Otakar Smrz, 2008/05/07
#
# ElixirFM Context for the TrEd Environment ########################################################

# $Id: ElixirFM.mak 730 2008-10-18 20:48:24Z smrz $

package ElixirFM;

use 5.008;

use strict;

use ElixirFM;

use File::Spec;
use File::Copy;

our $VERSION = do { q $Revision: 730 $ =~ /(\d+)/; sprintf "%4.2f", $1 / 100 };

# ##################################################################################################
#
# ##################################################################################################

#binding-context ElixirFM

BEGIN { import TredMacro; }

our ($this, $root, $grp);

our ($Redraw);

our ($dims, $fill) = (10, ' ' x 4);

our $hiding_level = 0;


sub entity {

    my $this = $_[0];

    return unless exists $this->{'entity'};

    return $this->{'entity'}[0][0];
}

sub plurals {

    my $this = $_[0];

    return unless exists $this->{'entity'} and exists $this->{'entity'}[0][0][1]{'plural'};

    return @{$this->{'entity'}[0][0][1]{'plural'}};
}

sub feminis {

    my $this = $_[0];

    return unless exists $this->{'entity'} and exists $this->{'entity'}[0][0][1]{'femini'};

    return @{$this->{'entity'}[0][0][1]{'femini'}};
}

sub masdars {

    my $this = $_[0];

    return unless exists $this->{'entity'} and exists $this->{'entity'}[0][0][1]{'masdar'};

    return @{$this->{'entity'}[0][0][1]{'masdar'}};
}

# ##################################################################################################
#
# ##################################################################################################

# our $lexicon = do "C:/Data/PADT-work/ElixirFM/Lexicon.pm";

# my @keys = keys %{$lexicon};

# foreach my $x (@keys) {

    # my $y = $x;
    
    # $y =~ s/^(.+[aiuAIU])(.)[aiu]\2$/$1$2\~/;
    # $y =~ s/^(.+[^aiuAIU])(.)([aiu])\2$/$1$3$2\~/;

    # $y =~ s/[OWI\|\}]$/'/;
    
    # $y =~ s/aY?$//;
    # $y =~ s/uw?$//;
    # $y =~ s/iy?$//;
        
    # if ($x ne $y) {
    
        # $lexicon->{$y} = $lexicon->{$x};
        
        # delete $lexicon->{$x};
    # }
# }


# sub save_rest {

    # ChangingFile(0);
    # use Data::Dumper;
    # open F, '>', 'C:/Data/FunnyThing/Weird.pm';
    # print F Data::Dumper->Dump([$ElixirFM::lexicon], ['lexicon']);
    # close F;
# }

# sub find_verb {

    # ChangingFile(0);

    # my $delete = shift;

    # use Encode::Arabic::Buckwalter ':xml';

    # return unless $this->level() == 2;

    # return unless ElixirFM::entity($this)->[0] eq 'Verb';

    # my $x = $this->{'morphs'};
    # my $y = exists ElixirFM::entity($this)->[1]{'pfirst'} ? ElixirFM::entity($this)->[1]{'pfirst'}[0] || '' : '';

    # foreach my $z ($x, $y) {
    
        # $z = encode "buckwalter", decode "arabtex", ElixirFM::merge($this->parent()->{'root'}, $z);
    
        # $z =~ s/[OWI\|\}]$/'/;

        # $z =~ s/aA/A/g;

        # $z =~ s/aY$//;
        # $z =~ s/uw$//;
        # $z =~ s/iy$//;
    
        # if (exists $lexicon->{$z}) {

            # unless ($this->children()) {

                # ChangingFile(1);
                
                # $this = new_Frame();
                # $this = new_Frame();
            # }

            # delete $lexicon->{$z} if $delete;
        # }
    # }

    # return;
# }

sub change_entity {

    ChangingFile(0);

    return unless $this->level() == 2;

    ChangingFile(1);

    my $ent = ElixirFM::entity($this);

    @{$ent} = @_;

    return $ent->[1];
}

#bind change_entity_V Ctrl+V menu Change Entity Verb
sub change_entity_V {

    ChangingFile(0);

    return unless $this->level() == 2;

    my $old = ElixirFM::entity($this)->[1];

    my $new = change_entity('Verb', new Fslib::Struct);

    foreach (qw 'form pfirst imperf second tense voice') {

        $new->{$_} = $old->{$_} if exists $old->{$_};
    }

    ChangingFile(1);
}

#bind change_entity_N Ctrl+N menu Change Entity Noun
sub change_entity_N {

    ChangingFile(0);

    return unless $this->level() == 2;

    my $ent = ElixirFM::entity($this);

    my $cat = $ent->[0];
    my $old = $ent->[1];

    my $new = change_entity('Noun', new Fslib::Struct);

    foreach (qw 'plural gender number derive') {

        $new->{$_} = $old->{$_} if exists $old->{$_};
    }

    if ($cat eq 'Adj') {

        unless (exists $new->{'plural'} and @{$new->{'plural'}}) {

            $new->{'plural'} = List($this->{'morphs'} . ' |< Un');
        }

        $new->{'derive'} = '------F---';
    }

    ChangingFile(1);
}

#bind change_entity_A Ctrl+A menu Change Entity Adj
sub change_entity_A {

    ChangingFile(0);

    return unless $this->level() == 2;

    my $old = ElixirFM::entity($this)->[1];

    my $new = change_entity('Adj', new Fslib::Struct);

    foreach (qw 'plural femini number') {

        $new->{$_} = $old->{$_} if exists $old->{$_};
    }

    if (exists $new->{'plural'} and @{$new->{'plural'}} == 1) {

        delete $new->{'plural'} if $new->{'plural'}[0] eq $this->{'morphs'} . ' |< Un';
    }

    ChangingFile(1);
}

#bind change_entity_S Ctrl+S menu Change Entity Pron
sub change_entity_S {

    change_entity('Pron', new Fslib::Container);
}

#bind change_entity_Q Ctrl+Q menu Change Entity Num
sub change_entity_Q {

    ChangingFile(0);

    return unless $this->level() == 2;

    my $old = ElixirFM::entity($this)->[1];

    my $new = change_entity('Num', new Fslib::Struct);

    foreach (qw 'plural femini') {

        $new->{$_} = $old->{$_} if exists $old->{$_};
    }

    ChangingFile(1);
}

#bind change_entity_D Ctrl+D menu Change Entity Adv
sub change_entity_D {

    change_entity('Adv', new Fslib::Container);
}

#bind change_entity_P Ctrl+P menu Change Entity Prep
sub change_entity_P {

    change_entity('Prep', new Fslib::Container);
}

#bind change_entity_C Ctrl+C menu Change Entity Conj
sub change_entity_C {

    change_entity('Conj', new Fslib::Container);
}

#bind change_entity_F Ctrl+F menu Change Entity Part
sub change_entity_F {

    change_entity('Part', new Fslib::Container);
}

#bind change_entity_I Ctrl+I menu Change Entity Intj
sub change_entity_I {

    change_entity('Intj', new Fslib::Container);
}

#bind change_entity_X Ctrl+X menu Change Entity Xtra
sub change_entity_X {

    change_entity('Xtra', new Fslib::Container);
}

#bind change_entity_Y Ctrl+Y menu Change Entity Ynit
sub change_entity_Y {

    change_entity('Ynit', new Fslib::Container);
}

#bind change_entity_Z Ctrl+Z menu Change Entity Zero
sub change_entity_Z {

    change_entity('Zero', new Fslib::Container);
}

#bind change_entity_G Ctrl+G menu Change Entity Grph
sub change_entity_G {

    change_entity('Grph', new Fslib::Container);
}

#bind enforce_literal Ctrl+l menu Enforce Literal
sub enforce_literal {

    ChangingFile(0);

    my $node = $this;

    $node = $node->parent() if $node->level() == 2;

    return unless $node->level() == 1;

    my %m = map { ElixirFM::morphs($_)->[0], 1 }
            map { $_->{'morphs'},
                  ElixirFM::plurals($_),
                  ElixirFM::feminis($_) } $node->children();

    my @m = keys %m;

    return unless @m == 1 and $m[0] ne '_____';

    $node->{'root'} = ElixirFM::merge($node->{'root'}, $m[0]);

    foreach ($node->children()) {

        $_ =~ s/^((?:.+\>\| )?)[^ ]+((?: \|\<.+)?)$/$1_____$2/

            foreach $_->{'morphs'},
                    exists $_->{'entity'} ?
                    ((exists $_->{'entity'}[0][0][1]{'plural'} ? @{$_->{'entity'}[0][0][1]{'plural'}} : ()),
                     (exists $_->{'entity'}[0][0][1]{'femini'} ? @{$_->{'entity'}[0][0][1]{'femini'}} : ())) : ();
    }

    ChangingFile(1);
}

#bind enforce_string Ctrl+s menu Enforce String
sub enforce_string {

    ChangingFile(0);

    my $node = $this;

    $node = $node->parent() if $node->level() == 2;

    return unless $node->level() == 1;

    my %m = map { ElixirFM::morphs($_)->[0], 1 }
            map { $_->{'morphs'},
                  ElixirFM::plurals($_),
                  ElixirFM::feminis($_) } $node->children();

    my @m = keys %m;

    return unless @m == 1 and $m[0] !~ /^"[^ ]+"$/;

    $node->{'root'} = ElixirFM::merge($node->{'root'}, $m[0]);

    foreach ($node->children()) {

        $_ =~ s/^((?:.+\>\| )?)[^ ]+((?: \|\<.+)?)$/$1"$node->{'root'}"$2/

            foreach $_->{'morphs'},
                    exists $_->{'entity'} ?
                    ((exists $_->{'entity'}[0][0][1]{'plural'} ? @{$_->{'entity'}[0][0][1]{'plural'}} : ()),
                     (exists $_->{'entity'}[0][0][1]{'femini'} ? @{$_->{'entity'}[0][0][1]{'femini'}} : ())) : ();
    }

    $node->{'root'} = join ' ', split /(?<![._^,])/, $node->{'root'};

    ChangingFile(1);
}

#bind new_Nest Ctrl+n menu New Nest
sub new_Nest {

    my $level = $this->level();

    my $node;

    if ($level == 0) {

        $node = NewSon($this);
    }
    else {

        $this = $this->parent() foreach 1 .. $level - 1;

        $node = NewLBrother($this);
    }

    DetermineNodeType($node);

    return $node;
}

#bind new_Entry Ctrl+e menu New Entry
sub new_Entry {

    my $level = $this->level();

    my $node;

    ChangingFile(0);

    if ($level == 0) {

        $this = new_Nest($this);

        $level++;
    }

    if ($level == 1) {

        $node = NewSon($this);
    }
    else {

        $this = $this->parent() foreach 1 .. $level - 2;

        $node = NewLBrother($this);
    }

    DetermineNodeType($node);

    $node->{'morphs'} = '_____';

    $node->{'entity'} = new Fslib::Seq;

    $node->{'entity'}->set_content_pattern('(Verb|Noun|Adj|Pron|Num|Adv|Prep|Conj|Part|Intj|Xtra|Ynit|Zero|Grph)');
    $node->{'entity'}->push_element('Grph', new Fslib::Struct);

    ChangingFile(1);

    return $node;
}

#bind new_Frame Ctrl+f menu New Frame
sub new_Frame {

    my $level = $this->level();

    my $node;

    ChangingFile(0);

    return unless $level > 1;

    $node = NewSon($this);

    DetermineNodeType($node);

    if ($level == 3 and not $node->rbrother()) {

        $node->{'role'} = 'ACT';
        $node->{'type'} = 'OBL';
    }

    ChangingFile(1);

    return $node;
}

#bind change_slot_role Ctrl+r menu Change Slot Role
sub change_slot_role {

    ChangingFile(0);

    return unless $this->level() == 4;

    main::doEditAttr($grp, $this, 'role');
}

#bind change_slot_type Ctrl+t menu Change Slot Type
sub change_slot_type {

    ChangingFile(0);

    return unless $this->level() == 4;

    main::doEditAttr($grp, $this, 'type');
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

rootstyle:<? '#{vertical}#{Node-textalign:left}#{Node-shape:rectangle}' .
             '#{skipHiddenLevels:1}#{lineSpacing:1.2}' ?>

style:<? ( $this->level() < 6 ? '#{Line-coords:n,n,p,n,p,p}' : '' ) .
         ( $ElixirFM::hiding_level && $this->level() > $ElixirFM::hiding_level
               ? '#{Node-hide:1}' :
           $this->level() == 0 ? '#{Node-hide:1}' :
           $this->level() == 4 ? '#{Node-rellevel:1}' . (
                 $this->{'type'} eq 'OBL'
               ? '#{Line-dash}#{Line-width:3}#{Line-fill:black}'
               : $this->{'type'} eq 'OPT'
               ? '#{Line-dash:-}#{Line-width:2}#{Line-fill:black}'
               : '#{Line-dash:-}#{Line-width:2}#{Line-fill:red}' ) :
           $this->level() == 6 ? '#{Node-rellevel}' . (
                 '#{Line-dash}#{Line-width:2}#{Line-fill:black}'
           ) : '' ) ?>

node:<? $this->level() == 2
      ? '${entity=' . ElixirFM::entity($this)->[0] . '}   #{custom6}${entity=' .
        ( join '}  #{custom3}${entity=',
          map { ref $_ ? @{$_} : () }
          map { $_->{form}, $_->{imperf}, $_->{second}, $_->{pfirst} }
          ElixirFM::entity($this)->[1] ) . '}' .
        ( $this->{'limits'}{'fst'} ?
          "\n" . '#{custom7}${limits=limited} #{custom3}${limits="' .
          $this->{'limits'}{'fst'} . '"}' : '' ) .
        ( ElixirFM::entity($this)->[1]{'derive'} ?
          "\n" . '#{custom7}${entity=derives} #{custom3}${entity="' .
          ElixirFM::entity($this)->[1]{'derive'} . '"}' : '' )
      : $this->level() == 4
      ? ( $this->{'type'} eq 'OBL' ? '#{custom2}' :
          $this->{'type'} eq 'OPT' ? '#{custom6}' : '') .
          '${=' . $this->{'role'} . '}'
      : $this->level() > 4
      ? ( join "\n", $this->{'form'} eq '' ? ()
                     : '${=' . ElixirFM::phor($this->{'form'}) . '}',
                     $this->{'tag'} eq '' ? ()
                     : '#{custom2}${=' . $this->{'tag'} . '}' )
      : '#{darkgrey}${entity=' . $this->{'#name'} . '}'
   ?><? $this->level() == 1
      ? '  #{custom6}' . ElixirFM::phor(ElixirFM::cling($this->{'root'})) .
        '  #{custom2}' . '${root}'
      : '' ?>

node:<? $this->level() == 2
      ? '#{custom2}${morphs=' . $this->{morphs} . '}'
        . ( join "", map { "\n" . $_ } map {
              '#{custom6}${entity=' . $_ . '}' }
            ElixirFM::plurals($this),
            ElixirFM::masdars($this) )
        . ( join "", map { "\n" . $_ } map {
              '#{custom3}${entity=' . $_ . '}' }
            ElixirFM::feminis($this) )
      : '' ?>

node:<? $this->level() == 2
      ? ElixirFM::phon(ElixirFM::merge($this->parent()->{'root'}, $this->{morphs})) .
        '#{grey30}' . ( join "",
          map { "\n" . ElixirFM::phon(ElixirFM::merge($_->[0], $_->[1])) }
          map { [$this->parent()->{'root'}, $_] }
          ElixirFM::plurals($this),
          ElixirFM::masdars($this),
          ElixirFM::feminis($this) )
      : '' ?>

node:<? $this->level() == 2
      ? ElixirFM::orth(ElixirFM::merge($this->parent()->{'root'}, $this->{morphs})) .
        '#{grey30}' . ( join "",
          map { "\n" . ElixirFM::orth(ElixirFM::merge($_->[0], $_->[1])) }
          map { [$this->parent()->{'root'}, $_] }
          ElixirFM::plurals($this),
          ElixirFM::masdars($this),
          ElixirFM::feminis($this) )
      : '' ?>

node:#{custom3}<?'${reflex=' . (join ", ", @{$this->{reflex}}) . '}'?>

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
    my ($nodes, $words);

    my $tree = $fsfile->tree($index);

    return [];
}

sub highlight_value_line_tag_hook {

    return $grp->{root} if $grp->{root}->{'type'} eq 'entity';

    my $node = $grp->{currentNode};

    $node = $node->parent() until !$node or $node->{'type'} eq 'word_node' or $node->{'type'} eq 'paragraph';

    return $node;
}

sub value_line_doubleclick_hook {

    return if $grp->{root}->{'type'} eq 'paragraph';

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

    ($name, $path, undef) = File::Basename::fileparse($thisfile, '.xml');
    (undef, $path, undef) = File::Basename::fileparse((substr $path, 0, -1), '');

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

ElixirFM - Context for Annotation of the ElixirFM Lexicon in the TrEd Environment


=head1 REVISION

    $Revision: 730 $       $Date: 2008-10-18 22:48:24 +0200 (Sat, 18 Oct 2008) $


=head1 DESCRIPTION

ElixirFM ...


=head1 SEE ALSO

TrEd Tree Editor L<http://ufal.mff.cuni.cz/~pajas/tred/>

Prague Arabic Dependency Treebank L<http://ufal.mff.cuni.cz/padt/online/>


=head1 AUTHOR

Otakar Smrz, L<http://ufal.mff.cuni.cz/~smrz/>

    eval { 'E<lt>' . ( join '.', qw 'otakar smrz' ) . "\x40" . ( join '.', qw 'mff cuni cz' ) . 'E<gt>' }

Perl is also designed to make the easy jobs not that easy ;)


=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Otakar Smrz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
