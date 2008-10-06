# -*- cperl -*-

package ValLex::GUI;

BEGIN { import TredMacro; }
use lib CallerDir('..');
use utf8;

use vars qw($ValencyLexicon $ChooserHideObsolete $frameid_attr
	    $framere_attr $lemma_attr $sempos_attr
            $vallexEditor $chooserDialog
	    $vallex_validate
	    $vallex_file
	  );

BEGIN {
$ValencyLexicon=undef;
$ChooserHideObsolete=1;
$frameid_attr="frameid";
$framere_attr="framere";
$lemma_attr="t_lemma";
$sempos_attr="g_wordclass";

$vallexEditor=undef;
$chooserDialog=undef;

$vallex_validate = 0;
$vallex_file = $ENV{VALLEX};
unless (defined($vallex_file) and length($vallex_file)) {
  # try to find vallex in libDir (old-way) or in resources (new-way)
  $vallex_file = ResolvePath(CallerDir()."/vallex.xml",'vallex.xml',1);
}
}

#$XMLDataClass="TrEd::ValLex::JHXMLData";
#$XMLDataClass="TrEd::ValLex::LibXMLData";

%sempos_map = (
  semn   => 'N',
  semv   => 'V',
  semadj => 'A',
  semadv => 'D',
  n   => 'N',
  v   => 'V',
  adj => 'A',
  adv => 'D'
 );

sub sempos {
  my ($sempos)=@_;
  if ($sempos=~/^((?:sem)?([vn]|adj|adv))/) {
    return $sempos_map{$1}
  }
  return undef;
}

sub init_XMLDataClass {
  unless (defined $XMLDataClass) {
    eval { require XML::JHXML; };
    if ($@) {
      print STDERR "Using LibXML\n" if $::tredDebug;
      eval { require XML::LibXML; };
      die $@ if $@;
      $XMLDataClass="TrEd::ValLex::ExtendedLibXML";
    } else {
      print STDERR "Using JHXML\n" if $::tredDebug;
      $XMLDataClass="TrEd::ValLex::ExtendedJHXML";
    }
  }
  require ValLex::Data;
  if ($XMLDataClass =~ /JHXML/) {
    require ValLex::ExtendedJHXML;
  } elsif ($XMLDataClass =~ /LibXML/) {
    require ValLex::ExtendedLibXML;
  }
}

