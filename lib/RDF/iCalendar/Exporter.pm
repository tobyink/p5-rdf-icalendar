package RDF::iCalendar::Exporter;

use 5.008;
use base qw[RDF::vCard::Exporter];
use common::sense;

use Data::Dumper; #XXX
use MIME::Base64 qw[];
use RDF::iCalendar::Entity;
use RDF::iCalendar::Line;
use RDF::TrineShortcuts qw[:all];
use Scalar::Util qw[blessed];
use URI;

# kinda constants
sub I    { return 'http://www.w3.org/2002/12/cal/icaltzd#' . shift; }
sub IX   { return 'http://buzzword.org.uk/rdf/icaltzdx#' . shift; }
sub RDF  { return 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' . shift; }
sub V    { return 'http://www.w3.org/2006/vcard/ns#' . shift; }
sub VX   { return 'http://buzzword.org.uk/rdf/vcardx#' . shift; }
sub XSD  { return 'http://www.w3.org/2001/XMLSchema#' . shift; }

use namespace::clean;

our $VERSION = '0.000_00';
our $PRODID  = sprintf("+//IDN cpan.org//NONSGML %s v %s//EN", __PACKAGE__, $VERSION);

our %cal_dispatch = (
	);

our %dispatch = (
	IX('contact')    => \&_prop_export_contact,
	I('contact')     => \&_prop_export_contact,
	I('geo')         => \&_prop_export_geo,
	IX('organizer')  => \&_prop_export_Person,
	I('organizer')   => \&_prop_export_Person,
	IX('attendee')   => \&_prop_export_Person,
	I('attendee')    => \&_prop_export_Person,
	# LOCATION
	# ATTACH
	# CATEGORIES
	# EXDATE
	# EXRULE
	# RDATE
	# RRULE
	# RELATED-TO
	# RESOURCES
	# VALARM
	# FREEBUSY
	);

sub rebless
{
	my ($self, $thing) = @_;
	if ($thing->isa('RDF::vCard::Line'))
	{
		return bless $thing, 'RDF::iCalendar::Line';
	}
	if ($thing->isa('RDF::vCard::Entity'))
	{
		return bless $thing, 'RDF::iCalendar::Entity';
	}
}

sub export_calendars
{
	my ($self, $model, %options) = @_;
	$model = rdf_parse($model)
		unless blessed($model) && $model->isa('RDF::Trine::Model');
	
	my @subjects =  $model->subjects(rdf_resource(RDF('type')), rdf_resource(I('Vcalendar')));
	push @subjects, $model->subjects(rdf_resource(I('component')), undef);	
	my %subjects = map { flatten_node($_) => $_ } @subjects;
	
	my @cals;
	foreach my $s (values %subjects)
	{
		push @cals, $self->export_calendar($model, $s, %options);
	}
	
	if ($options{sort})
	{
		return sort { $a->entity_order cmp $b->entity_order } @cals;
	}
	
	return @cals;
}

sub export_calendar
{
	my ($self, $model, $subject, %options) = @_;
	$model = RDF::TrineShortcuts::rdf_parse($model)
		unless blessed($model) && $model->isa('RDF::Trine::Model');
	
	my $ical = RDF::iCalendar::Entity->new( profile=>'VCALENDAR' );
	
	my %categories;
	my $triples = $model->get_statements($subject, undef, undef);
	while (my $triple = $triples->next)
	{
#		next
#			unless (substr($triple->predicate->uri, 0, length(&I)) eq &I or
#					  substr($triple->predicate->uri, 0, length(&IX)) eq &IX);

		if ($triple->predicate->uri eq I('component'))
		{
			$ical->add_component($self->export_component($model, $triple->object));
		}
		elsif (defined $cal_dispatch{$triple->predicate->uri}
		and    ref($cal_dispatch{$triple->predicate->uri}) eq 'CODE')
		{
			my $code = $cal_dispatch{$triple->predicate->uri};
			$ical->add($code->($self, $model, $triple));
		}
		elsif (! $triple->object->is_blank)
		{
			$ical->add($self->_prop_export_simple($model, $triple));
		}
	}
			
	$ical->add(
		RDF::iCalendar::Line->new(
			property        => 'version',
			value           => '2.0',
			)
		);
		
	$ical->add(
		RDF::iCalendar::Line->new(
			property        => 'prodid',
			value           => (defined $options{prodid} ? $options{prodid} : $PRODID),
			)
		) unless exists $options{prodid} && !defined $options{prodid};

	$ical->add(
		RDF::iCalendar::Line->new(
			property        => 'source',
			value           => $options{source},
			type_parameters => {value=>'URI'},
			)
		) if defined $options{source};

	return $ical;
}

sub export_component
{
	my ($self, $model, $subject, %options) = @_;
	$model = RDF::TrineShortcuts::rdf_parse($model)
		unless blessed($model) && $model->isa('RDF::Trine::Model');
	
	my $profile = 'VEVENT';
	$profile = 'VTIMEZONE'
		if $model->count_statements($subject, rdf_resource(RDF('type')), rdf_resource(I('Vtimezone')));
	$profile = 'VFREEBUSY'
		if $model->count_statements($subject, rdf_resource(RDF('type')), rdf_resource(I('Vfreebusy')));
	$profile = 'VALARM'
		if $model->count_statements($subject, rdf_resource(RDF('type')), rdf_resource(I('Valarm')));
	$profile = 'VJOURNAL'
		if $model->count_statements($subject, rdf_resource(RDF('type')), rdf_resource(I('Vjournal')));
	$profile = 'VTODO'
		if $model->count_statements($subject, rdf_resource(RDF('type')), rdf_resource(I('Vtodo')));
	$profile = 'VEVENT'
		if $model->count_statements($subject, rdf_resource(RDF('type')), rdf_resource(I('Vevent')));
	
	my $c = RDF::iCalendar::Entity->new( profile=>$profile );
	
	my %categories;
	my $triples = $model->get_statements($subject, undef, undef);
	while (my $triple = $triples->next)
	{
#		next
#			unless (substr($triple->predicate->uri, 0, length(&I)) eq &I or
#					  substr($triple->predicate->uri, 0, length(&IX)) eq &IX);

		if (defined $dispatch{$triple->predicate->uri}
		and ref($dispatch{$triple->predicate->uri}) eq 'CODE')
		{
			my $code = $dispatch{$triple->predicate->uri};
			$c->add($code->($self, $model, $triple));
		}
		elsif (! $triple->object->is_blank)
		{
			$c->add($self->_prop_export_simple($model, $triple));
		}
	}
			
	return $c;
}

sub _prop_export_simple
{
	my ($self, $model, $triple) = @_;
	my $rv = $self->SUPER::_prop_export_simple($model, $triple);
	return $self->rebless($rv);
}

sub _prop_export_contact
{
	my ($self, $model, $triple) = @_;

	if ($triple->object->is_literal)
	{
		return $self->_prop_export_simple($model, $triple);
	}
	
	my $card = $self->export_card($model, $triple->object);
	my $uri  = URI->new('data:');
	$uri->media_type('text/directory');
	$uri->data("$card");

	my $label = '';
	my ($fn)     = $card->get('fn');
	my ($email)  = $card->get('email');
	if ($fn and $email)
	{
		$label = sprintf('%s <%s>',
			$fn->_unescape_value($fn->value_to_string),
			$email->_unescape_value($email->value_to_string),
			);
	}
	elsif ($fn)
	{
		$label = $fn->_unescape_value($fn->value_to_string);
	}
	elsif ($email)
	{
		$label = $email->_unescape_value($email->value_to_string);
	}

	return RDF::iCalendar::Line->new(
		property => 'contact',
		value    => $label,
		type_parameters => {
			altrep   => "\"$uri\"",
			},
		);
}


sub _prop_export_geo
{
	my ($self, $model, $triple) = @_;
	
	if ($triple->object->is_literal)
	{
		return $self->_prop_export_simple($model, $triple);
	}
	elsif ($triple->object->is_resource
	and    $triple->object->uri =~ /^geo:(.+)$/i)
	{
		my $g = $1;
		return RDF::iCalendar::Line->new(
			property => 'geo',
			value    => [ split /[,;]/, $g, 2 ],
			);
	}
	
	my ($lat, $lon);
	{
		my @latitudes = grep
			{ $_->is_literal }
			$model->objects($triple->object, rdf_resource(RDF('first')));
		$lat = $latitudes[0]->literal_value if @latitudes;
		
		my @nodes = grep
			{ !$_->is_literal }
			$model->objects($triple->object, rdf_resource(RDF('next')));
		if (@nodes)
		{
			my @longitudes = grep
				{ $_->is_literal }
				$model->objects($nodes[0], rdf_resource(RDF('first')));
			$lon = $longitudes[0]->literal_value if @longitudes;
		}
	}
	
	return RDF::iCalendar::Line->new(
		property => 'geo',
		value    => [$lat||0, $lon||0],
		);
}

sub _prop_export_Person
{
	my ($self, $model, $triple) = @_;

	if ($triple->object->is_literal)
	{
		return $self->_prop_export_simple($model, $triple);
	}
	
	my $property = {
		I('organizer')  => 'organizer',
		IX('organizer') => 'organizer',
		I('attendee')   => 'attendee',
		IX('attendee')  => 'attendee',
		}->{ $triple->predicate->uri };
	
	my ($name, $email, $role, $partstat, $rsvp, $cutype, %thing_values);
	
	my %thing_meta = (
		'sent-by'        => [map {rdf_resource($_)} IX('sentBy'), I('sent-by')],
		'delegated-to'   => [map {rdf_resource($_)} IX('delegatedTo'), I('delegated-to')],
		'delegated-from' => [map {rdf_resource($_)} IX('delegatedFrom'), I('delegated-from')],
		);
	
	if ($triple->object->is_resource
	and $triple->object->uri =~ /^mailto:.+$/i)
	{
		$email = $triple->object->uri;
	}
	else
	{
		($name) = grep
			{ $_->is_literal }
			$model->objects_for_predicate_list($triple->object, rdf_resource(IX('cn')), rdf_resource(V('fn')));

		($role) = grep
			{ $_->is_literal }
			$model->objects_for_predicate_list($triple->object, rdf_resource(V('role')), rdf_resource(I('role')), rdf_resource(IX('role')));

		($partstat) = grep
			{ $_->is_literal }
			$model->objects_for_predicate_list($triple->object, rdf_resource(I('partstat')), rdf_resource(IX('partstat')));

		($rsvp) = grep
			{ $_->is_literal }
			$model->objects_for_predicate_list($triple->object, rdf_resource(I('rsvp')), rdf_resource(IX('rsvp')));

		($cutype) = grep
			{ $_->is_literal }
			$model->objects_for_predicate_list($triple->object, rdf_resource(VX('kind')), rdf_resource(I('cutype')), rdf_resource(IX('cutype')));

		($email) = $model->objects($triple->object, rdf_resource(V('email')));
		if ($email
		and ($email->is_blank or ($email->is_resource and $email->uri !~ /^mailto:/i)))
		{
			($email) = grep
				{ !$_->is_blank }
				$model->objects($email, rdf_resource(RDF('value')));
		}

		# This bit doesn't just work for sent-by, but also delegated-from/delegated-to
		while (my ($P, $X) = each %thing_meta)
		{
			my ($sentby) = $model->objects_for_predicate_list($triple->object, @$X);
			# if $sentby isn't an email address
			if (!defined $sentby) {}
			elsif ($sentby->is_blank or $sentby->is_resource && $sentby->uri !~ /^mailto:/i)
			{
				# Maybe it's a vcard:Email resource; if so, then get the rdf:value.
				my ($value) = grep
					{ !$_->is_blank }
					$model->objects($triple->object, rdf_resource(RDF('value')));
				if ($value)
				{
					$sentby = $value;
				}
				# If it's not then it might be a vcard:VCard...
				else
				{
					my ($sb_email) = $model->objects($sentby, rdf_resource(V('email')));
					if (!defined $sb_email) {}
					elsif ($sb_email->is_literal or $sb_email->is_resource && $sb_email->uri !~ /^mailto:/i)
					{
						$sentby = $sb_email;
					}
					else
					{
						my ($value) = grep
							{ !$_->is_blank }
							$model->objects($sb_email, rdf_resource(RDF('value')));
						if ($value)
						{
							$sentby = $value;
						}
					}
				}
			}
			
			$thing_values{$P} = $sentby if $sentby;
		}
	}
	
	my %params = ();
	$params{'cn'} = flatten_node($name)
		if defined $name;
	
	foreach my $P (keys %thing_meta)
	{
		$params{$P} = flatten_node($thing_values{$P})
			if defined $thing_values{$P};
	}

	$params{'cutype'} = flatten_node($cutype)
		if (defined $cutype and $property eq 'attendee');
	$params{'partstat'} = flatten_node($partstat)
		if (defined $partstat and $property eq 'attendee');
	$params{'role'} = flatten_node($role)
		if (defined $role and $property eq 'attendee');
	$params{'rsvp'} = flatten_node($rsvp)
		if (defined $rsvp and $property eq 'attendee');

	if (!$email)
	{
		$email = $name;
		$params{'value'} = 'TEXT';
	}
	
	return RDF::iCalendar::Line->new(
		property => $property,
		value    => flatten_node($email),
		type_parameters => \%params,
		);
}


1;