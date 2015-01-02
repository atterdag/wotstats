#!/usr/bin/perl

use strict;
use warnings;
use HTTP::Tiny;
use XML::Simple qw(:strict);
use DBI;

my $version = '17';
my $url = 'http://www.wnefficiency.net/exp/expected_tank_values_' . $version . '.xml';
my $expected_tank_values = get_expected_tank_values($url);

my $dbhost = 'localhost';
my $dbport = '5432';
my $dbname = 'wotstats';
my $dbuser = 'wotstats';
my $dbpass = 'passw0rd';
my $dsn    = "dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport";
our $dbh = DBI->connect($dsn,$dbuser, $dbpass, {AutoCommit => 0, RaiseError => 1, PrintError => 1} ) || die 'DB connection failed: ' . $DBI::errstr;
print "DBI is version $DBI::VERSION, DBD::Pg is version $DBD::Pg::VERSION\n";

open (CSV, ">expected_tank_values_17.csv") || die 'Could not open CSV file for writing: ' . $!;
print CSV "IDNum,expFrag,expDamage,expSpot,expDef,expWinRate,countryid,tankid\n";

for my $IDNum ( keys( %{ $expected_tank_values->{'WN8'}->{'tank'} } ) ) {
	my $expFrag    = $expected_tank_values->{'WN8'}->{'tank'}->{$IDNum}->{'expFrag'};
	my $expDamage  = $expected_tank_values->{'WN8'}->{'tank'}->{$IDNum}->{'expDamage'};
	my $expSpot    = $expected_tank_values->{'WN8'}->{'tank'}->{$IDNum}->{'expSpot'};
	my $expDef     = $expected_tank_values->{'WN8'}->{'tank'}->{$IDNum}->{'expDef'};
	my $expWinRate = $expected_tank_values->{'WN8'}->{'tank'}->{$IDNum}->{'expWinRate'};
	my $countryid  = $expected_tank_values->{'WN8'}->{'tank'}->{$IDNum}->{'countryid'};
	my $tankid     = $expected_tank_values->{'WN8'}->{'tank'}->{$IDNum}->{'tankid'};

    set_expected_tank_values($IDNum,$expFrag,$expDamage,$expSpot,$expDef,$expWinRate,$countryid,$tankid);
    
  	print CSV $IDNum    . ','
	        . $expFrag    . ','
	        . $expDamage  . ','
	        . $expSpot    . ','
	        . $expDef     . ','
	        . $expWinRate . ','
	        . $countryid  . ','
	        . $tankid     . "\n";
}

close(CSV);

sub set_expected_tank_values {
    my $IDNum = $_[0];
    my $expFrag = $_[1];
    my $expDamage = $_[2];
    my $expSpot = $_[3];
    my $expDef = $_[4];
    my $expWinRate = $_[5];
    my $countryid = $_[6];
    my $tankid = $_[7];
    
    my $SQL = 'SELECT ?::text';
    $dbh->do($SQL, undef, "DBD::Pg version $DBD::Pg::VERSION");
    
    my $count_stmt = 'SELECT COUNT(*) FROM public.expected_tank_values_'. $version . ' WHERE IDNum=\'' . $IDNum . '\'';
    my $count = $dbh->selectrow_array( $count_stmt );
    if ($dbh->err()){
        die $count_stmt . ' failed : ' . $dbh->errstr();
    }
   
    our($stmt);
    if ( $count eq 0 ) {
        $stmt = 'INSERT INTO public.expected_tank_values_' . $version . ' ( IDNum, expFrag, expDamage, expSpot, expDef, expWinRate, countryid, tankid )
                  VALUES (\'' . $IDNum . '\',
                          \'' . $expFrag . '\',
                          \'' . $expDamage . '\',
                          \'' . $expSpot . '\',
                          \'' . $expDef . '\',
                          \'' . $expWinRate . '\',
                          \'' . $countryid . '\',
                          \'' . $tankid . '\')';
    } elsif ( $count eq 1 ) {
        $stmt = 'UPDATE public.expected_tank_values_'. $version . '
                  SET expFrag=\''    . $expFrag . '\',
                      expDamage=\''  . $expDamage . '\',
                      expSpot=\''    . $expSpot . '\',
                      expDef=\''     . $expDef . '\',
                      expWinRate=\'' . $expWinRate . '\',
                      countryid=\''  . $countryid . '\',
                      tankid=\''     . $tankid . '\'
                  WHERE IDNum=\'' . $IDNum . '\'';
    }
    
    my $rv = $dbh->do( $stmt ) || die $DBI::errstr;
    if ($dbh->err()){
         die $stmt . ' failed: ' . $dbh->errstr();
    }
    $dbh->commit;
}

sub get_expected_tank_values {
	my $response = HTTP::Tiny->new->get( $_[0] );
	die "Failed!\n" unless $response->{success};
	my $content = $response->{content} if length $response->{content};
	return XMLin(
		$content,
		KeyAttr    => { tank => 'IDNum' },
		ForceArray => ['tank']
    );
}

# Dumps entire hash for debugging
#use Data::Dumper;
#print Dumper($expected_tank_values);

exit(0);
