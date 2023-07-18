package TrEd::FramesPairs::FramesPairsData;

use strict;

sub new {
	my ($self, $file, $cpconvert, $novalidation)  = @_;
	my $class = ref($self) || $self;
	$cpconvert = TrEd::FramesPairs::DummyConv->new() unless ref($cpconvert); 
	my $new = bless [$class->parser_start($file, $novalidation), $file, 0, $cpconvert,undef,[]],$class; #parser, doc, file, changed, cpconvert, users,clients
	$new->loadListOfUsers();
	return $new;

}

sub parser_start {
  my ($self, $file, $novalidation)=@_;
  my $parser; 
  if ($^O eq 'MSWin32' and $XML::LibXML::VERSION lt '1.49') {
    $parser=XML::LibXML->new(
                             ext_ent_handler => sub {
                               my $f=$file;
                               $f=~s!([\\/])[^/\\]+$!$1!;
                               local *F;
                               print STDERR "Trying to open dtd at $f$_[0]\n";
                               open(F,"$f$_[0]") || print STDERR "failed to open dtd\n";
                               my @f=<F>;
                               close F;
                               return join "",@f;
                             }
                            );
  } else {
    $parser=XML::LibXML->new();
  }
  return () unless $parser;
  if (!$novalidation) {
    $parser->validation(1);
    $parser->load_ext_dtd(1);
    $parser->expand_entities(1);
  } else {
    $parser->validation(0);
    $parser->load_ext_dtd(0);
    $parser->expand_entities(0);
  }
  my $doc;
  print STDERR "parsing file $file\n";
  eval {
      $doc=$parser->parse_file($file);
  };
  print STDERR "$@\ndone\n";
  die "$@\n" if $@;
  $doc->indexElements() if ref($doc) and $doc->can('indexElements');
  
  return ($parser,$doc);
}

sub parser {
	return undef unless ref($_[0]);
	return $_[0]->[0];
}


sub doc {
	return undef unless ref($_[0]);
	return $_[0]->[1];
}

sub file {
	return undef unless ref($_[0]);
	return $_[0]->[2];
}

sub changed {
	return undef unless ref($_[0]);
	return $_[0]->[3];
}

sub conv {
	return undef unless ref($_[0]); 
	return $_[0]->[4];
}

sub compare {
	return $_[1] cmp $_[2];
}

sub clients {
	return undef unless ref($_[0]);
	return $_[0]->[6];
}

sub user {
	my ($self, $doc) = @_;
	return undef unless ref($doc); 
	my $root = $doc->getDocumentElement(); 
	return $root->getAttribute("owner");
}

sub set_parser {
	my ($self, $parser) = @_;
	return undef unless ref($self);
	$self->[0] = $parser;
}

sub set_doc {
	my ($self, $doc) = @_;
	return undef unless ref($self);
	$self->[1] = $doc;
}


sub get_frame_pair_by_en_cs_ids {
	my ($self, $doc, $evfid, $cvfid) = @_;
	return undef unless $doc;

	my $root = $doc->getDocumentElement();
	return undef if ($evfid !~ /^(.*)f(\d+.*)/);

	my $vw_id = $1;
	my ($framepair) = $root->findnodes('/frames_pairs/body/valency_word[@vw_id="'.$vw_id.'"]/en_frame[@en_id="'.$evfid.'"]/frame_pair[@cs_id="'.$cvfid.'"]');
	
	return $framepair;
}

sub generateNewVWId{
	my ($self, $doc, $body) = @_;
	return undef unless $doc;
	return undef unless $body;

	my $max_id = 0;
	foreach my $valency_word ($body->findnodes('valency_word')){
		my $id = $valency_word->getAttribute('id');
		$id =~ s/^vw//;
		$id =~ s/_.*$//;
		$max_id = $id if ($max_id < $id);
		}
	$max_id++;

	my $user=$self->user($doc);
	$user=~s/^v-//; 

	return "vw".${max_id}."_".$user;
}

