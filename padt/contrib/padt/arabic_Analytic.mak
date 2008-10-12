# -*- cperl -*-

#include <tred.mac>

#binding-context TredMacro

package TredMacro;

sub file_opened_hook {

    SwitchContext('Analytic');
    SetCurrentStyleSheet('Analytic');
}

#include "arabic_common.mak"

#include "Analytic.mak"
