
# FramesPairs Editor widget (the main component)
#

package TrEd::FramesPairs::Editor;
use strict;
use base qw(TrEd::FramesPairs::FramedWidget);
use vars qw($reviewer_can_delete $reviewer_can_modify $display_problems $LINK_DELIMITER);

require Tk::LabFrame;
require Tk::DialogBox;
require Tk::Adjuster;
require Tk::Dialog;
require Tk::Checkbutton;
require Tk::Button;
require Tk::Optionmenu;
require Tk::NoteBook;

sub limit { 100 }

#qw();
$LINK_DELIMITER = "::";

# Color of buttons whose functionality is not implemented yet.
my $COLOR_NOT_IMPLEMENTED = "#888";

#my @bold   = (-foreground=>'#C00000');
#my @selected = (-background => '#C9D8E3', qw/-relief raised -borderwidth 1/);
#my @normal = (-background => undef, qw/-relief flat/);

sub new_dialog_window {
  my ($top,$data,$vallex_en_data,$vallex_cs_data,
	  $selected_lemma,$autosave,$confs,
	  $wordlist_item_style,
	  $framelist_item_style,
	  $frames_pairs_item_style,
	  $fe_confs,
      $en_frame,
      $cs_frame,
	  $lang,
      $bindings
     )=@_;

  my $can_edit = $data->user_is_annotator() or $data->user_is_reviewer(); 
  my $d = $top->Toplevel(-title => "FramesPairs viewer: ".
			 $data->getUserName($data->user($data->doc))
			);
  $d->withdraw;

  $d->bind('all','<Tab>',[sub { shift->focusNext; }]);
  $d->bind($d,'<Return>',[sub {  }]);
  $d->bind($d,'<KP_Enter>',[sub {  }]);
  my $button_frame=$d->Frame()->pack(qw(-fill x -side bottom));
  my $frames_pairs= TrEd::FramesPairs::Editor->new($data, $data->doc() ,$d,0,
	  				$vallex_en_data,
					$vallex_cs_data,
					$wordlist_item_style,
					$framelist_item_style,
					$frames_pairs_item_style,
					$fe_confs, 
					$en_frame,
					$cs_frame,
					$lang);

  $frames_pairs->subwidget_configure($confs) if ($confs);   
  $frames_pairs->pack(qw/-expand 1 -fill both -side top/);

  $frames_pairs->wordlist_item_changed($frames_pairs->subwidget('wordlist')->focus_by_text($selected_lemma,1));
  $frames_pairs->framelist_item_changed($frames_pairs->subwidget('framelist')->focus_by_ID($lang eq "en" ? $en_frame : $cs_frame));
  $frames_pairs->subwidget('framespairslist')->focus_by_ID($lang eq "en" ? $cs_frame : $en_frame);
  $d->Frame(qw/-height 3 -borderwidth 2 -relief sunken/)->
    pack(qw(-fill x -side top -pady 6));
  
    $button_frame->Frame()->pack(qw(-expand 1 -fill x -side left))->
      Button(-text => 'Close',
	     -underline => 2,
	     -command =>
	       [sub {
		  my ($d,$f,$top)=@_;
		  $frames_pairs->destroy();
		  undef $frames_pairs;
		  $d->destroy();
		  undef $d;
		},$d,$frames_pairs,$top]
	      )->pack(qw(-padx 10 -expand 1));
    $d->bind('all','<Escape>'=> [sub { shift; shift->{selected_button}='Close'; },$d ]);
  
	$button_frame->BindButtons;
    $d->protocol('WM_DELETE_WINDOW' =>
		   [$d,'destroy']);
  
  if (ref($bindings)) {
    while (my ($event, $command) = each %$bindings) {
      if (ref($command) eq 'ARRAY') {
	$d->bind($event, [@$command,$frames_pairs]);
      } else {
	$d->bind($event, [$command,$frames_pairs]);
      }
    }
  }

  return ($d,$frames_pairs);
}

