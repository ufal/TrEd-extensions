# -*- cperl -*-

#ifndef pdt_vallex_non_gui
#define pdt_vallex_non_gui

package ValLex::NonGUI;

BEGIN { import TredMacro; }

sub new {
  my ($self,$file)=@_;
  my $jh = eval {
      require XML::JHXML;
      require TrEd::ValLex::ExtendedJHXML;
      1;
  };
  unless ($jh) {
      require TrEd::ValLex::Data;
      require TrEd::ValLex::ExtendedLibXML;
  };
  $file ||= $ENV{VALLEX} || FindInResources('vallex.xml');
  my $url = Treex::PML::IO::make_URI($file);
  $file = ($url->scheme eq 'file') ? $url->file : "$url";
  return TrEd::ValLex::ExtendedJHXML->new($file) if $jh;
  return TrEd::ValLex::ExtendedLibXML->new($file, 0, 1);
}

1;

#endif pdt_vallex_non_gui
