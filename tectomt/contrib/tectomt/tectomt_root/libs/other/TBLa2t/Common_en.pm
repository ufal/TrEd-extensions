package TBLa2t::Common_en;

use 5.008;
use strict;
use warnings;

use TBLa2t::Common;

use Exporter 'import';
our @EXPORT = qw($MODEL @func3 tag adjust_lemma morph_real fill_afun);

use Report;

our @func3 = qw( ACT ADDR AIM APP BEN CAUS CPHR CPR DIR1 DIR3 EFF LOC MANN ORIG PAT RHEM RSTR TFHL ); # jen uzly, ktere v trenovacich datech jsou generovane a nemaji deti (a jsou takove alespon 2x)

my $model = $ENV{'TBLa2t_MODEL_en'} || "en_wsj";
Report::info "Using English language model \"$model\"";
our $MODEL = "$ENV{'TMT_SHARED'}/generated_data/models_for_TBLa2t/$model";
-d $MODEL or Report::fatal "Missing model: $MODEL";

#======================================================================

sub tag
{
	my $a_node = shift;
	my $tag = attr($a_node, 'm/tag');
	return $tag =~ /^#+$/? '###' : $tag;
}
	
#======================================================================

sub adjust_lemma
{
	my ($a_node) = @_;
	my $lemma = attr($a_node, 'm/lemma');
	$lemma =~ s/^(.+?)[_].+$/$1/;
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
		push @ret, adjust_lemma($a_aux) if tag($a_aux) =~ /^(IN)|(NN)|(POS)|(TO)/;
	}
	my $ret = join '+', sort @ret;
	$_ = $a_lex? tag($a_lex) : '#';
	my $pos = do {
		/^(PRP\$)|(WP\$)$/ ? 'P' :
		/^(NN)|(PRP$)|(WP)/ ? 'N' :
		/(^JJ)|(^[^P]?DT$)/ ? 'A' :
		/^(VB)|(MD)/ ? 'V' :
		/^(RB)|(WRB)$/ ? 'D' :
		/^(CD)|(PDT)/ ? 'C' :
		/^CC/ ? 'J' :
		/^IN/ ? 'R' :
		/^RP/ ? 'T' :
		/^UH/ ? 'I' :
		/^[^#]/ ? 'X' :
		        '#'
		};
	return ($ret? $ret.'+' : "") . $pos;
}

#======================================================================

sub fill_afun
{
	my ($t_root) = @_;
	for my $a_node (map { $_->get_lex_anode } $t_root->get_descendants) {
		$a_node or next; # for nodes added at the t-layer only
		my $nt = ($a_node->get_nonterminal_pnodes)[-1]; # the highest nonterminal
		$a_node->set_attr('afun', $nt ?
			join('-', ($nt->get_attr('phrase'), make_array($nt->get_attr('functions'))))
			: $a_node->get_terminal_pnode->get_attr('tag') );
		tag($a_node) ne 'CC' or $a_node->set_attr('afun', 'Coord');
	}
}

#======================================================================

1;

