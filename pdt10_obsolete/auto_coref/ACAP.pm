
# -*- perl -*-
# This script is an attempt to automatically find possible coreferents
# in TGTS structures for Czech.
# contributed to TrEd by Oliver Culo in 12/2003

# Completely substituted by Zdenek Zabokrtsky'code in 4/2004

package ACAP;


# listst of control verbs

my $control_ADDR='(br�nit|d�t|donutit|dopomoci|doporu�it|doporu�ovat|dovolit|dovolovat|motivovat|na��dit|nau�it|navrhnout|navrhovat|nutit|poda�it_se|pom�hat|pomoci|pov��it|povolit|povolovat|po�adovat|p�edepsat|p�ik�zat|p�im�t|p�inutit|sta�it|st�t|ukl�dat|ulo�it|umo�nit|umo��ovat|ur�it|vypomoci|zabr�nit|zabra�ovat|zak�zat|zakazovat|zapov�dat|zavazovat|zmocnit|znemo�nit|znemo��ovat)';

my $control_PAT='(bavit|b�t|donutit|nau�it|nechat|nech�vat|nutit|opr�vnit|osv�d�ovat_se|poda�it_se|p�ipravit|sna�it_se|spat�it|sta�it|�kodit|unavovat|vadit|vid�t|vyplatit_se|zb�t|zb�vat)';

my $control_BEN='(b�t|b�vat|j�t|lze|odm�tat|ozna�it|pova�ovat|sna�it_se|st�t|uznat|vyplatit_se|zd�t_se|znamenat)';

my $control_ACT='(b�t_se|c�tit_se|�asit|da�it_se|d�t|d�t|d�t_se|d�vat|doj�t|dok�zat|dostat|dov�st|dovolit_si|dovolovat_si|dozv�d�t_se|hodlat|hrozit|chodit|cht�t|cht�t_se|chystat_se|jet|jevit_se|jezdit|kl�st|koukat|m�nit|m�t|moci|naklonit|nam�hat_se|napadnout|nau�it_se|nechat_se|nech�vat|nech�vat_se|odej�t|odhodlat|odhodlat_se|odl�tat|odm�tat|odm�tnout|odnau�it_se|odv�it_se|opomenout|opr�vnit|ost�chat_se|pl�novat|poda�it_se|pokou�et_se|pokusit|pokusit_se|pom�hat|pot�ebovat|pova�ovat|pov�st_se|p��t_si|p�estat|p�est�vat|p�ich�zet|p�ijet|p�ij�t|p�ij�t_si|p�ij�d�t|p�ipravit|p�isl�bit|p��slu�et|rozhodnout|rozhodnout_se|rozmyslit_si|sna�it_se|sp�chat|stihnout|sv�st|tou�it|troufat_si|troufnout_si|u�it_se|uk�zat_se|ukazovat_se|um�t|usilovat|uznat|v�hat|v�d�t|vyh�bat_se|vytknout_si|za��nat|za��t|zak�zat|zapomenout|zapom�nat|zaslou�it_si|zatou�it|zav�zat_se|zb�t|zkou�et|zkusit|znamenat|znemo��ovat|z�stat|z�st�vat|zvl�dnout|zvyknout_si)';

# ------------------------------------------------------------------------------
# --------  function for automatic assignment of grammatical coreference -------

