#!usr/bin/perl -w
use strict;
use Mojo::UserAgent;
use Mojo::DOM;

my $xmldoc=<<DOC;
<?xml version="1.0" encoding="UTF-8"?> 	
<request> 	
	<query>вебпокупка</query>
        <maxpassages>1</maxpassages>
	<groupings>
		<groupby attr="d" mode="deep" groups-on-page="2"  docs-in-group="1" /> 	
	</groupings> 	
        <page>1</page>
</request>
DOC

my $pubkey='http://xmlsearch.yandex.ru/xmlsearch?user=emarkllc&key=03.82612598:b5ad3ae6a2ab55b9f578e3c9e7a4149a&lr=225';
my $ua=Mojo::UserAgent->new;
my $tx=Mojo::DOM->new;

$tx=$ua->post($pubkey=>{'Content-Type'=>'application/xml'}=>$xmldoc)->res->dom;
my @test=();
$tx->find('url')->each(sub{push @test,$_->text});
my $test=@test;
print $test,@test;