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

my $underscore = '_';
my @alphanum = ('a'..'z','0'..'9');
my $alphanum = '{'. join(',',@alphanum).'}';
#my @search_patterns = (<$alphanum$alphanum$alphanum>, <$underscore$alphanum$alphanum>, <$alphanum$underscore$alphanum>, <$alphanum$alphanum$underscore>);
my @search_patterns = ('atterdag','Martoow','w00t_tK','afoaa','Wabbiit','Fenan');

foreach my $search_pattern (@search_patterns) {
	my $url =
	  'http://api.worldoftanks.eu/wot/account/list/?application_id=' . $application_id . '&search=' . $search_pattern;
	my $list_accounts = getJSON($url);

	foreach my $account ( @{ $list_accounts->{'data'} } ) {
        my $account_id = $account->{'account_id'};
		my $nickname = $account->{'nickname'};
		set_account($account_id,$nickname);
	}
}
sub set_account {
	my $account_id = $_[0];
	my $nickname = $_[1];

	my $SQL = 'SELECT ?::text';
	$dbh->do($SQL, undef, "DBD::Pg version $DBD::Pg::VERSION");

	my $count_stmt = 'SELECT COUNT(*) FROM public.account_list WHERE account_id=\'' . $account_id . '\'';
	my $count = $dbh->selectrow_array( $count_stmt );
	if ($dbh->err()){
		die $count_stmt . ' failed : ' . $dbh->errstr();
	}

	our($stmt);
	if ( $count eq 0 ) {
		$stmt = 'INSERT INTO public.account_list ( account_id, nickname )
                  VALUES (\'' . $account_id . '\',
                          \'' . $nickname . '\')';
        print "setting account for: " . $account_id . "\n";
	} elsif ( $count eq 1 ) {
		$stmt = 'UPDATE public.account_list
                  SET nickname=\''   . $nickname . '\'
                  WHERE account_id=\'' . $account_id . '\'';
        print "updating account for: " . $account_id . "\n";
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
