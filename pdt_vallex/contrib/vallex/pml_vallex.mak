# -*- cperl -*-

package PML_Vallex;

#binding-context PML_Vallex
#bind space to EditAttributes

BEGIN { import TredMacro; }
use strict;

sub allow_switch_context_hook {
  return 'stop' if SchemaName() ne 'valency_lexicon';
}
sub switch_context_hook {
  SetCurrentStylesheet('PML_Vallex');
  Redraw() if GUI();
}

1;

