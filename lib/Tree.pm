
package Tree;

use 5.6.0;

use strict;
use warnings;

our $VERSION = '0.99_00';

use Scalar::Util qw( blessed refaddr weaken );
use Contextual::Return;

my %CONFIG = (
    use_weak_refs => 1,
);

sub import {
    shift;
    for (@_) {
        if ( lc($_) eq 'no_weak_refs' ) {
            $CONFIG{ use_weak_refs } = 0;
        }
        elsif ( lc($_) eq 'use_weak_refs' ) {
            $CONFIG{ use_weak_refs } = 1;
        }
    }
}

# These are the class methods

my %error_handlers = (
    'quiet' => sub {
    },
    'warn' => sub {
    },
    'die' => sub {
    },
);

sub QUIET { return $error_handlers{ 'quiet' } } 
sub WARN  { return $error_handlers{ 'warn' } } 
sub DIE   { return $error_handlers{ 'die' } } 

# The default error handler is quiet
my $ERROR_HANDLER = $error_handlers{ quiet };

sub new {
    my $class = shift;
    my $self = bless {
        _children => [],
        _parent => $class->_null,
        _height => 1,
        _width => 1,
        _error_handler => $ERROR_HANDLER,
        _root => undef,
    }, $class;
    $self->{_root} = $self;
    return $self;
}

# These are the behaviors

