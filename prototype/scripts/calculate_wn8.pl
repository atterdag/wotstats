#!/usr/bin/perl

use strict;
use warnings;
use DBI;
# Dumps entire hash for debugging
use Data::Dumper;

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
	my $tank_ids_stmt = 'SELECT tank_id FROM public.account_tanks WHERE account_id=\'' . $account_id . '\'';
	my $tank_ids = $dbh->selectcol_arrayref( $tank_ids_stmt );
	if ($dbh->err()){
	    die $stmt . ' failed : ' . $dbh->errstr();
	}
	our (%tank_statistic);
	$tank_statistic{'account_id'} = $account_id;
	foreach my $tank_id ( @{$tank_ids} ) {
		$tank_statistic{'tank_id'} = $tank_id;
		$tank_statistic{'wn8'} = get_wn8(%tank_statistic);
#		print Dumper(%tank_statistic);
		print 'inserting wn8 ' . $tank_statistic{'wn8'} . ' for tank_id ' . $tank_statistic{'tank_id'} . ' for account_id ' . $tank_statistic{'account_id'} . "\n";
		set_wn8(%tank_statistic);
	}
}

sub get_wn8 {
    my (%tank_statistic) = @_;
	my $tank_stats_table_name = 'public.tank_stats_' . $tank_statistic{'tank_id'} . '_all';
	
    my $SQL = 'SELECT ?::text';
    $dbh->do($SQL, undef, "DBD::Pg version $DBD::Pg::VERSION");

    my $step_one_data_stmt = 'SELECT ' . $tank_stats_table_name . '.battles,
                                         ' . $tank_stats_table_name . '.damage_dealt,
                                         ' . $tank_stats_table_name . '.spotted,
                                         ' . $tank_stats_table_name . '.frags,
                                         ' . $tank_stats_table_name . '.dropped_capture_points,
                                         ' . $tank_stats_table_name . '.wins,
                                         public.expected_tank_values_17.expdamage,
                                         public.expected_tank_values_17.expspot,
                                         public.expected_tank_values_17.expfrag,
                                         public.expected_tank_values_17.expdef,
                                         public.expected_tank_values_17.expwinrate
                                    FROM ' . $tank_stats_table_name . '
                                      INNER JOIN public.expected_tank_values_17 
                                        ON ' . $tank_stats_table_name . '.tank_id=public.expected_tank_values_17.IDNum 
                                    WHERE ' . $tank_stats_table_name . '.account_id=\'' . $tank_statistic{'account_id'} . '\'';

    my $step_one_data_result = $dbh->selectrow_hashref( $step_one_data_stmt );
    if ($dbh->err()){
        die $step_one_data_stmt . ' failed : ' . $dbh->errstr();
    }
        
    # Calcuate averages for tank
    our ($avgDmg, $avgSpot, $avgFrag, $avgDef, $avgWinRate);
    
    if ( $step_one_data_result->{'damage_dealt'} eq "0" ) { $avgDmg     = 0 } else {
		$avgDmg     = $step_one_data_result->{'damage_dealt'}           / $step_one_data_result->{'battles'};
    } 
    if ( $step_one_data_result->{'damage_dealt'} eq "0" ) { $avgSpot    = 0 } else {
		$avgSpot    = $step_one_data_result->{'spotted'}                / $step_one_data_result->{'battles'};
    } 
    if ( $step_one_data_result->{'damage_dealt'} eq "0" ) { $avgFrag    = 0 } else {
		$avgFrag    = $step_one_data_result->{'frags'}                  / $step_one_data_result->{'battles'};
    } 
    if ( $step_one_data_result->{'damage_dealt'} eq "0" ) { $avgDef     = 0 } else {
		$avgDef     = $step_one_data_result->{'dropped_capture_points'} / $step_one_data_result->{'battles'};
    } 
    if ( $step_one_data_result->{'damage_dealt'} eq "0" ) { $avgWinRate = 0 } else {
		$avgWinRate = $step_one_data_result->{'wins'}                   / $step_one_data_result->{'battles'};
    } 

	print "$avgDmg, $avgSpot, $avgFrag, $avgDef, $avgWinRate\n";
	
	# Step 1 - Calculate relative performance according to expected values
	our ($rDAMAGE, $rSPOT, $rFRAG, $rDEF, $rWIN );
	if ( $avgDmg     eq "0" ) { $rDAMAGE = 0 } else {
		my $rDAMAGE = $avgDmg     / $step_one_data_result->{'expdamage'};
	}
	if ( $avgSpot    eq "0" ) { $rSPOT   = 0 } else {
		my $rSPOT   = $avgSpot    / $step_one_data_result->{'expspot'};
	}
	if ( $avgFrag    eq "0" ) { $rFRAG   = 0 } else {
		$rFRAG   = $avgFrag    / $step_one_data_result->{'expfrag'};
	}
	if ( $avgDef     eq "0" ) { $rDEF    = 0 } else {
		$rDEF    = $avgDef     / $step_one_data_result->{'expdef'};
	}
	if ( $avgWinRate eq "0" ) { $rWIN    = 0 } else {
		$rWIN    = $avgWinRate / $step_one_data_result->{'expwinrate'};
	}

	print "$rDAMAGE, $rSPOT, $rFRAG, $rDEF, $rWIN\n";
	
	# Step 2 - Sets the zero point for the ratios.
	my $rWINc    = max(0,                      ($rWIN    - 0.71) / (1 - 0.71) );
    my $rDAMAGEc = max(0,                      ($rDAMAGE - 0.22) / (1 - 0.22) );
	my $rFRAGc   = max(0, min($rDAMAGEc + 0.2, ($rFRAG   - 0.12) / (1 - 0.12)));
	my $rSPOTc   = max(0, min($rDAMAGEc + 0.1, ($rSPOT   - 0.38) / (1 - 0.38)));
	my $rDEFc    = max(0, min($rDAMAGEc + 0.1, ($rDEF    - 0.10) / (1 - 0.10)));

	# Step 3 takes the weighted (in Step 1) and normalized (in step 2) performance ratios and processes them through the coefficients determined for the final formula
	my $wn8 = 	980 * $rDAMAGEc + 210 * $rDAMAGEc * $rFRAGc + 155 * $rFRAGc * $rSPOTc + 75 * $rDEFc * $rFRAGc + 145 * min(1.8, $rWINc);
	
	return($wn8);
}

sub set_wn8 {
    my (%tank_statistic) = @_;
	my $tank_stats_table_name = 'public.tank_stats_' . $tank_statistic{'tank_id'} . '_all';
	
    my $SQL = 'SELECT ?::text';
    $dbh->do($SQL, undef, "DBD::Pg version $DBD::Pg::VERSION");

    my $stmt = 'UPDATE public.tank_stats_' . $tank_statistic{'tank_id'} . '_all
                                SET wn8=' . $tank_statistic{'wn8'} . '
                                WHERE account_id=\'' . $tank_statistic{'account_id'} . '\'';
    my $rv = $dbh->do( $stmt ) || die $DBI::errstr;
    if ($dbh->err()){
        die $stmt . ' failed: ' . $dbh->errstr();
    }
    $dbh->commit;
    
}

sub max ($$) { $_[$_[0] < $_[1]] }
sub min ($$) { $_[$_[0] > $_[1]] }

exit(0);
