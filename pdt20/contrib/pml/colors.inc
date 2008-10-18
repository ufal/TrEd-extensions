# -*- cperl -*-

{ my@CustomColors=qw/error red
                     mlemma blue
                     form black
                     tag darkgreen
                     lemma black
                     current red
                     sentence black
                     spell gray
                     status darkblue
                     tfa_text darkcyan
                     tfa_t white
                     tfa_f yellow
                     tfa_c green
                     tfa_no #c0c0c0
                     func #601808
                     subfunc #a02818
                     afun darkblue
                     coappa blue
                     parenthesis #809080
                     nodetype darkblue
                     complex darkmagenta
                     detail darkgreen
                     detailheader #002416
                     coref darkblue
                     arrow_textual #4C509F
                     arrow_grammatical #C05633
                     arrow_segment darkred
                     arrow_compl #629F52
                     arrow_exoph blue
                     line_normal #7f7f7f
                     line_member #a0a0a0
                     line_comm #6F11EA
                     lex darkgreen
                     aux darkorange/;
  while(@CustomColors){
    my$key=shift(@CustomColors);
    my$val=shift(@CustomColors);
    unless (CustomColor($key)) {
      CustomColor($key,$val);
    }
  }
}
