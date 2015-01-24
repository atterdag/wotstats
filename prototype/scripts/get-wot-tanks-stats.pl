#!/usr/bin/perl

use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use DBI;
# Dumps entire hash for debugging
use Data::Dumper;

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

my @tank_common_attributes = qw( tank_id max_xp max_frags frags mark_of_mastery in_garage );
my @tank_statistics_attributes = qw( battles wins losses draws survived_battles xp battle_avg_xp frags spotted capture_points shots hits piercings damage_dealt damage_received dropped_capture_points hits_percents );


foreach my $account_id (@{ $account_ids } ) {
    my $url = 'http://api.worldoftanks.eu/wot/tanks/stats/?application_id=' . $application_id . '&account_id=' . $account_id;
    my $tanks = getJSON($url);

    my(%tanks_common);
    $tanks_common{'account_id'} = $account_id;
    foreach my $tank (keys(@{$tanks->{'data'}->{$account_id}})) {
        foreach my $tank_common_attribute ( @tank_common_attributes ) { 
            $tanks_common{$tank_common_attribute} = $tanks->{'data'}->{$account_id}->[$tank]->{$tank_common_attribute};
        }

	    if ( $tanks_common{'in_garage'} eq "" ) {
	        $tanks_common{'in_garage'} = "FALSE";
	    } else {
	        $tanks_common{'in_garage'} = "TRUE";
	    }

        if ( $tanks_common{'frags'} eq "" ) {
            $tanks_common{'frags'} = "null";
        }
	
#       print Dumper(%tanks_common);
        set_tanks_common(%tanks_common);

	    my @tank_statistics_types = qw(all clan team company );
	    for my $tank_statistics_type ( @tank_statistics_types ) {
	        
	        my(%tank_statistics);
	        $tank_statistics{'account_id'} = $account_id;
            $tank_statistics{'tank_id'} = $tanks_common{'tank_id'};
	        $tank_statistics{'tank_statistics_type'} = $tank_statistics_type;
	        foreach my $tank_statistics_attribute ( @tank_statistics_attributes ) { 
	            $tank_statistics{$tank_statistics_attribute} = $tanks->{'data'}->{$account_id}->[$tank]->{$tank_statistics_type}->{$tank_statistics_attribute};
	        }
	
#           print Dumper(%tank_statistics);
	        set_tank_statistics(%tank_statistics);
	    }
    }
}

sub set_tanks_common {
    my (%tanks_common) = @_;

    my $SQL = 'SELECT ?::text';
    $dbh->do($SQL, undef, "DBD::Pg version $DBD::Pg::VERSION");

    my $count_stmt = 'SELECT COUNT(*) FROM public.tank_stats_' . $tanks_common{'tank_id'} . '_common WHERE account_id=\'' . $tanks_common{'account_id'} . '\'';
    my $count = $dbh->selectrow_array( $count_stmt );
    if ($dbh->err()){
        die $count_stmt . ' failed : ' . $dbh->errstr();
    }

    our($stmt);
    if ( $count eq 0 ) {
        $stmt = 'INSERT INTO public.tank_stats_' . $tanks_common{'tank_id'} . '_common ( account_id, 
                                                                                         tank_id,
                                                                                         max_xp,
                                                                                         max_frags,
                                                                                         frags,
                                                                                         mark_of_mastery,
                                                                                         in_garage )
                  VALUES (' . $tanks_common{'account_id'} . ',
                          ' . $tanks_common{'tank_id'} . ',
                          ' . $tanks_common{'max_xp'} . ',
                          ' . $tanks_common{'max_frags'} . ',
                          ' . $tanks_common{'frags'} . ',
                          ' . $tanks_common{'mark_of_mastery'} . ',
                          ' . $tanks_common{'in_garage'} . ')';
        print 'inserting into tank_stats_' . $tanks_common{'tank_id'} . '_common for: ' . $tanks_common{'account_id'} . "\n";
    } elsif ( $count eq 1 ) {
        $stmt = 'UPDATE public.tank_stats_' . $tanks_common{'tank_id'} . '_common
                  SET max_xp='          . $tanks_common{'max_xp'} . ',
                      max_frags='       . $tanks_common{'max_frags'} . ',
                      frags='           . $tanks_common{'frags'} . ',
                      mark_of_mastery=' . $tanks_common{'mark_of_mastery'} . ',
                      in_garage='       . $tanks_common{'in_garage'} . '
                  WHERE account_id=\'' . $tanks_common{'account_id'} . '\'';
        print 'updating tank_stats_' . $tanks_common{'tank_id'} . '_common for: ' . $tanks_common{'account_id'} . "\n";
    }
    my $rv = $dbh->do( $stmt ) || die $DBI::errstr;
    if ($dbh->err()){
        die $stmt . ' failed: ' . $dbh->errstr();
    }
    $dbh->commit;
}

