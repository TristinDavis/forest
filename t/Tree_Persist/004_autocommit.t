use strict;
use warnings;

use Test::More;

plan tests => 16;

my $CLASS = 'Tree::Persist';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

use File::Copy qw( cp );
use File::Spec::Functions qw( catfile );
use Test::File;
use Test::File::Cleaner;
use Test::File::Contents;
use Scalar::Util qw( refaddr );

my $dirname = catfile( qw( t Tree_Persist datafiles ) );

my $cleaner = Test::File::Cleaner->new( $dirname );

{
    my $filename = catfile( $dirname, 'save1.xml' );

    cp( catfile( $dirname, 'tree1.xml' ), $filename );

    file_exists_ok( $filename, 'Tree1 file exists' ); 

    file_contents_is( $filename, <<__END_FILE__, '... and the contents are good' );
<node class="Tree" value="root">
</node>
__END_FILE__

    my $persist = $CLASS->connect({
        filename => $filename,
    });

    ok( $persist->autocommit, "Autocommit defaults to true" );

    ok( $persist->autocommit( 0 ), "Setting autocommit returns the old value" );
    ok( !$persist->autocommit, "After setting it to false, it's now false" );

    my $tree = $persist->tree;

    $tree->value( 'foo' );

    file_contents_is( $filename, <<__END_FILE__, "Shoudn't change anything with autocommit off" );
<node class="Tree" value="root">
</node>
__END_FILE__

    $persist->commit;

    file_contents_is( $filename, <<__END_FILE__, "... but committing should." );
<node class="Tree" value="foo">
</node>
__END_FILE__

    $tree->value( 'bar' );

    file_contents_is( $filename, <<__END_FILE__, "No change ..." );
<node class="Tree" value="foo">
</node>
__END_FILE__

    $persist->rollback;

    file_contents_is( $filename, <<__END_FILE__, "Still no change ..." );
<node class="Tree" value="foo">
</node>
__END_FILE__

    my $tree2 = $persist->tree;

    isnt( refaddr($tree), refaddr($tree2), "After rollback, the actual tree object changes" );

    is( $tree->value, 'bar', "The reference to the old tree still has the old value" );
    is( $tree2->value, 'foo', "... and rollback restores the original value in the new tree" );
}

{
    my $filename = catfile( $dirname, 'save2.xml' );

    cp( catfile( $dirname, 'tree1.xml' ), $filename );

    file_exists_ok( $filename, 'Tree1 file exists' ); 

    file_contents_is( $filename, <<__END_FILE__, '... and the contents are good' );
<node class="Tree" value="root">
</node>
__END_FILE__

    my $persist = $CLASS->connect({
        filename => $filename,
    });

    my $modtime = -M $filename;

    sleep 1;

    $persist->commit;

    my $new_modtime = -M $filename;

    # Need to track changes made to the tree
    cmp_ok( $modtime, '==', $new_modtime, "commit() with autocommit() on is a no-op" );
}
