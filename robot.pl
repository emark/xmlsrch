#!/usr/bin/perl -w
use strict;
use DBI;
use LWP::UserAgent;
use XML::XPath;
use Encode;

my $VERSION='0.1';
my $database = "db/database";
my $dsn = "DBI:SQLite:dbname=$database;";
my $user = "";
my $pass = undef;
my $dbh = DBI->connect($dsn, $user, $pass);
if (!$dbh) {
    die "Can't connect to $dsn: $!";
}
my $webapp=LWP::UserAgent->new();
$webapp->agent("YXMLS $VERSION");
my $xml='';

&XMLRequest;

sub XMLRequest()
{
    my $reqid='';
    my $reqid_tag='';
    my $page=0;
    my $lastpage=0;#Ограничение на количество страниц в выборке
    my $xmldoc='';
    my @parsesite=();
    for ($page=0;$page<=$lastpage;$page++)
    {
        $xmldoc=<<DOC;
<?xml version="1.0" encoding="UTF-8"?> 	
<request> 	
	<query>(купить джинсы) интернет магазин</query>
        <maxpassages>4</maxpassages>
	<groupings>
		<groupby attr="d" mode="deep" groups-on-page="10"  docs-in-group="1" /> 	
	</groupings> 	
        <page>$page</page>
</request>
DOC
        #print $xmldoc;
        #формируем HTTP запрос
        my $req=HTTP::Request->new(POST=>'http://xmlsearch.yandex.ru/xmlsearch?user=emarkllc&key=03.82612598:b5ad3ae6a2ab55b9f578e3c9e7a4149a&lr=225');
        $req->content_type('application/xml');
        $req->content($xmldoc);
        my $response=$webapp->request($req);
        $xml=$response->content;
        $xml=XML::XPath->new(xml=>$xml);
        my $found= $xml -> findvalue ('/yandexsearch/response/found');
        my $error = $xml -> findvalue ('/yandexsearch/response/error');
        my @found = $xml -> findnodes ('/yandexsearch/response/results/grouping/group/doc');
        #$reqid=$xml->findvalue('/yandexsearch/response/reqid');
        #$reqid_tag="<reqid>$reqid</reqid>";
        #$page=$xml->findvalue('/yandexsearch/response/results/grouping/page');
        #print "RequestID: $reqid\n";
        print "Found: $found\n";
        print "Page: $page\n";
        if($error ne '')
        {
            print "Error: $error";
        }
        else
        {
            foreach (@found)
            {
                print $xml->findvalue('domain',$_);
                print "\t";
                print $xml->findvalue('charset',$_);
                print "\t";
                print $xml->findvalue('mime-type',$_);
                print "\t";
                print "\n";
                @parsesite=($xml->findvalue('domain',$_),
                            $xml->findvalue('charset',$_),
                            $xml->findvalue('mime-type',$_)
                            );
                if($parsesite[2] eq 'text/html')
                {
                    &SiteParse(@parsesite);
                }
            }
        }
    }
}

#Парсинг сайта
#Usage: DOMAIN,CHARSET
sub SiteParse()
{
    print "Starting parse site: $_[0]\n";
    my $content='';
    my $parse=HTTP::Request->new(GET=>"http://$_[0]");
    $parse->content_type('text/html');
    my $response=$webapp->request($parse);
    my $count=0;
    if($response->is_success)
    {
        $content=$response->content;
        Encode::from_to($content,$_[1],'utf-8');
        #print $content;
        print 'Searching contacts...';
        if($content=~/.*(КОНТАКТЫ|Контакты|контакты|О МАГАЗИНЕ|О магазине|О НАС|О нас|О КОМПАНИИ|О компании|о компании).*/)
        {
            print "Ok\n";
            $count++;
        }
        else
        {
            print "False\n";
        }
        print 'Searching catalog...';
        if($content=~/.*(КАТАЛОГ|Каталог|каталог).*/)
        {
            print "Ok\n";
            $count++;
        }
        else
        {
            print "False\n";
        }
        print 'Searching delivery options...';
        if($content=~/.*(ДОСТАВКА|Доставка|доставка|ОПЛАТА|Оплата|оплата|О ДОСТАВКЕ|О доставке|ДОСТАВКА И ОПЛАТА|Доставка и оплата|ОПЛАТА И ДОСТАВКА|Оплата и доставка).*/)
        {
            print "Ok\n";
            $count++;
        }
        else
        {
            print "False\n";
        }
        print "Total count: $count\n";
        if($count>=2)
        {
            &DBRec($_[0],$count);
        }
    }
    else
    {
        print $response->status_line."\n";
    }
}

#Процедура записи данных в БД
sub DBRec()
{
    my $sth = $dbh->prepare("INSERT INTO sites (id,url,date,count) VALUES(NULL,'$_[0]',DATE(),$_[1])");
    $sth->execute;
}

$dbh->disconnect;
