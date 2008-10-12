# -*- cperl -*-

#include <tred.mac>

#binding-context TredMacro

package TredMacro;

sub file_opened_hook {

    SwitchContext('ElixirFM');
    SetCurrentStyleSheet('ElixirFM');
}

#include "arabic_common.mak"

#include "ElixirFM.mak"
