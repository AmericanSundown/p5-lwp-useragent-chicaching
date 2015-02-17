package LWP::UserAgent::Role::CHICaching;

use 5.006000;
use CHI;
use Moo::Role;
use Types::Standard qw(Str InstanceOf);
use Types::URI -all;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.001';

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

around request => sub {
	my ($orig, $self) = (shift, shift);
	my @args = @_;
	my $request = $args[0];

	return $self->$orig(@args) if $request->method ne 'GET';

	$self->request_uri($request->uri);

	my $cached = $self->cache->get($self->key); # CHI will take care of expiration

	if (defined($cached)) {
		return $cached;
	} else {
		my $expires_in = 0;
		my $res = $self->$orig(@args);
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



