# -*- cperl -*-

# context guessing

push @TredMacro::AUTO_CONTEXT_GUESSING, sub {
  my ($hook)=@_;
  my $resuming = ($hook eq 'file_resumed_hook');
  my $current = CurrentContext();
  if (PML::SchemaName() eq 'tdata') {
    SetCurrentStylesheet(STYLESHEET_FROM_FILE()) if $resuming;
    if ($current eq 'PML_A_Edit') {
      return 'PML_T_Edit';
    } elsif ($current =~ /^PML.*_T_/) {
      return $current;
    } else {
      return 'PML_T_View';
    }
  } elsif (PML::SchemaName() eq 'adata') {
    SetCurrentStylesheet(STYLESHEET_FROM_FILE()) if $resuming;
    if ($current eq 'PML_T_Edit') {
      return 'PML_A_Edit';
    } elsif ($current =~ /^PML.*_A_/) {
      return $current;
    } else {
      return 'PML_A_View';
    }
    return 1;
  } elsif (PML::SchemaName() eq 'aeditdata') {
    SetCurrentStylesheet(STYLESHEET_FROM_FILE()) if $resuming;
    return 'PML_A_Edit';
  } elsif (PML::SchemaName() eq 'mdata') {
    SetCurrentStylesheet(STYLESHEET_FROM_FILE()) if $resuming;
    if ($current =~ /^PML.*_M_/) {
      return $current;
    } else {
      return 'PML_M';
    }
  }
  return;
};
