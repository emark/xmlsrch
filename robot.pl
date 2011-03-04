#!/usr/bin/perl -w
use strict;
use DBI;
use LWP::UserAgent;
use XML::XPath;

my $database = "db/database";
my $dsn = "DBI:SQLite:dbname=$database;";
my $user = "";
my $pass = undef;
my $dbh = DBI->connect($dsn, $user, $pass);
if (!$dbh) {
    die "Can't connect to $dsn: $!";
}
my $webapp=LWP::UserAgent->new();
$webapp->agent('YaXMLSch 0.1');
my $xml='';

&XMLRequest();


sub XMLRequest()
{
    my $reqid='';
    my $reqid_tag='';
    my $xmldoc=<<DOC;
<?xml version="1.0" encoding="UTF-8"?> 	
<request> 	
	<query>(купить джинсы) интернет магазин (ОГРН доставка)</query>
	<groupings>
		<groupby attr="d" mode="deep" groups-on-page="5"  docs-in-group="1" /> 	
	</groupings> 	
<page>0</page>
$reqid_tag
</request>
DOC
    
    #формируем HTTP запрос
    my $req=HTTP::Request->new(POST=>'http://xmlsearch.yandex.ru/xmlsearch?user=emarkllc&key=03.82612598:b5ad3ae6a2ab55b9f578e3c9e7a4149a&lr=225');
    $req->content_type('application/xml');
    $req->content($xmldoc);
    my $response=$webapp->request($req);
    $xml=$response->content;
    $xml=XML::XPath->new(xml=>$xml);
    my $found= $xml -> findvalue ('/yandexsearch/response/found');
    my $error = $xml -> findvalue ('/yandexsearch/response/error');
    my @found = $xml -> findnodes ("/yandexsearch/response/results/grouping/group/doc");
    print "Found: $found\n";
    if($error ne '')
    {
        print "Error: $error";
    }
    else
    {
        foreach (@found)
        {
            print $xml->findvalue('domain',$_);
            print "\n";
        }
    }
}

#Процедура записи данных в БД
sub DBRec()
{
    my $sth = $dbh->prepare("SELECT * FROM sites");
    $sth->execute;
    while (my @row = $sth->fetchrow_array)
    {
        printf "%-20s : %s\n", $sth->{NAME}->[$_], $row[$_] for 0..@row-1;
        print "\n";
    }
}

$dbh->disconnect;
