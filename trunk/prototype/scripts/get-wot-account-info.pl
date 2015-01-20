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

my $SQL = 'SELECT ?::text';
$dbh->do($SQL, undef, "DBD::Pg version $DBD::Pg::VERSION");

my $stmt = 'SELECT account_id FROM public.account_list';
my $account_ids = $dbh->selectcol_arrayref( $stmt );
if ($dbh->err()){
    die $stmt . ' failed : ' . $dbh->errstr();
}

my @info_common_attributes = qw( clan_id client_language global_rating created_at updated_at last_battle_time logout_at );
my @info_statistics_max_attributes = qw( max_xp_tank_id frags max_xp max_damage_vehicle max_damage_tank_id max_damage max_frags max_frags_tank_id trees_cut );
my @info_statistics_attributes = qw( battles wins losses draws survived_battles tanking_factor base_xp xp battle_avg_xp avg_damage_blocked avg_damage_assisted avg_damage_assisted_track avg_damage_assisted_radio hits_percents frags spotted capture_points dropped_capture_points shots hits piercings explosion_hits no_damage_direct_hits_received damage_dealt damage_received direct_hits_received piercings_received explosion_hits_received );

foreach my $account_id (@{ $account_ids } ) {
	my $url = 'http://api.worldoftanks.eu/wot/account/info/?application_id=' . $application_id . '&account_id=' . $account_id;
	my $info = getJSON($url);
	
	my(%info_common);
	$info_common{'account_id'} = $account_id;
	foreach my $info_common_attribute ( @info_common_attributes ) { 
		$info_common{$info_common_attribute} = $info->{'data'}->{$account_id}->{$info_common_attribute};
	}

	foreach my $info_common_key (keys(%info_common)) {  
		if ( $info_common{$info_common_key} eq "" ) {
			$info_common{$info_common_key}='null';
		}	
	}

#	print Dumper(%info_common);
	set_info_common(%info_common);

	my(%info_statistics_max);
	$info_statistics_max{'account_id'} = $account_id;
	foreach my $info_statistics_max_attribute ( @info_statistics_max_attributes ) { 
		$info_statistics_max{$info_statistics_max_attribute} = $info->{'data'}->{$account_id}->{'statistics'}->{$info_statistics_max_attribute};
	}

	foreach my $info_statistics_max_key (keys(%info_statistics_max)) {  
		if ( $info_statistics_max{$info_statistics_max_key} eq "" ) {
			$info_statistics_max{$info_statistics_max_key}='0';
		}	
	}

#	print Dumper(%info_statistics_max);
	set_info_statistics_max(%info_statistics_max);

	my @info_statistics_types = qw(all clan team company historical );
	for my $info_statistics_type ( @info_statistics_types ) {
		
		my(%info_statistics);
		$info_statistics{'account_id'} = $account_id;
		$info_statistics{'info_statistics_type'} = $info_statistics_type;
		
		foreach my $info_statistics_attribute ( @info_statistics_attributes ) { 
			$info_statistics{$info_statistics_attribute} = $info->{'data'}->{$account_id}->{'statistics'}->{$info_statistics_type}->{$info_statistics_attribute};
		}

		foreach my $info_statistics_key (keys(%info_statistics)) {  
			if ( $info_statistics{$info_statistics_key} eq "" ) {
				$info_statistics{$info_statistics_key}='0';
			}	
		}

#		print Dumper(%info_statistics);
		set_info_statistics(%info_statistics);
	}
}

