package PMLTQ::Relation::PDT20;
#
# This file implements the following user-defined relations for PML-TQ
#
# - a/lex.rf|a/aux.rf
# - eparent (both t-layer and a-layer)
# - echild (both t-layer and a-layer)
#
#################################################
{
  package PMLTQ::Relation::PDT20::ALexOrAuxRFIterator;
  use strict;
  use base qw(PMLTQ::Relation::SimpleListIterator);
  use PMLTQ::Relation {
      name => 'a/lex.rf|a/aux.rf',
      start_node_type => 't-node',
      target_node_type => 'a-node',
      iterator_class => __PACKAGE__,
      iterator_weight => 2,
      test_code => q(grep($_ eq $end->{id}, GetANodeIDs($start)) ? 1 : 0),
  };

  sub get_node_list  {
    my ($self,$node)=@_;
    my $fsfile = $self->start_file;
    my $a_file = PML_T::AFile($fsfile);
    return [ $a_file ? map [$_,$a_file ], PML_T::GetANodes($node,$fsfile) : () ];
  }
}
# #################################################
{
  package PMLTQ::Relation::PDT20::AEParentIterator;
  use strict;
  use base qw(PMLTQ::Relation::SimpleListIterator);
  use PMLTQ::Relation {
      name => 'eparent',
      reversed_relation => 'echild',
      start_node_type => 'a-node',
      target_node_type => 'a-node',
      iterator_class => __PACKAGE__,
      test_code => q( grep($_ == $end, PML_A::GetEParents($start,\&PML_A::DiveAuxCP)) ? 1 : 0 ),
  };
  sub get_node_list  {
    my ($self,$node)=@_;
    my $type = $node->type->get_base_type_name;
    my $fsfile = $self->start_file;
    return [
      map [ $_,$fsfile ], PML_A::GetEParents($node,\&PML_A::DiveAuxCP)
    ];
  }
}
#################################################
{
  package PMLTQ::Relation::PDT20::TEParentIterator;
  use strict;
  use base qw(PMLTQ::Relation::SimpleListIterator);
  use PMLTQ::Relation {
      name => 'eparent',
      reversed_relation => 'echild',
      start_node_type => 't-node',
      target_node_type => 't-node',
      iterator_class => __PACKAGE__,
      iterator_weight => 2,
      test_code => q( grep($_ == $end, PML_T::GetEParents($start)) ? 1 : 0 ),
  };
  sub get_node_list  {
    my ($self,$node)=@_;
    my $type = $node->type->get_base_type_name;
    my $fsfile = $self->start_file;
    return [
      map [ $_,$fsfile ], PML_T::GetEParents($node)
    ];
  }
}
#################################################
{
  package PMLTQ::Relation::PDT20::AEChildIterator;
  use strict;
  use base qw(PMLTQ::Relation::SimpleListIterator);
  use PMLTQ::Relation {
      name => 'echild',
      reversed_relation => 'eparent',
      start_node_type => 'a-node',
      target_node_type => 'a-node',
      iterator_class => __PACKAGE__,
      iterator_weight => 5,
      test_code => q( grep($_ == $start, PML_A::GetEParents($end,\&PML_A::DiveAuxCP)) ? 1 : 0 ),
  };
  sub get_node_list  {
    my ($self,$node)=@_;
    my $type = $node->type->get_base_type_name;
    my $fsfile = $self->start_file;
    return [
      map [ $_,$fsfile ], PML_A::GetEChildren($node,\&PML_A::DiveAuxCP)
    ];
  }
}
#################################################
{
  package PMLTQ::Relation::PDT20::TEChildIterator;
  use strict;
  use base qw(PMLTQ::Relation::SimpleListIterator);
  use PMLTQ::Relation {
      name => 'echild',
      reversed_relation => 'eparent',
      start_node_type => 't-node',
      target_node_type => 't-node',
      iterator_class => __PACKAGE__,
      iterator_weight => 5,
      test_code => q( grep($_ == $start, PML_T::GetEParents($end)) ? 1 : 0 ),
  };
  sub get_node_list  {
    my ($self,$node)=@_;
    my $type = $node->type->get_base_type_name;
    my $fsfile = $self->start_file;
    return [
      map [ $_,$fsfile ], PML_T::GetEChildren($node)
    ];
  }
}

1;

