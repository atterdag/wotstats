#!/usr/bin/perl

use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use DBI;
# Dumps entire hash for debugging
#use Data::Dumper;

my $application_id="d0a293dc77667c9328783d489c8cef73";
my $dbhost = 'localhost';
my $dbport = '5432';
my $dbname = 'wotstats';
my $dbuser = 'wotstats';
my $dbpass = 'passw0rd';
my $dsn    = "dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport";
our $dbh = DBI->connect($dsn,$dbuser, $dbpass, {AutoCommit => 0, RaiseError => 1, PrintError => 1} ) || die 'DB connection failed: ' . $DBI::errstr;
print "DBI is version $DBI::VERSION, DBD::Pg is version $DBD::Pg::VERSION\n";

my $url = 'http://api.worldoftanks.eu/wot/encyclopedia/tanks/?application_id=' . $application_id;
my $tanks = getJSON($url);
my @tank_attributes = qw( nation_i18n name image image_small nation is_premium type_i18n contour_image short_name_i18n name_i18n type );
#print Dumper($tanks);
#exit(0);
foreach my $tank_id ( keys(%{$tanks->{'data'}}) ) {
    my(%tank);
    $tank{'tank_id'} = $tank_id;
    foreach my $tank_attribute ( @tank_attributes ) { 
        $tank{$tank_attribute} = $tanks->{'data'}->{$tank_id}->{$tank_attribute};
    }
    if ( $tank{'is_premium'} eq "0" ) {
    	$tank{'is_premium'} = "FALSE";
    } else {
    	$tank{'is_premium'} = "TRUE";
    }
    set_tank(%tank);
}

sub set_tank {
    my (%tank) = @_;

    my $SQL = 'SELECT ?::text';
    $dbh->do($SQL, undef, "DBD::Pg version $DBD::Pg::VERSION");

    my $count_stmt = 'SELECT COUNT(*) FROM public.tanks WHERE tank_id=' . $tank{'tank_id'};
    my $count = $dbh->selectrow_array( $count_stmt );
    if ($dbh->err()){
        die $count_stmt . ' failed : ' . $dbh->errstr();
    }

    our($stmt);
    if ( $count eq 0 ) {
        $stmt = 'INSERT INTO public.tanks ( tank_id, nation_i18n, name, image, image_small, nation, is_premium, type_i18n, contour_image, short_name_i18n, name_i18n, type )
                  VALUES ('   . $tank{'tank_id'} . ',
                          \'' . $tank{'nation_i18n'} . '\',
                          \'' . $tank{'name'} . '\',
                          \'' . $tank{'image'} . '\',
                          \'' . $tank{'image_small'} . '\',
                          \'' . $tank{'nation'} . '\',
                          '   . $tank{'is_premium'} . ',
                          \'' . $tank{'type_i18n'} . '\',
                          \'' . $tank{'contour_image'} . '\',
                          \'' . $tank{'short_name_i18n'} . '\',
                          \'' . $tank{'name_i18n'} . '\',
                          \'' . $tank{'type'} . '\')';
        print "inserting entry for: " . $tank{'tank_id'} . "\n";
    } elsif ( $count eq 1 ) {
        $stmt = 'UPDATE public.tanks
                  SET nation_i18n=\''     . $tank{'nation_i18n'} . '\',
                      name=\''            . $tank{'name'} . '\',
                      image=\''           . $tank{'name'} . '\',
                      image_small=\''     . $tank{'image'} . '\',
                      nation=\''          . $tank{'nation'} . '\',
                      is_premium='        . $tank{'is_premium'} . ',
                      type_i18n=\''       . $tank{'type_i18n'} . '\',
                      contour_image=\''   . $tank{'contour_image'} . '\',
                      short_name_i18n=\'' . $tank{'short_name_i18n'} . '\',
                      name_i18n=\''       . $tank{'name_i18n'} . '\',
                      type=\''            . $tank{'type'} . '\'
                  WHERE tank_id=\'' . $tank{'tank_id'} . '\'';
        print "updating entry for: " . $tank{'tank_id'} . "\n";
    }
    #print $stmt . "\n";
    my $rv = $dbh->do( $stmt ) || die $DBI::errstr;
    if ($dbh->err()){
        die $stmt . ' failed: ' . $dbh->errstr();
    }
    $dbh->commit;
}

sub getJSON {
    my $response = HTTP::Tiny->new->get( $_[0] );
    die "Failed!\n" unless $response->{success};
    my $content = $response->{content} if length $response->{content};
    my $json = JSON->new->ascii;
    return $json->decode($content);
}

exit(0);
