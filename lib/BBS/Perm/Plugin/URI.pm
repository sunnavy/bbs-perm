package BBS::Perm::Plugin::URI;

use warnings;
use strict;
use Carp;
use Gtk2;

use version; our $VERSION = qv('0.0.3');

sub new {
    my ( $class, %opt ) = @_;
    my $widget = $opt{widget}  || Gtk2::LinkButton->new('');
    my $cmd    = $opt{browser} || 'firefox -new-tab';
    my $self   = [$widget];
    bless $self, ref $class || $class;
    $self->widget->set_uri_hook( sub { $self->_browse($cmd); } );
    return $self;
}

sub _browse {
    my ( $self, $cmd ) = @_;
    my $uri = $self->widget->get_uri;
    if ($uri) {
        system("$cmd \Q$uri\E &")
            and warn 'can not run browser';
    }
}

sub widget {
    return shift->[0];
}

sub push {
    my ( $self, $input ) = @_;
    return push @$self, $input;
}

sub pop {
    my $self = shift;
    return pop @$self unless @$self == 1;
}

sub uri {
    my $self = shift;
    return [@{$self}[1 .. $#{$self}]];
}

sub size {
    return @{shift->uri};
}


sub clear {
    my $self = shift;
    splice @$self, 1;
}

1;

__END__

=head1 NAME

BBS::Perm::Plugin::URI - render quickly URI submittal for BBS::Perm


=head1 VERSION

This document describes BBS::Perm::Plugin::URI version 0.0.3

=head1 SYNOPSIS

    use BBS::Perm::Plugin::URI;
    my $uri = BBS::Perm::Plugin::URI->new( browser => 'firefox -new-tab');
    my $button = $uri->widget;
    $uri->push( 'http://cpan.org' );
    $uri->pop;
    $uri->clear;

=head1 DESCRIPTION

BBS::Perm::Plugin::URI is a plugin of BBS::Perm for quickly submitting URI
If current text has some URI such as http://www.cpan.org, you can use your
browser to visit it, just hit Alt+Numer, where Number is the position of 
the URI appears. If it's the first URI on our screen, the Number is 1.
If it's the 5th URI, the Number is 5. And so on, till 9.
Alt+0 will visit your default URI.
If there's no the Nth URI when you submit Alt+N, you'll visit the last URI.

Yeah, I know, it's not elegant, but in BBS world, URI is rare, so it's not
a critical problem, IMHO, ;-)

To make this work, you have to enable BBS::Perm's accel option.

=head1 INTERFACE

=over 4

=item new( browser => $browser, widget => $widget )

create a new BBS::Perm::Plugin::URI object

$browser is your command to visit the URI, which will be provideed as the
argument.

$widget is a Gtk2::LinkButton object, default is a new one.

=item widget

get the widget of our object.

=item push($uri)

push $uri to our object.

=item pop

pop one URI from our object.

=item uri

get a arrayref referred to a list of URIs in our object.

=item size

get the number of URIs in our object.

=item clear

clear URIs in our object.

=back

=head1 DEPENDENCIES

L<Gtk2>, L<version>

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

sunnavy  C<< <sunnavy@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, sunnavy C<< <sunnavy@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