sub set_tank_statistics {
    my (%tank_statistics) = @_;

    my $SQL = 'SELECT ?::text';
    $dbh->do($SQL, undef, "DBD::Pg version $DBD::Pg::VERSION");

    my $count_stmt = 'SELECT COUNT(*) FROM public.tank_stats_' . $tank_statistics{'tank_id'} . '_' . $tank_statistics{'tank_statistics_type'} .' WHERE account_id=\'' . $tank_statistics{'account_id'} . '\'';
    my $count = $dbh->selectrow_array( $count_stmt );
    if ($dbh->err()){
        die $count_stmt . ' failed : ' . $dbh->errstr();
    }

    our($stmt);
    if ( $count eq 0 ) {
        $stmt = 'INSERT INTO public.tank_stats_' . $tank_statistics{'tank_id'} . '_' . $tank_statistics{'tank_statistics_type'} .' ( account_id, 
                                                                                                                                     tank_id,
                                                                                                                                     battles,
                                                                                                                                     wins,
                                                                                                                                     losses,
                                                                                                                                     draws,
                                                                                                                                     survived_battles,
                                                                                                                                     xp,
                                                                                                                                     battle_avg_xp,
                                                                                                                                     frags,
                                                                                                                                     spotted,
                                                                                                                                     capture_points,
                                                                                                                                     shots,
                                                                                                                                     hits,
                                                                                                                                     damage_dealt,
                                                                                                                                     damage_received,
                                                                                                                                     dropped_capture_points,
                                                                                                                                     hits_percents )
                  VALUES (' . $tank_statistics{'account_id'} . ',
                          ' . $tank_statistics{'tank_id'} . ',
                          ' . $tank_statistics{'battles'} . ',
                          ' . $tank_statistics{'wins'} . ',
                          ' . $tank_statistics{'losses'} . ',
                          ' . $tank_statistics{'draws'} . ',
                          ' . $tank_statistics{'survived_battles'} . ',
                          ' . $tank_statistics{'xp'} . ',
                          ' . $tank_statistics{'battle_avg_xp'} . ',
                          ' . $tank_statistics{'frags'} . ',
                          ' . $tank_statistics{'spotted'} . ',
                          ' . $tank_statistics{'capture_points'} . ',
                          ' . $tank_statistics{'shots'} . ',
                          ' . $tank_statistics{'hits'} . ',
                          ' . $tank_statistics{'damage_dealt'} . ',
                          ' . $tank_statistics{'damage_received'} . ',
                          ' . $tank_statistics{'dropped_capture_points'} . ',
                          ' . $tank_statistics{'hits_percents'} . ')';
        print 'inserting into tank_stats_' . $tank_statistics{'tank_id'} . '_' . $tank_statistics{'tank_statistics_type'} .' statistics for: ' . $tank_statistics{'account_id'} . "\n";
    } elsif ( $count eq 1 ) {
        $stmt = 'UPDATE public.tank_stats_' . $tank_statistics{'tank_id'} . '_' . $tank_statistics{'tank_statistics_type'} .'
                  SET battles='                . $tank_statistics{'battles'} . ',
                      wins='                   . $tank_statistics{'wins'} . ',
                      losses='                 . $tank_statistics{'losses'} . ',
                      draws='                  . $tank_statistics{'draws'} . ',
                      survived_battles='       . $tank_statistics{'survived_battles'} . ',
                      xp='                     . $tank_statistics{'xp'} . ',
                      battle_avg_xp='          . $tank_statistics{'battle_avg_xp'} . ',
                      frags='                  . $tank_statistics{'frags'} . ',
                      spotted='                . $tank_statistics{'spotted'} . ',
                      capture_points='         . $tank_statistics{'capture_points'} . ',
                      shots='                  . $tank_statistics{'shots'} . ',
                      hits='                   . $tank_statistics{'hits'} . ',
                      damage_dealt='           . $tank_statistics{'damage_dealt'} . ',
                      damage_received='        . $tank_statistics{'damage_received'} . ',
                      dropped_capture_points=' . $tank_statistics{'dropped_capture_points'} . ',
                      hits_percents='          . $tank_statistics{'hits_percents'} . '
                  WHERE account_id=' . $tank_statistics{'account_id'};
        print 'updating tank_stats_' . $tank_statistics{'tank_id'} . '_' . $tank_statistics{'tank_statistics_type'} .' statistics for: ' . $tank_statistics{'account_id'} . "\n";
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
