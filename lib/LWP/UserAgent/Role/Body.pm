package LWP::UserAgent::Role::Body;

use 5.006000;
use CHI;
use Moo::Role;
use Types::Standard qw(Bool);

sub finalize {
	return $_[1];
}

sub cache_set {
	my ($self, $res, $expires_in) = @_;
	$self->cache->set($self->key, $res, { expires_in => $expires_in });
}

1;
