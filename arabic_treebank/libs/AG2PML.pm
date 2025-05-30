package AG2PML;

use Treex::PML;
use Treex::PML::Instance;
use Treex::PML::Schema;
use strict;
use XML::LibXML;
use XML::LibXML::XPathContext;
use File::Spec;
use 5.008;

=item open_backend (filename,mode)

Only reading is supported now!

=cut

sub open_backend {
  my ($filename, $mode, $encoding)=@_;
  return $filename;
}

=pod

=item close_backend (filehandle)

Close given filehandle opened by previous call to C<open_backend>

=cut

sub close_backend {
  my ($fh)=@_;
  return Treex::PML::IO::close_backend($fh) if ref($fh);
  return 1;
}

=pod

=item read (handle_ref,fsfile)

=cut

sub detransliterate {
  my ($decode)=@_;
  $decode=~s/\(null\)//g;
  eval {
    $decode =~ tr[,;?'|>&<}AbptvjHxd*rzs$SDTZEg_fqklmnhwYyFNKaui~o`{PJRVG0-9]
         [\x{060C}\x{061B}\x{061F}\x{0621}-\x{063A}\x{0640}-\x{0652}\x{0670}\x{0671}\x{067E}\x{0686}\x{0698}\x{06A4}\x{06AF}\x{0660}-\x{0669}]; #'
  };
  return $decode;
}

sub xp {
  my ($xpc,$node,$xp)=@_;
  return $xpc->findvalue($xp,$node);
}

sub ag_attr {
  my ($node,$name)=@_;
  $node->getAttributeNode($name)->getValue();
}

sub open_signal_file {
  my ($sigfile, $input)=@_;
  $input = File::Spec->rel2abs($input);
  my $abs  = URI->new($sigfile)->abs($input);
  unless ($abs->scheme) {
    $abs->scheme('file');
  }
  my $filename = $sigfile;
  if ($abs->scheme eq 'file') {
    my ($base_vol,$base_dir) = File::Spec->splitpath($input);
    my $base = File::Spec->catpath($base_vol,$base_dir);
    $filename = $abs->file;
    unless (-f $filename) {
      if ($filename=~m{/mnt/unagi/spd24/arabic-pos/UMAAH/sgm/processed/([^/]*)$} and -f File::Spec->catfile($base,'..','..','sgm',$1)) {
        $filename = File::Spec->catfile($base,'..','..','sgm',$1);
      } else {
        (undef,undef,$filename) = File::Spec->splitpath($filename);
        my $rel = File::Spec->catfile('sgm',$filename);
        for (0..2) {
          my $try = File::Spec->catfile($base,$rel);
          if (-f $try) {
            $filename = $try;
          }
          $rel = File::Spec->catfile('..',$rel);
        }
      }
      warn("Warning: xlink:href leads to a non-existing signal file, will try $filename\n")
        if $Treex::PML::Debug;
    }
  }
  return Treex::PML::IO::open_backend($filename,'r');
}

sub read_signal_file_tdf {
  my ($sigfile, $input, $encoding)=@_;
  $input = File::Spec->rel2abs($input);
  my $abs  = URI->new($sigfile)->abs($input);
  unless ($abs->scheme) {
    $abs->scheme('file');
  }
  my $filename = $sigfile;
  if ($abs->scheme eq 'file') {
    my ($base_vol,$base_dir) = File::Spec->splitpath($input);
    my $base = File::Spec->catpath($base_vol,$base_dir);
    $filename = $abs->file;
    (undef,undef,$filename) = File::Spec->splitpath($filename);
    my $rel = File::Spec->catfile('tdf',$filename);
    for (0..2) {
      my $try = File::Spec->catfile($base,$rel);
      if (-f $try) {
        $filename = $try;
      }
      $rel = File::Spec->catfile('..',$rel);
    }
  }
  my $fh = new IO::File();
  $fh->open($filename,'r') || return;
  eval {
    binmode($fh,":raw:perlio:encoding($encoding)");
  };
  warn $@ if $@;
  my @file_content = map { (split /\t/, $_)[7];  } grep {$_ !~ m/^;/} <$fh>;
  shift @file_content; # removing header
  return [@file_content];
}

sub fix_sgm_content {
  my $content = shift;
  $content =~ s/ id=(\d+)/ id="$1"/g; # apostrophize attribute id
  return $content;
}

sub get_signal {
  my ($sigfile, $input, $encoding)=@_;
  my $is_sgm_type;
  $is_sgm_type = ( $sigfile =~ m/\.sgm$/);
  if($is_sgm_type){
    my $parser = XML::LibXML->new();
    $parser->load_ext_dtd(1);
    $parser->validation(0);
    my $xpc = XML::LibXML::XPathContext->new();
    $xpc->registerNs(ag=>'http://www.ldc.upenn.edu/atlas/ag/');

    my $sigfh = open_signal_file($sigfile,$input, $encoding) or die "Can't open $sigfile. Aborting!\n"; 
    my $xml = "<?xml version='1.0' encoding='utf-8'?>\n".
                      "<!DOCTYPE DOC [\n".
                      "<!ENTITY HT ''>\n".
                      "<!ENTITY QC ''>\n".
                      "]>".fix_sgm_content(join("", <$sigfh>));
    my $sigdom = eval { $parser->parse_string($xml) };
    close ($sigfh);
    FIXING_LOOP:while (! $sigdom) {
      my $error_msg = $@;
      warn "Error parsing $sigfile ($error_msg). Trying to fix it !!!\n";
      if($error_msg =~ m/Entity '(.*?)' not defined/){
        my $entity=$1;
        $xml =~ s/(&$entity;)/'#'x(length($1))/eg;
        warn "$sigfile: Replacing '&$entity;' with '##".'#'x(length($entity))."'\n"
      } elsif($error_msg =~ m/xmlParseEntityRef: no name/) {
        $xml =~ s/&(\s)/#$1/g;
        warn "$sigfile: Replacing '&' with '#'\n"
      } else {
        last FIXING_LOOP;
      }
      $sigdom = eval { $parser->parse_string($xml) };
    }
    unless ($sigdom) {
      die "Error parsing $sigfile ($@). Aborting!\n";
    }
    my @paratxt=$xpc->findnodes( qq{ //*[name()='P'] | //seg }, $sigdom)->to_literal_list();
    return [map {s/^\n//;$_} @paratxt ];
  } else {
    return read_signal_file_tdf($sigfile,$input, $encoding);
  }
}


sub read {
  my ($input, $fsfile)=@_;
  die "Filename required, not a reference ($input)!" if ref($input);
  return unless ref($fsfile);

  my $parser = XML::LibXML->new();
  $parser->load_ext_dtd(1);
  $parser->validation(0);
  my $agdom = eval { $parser->parse_file($input); };
  unless ($agdom) {
    print STDERR "Error parsing ",$fsfile->filename(),". Aborting!\n";
    return 0;
  }
  $agdom->validate();

  my (undef,undef,$input_base) = File::Spec->splitpath($input);

  my $pml = <<"EOF";
<?xml version="1.0" encoding="utf-8"?>
<arabic_treebank xmlns="http://ufal.mff.cuni.cz/pdt/pml/">
 <head>
  <schema href="arabic_treebank_schema.xml"/>
 </head>
 <meta>
  <annotation_info>
   <desc>Automatically generated by AG2PML.pm from $input_base</desc>
  </annotation_info>
 </meta>
 <trees><LM id="fake"/></trees>
</arabic_treebank>
EOF

  my $output=$input; # $output=~s/\.xml$//; $output.='.pml';
  Treex::PML::Instance->load({string   => $pml,
             filename => $output,
             config   => $Treex::PML::Backend::PML::config
            })->convert_to_fsfile($fsfile);
  # $fsfile->changeBackend('PML');
  $fsfile->delete_tree(0);
  delete $fsfile->appData('id-hash')->{foo};

  my $xpc = XML::LibXML::XPathContext->new();
  $xpc->registerNs(ag=>'http://www.ldc.upenn.edu/atlas/ag/');

  my $sigfile = xp($xpc,$agdom, q{ string(//ag:Signal/@xlink:href) } );
  my $sigfile_encoding = xp($xpc,$agdom, q{ string(//ag:Signal/@encoding) } );
  my @signal = @{get_signal($sigfile,$input, $sigfile_encoding)};

  my %_id_hash = map { ag_attr($_,'id') => $_ }
    $xpc->findnodes(q{ //ag:Anchor|//ag:Annotation },$agdom);
  
  foreach my $ag ($xpc->findnodes(q{ //ag:AG },$agdom )) {
    my $agid=ag_attr($ag,'id');
    my $tree=xp($xpc,$ag,q{ string(descendant::ag:OtherMetadata[@name='treebanking']|
                              descendant::ag:MetadataElement[@name='treebanking']) });
    my $para=xp($xpc,$ag,q{ string(descendant::ag:OtherMetadata[@name='paragraph']|
                              descendant::ag:MetadataElement[@name='paragraph']) });
    my $comment=xp($xpc,$ag,q{ string(descendant::ag:OtherMetadata[@name='tbcomment']|
                                 descendant::ag:MetadataElement[@name='tbcomment']) });

    my $paratxt = @signal[$para-1];
    my @nodes;

    my $schema = $fsfile->metaData('schema');
    my ($root_type, $nonterminal_type, $terminal_type, $trace_type) =
      map { $schema->get_type_by_name($_)->get_content_decl }
      qw(root.type nonterminal.type terminal.type trace.type);
    my $tree_id=$agid; $tree_id=~tr[:][-];

    foreach my $annotation ($xpc->findnodes(q{ descendant::ag:Annotation[@type='word'] },$ag)) {
      my $start=ag_attr($_id_hash{ag_attr($annotation,'start')},'offset');
      my $end=ag_attr($_id_hash{ag_attr($annotation,'end')},'offset');

      $start=~s/\.(\d+)$//;
      $end=~s/\.(\d+)$//;
      my $token=substr($paratxt,$start,$end-$start);
      $token =~ s/\s+$//;
      my $id = ag_attr($annotation,'id'); $id=~tr[:][-];
      my $node=Treex::PML::Factory->createTypedNode($terminal_type,{
    '#name'=>'terminal',
    id=> $id,
    token => $token,
    lookup_word => xp($xpc,$annotation,q{ string(ag:Feature[@name='lookup-word']) }),
    comment => xp($xpc,$annotation,q{ string(ag:Feature[@name='comment']) }),
      },1);
      $node->{_start}=$start;
      $node->{_end}=$end;
      my $selection_id=xp($xpc,$annotation,q{ string(ag:Feature[@name='selection']) });
      my ($selection)=
    $xpc->findnodes(qq{ (id("$selection_id")|//ag:Annotation[\@id="$selection_id"])[1] },$annotation);
      if ($selection) {
    $node->{gloss}=xp($xpc,$selection,q{ string(ag:Feature[@name='gloss']) });
    my $solution=xp($xpc,$selection,q{ string(ag:Feature[@name='solution']) });
    my $lemmatag;
    ($node->{translit},$lemmatag)=($solution=~m{^\(([^)]+)\)\s+(.*)$});
    my @lemmatag=split /\+/,$lemmatag;
    $node->{lemma}=join '+', map { m{^(.*)/}; $1 } @lemmatag;
    $node->{morph}=join '+',map { m{^.*/(.*)}; $1 } @lemmatag;
      }
      if ($node->{translit} ne "") {
    $node->{form}=detransliterate($node->{translit});
      } else {
    $node->{form}=$node->{token};
      }
      push @nodes,$node;
    }
    @nodes = sort { $a->{_start} <=> $b->{_start} } @nodes;
    foreach my $i (0..$#nodes) {
      $nodes[$i]->{order}=$i;
    }

    my @nts;
    my $nt=0;
    my $trace=0;

    $_=$tree;
    s/^\(\s*Paragraph\s*//;
    s/\s*\)\s*$//;
    while(/
       \G \s*+ ( (?&WORD) | (?&BRACKETED) )
       (?(DEFINE)
          (?<WORD>      [^\(\)]+ )
          (?<BRACKETED> \s* \( (?&TEXT)? \s* \) )
          (?<TEXT>      (?: (?&WORD) | (?&BRACKETED) )+ )
       )
      /xg ){
      if ($1 =~ /^\s*[\d\*\A-Z]+\s*$/){
        $tree =~ s/(Paragraph\s*)(\(.*\))$/$1( PARAGRAPH $2 )/;
        print STDERR "$tree\n";
        warn("$tree_id: Terminal directly under paragraph -> adding PARAGRAPH root node\n");
        last;
      }
    }

    my $lastord;

    $tree=~s{ (?:(\d+)|(\*\S*))(?= )}{
      if ($1 ne "") {
    $lastord=$1;
    " $1"
      } else {
    $lastord+=0.01;
    " $lastord$2"
      }
    }eg;

    print "parsing preprocessed tree $agid:\n$tree\n\n" if $Treex::PML::Debug;
    my $origtree=$tree;
    my (%coref,%gapping);
    while ($tree =~ s{\( ([^()]+) \)}{nt$nt}) {
      my @children=split /\s+/,$1;
      my $cat=shift @children;
      my $node;
      if ($cat eq 'Paragraph') {
        $node=Treex::PML::Factory->createTypedNode($root_type,{
          id => $tree_id.'-s1',
          para_id => $tree_id,
          comment => $comment,
          para=>$para,
          sent_no => 1,
        },1);
      } else {
        my $id = $tree_id.'-nt'.$nt;
        $node=Treex::PML::Factory->createTypedNode($nonterminal_type,{
          '#name'=>'nonterminal',
          id => $id,
        },1);
        if ($cat=~s/=(\d+)$//) {
          if ($gapping{$1}) {
            $node->{'gapping.rf'}=$gapping{$1};
          }
          $gapping{$1}=$id;
        }
        if ($cat=~s/-(\d+)$//) {
          if ($coref{$1}) {
            $node->{'coref.rf'}=$coref{$1};
          }
          $coref{$1}=$id;
        }
        my @functions = split '-',$cat;
        $node->{cat}=shift @functions;
        $node->{functions}=Treex::PML::Factory->createList(\@functions,1);
      }
      foreach (reverse @children) { # reverse because paste_on pastes before first son
        my $child;
        if (/^nt(\d+)$/) {
          $child=$nts[$1];
        } elsif (/^(\d+)$/) {
          die "no word has index $_ in $agid:\n$origtree\n" if $_ >$#nodes;
          $child=$nodes[$_];
        } elsif (/^(\d+(?:\.\d+))(\*.*)$/) {
          my $type = $2;
          $type=~s/^\*\|\*$//g;
          $child=Treex::PML::Factory->createTypedNode($trace_type,{
            '#name'=>'trace',
            id => $tree_id.'-trace'.($trace++),
            type=>$type,
          });
        } else {
          die "unrecoginzed token $_! Aborting\n";
        }
        die "malformed tree?\n" unless ref($child);
        $child->paste_on($node);
      }
      $nts[$nt]=$node;
      $nt++;
    }
    my $root=pop @nts;
    if ($root) {
      $fsfile->insert_tree($root,$fsfile->lastTreeNo()+1);

      # split paragraph into several sentences:
      my @c = $root->children;
      if (@c > 1) {
        for my $i (1..$#c) {
          my $node=Treex::PML::Factory->createTypedNode($root_type,{
            id => $root->{id}.'-s'.($i+1),
            para=>$root->{para},
            para_id=>$root->{para_id},
            sent_no => $i+1,
          },1);
          $c[$i]->cut()->paste_on($node);
          $fsfile->insert_tree($node,$fsfile->lastTreeNo()+1);
        }
      }
    } else {
      warn "Failed to create a tree from $agid\n";
    }
  }
}


=item test (filehandle | filename, encoding?)

=cut

sub test {
  my ($f,$encoding)=@_;

  if (ref($f)) {
    my $line1=$f->getline();
    my $line2=$f->getline();
    return ($line1.$line2)=~/<!DOCTYPE AGSet/ ? 1 : 0;
  } else {
    my $fh = Treex::PML::IO::open_backend($f,"r");
    my $test = $fh && test($fh,$encoding);
    close_backend($fh);
    return $test;
  }
}

1;
