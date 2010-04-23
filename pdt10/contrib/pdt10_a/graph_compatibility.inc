# -*- cperl -*-

package TredMacro;

###########################################################
# Macros for backward compatibility with Graph

=head2 Compatibility macros used by the Graph2Tred macro convertor

Please avoid using macros listed in this section.

=over 4

=item C<PrintToFile(filename,string,...)>

Print given strings to the end of the given file.

=cut

sub PrintToFile {
  my $file=shift;
  return unless( defined($file) and $file ne '' );
  my @a=@_;

  if (open(my $PTF,">>$file")) {
    print $PTF (join("",(map {
      s/\\\|/|/g;
      s/\\n/\n/g;
      $_} @a)));
    close($PTF);
  } else { print STDERR "Could not open file $file\n"; }
}

=item C<ValNo(n,string)>

Return the n'th field of the given string where individual fields are
separated by "|".

=cut

sub ValNo {
  my $n=shift;
  my @val=ListSplit(shift);
  return $val[$n];
}

=item C<AtrNo(n)>

Retrun name of the n'th attribute defined in the FS file. This macro
only abbreviates the following expression:
C<< FS()->atno(n) >>

=cut

sub AtrNo {
  return FS()->atno(shift);
}

=item C<Union(string_a,string_b)>

Return a string consisting of |-separated fields which form a pairwise
disjoint set of the |-separated fields of the given strings string_a
and string_b.

=cut

sub Union {
  my @c=();
  my $s;
  my $t;
  element: foreach $s (ListSplit(shift),ListSplit(shift)) {
    for ($t=0;$t<=$#c;$t++) {
      next element if ($c[$t] eq $s);
    }
    push @c,$s;
  }
  return join('|',@c);
}

=item C<Interjection(string_a,string_b)>

Return a string consisting of |-separated fields which form the
interjection of the sets of |-separated fields of the given strings
string_a and string_b.

=cut

sub Interjection {
  return $_[0] unless $_[1] ne "";
  my @a=ListSplit($_[1]);
  my @c=();
  my $s;
  my $t;
  element: foreach $s (ListSplit(Union($_[0],""))) {
    for ($t=0;$t<=$#a;$t++) {
      if ($a[$t] eq $s) {
	push(@c,$s);
	next element;
      }
    }
  }
  return join '|',@c;
}

=item C<ListSplit(string)>

Split the given string of |-separated fields and return a list of the
individual fields.

=cut

sub ListSplit {

  my $s=shift;
  my $j=0;
  my $i=0;
  my @a=();
  while (($j=index($s,'|',$j))>=0) {
    $j++,next if ($j>0 and substr($s,$j-1,1) eq "\\");
    push @a, substr($s,$i,$j-$i);
    $i=++$j; $j=$i;
  }
  push @a, substr($s,$i,length($s)-$i) if ($i<length($s));
  return @a;
}

=item C<ListJoin(list)>

Form a string of |-separated fields from the given list of fields.

=cut

sub ListJoin {
 return join '|', map { s/|/\|/ }  @_;
}

=item C<ListEq(string1, string2)>

Compare the sets of |-separated fields of the two given
strings. Return true if the sets contain the same elements; return
false otherwise.

=cut

sub ListEq {
  my ($a,$b)=(shift,shift);
  $a=Union($a,""); # make them uniqe
  $b=Union($b,""); # make them uniqe
  my @a=ListSplit($a);
  my @b=ListSplit($b);

  return 0 unless ($#a == $#b);

  my @c=ListSplit(Union($a,$b));

  return ($#a == $#c);
}

=item C<ListAssign(string,n,value)>

Return the given string of |-separated fields, except that the n'th
field in the string is replaced by the given value.

=cut

sub ListAssign {
  my @a=ListSplit(shift);
  my ($n,$value)=(shift,shift);

  $a[$n]=ValNo(0,$value);
  return join '|',@a;
}

=item C<SubStr(string,position,length)>

Simple substr wrapper which returns an empty string if the position is
beyond the end of the string.

=cut

sub SubStr {
  my ($str, $pos, $len)=(shift, shift, shift);

  return "" if ($pos > length($str));
  return substr($str,$pos,$len);
}

=back

=cut

1;
