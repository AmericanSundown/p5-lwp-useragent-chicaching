use Test::More;
use Plack::Runner;
use Test::Exception;

my %counter;
$counter{'DAHUT'} = 0;

my $app = sub {
	my $env = shift;
	my $req = Plack::Request->new($env);
	my $query = $req->param('query');
	$counter{$query}++;
	die "This request has been done before, shouldn't run the app again" if ($counter{$query} > 1);
	return [ 200, [ 'Cache-Control' => 'max-age=4', 'Content-Type' => 'text/plain'], [ "Hello $query"] ] 
};

my $runner = Plack::Runner->new;
$runner->parse_options('--host=localhost');
$runner->run($app);

my $cache = CHI->new( driver => 'Memory', global => 1 );
my $ua = LWP::UserAgent::CHICaching->new(cache => $cache);

my $res1 = $ua->get("http://localhost:5000/?query=DAHUT");
is $res1->content, "Hello DAHUT";

my $res2;
lives_ok { $ua->get("http://localhost:5000/?query=DAHUT") } "Didn't die, so it probably came from cache";
is $res2->content, "Hello DAHUT";

done_testing;