sub generateEnFrameId{
	my ($self, $doc, $valency_word) = @_;
	return undef unless $doc;
	return undef unless $valency_word;

	my $max_id = 0;
	foreach my $en_frame ($valency_word->findnodes('en_frame')){
		my $id = $en_frame->getAttribute('id');
		return undef if ($id !~ /^(vw\d+.*)f(\d+.*)/);
		my $f_id = $2;
		$f_id =~ s/_.*$//;
		$max_id = $f_id if ($max_id < $f_id);
		}
	$max_id++;

	my $user=$self->user($doc);
	$user=~s/^v-//; 

	my $vw_id = $valency_word->getAttribute("id");
	return $vw_id."f".${max_id}."_".$user;
}

sub set_file {
	my ($self, $file) = @_;
	return undef unless ref($self);
	$self->[2] = $file;
}

sub set_change_status {
	my ($self, $status) = @_;
	return undef unless ref($self);
	$self->[3] = $status;
}

sub ask_save{
	my ($self, $win)=@_;
	return -1 unless ref($self);
	return 0 unless $self->changed();

	my $answer = "";
	if (defined $win){
		my $d = $win->toplevel->Dialog(
			-wraplength => 300,
			-bitmap => 'question',
			-title => "Saving file",
			-buttons => ['Yes', 'No']);
	$d->add('Label',-text => "File " . $self->file() . " may be changed!\n\n Do you want to save it?")->pack();

		$answer=$d->Show();
		}
	else{
			$answer = TredMacro::questionQuery("Saving file", "File". $self->file() . " may be changed!\n\nDo you want to save it?", "Yes", "No");
	}
	
	if ($answer eq 'Yes'){
		return $self->save();
	}
	else{
		return 0;
	}
}

sub save{
	my ($self, $no_backup)=@_;
	return unless ref($self);
	my $file=$self->file();
	my $backup=$file;
	if ($^O eq "MSWin32") {
		$backup=~s/(\.xml)?$/.bak/i;
	}
	else{
		$backup.="~";
	}

	unless ($no_backup || rename $file, $backup) {
		warn "Couldn't create backup file, aborting save!\n";
		return -1;
	}
	
	$self->doc()->toFile($file);
	$self->set_change_status(0);
	return 1;

}

sub ask_doc_reload{
	my ($self, $win)=@_;
	return -1 unless ref($self);
	return 0 unless $self->changed();

	my $answer = "";
	if (defined $win){
		my $d = $win->toplevel->Dialog(
			-wraplength => 300,
			-bitmap => 'question',
			-title => "Reloading file",
			-buttons => ['Yes', 'No']);
		$d->add('Label',-text => "File " . $self->file() . " may be changed!\n\n Do you want to reload it?")->pack();

		$answer=$d->Show();
	}
	else{
		$answer = TredMacro::questionQuery("Reloding file", "File". $self->file() . " may be changed!\n\nDo you want to reload it?", "Yes", "No");
	}

	if ($answer eq 'Yes'){
		return $self->doc_reload();
	}
	else{
		return 0;
	}
}

sub doc_reload {
	my ($self)=@_;
	my $parser = $self->parser();
	return undef unless $parser;
	$parser->load_ext_dtd(1);
	$parser->validation(0);
	print STDERR "parsing file ". $self->file . "\n";
	eval{
		my $doc=$parser->parse_file($self->file);
		$self->set_doc($doc);
	};
	print STDERR "$@\ndone\n";

	$self->set_change_status(0);

}

sub doc_free{
	my ($self) = @_;
	$self->make_clients_forget_data_pointers();
	$self->set_doc(undef);
}


sub reload{
	my ($self)=@_;
	$self->doc_free();
	$self->doc_reload();
	$self->loadListOfUsers();
	$self->set_change_status(0);
}

sub loadListOfUsers{
	my ($self)=@_;
	my $users={};
	return undef unless ref($self);
	my $doc=$self->doc();
	my ($head)=$doc->documentElement()->getChildElementsByTagName("head");
	if ($head){
		my ($list)=$head->getChildElementsByTagName("list_of_users");
		if($list) {
			foreach my $user ($list->getChildElementsByTagName("user")){
				$users->{$user->getAttribute("id")}=
					[
						$user->getAttribute("name"),
						$user->getAttribute("annotator") eq "YES",
						$user->getAttribute("reviewer") eq "YES"
					]
			}
		}
	}
	$self->[5]=$users;
	
}

