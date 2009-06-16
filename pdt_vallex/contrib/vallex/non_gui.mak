# -*- cperl -*-

#ifndef pdt_vallex_non_gui
#define pdt_vallex_non_gui

package ValLex::NonGUI;

BEGIN { import TredMacro; }

sub new {
  my ($self,$file)=@_;
  require XML::JHXML;
  require TrEd::ValLex::Data;
  require TrEd::ValLex::ExtendedJHXML;
  $file ||= $ENV{VALLEX} || FindInResources('vallex.xml');
  my $url = IOBackend::make_URI($file);
  $file = ($url->scheme eq 'file') ? $url->file : "$url";
  return TrEd::ValLex::ExtendedJHXML->new($file);
}

1;

#endif pdt_vallex_non_gui
