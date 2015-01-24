#!/usr/bin/perl

use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use DBI;

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

my $stmt = 'SELECT tank_id FROM public.tanks';
my $tank_ids = $dbh->selectcol_arrayref( $stmt );
if ($dbh->err()){
    die $stmt . ' failed : ' . $dbh->errstr();
}

foreach my $tank_id (@{ $tank_ids } ) {
	create_tank_stats_common_table($tank_id);
    my @tank_statistics_types = qw(all clan team company );
    for my $tank_statistics_type ( @tank_statistics_types ) {
        create_tank_stats_table($tank_id,$tank_statistics_type);
    }
}

sub create_tank_stats_common_table {
    my ($tank_id) = $_[0];

    my $SQL = 'SELECT ?::text';
    $dbh->do($SQL, undef, "DBD::Pg version $DBD::Pg::VERSION");
    my $count_stmt = 'SELECT count(*) FROM information_schema.tables WHERE table_catalog = \'wotstats\' AND table_schema = \'public\' AND table_type = \'BASE TABLE\' AND table_name = \'tank_stats_' . $tank_id .'_common\'';
    my $count = $dbh->selectrow_array( $count_stmt );
    if ($dbh->err()){
        die $count_stmt . ' failed : ' . $dbh->errstr();
    }

    our($stmt);
    if ( $count eq 0 ) {
        $stmt = '
CREATE TABLE tank_stats_' . $tank_id .'_common (
  account_id integer NOT NULL,
  tank_id integer NOT NULL,
  max_xp integer,
  max_frags integer,
  frags integer,
  mark_of_mastery integer,
  in_garage boolean,
  CONSTRAINT tank_stats_' . $tank_id .'_common_global_pkey PRIMARY KEY (account_id, tank_id)
)
WITH (
  OIDS=FALSE,
  autovacuum_enabled=true
);
ALTER TABLE tank_stats_' . $tank_id .'_common
  OWNER TO wotstatsadmins;';
        print 'creating table: tank_stats_' . $tank_id .'_common' . "\n";
        #print $stmt . "\n";
        my $rv = $dbh->do( $stmt ) || die $DBI::errstr;
        if ($dbh->err()){
            die $stmt . ' failed: ' . $dbh->errstr();
        }
        $dbh->commit;
    } elsif ( $count eq 1 ) {
        print 'table tank_stats_' . $tank_id .'_common already exists' . "\n";
    }
}

sub create_tank_stats_table {
    my ($tank_id) = $_[0];
    my ($type)  = $_[1];

    my $SQL = 'SELECT ?::text';
    $dbh->do($SQL, undef, "DBD::Pg version $DBD::Pg::VERSION");
    my $count_stmt = 'SELECT count(*) FROM information_schema.tables WHERE table_catalog = \'wotstats\' AND table_schema = \'public\' AND table_type = \'BASE TABLE\' AND table_name = \'tank_stats_' . $tank_id . '_' . $type .'\'';
    my $count = $dbh->selectrow_array( $count_stmt );
    if ($dbh->err()){
        die $count_stmt . ' failed : ' . $dbh->errstr();
    }

    our($stmt);
    if ( $count eq 0 ) {
        $stmt = '
CREATE TABLE tank_stats_' . $tank_id . '_' . $type .' (
  account_id integer NOT NULL,
  tank_id integer NOT NULL,
  battles integer,
  wins integer,
  losses integer,
  draws integer,
  survived_battles integer,
  xp integer,
  battle_avg_xp integer,
  frags integer,
  spotted integer,
  capture_points integer,
  shots integer,
  hits integer,
  piercings integer,
  damage_dealt integer,
  damage_received integer,
  dropped_capture_points integer,
  hits_percents integer,
  wn8 integer,
  CONSTRAINT tank_stats_' . $tank_id . '_' . $type .'_global_pkey PRIMARY KEY (account_id, tank_id)
)
WITH (
  OIDS=FALSE,
  autovacuum_enabled=true
);
ALTER TABLE tank_stats_' . $tank_id . '_' . $type .'
  OWNER TO wotstatsadmins;';
        print 'creating table: tank_stats_' . $tank_id . '_' . $type . "\n";
        my $rv = $dbh->do( $stmt ) || die $DBI::errstr;
        if ($dbh->err()){
            die $stmt . ' failed: ' . $dbh->errstr();
        }
        $dbh->commit;
    } elsif ( $count eq 1 ) {
        print 'table tank_stats_' . $tank_id . '_' . $type .' already exists' . "\n";
    }
}

exit(0);
