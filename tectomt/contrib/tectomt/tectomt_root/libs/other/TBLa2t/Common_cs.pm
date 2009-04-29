package TBLa2t::Common_cs;

use 5.008;
use strict;
use warnings;

use TBLa2t::Common;

use Exporter 'import';
our @EXPORT = qw($MODEL @func3 tag_generic adjust_lemma morph_real);

use Report;

our @func3 = qw( ACMP ACT ADDR APP BEN CAUS CM CPHR CPR DIR1 DIR2 DIR3 DPHR EFF EXT ID LOC MANN MAT ORIG PAT PRED RHEM RSTR TFRWH TOWH TWHEN ); # jen uzly, ktere v trenovacich datech jsou generovane a nemaji deti (a jsou takove alespon 2x)

my $model = $ENV{'TBLa2t_MODEL_cs'} || "cs_pdt";
Report::info "Using Czech language model \"$model\"";
our $MODEL = "$ENV{'TMT_SHARED'}/generated_data/models_for_TBLa2t/$model";
-d $MODEL or Report::fatal "Missing model: $MODEL";

#======================================================================

sub tag_generic
{
	my $a_node = shift;
	my $ret = "";
	my @t = split //, attr($a_node, 'm/tag');
	for (@_) {
		$ret .= $t[$_] . " ";
	}
	return $ret;
}

#======================================================================

sub adjust_lemma
{
	my ($a_node) = @_;
	my $lemma = attr($a_node, 'm/lemma');
	$lemma =~ s/^(.+?)[-_`].+$/$1/;
	$lemma or $lemma eq '0' or Report::fatal "Empty adjusted lemma (". attr($a_node, 'm/lemma').")";
	return $lemma;
}

#======================================================================

sub morph_real
{
	my ($t_node) = @_;
	$t_node = ($t_node->get_transitive_coap_members)[0] if $t_node->is_coap_root;
	$t_node or ($t_node) = @_; # workaround for CoAp roots being leaves
	my $a_lex = $t_node->get_lex_anode;
	my @ret = ();
	for my $a_aux ($t_node->get_aux_anodes) {
		push @ret, adjust_lemma($a_aux) if $a_aux->get_attr('m/tag') =~ /^[NJR]/;
	}
	my $tag = attr($a_lex, 'm/tag');
	my $case = substr($tag, 4, 1);
	my $ret = join '+', sort @ret;
	return ($ret? $ret.'+' : "") . substr($tag, 0, 1).($case =~ /[1-7]/? $case : "");
}

#======================================================================

1;

