package TrEd::FramesPairs::LibXMLData;

use strict;
use base qw(TrEd::FramesPairs::FramesPairsData);
use IO;
use XML::LibXML;

#############################################
## adding some features to XML::LibXML::Node
#############################################
package XML::LibXML::Node;

sub getChildElementsByTagName {
  my ($self,$name)=@_;
  my $n=$self->firstChild();
  my @n;
  while ($n) {
    push @n,$n if ($n->nodeName() eq $name);
    $n=$n->nextSibling();
  }
  return @n;
}

1;