#-------------------------------------------------------------------------------
sub create_widget {
  my ($self, $data, 
	  $field, $top, $reverse,
	  $vallex_en_data, $vallex_cs_data,
      $wordlist_item_style,
      $framelist_item_style,
      $frames_pairs_item_style,
      $fe_confs,
	  $en_frame,
	  $cs_frame,
  	  $lang)= @_;
  my $framespair;

  $framespair = $top->Frame(-takefocus => 0);

  my $top_framespair= $framespair->Frame(-takefocus => 0)->pack(qw/-expand yes -fill both -side top/);

  # Labeled frames

  my $wf = $top_framespair->Frame(-takefocus => 0);


  my $lexlist_frame=$wf->LabFrame(-takefocus => 0,-label => "Words",
				  -labelside => "acrosstop", 
				     qw/-relief raised/);
  $lexlist_frame->pack(qw/-expand yes -fill both -padx 4 -pady 4/);


  my $ff = $top_framespair->Frame(-takefocus => 0);
  my $framelist_frame=$ff->LabFrame(-takefocus => 0, -label => "Frames",
	  				-labelside => "acrosstop",
					qw/-relief raised/);
  $framelist_frame->pack(qw/-expand yes -fill both -padx 4 -pady 4/);

  my $fpf = $top_framespair->Frame(-takefocus => 0);
  
  my $framesPairs_frame = $fpf->LabFrame(-takefocus => 0, -label => "FramesPairs",
  					-labelside => "acrosstop",
					qw/-relief raised/);
  $framesPairs_frame->pack(qw/-expand yes -fill both -padx 4 -pady 4/);

  my $adjuster = $top_framespair->Adjuster();

  ## Word List
  my $lexlist = TrEd::FramesPairs::WordList->new($data, undef, $lexlist_frame,
					    $wordlist_item_style, $vallex_en_data, $vallex_cs_data,$lang,
					    qw/-height 10 -width 0/);
  $lexlist->pack(qw/-expand yes -fill both -padx 6 -pady 6/);



  $lexlist->configure(-browsecmd => [
				     \&wordlist_item_changed,
				     $self
				    ]);

  $lexlist->fetch_words("");

    if ($reverse) {
      $wf->pack(qw/-side right -fill both -expand yes/);
      $adjuster->packAfter($wf, -side => 'right');
      $ff->pack(qw/-side right -fill both -expand yes/);
      $fpf->pack(qw/-side right -fill both -expand yes/);
    } else {
      $wf->pack(qw/-side left -fill both -expand yes/);
      $adjuster->packAfter($wf, -side => 'left');
      $ff->pack(qw/-side left -fill both -expand yes/);
      $fpf->pack(qw/-side left -fill both -expand yes/);
    }

	 $lexlist->subwidget('search')->focus;

  # List of Frames
  my $framelist =
    TrEd::FramesPairs::FrameList->new($data, undef, $framelist_frame,
				 $framelist_item_style, $vallex_en_data, $vallex_cs_data, $lang,
				 qw/-height 10 -width 20/);


  $framelist->pack(qw/-expand yes -fill both -padx 6 -pady 6/);

  $framelist->configure(-browsecmd => [
				     \&framelist_item_changed,
				     $self
				    ]);

  # FramesPairs Mapping
  my $framespairslist =
  	TrEd::FramesPairs::FramesPairsMapping->new($data, undef, $framesPairs_frame,
				$frames_pairs_item_style, $vallex_en_data, $vallex_cs_data,$lang,
				qw/-height 10 -width 80/);
  $framespairslist->pack(qw/-expand yes -fill both -padx 6 -pady 6/);

  # Bind buttons
  $framespair->BindButtons;

  return $lexlist->widget(),{
	     frame       => $framespair,
	     top_framespair    => $top_framespair,
	     word_frame   => $lexlist_frame,
	     frame_frame  => $framelist_frame,
	     framespairslist    => $framespairslist,
	     wordlist     => $lexlist,
	     framelist     => $framelist,
	     wordlistitemstyle  => $wordlist_item_style,
		 framelistitemstyle => $framelist_item_style,
             search_params => ['',0,0],
	    },$fe_confs;
}