sub init_VallexClasses {
  require ValLex::Widgets;
  require ValLex::Editor;
  require ValLex::Chooser;
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

sub close_ValencyLexicon {
  if ($chooserDialog) {
    $chooserDialog->destroy_dialog();
    undef $chooserDialog;
  }
  if ($vallexEditor) {
    $vallexEditor->destroy();
    undef $vallexEditor;
  }
  undef $ValencyLexicon;
}

sub init_ValencyLexicon {
  my $opts_ref = shift;
  my $top=ToplevelFrame();
  unless ($ValencyLexicon) {
    my $conv= TrEd::CPConvert->new("utf-8", 
				   $TrEd::Convert::support_unicode
				     ? "utf-8" : (($^O eq "MSWin32") ? "windows-1250" : "iso-8859-2"));
    my $info;
    eval {
      if ($^O eq "MSWin32") {
	$vallex_file =~ s{/}{\\}g;
	#### we may leave this commented out since it does not work correctly under windows
	#    my $info=InfoDialog($top,"First run, loading lexicon. Please, wait...");
      } else {
	$info=InfoDialog($top,"First run, loading lexicon $vallex_file. Please, wait...");
      }
      my $url = IOBackend::make_URI($vallex_file);
      my $file = ($url->scheme eq 'file') ? $url->file : "$url";
      $ValencyLexicon= $XMLDataClass->new($file,$conv,!$vallex_validate);
    };
    my $err=$@;
    $info->destroy() if $info;
    if ($err or !$ValencyLexicon->doc()) {
      print STDERR "$err\n";
      $top->Unbusy(-recurse=>1);
      ErrorMessage("Valency lexicon not found or corrupted.\nPlease, make sure that the following file is installed correctly: ${vallex_file}!\n\n$err\n");
      undef $vallex_file;
      return;
    } else {
      return $ValencyLexicon;
    }
  }
  %{$ValencyLexicon->user_cache}=() if defined($ValencyLexicon) and defined($ValencyLexicon->user_cache()); # clear cache
  return $ValencyLexicon;
}

sub Init {
  my $opts_ref = shift;
  $vallex_file = $opts_ref->{-vallex_file} if ($opts_ref->{-vallex_file} ne "");
  if ( $ValencyLexicon ) {
    my $current_file = $ValencyLexicon->file;
    if (File::Spec->rel2abs($current_file) eq File::Spec->rel2abs($vallex_file)) {
      return $ValencyLexicon;
    } else {
      close_ValencyLexicon();
    }
  }
  init_XMLDataClass();
  init_VallexClasses();
  return init_ValencyLexicon($opts_ref);
}

sub ShowFrames {
  if (@_ == 1 and UNIVERSAL::isa($_[0],'HASH')) {
    $opts_ref = shift
  } else {
    my %opts = @_;
    $opts_ref = \%opts;
  }
  my $msg;
  Init($opts_ref) or return;
  my $frames = exists $opts_ref->{-frameid} ?
    $opts_ref->{-frameid} : ($opts_ref->{-node} ? $opts_ref->{-node}->attr(($opts_ref->{-frameid_attr} || $frameid_attr)) : undef);
  my @frames;
  @frames = $ValencyLexicon->by_id(join " ",split /\|/,$frames);
  for my $f (@frames) {
    $word=$ValencyLexicon->getWordForFrame($f);
    unless (defined($msg)) {
      $msg = ["Lexicon word item:",[qw(label)],"  ".$ValencyLexicon->getLemma($word)."\n\n",[qw(lemma)]];
    }
    my ($frame, $id, $elements, $status, $example, $auth, $note) = @{$ValencyLexicon->getFrame($f)};
    push @$msg,
      $elements."\n\n",[qw(elements)],
	"Frame_ID:",[qw(label)],"  $id\n\n",[qw(id)],
	  "Examples:",[qw(label)],
	    "\n".$example."\n\n",[qw(example)],
	      ($note ne "" ? ("Note:",[qw(label)],"\n".$note."\n\n",[qw(note)]) : ()),
		"---------------------------------------\n\n",[];
  }
  main::textDialog($grp,
		   {
		     -title => 'Assigned valency frame(s)', -buttons => ['OK'] },
		   {
		     -text => 'Assigned valency frame(s)', -justify => 'left', -foreground => 'darkblue' },
		   undef,
		   { -readonly => 1,
		     -font => StandardTredValueLineFont(),
		     -width => 80, -height => 30,
		     -tags => {
		       elements => [-background => '#dddddd'],
		       label => [-underline => 1],
		       id => [-foreground => '#999999'],
		       lemma => [-foreground => 'darkblue'],
		       example => [-foreground => 'black'],
		       note => [-foreground => 'darkgreen']
		      }
		    },
		   $msg,
		   { dialog => [
		     ['<Escape>',sub { $_[0]->toplevel->{selected_button}= "Cancel" }]
		    ] });
  return 1;
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
  if ($vallexEditor) {
    return unless ref($vallexEditor);
    $vallexEditor->toplevel->deiconify;
    $vallexEditor->toplevel->focus;
    $vallexEditor->toplevel->raise;
  }
  $vallexEditor=1;
  my $top=ToplevelFrame();
#  $top->Busy(-recurse=>1);
  
  Init($opts_ref) or return;

  my $lemma=TrEd::Convert::encode(exists $opts_ref->{-lemma} ? 
				    $opts_ref->{-lemma} : $node ? $node->attr($lemma_attr) : undef);
  $lemma=~s/_/ /g;

  my $pos='V';
  if (exists($opts_ref->{-pos})) {
    $pos = $opts_ref->{-pos};
  } elsif (exists($opts_ref->{-sempos})) {
    $pos = sempos($opts_ref->{-sempos});
  } elsif ($node) {
    $pos = sempos($node->attr(($opts_ref->{-sempos_attr} || $sempos_attr)));
  }

  my $font = $main::font;
  my $fc=[-font => $font];

  my $fe_conf={ elements => $fc,
		example => $fc,
		note => $fc,
		problem => $fc
	      };
  my $vallex_conf = {
		     framelist => $fc,
		     framenote => $fc,
		     frameproblem => $fc,
		     wordlist => { wordlist => $fc, search => $fc},
		     wordnote => $fc,
		     wordproblem => $fc,
		     infoline => { label => $fc }
		    };

  my $frameid = $opts_ref->{-frameid} || ($node ? $node->attr(($opts_ref->{-frameid_attr} || $frameid_attr)) : undef);
  print STDERR "EDITOR start at: $lemma,$pos,$frameid\n";

  my $d;
  ($d,$vallexEditor)=
    TrEd::ValLex::Editor::new_dialog_window($top,
					    $ValencyLexicon,
					    [$lemma,$pos],    # select field
					    1,                # autosave
					    $vallex_conf,
					    $fc,
					    $fc,
					    $fe_conf,
					    $frameid,         # select frame
					    0,
					    $opts_ref->{-bindings}
					   );                 # start frame editor
  $d->bind('<Destroy>',sub { undef $vallexEditor; });
  TredMacro::register_exit_hook(sub {
				  if (ref($vallexEditor)) {
				    $vallexEditor->ask_save_data();
				  }
				});
  $d->Popup;
  return 1;
}

sub copy_verb_frame {
  my ($w,$group,$editor)=@_;
  print "copy_verb_frame $editor\n";
  my $top=$w->toplevel();
  my $data=$editor->data();

  my $wl=$editor->subwidget('wordlist')->widget();
  my $item=$wl->infoAnchor();
  print "item $item\n";
  return unless defined($item);
  my $word=$wl->infoData($item);
  return unless $word;
  my $target_lemma=$data->getLemma($word);
  my $target_pos=$data->getPOS($word);
  print "lemma $target_lemma\n";

  my $d=$top->Dialog(-title => 'Select source verb',
		     -buttons => ['OK','Cancel']);
  my $lexlist = TrEd::ValLex::WordList->new($data, undef, $d,
					    $editor->subwidget('wordlistitemstyle'),
					    qw/-height 10 -width 0/);
  $lexlist->set_pos_filter('V');
  $lexlist->pack(qw/-expand yes -fill both -padx 6 -pady 6/);
  $lexlist->fetch_data();
  $lexlist->widget()->focus();
  for (my $i=length($target_lemma); $i>0; $i--) {
    $lexlist->focus_by_text(substr($target_lemma,0,$i),undef,1) && last;
  }
  $d->bind('<Return>', \&TrEd::ValLex::Widget::dlgReturn );
  $d->bind('<KP_Enter>', \&TrEd::ValLex::Widget::dlgReturn );
  $d->bind($d,'<Escape>', [sub { shift; $_[0]->{selected_button}= "Cancel"; },$d] );
  $d->protocol('WM_DELETE_WINDOW' => [sub { shift->{selected_button}='Cancel'; },$d]);
  my $answer=$d->Show();
  if ($answer eq 'OK') {
    my $focused=$lexlist->focused_word();
    if (ref($focused)) {
      my ($lemma,$pos)= @$focused;
      print "lemma: $lemma, POS: $pos\n";
      my $verb=$data->findWordAndPOS($lemma,$pos);
      return unless $verb;
      my $new;
      foreach my $frame ($data->getFrameList($verb)) {
	next unless ($frame->[3] =~ /^active$|^reviewed$/);
	my $elements=$frame->[2];
	if ($target_pos eq 'N') {
	  $elements=~s/(ACT[\[\(])(1|[^\]\)]+,1)(\]|\)|,)/${1}p,2,7${3}/;
	  $elements=~s/(PAT[\[\(])(4|[^\]\)]+,4)(\]|\)|,)/${1}2${3}/;
	}
	$new=$data->addFrame(undef,$word,$elements,"($lemma.$pos)",$frame->[4],"",$data->user());
	print "$lemma: converting $frame->[2] => $elements\n";
      }
      if ($new) {
	$editor->subwidget('framelist')->fetch_data($word);
	$editor->wordlist_item_changed($editor->subwidget('wordlist')->focus($word));
	$editor->framelist_item_changed($editor->subwidget('framelist')->focus($new));
      }
    }
  }
  $lexlist->destroy();
  $d->destroy();
}

