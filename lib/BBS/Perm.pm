package BBS::Perm;

use 5.008;
use warnings;
use strict;
use Carp;
use Regexp::Common qw/URI/;
use Encode;
use BBS::Perm::Term;
use BBS::Perm::Config;
use UNIVERSAL::require;
use UNIVERSAL::moniker;

use version; our $VERSION = qv('0.0.3');

my %component = (
    IP   => 0,
    URI  => 0,
    Feed => 0,
);

sub new {
    my ( $class, %opt ) = @_;
    my $self = {};

    if ( $self->{window} ) {
        if ( ref $self->{window} eq 'Gtk2::Window' ) {
            $self->{window} = $opt{window};
        }
        else {
            croak 'window must be a Gtk2::Window object';
        }
    }
    else {
        $self->{window} = Gtk2::Window->new;
    }

    bless $self, ref $class || $class;

    if ( $opt{config} ) {
        $self->{config} = BBS::Perm::Config->new( %{ $opt{config} } );
    }
    else {
        croak 'BBS::Perm must have config option';
    }

    $self->{term} = BBS::Perm::Term->new( $opt{term} ? %{ $opt{term} } : () );

    for ( keys %component ) {
        if ( $component{$_} ) {
            $_ = 'BBS::Perm::Plugin::' . $_;
            $_->require or die $@;
            my $key = $_->moniker;
            $self->{$key} = $_->new(
                %{ $self->config->setting('global')->{$key} },
                defined $opt{$key} ? %{ $opt{$key} } : ()
            );
        }
    }

    if ( not $opt{accel} ) {    # enable accel is default
        $self->_register_accel;
    }

    if ( $component{Feed} ) {
        $self->feed->entry->signal_connect(
            activate => sub {
                my $text = $self->feed->text || q{};
                $text =~ s/(\033)/$1$1/g;    # term itself will eat an escape
                $self->term->term->feed_child_binary(encode 'gbk', $text);
                $self->feed->entry->set_text(q{});
            }
        );
    }

    return $self;
}

sub _clean {                                 # be called when an agent exited
    my $self = shift;
    $self->term->clean;
    if ( $self->term->term ) {
        $self->window->set_title( $self->term->title );
    }
    else {
        $self->window->set_title($self->config->setting('global')->{title} ||
                'bbs-perm' );
    }
}

sub _switch {
    my ( $self, $direct ) = @_;
    $self->term->switch($direct);
    $self->window->set_title( $self->term->title );
}

sub _register_accel {
    my $self  = shift;
    my %accel = ();
    if ( $self->config->setting('global')->{accel} ) {
        %accel = %{ $self->config->setting('global')->{accel} };
    }

    for ( keys %accel ) {
        my $value = $accel{$_};
        my $mod   = ['mod1-mask'];
        if ( $value =~ /^(C|M)-(.)/i ) {
            $mod = ['control-mask'] if lc $1 eq 'c';
            $accel{$_} = [ $2, $mod ];
        }
        else {
            warn "accel $_ is incorrect";
        }
    }

    my @accels = (
        [   $accel{left}->[0] || 'j',
            $accel{left}->[1] || ['mod1-mask'],
            ['visible'],
            sub { $self->_switch(-1) }
        ],
        [   $accel{right}->[0] || 'k',
            $accel{right}->[1] || ['mod1-mask'],
            ['visible'],
            sub { $self->_switch(1) }
        ],
    );

    for my $site ( $self->config->sites ) {
        my $shortcut = $self->config->setting($site)->{shortcut};
        my $mod      = ['mod1-mask'];
        if ( $shortcut =~ /^(C|M)-(\w)/i ) {
            $mod = ['control-mask'] if lc $1 eq 'c';
            push @accels, [
                $2, $mod,
                ['visible'],
                sub {
                    $self->connect($site);
                    }
            ];
        }
    }

    if ( $component{Feed} ) {
        push @accels, [
            $accel{feed}->[0]
                || 'f',
            $accel{feed}->[1]
                || ['control-mask'],
            ['visible'],
            sub {
                if ( $self->feed->entry->has_focus ) {
                    $self->term->term->grab_focus if $self->term->term;
                }
                else {
                    $self->feed->entry->grab_focus;
                }
                }
            ],
            ;
    }

    if ( $component{URI} ) {
        for my $key ( 0 .. 9 ) {
            push @accels, [
                $key,
                ['mod1-mask'],
                ['visible'],
                sub {
                    if ( $self->uri->uri->[ $key - 1 ] ) {
                        $self->uri->widget->set_uri(
                              $key == 0
                            ? $self->config->get_value( global => 'uri' )
                            : $self->uri->uri->[ $key - 1 ]
                        );
                    }
                    else {
                        $self->uri->widget->set_uri( $self->uri->uri->[-1] );
                    }
                    $self->uri->widget->clicked;
                },
            ];
        }
    }

    my $window = $self->{window};
    my $accel  = Gtk2::AccelGroup->new;
    $accel->connect( ord $_->[0], @$_[ 1 .. 3 ] ) for @accels;
    $window->add_accel_group($accel);
}

