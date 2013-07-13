package Video::Format::MP4;

use 5.010001;
use strict;
use warnings;

use base "Video::Format"; 

our %ATOM_HANDLERS = (
    "FILE"  => \&atom_walk,
    "ftyp"  => \&ftyp,
    "moov"  => \&atom_walk,
    "trak"  => \&atom_walk,
);


sub parse {
    my $self = shift;
    my $name = $self->getprop("name");

    return unless defined($name);

    if (exists($ATOM_HANDLERS{$name})) {
        $ATOM_HANDLERS{$name}->($self);
    }
}


sub atom_info {
    my $self = shift;

    return unless defined($self->{buffer});

    my $blen = length(${$self->{buffer}});
    my $size = $self->UI32();
    my $name = $self->BString(4);
    my $hdr_len = 8;

    return undef unless defined($name) and defined($size);

    if ($size == 1) {
        $size = $self->UI64();
        $hdr_len += 8;

    } elsif ($size == 0) {
        $size = $blen;
    }

    my $buf = $self->BString($size - $hdr_len);
    my $atom = $self->new(\$buf);
    $atom->setprop("name", $name);
    $atom->setprop("size", $size);
    $atom->setprop("parent", \$self);

    return $atom;
}

sub atom_walk {
    my $self = shift;

    while (my $atom = $self->atom_info()) {
        $atom->parse();
    }
}

sub ftyp {
    my $self = shift;

}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Video::Format::MP4 - Parse MP4 file format

=head1 AUTHOR

Eugene Mychlo, E<lt>myc@barev.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Eugene Mychlo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