sub autoAssignCorefs ($) {

  my $node=shift || $this;
  return unless ($node->parent and $node->parent->parent);
  my $parent=$node->parent;
  my $grandpa=$parent->parent;
  my ($lparent)=(PDT::GetFather_TR($node));
  my $antec;

  #  -------------------- gramaticka kontrola -------------------------------
  if ($node->{trlemma} eq '&Cor;' and $parent->{tag}=~/^Vf/ and $grandpa->{tag}=~/^V/) {
    if ($grandpa->{trlemma}=~/^$control_BEN$/) {
      ($antec)=(grep {$_->{func} eq "BEN"} $grandpa->children);
    }
    if (not $antec and $grandpa->{trlemma}=~/^$control_ADDR$/) {
      ($antec)=(grep {$_->{func} eq "ADDR"} $grandpa->children);
    }
    if (not $antec  and $grandpa->{trlemma}=~/^$control_ACT$/) {
      ($antec)=(grep {$_->{func} eq "ACT"} $grandpa->children);
    }
  }

  # ------------------- zvratna zajmena -------------------
  elsif ($node->{trlemma} eq "se" and $node->{func} ne "DPHR") {
    my $par=$node;
    while ($par->parent) {
      my $child=$par;
      $par=$par->parent;
      my @children= PDT::GetChildren_TR($par);
      my ($act)= grep {$_->{afun} eq "Sb" and $_ ne $child and $_ ne $node} @children;
      if (not $act) {($act)= grep {$_->{func} eq "ACT" and $_ ne $child and $_ ne $node} @children; }
      if ($act) {
	if (PDT::is_member_TR($act)) {$act=$act->parent}
	$antec=$act;
	last;
      }
    }
  }

 # -------- vztazne vedlejsi vety
 elsif ($node->{trlemma}=~/^(kter�|jak�|jen�|kdy|kde|co|kdo)$/ and $lparent
	and $lparent->{tag}=~/^V/ and $lparent->{func} eq "RSTR") {
   my ($lgrandpa)=(PDT::GetFather_TR($lparent));
   if ($lgrandpa and $lgrandpa->{tag}=~/^[PN]/) {
     my %path_to_root;
     my $n=$node;
     while ($n->parent) {
       $path_to_root{$n}=1;
       $n=$n->parent
     };
     $n=$lgrandpa;
     while ($n->parent) {
       if ($path_to_root{$n}) {$antec=$n;last}
       $n=$n->parent;
     }
   }
 }

 # -------- vztazne vedlejsi vety s privlastnovacim vztaznym zajmenem (clovek, v jehoz dome...)
 elsif ($node->{trlemma}=~/^(jen�)$/ and $lparent and $lparent->{tag}=~/^N/) {
   my ($lgrandpa)=(PDT::GetFather_TR($lparent));
   if ($lgrandpa
       and $lgrandpa->{func} eq "RSTR"
       and $lgrandpa->{tag}=~/^V/
      ) {
     my ($lggrandpa)=(PDT::GetFather_TR($lgrandpa));
     if ($lggrandpa and $lggrandpa->{tag}=~/^[PN]/) {
       my %path_to_root;
       my $n=$node;
       while ($n->parent) {
	 $path_to_root{$n}=1;
	 $n=$n->parent
       };
       $n=$lggrandpa;
       while ($n->parent) {
	 if ($path_to_root{$n}) {$antec=$n;last}
	 $n=$n->parent;
       }
     }
   }
 }

  # ------------------ jmenne doplnky ve shode se subjektem -------------------------
  elsif ($node->{func} eq "COMPL" and $node->{tag}=~/^(AC|((NN|PL|AA|C[rl])..1))/) {
    my ($parent)=(PDT::GetFather_TR($node));
    my @children= PDT::GetChildren_TR($parent);
    my ($act)= grep {$_->{afun} eq "Sb" and $_ ne $child and $_ ne $node} @children;
    if (not $act) {
	($act)= grep {$_->{func} eq "ACT" and $_ ne $child and $_ ne $node} @children;
      }
    if ($act) {
      if (PDT::is_member_TR($act)) {$act=$act->parent}
      $antec=$act;
    }
  }

  # ------------------ jmenne doplnky ve shode s objektem -------------------------
  elsif ($node->{func} eq "COMPL" and $node->{tag}=~/^(NN|AA)..4/) {
    my ($parent)=(PDT::GetFather_TR($node));
    my @children= PDT::GetChildren_TR($parent);
    my ($obj)= grep {$_->{tag}=~/^.[^7]..4/ and $_ ne $child and $_ ne $node} @children;
    if ($obj) {
      if (PDT::is_member_TR($obj)) {$obj=$obj->parent}
      $antec=$obj;
    }
  }

  if ($antec) {
    my $antecid=$antec->{TID} || $antec->{AID};
    return ($antecid,'autogrammatical')
  }  else {
    return undef
  }
}

# ------------------------------------------------------------------------------
# ----------- function for detecting coreference `candidates' ------------------ 

sub corefCandidate {
  my $node=shift || $this;
  my $depth;
  my $x=$node; while ($x->parent) {$depth++;$x=$x->parent}
  return unless $node;
  my ($parent)=(PDT::GetFather_TR($node));
  return ($node->{func}!~/(ETHD|DPHR|INTF|EXT)/ and
	  (
	   $node->{trlemma}=~/^(Cor|\&Cor|\&Cor;|\&Rcp;|.?QCor.?|on|se)$/
	   or ($node->{trlemma}=~/^(ten|tent��|t��|tento|tenhle)$/ and
	       $node->{func}!~/(RSTR|DIFF)/
	       and not (grep {
		 $_->{sentord}==$node->{sentord}+2 and
		   ($_->{trlemma}=~/^(kdo|co|kter�|jak�|jak|jen�)$/ or # ten, kdo...
		    $_->{tag}=~/^J,/) # to, ze....
		 } $node->root->descendants()
		       )
	      )
	   or ($node->{trlemma}=~/^(jen�|jak|kdy|kam|kudy|kde|kdo|co|co�|tenhle|odkud|odkdy)$/
	       and $node->{ord}>2
	       and not ($parent->{func}=~/(EFF|PAT)/ and $parent->{tag}=~/^V/)
	       and $depth>2
	      )
	   or ($node->{trlemma}=~/^(kter�|jak�)$/
	       and not $parent->{tag}=~/^N/
	       and $depth>2
	      )

	   or $node->{func}=~/^COMPL/
	  )
	 )
}

1;

