# -*- cperl -*-

package TrEd::FramesPairs::ExtendedLibXML;
use TrEd::FramesPairs::LibXMLData;
use base qw(TrEd::FramesPairs::LibXMLData);

sub user_cache {
  $self->[10] = {} unless defined($self->[10]);
  return $self->[10];
}

sub doc_free {
  my ($self)=@_;
  %{$self->user_cache}=();
  $self->TrEd::FramesPairs::FramesPairsData::doc_free;
}

sub clear_indexes {
  $self->[8]=undef;
  $self->[9]=undef;
  $self->[10]=undef;
}

sub _uniq { my %a; @a{@_}=@_; values %a }

*elements = \&TrEd::EngValLex::Data::getFrameElementNodes;

sub reload {
  my $self = shift;
  $self->clear_indexes();
  return $self->TrEd::FramesPairs::FramesPairsData::reload(@_);
}


1;
