#!/usr/bin/perl

#use strict;
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

my @tanks_common_attributes = qw( tank_id max_xp max_frags frags mark_of_mastery in_garage );
my @tanks_statistics_attributes = qw( battles wins losses draws survived_battles tanking_factor base_xp xp battle_avg_xp avg_damage_blocked avg_damage_assisted avg_damage_assisted_track avg_damage_assisted_radio hits_percents frags spotted capture_points dropped_capture_points shots hits piercings explosion_hits no_damage_direct_hits_received damage_dealt damage_received direct_hits_received piercings_received explosion_hits_received );

foreach my $account_id (@{ $account_ids } ) {
    my $url = 'http://api.worldoftanks.eu/wot/tanks/stats/?application_id=' . $application_id . '&account_id=' . $account_id;
    my $tanks = getJSON($url);

    my(%tanks_common);
    $tanks_common{'account_id'} = $account_id;
    foreach my $tank (keys(@{$tanks->{'data'}->{$account_id}})) {
        foreach my $tanks_common_attribute ( @tanks_common_attributes ) { 
            $tanks_common{$tanks_common_attribute} = $tanks->{'data'}->{$account_id}->[$tank]->{$tanks_common_attribute};
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

    }

#    my @info_statistics_types = qw(all clan team company );
#    for my $info_statistics_type ( @info_statistics_types ) {
#        
#        my(%info_statistics);
#        $info_statistics{'account_id'} = $account_id;
#        $info_statistics{'info_statistics_type'} = $info_statistics_type;
#        
#        foreach my $info_statistics_attribute ( @info_statistics_attributes ) { 
#            $info_statistics{$info_statistics_attribute} = $info->{'data'}->{$account_id}->{'statistics'}->{$info_statistics_type}->{$info_statistics_attribute};
#        }
#
#        foreach my $info_statistics_key (keys(%info_statistics)) {  
#            if ( $info_statistics{$info_statistics_key} eq "" ) {
#                $info_statistics{$info_statistics_key}='0';
#            }   
#        }
#
##       print Dumper(%info_statistics);
#        set_info_statistics(%info_statistics);
#    }
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
        print "inserting statistics for " . $tanks_common{'account_id'} . ' in tank_stats_' . $tanks_common{'tank_id'} . '_commo' . "\n";
    } elsif ( $count eq 1 ) {
        $stmt = 'UPDATE public.tank_stats_' . $tanks_common{'tank_id'} . '_common
                  SET max_xp='          . $tanks_common{'max_xp'} . ',
                      max_frags='       . $tanks_common{'max_frags'} . ',
                      frags='           . $tanks_common{'frags'} . ',
                      mark_of_mastery=' . $tanks_common{'mark_of_mastery'} . ',
                      in_garage='       . $tanks_common{'in_garage'} . '
                  WHERE account_id=\'' . $tanks_common{'account_id'} . '\'';
        print "updating statistics for " . $tanks_common{'account_id'} . ' in tank_stats_' . $tanks_common{'tank_id'} . '_commo' . "\n";
    }
    my $rv = $dbh->do( $stmt ) || die $DBI::errstr;
    if ($dbh->err()){
        die $stmt . ' failed: ' . $dbh->errstr();
    }
    $dbh->commit;
}