sub set_info_common {
	my (%info_common) = @_;

	my $SQL = 'SELECT ?::text';
	$dbh->do($SQL, undef, "DBD::Pg version $DBD::Pg::VERSION");

	my $count_stmt = 'SELECT COUNT(*) FROM public.account_info_common WHERE account_id=\'' . $info_common{'account_id'} . '\'';
	my $count = $dbh->selectrow_array( $count_stmt );
	if ($dbh->err()){
		die $count_stmt . ' failed : ' . $dbh->errstr();
	}

	our($stmt);
	if ( $count eq 0 ) {
		$stmt = 'INSERT INTO public.account_info_common ( account_id, 
		                                          clan_id,
		                                          client_language,
		                                          global_rating,
		                                          created_at,
		                                          updated_at,
		                                          last_battle_time,
		                                          logout_at )
				  VALUES ('              . $info_common{'account_id'} . ',
					      '              . $info_common{'clan_id'} . ',
					      \''            . $info_common{'client_language'} . '\',
					      '              . $info_common{'global_rating'} . ',
					      to_timestamp(' . $info_common{'created_at'} . '),
					      to_timestamp(' . $info_common{'updated_at'} . '),
					      to_timestamp(' . $info_common{'last_battle_time'} . '),
					      to_timestamp(' . $info_common{'logout_at'} . '))';
        print "setting common info for: " . $info_common{'account_id'} . "\n";
	} elsif ( $count eq 1 ) {
		$stmt = 'UPDATE public.account_info_common
				  SET clan_id='                       . $info_common{'clan_id'} . ',
                      client_language=\''             . $info_common{'client_language'} . '\',
                      global_rating='                 . $info_common{'global_rating'} . ',
                      created_at=to_timestamp('       . $info_common{'created_at'} . '),
                      updated_at=to_timestamp('       . $info_common{'updated_at'} . '),
                      last_battle_time=to_timestamp(' . $info_common{'last_battle_time'} . '),
                      logout_at=to_timestamp('        . $info_common{'logout_at'} . ')
                  WHERE account_id=\'' . $info_common{'account_id'} . '\'';
	}
	my $rv = $dbh->do( $stmt ) || die $DBI::errstr;
	if ($dbh->err()){
		die $stmt . ' failed: ' . $dbh->errstr();
	}
	$dbh->commit;
}

sub set_info_statistics_max {
	my (%info_statistics_max) = @_;

	my $SQL = 'SELECT ?::text';
	$dbh->do($SQL, undef, "DBD::Pg version $DBD::Pg::VERSION");

	my $count_stmt = 'SELECT COUNT(*) FROM public.account_info_statistics_max WHERE account_id=\'' . $info_statistics_max{'account_id'} . '\'';
	my $count = $dbh->selectrow_array( $count_stmt );
	if ($dbh->err()){
		die $count_stmt . ' failed : ' . $dbh->errstr();
	}

	our($stmt);
	if ( $count eq 0 ) {
		$stmt = 'INSERT INTO public.account_info_statistics_max ( account_id, 
														  max_xp_tank_id,
														  max_xp,
														  max_damage_vehicle,
														  max_damage_tank_id,
														  max_damage,
														  max_frags,
														  max_frags_tank_id,
														  trees_cut )
				  VALUES (' . $info_statistics_max{'account_id'} . ',
					      ' . $info_statistics_max{'max_xp_tank_id'} . ',
					      ' . $info_statistics_max{'max_xp'} . ',
					      ' . $info_statistics_max{'max_damage_vehicle'} . ',
					      ' . $info_statistics_max{'max_damage_tank_id'} . ',
					      ' . $info_statistics_max{'max_damage'} . ',
					      ' . $info_statistics_max{'max_frags'} . ',
					      ' . $info_statistics_max{'max_frags_tank_id'} . ',
					      ' . $info_statistics_max{'trees_cut'} . ')';
        print "setting max statistics for: " . $info_statistics_max{'account_id'} . "\n";
	} elsif ( $count eq 1 ) {
		$stmt = 'UPDATE public.account_info_statistics_max
				  SET max_xp_tank_id='     . $info_statistics_max{'max_xp_tank_id'} . ',
                      max_xp='             . $info_statistics_max{'max_xp'} . ',
                      max_damage_vehicle=' . $info_statistics_max{'max_damage_vehicle'} . ',
                      max_damage_tank_id=' . $info_statistics_max{'max_damage_tank_id'} . ',
                      max_damage='         . $info_statistics_max{'max_damage'} . ',
                      max_frags='          . $info_statistics_max{'max_frags'} . ',
                      max_frags_tank_id='  . $info_statistics_max{'max_frags_tank_id'} . ',
                      trees_cut='          . $info_statistics_max{'trees_cut'} . '
                  WHERE account_id='       . $info_statistics_max{'account_id'};
        print "updating max statistics for: " . $info_statistics_max{'account_id'} . "\n";
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

	my $count_stmt = 'SELECT COUNT(*) FROM public.account_info_statistics_' . $info_statistics{'info_statistics_type'} . ' WHERE account_id=\'' . $info_statistics{'account_id'} . '\'';
	my $count = $dbh->selectrow_array( $count_stmt );
	if ($dbh->err()){
		die $count_stmt . ' failed : ' . $dbh->errstr();
	}

	our($stmt);
	if ( $count eq 0 ) {
		$stmt = 'INSERT INTO public.account_info_statistics_' . $info_statistics{'info_statistics_type'} . ' ( account_id, 
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
		$stmt = 'UPDATE public.account_info_statistics_' . $info_statistics{'info_statistics_type'} . '
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