sub import {
    my $class = shift;
    my @list  = @_;
    for (@list) {
        if ( defined $component{$_} ) {
            $component{$_} = 1;
        }
    }
}

sub connect {
    my ( $self, $site ) = @_;
    my $conf = $self->config->setting($site);
    $self->term->init($conf);

    $self->term->term->signal_connect(
        contents_changed => sub {
            $self->_contents_changed;
        }
    );
    $self->term->term->signal_connect( child_exited => sub { $self->_clean }
    );
    $self->window->set_title( $self->term->title );

    $self->term->connect( $conf, $self->config->file, $site );
}

sub _contents_changed {
    my $self = shift;
    my $text = encode 'utf8', $self->term->text;

    if ( $component{URI} ) {
        $self->uri->clear;    # clean previous uri
        $self->uri->push($1)
            while $text =~ /($RE{URI}{HTTP} | $RE{URI}{FTP})/gx;

        #        $self->uri->widget->set_label( $self->uri->show );
    }
    if ( $component{IP} ) {
        $self->ip->clear;     # and ip info.
        $self->ip->add($1) while ( $text =~ /(\d+\.\d+\.\d+\.(?:\d+|\*))/g );
        $self->ip->show;
    }
}

sub AUTOLOAD {
    our $AUTOLOAD;
    no strict 'refs';
    if ( $AUTOLOAD =~ /.*::(.*)/ ) {
        my $element = $1;
        *$AUTOLOAD = sub { return shift->{$element} };
        goto &$AUTOLOAD;
    }

}

# we need this because of AUTOLOAD
sub DESTROY { }

1;

__END__

=head1 NAME

BBS::Perm - a component for your own BBS client


=head1 VERSION

This document describes BBS::Perm version 0.0.3


=head1 SYNOPSIS

    use BBS::Perm qw/Feed IP URI/;
    my $perm = BBS::Perm->new(
        perm   => { accel => 1 },
        config => { file   => '.bbs-perm/config.yml' },
        ip => { encoding => 'gbk' }
    );

=head1 DESCRIPTION

Want to build your own BBS client using Gtk2? Maybe BBS::Perm can help you.

Although BBS::Perm is still very, very young, it can help you now.

With BBS::Perm, you can:

1. have multi terminals at the same time, and quickly switch among them.

2. anti-idle

3. commit sth. from file or even command output directly.

4. extract URIs and browse them quickly.

5. get some useful information of IPv4 addresses.

6. build your window layout freely.

7. use your own agent script.

=head1 INTERFACE

=over 4

=item new ( %opt )

Create a new BBS::Perm object.

%opt is some configuration options:

{ config => $config, $uri => $uri, perm => $perm }

All the values of %opt are hashrefs.

For each component, there can be a configuration pair for it.
perm => $perm is for BBS::Perm itself, where $perm is as follows:

=over 4

=item window => $window

    $window is a Gtk2::Window object, which is your main window.

=item accel => 1 | 0

     use accelerator keys or not, default is 1

=back

=item connect($sitename)

connect to $sitename.

=item config, uri, ip, ...

For each sub component, there's a method with the componnet's last
name(lowcase), so you can get each sub component from a BBS::Perm object.

e.g. $self->config is the BBS::Perm::Config object.

=item window

return the main window object, which is a Gtk2::Window object.

=back

=head1 DEPENDENCIES

L<Gtk2>, L<Regexp::Common>, L<UNIVERSAL::require>, L<UNIVERSAL::moniker>,L<version>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

When a terminal is destroyed, if there is a warning like
"gdk_window_invalidate_maybe_recurse: assertion `window != NULL' failed",
please update you vte lib to 0.14 or above, this bug will gone, ;-)

=head1 AUTHOR

sunnavy  C<< <sunnavy@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, sunnavy C<< <sunnavy@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

