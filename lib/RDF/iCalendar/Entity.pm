package RDF::iCalendar::Entity;

use 5.008;
use base qw[RDF::vCard::Entity];
use strict;

our $VERSION = '0.003';

1;


__END__

=head1 NAME

RDF::iCalendar::Entity - represents an iCalendar calendar, event, todo, etc.

=head1 DESCRIPTION

This is a trivial subclass of L<RDF::vCard::Entity>.

=head1 SEE ALSO

L<RDF::iCalendar>, L<RDF::vCard::Entity>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

