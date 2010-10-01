#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
use File::Slurp;

BEGIN {
    local $@;
    eval { require YAML::Syck };
    if ($@) {
        require YAML;
        *LoadFile = *YAML::LoadFile;
    }
    else {
        *LoadFile = *YAML::Syck::LoadFile;
    }
}

BEGIN { use_ok('BBS::Perm::Config'); }

my $file = 't/config.yml';

my $config = LoadFile($file);
tidy($config);

my $t = BBS::Perm::Config->new;
isa_ok( $t, 'BBS::Perm::Config' );
$t->load($file);


$t = BBS::Perm::Config->new( file => $file );
isa_ok( $t, 'BBS::Perm::Config' );

eq_array( [ $t->sites ], [ keys %$config ], 'sites method' );
is( $t->file, $file, 'file method' );

for ( $t->sites ) {
    eq_hash( $t->setting($_), $config->{$_}, 'setting method' );
}

for ( $t->sites ) {
    is_deeply( $t->setting($_), $config->{$_}, 'sites and setting method' );
}

sub tidy {
    my $self = shift;
    for my $site ( grep { $_ ne 'global' } keys %$self ) {
        for ( keys %{ $self->{global}{term} } ) {
            $self->{$site}{$_} = $self->{global}{term}{$_}
                unless defined $self->{$site}{$_};
        }
    }
}
