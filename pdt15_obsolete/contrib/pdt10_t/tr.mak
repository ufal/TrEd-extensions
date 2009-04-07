## -*- cperl -*-
## author: Petr Pajas
## Time-stamp: <2009-04-03 11:31:47 pajas>

package Tectogrammatic;

BEGIN { import TredMacro; }

push @TredMacro::AUTO_CONTEXT_GUESSING, sub {
  if ($grp->{FSFile} and $grp->{FSFile}->FS and $grp->{FSFile}->FS->hide eq 'TR') {
    if (CurrentContext() eq 'TR_Correction' or CurrentContext() eq 'TFA') {
      return CurrentContext();
    } else {
      return 'Tectogrammatic';
    }
  }
  return;
};

sub patterns_forced {
  return (grep { $_ eq 'force' } GetPatternsByPrefix('patterns',STYLESHEET_FROM_FILE()) ? 1 : 0)
}

sub switch_context_hook {

  # if this file has no balloon pattern, I understand it as a reason to override
  # its display settings!

  if ($grp->{FSFile} and !patterns_forced() and !$grp->{FSFile}->hint()
     ) {
    default_tr_attrs();
  }
  $FileNotSaved=0;
}

#include "tr_common.mak"

#include "tr_vallex_transform.mak"

