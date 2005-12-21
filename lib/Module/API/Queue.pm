# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

package Module::API::Queue;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use URI;
use Net::HTTP;
use Net::HTTP::NB;
use IO::Select;

=head1 NAME

Module::API::Queue - allow queueing of requests and non-blocking
processing of them.

=head1 SYNOPSIS

    use Module::API;
    my $api = Module::API->new( server_url => 'http://api.example.com/api' );

    $api->send_nb( 'request_name_1', \%data_1 );
    $api->send_nb( 'request_name_2', \%data_2 );

    while ( $api->queue->total_count ) {

        # check if a request has been completed
        if ( my $response = $api->queue->next_response ) {

            # deal with the response
            ...;
            next;
        }

        # do something whilst the requests are processed.
        ...;
    }

=head1 DESCRIPTION

With API calls that go to a remote machine there is a time delay
between sending the request and receiving the
response. C<Module::API::Queue> lets you do something during this
delay.

All of the complexity of doing this is hidden from you. You need only
send requests using C<$api-E<gt>send_nb(...)> and then check the queue
from time to time to deal with the returned responses. In between
checking the queue you are able to go off and do other things such as
preparing more requests, updating a user interface or whatever.

=head1 HOW IT WORKS

C<Module::API::Queue> maintains three internal lists:

=over 4

=item to_send

The requests that have been added to the queue but have not been sent
yet. The requests are sent one by one in the order in which they were
added to the queue.

=item in_progress

The requests that have been sent but whose responses have not been
fully received yet. There is no particular order. The number on this
list is limited by C<slots>.;

=item to_return

Requests that have been sent and their responses fully received. The
are now ready for you to take back and deal with. They are in the
order that they finished being received in - which may not be the
order they were sent in.

=back

Each time you call a method the internal lists are processed. This
means that you should get back to the queue (or at least C<poke> it)
fairly often to ensure that it all works smoothly.

=head1 METHODS

=head2 new

    my $api_queue = Module::API::Queue->new( api_class => 'Your::API::Class' );
    my $api_queue = $api->queue;

Creates a new queue - but it is better to create an API object and
access the queue through that. If the queue does not exist the API
object will create it and configure it. The C<$api-E<gt>queue> is so
preferred that it is used in all the examples other than this one.

=cut

sub new {
    my $class = shift;
    return bless {
        to_send     => [],
        in_progress => {},
        to_return   => [],
        slots       => 20,
    }, $class;
}

=head2 slots

    $slots = $api->queue->slots(123);    # Set slots to '123'
    $slots = $api->queue->slots;         # Get the number of slots

Getter/setter for the number of slots - the maximum number of requests
to have on C<in_progress> at any one time. Defaults to 20. More
requests can be added to the queue even when the limit is reached -
but the requests will not be sent until there is a free slot. Returns
the number set.

Changing the number of slots only affects adding requests to the
C<in_progress> list. Requests that are currently on the list are not
affected.  The queue can be paused by setting C<slots> to zero.

=cut

sub slots {
    my $self = shift;
    $$self{slots} = shift if @_;
    return $$self{slots};
}

=head2 add

    $api->queue->add( $api_request, $api_request2, ... );

Add L<Module::API::Request> objects to the queue. Always returns true.

=cut

sub add {
    my $self = shift;

    push @{ $$self{to_send} }, @_;
    $self->poke;

    return 1;
}

=head2 *_count methods

    my $number_to_send     = $api->queue->to_send_count;
    my $number_in_progress = $api->queue->in_progress_count;
    my $number_to_return   = $api->queue->to_return_count;

    # Sum of all the above.
    my $number_on_queue = $api->queue->total_count;

These return the number of requests in the various stages, or the
total count. The queue is C<poke>d before the counts are made so that the
values are up to date.

=cut

sub to_send_count   { my $s = shift; $s->poke; scalar @{ $$s{to_send} }; }
sub to_return_count { my $s = shift; $s->poke; scalar @{ $$s{to_return} }; }

sub in_progress_count {
    my $s = shift;
    $s->poke;
    scalar keys %{ $$s{in_progress} };
}

