package Plack::Middleware::iPhone;

use warnings;
use strict;
use parent qw( Plack::Middleware );
use Plack::Util::Accessor qw( manifest icon startup_image tidy viewport statusbar );

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    
    $self->write_manifest if $self->manifest;

    return $self;
}

sub call {
    my $self = shift;

    my $res = $self->app->(@_);
    $self->response_cb($res, sub {
        my $res = shift;
        my $h = Plack::Util::headers($res->[1]);
        if ($h->get('Content-Type') =~ m!^text/html!) {
            return sub {
                my $chunk = shift;
                return unless defined $chunk;
                return $self->filter($chunk);
            };
        }
    });
}

sub filter {
    my $self = shift;
    my $chunk = shift;
    require HTML::DOM;
    my $dom = new HTML::DOM or return $chunk;
    $dom->write($chunk);
    $dom->close;
    
    if (my $manifest = $self->manifest) {
        $dom->documentElement->setAttribute('manifest', $manifest);
    }
    
    my $head = $dom->getElementsByTagName('head')->[0];
    my @meta = (
        [ name => 'viewport', content => $self->viewport || 'width = device-width' ],
        [ name => 'apple-mobile-web-app-capable', content => 'yes' ],
        [ name => 'apple-mobile-web-app-status-bar-style', content => $self->statusbar || 'gray' ],
    );
    for my $attrs (@meta) {
        $head->appendChild( $self->el( $dom, 'meta', @$attrs ) );
    }
    
    my %rel_links = map { $_->rel => 1 } $head->getElementsByTagName('link');
    my @links;
    push @links, { rel => "apple-touch-icon", href => $self->icon } if $self->icon;
    push @links, { rel => "apple-touch-startup-image", href => $self->startup_image } if $self->startup_image;
    
    for my $link_attrs (@links) {
        if ( $rel_links{ $link_attrs->{rel} } ) {
            warn "$link_attrs->{rel} link already exists";
        } else {
            $head->appendChild( $self->el( $dom, 'link', %$link_attrs ) );
        }
    }
    
    my $html = $dom->innerHTML;
    
    if ($self->tidy) {
        require HTML::Tidy;
        my $tidy = HTML::Tidy->new( { output_html => 1, indent => 'auto',  tidy_mark => 'no' });
        $html = $tidy->clean($html);
    }
    
    return $html;
}

sub el {
    my $self = shift;
    my $dom = shift;
    my $type = shift;
    my @attrs = @_;
    my $el = $dom->createElement($type);
    while (my ($attr, $val) = splice @attrs, 0, 2) {
        $el->$attr($val);
    }
    return $el;
}

sub write_manifest {
    my $self = shift;
    
    require Digest::MD5;
    require File::Slurp;
    my $manifest = $self->manifest;
    
    # Write the manifest once, at compile time
    open my $fh, '>', $manifest or die "Unable to write manifest $manifest. $!";
    $fh->print("CACHE MANIFEST\n");
    for my $file (<*.*>) {
        # Don't put manifest or app.psgi in manifest file
        next if $file eq $manifest or $file eq __FILE__;
        
        # Write MD5 hash so that manifest changes whenever files change (auto cache updating)
        $fh->print("$file #");
        $fh->print(Digest::MD5::md5_hex(File::Slurp::read_file($file)) . "\n");
    }
}

1;

__END__

=head1 NAME

Plack::Middleware::iPhone - Make your html more iPhone friendly

=head1 SYNOPSIS

  # iPhone compatible directory listing..
  use Plack::Builder;
  use Plack::App::Directory;
  builder {
      enable 'iPhone';
      Plack::App::Directory->new;
  }
  
  # or with some options..
  builder {
    enable "iPhone",
        tidy => 1,
        manifest => 'app.manifest',
        viewport => 'initial-scale = 1, maximum-scale = 1.5, width = device-width',
        statusbar => 'black-translucent',
        startup_image => 'loading.png';
        icon => 'icon.png',
    $app;
  }

=head1 DESCRIPTION

Plack::Middleware::iPhone does some on the fly rewriting of any html content returned by your app (mostly just the head block) 
to make it play nicer with iPhones. This is just a toy, for real 
L<HTML5|http://www.quirksmode.org/blog/archives/2010/03/html5_apps.html>
mobile web apps you should be writing the HTML yourself.

=head1 SEE ALSO

L<Building iPhone Apps with HTML, CSS, and JavaScript|http://building-iphone-apps.labs.oreilly.com>, Jonathan Stark (freely available).

=head2 OPTIONS

=head3 icon

A 57x57 image icon that the iPhone will display as a shortcut to your app if you add it to your Home Screen
via the "Add to Home Screen" function.

=head3 startup_image

A 320x460 PNG image that is displayed while your app is loading. If this is not set, the iPhone automatically
uses a screenshot of the most recent app state.

=head3 statusbar

Sets the C<apple-mobile-web-app-status-bar-style> meta tag, which controls the status bar appearance when yourself
app is launched from a Home icon shortcut.

Valid options are:

=over 4

=item *

gray (default)

=item *

black

=item *

black-translucent

=back

=head3 viewport

Sets the viewport meta tag, which determines how wide your iPhone thinks the screen is and scaling options. 

See 
L<Configuring the Viewport|http://developer.apple.com/safari/library/documentation/AppleApplications/Reference/SafariWebContent/UsingtheViewport/UsingtheViewport.html>
for more information.

=head3 manifest

Automatically generates a manifest file for your application (with whatever name you pass in), and sets the 
C<manifest> attribute on the html root tag, which triggers your iPhone to start using offline HTML Web App caching.

See L<Going Offline|http://building-iphone-apps.labs.oreilly.com/ch06.html> for more information

=head3 tidy 

Run the HTML through HTML::Tidy

=head1 AUTHOR

Patrick Donelan, C<< <pat at patspam.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Patrick Donelan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
