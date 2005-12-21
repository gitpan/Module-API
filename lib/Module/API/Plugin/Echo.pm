# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

package Module::API::Plugin::Echo;
use Storable ();

=head2 can_do_request

Is used to see if this plugin can handle the request. It is passed the
request name and should return true if it can handle the request. This
result will be cached so that the next time a request is made this
module will be called to process it.

=cut

sub can_do_request {
    my $class        = shift;
    my $request_name = shift;

    return 1 if $request_name eq 'echo';
}

=head2 process

The meat of the module. This method is passed the request object and
is expected to do whatever it needs to do, and then return a hashref
which will be sent back as the payload to the response object.

=cut

sub process {
    my $class    = shift;
    my $request  = shift;
    my $response = shift;

    my $data = $request->data;
    my $copy = Storable::dclone $data;
    $response->data($copy);

    return 1;
}

1;
