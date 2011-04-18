#!/usr/bin/perl -w
use Jabber::SimpleSend qw(send_jabber_message);
send_jabber_message({
                       user     => 'xmlsrch@jabber.org',
                       password => 'x0A8Acs1gj',
                       target   => 'emark@jabber.org',
                       subject  => '',
                       message  => "Must be wrong end.\nPie Good"});