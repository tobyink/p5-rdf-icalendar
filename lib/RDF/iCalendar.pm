package RDF::iCalendar;

use 5.008;
use common::sense;
use RDF::iCalendar::Exporter;
use RDF::iCalendar::Importer;

our $VERSION = '0.001';

1;

__END__

=head1 NAME

RDF::iCalendar - convert between RDF and iCalendar

=head1 DESCRIPTION

This module doesn't do anything itself; it just loads RDF::iCalendar::Exporter 
for you.

=head2 RDF::iCalendar::Exporter

L<RDF::iCalendar::Exporter> takes some RDF using the W3C's iCalendar vocabulary,
and outputs L<RDF::iCalendar::Entity> objects.

=head2 RDF::iCalendar::Importer

B<RDF::vCard::Importer> will do the reverse, but doesn't exist yet.

=head2 RDF::iCalendar::Entity

An L<RDF::iCalendar::Entity> objects is an individual iCalendar calendar. It overloads
stringification, so just treat it like a string.

=head2 RDF::iCalendar::Line

L<RDF::iCalendar::Line> is internal fu that you probably don't want to touch.

=head1 BUGS

Please report any bugs to
L<https://rt.cpan.org/Public/Dist/Display.html?Name=RDF-iCalendar>.

=head1 SEE ALSO

L<http://www.w3.org/TR/rdfcal/>.

L<http://www.perlrdf.org/>.

L<RDF::vCard>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

