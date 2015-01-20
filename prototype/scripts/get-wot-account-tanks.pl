#!/usr/bin/perl

use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use DBI;

my $application_id="d0a293dc77667c9328783d489c8cef73";
my $dbhost = 'localhost';
my $dbport = '5432';
my $dbname = 'wotstats';
my $dbuser = 'wotstats';
my $dbpass = 'passw0rd';
my $dsn    = "dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport";
our $dbh = DBI->connect($dsn,$dbuser, $dbpass, {AutoCommit => 0, RaiseError => 1, PrintError => 1} ) || die 'DB connection failed: ' . $DBI::errstr;
print "DBI is version $DBI::VERSION, DBD::Pg is version $DBD::Pg::VERSION\n";

my $SQL = 'SELECT ?::text';
$dbh->do($SQL, undef, "DBD::Pg version $DBD::Pg::VERSION");

my $stmt = 'SELECT account_id FROM public.account_list';
my $account_ids = $dbh->selectcol_arrayref( $stmt );
if ($dbh->err()){
    die $stmt . ' failed : ' . $dbh->errstr();
}
foreach my $account_id (@{ $account_ids } ) {
    my $url = 'http://api.worldoftanks.eu/wot/account/tanks/?application_id=' . $application_id . '&account_id=' . $account_id;
    my $tanks = getJSON($url);
    for my $tank (keys(@{$tanks->{'data'}->{$account_id}})) {
    	my(%tank);
	    $tank{'account_id'} = $account_id;
	    $tank{'tank_id'}         = $tanks->{'data'}->{$account_id}->[$tank]->{'tank_id'};;
	    $tank{'mark_of_mastery'} = $tanks->{'data'}->{$account_id}->[$tank]->{'mark_of_mastery'};
	    $tank{'battles'}         = $tanks->{'data'}->{$account_id}->[$tank]->{'statistics'}->{'battles'};
	    $tank{'wins'}            = $tanks->{'data'}->{$account_id}->[$tank]->{'statistics'}->{'wins'};
	    set_account_tanks(%tank);
    }
}

sub set_account_tanks {
    my (%tank) = @_;

    my $SQL = 'SELECT ?::text';
    $dbh->do($SQL, undef, "DBD::Pg version $DBD::Pg::VERSION");

    my $count_stmt = 'SELECT COUNT(*) FROM public.account_tanks WHERE account_id=\'' . $tank{'account_id'} . '\' AND tank_id=\'' . $tank{'tank_id'} . '\'';
    my $count = $dbh->selectrow_array( $count_stmt );
    if ($dbh->err()){
        die $count_stmt . ' failed : ' . $dbh->errstr();
    }

    our($stmt);
    if ( $count eq 0 ) {
        $stmt = 'INSERT INTO public.account_tanks ( account_id, 
                                                    tank_id,
                                                    mark_of_mastery,
                                                    wins,
                                                    battles )
                  VALUES (' . $tank{'account_id'} . ',
                          ' . $tank{'tank_id'} . ',
                          ' . $tank{'mark_of_mastery'} . ',
                          ' . $tank{'wins'} . ',
                          ' . $tank{'battles'} . ')';
        print "setting account tank for account_id:" . $tank{'account_id'} . ", tank_id:". $tank{'tank_id'} . "\n";
    } elsif ( $count eq 1 ) {
        $stmt = 'UPDATE public.account_tanks
                  SET mark_of_mastery=' . $tank{'mark_of_mastery'} . ',
                      wins='            . $tank{'wins'} . ',
                      battles='         . $tank{'battles'} . '
                  WHERE account_id=' . $tank{'account_id'} . '
                   AND tank_id=' . $tank{'tank_id'};
        print "updating account tank for account_id:" . $tank{'account_id'} . ", tank_id:". $tank{'tank_id'} . "\n";
    }
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
