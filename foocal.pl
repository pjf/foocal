#!/usr/bin/perl -w
use 5.010;
use strict;
use warnings;
use autodie;
use utf8::all;

use constant KIWI_SHEET => '0AhJdYvDd5jsgdDZkMHIxNndMcGdhZjJRZlF4Tm1vcHc';
use constant TIME_COLUMN => 1;
use constant ROOM_ROW    => 1;
use constant DEBUG => 1;

use Net::Google::Spreadsheets;
use Config::Tiny;

my $config = Config::Tiny->new->read('auth.ini');

my $google = Net::Google::Spreadsheets->new(
    username => $config->{Google}{username},
    password => $config->{Google}{password},
);

debug("Logging in...");

my $spreadsheet = $google->spreadsheet({
    key => KIWI_SHEET,
});

my $worksheet = $spreadsheet->worksheet({ title => 'Sheet1'});

debug("Getting cells...");

my @cells = $worksheet->cells({
    'min-row' => 1,
    'max-row' => 20,
    'min-col' => 1,
    'max-col' => 20,
});

debug("Entering The Matrix...");

my @matrix;

foreach my $cell (@cells) {
    # MATRIX: [Time][Room]
    $matrix[$cell->row][$cell->col] = $cell->content;
}

# Now walk through each session time...

print_header();

foreach my $session (@matrix) {
    print_room_timetable($session);
}

say "</body></html>";

sub print_header {
    say q{
        <!DOCTYPE html>
        <html><head>
        <link type="text/css" rel="stylesheet" href="style.css" />
        </head>
        <body>
    };
}

sub print_room_timetable {
    my ($session) = @_;

    # XXX - OH NOES MAGIC NUMBERS

    my $time = $session->[1];

    say "<h1>$time</h1>";
    say "<!-- We all feel REALLY dirty for doing this... -->";
    say "<table>";

    for (my $i = 2; $i < @$session; $i++) {
        my $room    = $matrix[ROOM_ROW][$i];
        my $session = $session->[$i];
        say "<tr><th>$room</th><td>$session</td></tr>";
    }
    say "</table>";
}

sub debug {
    return if not DEBUG;
    warn "@_\n";
}

__END__

# Our first non-empty row will contain our room names.

say "Here are our rooms!" if DEBUG;

for (my $i = 1; $i < @{ $matrix[ROOM_ROW] }; $i++) {
    next if not defined $cell;
    say "$i: $cell" if DEBUG;

}

# say Dumper \@matrix;

__END__

my @times = get_times();
my @rooms = get_rooms();

use Data::Dumper;
say Dumper \@times, \@rooms;

for (my $t=0; $t < @times; $t++) {
    my $time = $times[$t] or next;
    say "== Schedule for $time ==\n";
    for (my $r=0; $r < @rooms; $r++) {
        my $room = $rooms[$r] or next;

        warn "Grabbing $t:$r ($room)\n";

        my $talk = $worksheet->cell({ col => $t, row => $r })->content;
        say "$room: $talk";
    }
}

sub get_times {
    my $row = 1;

    # Get all our times...

    my @times;

    while (my $time = $worksheet->cell( { col => TIME_COLUMN, row => $row })->content ) {
        say $time;
        $times[$row] = $time;
        $row++;
    }

    return @times;
}

sub get_rooms {
    my $col = 1;

    my @rooms;

    while (my $room = $worksheet->cell( { col => $col, row => ROOM_ROW })->content ) {
        say $room;
        $rooms[$col] = $room;
        $col++;
    }

    return @rooms;
}
