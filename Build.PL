use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Module::API',
    license           => 'perl',
    dist_author       => 'Edmund von der Burg <evdb@ecclestoad.co.uk>',
    dist_version_from => 'lib/Module/API.pm',
    build_requires    => {
        'Carp'                                   => 0,
        'Cwd'                                    => 0,
        'Data::Dumper'                           => 0,
        'File::Slurp'                            => 0,
        'File::Spec'                             => 0,
        'HTTP::Request'                          => 0,
        'HTTP::Response'                         => 0,
        'HTTP::Server::Simple'                   => 0,
        'HTTP::Server::Simple::CGI::Environment' => 0,
        'LWP::UserAgent'                         => 0,
        'List::Util'                             => 0,
        'Module::Build'                          => 0,
        'Module::Pluggable'                      => 0,
        'Net::HTTP::NB'                          => 0,
        'Storable'                               => 0,
        'Test::LongString'                       => 0,
        'Test::More'                             => 0,
        'URI'                                    => 0,
        'YAML'                                   => 0,
        'base'                                   => 0,
        'strict'                                 => 0,
        'warnings'                               => 0,
    },
    add_to_cleanup       => ['Module-API-*'],
    recursive_test_files => 1,
);

$builder->create_build_script();
