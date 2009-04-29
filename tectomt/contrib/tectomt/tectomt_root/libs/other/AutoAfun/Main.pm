package AutoAfun::Main;

# -*- cperl -*-
## author: Petr Pajas, Zdenek Zabokrtsky

# this code was extracted from Tred's AutoAfun extension
# and arranged for the needs of TectoMT by Zdenek Zabokrtsky

use strict;
use Fslib;
use AutoAfun::Assign_afun;

#use lib CallerDir("AutoAfun");

my %LcAfuns = map { lc($_)=>$_ }
  qw(--- Pred Pnom AuxV Sb Obj Atr Adv AtrAdv AdvAtr Coord AtrObj
     ObjAtr AtrAtr AuxT AuxR AuxP Apos ExD AuxC Atv AtvV AuxO AuxZ
     AuxY AuxG AuxK AuxX AuxS Pred_Co Pnom_Co AuxV_Co Sb_Co Obj_Co
     Atr_Co Adv_Co AtrAdv_Co AdvAtr_Co Coord_Co AtrObj_Co ObjAtr_Co
     AtrAtr_Co AuxT_Co AuxR_Co AuxP_Co Apos_Co ExD_Co AuxC_Co Atv_Co
     AtvV_Co AuxO_Co AuxZ_Co AuxY_Co AuxG_Co AuxK_Co AuxX_Co Pred_Ap
     Pnom_Ap AuxV_Ap Sb_Ap Obj_Ap Atr_Ap Adv_Ap AtrAdv_Ap AdvAtr_Ap
     Coord_Ap AtrObj_Ap ObjAtr_Ap AtrAtr_Ap AuxT_Ap AuxR_Ap AuxP_Ap
     Apos_Ap ExD_Ap AuxC_Ap Atv_Ap AtvV_Ap AuxO_Ap AuxZ_Ap AuxY_Ap
     AuxG_Ap AuxK_Ap AuxX_Ap Pred_Pa Pnom_Pa AuxV_Pa Sb_Pa Obj_Pa
     Atr_Pa Adv_Pa AtrAdv_Pa AdvAtr_Pa Coord_Pa AtrObj_Pa ObjAtr_Pa
     AtrAtr_Pa AuxT_Pa AuxR_Pa AuxP_Pa Apos_Pa ExD_Pa AuxC_Pa Atv_Pa
     AtvV_Pa AuxO_Pa AuxZ_Pa AuxY_Pa AuxG_Pa AuxK_Pa AuxX_Pa
     NA ???);
my $AutoAfunAtr='afun';

sub afun_info {
  my ($node)=@_;
#  print STDERR $node->attr('m/lemma')." ".$node->attr('m/tag')."\n";
  return ref($node) ?
    ($node->attr('m/lemma')||"#1",$node->attr('m/tag')||"Z#--------------"): #,scalar($node->children())) :
    (undef, undef); #, undef);
}

sub real_parent {
  my ($node)=@_;
  my $last;
  do  {
    $node=$node->parent();
    $last=$node if $node;
  } while ($node and $node->attr('m/tag')!~/^[NVADPC]/);
  return $last;
}


sub normalize_afun {
  my ($afun)=@_;
  if ($afun eq "???" or $afun eq "") {return "Atr"}
  else {  return $LcAfuns{$afun} };
}

#bind assign_afun_auto Ctrl+Shift+F9 menu Auto-assign analytical function to node
sub assign_afun_auto {
  my $node = shift;

  if (!$node->parent) {
    $node->{$AutoAfunAtr}='AuxS';
    return;
  }
  my ($afun,$num1,$num2)=
    AutoAfun::Assign_afun::afun( afun_info(real_parent($node)),
		       afun_info($node->parent),
		       afun_info($node),
		     );
  my $afun = normalize_afun($afun);
  if ($afun =~ s/_.+//) {
      $node->{is_member} = 1;
  }
  $node->{$AutoAfunAtr} = $afun;
}


sub assign_afun_auto_tree {
  my ($root)=@_;
  my $node = $root;;
  while ($node) {
    assign_afun_auto($node);
    $node=$node->following($root);
  }
}

1;
