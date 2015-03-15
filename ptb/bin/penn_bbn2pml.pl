#!/usr/bin/env perl
# penn2pml.pl     pajas@ufal.mff.cuni.cz     2009/08/27 09:00:07

our $VERSION="0.2";

use Scalar::Util qw(weaken);
use warnings;
use strict;
$|=1;

use open ':std' => 'utf8';

use File::Spec;
use FindBin;
use Getopt::Long;
use Pod::Usage;
use Mojo::DOM;
use Storable;
use Digest::MD5 qw(md5_hex);

my ($sentence_fail_counter, $sentence_total_counter);

Getopt::Long::Configure ("bundling");
my %opts = (
  'base-schema' => 'pennmrg_schema.xml',
  'output-dir' => '.',
  'encoding' => 'UTF-8',
  'bbn-data' => File::Spec->catdir($FindBin::Bin, 'data'),
);
GetOptions(\%opts,
#   'debug|D',
    'encoding|e=s',
    'output-dir|o=s',
    'bbn-data|d=s',
    'generate-schema|g=s',
    'nonbracketed-terminals|B',
    'bracketed-terminals|b',
    'base-schema|s=s',
    'quiet|q',
    'help|h',
    'usage|u',
    'version|V',
    'man',
) or $opts{usage}=1;

if ($opts{help}) {
  pod2usage(-exitstatus => 0, -verbose => 99, -sections => '.*');
  exit;
}
if ($opts{man}) {
  pod2usage(-exitstatus => 0, -verbose => 2);
  exit;
}
if ($opts{version}) {
  print "$VERSION\n";
  exit;
}
if ($opts{usage} or !@ARGV) {
  pod2usage(-msg => 'penn2pml.pl');
  exit;
}

