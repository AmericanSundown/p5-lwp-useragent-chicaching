package LWP::UserAgent::CHICaching;

use 5.006000;
use strict;
use warnings;

use CHI;
use Moo;
use Types::Standard qw(Str InstanceOf);
use Types::URI -all;
extends 'LWP::UserAgent';


our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.001';

=pod

=encoding utf-8

=head1 NAME

LWP::UserAgent::CHICaching - LWP::UserAgent with caching based on CHI

=head1 SYNOPSIS

The usual way of using L<LWP::UserAgent>, really, just pass a C<cache>
parameter with a L<CHI> object to the constructor:

  my $cache = CHI->new( driver => 'Memory', global => 1 );
  my $ua = LWP::UserAgent::CHICaching->new(cache => $cache);
  my $res1 = $ua->get("http://localhost:3000/?query=DAHUT");

=head1 DESCRIPTION

This is YA caching user agent. When the client makes a request to the
server, sometimes the response should be cached, so that no actual
request has to be sent at all, or possibly just a request to validate
the cache. HTTP 1.1 defines how to do this. This module makes it
possible to use the very flexible L<CHI> module to manage such a
cache.

But why? Mainly because I wanted to use L<CHI> facilities, and partly
because I wanted to focus on HTTP 1.1 features.

=head2 Attributes and Methods

=over

=item C<< cache >>

Used to set the C<CHI> object to be used as cache in the constructor.

=item C<< key >>, C<< clear_key >>

The key to use for a response. Defaults to the canonical URI of the
request. May make sense to set differently in the future, but should
probably be left alone for now.

=item C<< request_uri >>

The Request-URI of the request. When set, it will clear the C<key>,
but should probably be left to be used internally for now.

=item C<< request >>

Overriding L<LWP::UserAgent>'s request method.

=back

=cut

has cache => (
				  is => 'ro',
				  isa => InstanceOf['CHI::Driver'],
				  required => 1,
				 );

has key => (
				is => 'rw',
				isa => Str,
				lazy => 1,
				clearer => 1,
				builder => '_build_key'
			  );


has request_uri => (
						  is =>'rw',
						  isa => Uri,
						  coerce => 1,
						  trigger => \&clear_key,
						 );

sub _build_key {
	my $self = shift;
	return $self->request_uri->canonical->as_string;
}

sub request {
	my $self = shift;
	my @args = @_;
	my $request = $args[0];

	return $self->SUPER::request(@args) if $request->method ne 'GET';

	$self->request_uri($request->uri);

	my $cached = $self->cache->get($self->key); # CHI will take care of expiration

	if (defined($cached)) {
		return $cached;
	} else {
		my $expires_in = 0;
		my $res = $self->SUPER::request(@args);
		if ($res->is_success) { # Cache only successful responses for now
			my $cc = $res->header('Cache-Control');
			if (defined($cc)) {
				($expires_in) = ($cc =~ m/max-age=(\d+)/);
			}
			if ($expires_in > 0) {
				$self->cache->set($self->key, $res, { expires_in => $expires_in });
			}
		}
		return $res;
	}
}

1;

__END__

=head1 LIMITATIONS

Will only cache C<GET> requests and only looks at the C<Cache-Control:
max-age> header. Does not make any attempts to see if the response is
invalid.



=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-lwp-useragent-chicaching/issues>.

=head1 TODO

This is a very early release, meant just for the author's immediate
needs. These are the things that I'd like to do:

=over

=item * Enable smarter generation of keys, so that semantically
identical content can be cached efficiently even though they may have
different URIs.

=item * Support all of L<RFC7234|http://tools.ietf.org/html/rfc7234>
and <RFC7232|http://tools.ietf.org/html/rfc7232>

=back

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 ACKNOWLEDGEMENTS

It was really nice looking at the code of L<LWP::UserAgent::WithCache>, when I wrote this.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

