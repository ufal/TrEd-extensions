package SimpleLemmatizer::Czech;

# simple lemmatizer using mapping (form,pos)->lemma extracted from PDT
# written by Zdenek Zabokrtsky

use strict;
use warnings;

my $filename = "$ENV{TMT_SHARED}/generated_data/data_for_simple_lemmatizer/form_and_pos_to_lemma.tsv.gz";

my %form_and_pos_to_lemma;

print STDERR "Loading the lemmatization table...\n";
my $fh = Treex::PML::IO::open_uri($filename,'UTF-8') or die $!;
#open my $fh, "<:raw:perlio:gzip:utf8",$filename or die $!;
while (<$fh>) {
    chomp;
    my ($form,$pos,$lemma) = split /\t/;
    $form_and_pos_to_lemma{$form}{$pos} = $lemma
        unless defined $form_and_pos_to_lemma{$form}{$pos};
}
Treex::PML::IO::close_uri($fh);
print STDERR "Lemmatization table loaded.\n";

sub lemmatize {
    my ($form,$tag) = @_;
    if ($tag =~ /^(.)/) {
        my $pos = $1;
        my $lemma = $form_and_pos_to_lemma{lc($form)}{$pos} || lc($form);
    }
}
