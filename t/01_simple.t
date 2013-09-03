use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request;

{
    package Mock::Web;
    use Amon2::Lite;

    get '/pass'        => sub { shift->create_response(200) };
    get '/success'     => sub { shift->create_response(200) };
    get '/fail'        => sub { shift->create_response(200) };
    get '/not_defined' => sub { shift->create_response(200) };
}

{
    package Mock::AC::Role::Successful;
    use Mouse::Role;

    override 'authenticate' => sub {
        my ($self, $c, $option) = @_;
        $self->success;
    };

    package Mock::AC::Role::Failure;
    use Mouse::Role;

    override ''
}

subtest 'use array' => sub {
    Mock::Web->load_plugin(
        'Web::AccessControl' => +{
            controls => +{
                '/pass'    => [qw()],
                '/success' => sub {
                    my ($self, $c, $option) = @_;
                    $self->success;
                },
                '/fail'    => sub {
                    my ($self, $c, $option) = @_;
                    $self->failed;
                    return $c->create_response(401);
                },
            },
        },
    );
    my $app = Mock::Web->to_app;

    test_psgi($app, sub {
        my $cb = shift;
        is $cb->(HTTP::Request->new(GET => '/pass'))->code        => 200;
        is $cb->(HTTP::Request->new(GET => '/success'))->code     => 200;
        is $cb->(HTTP::Request->new(GET => '/fail'))->code        => 401;
        is $cb->(HTTP::Request->new(GET => '/not_defined'))->code => 404;
    });
};

subtest 'use module' => sub {
    Mock::Web->load_plugin(
        'Web::AccessControl' => +{
            namespace => 'Mock::AC::Role',
            roles     => [],
            controls => +{
                '/pass'    => [qw()],
                '/success' => [qw(Successful)],
                '/fail'    => [qw(Failure)],
            },
        },
    );
    my $app = Mock::Web->to_app;

    test_psgi($app, sub {
        my $cb = shift;
        is $cb->(HTTP::Request->new(GET => '/pass'))->code        => 200;
        is $cb->(HTTP::Request->new(GET => '/success'))->code     => 200;
        is $cb->(HTTP::Request->new(GET => '/fail'))->code        => 401;
        is $cb->(HTTP::Request->new(GET => '/not_defined'))->code => 404;
    });

};

done_testing();