sub destroy {
  my ($self)=@_;
  $self->subwidget("framespairslist")->destroy();
  $self->subwidget("wordlist")->destroy();
  $self->subwidget("framelist")->destroy();
  $self->SUPER::destroy();
}

sub reload_data {
  my ($self,$top)=@_;
  $top->Busy(-recurse=> 1);
  my $field=$self->subwidget("wordlist")->focused_word();
  $self->data()->reload();
  if ($field) {
    my $word=$self->vallex_data()->findWordAndPOS(@{$field});
    $self->wordlist_item_changed($self->subwidget("wordlist")->focus($word));

  } else {
    $self->subwidget("wordlist")->fetch_words("");
  }
  $top->Unbusy(-recurse=> 1);
}

sub ask_save_data {
  my ($self,$top)=@_;
  return 0 unless ref($self);
  my $d=$self->widget()->toplevel->Dialog(-text=>
					"Valency lexicon changed!\nDo you want to save it?",
					-bitmap=> 'question',
					-title=> 'Question',
					-buttons=> ['Yes','No']);
  $d->bind('<Return>', \&TrEd::FramesPairs::Widget::dlgReturn);
  $d->bind('<KP_Enter>', \&TrEd::FramesPairs::Widget::dlgReturn);
  my $answer=$d->Show();
  if ($answer eq 'Yes') {
    $self->save_data($top);
    return 0;
  } elsif ($answer eq 'Keep') {
    return 1;
  }
}

sub save_data {
  my ($self,$top)=@_;
  my $top=$top || $self->widget->toplevel;
  $top->Busy(-recurse=> 1);
  $self->data()->save();
  $top->Unbusy(-recurse=> 1);
}

sub fetch_words {
  my ($self,$word)=@_;
  $self->subwidget("wordlist")->fetch_words($word);
  $self->wordlist_item_changed();
}

sub fetch_frames {
	my ($self, $word)=@_;
  	$self->subwidget('framelist')->fetch_data($word);
    $self->framelist_item_changed();
}
sub wordlist_item_changed {
  my ($self,$item)=@_;

  my $h=$self->subwidget('wordlist')->widget();
  my $word;

  $word=$h->infoData($item) if ($h->infoExists($item)); 

  $self->subwidget('wordlist')->focus_index($item);
  $self->fetch_frames($word);
  
}

sub framelist_item_changed {
  my ($self,$item)=@_;
  my $h=$self->subwidget('framelist')->widget();
  my $frame;
  my $e;
  $frame=$h->infoData($item) if defined($item);
  $frame=undef unless ref($frame);
  
  $self->subwidget('framespairslist')->fetch_data($frame);
  
}

sub quick_search {
  my ($self,$value)=@_;
  return defined($self->focus_by_text($value));
}


sub focus_by_text {
	my ($self,$text,$caseinsensitive)=@_;
  my $h=$self->subwidget('framespair')->widget();
#  use locale;
  my $st = $h->infoAnchor();
  my ($t) = ($st eq "") ? $h->infoChildren("") : $st;
  while ($t ne "") {
    my $item=$h->itemCget($t,0,'-text');
    if (!$caseinsensitive and index($item,$text)>=0 or
	$caseinsensitive and index(lc($item),lc($text))>=0) {
      $h->anchorSet($t);
      $h->selectionClear();
      $h->selectionSet($t);
      $h->see($t);
      return $t;
    }
    $t=$h->infoNext($t);
    last if $t eq $st;
    ($t) = $h->infoChildren("") if ($t eq "" and $st);
    last if $t eq $st;
  }
  return undef;
}

1;
