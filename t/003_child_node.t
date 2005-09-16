use strict;
use warnings;

use Test::More tests => 26;

my $CLASS = 'Tree';
use_ok( $CLASS );

# Test plan:
# Add a single child, then retrieve it, then remove it.
# 1) Verify that one can retrieve a child added
# 2) Verify that the appropriate status methods reflect the change
# 3) Verify that the child can be removed
# 4) Verify that the appropriate status methods reflect the change

my $tree = $CLASS->new();
isa_ok( $tree, $CLASS );

my $child = $CLASS->new();
isa_ok( $child, $CLASS );

ok( $child->is_root, "The child is a root ... for now" );
ok( $child->is_leaf, "The child is also a leaf" );

ok( !$tree->has_child( $child ), "The root doesn't have the child ... yet" );

is( $tree->add_child( $child ), $tree, "add_child() chains" );

ok( $tree->is_root, 'The root is still the root' );
ok( !$tree->is_leaf, 'The root is no longer a leaf' );

ok( !$child->is_root, 'The child is no longer a root' );
ok( $child->is_leaf, 'The child is still a leaf' );

ok( $tree->children == 1, "The root has one child" );
my @children = $tree->children;
ok( @children == 1, "The list of children is still 1 long" );
is( $children[0], $child, "The child is correct" );

is( $child->parent, $tree, "The child's parent is also set correctly" );

ok( $tree->has_child( $child ), "The tree has the child" );

ok( $tree->height == 2, "The root's height is 2" );
ok( $child->height == 1, "The child's height is 1" );

is( $tree->remove_child( $child ), $child, "remove_child() returns the removed node" );

ok( $tree->is_root, 'The root is still the root' );
ok( $tree->is_leaf, 'The root is now a leaf' );

ok( $child->is_root, 'The child is now a root' );
ok( $child->is_leaf, 'The child is still a leaf' );

ok( $tree->children == 0, "The root has no children" );

ok( $tree->height == 1, "The root's height is now 1 again" );
ok( $child->height == 1, "The child's height is still 1" );

