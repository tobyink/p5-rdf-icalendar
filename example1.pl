use lib "lib";
use lib "../HTML-HTML5-Parser/lib";
use lib "../HTML-Microformats/lib";
use lib "../RDF-vCard/lib";

use HTML::Microformats;
use RDF::TrineShortcuts;
use RDF::iCalendar::Exporter;

my $hcalendar = <<'HTML';
<div class="vcalendar">

  <div class="vevent">
    <h1 class="uid" id="xmas">
      <span class="summary">Christmas</span> Schedule
    </h1>
    <abbr class="dtstart" title="0001-12-25" style="display:none"></abbr>
    <p class="comment rrule"><span class="freq">Yearly</span>
    period of festive merriment.</p>
    <div class="attendee vcard">
      <b class="role">
        <abbr title="REQ-PARTICIPANT">Required for merriment:</abbr>
      </b><br>
      <span class="fn">
        <span class="honorific-prefix nickname">Santa</span>
        <span class="given-name">Claus</span>
      </span>
      (<span class="adr><span class="region">North Pole</span></span>)
    </div>
	 <p class=geo>12;34</p>
  </div>
  
    <div class="vtodo">
      <h2 class="uid" id="shopping">Shopping</h2>
      <abbr class="dtstart" title="2008-12-01">In December</abbr>, don't forget
      to <span class="summary">buy everyone their presents</span> before the
      shops shut on <abbr class="due" title="2008-12-24T16:00:00">Christmas
      Eve</abbr>!
    </div>
    
    <div class="vevent">
      <h2 id="jones" class="uid summary">Jones' Christmas Lunch</h2>
      <p class="comment">The Joneses have been having a wonderful lunch 
      <abbr class="rrule" title="FREQ=YEARLY">every year</abbr> at
      <abbr class="dtstart" title="2003-12-25T13:00:00Z">1pm for the last
      few years</abbr>.</p>
      <p><span class="attendee">Everyone</span>'s invited.</p>
    </div>
  
  <div class="vevent">
    <h2 class="summary">Boxing Day</h2>
    <p class="comment">
      <abbr class="rrule" title="FREQ=YEARLY">Every year</abbr>
      <abbr class="dtstart" title="0001-12-26">the day after</abbr>
      <a class="related-to" href="#xmas" rel="vcalendar-sibling">Christmas</a>
      is Boxing Day. Nobody knows quite why this day is called that.
    </p>
	 <p class="contact organizer attendee vcard">
		<a class="fn email" href="mailto:alice@example.net">Alice Jones</a>
		<span class="role">required</span>
		<span class="sent-by vcard">
			<a class="fn email" href="mailto:bob@example.net">Bob Jones</a>
		</span>
	 </p>
  </div>
  
</div>
HTML

my $doc = HTML::Microformats->new_document($hcalendar, 'http://hcal.example.net/')->assume_all_profiles;
print rdf_string($doc->model =>'Turtle');
print "========\n";
my @cals = RDF::iCalendar::Exporter->new->export_calendars($doc->model);
print "========\n";
print $_ foreach @cals ;
