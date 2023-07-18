#
# FramesPairs views baseclass
#

package TrEd::FramesPairs::Widget;
#use locale;
use base qw(TrEd::FramesPairs::DataClient);
use Tk::BindButtons;

sub ShowDialog {
  my ($cw, $focus, $oldFocus)= @_;
  $oldFocus= $cw->focusCurrent unless $oldFocus;
  my $oldGrab= $cw->grabCurrent;
  my $grabStatus= $oldGrab->grabStatus if ($oldGrab);
  $cw->Popup();

  Tk::catch {
    $cw->grab;
  };
  $focus->focusForce if ($focus);
  Tk::DialogBox::Wait($cw);
  eval {
    $oldFocus->focusForce;
  };
  $cw->withdraw;
  $cw->grabRelease;
  if ($oldGrab) {
    if ($grabStatus eq 'global') {
      $oldGrab->grabGlobal;
    } else {
      $oldGrab->grab;
    }
  }
  return $cw->{selected_button};
}

sub dlgReturn {
  my ($w,$no_default)=@_;
  my $f=$w->focusCurrent;
  if ($f and $f->isa('Tk::Button')) {
    $f->Invoke();
  } elsif (!$no_default) {
    $w->toplevel->{default_button}->Invoke
      if $w->toplevel->{default_button};
  }
  Tk->break;
}

sub new {
  my ($self, $data, $field, @widget_options)= @_;
  $class = ref($self) || $self;
  my $new = bless [$data,$field],$class;
  $new->register_as_data_client();
  my @new= $new->create_widget($data,$field,@widget_options);
  push @$new,@new;
  return $new;
}

sub data {
  my ($self)=@_;
  return undef unless ref($self);
  return $self->[0];
}

sub field {
  my ($self)=@_;
  return undef unless ref($self);
  return $self->[1];
}

sub widget {
  my ($self)=@_;
  return undef unless ref($self);
  return $self->[2];
}

sub pack {
  my $self=shift;
  return undef unless ref($self);
  return $self->widget()->pack(@_);
}

sub configure {
  my $self=shift;
  return undef unless ref($self);
  return $self->widget()->configure(@_);
}

#
# FramesPairs views baseclass for component widgets
#

package TrEd::FramesPairs::FramedWidget;
use base qw(TrEd::FramesPairs::Widget);

sub frame {
  my ($self)=@_; 
  return undef unless ref($self); 
  return $self->[3]->{frame};
}

sub subwidget {
 my ($self,$sub)=@_;
  return undef unless ref($self) and ref($self->[3]);
  return $self->[3]->{$sub};
}

sub pack {
  my $self=shift; 
  return undef unless ref($self); 
  return $self->frame()->pack(@_);
}

sub configure {
  my $self=shift;
  return undef unless ref($self);
  return $self->widget()->configure(@_);
}

sub subwidget_configure {
  my ($self,$conf)=@_;
  foreach (keys(%$conf)) {
    my $subw=$self->subwidget($_);
    next unless $subw;
    foreach my $sub (ref($subw) eq 'ARRAY' ? @$subw : ($subw)) {
      if ($sub->isa("TrEd::FramesPairs::FramedWidget") and
	  ref($conf->{$_}) eq "HASH") {
	$sub->subwidget_configure($conf->{$_});
      } elsif(ref($conf->{$_}) eq "ARRAY") {
	$sub->configure(@{$conf->{$_}});
      } else {
	print STDERR "bad configuration options $conf->{$_}\n";
      }
    }
  }
}

#
# FramePairsMapping widget
#

package TrEd::FramesPairs::FramesPairsMapping;
use base qw(TrEd::FramesPairs::Widget);

require Tk::Tree;
require Tk::HList;
require Tk::ItemStyle;

sub UpDown { 
  my ($tree,$dir) = @_;
  my $anchor = $tree->info('anchor');
  unless(defined $anchor) {
    $anchor = 
      $dir eq 'next' ? 
	($tree->info('children'))[0] :
	(reverse $tree->info('children'))[0];
    if (defined $anchor) {
      $tree->selectionClear;
      $tree->anchorSet($anchor);
      $tree->see($anchor);
      $tree->selectionSet($anchor);
    }
  } else {
    $tree->UpDown($dir);
  }
}

