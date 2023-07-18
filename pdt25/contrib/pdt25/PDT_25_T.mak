# -*- cperl -*-

#ifndef PDT_25_T
#define PDT_25_T

#include <contrib/pml/PML_T_View.mak>

package PDT_25_T;

#binding-context PDT_25_T

#include "PDT_25_T.inc"

#key-binding-adopt PML_T_View
#menu-binding-adopt PML_T_View

#include <contrib/support/unbind_edit.inc>

#bind AnalyticalTree to Ctrl+A menu Display corresponding analytical tree
#bind toggle_clause_coloring to c menu Toggle clause coloring on/off
#bind toggle_mwe_folding to f menu Toggle multiword-entity folding on/off
#bind toggle_legend to l menu Toggle Legend

1;

#endif PDT_25_T