sub trim($) {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

sub escape($) {
  my $val = shift;
  $val =~ s/&/&amp;/g; $val =~ s/</&lt;/g; $val =~ s/"/&quot;/g;
  return $val;
}

sub pennform2form($) {
  my $form = shift;
  for ($form) {
    s/-LRB-/(/ or s/-RRB-/)/ or s/-LSB-/[/ or
    s/-RSB-/]/ or s/-LCB-/{/ or s/-RCB-/}/ or
    s%\\/%/%g
  }
  return $form;
} # pennform2form

sub match_terminals {
  my ($mwes, $bbn_sentence, $terminals, $sentence_id) = @_;

  my @sentence = @$bbn_sentence;
  my @terms = @$terminals;
  my $mwe_count;
  while (my $token = shift @sentence) {
    my $form = ref $token ? $token->[0] : $token;
    my $content = $form; $content =~ s/\s+//g;
    my $stem;
    my @ids;
    my $match = 0;
    my $skip = 0;
    TERMINAL:
    while (my $terminal = shift @terms) {
      push @ids, $terminal->[0];
      $stem .= $terminal->[1];
      if ($stem eq $content) {
        if (ref $token && not $skip) {
          $mwe_count++;
          push @{$mwes->{-children}}, {
            -name => 'LM',
            -attributes => { id => "$sentence_id-mwe$mwe_count" },
            -children => [
              { -name => 'form', -content => $form },
              { -name => 'name', -content => $token->[1] },
              { -name => 'type', -content => $token->[2] },
              ( $token->[3] ? ({ -name => 'subtype', -content => $token->[3] }) : ()),
              { -name => 'terminal.rfs', -children => [
                map { { -name => 'LM', -content => $_ } } @ids
              ]}
            ]
          };
        }
        $match = 1;
        last TERMINAL;
      }

      while (length($stem) > length($content) && @sentence) {
        $token = shift @sentence;
        $content .= ref $token ? $token->[0] : $token;
        $content =~ s/\s+//g;

        if ($stem eq $content) {
          $skip = 1;
          last TERMINAL
        }
      }
    }
    unless ($match || $skip) {
      warn "Sentence $sentence_id didn't match BBN tokens";
      $sentence_fail_counter++;
      last;
    }
  }

   
  # unless (@terms == 0 && @sentence == 0) {
  #   use Data::Dumper;
  #   print STDERR Dumper($bbn_sentence);
  #   print STDERR Dumper(\@sentence);
  #   print STDERR Dumper($terminals);
  #   print STDERR Dumper(\@terms);
  # }
}

# opening the schema output file first, so that errors are reported
# before the files are processed (which can take some time)
my ($schema_out_fh,%postag_values, %function_values, %cat_values);
if ($opts{'generate-schema'}) {
  open $schema_out_fh, '>', $opts{'generate-schema'}
    or die "Cannot write schema to $opts{'generate-schema'}";
}

my $nonbracketed_terminals = $opts{'nonbracketed-terminals'};
my $bracketed_terminals = $opts{'bracketed-terminals'};

my @files = @ARGV;
if ($^O eq 'MSWin32') {
    @files = map { -r $_ ? $_ : glob ($_) } @ARGV;
}

my @bbn;
@bbn = grep { -r $_ } glob($opts{'bbn-data'}) if $opts{'bbn-data'};

die 'BNN data not found!' unless @bbn;

my %bbn_documents = ();
my $cache_filename = '.' . md5_hex(sort @bbn);
if (-r $cache_filename) {
  %bbn_documents = %{retrieve($cache_filename)};
  # print join ', ', sort keys %bbn_documents;
  # exit;
} else {
  foreach my $file (@bbn) {
    open(my $F, '<', $file) or warn "Cannot open $file for reading";
    binmode($F,":raw:perlio:encoding($opts{encoding})");

    my $doc; my $sentence_no = 0;
    while (my $line=<$F>) {
      next unless $line =~ /^(\s+|<DOCNO>)/;
      if ($line =~ m{<DOCNO> (.+) </DOCNO>}) {
        $doc = lc $1;
        $bbn_documents{$doc} = {};
        $sentence_no = 0;
        next;
      }
      $line =~ s/^\s+//;
      my @sentence;
      $sentence_no += 1;

      my $dom = Mojo::DOM->new($line);
      my $key;
      for (@{$dom->tree}) {
        next unless ref $_;
        my $t = $_->[0];
        my $content;
        if ($t eq 'tag') {
          my $kind = lc $_->[1];
          my $type = lc $_->[2]->{type};
          #print STDERR "$type\n";
          $type =~ s/^([^:]+):?(\w+)?$/$1/;
          my $subtype = $2;
          #print STDERR $subtype||'' . "\n";

          $content = pop @$_;
          $content = escape(trim($content->[1]));

          push @sentence, [$content, $kind, $type, $subtype];
          $key .= $content;
        } elsif ($t eq 'text') {
          $content = escape(trim($_->[1]));
          next unless $content;
          push @sentence, $content;
          $key .= $content;
        }
      }
      $key =~ s/\s+//g;
      $key = md5_hex($key);
      #push @{$bbn_documents{$doc}}, \@sentence;
      $bbn_documents{$doc}->{$key} = \@sentence;
    }
    close $F;
  }

  store \%bbn_documents, $cache_filename;
}

foreach my $file (@files){
  my ($S,$T);
  if ($file=~/\.gz$/) {
    require IO::Uncompress::Gunzip;
    $S = IO::Uncompress::Gunzip->new($file, AutoClose => 1);
  } else {
    open($S, '<', $file) or undef $S;
  }
  unless (defined $S) {
    warn "Cannot open $file for reading";
    next;
  }
  binmode($S,":raw:perlio:encoding($opts{encoding})");
  my (undef,undef,$basename) = File::Spec->splitpath($file);
  $basename=~s/\.gz$//;

  my $out = $basename.'.pml';
  $out = File::Spec->rel2abs($out, $opts{'output-dir'});

  open($T,">:utf8", $out) or do {
    warn "Cannot open $file for writing";
    next;
  };
  my $schema = $opts{'generate-schema'} || $opts{'base-schema'};
  print $T <<"HEADER";
<?xml version="1.0" encoding="UTF-8"?>
<pennmrg xmlns="http://ufal.mff.cuni.cz/pdt/pml/">
 <head>
  <schema href="$schema" />
 </head>
 <meta>
  <annotation_info>
   <desc>Converted from PTB 3.0 mrg file and merged with BBN</desc>
  </annotation_info>
 </meta>
 <trees>
HEADER

  my $input;
  while (my $line=<$S>) {
    chomp $line;
    $line=~s/\r//g;
    next if ($line=~/^\s*\</); # skip SGML/XML markup (e.g. in Chinese Treebank files)
    next if ($line=~/^\*/);    # skip UPenn copyright comments
    next if ($line=~/^\( @[^)]*\)\s*$/); # skip Penn Atis IDs (or what)
    next if ($line=~/^\( END_OF_TEXT_UNIT \)$/); # skip Penn Atis eot marks
    if ($line=~/^\(/) { $line = "\n".$line }
    $input.=$line;
  }
  $input =~ s/[ \t]+/ /g;
  $input =~ s/^\s+//; # specifically, trim the leading new-line
  $input =~ s/ $//;
  $input =~ s/([\(\)]) /$1/g;
  $input =~ s/ ([\(\)])/$1/g;
  $input = escape($input);
  my $sentence_count;
  my $base_id = $basename; $base_id=~s/\.mrg$//;
  my $doc_name = $base_id; $doc_name =~ s/_//;
  my $doc = $bbn_documents{$doc_name};
  warn "Can't find related BBN document for $doc_name" unless $doc;
  foreach my $sentence (split /\n/,$input) {
    $sentence_total_counter++;
    my ($terminal_count, $nonterminal_count, $order)=(0,0,0);
    $sentence_count++;
    $sentence =~ s/^\(   (\(.+\)) \)$/$1/x;
    my $sentence_id = "$base_id-s$sentence_count";
    my $sentence_pointer = 0;
    my @terminals;
    my $bbn_sentence;

    # print "$sentence\n";
    # print "$doc\n";

    # in order to be able to compute coindexes and intersentential
    # gapping, we first buffer the nodes and then serialize them to
    # XML
    my $root = {
      -name => 'LM',
      -attributes => { id=>$sentence_id },
    };
    my $mwes = {
      -name => 'mwes',
      -children => [],
    };
    my $tree = {
      -name => 'tree',
      -up => undef,
      -children => [],
    };
    $root->{-children} = [ $mwes, $tree ];
    my $parent = $tree;
    my (@coindex,%target_id);
    while ($sentence) {
      # terminal
      if ( (not($nonbracketed_terminals) and
        # case (VB find)
          $sentence=~s{
                ^\(                      # (
                                ((?:[^\ ()\\]|\\.)+) # POS
                                (\ )                 # <space>
                                ((?:[^\\()/]|\\.)+)  # WORD
                              \)                     # )
              }{}x)
      or
        # alternative format: find/VB
        not($bracketed_terminals) and
      $sentence=~s{^(?:\s|\+)*
             (?:
               # WORD                   /   POS
               ((?:[^\ ()/\\+]|\\.)+)  (/)  ((?:[^\ ()\\+]|\\.)+)
               |
           # e.g. *T*
           (\*(?:[^\ ()/\\+]|\\.)+)
         )
       }{}x
     ) {
    my ($tag,$pennform) = $4 ? ('', $4) : ($2 eq '/') ? ($3,$1) : ($1,$3);
    my $form = pennform2form($pennform);
    $terminal_count++;
    my $terminal_id = "$sentence_id-t$terminal_count";
    my $coindex;
    if ($pennform =~ s{\*[-](\d+)$}{*}) {
      $coindex = {
        -name => 'coindex.rf',
        -content => $1,
      };
      push @coindex, $coindex;
    }
    my $node = {
      -name => 'terminal',
      -attributes => { id => $terminal_id },
      -children => [
        { -name => 'form', -content=>$form },
        (defined($tag) ? { -name => 'pos', -content=>$tag } : ()),
        (($pennform=~m/^\*/) ? () : { -name => 'order', -content=>$order++ }),
        ($coindex ? $coindex : ()),
       ],
      };

    push @terminals, [$terminal_id, $pennform] unless $coindex || $pennform=~m/^\*/ || $pennform eq '0';
    $postag_values{$tag}=undef if $opts{'generate-schema'};
    push @{$parent->{-children}}, $node;
      }

      # nonterminal opening bracket
      elsif ($sentence=~s/^\(([^ ()]+)//) {
    my $cat = $1;
    $nonterminal_count++;
    my $nonterminal_id = "$sentence_id-n$nonterminal_count";
    my $role = "";
    my $coindex = "";
    my $node = {
      -name => 'nonterminal',
      -attributes => { id => $nonterminal_id },
      -children => [
       ],
    };
    push @{$parent->{-children}}, $node;
    if ($cat =~ s/-(\d+)//) {
      if (exists $target_id{$1}) {
        warn "Node $nonterminal_id with cat $cat has coindex $1, also found at $target_id{$1}\n";
      } else {
        $target_id{$1}=$nonterminal_id;
      }
    }
    if ($cat =~ s/=(\d+)//) {
      my $coindex = {
             -name => 'coindex.rf',
             -content => $1,
            };
      push @coindex, $coindex;
      push @{$node->{-children}}, $coindex;
    }
    if ($cat =~ s/\-(.*)//) {
      my @functions = grep {!/^\d+$/} split /-/,$1;
      @function_values{@functions}=() if $opts{'generate-schema'};
      push @{$node->{-children}}, {
        -name => 'functions',
        -children => [ map { { -name=>'LM', -content=> $_ } } @functions ],
      };
    }
    my $children = { -name => 'children', -children => [], -up => $parent };
    weaken($children->{-up});
    my @cats = split /\|/,$cat;
    if ($opts{'generate-schema'}) {
      $cat_values{$_}=undef for @cats;
    }
    push @{$node->{-children}}, {
      -name => 'cat',
      (@cats>1) ? (-children => [
        map { { -name=>'AM', -content=> $_ } } @cats,
      ] ) : (-content => $cat)
     }, $children;
    $parent = $children;
      }

      # nonterminal closing bracket
      elsif ($sentence=~s/^\)//) {
    $parent = $parent->{-up};
      }

      # parse error
      else {
    die "$sentence_id: No reduction:\n'$sentence'\n";
      }
    }

    # translate coindex numbers to PMLREFs
    my %unreferenced = %target_id;
    for my $coindex (@coindex) {
      my $target = $target_id{ $coindex->{-content} };
      if (defined($target) and length($target))  {
    delete $unreferenced{ $coindex->{-content} };
    $coindex->{-content} = $target;
      } else {
    warn "$sentence_id: Didn't find coindexed node: $coindex->{-content}\n";
    $coindex->{-content} = 'unknown-'.$coindex->{-content};
      }
    }
    unless ($opts{quiet}) {
      foreach (keys %unreferenced) {
    warn "$sentence_id: Didn't find any reference to coindex $_ ($unreferenced{$_})\n";
      }
    }

    if ($doc) {
      my $key = join '', map { $_->[1] } @terminals;
      $key =~ s/\s+//g;
      $key = md5_hex($key);
      $bbn_sentence = $doc->{$key};
      unless ($bbn_sentence) {
        $sentence_fail_counter++;
        warn "Cannot find sentence $sentence_count ($key) in $doc_name";
      }      
    } else {
      $sentence_fail_counter++;
    }

    match_terminals($mwes, $bbn_sentence, \@terminals, $sentence_id) if $bbn_sentence;

    # dump the tree
    print $T serialize_xml_element($root,2), "\n";
  }

  print $T <<'FOOTER';
  </trees>
</pennmrg>
FOOTER

  close $T;
}

if ($schema_out_fh) {
  my $postag_values = join "\n",map qq{      <value>$_</value>}, sort keys %postag_values;
  my $cat_values = join "\n",map qq{      <value>$_</value>}, sort keys %cat_values;
  my $function_values = join "\n",map qq{      <value>$_</value>}, sort keys %function_values;
  print $schema_out_fh <<"EOF"
<?xml version="1.0" encoding="utf-8"?>
<pml_schema xmlns="http://ufal.mff.cuni.cz/pdt/pml/schema/" version="1.1">
  <description>Generated schema for converted MRG PTB Data</description>
  <import schema="$opts{'base-schema'}"/>

  <type name="postag.type">
    <choice>
$postag_values
    </choice>
  </type>
  <type name="cat.type">
    <choice>
$cat_values
    </choice>
  </type>
  <type name="function.type">
    <choice>
$function_values
    </choice>
  </type>
</pml_schema>
EOF
}

sub serialize_xml_element {
  my ($node,$indent)=@_;
  my $output='';
  $output = (' ' x $indent).'<' . $node->{-name};
  my $attributes = $node->{-attributes} || {};
  for (keys %$attributes) {
    my $val = $attributes->{$_};
    $val = escape($val);
    $output .= qq{ $_="$val"};
  }
  if (exists $node->{-children}) {
    $output .= ">\n".join('', map serialize_xml_element($_,$indent+1), @{$node->{-children}}) . 
      (' ' x $indent).qq(</$node->{-name}>\n);
  } elsif (exists $node->{-content}) {
    $output .= qq(>$node->{-content}</$node->{-name}>\n);
  } else {
    $output .= qq(/>\n);
  }
}


print "TOTAL SENTENCES: $sentence_total_counter \n";
print "FAILED SENTENCES $sentence_fail_counter \n";
print "RATIO: ". ($sentence_fail_counter / $sentence_total_counter)*100 . "% \n";


__END__

=head1 NAME

penn2pml.pl - convert files in the Penn Treebank (MRG) format to PML

=head1 SYNOPSIS

  penn2pml.pl [options] file.mrg ...

or

  penn2pml.pl -u          for usage
  penn2pml.pl -h          for help
  penn2pml.pl --man       for the manual page
  penn2pml.pl --version   for version

=head1 DESCRIPTION

This script converts files in the Penn Treebank (MRG) format to a PML
format based on the pennmrg_schema.xml or pennmrg_untyped_schema.xml
PML schemas distributed together with this script.

=over 5

=item B<--encoding|-e> encoding

Specify input character encoding (default is UTF-8). The output is
always stored in UTF-8.

=item B<--output-dir|-o> dirname

Write output files to a given directory. By default, all output files
are saved in the current directory under names that correspond to the
base input filenames with possible .gz suffix stripped and with .pml
suffix appended.

=item B<--base-schema|-s> pennmrg_schema.xml|pennmrg_untyped_schema.xml

Schema to use as base schema for the converted files. The
C<pennmrg_untyped_schema.xml> schema differs from
C<pennmrg_schema.xml> in using a single merged structure to represent
both terminal and neterminal nodes (although these nodes are still
stored different elements). The resulting data are identical as XML
documents (except for the schema reference), but their PML data model is different.
Using the untyped schema may simplify querying with PML-TQ.

The default is C<pennmrg_schema.xml>.

=item B<--generate-schema|-g> output_schema.xml

The base schema (as described above) declares the node attributes
'cat', 'pos', and 'functions' as enumerated types using the values
of Penn Treebank 3. This flag allows the script to collect the actual
set of values for these attributes from the data and generate a PML
schema that enumerates exactly those values that occur in the
converted documents. The result may not necessarily be a subset or
superset of the values listed in the base schema.

=item B<--bracketed-terminals|b>

Assume all terminals have the format of (POS WORD).

=item B<--non-bracketed-terminals|B>

Assume all terminals have the format of WORD/POS or TRACE, where TRACE
is a token starting with '*', e.g. *T*-2 or *op*.
Sibling terminals are assumed to be separated by whitespace or '+'.

=item B<--usage|-u>

Print a brief help message on usage and exits.

=item B<--help|-h>

Prints the help page and exits.

=item B<--man>

Displays the help as manual page.

=item B<--version>

Print program version.

=back

=head1 AUTHOR

Petr Pajas, E<lt>pajas@sup.ms.mff.cuni.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Petr Pajas

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
