package TredPlugin::CzechAnalysis;

# Simple API for morphological, analytical and tectogrammatical
# analysis of Czech sentences, using only pure-Perl TectoMT blocks.
# Intended for interactive usage in Tred.
# written by Zdenek Zabokrtsky

use strict;
use warnings;

use TectoMT::Document;
use TectoMT::Bundle;
use TectoMT::Node;
use TectoMT::Scenario;

my $scenario =  TectoMT::Scenario->new({'blocks' => [ qw(
        SCzechW_to_SCzechM::Sentence_segmentation
	SCzechW_to_SCzechM::Tokenize.pm
	SCzechW_to_SCzechM::Simple_tagger
	SCzechW_to_SCzechM::Simple_lemmatizer
        SCzechM_to_SCzechA::ZZ_parser
        SCzechM_to_SCzechA::Fill_afun
	SCzechM_to_SCzechA::Fix_is_member
        SCzechA_to_SCzechT::Mark_auxiliary_nodes
        SCzechA_to_SCzechT::Build_ttree
        SCzechA_to_SCzechT::Rehang_unary_coord_conj
	SCzechA_to_SCzechT::Fill_is_member
        SCzechA_to_SCzechT::Assign_coap_functors
        SCzechA_to_SCzechT::Fix_is_member
        SCzechA_to_SCzechT::Distrib_coord_aux
        SCzechA_to_SCzechT::Mark_clause_heads
        SCzechA_to_SCzechT::Mark_relclause_heads
        SCzechA_to_SCzechT::Fix_tlemmas
        SCzechA_to_SCzechT::Recompute_deepord
        SCzechA_to_SCzechT::Assign_nodetype
        SCzechA_to_SCzechT::Assign_grammatemes
        SCzechA_to_SCzechT::Detect_formeme
        SCzechA_to_SCzechT::TBLa2t_phaseFd
                                                    ) ]});


sub Get_mat_text_analyses {
    my $text = shift;

    if (not defined $text or $text eq "") {
        die "Undefined or empty input text!";
    }

    my $document = TectoMT::Document->new();
    $document->set_attr('czech_source_text', $text);

    $scenario->apply_on_tmt_documents($document);

    my @bundles = $document->get_bundles;

    my @fs_m_roots = map {$_->get_tree('SCzechM')->get_tied_fsnode;} @bundles;
    my @fs_a_roots = map {$_->get_tree('SCzechA')->get_tied_fsnode;} @bundles;
    my @fs_t_roots = map {$_->get_tree('SCzechT')->get_tied_fsnode;} @bundles;

    return ( \@fs_m_roots, \@fs_a_roots, \@fs_t_roots );

}
