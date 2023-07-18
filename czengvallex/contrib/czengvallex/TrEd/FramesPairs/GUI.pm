# -*- cperl -*-

package TrEd::FramesPairs::GUI;
BEGIN { import TredMacro; }
use lib CallerDir('..');
use utf8;
use Scalar::Util qw(blessed);

use vars qw($FramesPairs $frameid_attr
            $lemma_attr 
			$framesPairsEditor 
			$framesPairs_validate $framesPairs_file);

BEGIN
{
	$FramesPairs=undef;
	$frameid_attr="frameid";
	$lemma_attr="t_lemma";

	$framesPairsEditor=undef;

	$framesPairs_validate = 0;
	$framesPairs_file = $ENV{FRAMESPAIRS};
	unless (defined($framesPairs_file) and length($framesPairs_file)) {
		$framesPairs_file = FindInResources('frames_pairs.xml');
	}
}

sub init_FramesPairsClasses {
  require XML::LibXML;
  require TrEd::FramesPairs::FramesPairsData;
  require TrEd::FramesPairs::ExtendedLibXML;
  require TrEd::FramesPairs::Widgets;
  require TrEd::FramesPairs::Editor;
  require TrEd::CPConvert;
}

sub InfoDialog {
  my ($top,$text)=@_;

  my $t=$top->Toplevel();
  my $f=$t->Frame(qw/-relief raised -borderwidth 3/)->pack();
  my $l=$f->Label(-text => $text,
		  -font => StandardTredFont(),
		  -wraplength => 200
		 )->pack();
  $t->overrideredirect(1);
  $t->Popup();
  $top->idletasks();
  return $t;

}

sub close_FramesPairs {
  if (ref $framesPairsEditor) {
    $framesPairsEditor->destroy();
    undef $framesPairsEditor;
  }
  undef $FramesPairs;
}

