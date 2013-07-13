package Video::Format;

our $VERSION = '0.01';

use 5.010001;
use strict;
use warnings;
use vars qw($VERSION $AUTOLOAD @ISA);

use Carp;
use POSIX qw(strftime mktime);

use Video::Format::MP4; 


sub new {
    my $class = shift;
    my $buf = shift;

    croak "Undefined value" unless defined($buf);
    croak "Not a SCALAR reference" unless ref($buf) eq 'SCALAR';

    my $self = bless {}, ref($class) || $class || __PACKAGE__;
    $self->{buffer} = $buf;
    $self->{buflen} = length(${$buf});

    return $self;
}


sub _be2int16 {
    return unpack('s>', $_[1])
}

sub _be2uint16 {
    return unpack('S>', $_[1])
}

sub _be2uint24 {
    my @a = unpack('C3',  $_[1]);
    return ($a[0] << 16) + ($a[1] << 8) + $a[2];
}

sub _be2int32 {
    return unpack('l>', $_[1])
}

sub _be2uint32 {
    return unpack('L>', $_[1])
}

sub _be2int64 {
    return unpack('q>', $_[1])
}

sub _be2uint64 {
    return unpack('Q>', $_[1])
}

sub _be2double {
    return unpack('d', pack('q', $_[0]->_be2uint64($_[1])));
}

sub get_bits {
    my $self;
    my $bs = shift;
    my $bt_cnt = shift;
    my $bt_off = shift;

    return ($bs >> $bt_off) & ((2 << ($bt_cnt - 1)) - 1);
}

sub apple_date {
    my $self = shift;
    my $tm = shift;
    my $ref_t = POSIX::mktime( 0, 0, 0, 1, 0, 4) + $tm;  # January 1, 1904

    return POSIX::strftime("%Y-%m-%d %H:%M:%S UTC", gmtime($ref_t));
}

sub I8 {
    my $self = shift;

    my $rv = unpack('c', ${$self->{buffer}});
    substr(${$self->{buffer}}, 0, 1) = '';
    return $rv;
}

sub UI8 {
    my $self = shift;

    my $rv = unpack('C', ${$self->{buffer}});
    substr(${$self->{buffer}}, 0, 1) = '';
    return $rv;
}

sub I16 {
    my $self = shift;

    my $rv = $self->_be2int16(${$self->{buffer}});
    substr(${$self->{buffer}}, 0, 2) = '';
    return $rv;
}

sub UI16 {
    my $self = shift;

    my $rv = $self->_be2uint16(${$self->{buffer}});
    substr(${$self->{buffer}}, 0, 2) = '';
    return $rv;
}

sub UI24 {
    my $self = shift;

    my $rv = $self->_be2uint24(${$self->{buffer}});
    substr(${$self->{buffer}}, 0, 3) = '';
    return $rv;
}

sub I32 {
    my $self = shift;

    my $rv = $self->_be2int32(${$self->{buffer}});
    substr(${$self->{buffer}}, 0, 4) = '';
    return $rv;
}

sub UI32 {
    my $self = shift;

    my $rv = $self->_be2uint32(${$self->{buffer}});
    substr(${$self->{buffer}}, 0, 4) = '';
    return $rv;
}

sub I64 {
    my $self = shift;

    my $rv = $self->_be2int64(${$self->{buffer}});
    substr(${$self->{buffer}}, 0, 8) = '';
    return $rv;
}

sub UI64 {
    my $self = shift;

    my $rv = $self->_be2uint64(${$self->{buffer}});
    substr(${$self->{buffer}}, 0, 8) = '';
    return $rv;
}

sub DOUBLE {
    my $self = shift;

    my $rv = $self->_be2double(${$self->{buffer}});
    substr(${$self->{buffer}}, 0, 8) = '';
    return $rv;
}

sub BString {
    my $self = shift;
    my $len = shift;
    my $str = substr(${$self->{buffer}}, 0, $len);
    substr(${$self->{buffer}}, 0, $len) = '';
    return $str;
}

sub parse {
    my $self = shift;
    my $fmt = undef;;

    if (substr(${$self->{buffer}}, 0, 4) eq "FLV\1") {
        $fmt = Video::Format::FLV->new($self->{buffer});
        $self->{type} = "FLV";

    } elsif (substr(${$self->{buffer}}, 4, 4) eq "ftyp") {
        $fmt = Video::Format::MP4->new($self->{buffer});
        $fmt->setprop("name", "FILE");
        $self->{type} = "MP4";

    } else {
        carp "Unknown file format";
    }

    return $fmt;
}

sub parse_recursive {
    my $self = shift;
    my $format = $self->parse();

    return $format->parse();
}

sub type {
    my $self = shift;

    return $self->{type};
}

sub setprop {
    my $self = shift;
    my $prop = shift;
    my $val = shift;

    if (exists($self->{prop})) {
        $self->{prop}->{$prop} = $val;
    } else {
        $self->{prop} = {$prop => $val};
    }
}

sub getprop {
    my $self = shift;
    my $prop = shift;

    if (exists($self->{prop}) and exists($self->{prop}->{$prop})) {
        return $self->{prop}->{$prop};
    }

    return undef;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Video::Format - Parse video formats (containers) such as MP4, F4F, FLV

=head1 SYNOPSIS

  use Video::Format;
  
  open(FH, "file.mp4");
  sysread(FH, $buf, -s "file.mp4");

  $vf = Video::Format->new(\$buf);
  $fmt = $vf->parse();
  print $vf->type() . "\n";
  $fmt->parse();

=head1 DESCRIPTION

Stub documentation for Video::Format, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.


=head1 SEE ALSO

=over 4

=item MP4::Info Project Page

L<http://search.cpan.org/~jhar/MP4-Info>

=item ISO 14496-12:2004 - Coding of audio-visual objects - Part 12: ISO base media file format

L<http://www.iso.ch/iso/en/ittf/PubliclyAvailableStandards/c038539_ISO_IEC_14496-12_2004(E).zip>

=item ISO 14496-14:2003 - Coding of audio-visual objects - Part 14: MP4 file format

L<http://www.iso.org/iso/en/CatalogueDetailPage.CatalogueDetail?CSNUMBER=38538>
(Not worth buying - the interesting stuff is in Part 12).

=item 3GPP TS 26.244 - 3GPP file format (3GP)

L<http://www.3gpp.org/ftp/Specs/html-info/26244.htm>

=item QuickTime File Format

L<http://developer.apple.com/documentation/QuickTime/QTFF/>

=item ISO 14496-1 Media Format

L<http://www.geocities.com/xhelmboyx/quicktime/formats/mp4-layout.txt>

=item Adobe Flash Video File Format Specificati on Version 10.1

L<http://download.macromedia.com/f4v/video_file_format_spec_v10_1.pdf>

=back

=head1 AUTHOR

Eugene Mychlo, E<lt>myc@barev.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Eugene Mychlo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
