# -*- cperl -*-

#ifndef PML_Diff
#define PML_Diff

{

package TrEd::Macro;
our ($grp, $this, $Redraw);


package PML_Diff;

BEGIN { import PML; }

use strict;

my @check_list;
my $compare_all = 1;
my $check_dependency = 1;
my $check_attributes = 1;

#binding-context PML_Diff

#bind clear_diff_attrs to Alt+-
sub clear_diff_attrs {
    foreach my $tree (GetTrees()) {
        foreach my $node ($tree, $tree->descendants) {
            delete $node->{_diff_dep_};
            delete $node->{_diff_attrs_};
        }
    }
}

sub switch_context_hook {
    my ($precontext, $context) = @_;
    return unless ($precontext ne $context);
    return unless $grp->{FSFile};
    Redraw_FSFile();
    return;
}

sub pre_switch_context_hook {
    my ($precontext, $context) = @_;
    return unless ($precontext ne $context);
    return;
}

sub node_style_hook {
    my ($node, $styles) = @_;
    if ($node->{_diff_dep_}) {
        AddStyle($styles, 'Line', -fill => 'red', -dash => '- -');
    }
    if ($node->{_diff_attrs_}) {
        AddStyle($styles, "Oval", -fill => 'darkorange');
        AddStyle($styles, "Node", -addwidth => 4, -addheight => 4);
        AddStyle($styles, "Text[$_]", -fill => 'orange')
            for split / /, $node->{_diff_attrs_};
    }
}

sub current_node_change_hook {
    my ($node, $prev) = @_;
    return unless (exists($node->{order}));
    foreach my $win (@{$grp->{framegroup}->{treeWindows}}) {
        next if ($win eq $grp);
        next unless ($win->{FSFile} and $win->{macroContext} eq 'PML_Diff');
        my $r=$win->{FSFile}->tree($win->{treeNo});
        while ($r and $r->{order} ne $node->{order}) {
            $r = $r->following();
        }
        SetCurrentNodeInOtherWin($win, $r) if ($r);
        CenterOtherWinTo($win, $r) if ($r);
    }
    return;
}

#bind find_next_difference to space menu Goto next difference
sub find_next_difference {
    my $node = $this->following;
    while ($node and not
           ($node->{_diff_dep_}
            or $node->{_diff_attrs_})) {
        $node = $node->following;
    }
    $this = $node if ($node);
    ChangingFile(0);
    $Redraw = 'none';
}


#bind find_next_difference_in_file to Alt+space menu Goto next difference in file
sub find_next_difference_in_file {
    my $node;
    my $next = 1;
  LOOP:
    while ($next) {
        $node = $this->following;
        while ($node) {
            last LOOP if $node->{_diff_dep_} or $node->{_diff_attrs_};
            $node = $node->following;
        }
        $next = TieNextTree();
    }
    if ($node) {
        $this = $node;
        $Redraw = 'tie';
    } else {
        $Redraw = 'tie'
    }
    ChangingFile(0);
}


sub serialize {
    my ($node, $attr) = @_;
    my $ref = ref $node->{$attr};
    if (not $ref) {
        return $node->{$attr};
    }
    if ($ref eq 'Treex::PML::List') {
        my @return = ListV($node->{$attr});
        @return = sort @return if $node->type("$attr/")->is_ordered;
        return join "\n", @return;
    } else {
        return '';
    }
}

sub diff_trees {
    my $summary = shift;

    @check_list = Schema()->attributes unless @check_list;
    my ($id) = Schema()->find_types_by_role('#ORDER');
    $id = $id->get_name;

    my %T = @_;    # %T is a hash of the form id => tree, where id is
                   # any textual identifier of the tree

    my @names = keys %T;

    foreach my $tree (values %T) {
        my $acount = 0;
        my $node = $tree;
        while ($node) {
            $acount++;
            delete $node->{_diff_dep_};
            delete $node->{_diff_attrs_};
            $node = $node->following();
        }
        # store the information in $tree
        $tree->{_acount} = $acount;
    }

    my $total = 0;
    my %total = undef;
    my $total_dependency = 0;
    my $total_values = 0;
    my %dependency = map { $_ => 0 } 1 .. @names;
    my %value = map { $_ => 0 } 1 .. @names;

    my $node;

    # group nodes by order
    my %group_by_order;
    for my $name (@names) {
        for my $node ($T{$name}, $T{$name}->descendants) {
            push @{ $group_by_order{$node->{$id}} }, $node;
        }
    }


    my $r = $T{$names[0]};
    for my $node ($r, $r->descendants) {
        my @grouped = @{ $group_by_order{$node->{$id}}};

        if ($check_dependency) {
            my %parents;
            my @keys = map { $_->parent ? $_->parent->{$id} : 'ROOT' }
                            @grouped;
            undef @parents{@keys};
            if (keys %parents > 1) {
                print "DIFF PARENT $node->{$id}\n";
                $r->{_dcount}++;
                $total_dependency++;
                $_->{_diff_dep_} = 1 for @grouped;
            }
        }

        if ($check_attributes) {
            for my $attr (@check_list) {
                my %strings;
                my @keys = map { serialize($_, $attr) } @grouped;
                undef @strings{@keys};
                if (keys %strings > 1) {
                    print "DIFF ATTR $attr $node->{$id}\n";
                    $r->{_vcount}++;
                    $_->{_diff_attrs_} = 1 for @grouped;
                    $total_values++;
                }
            }
        }
    }

    return unless $summary;
    $total = $total_values + $total_dependency;
    my @summary = ();
    push @summary, "Comparison of @names\n\nFile statistics:\n" if ($summary);

    foreach my  $f (@names) {
        push @summary,
          "$f:\n\tTotal:\t$T{$f}->{_acount} nodes\n";
    }

    foreach (keys %total) {
        $total_values += $total{$_};
    }

    delete $total{''};

    push @summary,
        "Diferences statistics:\n",
        "\tTotal:\t$total differences\n",
        "\tStructure:\t$total_dependency\n",
        "\tAttributes:\t$total_values\n",
        map ({ "\t  -- $_:\t$total{$_}\n" } keys(%total)),
        "\n";
    return @summary;
}

#bind DiffFiles to equal menu Compare trees
#bind DiffWholeFiles to Alt+equal menu Compare files
#bind DiffFiles_select_attrs to Ctrl+equal menu Choose attributes to compare
#bind DiffFiles_with_summary to Ctrl+plus menu Compare trees with summary

sub DiffFiles_select_attrs {
    ListQuery("Select attributes to compare",
              "multiple",
              [Schema()->attributes],
              \@check_list);
    ChangingFile(0);
    $Redraw = 'none';
}

sub DiffFiles_with_summary {
    my ($class) = @_;
    require Tk::ROText;
    my @summary = $class->DiffFiles(1);

    my $top = ToplevelFrame();

    my $d = $top->DialogBox('-title' => "Comparison summary",
                          '-width'   => '8c',
                          '-buttons' => ["OK"]);
    $d->bind('all', '<Escape>'=> [sub { shift;
                                        shift->{selected_button}='OK';
                                    },$d ]);

    my $t= $d->Scrolled(qw/ROText
                           -relief sunken
                           -borderwidth 2
                           -height 30
                           -scrollbars e/,
                        -tabs => [qw/1c 4c/],
                       );
    $t->pack(qw/-expand yes -fill both/);

    $t->insert('0.0', join q{}, @summary);
    $t->BindMouseWheelVert();
    $t->BindMouseWheelHoriz("Shift");
    $t->focus;
    $d->Show();
    ChangingFile(0);
}

sub DiffFiles {
    my ($class, $summary) = @_;
    my $fg = $TredMacro::grp->{framegroup};
    my @T;
    my ($fs, $tree);
    foreach my $win (@{$fg->{treeWindows}}) {
        next unless $compare_all or $win->{macroContext} eq 'PML_Diff';
        $fs = $win->{FSFile};
        if ($fs) {
            $tree = $fs->treeList()->[$win->{treeNo}];
            push @T,
                ($fs->filename()."##".($win->{treeNo}+1) => $tree) if $tree;
        }
    }
    ChangingFile(0);
    if (@T > 2) {
        $Redraw = 'all';
        return diff_trees($summary, @T);
    } else {
        $Redraw = 'none';
    }
}

sub DiffWholeFiles {
    my ($class, $summary)=@_;
    my $fg = $TredMacro::grp->{framegroup};
    my @T;
    my $i = 0;
    do {
        @T = ();
        foreach my $win (@{$fg->{treeWindows}}) {
            next unless $compare_all or $win->{macroContext} eq 'PML_Diff';
            my $fs = $win->{FSFile};
            if ($fs) {
                my $tree;
                $tree = $fs->treeList()->[$i] if $i <= $fs->lastTreeNo();
                push @T, ($fs->filename()."##".($i+1) => $tree) if $tree;
            }
        }
        $i++;
        print STDERR "$i: @T\n";
        diff_trees($summary, @T) if @T > 2;
    } while (@T > 2);
    ChangingFile(0);
    $Redraw = 'all';
}

}
#endif