sub create_widget { 
  my ($self, $data, $field, $top, $common_style, $vallex_en_data, $vallex_cs_data, $lang, @conf) = @_;
  my $w = $top->Scrolled(qw/Tree -columns 1
                              -indent 15
                              -drawbranch 1
                              -background white
                              -selectmode browse
                              -header 1
                              -relief sunken
                              -scrollbars osoe/,
			  );
  for ($w->Subwidget('scrolled')) {
     $w->bind('Tk::Tree','<Up>', [\&UpDown,'prev'] );
     $w->bind('Tk::Tree','<Down>', [\&UpDown,'next'] );
  }

  $w->configure(-opencmd => [\&open_superframe,$w],
		-closecmd => [\&close_superframe,$w]);
  $w->configure(@conf) if (@conf);
  $common_style=[] unless (ref($common_style) eq "ARRAY");
  $w->BindMouseWheelVert() if $w->can('BindMouseWheelVert');
  $w->headerCreate(0,-itemtype=>'text', -text=>'Mappping', -underline => 0);
  $top->toplevel->bind('<Alt-e>',sub { $w->focus() });
  return $w, {
	      reviewed => $w->ItemStyle("imagetext", -foreground => 'black',
					-background => 'white', @$common_style),
	      active => $w->ItemStyle("imagetext", -foreground => 'black',
				      -background => 'white', @$common_style)
	     },{
		reviewed => $w->Pixmap(-file => Tk::findINC("TrEd/EngValLex/ok.xpm")),
		active => $w->Pixmap(-file => Tk::findINC("TrEd/EngValLex/filenew.xpm"))
	       },0,0,1,$vallex_en_data, $vallex_cs_data,$lang;
}

sub style {
  return $_[0]->[3]->{$_[1]};
}

sub pixmap {
  return $_[0]->[4]->{$_[1]};
}

sub lang {
	return $_[0]->[10];
}
 
sub lang_2{
	my ($self)=@_;
	return "en" if ($self->lang() eq "cs");
	return "cs" if ($self->lang() eq "en");
}

sub vallex_data {
	my ($self,$lang)=@_; 
	return $_[0]->[8] if ($lang eq "en");
	return $_[0]->[9] if ($lang eq "cs");
}


sub forget_data_pointers {
  my ($self)=@_;
  my $t=$self->widget();
  if ($t) {
    $t->delete('all');
  }
}

sub fetch_data {
	my ($self, $frame)=@_;
  	my $t=$self->widget();
  	$t->delete('all');
	return unless $frame;
  	my ($e,$f,$i);
  	my $style;
  	my $vallex_data_2=$self->vallex_data($self->lang_2());

    foreach my $entry ($self->data()->getNormalFramePairsList($frame, $self->lang())) {
      $e = $t->addchild("",-data => $entry->[0]);
	  my $frame_2=$vallex_data_2->doc()->findnodes(
		  	'valency_lexicon/body/word/valency_frames/frame[@id="'.
			($self->lang() eq "en" ? $entry->[2] : $entry->[1]).'"]')->[0];
	  my $lemma = (defined $frame_2 ? $vallex_data_2->getLemma($vallex_data_2->getWordForFrame($frame_2)) : "");
      $i=$t->itemCreate($e, 0,
			-itemtype=>'imagetext',
			-text=> $lemma . " (" . ($self->lang() eq "en" ? $entry->[2] : $entry->[1]).")\n\t".$entry->[3]);

    }
  $t->autosetmode();
}


sub focus_by_ID {
	my ($self, $id) = @_; 
	my $h=$self->widget();
	foreach my $t ($h->infoChildren()) {
		if ($h->itemCget($t,0,'-text') =~ /($id)/){
			$h->anchorSet($t);
			$h->see($t);
			return $t;
		}
	}
	return undef;
}


#
#FrameList widget
#

package TrEd::FramesPairs::FrameList;
use base qw(TrEd::FramesPairs::FramedWidget);

