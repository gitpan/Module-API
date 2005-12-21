# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

package TestAPI::Plugin::IncrementToken;

sub can_do_request {
    my $class        = shift;
    my $request_name = shift;

    return 1 if $request_name eq 'increment_token';
}

=head2 process

Ignore the payload and just increment the C<session_token>.

=cut

sub process {
    my $class    = shift;
    my $request  = shift;
    my $response = shift;

    my $token = $request->config('token');
    $token++;
    $response->config( 'token', $token );

    return {};
}

1;
