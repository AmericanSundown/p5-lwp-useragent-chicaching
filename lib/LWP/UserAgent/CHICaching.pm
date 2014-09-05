use 5.010001;
use strict;
use warnings;

package LWP::UserAgent::CHICaching;

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

=head1 DESCRIPTION

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


=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-lwp-useragent-chicaching/issues>.

=head1 TODO

This is a very early release, meant just for the author's immediate
needs. These are the things that I'd like to do:

=over

=item * I haven't found a good way to test this module: How do you
test that at the webserver, nothing happens?

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

This software is copyright (c) 2014 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