require Tk::Tree;
require Tk::HList;
require Tk::ItemStyle;

sub create_widget{
	my ($self, $data, $field, $top, $item_style, $vallex_en_data, $vallex_cs_data,$lang, @conf) = @_;

	my $w = $top->Scrolled(qw/HList -columns 1
								  -background white
								  -selectmode browse
								  -header 1
								  -relief sunken
								  -scrollbars osoe/)->pack(qw/-side top -expand yes -fill both/);
	for ($w->Subwidget('scrolled')){
		$_->bind($_,'<ButtonRelease-1>', sub { Tk->break });
		$_->bind(ref($_),'<ButtonRelease-1>',sub { Tk->break } );
	}

	$item_style = [] unless(ref($item_style) eq "ARRAY");
	my $itemStyle = $w->ItemStyle("text", 
						-foreground => 'black', 	
						-background => 'white',
						@{$item_style});

	return ($w, {frame => $w}, $itemStyle,$vallex_en_data, $vallex_cs_data,$lang);
}

sub style { $_[0]->[1]; }
sub lang { $_[0]->[7]; }

sub vallex_data {
	my ($self)=@_; 
	return $_[0]->[5] if ($self->lang() eq "en");
	return $_[0]->[6] if ($self->lang() eq "cs");
}

sub forget_data_pointers {
  my ($self)=@_;
  my $t=$self->widget();
  if ($t) {
    $t->delete('all');
  }
}

sub fetch_data {
  my ($self, $word)=@_; 
  my $t=$self->widget();
  my ($e,$f,$i);
  my $style;
  $t->delete('all');

  $t->headerCreate(0,-itemtype=>'text', -text=>'Frame ID');
  $t->columnWidth(0,'');
  return unless ref($word);

  foreach my $entry ($self->vallex_data()->getFrameList($word)){
	$e=$t->addchild("", -data=>$entry->[0]); 
	$t->itemCreate($e, 0, -itemtype=>'text',
			-text=>$entry->[1],
			-style=>$self->style());
  }
} 

sub focus_by_ID {
	my ($self, $id) = @_; 
	my $h=$self->widget();
	foreach my $t ($h->infoChildren()) {
		if ($h->itemCget($t,0,'-text') eq $id){
			$h->anchorSet($t);
			$h->see($t);
			return $t;
		}
	}
	return undef;
}

#
# WordList widget
#

package TrEd::FramesPairs::WordList;
use base qw(TrEd::FramesPairs::FramedWidget);

require Tk::HList;
require Tk::ItemStyle;

sub create_widget {
  my ($self, $data, $field, $top, $item_style, $vallex_en_data, $vallex_cs_data, $lang, @conf) = @_;

  my $frame = $top->Frame(-takefocus => 0);
  my $ef = $frame->Frame(-takefocus => 0)->pack(qw/-pady 5 -side top -fill x/);
  my $l = $ef->Label(-text => "Search: ",-underline => 3)->pack(qw/-side left/);
  my $e = $ef->Entry(qw/-background white -validate key/,
		     -validatecommand => [\&quick_search,$self]
		    )->pack(qw/-expand yes -fill x/);
  $top->toplevel->bind('<Alt-r>',sub { print STDERR "Alt-r\n"; $e->focus() });

  ## Word List
  my $w = $frame->Scrolled(qw/HList -columns 1 -background white
                              -selectmode browse
                              -scrollbars osoe
                              -header 1
                              -relief sunken/)->pack(qw/-side top -expand yes -fill both/);
  for ($w->Subwidget('scrolled')) {
    $_->bind($_,'<ButtonRelease-1>',sub { Tk->break });
    $_->bind(ref($_),'<ButtonRelease-1>',sub { Tk->break });
##    $_->bind(ref($_),'<ButtonRelease-1>',sub { Tk->break; });
     $_->bind($_,'<Double-1>',
	     [sub {
	       my ($h,$self)=@_;
#	       my $h=$self->subwidget('wordlist')->widget();
	       my $word=$h->infoData($h->infoAnchor()) if ($h->infoAnchor());
		   $self->fetch_words($word); 
	       $self->focus($word);
	       Tk->break;
	     },$self]);
   }
  $e->bind('<Return>',[
			  sub {
			    my ($cw,$w,$self)=@_;
			    $self->quick_search($cw->get);
			    $w->Callback(-browsecmd => $w->infoAnchor());
			    Tk->break;
			  },$w,$self
			 ]);
  $e->bind('<Down>',[$w,'UpDown', 'next']);
		 # $e->bind('<Up>',[$w,'UpDown', 'prev']);


  $w->configure(@conf) if (@conf);
  $w->BindMouseWheelVert() if $w->can('BindMouseWheelVert');
  $item_style = [] unless(ref($item_style) eq "ARRAY");
  my $itemStyle = $w->ItemStyle("text",
				-foreground => 'black',
				-background => 'white',
				@{$item_style});
  return (
	  $w,
	  {
	   frame => $frame,
	   wordlist => $w,
	   search => $e,
	   label => $l
	  },
	  $itemStyle,   # style
	  50,           # max_surrounding
	  $vallex_en_data,
	  $vallex_cs_data,
	  $lang
  	);
}

