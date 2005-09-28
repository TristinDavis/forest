use strict;
use warnings;

use Test::More;

use t::tests qw( %runs );

plan tests => 22 + 3 * $runs{stats}{plan};

my $CLASS = 'Tree';
use_ok( $CLASS );

# Test plan:
# 1) Create with an empty new().
# 2) Create with a payload passed into new().
# 3) Create with 2 parameters passed into new().

{
    my $tree = $CLASS->new();
    isa_ok( $tree, $CLASS );

    my $parent = $tree->parent;
    is( $parent, $tree->_null, "The root's parent is the null node" );

    $runs{stats}{func}->( $tree,
        height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
    );

    is( $tree->root, $tree, "The root's root is itself" );

    is( $tree->value, undef, "The root's value is undef" );
    is( $tree->value( 'foobar' ), 'foobar', "Setting value() returns the value passed in" );
    is( $tree->value(), 'foobar', "Calling value() returns the value passed in" );

    is_deeply( $tree->mirror, $tree, "A single-node tree's mirror is itself" );
}

{
    my $tree = $CLASS->new( 'payload' );
    isa_ok( $tree, $CLASS );

    my $parent = $tree->parent;
    is( $parent, $tree->_null, "The root's parent is the null node" );

    $runs{stats}{func}->( $tree,
        height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
    );

    is( $tree->root, $tree, "The root's root is itself" );
    is( $tree->value, 'payload', "The root's value is undef" );
    is( $tree->value( 'foobar' ), 'foobar', "Setting value() returns the value passed in" );
    is( $tree->value(), 'foobar', "Setting value() returns the value passed in" );

    is_deeply( $tree->mirror, $tree, "A single-node tree's mirror is itself" );
}

{
    my $tree = $CLASS->new( 'payload', 'unused value' );
    isa_ok( $tree, $CLASS );

    my $parent = $tree->parent;
    is( $parent, $tree->_null, "The root's parent is the null node" );

    $runs{stats}{func}->( $tree,
        height => 1, width => 1, depth => 0, size => 1, is_root => 1, is_leaf => 1,
    );

    is( $tree->root, $tree, "The root's root is itself" );
    is( $tree->value, 'payload', "The root's value is undef" );
    is( $tree->value( 'foobar' ), 'foobar', "Setting value() returns the value passed in" );
    is( $tree->value(), 'foobar', "Setting value() returns the value passed in" );

    is_deeply( $tree->mirror, $tree, "A single-node tree's mirror is itself" );
}
