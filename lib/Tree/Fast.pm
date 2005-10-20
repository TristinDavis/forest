package Tree::Fast;

use strict;
use warnings;

our $VERSION = '1.00';

use Scalar::Util qw( blessed weaken );

sub new {
    my $class = shift;

    return $class->clone( @_ )
        if blessed $class;

    my $self = bless {}, $class;

    $self->_init( @_ );

    return $self;
}

sub _init {
    my $self = shift;
    my ($value) = @_;

    $self->{_parent} = $self->_null,
    $self->{_children} = [];
    $self->{_value} = $value,

    return $self;
}

sub clone {
    my $self = shift;

    return $self->new(@_) unless blessed $self;

    my $value = @_ ? shift : $self->value;
    my $clone = ref($self)->new( $value );

    if ( my @children = @{$self->{_children}} ) {
        $clone->add_child( map { $_->clone } @children );
    }

    return $clone;
}

sub add_child {
    my $self = shift;
    my @nodes = @_;

    my $index;
    if ( !blessed $nodes[0] ) {
        $index = shift @nodes;
    }

    for my $node ( @nodes ) {
        $node->_set_parent( $self );
    }

    if ( defined $index ) {
        if ( $index ) {
            splice @{$self->{_children}}, $index, 0, @nodes;
        }
        else {
            unshift @{$self->{_children}}, @nodes;
        }
    }
    else {
        push @{$self->{_children}}, @nodes;
    }

    return $self;
}

sub remove_child {
    my $self = shift;
    my @indices = @_;

    my @return;
    for my $idx (sort { $b <=> $a } @indices) {
        my $node = splice @{$self->{_children}}, $idx, 1;
        $node->_set_parent( $node->_null );

        push @return, $node;
    }

    return @return;
}

sub parent {
    my $self = shift;
    return $self->{_parent};
}

sub _set_parent {
    my $self = shift;

    $self->{_parent} = shift;
    weaken( $self->{_parent} );

    return $self;
}

sub children {
    my $self = shift;
    if ( @_ ) {
        my @idx = @_;
        return @{$self->{_children}}[@idx];
    }
    else {
        if ( caller->isa( __PACKAGE__ ) ) {
            return wantarray ? @{$self->{_children}} : $self->{_children};
        }
        else {
            return @{$self->{_children}};
        }
    }
}

sub value {
    my $self = shift;
    return $self->{_value};
}

sub set_value {
    my $self = shift;

    $self->{_value} = $_[0];

    return $self;
}

sub mirror {
    my $self = shift;

    @{$self->{_children}} = reverse @{$self->{_children}};
    $_->mirror for @{$self->{_children}};

    return $self;
}

use constant PRE_ORDER   => 1;
use constant POST_ORDER  => 2;
use constant LEVEL_ORDER => 3;

sub traverse {
    my $self = shift;
    my $order = shift || $self->PRE_ORDER;

    my @list;

    if ( $order eq $self->PRE_ORDER ) {
        @list = ($self);
        push @list, map { $_->traverse( $order ) } @{$self->{_children}};
    }
    elsif ( $order eq $self->POST_ORDER ) {
        @list = map { $_->traverse( $order ) } @{$self->{_children}};
        push @list, $self;
    }
    elsif ( $order eq $self->LEVEL_ORDER ) {
        my @queue = ($self);
        while ( my $node = shift @queue ) {
            push @list, $node;
            push @queue, @{$node->{_children}};
        }
    }
    else {
        return $self->error( "traverse(): '$order' is an illegal traversal order" );
    }

    return @list;
}

sub _null {
    return Tree::Null->new;
}

package Tree::Null;

#XXX Add this in once it's been thought out
#our @ISA = qw( Tree );

# You want to be able to interrogate the null object as to
# its class, so we don't override isa() as we do can()

use overload
    '""' => sub { return "" },
    '0+' => sub { return 0 },
    'bool' => sub { return },
        fallback => 1,
;

{
    my $singleton = bless \my($x), __PACKAGE__;
    sub new { return $singleton }
    sub AUTOLOAD { return $singleton }
    sub can { return sub { return $singleton } }
}

# The null object can do anything
sub isa {
    my ($proto, $class) = @_;

    if ( $class =~ /^Tree(?:::.*)?$/ ) {
        return 1;
    }

    return $proto->SUPER::isa( $class );
}

1;
__END__

=head1 NAME

Tree::Fast - the fastest possible implementation of a tree in pure Perl

=head1 SYNOPSIS

=head1 DESCRIPTION

This is meant to be the core imlpementation for L<Tree>, stripped down as much
as possible. There is no error-checking, bounds-checking, event-handling,
convenience methods, or anything else of the sort. If you want something fuller-
featured, please look at L<Tree>, which is a wrapper around L<Tree::Fast>.

=head1 METHODS

=head2 Constructor

