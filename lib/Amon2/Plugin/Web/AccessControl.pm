package Amon2::Plugin::Web::AccessControl;
use strict;
use warnings;
use utf8;

use Amon2::Util ();
use Amon2::AccessControl;

sub init {
    my ($class, $c, $conf) = @_;

    my $controller = _create_access_controller($c, $conf);

    $c->add_trigger(
        BEFORE_DISPATCH => sub {
            my $c = shift;
            return _authenticate($c => $controller);
        },
    );
}

use Router::Simple;
sub _create_access_controller {
    my ($c, $conf) = @_;

    my $router = Router::Simple->new;
    my %controls = %{ $conf->{controls} };
    for my $path (keys %controls) {
        my %param = (
            namespace => $conf->{namespace},
            roles     => $conf->{roles},
        );
        if (ref $controls{$path} eq 'CODE') {
            $param{controls} = [$controls{$path}];
        } else {
            $param{controls} = $controls{$path};
        }
        $router->connect($path => \%param);
    }

    return $router;
}

sub _authenticate {
    my ($c, $controller) = @_;

    my $env = $c->req->env;

    if (my $p = $controller->match($env)) {

        my $namespace = $p->{namespace};
        my $roles     = $p->{roles};
        my @controls  = @{ $p->{controls} };

        my $response;
        while (my $role = shift @controls) {

            my $auth = Amon2::AccessControl->new();
            if ($namespace) {
                $auth->namespace($namespace);
            }

            my $option;
            if (ref $role eq 'CODE') {
                $option = +{authenticate => $role};
            } else {
                $option = ref $controls[0] ? shift @controls : +{};
                $auth->with($role);
            }

            $auth->authenticate($c, $option);

            if (!$auth->is_passed) {
                return $auth->response ? $auth->response : $c->res_401;
            }
        }
    } else {
        return $c->res_404;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Plugin::Web::AccessControl

=head1 SYNOPSIS

    use Amon2::Lite;

    __PACKAGE__->load_plugin(
        'Web::AccessControl' => +{
            controls => +{
                '/' => sub {},
            },
        },
    );

    __PACKAGE__->load_plugin(
        'Web::AccessControl' => +{
            namespace => 'Youe::AccessControl::Role',
            roles     => +{
                'Member' => +{redirect_to => '/login'},
            },
            controls => +{
                '/' => [qw(Mmeber)],
            },
        },
    );
