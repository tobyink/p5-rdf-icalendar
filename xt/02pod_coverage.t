use Test::More;
use Test::Pod::Coverage;

my @modules = qw(RDF::iCalendar::Exporter RDF::iCalendar::Entity RDF::iCalendar::Line);
pod_coverage_ok($_, "$_ is covered")
	foreach @modules;
done_testing(scalar @modules);