=over 4

=item B<new([$value])>

This will return a Tree object. It will accept one parameter which, if passed, will become the value (accessible by L<value()>). All other parameters will be ignored.

If you call C<$tree->new([$value])>, it will instead call C<clone()>, then set the value of the clone to $value.

=item B<clone()>

This will return a clone of C<$tree>. The clone will be a root tree, but all children will be cloned.

If you call <Tree->clone([$value])>, it will instead call C<new()>.

B<NOTE:> the value is merely a shallow copy. This means that all references will be kept.

=back

=head2 Behaviors

=over 4

=item B<add_child([ $idx ], @nodes)>

This will add all the @nodes as children of C<$tree>. If the first parameter
is a number, @nodes will be added starting at that index. If C<$idx> is negative, it will start that many in from the end. So, C<$idx == -1> will add @nodes before the last element of the children. If $idx is undefined, then it act as a push(). If $idx is 0, then it will act as an unshift.

=item B<remove_child(@nodes)>

This will remove all the @nodes from the children of C<$tree>. You can either pass in the actual child object you wish to remove, the index of the child you wish to remove, or a combination of both.

=item B<mirror()>

This will modify the tree such that it is a mirror of what it was before. This means that the order of all children is reversed.

B<NOTE>: This is a destructive action. It I<will> modify the tree's internal structure. If you wish to get a mirror, yet keep the original tree intact, use C<my $mirror = $tree->clone->mirror;>

=item B<traverse( [$order] )>

This will return a list of the nodes in the given traversal order. The default traversal order is pre-order.

The various traversal orders do the following steps:

=over 4

=item * Pre-order (aka Prefix traversal)

This will return the node, then the first sub tree in pre-order traversal, then the next sub tree, etc.

Use C<$tree->PRE_ORDER> as the C<$order>.

=item * Post-order (aka Prefix traversal)

This will return the each sub-tree in post-order traversal, then the node.

Use C<$tree->POST_ORDER> as the C<$order>.

=item * Level-order (aka Prefix traversal)

This will return the node, then the all children of the node, then all grandchildren of the node, etc.

Use C<$tree->LEVEL_ORDER> as the C<$order>.

=back

=back

All behaviors will reset last_error().

=head2 State Queries

=over 4

=item * B<has_child(@nodes)>

If called in a boolean context, this will return true is C<$tree> has each of the @nodes as a child. If called in a list context, it will map back the list of indices for each of the @nodes. If called in a scalar, non-boolean context, it will return back the index for C<$nodes[0]>.

=back

=head2 Accessors

=over 4

=item * B<parent()>

This will return the parent of C<$tree>.

=item * B<children( [ $idx, [$idx, ..] ] )>

This will return the children of C<$tree>. If called in list context, it will return all the children. If called in scalar context, it will return the number of children.

You may optionally pass in a list of indices to retrieve. This will return the children in the order you asked for them. This is very much like an arrayslice.

=item * B<value()>

This will return the value stored in the node.

=item * B<set_value([$value])>

This will set the value stored in the node to $value, then return $self.

=back

=head1 NULL TREE

If you call C<$self->parent> on a root node, it will return a Tree::Null
object. This is an implementation of the Null Object pattern optimized for
usage with L<Forest>. It will evaluate as false in every case (using L<overload>) and all methods called on it will return a Tree::Null object.

=head2 Notes

=over 4

=item * Tree::Null does B<not> inherit from anything. This is so that all the methods will go through AUTOLOAD vs. the actual method.

=item * However, calling isa() on a Tree::Null object will report that it is-a any object that is either Tree or in the Tree:: hierarchy.

=item * The Tree::Null object is a singleton.

=item * The Tree::Null object I<is> defined, though. I couldn't find a way to make it evaluate as undefined. That may be a good thing.

=back

=head1 BUGS

None that we are aware of.

The test suite for Tree 1.0 is based very heavily on the test suite for L<Test::Simple>, which has been heavily tested and used in a number of other major distributions, such as L<Catalyst> and rt.cpan.org.

=head1 TODO

=over 4

=item * traverse()

Need to add contextual awareness by providing an iterating closure (object?) in scalar context.

=item * N-ary Proofs

Need to generalize some of the btree proofs to N-ary trees, if possible.

=item * Traversals and memory

Need tests for what happens with a traversal list and deleted nodes, particularly w.r.t. how memory is handled - should traversals weaken if use_weak_refs is in force?

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Stevan Little for writing L<Tree::Simple>, upon which Tree is based.

=back

=head1 CODE COVERAGE

We use L<Devel::Cover> to test the code coverage of our tests. Please see L<Forest>
for the coverage report.

=head1 AUTHORS

Rob Kinyon E<lt>rob.kinyon@iinteractive.comE<gt>

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Thanks to Infinity Interactive for generously donating our time.

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
