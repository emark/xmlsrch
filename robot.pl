#!/usr/bin/perl -w
use strict;
use DBI;
use LWP::UserAgent;
use XML::XPath;
use Encode;
binmode(STDOUT, ":utf8");

my $VERSION='0.2';
my $database = "db/database";
my $dsn = "DBI:SQLite:dbname=$database;";
my $user = "";
my $pass = undef;
my $dbh = DBI->connect($dsn, $user, $pass);
if (!$dbh) {
    die "Can't connect to $dsn: $!";
}
my $sth =$dbh->prepare("DELETE FROM sites")->execute;#Очистка БД перед запуском
my $webapp=LWP::UserAgent->new();
$webapp->agent("YXMLS $VERSION");
my $xml='';
my $srchposition=0;#Позиция в поиске

&XMLRequest;

sub XMLRequest()
{
    my $reqid='';
    my $reqid_tag='';
    my $page=0;
    my $lastpage=0;#Ограничение на количество страниц в выборке
    my $xmldoc='';
    my @query='';
    my @parsesite=();
    open (FILE,"query.qr")|| die '';
        @query=<FILE>;
    close FILE;
    for ($page=$page;$page<=$lastpage;$page++)
    {
        $xmldoc=<<DOC;
<?xml version="1.0" encoding="UTF-8"?> 	
<request> 	
	<query>$query[0]</query>
        <maxpassages>4</maxpassages>
	<groupings>
		<groupby attr="d" mode="deep" groups-on-page="2"  docs-in-group="1" /> 	
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
        #print $xml;exit;
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
                $srchposition++;
                print $xml->findvalue('domain',$_);
                print "...";
                #print $xml->findvalue('charset',$_);
                #print "\t";
                #print $xml->findvalue('mime-type',$_);
                #print "\t";
                @parsesite=($xml->findvalue('domain',$_),
                            $xml->findvalue('charset',$_),
                            $xml->findvalue('mime-type',$_),
                            $xml->findvalue('title/hlword',$_),
                            $xml->findvalue('passages/passage/hlword',$_),
                            );
                if($parsesite[2] eq 'text/html')
                {
                    my $titlecheck=0;
                    my $passagcheck=0;
                    my $totalkeys=0;
                    my $ukey='';
                    my $parseaccess=0;
                    #проверка на наличие ключевых слов в заголовке и пассаже
                    foreach my $key(@query)
                    {
                        chomp $key;
                        my $ukey=decode_utf8($key);
                        
                        #print "$ukey=";
                        #print "$parsesite[3]";
                        
                        if($parsesite[3]=~/.*($ukey).*/)
                        {
                            $titlecheck++;
                            #print "..Ok\n";
                        }
                        if($parsesite[4]=~/.*($ukey).*/)
                        {
                            $passagcheck++;
                            #print "..Ok\n";
                        }
                        $totalkeys++;
                    }
                    $totalkeys=($totalkeys-1)*2;
                    $parseaccess=($titlecheck+$passagcheck)/$totalkeys;
                    #print "\n$titlecheck\t$passagcheck\t$totalkeys\t$parseaccess\n";
                    if($parseaccess>=0.5)
                    {
                        print "Parse: \n";
                        &SiteParse(@parsesite);
                    }
                    else
                    {
                        print "Not parse\n";
                    }
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
    $sth = $dbh->prepare("INSERT INTO sites (id,url,date,count,position) VALUES(NULL,'$_[0]',DATE(),$_[1],$srchposition)");
    $sth->execute;
}

$dbh->disconnect;
