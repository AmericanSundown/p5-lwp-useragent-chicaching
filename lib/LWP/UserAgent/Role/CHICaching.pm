package LWP::UserAgent::Role::CHICaching;

use 5.006000;
use CHI;
use Moo::Role;
use Types::Standard qw(Str InstanceOf);
use Types::URI -all;
use DateTime::Format::HTTP;
use Try::Tiny;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.002';

=pod

=encoding utf-8

=head1 NAME

LWP::UserAgent::Role::CHICaching - A role to allow LWP::UserAgent to cache with CHI

=head1 SYNOPSIS

Compose it into a class, e.g.

  package LWP::UserAgent::MyCacher;
  use Moo;
  extends 'LWP::UserAgent';
  with 'LWP::UserAgent::Role::CHICaching';


=head1 DESCRIPTION

This is a role for creating caching user agents. When the client makes
a request to the server, sometimes the response should be cached, so
that no actual request has to be sent at all, or possibly just a
request to validate the cache. HTTP 1.1 defines how to do this. This
role makes it possible to use the very flexible L<CHI> module to
manage such a cache. See L<LWP::UserAgent::CHICaching> for a finished
class you can use.


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

Wrapping L<LWP::UserAgent>'s request method.

=item C<< is_shared >>

A boolean value to set whether the cache can be shared. The default is
that it is.

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
				builder => sub { shift->request_uri->canonical->as_string }
			  );


has request_uri => (
						  is =>'rw',
						  isa => Uri,
						  coerce => 1,
						  trigger => sub { shift->clear_key },
						 );

has is_shared => (
					is => 'rw',
					isa => Bool,
					default => 1);

around request => sub {
	my ($orig, $self) = (shift, shift);
	my @args = @_;
	my $request = $args[0];

	return $self->$orig(@args) if $request->method ne 'GET';

	$self->request_uri($request->uri);

	my $cached = $self->cache->get($self->key); # CHI will take care of expiration

	if (defined($cached)) {
		######## Here, we decide whether to reuse a cached response.
		######## The standard describing this is:
		######## http://tools.ietf.org/html/rfc7234#section-4
		return $cached;
	} else {
		######## Here, we decide whether to store a response
		######## This is defined in:
		######## http://tools.ietf.org/html/rfc7234#section-3
		# Quoting the standard

		## A cache MUST NOT store a response to any request, unless:
		
		## o  The request method is understood by the cache and defined as being
		##    cacheable, and
		# TODO: Ok, only GET supported, see above
		
		
		my $expires_in = 0;
		my $res = $self->$orig(@args);
		## o  the response status code is understood by the cache, and
		if ($res->is_success) { # TODO: Cache only successful responses for now
			try {
				my $then = DateTime::Format::HTTP->parse_datetime($res->header('Expires'));
				my $dur = $then->subtract_datetime_absolute(DateTime->now);
				$expires_in = $dur->seconds;
			}; # If it croaks, we will not use anyway.
			my $cc = $res->header('Cache-Control');
			if (defined($cc)) {
				## o  the "no-store" cache directive (see Section 5.2) does not appear
				##    in request or response header fields, and
				return $res if ($cc =~ m/no-store|no-cache/); # TODO: Improve no-cache use
				if ($self-is_shared) {
					## o  the "private" response directive (see Section 5.2.2.6) does not
					##    appear in the response, if the cache is shared, and
					return $res if ($cc =~ m/private/);
					## o  the Authorization header field (see Section 4.2 of [RFC7235]) does
					##    not appear in the request, if the cache is shared, unless the
					##    response explicitly allows it (see Section 3.2), and
					if $request->header('Authorization') {
						return $res unless ($cc =~ m/public|must-revalidate|s-maxage/);
					}
				}
				## o  the response either:
				##
				##    *  contains an Expires header field (see Section 5.3), or
				# Done above, so that the Expires header may be
				# independent of the Cache-Control header

				##    *  contains a max-age response directive (see Section 5.2.2.8), or
				($expires_in) = ($cc =~ m/max-age=(\d+)/);

				##    *  contains a s-maxage response directive (see Section 5.2.2.9)
				##       and the cache is shared, or
				if ($self->is_shared) {
					($expires_in) = ($cc =~ m/s-maxage=(\d+)/);
				}

				##    *  contains a Cache Control Extension (see Section 5.2.3) that
				##       allows it to be cached, or
				# TODO

				##    *  has a status code that is defined as cacheable by default (see
				##       Section 4.2.2), or
				# TODO: We only do GET

				##    *  contains a public response directive (see Section 5.2.2.5).
				# We do not specifically deal with this

			}
			if ($expires_in > 0) {
				$self->cache->set($self->key, $res, { expires_in => $expires_in });
			}
		}
		return $res;
	}
};

1;

__END__

=head1 LIMITATIONS

Will only cache C<GET> requests and only looks at the C<Cache-Control:
max-age> header. Does not make any attempts to see if the response is
invalid.

=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-lwp-useragent-chicaching/issues>.


=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 ACKNOWLEDGEMENTS

It was really nice looking at the code of L<LWP::UserAgent::WithCache>, when I wrote this.

Thanks to Matt S. Trout for rewriting this to a Role.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.