sub add_child {
    my $self = shift;
    my @nodes = @_;

    my $index;
    if ( !blessed($nodes[0]) ) {
        my ($at) = shift @nodes;
        $index = shift @nodes;
    }
    elsif ( !blessed( $nodes[$#nodes - 1] ) ) {
        $index = pop @nodes;
        my ($at) = pop @nodes;
    }

    for my $node ( @nodes ) {
        #${$node->parent} = $self;
        $node->_set_parent( $self );
        ${$node->root} = $self->root;
    }

    if ( defined $index ) {
        if ( $index ) {
            splice @{$self->children}, $index, 0, @nodes;
        }
        else {
            unshift @{$self->children}, @nodes;
        }
    }
    else {
        push @{$self->children}, @nodes;
    }

    $self->_fix_height;
    $self->_fix_width;

    return $self;
}

sub remove_child {
    my $self = shift;
    my @nodes = @_;

    my @indices;
    foreach my $proto (@nodes) {
        if ( !blessed( $proto ) ) {
            push @indices, $proto;
        }
        else {
            push @indices, grep {
                refaddr($self->children->[$_]) eq refaddr($proto)
            } 0 .. $#{$self->children};
        }
    }

    my @return;
    for my $idx (sort { $b <=> $a } @indices) {
        my $node = splice @{$self->children}, $idx, 1;
        #${$node->parent} = $node->_null;
        $node->_set_parent( $node->_null );
        ${$node->root} = $node;

        push @return, $node;
    }

    $self->_fix_height;
    $self->_fix_width;

    return (
        DEFAULT { @return }
        ARRAYREF { \@return }
        SCALAR { $return[0] }
    );
}

# These are the state-queries

sub is_root {
    my $self = shift;
    return !$self->parent;
}

sub is_leaf {
    my $self = shift;
    return $self->height == 1;
}

sub has_child {
    my $self = shift;

    my %temp = map { refaddr($_) => undef } @{$self->children};

    my $rv = 1;
    $rv &&= exists $temp{refaddr($_)}
        for @_;

    return $rv;
}

# These are the smart accessors

sub parent { 
    my $self = shift;
    return (
        SCALARREF { \($self->{_parent}) }
        DEFAULT { $self->{_parent} }
    );
}

sub children {
    my $self = shift;
    if ( @_ ) {
        my @idx = @_;
        return @{$self->{_children}}[@idx];
    }
    else {
        return (
            DEFAULT { @{$self->{_children}} }
            SCALAR { scalar @{$self->{_children}} }
            ARRAYREF { $self->{_children} }
        );
    }
}

sub root {
    my $self = shift;
    return (
        SCALARREF { \($self->{_root}) }
        DEFAULT { $self->{_root} }
    );
}

sub height {
    my $self = shift;
    return (
        SCALARREF { \($self->{_height}) }
        DEFAULT { $self->{_height} }
    );
}

sub width {
    my $self = shift;
    return (
        SCALARREF { \($self->{_width}) }
        DEFAULT { $self->{_width} }
    );
}

sub error_handler {
    my $self = shift;

    if ( blessed( $self ) ) {
        if ( @_ ) {
            my $old = $self->{_error_handler};
            $self->{_error_handler} = shift;
            return $old;
        }

        return $self->{_error_handler};
    }
    else {
        my $old = $ERROR_HANDLER;
        $ERROR_HANDLER = shift;
        return $old;
    }
}

# These are private convenience methods

sub _null {
    return Tree::Null->new;
}

sub _fix_height {
    my $self = shift;

    my $height = 1;
    for my $child (@{$self->children}) {
        my $temp_height = $child->height + 1;
        $height = $temp_height if $height < $temp_height;
    }

    #XXX This sucks - Contextual::Return::Value needs to change
    # to walk though any nesting
    ${$self->height} = $height + 0;

    $self->parent->_fix_height;

    return $self;
}

sub _fix_width {
    my $self = shift;

    ${$self->width} = 0;
    for my $child (@{$self->children}) {
        ${$self->width} += $child->width;
    }
    ${$self->width} ||= 1;

    return $self;
}

sub _set_parent {
    my $self = shift;
    my ($value) = @_;

    ${$self->parent} = $value;
    weaken( $self->{_parent} ) if $CONFIG{ use_weak_refs };
}

# These are the book-keeping methods

sub DESTROY {
    my $self = shift;

    return if $CONFIG{ use_weak_refs };

    foreach my $child (grep { $_ } @{$self->children}) {
        ${$child->parent} = $child->_null;
    }
}

package Tree::Null;

#XXX Add this in once it's been thought out
#our @ISA = qw( Tree );

# There's a lot of choices that have been made to allow for
# subclassing of this package. They are:
# 1) overload uses method names and not subrefs
# 2) new() accesses a hash of singletons, not just a scalar
# 3) AUTOLOAD uses ref() instead of __PACKAGE__

# You want to be able to interrogate the null object as to
# its class, so we don't override isa() as we do can()

use overload
    '""' => 'stringify',
    '0+' => 'numify',
    'bool' => 'boolify',
        fallback => 1,
;

{
    my %singletons;
    sub new {
        my $class = shift;
        $singletons{$class} = bless \my($x), $class
            unless exists $singletons{$class};
        return $singletons{$class};
    }
}

# The null object can do anything
sub can {
    return 1;
}

{
    our $AUTOLOAD;
    sub AUTOLOAD {
        no strict 'refs';
        *{$AUTOLOAD} = sub { ref($_[0])->new };
        goto &$AUTOLOAD;
    }
}

sub stringify { return ""; }
sub numify { return 0; }
sub boolify { return; }

1;

__END__

=head1 NAME

Tree - the basic implementation of a tree

=head1 SYNOPSIS

=head1 DESCRIPTION

This is meant to be a full-featured replacement for L<Tree::Simple>.

=head1 METHODS

=head2 Constructor

=over 4

=item B<new()>

This will return a Tree object. It currently accepts no parameters.

=back

=head2 Behaviors

=over 4

=item B<add_child(@nodes)>

This will add all the @nodes as children of $self. If the first two or last two parameters are of the form C<at =E<gt> $idx>, @nodes will be added starting at that index.

=item B<remove_child(@nodes)>

This will remove all the @nodes from the children of $self. You can either pass in the actual child object you wish to remove, the index of the child you wish to remove, or a combination of both.

=back

=head2 State Queries

=over 4

=item B<is_root()>

This will return true is $self has no parent and false otherwise.

=item B<is_leaf()>

This will return true is $self has no children and false otherwise.

=item B<has_child(@nodes)>

This will return true is $self has each of the @nodes as a child.

=back

=head2 Accessors

=over 4

=item B<parent()>

This will return the parent of $self.

=item B<children( [ $idx, [$idx, ..] ] )>

This will return the children of $self. If called in list context, it will return all the children. If called in scalar context, it will return the number of children.

You may optionally pass in a list of indices to retrieve. This will return the children in the order you asked for them. This is very much like an arrayslice.

=item B<root()>

This will return the root node of the tree that $self is in. The root of the root node is itself.

=item B<height()>

This will return the height of $self. A leaf has a height of 1. A parent has a height of its tallest child, plus 1.

=item B<width()>

This will return the width of $self. A leaf has a width of 1. A parent has a width equal to the sum of all the widths of its children.

=back

=head1 CIRCULAR REFERENCES

Copy the text from L<Tree::Simple>, rewording appropriately.

=head1 BUGS

None that we are aware of.

The test suite for Tree 1.0 is based very heavily on the test suite for L<Test::Simple>, which has been heavily tested and used in a number of other major distributions, such as L<Catalyst> and rt.cpan.org.

=head1 CODE COVERAGE

We use L<Devel::Cover> to test the code coverage of my tests, below is the L<Devel::Cover> report on this module's test suite. We use TDD, which is why our coverage is so high.
 
  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  File                           stmt branch   cond    sub    pod   time  total
  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  blib/lib/Tree.pm               96.1   95.8  100.0   95.5  100.0  100.0   96.2
  Total                          96.1   95.8  100.0   95.5  100.0  100.0   96.2
  ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 MISSING TESTS

=over 4

=item * A test on import where something is passed in that isn't an expected value.

=item * For some reason, Deve::Cover is now counting lines as uncovered that were previously covered, like Tree::Null's can() and a commented-out mention of AUTOLOAD.

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item Stevan Little for writing Tree::Simple, upon which Tree is based.

=back

=head1 AUTHORS

Rob Kinyon E<lt>rob.kinyon@iinteractive.comE<gt>

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Thanks to Infinity Interactive for generously donating our time.

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut

