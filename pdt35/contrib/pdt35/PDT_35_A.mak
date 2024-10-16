# -*- cperl -*-

#ifndef PDT_35_A
#define PDT_35_A

#include <contrib/pml/PML_A_View.mak>

package PDT_35_A;

#binding-context PDT_35_A

#include "PDT_35_A.inc"

#key-binding-adopt PML_A_View
#menu-binding-adopt PML_A_View

#include <contrib/support/unbind_edit.inc>
#include <contrib/support/fold_subtree.inc>

#unbind-key Ctrl+R
#remove-menu Display tectogrammatical tree

#bind TectogrammaticalTree to Ctrl+T menu Display tectogrammatical tree
#bind toggle_clause_coloring to c menu Toggle clause coloring on/off
#bind toggle_clause_folding to f menu Toggle clause folding on/off

1;

#endif PDT_35_A