sub total_count {
    my $self  = shift;
    my $count = 0;

    $self->poke;

    $count += scalar @{ $$self{to_send} };
    $count += scalar keys %{ $$self{in_progress} };
    $count += scalar @{ $$self{to_return} };

    return $count;
}

=head2 poke

    $api->queue->poke;

Poke the queue. This means check the C<in_progress> queue for requests
that have finished and move them to the C<to_return> queue. Then send
any requests that are on the C<to_send>.

This is done automatically by most of the other methods so you need
not really ever do it. However it may prove useful to do this if you
find yourself away from the queue for a long time so that the queue is
kept current.

=cut

sub poke {
    my $self = shift;

    $self->_process_in_progress;
    $self->_process_to_send;

    return 1;
}

=head2 next_response

    $api_response = $api->queue->next_response;

Get the next C<$api_response> from the C<to_return> list. The response
is now removed from the list. If there are no more responses it
returns C<undef>.

=cut

sub next_response {
    my $self = shift;
    $self->poke;
    return shift @{ $$self{to_return} };
}

=head2 DESTROY

The destroy method croaks if a queue is destroyed with items still on
it.

=cut

sub DESTROY {
    my $self = shift;
    warn "Queue destroyed but not empty\n" if $self->total_count;
    return;
}

# Go through all the values on the select list and check to see if
# they have been fully recieved yet.

sub _process_in_progress {
    my $self = shift;

    foreach my $s ( $self->_io_select->can_read(0) ) {

        my $hashref = $$self{in_progress}{ $s->fileno };

        # If there is a code then read the body.
        if ( $$self{in_progress}{ $s->fileno }{code} ) {
            my $buf;
            my $n = $s->read_entity_body( $buf, 1024 * 16 );
            $$hashref{is_complete} = 1 unless $n;
            $$hashref{content} .= $buf;

            # warn $buf;
        }

        # If no code try to read the headers.
        else {
            my ( $code, $message, %headers ) =
              $s->read_response_headers( laxed => 1, junk_out => 1 );

            if ($code) {
                $$hashref{code}    = $code;
                $$hashref{message} = $message;
                $$hashref{headers} = \%headers;
            }
        }

        # If the message is complete then create a request and add it
        # to 'to_return';
        if ( $$hashref{is_complete} ) {
            delete $$self{in_progress}{ $s->fileno };
            $self->_io_select->remove($s);

            # warn Dumper $$hashref{content};

            my $config       = $$hashref{request}->config_copy;
            my $api_response = Module::API::Response->new(%$config);

            $api_response->request( $$hashref{request} );
            $api_response->api_object( $$hashref{request}->api_object );
            $api_response->payload->as_string( $$hashref{content} );
            $api_response->set_data_from_payload;

            my $token =
              $api_response->payload->as_hashref->{response_config}{token};
            $api_response->config( 'token', $token );
            $api_response->api_object->config( 'token', $token );

            push @{ $$self{to_return} }, $api_response;
        }
    }

    return 1;
}

# Add all the items waiting to be sent to 'to_send' up to the 'slots'
# limit.

sub _process_to_send {
    my $self = shift;

    while ( scalar @{ $$self{to_send} }
        && $self->slots > scalar keys %{ $$self{in_progress} } )
    {
        $self->_send_request( shift @{ $$self{to_send} } );
    }

    return 1;
}

sub _send_request {
    my $self    = shift;
    my $request = shift;

    my $uri      = URI->new( $request->config('server_url') );
    my $http_req = $request->as_http_request;

    my $s = Net::HTTP::NB->new( Host => $uri->host, PeerPort => $uri->port )
      || croak "could not create a Net::HTTP::NB object '$!'";

    my %headers = $request->http_headers;

    croak "Could not write request to $uri '$!'"
      unless $s->write_request( 'POST', $uri->as_string, %headers,
        $http_req->content );

    $self->_io_select->add($s);
    $$self{in_progress}{ $s->fileno }{request} = $request;
    return 1;
}

sub _io_select { return $$_[0]{io_select} ||= IO::Select->new(); }

1;
