package Export::Declare::Meta;
use strict;
use warnings;

use Carp qw/croak/;

my %STASH;

sub export       { $_[0]->{export} }
sub export_ok    { $_[0]->{export_ok} }
sub export_fail  { $_[0]->{export_fail} }
sub export_tags  { $_[0]->{export_tags} }
sub export_anon  { $_[0]->{export_anon} }
sub export_gen   { $_[0]->{export_gen} }
sub export_magic { $_[0]->{export_magic} }
sub package      { $_[0]->{package} }
sub vars         { $_[0]->{vars} }
sub menu         { $_[0]->{menu} }

sub new {
    my $class = shift;
    my ($pkg) = @_;

    croak "$class constructor requires a package name" unless $pkg;

    return $STASH{$pkg} if $STASH{$pkg};

    my $all     = [];
    my $fail    = [];
    my $default = [];
    return $STASH{$pkg} = bless(
        {
            export       => $default,
            export_ok    => $all,
            export_fail  => $fail,
            export_tags  => {DEFAULT => $default, ALL => $all, FAIL => $fail},
            export_anon  => {},
            export_gen   => {},
            export_magic => {},

            package => $pkg,
            vars    => 0,
            menu    => 0,
        },
        $class
    );
}

sub inject_menu {
    my $self = shift;
    return if $self->{menu}++;

    my $pkg = $self->{package};

    no strict 'refs';
    no warnings 'once';
    *{"$pkg\::IMPORTER_MENU"} = sub { %$self };
}

sub inject_vars {
    my $self = shift;
    return if $self->{vars}++;

    my $pkg = $self->{package};

    no strict 'refs';
    no warnings 'once';

    *{"$pkg\::EXPORT"}       = $self->{export};
    *{"$pkg\::EXPORT_OK"}    = $self->{export_ok};
    *{"$pkg\::EXPORT_TAGS"}  = $self->{export_tags};
    *{"$pkg\::EXPORT_ANON"}  = $self->{export_anon};
    *{"$pkg\::EXPORT_GEN"}   = $self->{export_gen};
    *{"$pkg\::EXPORT_FAIL"}  = $self->{export_fail};
    *{"$pkg\::EXPORT_MAGIC"} = $self->{export_magic};
}

1;