sub create_default_subst_frame {
  my ($d,$group,$editor)=@_;
  print "create_default_subst_frame $editor\n";
  my $data=$editor->data();
  my $wl=$editor->subwidget('wordlist')->widget();
  my $item=$wl->infoAnchor();
  print "item $item\n";
  return unless defined($item);
  my $word=$wl->infoData($item);
  print "word $word\n";
  return unless $word;
  my $pos=$data->getPOS($word);
  my $new=$data->addFrame(undef,$word,
			  ($pos eq 'V') ? 'ACT(1) PAT(4)' :
			  ($pos eq 'A') ? 'ACT(7) PAT(2)' : 'ACT(2,p,7) PAT(2)',
			  ,"","","",$data->user());
  print "new $new\n";
  $editor->subwidget('framelist')->fetch_data($word);
  $editor->wordlist_item_changed($editor->subwidget('wordlist')->focus($word));
  $editor->framelist_item_changed($editor->subwidget('framelist')->focus($new));
}

sub open_frame_instance_in_tred {
  my ($w,$group,$editor)=@_;
  my $top=$w->toplevel();
  my $win=$group->{focusedWindow};
  print "open_frame_instance_in_tred $editor\n";
  my $data=$editor->data();
  my $fl=$editor->subwidget('framelist')->widget();
  my $item=$fl->infoAnchor();
  return unless defined($item);
  my $frame=$fl->infoData($item);
  return unless ref($frame);
  my $example=$data->getFrameExample($frame);
  if ($example =~ /\{([^#}]*)(##?[0-9A-Z]+(?:\.[0-9]+)?)?\}/) {
    my $f=$1;
    my $suffix=$2;
    print "file: $f\n";
    my $fl=$win->{currentFilelist};
    return unless ref($fl);
    my $files=$fl->files_ref;
    my $i;
    for ($i=0; $i<=$#$files; $i++) {
      last if ($fl->file_at($i)=~/(?:^|\\|\/)([^\\\/]*)$/ and $1 eq $f);
    }
    if ($i<=$#$files) {
      print "index: $i\n";
      print "file: $files->[$i]\n";
      print "suffix: $suffix\n";
      print "win $win\n";
      $top->Busy(-recurse=>1);
      &main::gotoFile($group,$i,1,1);
      &main::applyFileSuffix($win,$suffix);
      &main::get_nodes_win($win);
      &main::redraw_win($win);
      &main::centerTo($win,$win->{currentNode});
      $top->Unbusy(-recurse=>1);
    }
  } else {
    print "no pointer in $example\n";
  }
}

sub parse_lemma {
  my ($trlemma,$lemma,$pos)=@_;
  my @components=split /_[\^,:;\']/,$lemma;
  my $pure_lemma=shift @components;
  my $deriv;
  foreach (@components) {
    if (/^\(.*\*(.*)\)/) {
      $deriv=$1;
      if ($deriv =~/^([0-9]+)(.*)$/) {
	$deriv=substr($pure_lemma,0,-$1).$2;
      }
      last;
    }
  }
  if ((($pos eq 'N' and $trlemma=~/[tn]í(?:$|\s)/) or
       ($pos eq 'A' and $trlemma=~/[tn]ý(?:$|\s)/)) 
      and $deriv=~/t$|ci$/) {
    $deriv=~s/-[0-9]+$//g;
    if ($trlemma=~/( s[ei])$/) {
      $deriv.=$1;
    }
  } else {
    $deriv=undef;
  }
  return ($pure_lemma,$deriv);
}

sub ChooseFrame {
  my $opts_ref;
  if (@_ == 1 and UNIVERSAL::isa($_[0],'HASH')) {
    $opts_ref = shift
  } else {
    my %opts = @_;
    $opts_ref = \%opts;
  }

  my $node = $opts_ref->{-node} || $this;
  if ($vallexEditor) {
    questionQuery("Sorry!","Valency editor already running.\n".
		  "To assign frames, you have to close it first.",
		  "Ok");
    return;
  }
  my $top=ToplevelFrame();
  $top->Busy(-recurse=>1);


  my $lemma=TrEd::Convert::encode(exists $opts_ref->{-lemma} ?
				    $opts_ref->{-lemma} : $node ? $node->attr(($opts_ref->{-lemma_attr} || $lemma_attr)) : undef);

  my $pos;
  if (exists($opts_ref->{-pos})) {
    $pos = $opts_ref->{-pos};
  } elsif (exists($opts_ref->{-sempos})) {
    $pos = sempos($opts_ref->{-sempos});
  } elsif ($node) {
    $pos = sempos($node->attr(($opts_ref->{-sempos_attr} || $sempos_attr)));
  }


  if ($lemma eq "") {
    $top->Unbusy(-recurse=>1);
    questionQuery("Sorry!","Can't determine t_lemma to use.", "Ok");
    return;
  }

  unless ($pos=~/^[NVAD]$/) {
    $top->Unbusy(-recurse=>1);
    questionQuery("Sorry!","Can't determine semantic POS.\n", "Ok");
    return;
  }
  $lemma=~s/_/ /g;


  Init($opts_ref) or return;
  my $field;
  my $new_word=0;
  my $word=$ValencyLexicon->findWordAndPOS($lemma,$pos);
  if (!exists($opts_ref->{-frameid}) and $node) {
    $opts_ref->{-frameid} = $node->attr(($opts_ref->{-frameid_attr} || $frameid_attr));
  }
  my ($l,$base);
  if ($opts_ref->{-morph_lemma}) {
    ($l,$base)=parse_lemma($lemma,TrEd::Convert::encode($opts_ref->{-morph_lemma}),
			   $opts_ref->{-morph_pos} || $pos);
  }
  my $base_word;
  $base_word=$ValencyLexicon->findWordAndPOS($base,"V") if (defined($base));
  if (!$word and $lemma ne lc($lemma)) {
    $lemma = lc($lemma);
    $word=$ValencyLexicon->findWordAndPOS($lemma,$pos);
    $base = lc($base);
    $base_word=$ValencyLexicon->findWordAndPOS($base,"V") if (defined($base));
  }
  $top->Unbusy(-recurse=>1);

  if ($opts_ref->{-no_assign} or !$ValencyLexicon->user_can_edit or $opts_ref->{-noadd}) {
    if (!$word) {
      ErrorMessage("The word $lemma.$pos was not found in the lexicon.\n");
      return;
    }
    $field=[ $word ? ($lemma,$pos) : () ];
  } else {
    if (!$word) {
      my $answer= questionQuery("Word not found",
				defined($base) && $base_word ?
				("The word $lemma.$pos was not found in the lexicon.\n",
				 "Add $lemma", "Use $base", "Cancel") :
				(!defined($base) ?
				("The word $lemma.$pos was not found in the lexicon.\n".
				 "Do you want to add it?","Add $lemma", "Cancel") :
				("Neither $lemma.$pos nor $base.V was found in the lexicon.\n".
				 "Do you want to add them?","Add $lemma",
				 "Add $base", "Add both", "Cancel")));

      if ($answer eq "Add $lemma") {
	$word=$ValencyLexicon->addWord($lemma,$pos);
	$new_word=[$lemma,$pos];
      } elsif ($answer eq "Add $base") {
	$base_word=$ValencyLexicon->addWord($base,"V");
	$new_word=[$base,"V"];
      } elsif ($answer eq "Add both") {
	$word=$ValencyLexicon->addWord($lemma,$pos);
	$base_word=$ValencyLexicon->addWord($base,"V");
	$new_word=[$lemma,$pos];
      } elsif ($answer eq "Cancel") {
	return;
      }
    }
    $field=[
	    $word ? ($lemma,$pos) : (),
	    $base_word ? ($base,"V") : ()
	   ];
  }
  #print "$word: $lemma $pos $opts_ref->{-frameid}\n";
  $opts_ref->{-title}=($opts_ref->{-title} || 'Valency frames');
  return DisplayFrame($field,$new_word,$opts_ref);
}

sub DisplayFrame {
  my ($field,$new_word,$opts_ref)=@_;

  my ($frame,$real);
  my $top=ToplevelFrame();
  if (ref($chooserDialog) and
      scalar(@{$chooserDialog->subwidget('framelists')}) !=
      scalar(@{$field}/2)) {
    $chooserDialog->destroy_dialog();
    undef $chooserDialog;
  }

  my $callback =
    (ref($opts_ref->{-no_assign}) ?
       [$opts_ref->{-no_assign}, $grp->{framegroup}] :
	 ((!$ValencyLexicon->user_is_annotator || $opts_ref->{-no_assign}) ? undef :
	    [\&frame_chosen, $grp->{framegroup},$opts_ref]));

  if (not ref($chooserDialog)) {
    my $font = $main::font;
    my $fc=[-font => $font];
    my $bfont;
    if (ref($font)) {
      $bfont = $font->Clone(-weight => 'bold');
    } else {
      $bfont=$font;
      $bfont=~s/-medium-/-bold-/;
    }
    my $fb=[-font => $bfont];
    my $fe_conf={ elements => $fc,
		  example => $fc,
		  note => $fc,
		  problem => $fc,
		  addword => $fc
		};
    my $vallex_conf = {
		       framelist => $fc,
		       framenote => $fc,
		       frameproblem => $fc,
		       wordlist => { wordlist => $fc, search => $fc},
		       wordnote => $fc,
		       wordproblem => $fc,
		       infoline => { label => $fc }
		      };

    my $chooser_conf = {
			framelists => $fc,
			framelist_labels => $fb,
		       };
    $chooserDialog=
      TrEd::ValLex::Chooser::create_toplevel($title,
					     $top,
					     $chooser_conf,
					     $fc,
					     $vallex_conf,
					     $fc,
					     $fc,
					     $fe_conf,
					     \$ChooserHideObsolete,
					     $ValencyLexicon,
					     $field,
					     [split /\|/, $opts_ref->{-frameid}],
					     $new_word,
					     $callback,
					     sub {
					       $chooserDialog->destroy_dialog();
					       undef $chooserDialog;
					     }
					    );
  } else {
    $chooserDialog->reuse($title,
			  \$ChooserHideObsolete,
			  $field,
			  [split /\|/, $opts_ref->{-frameid}],
			  $new_word,
			  $callback,
			  0);
  }
  return 1;
}

sub frame_chosen {
  my ($grp,$opts_ref,$chooser)=@_;


  return unless $grp and $grp->{focusedWindow};
  my $win = $grp->{focusedWindow};
  if ($win->{FSFile} and
      $win->{currentNode}) {
    my $field = $chooser->focused_framelist()->field();
    my $node = $win->{currentNode};
    #my $lemma = TrEd::Convert::encode($node->attr(($opts_ref->{-lemma_attr} || $lemma_attr))); 
    #my $pos = sempos($node->attr(($opts_ref->{-sempos_attr} || $sempos_attr)));
    my $lemma=TrEd::Convert::encode( ($node and ref($opts_ref) and defined($opts_ref->{-lemma_attr})) 
				       ? $node->attr($opts_ref->{-lemma_attr}) 
				       : $opts_ref->{-lemma});
    $lemma=~s/_/ /g;
    my $pos;
    if (ref $opts_ref and defined($opts_ref->{-sempos_attr})) {
      $pos = sempos($node->attr($opts_ref->{-sempos_attr}));
    } elsif (ref $opts_ref and exists($opts_ref->{-pos})) {
      $pos = $opts_ref->{-pos};
    } elsif (ref $opts_ref and exists($opts_ref->{-sempos})) {
      $pos = sempos($opts_ref->{-sempos});
    } elsif ($node) {
      $pos = sempos($node->attr($sempos_attr));
    }

    if (ref($field) and ($field->[0] eq $lemma or $field->[0] eq lc($lemma)) and
	$field->[1] eq $pos) {
      my @frames=$chooser->get_selected_frames();
      my $real=$chooser->get_selected_element_string();
      my $ids = $chooser->data->conv->decode(join("|",map { $_->getAttribute('id') } @frames));
      my $fmt  = $win->{FSFile}->FS();
      main::save_undo($win,main::prepare_undo($win,'Assign Valency Frame'));
      if (ref($opts_ref->{-assign_func})) {
	$opts_ref->{-assign_func}->($node,$ids,TrEd::Convert::decode($real),$win->{FSFile},$grp,$chooser,$opts_ref);
      } else {
	$node->set_attr(($opts_ref->{-frameid_attr} || $frameid_attr),$ids);
	$node->set_attr(($opts_ref->{-framere_attr} || $framere_attr),TrEd::Convert::decode($real)) if defined($opts_ref->{-framere_attr} || $framere_attr);
      }
      $chooser->widget->toplevel->withdraw() if $opts_ref->{-withdraw};
      $win->{framegroup}{top}->focus();
      $win->{framegroup}{top}->raise();
      $win->{FSFile}->notSaved(1);
      main::saveFileStateUpdate($win);
      main::onTreeChange($win);
    } else {
      $chooser->widget->toplevel->
	messageBox(-icon=> 'error',
		   -message=> "Can't assign frame for $field->[0].$field->[1] to $lemma.$pos",
		   -title=> 'Error', -type=> 'ok');

    }
  } else {
    $chooser->widget->toplevel->
      messageBox(-icon=> 'error',
		 -message=> "No node to assign selected frame $ids to!",
		 -title=> 'Error', -type=> 'ok');
  }
}

1;