sub get_user_info{
	my ($self, $user)=@_;
	return exists($self->[5]->{$user}) ? $self->[5]->{$user} : ["unknown user", 0, 0]; 
}

sub user_is_annotator{
	my ($self)=@_;
	return undef unless ref($self);
	return $self->get_user_info($self->user($self->doc))->[1];
}

sub user_is_reviewer{
	my ($self)=@_;
	return undef unless ref($self);
	return $self->get_user_info($self->user($self->doc))->[2];
}

sub getUserName{
	my ($self)=@_; 
	return undef unless ref($self); 
	return $self->conv->decode($self->get_user_info($self->user($self->doc))->[0]);
}

sub generateNewFPId{
	my ($self, $doc,$en_frame) = @_;
	return undef unless $doc;
	return undef unless $en_frame;

	my $max_id = 0;
	foreach my $framepair ($en_frame->findnodes('frame_pair')){ 
		my $id = $framepair->getAttribute('id');
		return undef if ($id !~ /^(vw\d+.*)f(\d+.*)p(\d+.*)/);
		my $p_id = $3;
		$p_id =~ s/_.*$//;
		$max_id = $p_id if ($max_id < $p_id);
		}
	$max_id++;

	my $user=$self->user($doc);
	$user=~s/^v-//; 

	my $f_id = $en_frame->getAttribute("id");
	return $f_id."p".${max_id}."_".$user; 

}
sub addValencyWord{
	my ($self, $doc, $body, $vw_id) = @_;

	my $valency_word = $doc->createElement("valency_word");
	my $new_id = $self->generateNewVWId($doc, $body);
	return unless defined($new_id);
	$body->appendChild($valency_word);
	$valency_word->setAttribute("id", $new_id);
	$valency_word->setAttribute("vw_id", $vw_id);
	return $valency_word;

}

sub addEnFrame{
	my ($self, $doc, $body, $vw_id, $evfid) = @_;

	my ($valency_word) = $body->findnodes('valency_word[@vw_id="'.$vw_id.'"]');
	if (not defined $valency_word){
		$valency_word = $self->addValencyWord($doc,$body, $vw_id);	
	}
	return unless $valency_word;

	my $en_frame = $doc->createElement("en_frame");
	my $new_id = $self->generateEnFrameId($doc,$valency_word);
	return unless defined($new_id);

	$valency_word->appendChild($en_frame);
	$en_frame->setAttribute("id", $new_id);
	$en_frame->setAttribute("en_id", $evfid);
	return $en_frame;

}


sub addFramePair {
	my ($self, $doc, $evfid, $cvfid) = @_;
	return undef unless $doc;
	
	my $framepair= $self->get_frame_pair_by_en_cs_ids($doc, $evfid,$cvfid);
	return $framepair if defined $framepair;
	
	if ($evfid !~ /^(.*)f(\d+.*)/){
		return undef;
	}
	
	my $vw_id = $1;
	my $f_id = $2;
	
	my $root = $doc->getDocumentElement();
	my ($body)=$root->getChildElementsByTagName("body");
	return unless $body;
	

	my ($en_frame) = $body->findnodes('valency_word[@vw_id="'.$vw_id.'"]/en_frame[@en_id="'.$evfid.'"]');
	if (not defined $en_frame){
		$en_frame = $self->addEnFrame($doc,$body,$vw_id, $evfid);
	}
	return unless $en_frame;
	
	my $new_id = $self->generateNewFPId($doc, $en_frame); 
	return unless defined($new_id);

	my $new_framepair = $doc->createElement("frame_pair");
	$new_framepair->setAttribute("id", $new_id);
	$new_framepair->setAttribute("status", "added");
	$new_framepair->setAttribute("cs_id", $cvfid);
	my $slots=$doc->createElement("slots");
	$new_framepair->appendChild($slots);

	$en_frame->appendChild($new_framepair);
	return $new_framepair;
}

