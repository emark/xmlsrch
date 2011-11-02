#!usr/bin/perl -w
#Script based on Mojolicious framework
use strict;
use Mojo::UserAgent;
use Mojo::DOM;
use DBIx::Custom;
my $VERSION='0.1';

my $dbi=DBIx::Custom->connect(dsn=>"dbi:SQLite:dbname=db/database");

print "Starting script at ".localtime(time);
print "\nClearing database\n";
$dbi->delete_all(table=>'sites');
$dbi->delete_all(table=>'errors');

my $pubkey='http://xmlsearch.yandex.ru/xmlsearch?user=emarkllc&key=03.82612598:b5ad3ae6a2ab55b9f578e3c9e7a4149a&lr=225';
my $ua=Mojo::UserAgent->new;
my $tx=Mojo::DOM->new;
my @res=();#XML responde

open(FILE,"< query.txt") || die "Can't open query file";
my @query=<FILE>;
close FILE;

foreach my $query(@query){
  chomp $query;
  my ($query,$lastpage)=split(';',$query);
  for (my $page=0;$page<=$lastpage;$page++){
    print "Create XML Schema doc for page: $page\n";
    my $xmldoc=<<XML;
<?xml version="1.0" encoding="UTF-8"?> 	
<request> 	
	<query>$query</query>
	<groupings>
		<groupby attr="d" mode="deep" groups-on-page="2"  docs-in-group="1" />
	</groupings> 	
        <page>$page</page>
</request>
XML

    print "POST query\n";
    $tx=$ua->post($pubkey=>{'Content-Type'=>'application/xml'}=>$xmldoc)->res->dom;
    $tx->find('domain')->each(sub{push @res, $_->text});
    my $err='';
    $tx->find('error')->first(sub{$err=$_->text});
    if($err eq ''){
      foreach (@res){
        $dbi->insert({domain=>$_,page=>$page},table=>'sites');
      }
    }else{
      print "Ops, I see error. Write it\n";
      $dbi->insert({error=>$err,describe=>"page:{$page},query:{$query}"},table=>'errors');
    }
    
  }#for $page
}#foreach @query
print "Close db connection";
$dbi=undef;