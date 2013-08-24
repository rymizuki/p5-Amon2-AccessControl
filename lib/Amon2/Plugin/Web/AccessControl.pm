package Amon2::Plugin::Web::AccessControl;
use strict;
use warnings;
use utf8;

use Amon2::Util ();

sub init {
    my ($class, $c, $conf) = @_;

    my $controller = _create_access_controller($c, $conf);

    $c->add_trigger(
        BEFORE_DISPATCH => sub {
            my $c = shift;

            my $ac = _authenticate($controller);
        },
    );
}

use Router::Simple;
sub _create_access_controller {
    my ($c, $conf) = @_;

    my $router = Router::Simple->new;
    my @paths = @{ $conf->{paths} };
    for my $control (@paths) {
        my $path       = $control->{path};
        my $conditions = $control->{condition};
        $router->connect($path, +{conditions => $conditions});
    }

    return $router;
}

sub _authenticate {
    my ($c, $controller) = @_;

    my $env = $c->req->env;

    if (my $p = $controller->match($env)) {
        my $response;
        while (my $code = shift @{ $p->{conditions} }) {
            my $auth = Amon2::AccessControl->new(code => $code)->authenticate($c);

            if (!$auth->is_passed) {
                return $auth->response ? $auth->response : $c->res_400;
            }
        }
    } else {
        return $c->res_404;
    }
}

1;
