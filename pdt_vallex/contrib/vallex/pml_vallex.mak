# -*- cperl -*-

package PML_Vallex;

#binding-context PML_Vallex
#bind space to EditAttributes

BEGIN { import TredMacro; }
use strict;

sub detect {
  return ( (PML::SchemaName() eq 'valency_lexicon') ? 1 : 0 );
}

push @TredMacro::AUTO_CONTEXT_GUESSING, sub {
  my ($hook)=@_;
  my $resuming = ($hook eq 'file_resumed_hook');
  my $current = CurrentContext();
  if (detect()) {
    SetCurrentStylesheet('PML_Vallex') if $resuming;
    return 'PML_Vallex';
  }
  return;
};

sub allow_switch_context_hook {
  return 'stop' unless detect();
}
sub switch_context_hook {
  SetCurrentStylesheet('PML_Vallex');
  Redraw() if GUI();
}

sub element_to_text {
  my ($el)=@_;
  my $text='';
  $text.='?' if $el->{type} eq 'non-oblig';
  $text.=$el->{functor}.'(';
  $text.=join ';', map {
    join ',', map { 
      my $n = $_;
      if (length($n->{'#label'})) {
	$n->{'#label'}
      } else {
	if ($n->{'#name'} =~ /^(?:typical|elided|state)$/) {
	  $n->{'#name'}
	} else {
	  my $morph =join('',grep { $_ ne 'unspecified' } map { $n->{$_} } qw(pos case deg gen num form afun));
	  ($n->{lemma}||'').($morph ? '.'.$morph : '')
	}
      }
    } $_->children;
  } $el->children;
  $text.=')';
  return $text;
}

1;

