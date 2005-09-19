use strict;
use warnings;

use Test::More tests => 39;

my $CLASS = 'Tree';
use_ok( $CLASS );

# Test Plan:
# 1) Add children to a root node to make a 2-level tree, using add_child() in various
#    configurations
# 2) Verify that the children are in the correct order
# 3) Remove children using remove_child() in various configurations
# 4) Verify that the children are in the correct order

my $root = $CLASS->new;
my @children = map { $CLASS->new } 1 .. 10;

$root->add_child( $children[0] );
cmp_ok( $root->children, '==', 1, "There is one child" );

$root->add_child( at => 0, $children[1] );
cmp_ok( $root->children, '==', 2, "There are now two children" );
is( $root->children->[0], $children[1], "First child correct" );
is( $root->children->[1], $children[0], "Second child correct" );

$root->add_child( at => 1, $children[2], $children[3] );
cmp_ok( $root->children, '==', 4, "There are now four children" );
is( $root->children->[0], $children[1], "First child correct" );
is( $root->children->[1], $children[2], "Second child correct" );
is( $root->children->[2], $children[3], "Third child correct" );
is( $root->children->[3], $children[0], "Fourth child correct" );

$root->add_child( $children[4], at => 3 );
cmp_ok( $root->children, '==', 5, "There are now five children" );
is( $root->children->[0], $children[1], "First child correct" );
is( $root->children->[1], $children[2], "Second child correct" );
is( $root->children->[2], $children[3], "Third child correct" );
is( $root->children->[3], $children[4], "Fourth child correct" );
is( $root->children->[4], $children[0], "Fifth child correct" );

$root->add_child( @children[5,6], at => 3 );
cmp_ok( $root->children, '==', 7, "There are now seven children" );
is( $root->children->[0], $children[1], "First child correct" );
is( $root->children->[1], $children[2], "Second child correct" );
is( $root->children->[2], $children[3], "Third child correct" );
is( $root->children->[3], $children[5], "Fourth child correct" );
is( $root->children->[4], $children[6], "Fifth child correct" );
is( $root->children->[5], $children[4], "Sixth child correct" );
is( $root->children->[6], $children[0], "Seventh child correct" );

$root->remove_child( 2 );
cmp_ok( $root->children, '==', 6, "There are now six children" );
is( $root->children->[0], $children[1], "First child correct" );
is( $root->children->[1], $children[2], "Second child correct" );
is( $root->children->[2], $children[5], "Third child correct" );
is( $root->children->[3], $children[6], "Fourth child correct" );
is( $root->children->[4], $children[4], "Fifth child correct" );
is( $root->children->[5], $children[0], "Sixth child correct" );

$root->remove_child( 2, 4 );
cmp_ok( $root->children, '==', 4, "There are now six children" );
is( $root->children->[0], $children[1], "First child correct" );
is( $root->children->[1], $children[2], "Second child correct" );
is( $root->children->[2], $children[6], "Third child correct" );
is( $root->children->[3], $children[0], "Fourth child correct" );

$root->remove_child( 2, $children[1] );
cmp_ok( $root->children, '==', 2, "There are now six children" );
is( $root->children->[0], $children[2], "First child correct" );
is( $root->children->[1], $children[0], "Second child correct" );
