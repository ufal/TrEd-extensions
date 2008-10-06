## -*- cperl -*-
## author: Petr Pajas
## $Id$
## Time-stamp: <2008-02-26 12:28:03 pajas>

#
# This file defines default macros for TR annotators.
# Only TredMacro context is present here.
#

sub register_exit_hook ($) {
  my ($hook)=@_;
  push @global_exit_hooks,$hook;
}

sub unregister_exit_hook ($) {
  my ($hook)=@_;
  @global_exit_hooks=grep { $_ ne $hook } @global_exit_hooks;
}

sub exit_hook {
  foreach my $sub (@global_exit_hooks) {
    if (ref($sub) eq 'ARRAY') {
      my $realsub=shift @$sub;
      eval{ &{$realsub}(@$sub); };
    } else {
      eval{ &$sub(); };
    }
    stderr($@) if $@;
  }
}

#ifdef TRED
sub patterns_forced {
  return (grep { $_ eq 'force' } GetPatternsByPrefix('patterns',STYLESHEET_FROM_FILE()) ? 1 : 0)
}

sub file_opened_hook {

  # if this file has no balloon pattern, I understand it as a reason to override
  # its display settings!

  Tectogrammatic->upgrade_file();

  if ($grp->{FSFile} and ! patterns_forced() and !$grp->{FSFile}->hint()) {
    Tectogrammatic->default_tr_attrs();
  }

  disable_node_menu_items();
  my $o=$grp->{framegroup}->{ContextsMenu};
  $o->options(['Tectogrammatic','TR_Diff']);
  SwitchContext('Tectogrammatic');
  $FileNotSaved=0;
}
#endif

#ifdef TRED
sub file_resumed_hook {
  SwitchContext('Tectogrammatic');
}
#endif

#include "tred_mac_common.mak"

#binding-context Tectogrammatic
#include "tr.mak"

#binding-context TR_Diff
#include "trdiff.mak"

#include "pdt.mak"
