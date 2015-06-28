use strict;
use warnings;

use Test::More;
use LWP::Protocol::PSGI;
use CHI;
use Plack::Request;

use_ok('LWP::UserAgent::CHICaching');

my $app = sub {
	my $env = shift;
	my $req = Plack::Request->new($env);
	my %headers = ('Cache-Control' => 'max-age=100', 'Content-Type' => 'text/plain');
	my $vary = $req->param('vary');
	if (defined($vary)) {
		$headers{'Vary'} = $vary;
	}
	return [ 200, [ %headers ], [ "Hello dahut"] ] 
};

LWP::Protocol::PSGI->register($app);

my $cache = CHI->new( driver => 'Memory', global => 1 );

subtest 'Testing normal UA without Vary' => sub {
	my $uabasic = LWP::UserAgent::CHICaching->new(cache => $cache);
	my $res1 = $uabasic->get("http://localhost:3000/");
	isa_ok($res1, 'HTTP::Response');
	is($res1->content, 'Hello dahut', 'First request, got the right shout');
	is($res1->freshness_lifetime, 100, 'Freshness lifetime is 100 secs');
	is($uabasic->cache_vary($res1), 1, 'Vary header not present, so we can cache');
};

subtest 'Testing normal UA with Vary' => sub {
	my $uabasic = LWP::UserAgent::CHICaching->new(cache => $cache);
	my $res1 = $uabasic->get("http://localhost:3000/?vary=accept");
	isa_ok($res1, 'HTTP::Response');
	is($res1->content, 'Hello dahut', 'First request, got the right shout');
	is($res1->freshness_lifetime, 100, 'Freshness lifetime is 100 secs');
	is($uabasic->cache_vary($res1), 0, 'Vary header present, so we cant cache');
	is($res1->header('Vary'), 'accept', 'Check the actual header');
};

subtest 'Testing normal UA with Vary: *' => sub {
	my $uabasic = LWP::UserAgent::CHICaching->new(cache => $cache);
	my $res1 = $uabasic->get("http://localhost:3000/?vary=*");
	isa_ok($res1, 'HTTP::Response');
	is($res1->content, 'Hello dahut', 'First request, got the right shout');
	is($res1->freshness_lifetime, 100, 'Freshness lifetime is 100 secs');
	is($uabasic->cache_vary($res1), 0, 'Vary header present, so we cant cache');
	is($res1->header('Vary'), '*', 'Check the actual header');
};



done_testing;
