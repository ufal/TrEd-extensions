# -*- cperl -*-

#include "arabic_common.mak"

#include "MorphoTrees.mak"
#include "Analytic.mak"
#include "DeepLevels.mak"
#include "PhraseTrees.mak"
#include "ElixirFM.mak"

package TredMacro;

push @AUTO_CONTEXT_GUESSING, sub {

    ## my ($hook) = @_;

    if (defined PML::SchemaName()) {
      if (PML::SchemaName() =~ /ElixirFM|MorphoTrees|Analytic|DeepLevels/) {
        SetCurrentStylesheet(PML::SchemaName());
        return PML::SchemaName();
      }
    }

    return 'MorphoTrees' if $grp->{FSFile}->FS()->isList('type') and
                            grep { /[EP]|paragraph|entity/ } $grp->{FSFile}->FS()->listValues('type');

    return 'DeepLevels'  if $grp->{FSFile}->FS()->isList('func') and
                            grep { /ACT|PAT|ADDR|EFF|ORIG/ } $grp->{FSFile}->FS()->listValues('func');

    return 'Analytic'    if $grp->{FSFile}->FS()->exists('afun') and
                            $grp->{FSFile}->FS()->exists('arabclause');

    return;
}
