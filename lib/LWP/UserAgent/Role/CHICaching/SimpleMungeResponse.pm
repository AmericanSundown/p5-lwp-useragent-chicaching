package LWP::UserAgent::Role::CHICaching::SimpleMungeResponse;

use 5.006000;
use CHI;
use Moo::Role;
use Types::Standard qw(Bool);
our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.03';

=pod

=encoding utf-8

=head1 NAME

LWP::UserAgent::Role::CHICaching::SimpleMungeResponse - A role to manipulate the response when caching

=head1 SYNOPSIS

See L<LWP::UserAgent::Role::CHICaching>.


=head1 DESCRIPTION

L<LWP::UserAgent::Role::CHICaching> is a role for creating caching
user agents. There's some complexity around caching different variants
of the same resource (e.g. the same thing in different natural
languages, different serializations that is considered in L<Section
4.1 of RFC7234|http://tools.ietf.org/html/rfc7234#section-4.1> that
this role is factored out to address in the dumbest way possible: Just
don't cache when the problem arises.

To really solve this problem in a better way, you need to generate a
cache key based on not only the URI, but also on the content
(e.g. C<Content-Language: en>), and so, provide a better
implementation of the C<key> attribute, and then, you also need to
tell the system when it is OK to cache something with a C<Vary> header
by making the C<cache_vary> method smarter. See
L<LWP::UserAgent::Role::CHICaching::VaryNotAsterisk> for an example of
an alternative.

=head2 Attributes and Methods

=over

=item C<< key >>, C<< clear_key >>

The key to use for a response. This role will return the canonical URI of the
request as a string, which is a reasonable default.

=item C<< cache_vary >>

Will never allow a response with a C<Vary> header to be cached.

=back

=cut


sub finalize {
	return $_[1];
}

sub cache_set {
	my ($self, $res, $expires_in) = @_;
	$self->cache->set($self->key, $res, { expires_in => $expires_in });
}

1;