sub set_info_statistics {
    my (%info_statistics) = @_;

    my $SQL = 'SELECT ?::text';
    $dbh->do($SQL, undef, "DBD::Pg version $DBD::Pg::VERSION");

    my $count_stmt = 'SELECT COUNT(*) FROM public.info_statistics_' . $info_statistics{'info_statistics_type'} . ' WHERE account_id=\'' . $info_statistics{'account_id'} . '\'';
    my $count = $dbh->selectrow_array( $count_stmt );
    if ($dbh->err()){
        die $count_stmt . ' failed : ' . $dbh->errstr();
    }

    our($stmt);
    if ( $count eq 0 ) {
        $stmt = 'INSERT INTO public.info_statistics_' . $info_statistics{'info_statistics_type'} . ' ( account_id, 
                                                          battles,
                                                          wins,
                                                          losses,
                                                          draws,
                                                          survived_battles,
                                                          tanking_factor,
                                                          base_xp,
                                                          xp,
                                                          battle_avg_xp,
                                                          avg_damage_blocked,
                                                          avg_damage_assisted,
                                                          avg_damage_assisted_track,
                                                          avg_damage_assisted_radio,
                                                          hits_percents,
                                                          frags,
                                                          spotted,
                                                          capture_points,
                                                          dropped_capture_points,
                                                          shots,
                                                          hits,
                                                          piercings,
                                                          explosion_hits,
                                                          no_damage_direct_hits_received,
                                                          damage_dealt,
                                                          damage_received,
                                                          direct_hits_received,
                                                          piercings_received,
                                                          explosion_hits_received )
                  VALUES (' . $info_statistics{'account_id'} . ',
                          ' . $info_statistics{'battles'} . ',
                          ' . $info_statistics{'wins'} . ',
                          ' . $info_statistics{'losses'} . ',
                          ' . $info_statistics{'draws'} . ',
                          ' . $info_statistics{'survived_battles'} . ',
                          ' . $info_statistics{'tanking_factor'} . ',
                          ' . $info_statistics{'base_xp'} . ',
                          ' . $info_statistics{'xp'} . ',
                          ' . $info_statistics{'battle_avg_xp'} . ',
                          ' . $info_statistics{'avg_damage_blocked'} . ',
                          ' . $info_statistics{'avg_damage_assisted'} . ',
                          ' . $info_statistics{'avg_damage_assisted_track'} . ',
                          ' . $info_statistics{'avg_damage_assisted_radio'} . ',
                          ' . $info_statistics{'hits_percents'} . ',
                          ' . $info_statistics{'frags'} . ',
                          ' . $info_statistics{'spotted'} . ',
                          ' . $info_statistics{'capture_points'} . ',
                          ' . $info_statistics{'dropped_capture_points'} . ',
                          ' . $info_statistics{'shots'} . ',
                          ' . $info_statistics{'hits'} . ',
                          ' . $info_statistics{'piercings'} . ',
                          ' . $info_statistics{'explosion_hits'} . ',
                          ' . $info_statistics{'no_damage_direct_hits_received'} . ',
                          ' . $info_statistics{'damage_dealt'} . ',
                          ' . $info_statistics{'damage_received'} . ',
                          ' . $info_statistics{'direct_hits_received'} . ',
                          ' . $info_statistics{'piercings_received'} . ',
                          ' . $info_statistics{'explosion_hits_received'} . ')';
        print "setting " . $info_statistics{'info_statistics_type'} . " statistics for: " . $info_statistics{'account_id'} . "\n";
    } elsif ( $count eq 1 ) {
        $stmt = 'UPDATE public.info_statistics_' . $info_statistics{'info_statistics_type'} . '
                  SET battles='                        . $info_statistics{'battles'} . ',
                      wins='                           . $info_statistics{'wins'} . ',
                      losses='                         . $info_statistics{'losses'} . ',
                      draws='                          . $info_statistics{'draws'} . ',
                      survived_battles='               . $info_statistics{'survived_battles'} . ',
                      tanking_factor=\''               . $info_statistics{'tanking_factor'} . '\',
                      base_xp='                        . $info_statistics{'base_xp'} . ',
                      xp='                             . $info_statistics{'xp'} . ',
                      battle_avg_xp='                  . $info_statistics{'battle_avg_xp'} . ',
                      avg_damage_blocked=\''           . $info_statistics{'avg_damage_blocked'} . '\',
                      avg_damage_assisted=\''          . $info_statistics{'avg_damage_assisted'} . '\',
                      avg_damage_assisted_track=\''    . $info_statistics{'avg_damage_assisted_track'} . '\',
                      avg_damage_assisted_radio=\''    . $info_statistics{'avg_damage_assisted_radio'} . '\',
                      hits_percents='                  . $info_statistics{'hits_percents'} . ',
                      frags='                          . $info_statistics{'frags'} . ',
                      spotted='                        . $info_statistics{'spotted'} . ',
                      capture_points='                 . $info_statistics{'capture_points'} . ',
                      dropped_capture_points='         . $info_statistics{'dropped_capture_points'} . ',
                      shots='                          . $info_statistics{'shots'} . ',
                      hits='                           . $info_statistics{'hits'} . ',
                      piercings='                      . $info_statistics{'piercings'} . ',
                      explosion_hits='                 . $info_statistics{'explosion_hits'} . ',
                      no_damage_direct_hits_received=' . $info_statistics{'no_damage_direct_hits_received'} . ',
                      damage_dealt='                   . $info_statistics{'damage_dealt'} . ',
                      damage_received='                . $info_statistics{'damage_received'} . ',
                      direct_hits_received='           . $info_statistics{'direct_hits_received'} . ',
                      piercings_received='             . $info_statistics{'piercings_received'} . ',
                      explosion_hits_received='        . $info_statistics{'explosion_hits_received'} . '
                  WHERE account_id=' . $info_statistics{'account_id'};
        print "updating " . $info_statistics{'info_statistics_type'} . " statistics for: " . $info_statistics{'account_id'} . "\n";
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
