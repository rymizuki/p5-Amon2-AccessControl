requires 'perl', '5.008001';
requires 'Amon2::Util';
requires 'Router::Simple';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Plack::Test';
    requires 'Amon2::Lite';
};

on 'develop' => sub {
    requires 'Log::Minimal';
};