sub style { $_[0]->[4]; }
sub max_surrounding { $_[0]->[5] };
sub lang { $_[0]->[8]; }

sub vallex_data {
	my ($self)=@_; 
	return $_[0]->[6] if ($self->lang() eq "en");
	return $_[0]->[7] if ($self->lang() eq "cs");
}

sub quick_search {
  my ($self,$value)=@_; 
  return defined($self->focus_by_text($value,undef));
}

sub forget_data_pointers {
  my ($self)=@_;
  my $t=$self->widget();
  if ($t) {
    $t->delete('all');
  }
}

sub fetch_words {
	my ($self, $word)=@_;
	my $t=$self->widget(); 
	my $e;
	$t->delete('all');
	$t->headerCreate(0,-itemtype=>'text', -text=>'Word lemma');
	$t->columnWidth(0,''); 
	foreach my $entry ($self->vallex_data()->getWordSubList($word,$self->max_surrounding(), "V")){
		$e=$t->addchild("", -data=>$entry->[0]); 
		$t->itemCreate($e, 0, -itemtype=>'text',
				-text=>$entry->[2],
				-style=>$self->style());
	}
}

sub focus_by_text {
  my ($self,$text,$caseinsensitive)=@_;
  my $h=$self->widget();
#  use locale;
  for my $i (0,1) {
    # 1st run tries to find it in current list; if it fails
    # 2nd run asks Data server for more data
    $self->fetch_words($text) if $i; 
    foreach my $t ($h->infoChildren()) {
      if ((!$caseinsensitive and index($h->itemCget($t,0,'-text'),$text)==0 or
	  $caseinsensitive and index(lc($h->itemCget($t,0,'-text')),lc($text))==0)) {
	$h->anchorSet($t);
	$h->selectionClear();
	$h->selectionSet($t);
	$h->see($t);
	return $t;
      }
    }
  }
  return undef;
}

sub focus_index {
  my ($self,$idx)=@_;
  my $h=$self->widget();
  if ($h->infoExists($idx)) {
    $h->anchorSet($idx);
    $h->selectionClear();
    $h->selectionSet($idx);
    $h->see($idx);
  }
  return $t;
}

sub focus {
  my ($self,$word)=@_;
  return unless ref($word);
  my $h=$self->widget();
  for my $i (0,1) {
    # 1st run tries to find it in current list; if it fails
    # 2nd run asks Data server for more data
    $self->fetch_words($word) if $i;
    foreach my $t ($h->infoChildren()) {
      if ($self->vallex_data()->isEqual($h->infoData($t),$word)) {
	$h->anchorSet($t);
	$h->selectionClear();
	$h->selectionSet($t);
	$h->see($t);
	return $t;
      }
    }
  }
  return undef;
}

sub focused_word {
  my ($self)=@_;
  my $h=$self->widget();
  my $t=$h->infoAnchor();
  if (defined($t)) {
    return [$h->itemCget($t,2,'-text'),$h->itemCget($t,1,'-text')]
  }
  return undef;
}

1;
