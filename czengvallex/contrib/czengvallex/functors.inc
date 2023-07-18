# -*- cperl -*-

my %allowed_functors=(
	ACMP => 1,
	ACT => 1,
	AIM => 1,
	ADDR => 1,
	BEN => 1,
	CAUS => 1,
	CNCS => 1,
	COMPL => 1,
	COND => 1,
	CONTRD => 1,
	CPHR => 1,
	CPR => 1,
	CRIT => 1,
	DIFF => 1,
	DIR1 => 1,
	DIR2 => 1,
	DIR3 => 1,
	DPHR => 1,
	EFF => 1,
	EXT => 1,
	HER => 1,
	INTT => 1,
	LOC => 1,
	MANN => 1,
	MEANS => 1,
	ORIG => 1,
	PAT=> 1,
	REG => 1,
	RESL => 1,
	RESTR => 1,
	RSTR => 1,
	SUBS => 1,
	TFHL => 1,
	TFRWH => 1,
	THL => 1,
	THO => 1,
	TOWH => 1,
	TPAR => 1,
	TSIN => 1,
	TTILL => 1,
	TWHEN => 1
);

sub allowed_functor {
	my $functor = shift;

	return ((defined $allowed_functors{$functor} and $allowed_functors{$functor} == 1) ? 1 : 0)

}

