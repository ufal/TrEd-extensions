# -*- mode: cperl; coding: utf-8; -*-


package CZ_T_Analysis;
{
#encoding utf8

use utf8;
use strict;
use warnings;
BEGIN { import TredMacro; }
use File::Temp ();
use File::Spec ();

use vars qw($tmt_root);

BEGIN {
   use vars qw($root $this $grp);
   my $tmt_dir=FindMacroDir('tectomt');
   $ENV{TMT_ROOT}= $tmt_root = "$tmt_dir/tectomt_root/";
   $ENV{TMT_SHARED}="$tmt_dir/tectomt_shared/";
}

use lib "$tmt_root/libs/core";
use lib "$tmt_root/libs/blocks";
use lib "$tmt_root/libs/other";

sub __this_dir {
  my $this_script_path =  [caller(0)]->[1];
  my ($volume,$dir) = File::Spec->splitpath( $this_script_path );
  return File::Spec->catpath($volume,$dir);
}

$TrEd::MacroStorage::CZ_T_Analysis::sentence||='Kočka leze dírou, pes oknem, nebude-li pršet, nezmoknem.';

=head1 NAME

CZ_T_Analysis - a TectoMT-based Czech analyzer for TrEd

=head1 DESCRIPTION

This package contains a TectoMT-based Czech analyzer producing
tectogrammatical, analytical and morphological layers for a given
Czech sentence.

=head1 USAGE

Use Macros->* Analyze Czech Text menu command in TrEd to start the
macro; select a base-filename for the PML files with the analysis and
insert one or more Czech sentences into the text box. The analyzer
will produce three PDT~2.0-like files with the suffixes .t
(tectogrammatical analysis), .a (analytical analysis), .m
(morphological analysis).

=cut


Bind(
  __PACKAGE__.'->analyze_sentence'  => {
    # key => 'F9',
    context=>'TredMacro',
    menu=>'__* Analyze Czech Text',
    changing_file => 0,
  }
);

=head1 MACROS

=over 5

=item CZ_T_Analysis->analyze_sentence(\%options)

Analyze a given Czech sentence up to tectogrammatical layer (without
functors) using a simple TectoMT application, producing 
three PML documents: mdata, adata, and tdata.

Optional arguments:

=over 8

=item sentence

The Czech sentence to analyze. If not given, a sample sentence is used
and if running from TrEd's GUI, the user is asked to replace or modify the sentence.

=item dir

A directory in which to store the resulting files.

=item basename

Basename for the resulting files. The suffixes .m.gz, .a.gz, and .t.gz
are appended. Default basename is 'result'.

=back

=cut

sub analyze_sentence {
  my ($class,$opts)=@_;

  croak "Usage: ".__PACKAGE__."->analyze_sentence({...})"
    if ref($class) or (defined($opts) and ref($opts) ne 'HASH');

  my ($sentence,$dir,$basename)= $opts ? (map $opts->{$_}, qw(sentence dir basename)) : ();
  croak "Directory $dir does not exist!" if defined($dir) and ! -d $dir;
  croak "Not a valid filename!" if defined($basename) && $basename=~m{[/\\:]};

  if (GUI()) {
    if (!defined($dir) and !defined($basename)) {
      ToplevelFrame()->Unbusy();
      my $path = main::get_save_filename(ToplevelFrame(),-title => 'Save result as (enter basename only)');
      ToplevelFrame()->Busy(-recurse=>1);
      return unless defined $path and length $path;
      my ($v,$d,$b) = File::Spec->splitpath($path);
      $dir=File::Spec->catpath($v,$d);
      $basename=$b;
    }
  }

  $basename='result' unless defined($basename) and length($basename);
  unless ($sentence) {
    if (GUI()) {
      $sentence = EditBoxQuery("Analyze text",$TrEd::MacroStorage::CZ_T_Analysis::sentence,"Enter czech text to analyze:") || return;
    } else {
      $sentence = $TrEd::MacroStorage::CZ_T_Analysis::sentence;
    }
  }
  $TrEd::MacroStorage::CZ_T_Analysis::sentence=$sentence;

  {
    my @rp;
    {
      local $Treex::PML::resourcePath = $Treex::PML::resourcePath;
      require TredPlugin::CzechAnalysis;
      @rp=$Treex::PML::resourcePath;
    }
    AddResourcePath(@rp);
  }

  my %results;
  @results{qw(m a t)} = TredPlugin::CzechAnalysis::Get_mat_text_analyses($sentence);

  $dir ||= File::Temp->tempdir('tredXXXX',TMPDIR=>1,CLEANUP=>1);

  # fix the results
  for my $m_root (@{$results{m}}) {
    $m_root->{'#name'}='s';
    for my $m ($m_root->descendants) {
      $m->{'#name'}='m';
      $m->{'#content'}=Treex::PML::Factory->createStructure({
	map { $_ => delete $m->{$_} }
	  qw(id form lemma tag)
	 },1);
    }
  }
  for my $a_root (@{$results{a}}) {
    for my $a ($a_root) {
      $a->{'s.rf'}='m#'.$a->{id};
      $a->{'s.rf'}=~s/A/M/;
    }
    PML_A_Edit->assign_afun_auto_tree( $a_root ); # before we delete m
    for my $a ($a_root->descendants) {
      $a->{'m.rf'}='m#'.$a->{id};
      $a->{'m.rf'}=~s/A/M/;
      delete $a->{m};
    }
  }

  for my $layer (qw(m a t)) {
    my $skel  = File::Spec->catfile(__this_dir(),'skel',"result.${layer}.gz");
    my $fsfile = Treex::PML::Factory->createDocumentFromFile($skel, {
      backends => [Backends()]
     });
    # update references
    for (values %{$fsfile->metaData('references')}) {
      my ($vol,$dir,$fn)=File::Spec->splitpath($_);
      if ($fn=~s/^result\./${basename}\./) {
	$_=File::Spec->catpath($vol,$dir,$fn);
      }
    }
    $fsfile->append_tree($_) for @{$results{$layer}};
    my $out = File::Spec->catfile($dir,"${basename}.${layer}.gz");
    print "Saving $out\n";
    $fsfile->writeFile($out);
  }

  if (GUI()) {
    Open(File::Spec->catfile($dir,"${basename}.t.gz"));
  }
}

}

=back

=head1 COPYRIGHT

Copyright (c) 2008 by Zdeněk Žabokrtský, Václav Klimeš, and Petr Pajas

=head1 LICENSE

You can use and distribute this program under the same terms as TrEd
itself.

=cut
