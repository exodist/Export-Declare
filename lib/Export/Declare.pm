package Export::Declare;
use strict;
use warnings;

use Carp qw/croak/;
use Importer;
use Export::Declare::Meta;

sub META() { 'Export::Declare::Meta' }

BEGIN { META->new(__PACKAGE__)->inject_vars }

our $VERSION = '0.001';

my %SIG_TO_TYPE = (
    '&' => 'CODE',
    '%' => 'HASH',
    '@' => 'ARRAY',
    '$' => 'SCALAR',
    '*' => 'GLOB',
);

exports(qw{
    export
    exports
    export_tag
    export_gen
    export_magic
});

export(import => sub { Importer->import_into(shift(@_), 0, @_) });

sub import {
    my $class = shift;
    return unless @_;

    my $caller = caller;

    my (@subs, %params);
    while(my $arg = shift @_) {
        push @subs => $arg unless substr($arg, 0, 1) eq '-';
        $params{substr($arg, 1)} = 1;
    }

    my $meta = META->new($caller);
    $meta->inject_menu if $params{menu};
    $meta->inject_vars if $params{vars} || !$params{menu};

    Importer->import_into($class, $caller, @subs) if @subs;
}

sub export {
    my ($sym, $ref) = @_;
    my ($name, $sig, $type) = _parse_sym($sym);

    my $from = caller;
    my $meta = META->new($from);

    return push @{$meta->export_ok} => $sym unless $ref;

    croak "Symbol '$sym' is type '$type', but reference '$ref' is not"
        unless ref($ref) eq $type;

    $meta->export_anon->{$sym} = $ref;
    push @{$meta->export_ok} => $sym;
}

sub exports {
    my $from = caller;
    my $meta = META->new($from);

    push @{$meta->export_ok} => grep _parse_sym($_), @_;
}

sub export_tag {
    my ($tag, @symbols) = @_;

    my $from = caller;
    my $meta = META->new($from);

    my $ref = $meta->export_tags->{$tag} ||= [];
    push @$ref => grep _parse_sym($_), @symbols;
}

sub export_gen {
    my ($sym, $sub) = @_;
    my ($name, $sig, $type) = _parse_sym($sym);
    my $from = caller;

    croak "Second argument to export_gen() must be either a coderef or a valid method on package '$from'"
        unless ref($sub) eq 'CODE' || $from->can($sub);

    my $meta = META->new($from);
    $meta->export_gen->{$sym} = $sub;
    push @{$meta->export_tags->{ALL}} => $sym;
}

sub export_magic {
    my ($sym, $sub) = @_;
    my ($name, $sig, $type) = _parse_sym($sym);
    my $from = caller;

    croak "Second argument to export_magic() must be either a coderef or a valid method on package '$from'"
        unless ref($sub) eq 'CODE' || $from->can($sub);

    my $meta = META->new($from);
    $meta->export_magic->{$sym} = $sub;
}

sub _parse_sym {
    my ($sym) = @_;
    my ($sig, $name) = ($sym =~ m/^(\W?)(.+)$/);
    croak "'$sym' is not a valid symbol name" unless $name;
    $sig ||= '&';

    my $type = $SIG_TO_TYPE{$sig} or croak "'$sym' is not a supported symbol";

    return ($name, $sig, $type);
}

1;
