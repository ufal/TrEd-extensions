# -*- cperl -*-

#ifndef czengvallex
#define czengvallex

#include <contrib/pml/PML.mak>
#include <contrib/eng-vallex/contrib.mac>
#include <contrib/vallex/contrib.mac>
#include <contrib/support/move_nodes_freely.inc>

package czengvallex;

#include "czengvallex.inc"

## Commented-out, do not include standard Tred macros in the czengvallex submenu
##key-binding-adopt TredMacro
##menu-binding-adopt TredMacro

#bind OpenValLexicon to Ctrl+Shift+Return menu Browse valency frame lexicon
#bind ChooseValFrame to Ctrl+Return menu Select and assign valency frame
#bind toggle_display_all to a menu Toggle display all nodes
#bind toggle_display_all_arrows to A menu Toggle display suggested arrows for all nodes
#bind AddNote to ! menu Add Note
#bind EditNote to n menu Edit Note
#bind EditCzengvallexFunctor to f menu Set functor for CzEngVallex purposes
#bind HandleCoApsSM to h menu Handle coordination, apposition and SM
#bind HandleAllCoApsSM to H menu Handle all coordinations, appositions and SM
#bind AddArtificialSons to s menu Add artificial sons
#bind AddAllArtificialSons to S menu Add all artificial sons
#bind CollectValLinks to c menu Collect slot links to FramesPairs
#bind CollectAllValLinks to C menu Collect slot links to FramesPairs for all nodes
#bind SetStatusDeleted to d menu Delete frame pair

#bind RemoveValLinks to Alt+R menu Delete slot links from FramesPairs
#bind RedrawValLinks to r menu Debug: Redraw automatic slot links
#bind RedrawAllValLinks to R menu Debug: Redraw automatic slot links for all nodes
#bind ReloadFramesPairs to L menu Reload file FramesPairs
#bind SaveFramesPairs to P menu Save file FramesPairs
#bind OpenFramesPairs to F menu Browse FramesPairs file
###bind jump_to_rightmost_tree_in_next_bundle to n
###bind jump_to_rightmost_tree_in_prev_bundle to p

#bind RotateNotCollect to Alt+l menu Change not_collect (only for english nodes)
#bind RotateSlotRemove to Alt+r menu Change slot_remove (only for english nodes)

#bind RememberNode to space menu Remember current node
#bind ForgetRemembered to Shift+space menu Forget remembered node
#bind ValalignCorefToRemembered to Alt+c menu Add or Remove valalign coref to remembered node

1;

#endif czengvallex