sub getVWordNodeByID{
	my ($self, $id)=@_;
	my $doc=$self->doc();
	return unless $doc;
	#use locale;
	my $docel=$doc->getDocumentElement();
	my ($body)=$docel->getChildElementsByTagName("body");
	return unless $body;
		
	my ($vword) = $body->findnodes('valency_word[@vw_id="'.$id.'"]');
	return $vword;
}


sub getEnFrameNodes{
	my ($self, $vword)=@_;
	return unless ref($vword);
	return $vword->getChildElementsByTagName("en_frame");
}

sub getEnFrameList{
	my ($self,$vword)=@_;
	return unless $vword;
	return map {$self->getEnFrame($_) } $self->getEnFrameNodes($vword);
}

sub getEnFrame{
	my ($self,$enframe)=@_;

	my $id = $self->conv->decode($enframe->getAttribute("id"));
	my $en_id = $self->conv->decode($enframe->getAttribute("en_id"));
	return [$enframe,$id,$en_id];
}

sub getFramePair{
	my ($self, $en_id, $frame_pair)=@_;

	return unless $frame_pair;

	my $cs_id = $self->conv->decode($frame_pair->getAttribute("cs_id"));
	my ($slots)=$frame_pair->getChildElementsByTagName("slots");

	my $slot_list="";
	foreach my $slot ($slots->getChildElementsByTagName("slot")){
			$slot_list .= ", " if $slot_list ne "";
			$slot_list .= $self->conv->decode($slot->getAttribute("en_functor")) . "->" . $self->conv->decode($slot->getAttribute("cs_functor"));
		}
	
	#slots
	return [$frame_pair, $en_id, $cs_id, $slot_list];
}

sub getFramePairNodesByEnID{
	my ($self, $id)=@_;
	my $doc=$self->doc();
	return unless $doc;
	my $docel=$doc->getDocumentElement();
	my ($body)=$docel->getChildElementsByTagName("body");
	return unless $body;
		
	my ($en_frame) = $body->findnodes('valency_word/en_frame[@en_id="'.$id.'"]');
	return unless $en_frame;
	my @frames_pairs=$en_frame->getChildElementsByTagName("frame_pair");
	return @frames_pairs;

}

sub getFramePairNodesByCsID{
	my ($self, $id)=@_;
	my $doc=$self->doc();
	return unless $doc;
	my $docel=$doc->getDocumentElement();
	my ($body)=$docel->getChildElementsByTagName("body");
	return unless $body;
		
	my @frames_pairs=$body->findnodes('valency_word/en_frame/frame_pair[@cs_id="'.$id.'"]');
	return @frames_pairs;

}

sub getNormalFramePairsList{
	my ($self, $frame, $lang)=@_;
	return unless ($frame, $lang);
	my $id = $self->conv->decode($frame->getAttribute("id")); 
	if ($lang eq "en"){
		return map {$self->getFramePair($id, $_) } $self->getFramePairNodesByEnID($id);
	}
	elsif ($lang eq "cs"){
		return map {$self->getFramePair($_->getParentNode()->getAttribute("en_id"),$_) } $self->getFramePairNodesByCsID($id);
	}
	
	return;
}



sub register_client{
	my ($self,$client)=@_;
	my $clients=$self->clients();
	unless (grep {$_ == $client} @$clients) {
		push @$clients,$client;
	}
}

sub unregister_client{
	my ($self, $client)=@_;
	my $clients=$self->clients();
	@$clients=grep {$_ !=$client} @$clients;
}

sub make_clients_forget_data_pointers{
	my ($self,$client)=@_;
	my $clients=$self->clients();
	foreach my $client (@$clients){
		$client->forget_data_pointers();
	}
}
	
sub DESTROY{
	my ($self)=@_;
	$self->set_parser(undef);
	$self->make_clients_forget_data_pointers();
}	

package TrEd::FramesPairs::DataClient;

sub data {                                                                                                                                                                         
}                                                                                                                                                                                  

sub register_as_data_client {
  if ($_[0]->data()) {
	$_[0]->data()->register_client($_[0]);
  }
}

sub unregister_data_client {
  if ($_[0]->data()) {
    $_[0]->data()->unregister_client($_[0]);
  }
}

sub forget_data_pointers {
}

sub destroy {
  my ($self)=@_;
  $_[0]->unregister_data_client();
}

1;