sub init_FramesPairs {
  my $opts_ref = shift;
  my $top=ToplevelFrame();
  unless ($FramesPairs) {
    my $conv= TrEd::CPConvert->new("utf-8", 
				   $TrEd::Convert::support_unicode
				     ? "utf-8" : (($^O eq "MSWin32") ? "windows-1250" : "iso-8859-2"));
    my $info; 
    eval {
      if ($^O eq "MSWin32") {
	$framesPairs_file =~ s{/}{\\}g unless (ref($framesPairs_file) or $framesPairs_file=~m{^[[:alpha:]][[:alnum:]]+://});
	#### we may leave this commented out since it does not work correctly under windows
	#    my $info=InfoDialog($top,"First run, loading lexicon. Please, wait...");
      } else {
	$info=InfoDialog($top,"First run, loading file $framesPairs_file. Please, wait...");
      }
      my $url = Treex::PML::IO::make_URI($framesPairs_file);
      my $file = ($url->scheme eq 'file') ? $url->file : "$url";
      $FramesPairs= TrEd::FramesPairs::FramesPairsData->new($file,$conv,!$framesPairs_validate);
    };
    my $err=$@; 
    $info->destroy() if $info;
    if ($err or !$FramesPairs->doc()) {
      print STDERR "$err\n";
      $top->Unbusy(-recurse=>1);
      ErrorMessage("File frames_pairs not found or corrupted.\nPlease, make sure that the following file is installed correctly: ${framesPairs_file}!\n\n$err\n");
	  undef $framesPairs_file;
      return;
    } else {
      return $FramesPairs;
    }
  }
  %{$FramesPairs->user_cache}=() if defined($FramesPairs) and defined($FramesPairs->user_cache()); # clear cache
  return $FramesPairs;
}

sub _is_same_filename {
  my ($f1,$f2)=@_;
  return 1 if $f1 eq $f2;
  my $u1 = (blessed($f1) and $f1->isa('URI')) ? $f1 : Treex::PML::IO::make_URI($f1);
  my $u2 = (blessed($f2) and $f2->isa('URI')) ? $f2 : Treex::PML::IO::make_URI($f2);
  return 1 if $u1 eq $u2;
  return 1 if $u1->canonical eq $u2->canonical;
  if (!ref($f1) and !ref($f2) and $^O ne 'MSWin32' and -f $f1 and -f $f2) {
    return _is_same_file($f1,$f2);
  }
  return 0;
}

sub _is_same_file {
  my ($f1,$f2) = @_;
  return 1 if $f1 eq $f2;
  my ($d1,$i1)=stat($f1);
  my ($d2,$i2)=stat($f2);
  return ($d1==$d2 and $i1!=0 and $i1==$i2) ? 1 : 0;
}

sub Init {
  my $opts_ref = shift;
  $framesPairs_file = $opts_ref->{-framesPairs_file} if ($opts_ref->{-framesPairs_file} ne "");
  if ( $FramesPairs ) {
    my $current_file = $FramesPairs->file;
    if (_is_same_filename($current_file) eq _is_same_filename($framesPairs_file)) {
      return $FramesPairs;
    } else {
      close_FramesPairs();
    }
  }
  init_FramesPairsClasses();
  return init_FramesPairs($opts_ref);
}

sub OpenEditor {
  my $opts_ref;
  if (@_ == 1 and UNIVERSAL::isa($_[0],'HASH')) {
    $opts_ref = shift
  } else {
    my %opts = @_;
    $opts_ref = \%opts;
  }
  my $node = $opts_ref->{-node} || $this;
  my $lang = $opts_ref->{-lang}; 
  if ($framesPairsEditor) {
    return unless ref($framesPairsEditor);
    $framesPairsEditor->toplevel->deiconify;
    $framesPairsEditor->toplevel->focus;
    $framesPairsEditor->toplevel->raise;
  }
  $framesPairsEditor=1;
  my $top=ToplevelFrame();
#  $top->Busy(-recurse=>1);
  
  Init($opts_ref) or return;

  my $lemma=TrEd::Convert::encode(exists $opts_ref->{-lemma} ? 
				    $opts_ref->{-lemma} : $node ? $node->attr($lemma_attr) : undef);

  my $en_frame = $opts_ref->{-en_frame};
  print STDERR "OPENING EDITOR: en_frame = '$en_frame'\n" if $::tredDebug;

  my $cs_frame = $opts_ref->{-cs_frame};
  
  $opts_ref->{-vallex_file} = $opts_ref->{-vallex_en_file};
  TrEd::EngValLex::GUI::Init($opts_ref) or return;

  my $opts_ref->{-vallex_file} = $opts_ref->{-vallex_cs_file};
  ValLex::GUI::Init($opts_ref) or return;

  my $font = $main::font;
  my $fc=[-font => $font];

  my $fe_conf={ elements => $fc
			};

  my $frames_pairs_conf = {
  			wordlist => { wordlist => $fc, search => $fc},
			framelist => $fc, 
			frames_pairs => $fc, 
			infoline => { label => $fc}
  };

  print STDERR "EDITOR start at: $en_frame,$cs_frame\n" if $::tredDebug;

  my $d;
  ($d,$framesPairsEditor)=
    TrEd::FramesPairs::Editor::new_dialog_window($top,
					    $FramesPairs,
						$TrEd::EngValLex::GUI::ValencyLexicon,
						$ValLex::GUI::ValencyLexicon,
						$lemma,
					    1,                # autosave
						$frames_pairs_conf,
						$fc,
						$fc,
						$fc,
						$fe_conf,
					    $en_frame,         # select frame
					    $cs_frame,         # select frame
						$lang,
					    $opts_ref->{-bindings}
					   );                 # start frame editor
  $d->bind('<Destroy>',sub { undef $framesPairsEditor; });
  TredMacro::register_exit_hook(sub {
				  if (ref($framesPairsEditor)) {
				    $framesPairsEditor->ask_save_data();
				  }
				});
  $d->Popup;
  return 1;
}



1;

