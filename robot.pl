#!/usr/bin/perl -w
use strict;
use DBI;

my $database = "db/database";
my $dsn = "DBI:SQLite:dbname=$database;";
my $user = "";
my $pass = undef; # Get password from /etc/my.cnf config file
my $dbh = DBI->connect($dsn, $user, $pass);
if (!$dbh) {
    die "Can't connect to $dsn: $!";
}

# Prepare statement for execution
my $sth = $dbh->prepare("SELECT * FROM sites");

# Execute statement
$sth->execute;

# Retrieve all rows produced by statement execution
while (my @row = $sth->fetchrow_array) {

    # Print name and value of each field in this record
    printf "%-20s : %s\n", $sth->{NAME}->[$_], $row[$_] for 0..@row-1;
    print "\n";
}

# Disconnect database connection
$dbh->disconnect;
